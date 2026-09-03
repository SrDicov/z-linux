#!/bin/sh -x
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getargbool >/dev/null 2>&1 || . /lib/dracut-lib.sh

if getargbool 0 live.accessibility; then
    if [ -d "${NEWROOT}/etc/dinit.d" ]; then
        [ -f "${NEWROOT}/etc/dinit.d/espeakup" ] && ln -s ../espeakup "${NEWROOT}/etc/dinit.d/boot.d/espeakup"
        [ -f "${NEWROOT}/etc/dinit.d/brltty" ] && ln -s ../brltty "${NEWROOT}/etc/dinit.d/boot.d/brltty"
    else
        [ -d "${NEWROOT}/etc/sv/espeakup" ] && ln -s "/etc/sv/espeakup" "${NEWROOT}/etc/runit/runsvdir/current/"
        [ -d "${NEWROOT}/etc/sv/brltty" ] && ln -s "/etc/sv/brltty" "${NEWROOT}/etc/runit/runsvdir/current/"
    fi
fi
