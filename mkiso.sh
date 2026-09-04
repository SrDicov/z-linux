#!/bin/bash

set -eu

. ./lib.sh

PROGNAME=$(basename "$0")
ARCH=$(uname -m)
IMAGES="base"
TRIPLET=
REPO=
DATE=$(date -u +%Y%m%d)

usage() {
	cat <<-EOH
	Usage: $PROGNAME [options ...] [-- mklive options ...]

	Wrapper script around mklive.sh for several standard flavors of live images.
	Adds void-installer and other helpful utilities to the generated images.

	OPTIONS
	 -a <arch>     Set architecture (or platform) in the image
	 -b <variant>  One of base, enlightenment, xfce, mate, cinnamon, gnome, kde,
	               lxde, lxqt, xfce-wayland, or omarchy (default: base). May be specified multiple times
	               to build multiple variants
	 -d <date>     Override the datestamp on the generated image (YYYYMMDD format)
	 -t <arch-date-variant>
	               Equivalent to setting -a, -b, and -d
	 -r <repo>     Use this XBPS repository. May be specified multiple times
	 -h            Show this help and exit
	 -V            Show version and exit

	Other options can be passed directly to mklive.sh by specifying them after the --.
	See mklive.sh -h for more details.
	EOH
}

while getopts "a:b:d:t:hr:V" opt; do
case $opt in
    a) ARCH="$OPTARG";;
    b) IMAGES="$OPTARG";;
    d) DATE="$OPTARG";;
    r) REPO="-r $OPTARG $REPO";;
    t) TRIPLET="$OPTARG";;
    V) version; exit 0;;
    h) usage; exit 0;;
    *) usage >&2; exit 1;;
esac
done
shift $((OPTIND - 1))

INCLUDEDIR=$(mktemp -d)
trap "cleanup" INT TERM

cleanup() {
    rm -rf "$INCLUDEDIR"
}

include_installer() {
    if [ -x installer.sh ]; then
        MKLIVE_VERSION="$(PROGNAME='' version)"
        installer=$(mktemp)
        sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" installer.sh > "$installer"
        install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
        rm "$installer"
    else
        echo installer.sh not found >&2
        exit 1
    fi
}

setup_pipewire() {
    PKGS="$PKGS pipewire alsa-pipewire"
    case "$ARCH" in
        asahi*)
            PKGS="$PKGS asahi-audio"
            SERVICES="$SERVICES speakersafetyd"
            ;;
    esac
    mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
    ln -sf /usr/share/applications/pipewire.desktop "$INCLUDEDIR"/etc/xdg/autostart/
    mkdir -p "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d
    ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    mkdir -p "$INCLUDEDIR"/etc/alsa/conf.d
    ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf "$INCLUDEDIR"/etc/alsa/conf.d
    ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf "$INCLUDEDIR"/etc/alsa/conf.d
}

