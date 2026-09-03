#!/bin/sh
# Driver loading (mdevd coldplug) and interface renaming (eth0 -> ens3, done
# by the initramfs udev) are asynchronous; dhcpcd's manager does not reliably
# pick up interfaces that already exist when it starts, but configuring a
# concrete interface always works. Wait for a real NIC, let names settle,
# then hand dhcpcd the explicit interface names.
i=0
ifaces=""
while [ "$i" -lt 30 ]; do
    ifaces=""
    for ifdir in /sys/class/net/*; do
        [ -d "$ifdir" ] || continue
        case "${ifdir##*/}" in
            lo) ;;
            *) ifaces="$ifaces ${ifdir##*/}" ;;
        esac
    done
    [ -n "$ifaces" ] && break
    i=$((i+1))
    sleep 1
done
# Let interface renaming settle before freezing the names into the command.
sleep 2
exec /usr/bin/dhcpcd -q -B $ifaces
