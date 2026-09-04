#!/bin/sh
# Create the live user's XDG_RUNTIME_DIR. There is no elogind/systemd in the
# live image, so nothing else creates /run/user/<uid> before the session
# starts on tty1.
. /etc/default/live.conf 2>/dev/null || USERNAME=anon

uid=$(id -u "$USERNAME" 2>/dev/null) || exit 0
gid=$(id -g "$USERNAME" 2>/dev/null) || exit 0

install -d -m 700 -o "$uid" -g "$gid" "/run/user/$uid"
exit 0
