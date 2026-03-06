#!/usr/bin/env bash
#
# package.sh - Assemble Sonic 3 A.I.R. Portable package
#
# Usage: bash src/scripts/package.sh
#
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/config.sh"

# ── Read game version from metadata ─────────────────────────────────────
GAME_DISPLAY_VERSION=""
if [ -f "$METADATA_FILE" ]; then
    GAME_DISPLAY_VERSION=$(grep '"Version"' "$METADATA_FILE" | sed 's/.*: *"\(.*\)".*/\1/' | tr -d '\r')
fi
if [ -z "$GAME_DISPLAY_VERSION" ]; then
    echo "WARNING: Could not read game version from $METADATA_FILE"
    GAME_DISPLAY_VERSION="unknown"
fi

# ── Clean ────────────────────────────────────────────────────────────────
echo "==> Cleaning previous build..."
rm -rf "$BUILD"
mkdir -p "$BUILD"

# ── Launcher executable ─────────────────────────────────────────────────
echo "==> Copying launcher executable..."
cp "$TEMPLATE/AppNamePortable.exe" "$BUILD/Sonic3AIRPortable.exe"

# ── Game files (excluding bonus/) ────────────────────────────────────────
echo "==> Copying game files (excluding bonus/)..."
mkdir -p "$BUILD/App/Sonic3AIR"
rsync -a --exclude='bonus' --exclude="$ROM_FILENAME" "$GAME/" "$BUILD/App/Sonic3AIR/"

# ── AppInfo configs ──────────────────────────────────────────────────────
echo "==> Copying AppInfo configs..."
mkdir -p "$BUILD/App/AppInfo/Launcher"
cp "$SRC/App/AppInfo/appinfo.ini"                    "$BUILD/App/AppInfo/appinfo.ini"
cp "$SRC/App/AppInfo/installer.ini"                  "$BUILD/App/AppInfo/installer.ini"
cp "$SRC/App/AppInfo/Launcher/Sonic3AIRPortable.ini" "$BUILD/App/AppInfo/Launcher/Sonic3AIRPortable.ini"

# Patch version from game metadata
if [ "$GAME_DISPLAY_VERSION" != "unknown" ]; then
    package_version=$(echo "$GAME_DISPLAY_VERSION" | sed 's/\.0*/./g; s/^0*//')
    sed -i "s/^PackageVersion=.*/PackageVersion=${package_version}/" "$BUILD/App/AppInfo/appinfo.ini"
    sed -i "s/^DisplayVersion=.*/DisplayVersion=${GAME_DISPLAY_VERSION}/" "$BUILD/App/AppInfo/appinfo.ini"
fi

# ── Icons (template placeholders) ────────────────────────────────────────
echo "==> Copying icons..."
cp "$TEMPLATE/App/AppInfo/appicon.ico"     "$BUILD/App/AppInfo/appicon.ico"
cp "$TEMPLATE/App/AppInfo/appicon_16.png"  "$BUILD/App/AppInfo/appicon_16.png"
cp "$TEMPLATE/App/AppInfo/appicon_32.png"  "$BUILD/App/AppInfo/appicon_32.png"
cp "$TEMPLATE/App/AppInfo/appicon_75.png"  "$BUILD/App/AppInfo/appicon_75.png"
cp "$TEMPLATE/App/AppInfo/appicon_128.png" "$BUILD/App/AppInfo/appicon_128.png"

# ── Template Readme ──────────────────────────────────────────────────────
cp "$TEMPLATE/App/Readme.txt" "$BUILD/App/Readme.txt"

# ── DefaultData skeleton ─────────────────────────────────────────────────
mkdir -p "$BUILD/App/DefaultData/UserData"

# ── Help page ────────────────────────────────────────────────────────────
cp "$SRC/help.html" "$BUILD/help.html"

# ── Other/ assets ────────────────────────────────────────────────────────
echo "==> Copying Other/ assets..."
mkdir -p "$BUILD/Other/Help/Images"
mkdir -p "$BUILD/Other/Source"
cp "$TEMPLATE/Other/Help/Images/Donation_Button.png"        "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Favicon.ico"                "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Help_Background_Footer.png" "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Help_Background_Header.png" "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Help_Logo_Top.png"          "$BUILD/Other/Help/Images/"
cp "$SRC/Other/Source/Sonic3AIRPortable.ini" "$BUILD/Other/Source/Sonic3AIRPortable.ini"
cp "$TEMPLATE/Other/Source/LauncherLicense.txt" "$BUILD/Other/Source/LauncherLicense.txt"
cp "$SRC/Other/Source/Readme.txt" "$BUILD/Other/Source/Readme.txt"

# ── Data directory + ROM ─────────────────────────────────────────────────
mkdir -p "$BUILD/Data"
if [ -f "$ROM_STAGING" ]; then
    echo "==> Copying ROM to Data/..."
    cp "$ROM_STAGING" "$BUILD/Data/$ROM_FILENAME"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Build complete!"
echo "========================================="
echo ""
echo "Output: $BUILD"
echo ""

echo "Versions:"
echo "  Sonic 3 A.I.R.     : $GAME_DISPLAY_VERSION (release: $GAME_VERSION)"
echo "  PA.c Template      : $TEMPLATE_VERSION"
built_pkg_ver=$(grep '^PackageVersion=' "$BUILD/App/AppInfo/appinfo.ini" | cut -d= -f2)
built_dis_ver=$(grep '^DisplayVersion=' "$BUILD/App/AppInfo/appinfo.ini" | cut -d= -f2)
echo "  Package (appinfo)  : $built_dis_ver (PackageVersion=$built_pkg_ver)"
echo ""

if [ -f "$BUILD/Data/$ROM_FILENAME" ]; then
    echo "ROM: included (Data/$ROM_FILENAME)"
else
    echo "ROM: not included (add it to Data/ before running)"
fi
echo ""

total_size=$(du -sh "$BUILD" | cut -f1)
echo "Total size: $total_size"