build_variant() {
    variant="$1"
    shift
    IMG=void-live-${ARCH}-${DATE}-${variant}.iso

    # el-cheapo installer is unsupported on arm because arm doesn't install a kernel by default
    # and to work around that would add too much complexity to it
    # thus everyone should just do a chroot install anyways
    WANT_INSTALLER=no
    case "$ARCH" in
        x86_64*|i686*)
            GRUB_PKGS="limine"
            GFX_PKGS="xorg-video-drivers xf86-video-intel"
            GFX_WL_PKGS="mesa-dri"
            WANT_INSTALLER=yes
            TARGET_ARCH="$ARCH"
            ;;
        aarch64*)
            GRUB_PKGS="limine"
            GFX_PKGS="xorg-video-drivers"
            GFX_WL_PKGS="mesa-dri"
            TARGET_ARCH="$ARCH"
            ;;
        asahi*)
            GRUB_PKGS="asahi-base asahi-scripts limine"
            GFX_PKGS="mesa-asahi-dri"
            GFX_WL_PKGS="mesa-asahi-dri"
            KERNEL_PKG="linux-asahi"
            TARGET_ARCH="aarch64${ARCH#asahi}"
            if [ "$variant" = xfce ]; then
                info_msg "xfce is not supported on asahi, switching to xfce-wayland"
                variant="xfce-wayland"
            fi
            ;;
    esac

    A11Y_PKGS="espeakup void-live-audio brltty"
    # libudev-zero is gone from the Void repos; install it from the Z Linux repo
    # (it replaces eudev-libudev and pairs with mdevd for udev API compatibility).
    case "$TARGET_ARCH" in
        x86_64|x86_64-musl)
            REPO="-r https://srdicov.github.io/z-repo/$TARGET_ARCH $REPO"
            PKGS="dialog cryptsetup lvm2 mdadm void-docs-browse xtools-minimal xmirror chrony tmux dbus wget mdevd libudev-zero iwd seatd dinit limine $A11Y_PKGS $GRUB_PKGS"
            ;;
        *)
            PKGS="dialog cryptsetup lvm2 mdadm void-docs-browse xtools-minimal xmirror chrony tmux dbus wget mdevd iwd seatd dinit limine $A11Y_PKGS $GRUB_PKGS"
            ;;
    esac
    FONTS="font-misc-misc terminus-font dejavu-fonts-ttf"
    WAYLAND_PKGS="$GFX_WL_PKGS $FONTS orca"
    XORG_PKGS="$GFX_PKGS $FONTS xorg-minimal xorg-input-drivers setxkbmap xauth orca"
    SERVICES=""

    LIGHTDM_SESSION=''

    case $variant in
        base)
            # Empty
        ;;
        enlightenment)
            PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter enlightenment terminology udisks2 firefox"
            LIGHTDM_SESSION=enlightenment
        ;;
        xfce*)
            PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter xfce4 gnome-themes-standard gnome-keyring gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox xfce4-pulseaudio-plugin"
            LIGHTDM_SESSION=xfce

            if [ "$variant" == "xfce-wayland" ]; then
                PKGS="$PKGS $WAYLAND_PKGS labwc"
                LIGHTDM_SESSION="xfce-wayland"
            fi
        ;;
        mate)
            PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter mate mate-extra gnome-keyring gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
            LIGHTDM_SESSION=mate
        ;;
        cinnamon)
            PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter cinnamon gnome-keyring colord gnome-terminal gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
            LIGHTDM_SESSION=cinnamon
        ;;
        gnome)
            PKGS="$PKGS $XORG_PKGS gnome firefox"
        ;;
        kde)
            PKGS="$PKGS $XORG_PKGS kde5 konsole firefox dolphin"
        ;;
        lxde)
            PKGS="$PKGS $XORG_PKGS lxde lightdm lightdm-gtk-greeter gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
            LIGHTDM_SESSION=LXDE
        ;;
        lxqt)
            PKGS="$PKGS $XORG_PKGS lxqt sddm gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
        ;;
        omarchy)
            # Z Linux desktop flavor: swayfx + omarchy-style Wayland stack.
            # The session is launched from the tty1 autologin via the skel
            # .bash_profile; no display manager. Extra packages for installed
            # systems (sddm, cups, ufw, python3, nodejs, vary, librewolf...)
            # land in a later phase together with installer integration.
            PKGS="$PKGS $WAYLAND_PKGS \
                swayfx quickshell fuzzel foot xorg-server-xwayland \
                grim slurp swappy wl-clipboard cliphist wtype wf-recorder wlsunset \
                swaylock swayidle kanshi mako libnotify \
                xdg-desktop-portal-wlr xdg-desktop-portal-gtk mate-polkit xdg-user-dirs \
                wireplumber rtkit brightnessctl pamixer playerctl power-profiles-daemon \
                git neovim tmux jq gum fzf ripgrep fd eza bat zoxide starship \
                btop fastfetch lazygit chromium \
                mpv imv ffmpegthumbnailer libvips papirus-icon-theme nwg-look \
                nerd-fonts-symbols-ttf noto-fonts-emoji"
        ;;
        *)
            >&2 echo "Unknown variant $variant"
            exit 1
        ;;
    esac

    if [ -n "$LIGHTDM_SESSION" ]; then
        mkdir -p "$INCLUDEDIR"/etc/lightdm
        echo "$LIGHTDM_SESSION" > "$INCLUDEDIR"/etc/lightdm/.session
        # needed to show the keyboard layout menu on the login screen
        cat <<- EOF > "$INCLUDEDIR"/etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
indicators = ~host;~spacer;~clock;~spacer;~layout;~session;~a11y;~power
EOF
    fi

    if [ "$WANT_INSTALLER" = yes ]; then
        include_installer
    else
        mkdir -p "$INCLUDEDIR"/usr/bin
        printf "#!/bin/sh\necho 'void-installer is not supported on this live image'\n" > "$INCLUDEDIR"/usr/bin/void-installer
        chmod 755 "$INCLUDEDIR"/usr/bin/void-installer
    fi

    if [ "$variant" != base ]; then
        setup_pipewire
    fi

    if [ "$variant" = omarchy ]; then
        # Desktop session files: skel (tty1 autologin launches the compositor)
        # and the session self-test helper.
        mkdir -p "$INCLUDEDIR"/etc/skel "$INCLUDEDIR"/usr/libexec
        cp -a desktops/omarchy/skel/. "$INCLUDEDIR"/etc/skel/
        install -m755 -t "$INCLUDEDIR"/usr/libexec/ desktops/omarchy/libexec/*
    fi

    mkdir -p "$INCLUDEDIR"/etc/dinit.d
    cp -a dinit-services/* "$INCLUDEDIR"/etc/dinit.d/
    rm -rf "$INCLUDEDIR"/etc/dinit.d/scripts
    mkdir -p "$INCLUDEDIR"/usr/libexec
    install -m755 -t "$INCLUDEDIR"/usr/libexec/ dinit-services/scripts/*
    install -Dm644 data/mdev.conf "$INCLUDEDIR"/etc/mdev.conf
    install -Dm644 data/dhcpcd.conf "$INCLUDEDIR"/etc/dhcpcd.conf

    # Replace util-linux poweroff/reboot/halt/shutdown with dinit-aware
    # commands that roll back services before powering off.
    install -d "$INCLUDEDIR"/usr/bin
    install -m755 -t "$INCLUDEDIR"/usr/bin/ data/bin/reboot data/bin/poweroff \
        data/bin/halt data/bin/shutdown


    ./mklive.sh -a "$TARGET_ARCH" -o "$IMG" -p "$PKGS" -S "$SERVICES" -I "$INCLUDEDIR" \
        ${KERNEL_PKG:+-v $KERNEL_PKG} ${REPO} "$@"

	cleanup
}

if [ ! -x mklive.sh ]; then
    echo mklive.sh not found >&2
    exit 1
fi

if [ -n "$TRIPLET" ]; then
    IFS=: read -r ARCH DATE VARIANT _ < <( echo "$TRIPLET" | sed -Ee 's/^(.+)-([0-9rc]+)-(.+)$/\1:\2:\3/' )
    build_variant "$VARIANT" "$@"
else
    for image in $IMAGES; do
        build_variant "$image" "$@"
    done
fi
