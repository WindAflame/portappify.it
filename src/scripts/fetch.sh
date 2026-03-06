#!/usr/bin/env bash
#
# fetch.sh - Download and prepare all dependencies
#
# Usage: bash scripts/fetch.sh
#
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/config.sh"

mkdir -p "$RESOURCES"

# ── PortableApps.com template ────────────────────────────────────────────
if [ ! -d "$TEMPLATE" ]; then
    if [ ! -f "$TEMPLATE_ZIP" ]; then
        echo "==> Downloading PortableApps.com Application Template ${TEMPLATE_VERSION}..."
        curl -L -o "$TEMPLATE_ZIP" "$TEMPLATE_URL"
    fi
    echo "==> Extracting template..."
    mkdir -p "$TEMPLATE_DIR"
    unzip -qo "$TEMPLATE_ZIP" -d "$TEMPLATE_DIR"
else
    echo "==> Template already present"
fi

# ── Sonic 3 A.I.R. ──────────────────────────────────────────────────────
if [ ! -d "$GAME" ]; then
    if [ ! -f "$GAME_ZIP" ]; then
        echo "==> Downloading Sonic 3 A.I.R. (${GAME_VERSION})..."
        curl -L -o "$GAME_ZIP" "$GAME_URL"
    fi
    echo "==> Extracting Sonic 3 A.I.R...."
    unzip -qo "$GAME_ZIP" -d "$RESOURCES"
    # Zip extracts to sonic3air_game/ — rename to expected name
    extracted="$RESOURCES/sonic3air_game"
    if [ -d "$extracted" ] && [ ! -d "$GAME" ]; then
        mv "$extracted" "$GAME"
    fi
    if [ ! -d "$GAME" ]; then
        echo "ERROR: Could not find extracted game folder. Please extract manually to:" >&2
        echo "  $GAME" >&2
        exit 1
    fi
else
    echo "==> Game already present"
fi

# ── ROM ──────────────────────────────────────────────────────────────────
if [ -f "$ROM_STAGING" ]; then
    echo "==> ROM already present"
elif [ -n "$ROM_PATH" ] && [ -f "$ROM_PATH" ]; then
    echo "==> Copying ROM from: $ROM_PATH"
    cp "$ROM_PATH" "$ROM_STAGING"
else
    echo ""
    echo "WARNING: ROM file not found!"
    if [ -n "$ROM_PATH" ]; then
        echo "  ROM_PATH is set but file does not exist: $ROM_PATH"
    else
        echo "  ROM_PATH is not set in .env"
    fi
    echo ""
    echo "  Sonic 3 A.I.R. requires a Sonic 3 & Knuckles ROM to play."
    echo "  See this guide on how to obtain one:"
    echo "  $ROM_FAQ_URL"
    echo ""
    echo "  Then set ROM_PATH in .env or place the file as:"
    echo "  $ROM_STAGING"
    echo ""
fi

# ── Validate ─────────────────────────────────────────────────────────────
for path in "$TEMPLATE" "$GAME" "$SRC"; do
    if [ ! -d "$path" ]; then
        echo "ERROR: Required directory not found: $path" >&2
        exit 1
    fi
done

echo "==> All prerequisites ready"
