#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$BASE_DIR/work"

echo "pi-gen work cleanup"
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
echo "Removing old pi-gen work directories..."

find "$WORK" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -print \
    -exec sudo rm -rf {} \;

echo
echo "Cleanup complete."
