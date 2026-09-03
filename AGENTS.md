# AGENTS.md - Void Linux void-mklive Repository

## Overview
This repository builds Void Linux live ISOs, ROOTFS tarballs, platform-specific filesystems (PLATFORMFS), ARM images (SBC), WSL images, and netboot artifacts. All scripts must run as root on Void Linux (or in the provided CI container).

## Key Commands (Makefile targets)

| Target | Description |
|--------|-------------|
| `make live-iso-all` | Build all live ISOs (uses `LIVE_ARCHS`, `LIVE_FLAVORS`, `DATECODE`) |
| `make rootfs-all` | Build all ROOTFS tarballs (uses `ARCHS`, `DATECODE`) |
| `make platformfs-all` | Build all PLATFORMFS tarballs (requires ROOTFS first, uses `PLATFORMS`, `DATECODE`) |
| `make images-all-sbc` | Build SBC images (.img.xz) from PLATFORMFS (uses `SBC_IMGS`, `DATECODE`) |
| `make images-all-cloud` | Build cloud images (.tar.gz) from PLATFORMFS (uses `CLOUD_IMGS`, `DATECODE`) |
| `make pxe-all` | Build netboot tarballs (uses `PXE_ARCHS`, `DATECODE`) |
| `make wsl-all` | Build WSL images (uses `WSL_ARCHS`, `DATECODE`) |
| `make dist` | Move artifacts to `distdir-<DATECODE>/` |
| `make checksum` | Generate `sha256sum.txt` in distdir |

**Required variables:**
- `DATECODE` - defaults to `$(date -u +%Y%m%d)`
- `REPOSITORY` - XBPS mirror (default: `https://repo-default.voidlinux.org/current`)
- `SUDO` - prefix for privileged commands (default: `sudo`; use `SUDO=` in CI)

## Scripts and Usage

| Script | Purpose | Key Options |
|--------|---------|-------------|
| `mkiso.sh` | Wrapper for live ISOs with void-installer | `-a <arch>`, `-b <variant>`, `-d <date>`, `-r <repo>` |
| `mklive.sh` | Basic live ISO generator | `-a <arch>`, `-b <base-pkg>`, `-r <repo>`, `-c <cachedir>`, `-i <comp>`, `-s <comp>` |
| `mkrootfs.sh` | ROOTFS tarball generator | `<arch>`, `-b <base-pkg>`, `-r <repo>`, `-c <cachedir>`, `-x <threads>` |
| `mkplatformfs.sh` | PLATFORMFS from ROOTFS | `<platform> <rootfs-tarball>`, `-b`, `-c`, `-r`, `-p <pkgs>`, `-x <threads>` |
| `mkimage.sh` | Disk image from PLATFORMFS | `<platformfs-tarball>`, `-b <fstype>`, `-B <size>`, `-r <fstype>`, `-s <size>` |
| `mknet.sh` | Netboot tarball from ROOTFS | `<rootfs-tarball>`, `-r`, `-c`, `-i <comp>`, `-K <kernel>` |

## Architecture/Platform Mapping
Defined in `Makefile` and `lib.sh:platform2arch()`:

- **Live ISOs**: `i686`, `x86_64`, `x86_64-musl`, `aarch64`, `aarch64-musl`, `asahi`, `asahi-musl`
- **ROOTFS**: many arches including `armv6l`, `armv7l`, `ppc64le`, `riscv64`, etc.
- **Platforms**: `rpi-armv6l`, `rpi-armv7l`, `rpi-aarch64`, `pinebookpro`, `pinephone`, `rock64`, `rockpro64`, `asahi`, `GCP`, `i686`, `x86_64`
- Platform → arch mapping in `lib.sh:set_target_arch_from_platform()`

## CI Build (GitHub Actions)
- Workflow: `.github/workflows/gen-images.yml` (manual dispatch)
- Container: `ghcr.io/void-linux/void-mklive:20250116R1` (privileged, `/dev:/dev`)
- Builds run in matrix across arches/platforms/flavors
- Artifacts uploaded per matrix entry, merged in `merge-artifacts` job
- Release via `release.sh start` (triggers workflow) and `release.sh dl` (downloads)

## Key Environment Variables
| Variable | Purpose |
|----------|---------|
| `XBPS_REPOSITORY` | XBPS repo URLs (space-separated `--repository=...`) |
| `XBPS_CACHEDIR` | Target package cache dir |
| `XBPS_HOST_CACHEDIR` | Host package cache dir |
| `XBPS_TARGET_ARCH` | Target arch for cross-builds (triggers qemu-binfmt) |
| `MKLIVE_REV` | Git revision for version string |
| `KEEP_BUILDDIR` | Set to preserve build directory on failure |

## Common Gotchas
1. **Must run as root** - scripts check `id -u` and exit if not root
2. **Void Linux host required** - not guaranteed to work on other distros or in containers without the CI image
3. **Cross-builds need qemu-user-static** - `lib.sh:register_binfmt()` sets up binfmt_misc
4. **DATECODE consistency** - use same `DATECODE` across all make targets for a release
5. **PLATFORMFS requires ROOTFS first** - Makefile dependency: `void-<platform>-PLATFORMFS` depends on `void-<arch>-ROOTFS`
6. **Musl variants** - append `-musl` to arch (e.g., `x86_64-musl`, `aarch64-musl`)
7. **Bootloaders**: x86 uses syslinux + grub (hybrid ISO), ARM64 uses grub only (EFI)
8. **Cleanup**: `mklive.sh` traps INT/TERM and cleans up mounts + build dir unless `KEEP_BUILDDIR=1`

## Versioning
- Version in `version` file (currently `0.26`)
- Git short SHA appended via `MKLIVE_REV` in `lib.sh:version()`

## Directory Structure
```
├── *.sh              # Main build scripts
├── lib.sh            # Shared functions (binfmt, chroot, pkg mgmt)
├── Makefile          # Build orchestration
├── version           # Version number
├── keys/             # XBPS repo public keys
├── dracut/           # Dracut modules (vmklive, autoinstaller)
├── grub/             # GRUB configs
├── isolinux/         # Syslinux configs
├── platforms/        # Platform-specific configs (pinebookpro.sh, x13s.sh)
├── data/             # Splash, motd, issue
├── container/        # CI container definition
└── .github/workflows/ # CI pipelines
```