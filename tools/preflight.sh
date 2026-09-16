#!/bin/bash

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

echo "pi-gen preflight"
echo "================"

echo
echo "Checking shell scripts..."

while IFS= read -r file
do
    if ! bash -n "$file"; then
        echo "FAIL: $file"
        ERRORS=$((ERRORS + 1))
    fi

done < <(
    find "$BASE_DIR" \
        -path "$BASE_DIR/work" -prune -o \
        -type f \
        -name '*.py' \
        -print
)


echo
echo "Checking Python..."

while IFS= read -r file
do
    if ! python3 -c \
        'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' \
        "$file"
    then
        echo "FAIL: $file"
        ERRORS=$((ERRORS + 1))
    fi

done < <(
    find "$BASE_DIR" \
        -path "$BASE_DIR/work" -prune -o \
        -type f \
        -name '*.py' \
        -print
)


echo
echo "Checking JSON..."

while IFS= read -r file
do
    if ! python3 -m json.tool "$file" >/dev/null
    then
        echo "FAIL: $file"
        ERRORS=$((ERRORS + 1))
    fi

done < <(
    find "$BASE_DIR" \
        -path "$BASE_DIR/work" -prune -o \
        -path "$BASE_DIR/export-noobs/00-release/files/partitions.json" -prune -o \
        -type f \
        -name '*.json' \
        -print
)


echo
echo "Checking executable run scripts..."

while IFS= read -r file
do
    if [ ! -x "$file" ]; then
        echo "FAIL: not executable: $file"
        ERRORS=$((ERRORS + 1))
    fi

done < <(
    find "$BASE_DIR" \
        -path "$BASE_DIR/work" -prune -o \
        -type f \
        \( \
            -name '*run.sh' \
            -o -name '*run-chroot.sh' \
        \) \
        -print
)

echo
echo "Checking for first-user ownership from build host..."

while IFS= read -r line
do
    echo "FAIL: possible build-host user/group reference:"
    echo "      $line"
    ERRORS=$((ERRORS + 1))

done < <(
    grep -R -n -E \
        'install .*(-o pi|-g pi)|chown +pi:pi' \
        "$BASE_DIR" \
        --include='*.sh' \
        --exclude='preflight.sh' \
        --exclude-dir='work' \
        2>/dev/null || true
)


echo
echo "Checking configuration..."

CONFIG_FILE=""

if [ -n "${CONFIG_FILE:-}" ] && [ -f "$CONFIG_FILE" ]; then
    :
elif [ -n "${CONFIG:-}" ] && [ -f "$CONFIG" ]; then
    CONFIG_FILE="$CONFIG"
fi

if [ -n "$CONFIG_FILE" ]; then

    FIRST_USER_NAME=$(
        awk -F= '
            /^FIRST_USER_NAME=/ {
                value=$2
                gsub(/^'\''|'\''$/, "", value)
                gsub(/^"|"$/, "", value)
                print value
            }
        ' "$CONFIG_FILE"
    )

    if [ -n "$FIRST_USER_NAME" ]; then
        echo "Configured first user: $FIRST_USER_NAME"
    else
        echo "WARNING: FIRST_USER_NAME not found in config"
    fi

else
    echo "No config file supplied; skipping user consistency checks."
fi


echo
if [ "$ERRORS" -eq 0 ]; then
    echo "Preflight passed."
    exit 0
fi

echo "Preflight failed: $ERRORS error(s)."
exit 1
