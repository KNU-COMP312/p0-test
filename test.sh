#!/bin/bash

if [ -z "$PINTOS_HOME" ]; then
      echo "[ERROR] PINTOS_HOME is not set. Please set it before running this
      script."
          exit 1
fi

# Set Pintos project path (based on the script location)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PINTOS_KERNEL="$PINTOS_HOME/threads/build/kernel.bin"
PINTOS_OUTPUT="$PINTOS_HOME/pintos_output.txt"

# Set PATH
export PATH=$PATH:$PINTOS_HOME/utils

# Get Git repository name
GIT_REPO=$(basename "$(git remote get-url origin 2>/dev/null)" 2>/dev/null)
if [ -z "$GIT_REPO" ]; then
    echo "[ERROR] Could not determine Git repository name."
    exit 1
fi
echo "[INFO] Git Repository Name: $GIT_REPO"

# 1. Build Pintos and verify success
echo "[INFO] Building Pintos..."
cd "$PINTOS_HOME/threads" || exit 1
make clean > /dev/null 2>&1  # Clean previous build
make > /dev/null 2>&1        # Build Pintos

# Check if kernel.bin exists after the build
if [ ! -f "$PINTOS_KERNEL" ]; then
    echo "[ERROR] Build failed. kernel.bin not found."
    exit 1
fi

echo "[INFO] Build successful."

# 2. Check if the Git repository name is included in kernel.bin
if ! strings "$PINTOS_KERNEL" | grep -q "$GIT_REPO"; then
    echo "[ERROR] Git repository name not found in kernel.bin"
    exit 1
fi

# 3. Run test test 
echo "[INFO] Running Pintos: alarm-single..."
cd "$PINTOS_HOME/threads/build" || exit 1
make tests/threads/alarm-single.result | tee "$PINTOS_OUTPUT"

if ! grep -q "pass tests/threads/alarm-single" "$PINTOS_OUTPUT"; then
    echo "[ERROR] Pintos basic test failed!"
    cat "$PINTOS_OUTPUT"  # Show output for debugging
    exit 1
fi

echo "[SUCCESS] All test passed!"
exit 0
