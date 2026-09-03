#!/bin/sh
# Z Linux Dinit injection
# Ensure /sbin/init points to dinit
if [ -x "${NEWROOT}/usr/bin/dinit" ]; then
    ln -sf /usr/bin/dinit "${NEWROOT}/sbin/init"
    # Create empty mtab
    > "${NEWROOT}/etc/mtab"
fi
