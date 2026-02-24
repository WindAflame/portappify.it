#!/usr/bin/env bash
#
# build.sh - Assemble Sonic 3 A.I.R. Portable (PortableApps.com package)
#
# Usage: bash build.sh   (from project root)
#
set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# ── Load .env (user overrides) ──────────────────────────────────────────
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source <(grep -E '^\s*[A-Z_]+=.' "$ENV_FILE" | tr -d '\r' || true)
    set +a
    echo "==> Loaded config from .env"
else
    echo "==> No .env file found, using defaults (copy .env.example to .env to customize)"
fi

# ── Defaults (overridable via .env) ─────────────────────────────────────
GAME_VERSION="${GAME_VERSION:-v24.02.02.0-stable}"
TEMPLATE_VERSION="${TEMPLATE_VERSION:-3.9.0}"
ROM_PATH="${ROM_PATH:-}"

# ── Derived paths ───────────────────────────────────────────────────────
RESOURCE="$PROJECT_ROOT/resources"
TEMPLATE_ZIP="$RESOURCE/PortableApps.com_Application_Template_${TEMPLATE_VERSION}.zip"
TEMPLATE_DIR="$RESOURCE/PortableApps.com_Application_Template_${TEMPLATE_VERSION}"
TEMPLATE="$TEMPLATE_DIR/AppNamePortable"
GAME_ZIP="$RESOURCE/sonic3air_game.zip"
GAME="$RESOURCE/Sonic 3 A.I.R"
SRC="$PROJECT_ROOT/src"
BUILD="$PROJECT_ROOT/build/Sonic3AIRPortable"

TEMPLATE_URL="https://downloads.sourceforge.net/portableapps/PortableApps.com_Application_Template_${TEMPLATE_VERSION}.zip"
GAME_URL="https://github.com/Eukaryot/sonic3air/releases/download/${GAME_VERSION}/sonic3air_game.zip"
ROM_FAQ_URL="https://docs.google.com/document/d/1oSud8dJHvdfrYbkGCfllAOp3JuTks7z4K5SwtVkXkx0"

mkdir -p "$RESOURCE"

# ── Download PortableApps.com template if missing ────────────────────────
if [ ! -d "$TEMPLATE" ]; then
    if [ ! -f "$TEMPLATE_ZIP" ]; then
        echo "==> Downloading PortableApps.com Application Template ${TEMPLATE_VERSION}..."
        curl -L -o "$TEMPLATE_ZIP" "$TEMPLATE_URL"
    fi
    echo "==> Extracting template..."
    # Zip contains AppNamePortable/ at root — extract into the versioned dir
    mkdir -p "$TEMPLATE_DIR"
    unzip -qo "$TEMPLATE_ZIP" -d "$TEMPLATE_DIR"
fi

# ── Download Sonic 3 A.I.R. if missing ──────────────────────────────────
if [ ! -d "$GAME" ]; then
    if [ ! -f "$GAME_ZIP" ]; then
        echo "==> Downloading Sonic 3 A.I.R. (${GAME_VERSION})..."
        curl -L -o "$GAME_ZIP" "$GAME_URL"
    fi
    echo "==> Extracting Sonic 3 A.I.R...."
    unzip -qo "$GAME_ZIP" -d "$RESOURCE"
    # Zip extracts to sonic3air_game/ — rename to expected name
    EXTRACTED="$RESOURCE/sonic3air_game"
    if [ -d "$EXTRACTED" ] && [ ! -d "$GAME" ]; then
        mv "$EXTRACTED" "$GAME"
    fi
    if [ ! -d "$GAME" ]; then
        echo "ERROR: Could not find extracted game folder. Please extract manually to:" >&2
        echo "  $GAME" >&2
        exit 1
    fi
fi

# ── Check / copy ROM file ───────────────────────────────────────────────
ROM_DEST="$GAME/Sonic_Knuckles_wSonic3.bin"
if [ ! -f "$ROM_DEST" ]; then
    if [ -n "$ROM_PATH" ] && [ -f "$ROM_PATH" ]; then
        echo "==> Copying ROM from: $ROM_PATH"
        cp "$ROM_PATH" "$ROM_DEST"
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
        echo "  $ROM_DEST"
        echo ""
        echo "  The build will continue, but the game won't start without the ROM."
        echo ""
    fi
fi

# ── Sanity checks ────────────────────────────────────────────────────────
for path in "$TEMPLATE" "$GAME" "$SRC"; do
    if [ ! -d "$path" ]; then
        echo "ERROR: Required directory not found: $path" >&2
        exit 1
    fi
done

# ── Read game version from metadata.json ────────────────────────────────
GAME_DISPLAY_VERSION=""
METADATA_FILE="$GAME/data/metadata.json"
if [ -f "$METADATA_FILE" ]; then
    GAME_DISPLAY_VERSION=$(python3 -c "import json; print(json.load(open('$METADATA_FILE'))['Version'])" 2>/dev/null || true)
fi
if [ -z "$GAME_DISPLAY_VERSION" ]; then
    echo "WARNING: Could not read game version from $METADATA_FILE"
    GAME_DISPLAY_VERSION="unknown"
fi

# ── Step 0: Clean previous build ─────────────────────────────────────────
echo "==> Cleaning previous build..."
rm -rf "$BUILD"
mkdir -p "$BUILD"

# ── Step 1: Copy launcher .exe (renamed from template) ──────────────────
echo "==> Copying launcher executable..."
cp "$TEMPLATE/AppNamePortable.exe" "$BUILD/Sonic3AIRPortable.exe"

