#!/bin/bash

WORK="$HOME/pi-gen/work"

echo "Pi-gen work cleanup"
echo "==================="

if [ ! -d "$WORK" ]; then
    echo "No work directory."
    exit 0
fi

echo
echo "Unmounting stale pi-gen mounts..."

mount | awk -v work="$WORK" '
    index($3, work) == 1 { print $3 }
' | sort -r | while read -r mountpoint
do
    echo "Unmounting: $mountpoint"
    sudo umount "$mountpoint" 2>/dev/null || true
done

echo
echo "Removing old PiNode work directories..."

find "$WORK" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -name 'pinode-*' \
    -print \
    -exec sudo rm -rf {} \;

echo
echo "Cleanup complete."
