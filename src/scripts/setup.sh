#!/usr/bin/env bash
#
# setup.sh - Check and install required system packages
#
# Usage: bash scripts/setup.sh
#
set -euo pipefail

REQUIRED_CMDS=(curl unzip rsync sed grep)

missing=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
    fi
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "All required packages are installed."
    exit 0
fi

echo "Missing packages: ${missing[*]}"

# Detect package manager and install
if command -v apt-get &>/dev/null; then
    echo "==> Installing with apt-get..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${missing[@]}"
elif command -v dnf &>/dev/null; then
    echo "==> Installing with dnf..."
    sudo dnf install -y -q "${missing[@]}"
elif command -v pacman &>/dev/null; then
    echo "==> Installing with pacman..."
    sudo pacman -S --noconfirm "${missing[@]}"
elif command -v apk &>/dev/null; then
    echo "==> Installing with apk..."
    sudo apk add --quiet "${missing[@]}"
else
    echo "ERROR: Could not detect a supported package manager (apt-get, dnf, pacman, apk)." >&2
    echo "Please install manually: ${missing[*]}" >&2
    exit 1
fi

echo "Done. All required packages are now installed."
