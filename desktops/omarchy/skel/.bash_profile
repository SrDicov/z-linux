# ~/.bash_profile - Z Linux live desktop (sabor omarchy)

[ -f ~/.bashrc ] && . ~/.bashrc

# Launch the desktop session on tty1. Escape hatch: add `live.no-desktop`
# to the kernel cmdline to get a plain console instead.
case "$(tty 2>/dev/null)" in
/dev/tty1)
    if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && \
       ! grep -qw live.no-desktop /proc/cmdline 2>/dev/null && \
       command -v dbus-run-session >/dev/null 2>&1; then
        COMPOSER="$(command -v swayfx || command -v sway)"
        if [ -n "$COMPOSER" ]; then
            uid=$(id -u); gid=$(id -g)
            XDG_RUNTIME_DIR="/run/user/$uid"
            if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                # user-runtime (dinit) normally creates this; fall back to
                # sudo (NOPASSWD on the live image) or the home dir.
                sudo install -d -m 700 -o "$uid" -g "$gid" "$XDG_RUNTIME_DIR" 2>/dev/null \
                    || { XDG_RUNTIME_DIR="$HOME/.cache/xdg-runtime"; mkdir -p -m 700 "$XDG_RUNTIME_DIR"; }
            fi
            export XDG_RUNTIME_DIR
            export XDG_SESSION_TYPE=wayland
            export XDG_CURRENT_DESKTOP=sway

            # Crash guard: if the compositor died seconds ago, drop to a
            # shell instead of looping through agetty's autologin.
            marker="$XDG_RUNTIME_DIR/sway-last-start"
            now=$(date +%s)
            if [ -f "$marker" ] && [ $((now - $(stat -c %Y "$marker" 2>/dev/null || echo "$now"))) -lt 5 ]; then
                echo "sway se reinicio demasiado rapido; pasando al shell." >&2
                return
            fi
            touch "$marker"

            exec dbus-run-session -- "$COMPOSER" >>"$XDG_RUNTIME_DIR/sway-session.log" 2>&1
        fi
    fi
    ;;
esac
