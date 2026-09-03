#!/bin/bash
ISO=$(ls -t void-live-x86_64-*.iso | head -n 1)
if [ -z "$ISO" ]; then
    echo "No ISO found!"
    exit 1
fi
echo "Booting $ISO in QEMU (serial log: vm-debug.log)..."
qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 -cdrom "$ISO" -boot d -vga virtio -serial file:vm-debug.log -display sdl,gl=on || \
qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 -cdrom "$ISO" -boot d -serial file:vm-debug.log
