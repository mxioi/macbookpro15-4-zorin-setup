#!/bin/bash
# Setup T2 Audio Configuration for Microphone
# Source: https://github.com/kekrby/t2-better-audio

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up T2 audio configuration..."
echo ""

if [ -f "$SCRIPT_DIR/fix_mic.sh" ]; then
    bash "$SCRIPT_DIR/fix_mic.sh"
else
    echo "Error: fix_mic.sh not found in $SCRIPT_DIR"
    exit 1
fi

echo ""
echo "Microphone setup complete"
echo ""
