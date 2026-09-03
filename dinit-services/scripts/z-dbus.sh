#!/bin/sh
# dbus-daemon needs its runtime dir and a machine-id before starting.
mkdir -p /run/dbus
[ -s /etc/machine-id ] || /usr/bin/dbus-uuidgen --ensure
exec /usr/bin/dbus-daemon --system --nofork
