#!/bin/sh
# Pseudofs may already be mounted by the initramfs; only mount what is missing.
mountpoint -q /proc || mount -t proc proc /proc -o nosuid,noexec,nodev
mountpoint -q /sys || mount -t sysfs sys /sys -o nosuid,noexec,nodev
mountpoint -q /dev || mount -t devtmpfs dev /dev -o mode=0755,nosuid
mkdir -p /sys/fs/cgroup
mountpoint -q /sys/fs/cgroup || mount -t cgroup2 cgroup2 /sys/fs/cgroup -o nosuid,noexec,nodev
