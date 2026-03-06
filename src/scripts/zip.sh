#!/usr/bin/env bash
#
# zip.sh - Create a ZIP distribution of the built package
#
# Usage: bash src/scripts/zip.sh
#
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/config.sh"

# ── Pre-checks ────────────────────────────────────────────────────────────────
if [ ! -d "$BUILD" ]; then
    echo "ERROR: Build output not found at $BUILD" >&2
    echo "       Run 'bash build.sh' first." >&2
    exit 1
fi

# ── Read version from the built package ──────────────────────────────────────
APPINFO="$BUILD/App/AppInfo/appinfo.ini"
VERSION=$(grep '^DisplayVersion=' "$APPINFO" 2>/dev/null | cut -d= -f2 || true)
[ -z "$VERSION" ] && VERSION="unknown"

# ── Create archive ────────────────────────────────────────────────────────────
mkdir -p "$DIST"
ZIP_NAME="Sonic3AIRPortable_${VERSION}_no-rom.zip"
ZIP_PATH="$DIST/$ZIP_NAME"

echo "==> Creating ZIP: $ZIP_NAME"
(cd "$(dirname "$BUILD")" && zip -r "$ZIP_PATH" "$(basename "$BUILD")/")

echo ""
echo "ZIP: $ZIP_PATH"
echo "Size: $(du -sh "$ZIP_PATH" | cut -f1)"
