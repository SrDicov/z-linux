#!/bin/sh
modprobe zram 2>/dev/null || exit 0
[ -e /dev/zram0 ] || exit 0
zramctl /dev/zram0 -s 2G -a lz4 || exit 0
mkswap /dev/zram0 >/dev/null 2>&1 && swapon /dev/zram0 -p 100
exit 0
