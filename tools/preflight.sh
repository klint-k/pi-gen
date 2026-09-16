#!/bin/bash

STAGE="$HOME/pinode-os/stage"
ERRORS=0

echo "PiNode preflight"
echo "==============="

echo
echo "Checking shell scripts..."
while IFS= read -r file
do
    if ! bash -n "$file"; then
        echo "FAIL: $file"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$STAGE" -type f -name '*.sh')

echo
echo "Checking Python..."
while IFS= read -r file
do
    if ! python3 -m py_compile "$file"; then
        echo "FAIL: $file"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$STAGE" -type f -name '*.py')

echo
echo "Checking JSON..."
while IFS= read -r file
do
    if ! python3 -m json.tool "$file" >/dev/null; then
        echo "FAIL: $file"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$STAGE" -type f -name '*.json')

echo
echo "Checking executable run scripts..."
while IFS= read -r file
do
    if [ ! -x "$file" ]; then
        echo "FAIL: not executable: $file"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$STAGE" -type f \( -name '*run.sh' -o -name '*run-chroot.sh' \))

echo
echo "Checking for __pycache__..."
find "$STAGE" -type d -name '__pycache__' -print

echo
echo "Checking old PiNode SSH path..."
grep -R "/var/lib/pinode/ssh" "$STAGE" \
    --exclude-dir="__pycache__" \
    2>/dev/null

echo
if [ "$ERRORS" -eq 0 ]; then
    echo "Preflight passed."
    exit 0
fi

echo "Preflight failed: $ERRORS error(s)."
exit 1
"""


~/pi-gen/tools/clean-work.sh

"""
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
