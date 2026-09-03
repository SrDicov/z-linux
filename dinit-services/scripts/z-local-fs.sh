#!/bin/sh
# The live overlay root is already rw; a failed remount must not fail the service.
mount -o remount,rw / 2>/dev/null || :
exit 0
