#!/bin/sh
# Nothing else sets the hostname under dinit (runit did it in stage 1).
if [ -s /etc/hostname ]; then
    read -r _hostname < /etc/hostname
    echo "${_hostname}" > /proc/sys/kernel/hostname
fi
