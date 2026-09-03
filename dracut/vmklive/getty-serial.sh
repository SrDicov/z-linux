#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

CONSOLE=$(getarg console)
if [ -d "${NEWROOT}/etc/dinit.d" ]; then
    case "$CONSOLE" in
    *ttyS0*) ln -s ../agetty-ttyS0 "${NEWROOT}/etc/dinit.d/boot.d/agetty-ttyS0" ;;
    *hvc0*)  ln -s ../agetty-hvc0 "${NEWROOT}/etc/dinit.d/boot.d/agetty-hvc0" ;;
    *hvsi0*) ln -s ../agetty-hvsi0 "${NEWROOT}/etc/dinit.d/boot.d/agetty-hvsi0" ;;
    esac
else
    case "$CONSOLE" in
    *ttyS0*) ln -s /etc/sv/agetty-ttyS0 ${NEWROOT}/etc/runit/runsvdir/default/ ;;
    *hvc0*)  ln -s /etc/sv/agetty-hvc0 ${NEWROOT}/etc/runit/runsvdir/default/ ;;
    *hvsi0*) ln -s /etc/sv/agetty-hvsi0 ${NEWROOT}/etc/runit/runsvdir/default/ ;;
    esac
fi
