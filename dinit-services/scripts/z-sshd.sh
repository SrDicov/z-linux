#!/bin/sh
# sshd refuses to start without host keys; generate them on first start.
[ -f /etc/ssh/ssh_host_ed25519_key ] || /usr/bin/ssh-keygen -A
exec /usr/bin/sshd -D