# ── Step 2: Copy game files (excluding bonus/) ──────────────────────────
echo "==> Copying game files (excluding bonus/)..."
mkdir -p "$BUILD/App/Sonic3AIR"
rsync -a --exclude='bonus' "$GAME/" "$BUILD/App/Sonic3AIR/"

# ── Step 3: Copy configs from src/ ──────────────────────────────────────
echo "==> Copying AppInfo configs..."
mkdir -p "$BUILD/App/AppInfo/Launcher"
cp "$SRC/App/AppInfo/appinfo.ini"                    "$BUILD/App/AppInfo/appinfo.ini"
cp "$SRC/App/AppInfo/installer.ini"                  "$BUILD/App/AppInfo/installer.ini"
cp "$SRC/App/AppInfo/Launcher/Sonic3AIRPortable.ini" "$BUILD/App/AppInfo/Launcher/Sonic3AIRPortable.ini"

# ── Step 3b: Patch appinfo.ini version from game metadata ───────────────
if [ "$GAME_DISPLAY_VERSION" != "unknown" ]; then
    # DisplayVersion = as-is from metadata (e.g. 21.09.12.0)
    # PackageVersion = dotted quad for Windows (strip leading zeros: 21.9.12.0)
    PACKAGE_VERSION=$(echo "$GAME_DISPLAY_VERSION" | sed 's/\.0*/./g; s/^0*//')
    sed -i "s/^PackageVersion=.*/PackageVersion=${PACKAGE_VERSION}/" "$BUILD/App/AppInfo/appinfo.ini"
    sed -i "s/^DisplayVersion=.*/DisplayVersion=${GAME_DISPLAY_VERSION}/" "$BUILD/App/AppInfo/appinfo.ini"
fi

# ── Step 4: Copy icons from template (default placeholders) ─────────────
echo "==> Copying icons..."
cp "$TEMPLATE/App/AppInfo/appicon.ico"     "$BUILD/App/AppInfo/appicon.ico"
cp "$TEMPLATE/App/AppInfo/appicon_16.png"  "$BUILD/App/AppInfo/appicon_16.png"
cp "$TEMPLATE/App/AppInfo/appicon_32.png"  "$BUILD/App/AppInfo/appicon_32.png"
cp "$TEMPLATE/App/AppInfo/appicon_75.png"  "$BUILD/App/AppInfo/appicon_75.png"
cp "$TEMPLATE/App/AppInfo/appicon_128.png" "$BUILD/App/AppInfo/appicon_128.png"

# ── Step 5: Copy template Readme.txt ────────────────────────────────────
echo "==> Copying App/Readme.txt..."
cp "$TEMPLATE/App/Readme.txt" "$BUILD/App/Readme.txt"

# ── Step 6: Create DefaultData skeleton ─────────────────────────────────
echo "==> Creating DefaultData/Sonic3AIR/ skeleton..."
mkdir -p "$BUILD/App/DefaultData/Sonic3AIR"

# ── Step 7: Copy help.html ──────────────────────────────────────────────
echo "==> Copying help.html..."
cp "$SRC/help.html" "$BUILD/help.html"

# ── Step 8: Copy Other/ assets ──────────────────────────────────────────
echo "==> Copying Other/ assets..."
mkdir -p "$BUILD/Other/Help/Images"
mkdir -p "$BUILD/Other/Source"

# Help images from template
cp "$TEMPLATE/Other/Help/Images/Donation_Button.png"        "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Favicon.ico"                "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Help_Background_Footer.png" "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Help_Background_Header.png" "$BUILD/Other/Help/Images/"
cp "$TEMPLATE/Other/Help/Images/Help_Logo_Top.png"          "$BUILD/Other/Help/Images/"

# Source files
cp "$SRC/Other/Source/Sonic3AIRPortable.ini" "$BUILD/Other/Source/Sonic3AIRPortable.ini"
cp "$TEMPLATE/Other/Source/LauncherLicense.txt" "$BUILD/Other/Source/LauncherLicense.txt"
cp "$SRC/Other/Source/Readme.txt" "$BUILD/Other/Source/Readme.txt"

# ── Step 9: Create empty Data/ directory ────────────────────────────────
echo "==> Creating Data/ directory..."
mkdir -p "$BUILD/Data"

# ── Summary ─────────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Build complete!"
echo "========================================="
echo ""
echo "Output: $BUILD"
echo ""

# Show versions
echo "Versions:"
echo "  Sonic 3 A.I.R.     : $GAME_DISPLAY_VERSION (release: $GAME_VERSION)"
echo "  PA.c Template      : $TEMPLATE_VERSION"
BUILT_PKG_VER=$(grep '^PackageVersion=' "$BUILD/App/AppInfo/appinfo.ini" | cut -d= -f2)
BUILT_DIS_VER=$(grep '^DisplayVersion=' "$BUILD/App/AppInfo/appinfo.ini" | cut -d= -f2)
echo "  Package (appinfo)  : $BUILT_DIS_VER (PackageVersion=$BUILT_PKG_VER)"
echo ""

# ROM status
if [ -f "$BUILD/App/Sonic3AIR/Sonic_Knuckles_wSonic3.bin" ]; then
    echo "ROM: included"
else
    echo "ROM: MISSING (game will not start)"
fi
echo ""

# Show size
TOTAL_SIZE=$(du -sh "$BUILD" | cut -f1)
echo "Total size: $TOTAL_SIZE"
echo ""