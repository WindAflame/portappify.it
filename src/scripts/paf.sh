#!/usr/bin/env bash
#
# paf.sh - Generate a PortableApps.com installer (.paf.exe)
#
# Requires the PortableApps.com Installer tool (Windows-only exe).
# Detection order:
#   1. PA_TOOL_PATH in .env  (explicit path, highest priority)
#   2. Common Windows installation paths (auto-detect)
#   3. resources/PortableApps.comInstaller/ (local cache from a previous download)
#   4. Download from PortableApps.com + extract with 7-Zip (fallback)
#
# Usage: bash src/scripts/paf.sh
#
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/config.sh"

# ── OS check ─────────────────────────────────────────────────────────────────
_is_windows() {
    case "$OSTYPE" in
        msys*|cygwin*) return 0 ;;
        linux*)
            # WSL: Windows interop lets us run .exe directly
            grep -qi microsoft /proc/version 2>/dev/null && return 0
            ;;
    esac
    return 1
}

if ! _is_windows; then
    echo "ERROR: paf.sh requires Windows (Git Bash, MSYS2, or WSL)." >&2
    echo "       The PortableApps.com Installer only runs on Windows." >&2
    exit 1
fi

# ── Build check ───────────────────────────────────────────────────────────────
if [ ! -d "$BUILD" ]; then
    echo "ERROR: Build output not found at $BUILD" >&2
    echo "       Run 'bash build.sh' first." >&2
    exit 1
fi

# ── Path helpers ─────────────────────────────────────────────────────────────

# Convert a Windows path (C:\...) to the native shell path (/mnt/c/... or /c/...)
_to_native_path() {
    local p="$1"
    # Already a Unix-style path — return as-is
    [[ "$p" =~ ^[A-Za-z]:[/\\] ]] || { echo "$p"; return; }
    if command -v wslpath &>/dev/null; then
        wslpath -u "$p"
    elif command -v cygpath &>/dev/null; then
        cygpath -u "$p"
    else
        # Fallback: C:\foo\bar → /mnt/c/foo/bar
        local drive rest
        drive="${p:0:1}"
        rest="${p:2}"
        rest="${rest//\\//}"
        echo "/mnt/${drive,,}${rest}"
    fi
}

# ── Locate PortableApps.comInstaller.exe ─────────────────────────────────────
_find_tool() {
    # 1. Explicit path from .env (handles both Windows and Unix paths)
    if [ -n "$PA_TOOL_PATH" ]; then
        local native
        native="$(_to_native_path "$PA_TOOL_PATH")"
        if [ -f "$native" ]; then
            echo "$native"
            return 0
        fi
        echo "WARNING: PA_TOOL_PATH is set but file not found: $PA_TOOL_PATH" >&2
    fi

    # 2. Common installation paths
    # Resolve home directory: prefer USERPROFILE (Windows env var passed through WSL)
    local win_home="/mnt/c/Users/$USER"
    if [ -n "${USERPROFILE:-}" ]; then
        win_home="$(_to_native_path "$USERPROFILE")"
    fi

    local common_paths=(
        # PortableApps.com Platform — user AppData install (WSL)
        "$win_home/AppData/Local/PortableApps.com/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        # PortableApps portable platform on C: or D: (WSL)
        "/mnt/c/PortableApps/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        "/mnt/d/PortableApps/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        # Program Files (WSL)
        "/mnt/c/Program Files/PortableApps.com/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        "/mnt/c/Program Files (x86)/PortableApps.com/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        # Git Bash / MSYS2 paths
        "/c/PortableApps/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        "/c/Program Files/PortableApps.com/PortableApps.comInstaller/PortableApps.comInstaller.exe"
        "/c/Program Files (x86)/PortableApps.com/PortableApps.comInstaller/PortableApps.comInstaller.exe"
    )
    for p in "${common_paths[@]}"; do
        if [ -f "$p" ]; then
            echo "$p"
            return 0
        fi
    done

    # 3. Local cache (previous download)
    if [ -f "$PA_TOOL_CACHE_EXE" ]; then
        echo "$PA_TOOL_CACHE_EXE"
        return 0
    fi

    return 1
}

# ── Download + extract fallback ───────────────────────────────────────────────
_download_tool() {
    # 7-Zip is needed to extract the .paf.exe (NSIS archive)
    local seven_z=""
    for candidate in 7z 7za "/c/Program Files/7-Zip/7z.exe" "/c/Program Files (x86)/7-Zip/7z.exe"; do
        if command -v "$candidate" &>/dev/null || [ -f "$candidate" ]; then
            seven_z="$candidate"
            break
        fi
    done

    if [ -z "$seven_z" ]; then
        echo "ERROR: 7-Zip not found. Cannot extract the PortableApps.com Installer." >&2
        echo "  Either:" >&2
        echo "    - On WSL: sudo apt-get install p7zip-full" >&2
        echo "    - On Windows: install 7-Zip from https://7-zip.org and add it to PATH" >&2
        echo "    - Or set PA_TOOL_PATH in .env to point to an existing PortableApps.comInstaller.exe" >&2
        exit 1
    fi

    if [ ! -f "$PA_TOOL_PAF" ]; then
        echo "==> Downloading PortableApps.com Installer ${PA_INSTALLER_VERSION}..."
        curl -L -o "$PA_TOOL_PAF" "$PA_TOOL_URL"
    fi

    echo "==> Extracting PortableApps.com Installer..."
    mkdir -p "$PA_TOOL_CACHE_DIR"
    "$seven_z" x "$PA_TOOL_PAF" -o"$PA_TOOL_CACHE_DIR" -y -bso0 -bsp0

    # The exe may be nested inside a subfolder after extraction
    local found
    found=$(find "$PA_TOOL_CACHE_DIR" -name "PortableApps.comInstaller.exe" | head -1)
    if [ -z "$found" ]; then
        echo "ERROR: PortableApps.comInstaller.exe not found after extraction." >&2
        echo "  The downloaded archive may have a different structure for version ${PA_INSTALLER_VERSION}." >&2
        echo "  Try setting PA_TOOL_PATH manually in .env." >&2
        exit 1
    fi

    # Normalise: move exe to the expected location if it landed in a subfolder
    if [ "$found" != "$PA_TOOL_CACHE_EXE" ]; then
        mv "$found" "$PA_TOOL_CACHE_EXE"
    fi

    echo "$PA_TOOL_CACHE_EXE"
}

# ── Resolve the tool ──────────────────────────────────────────────────────────
PA_EXE=""
if PA_EXE="$(_find_tool)"; then
    echo "==> Installer tool: $PA_EXE"
else
    echo "==> PortableApps.com Installer not found locally — downloading..."
    PA_EXE="$(_download_tool)"
    echo "==> Installer tool: $PA_EXE"
fi

# ── Convert build path to Windows format ─────────────────────────────────────
_to_win_path() {
    if command -v cygpath &>/dev/null; then
        cygpath -w "$1"
    elif command -v wslpath &>/dev/null; then
        wslpath -w "$1"
    else
        echo "$1"
    fi
}

BUILD_WIN="$(_to_win_path "$BUILD")"

# ── Run the installer ─────────────────────────────────────────────────────────
# PA_EXE is always a native Linux/WSL path (/mnt/c/...) — WSL2 interop runs it.
# The argument must be a Windows path (C:\...) for the installer to understand it.
echo "==> Generating .paf.exe installer..."
"$PA_EXE" "$BUILD_WIN"

# ── Move output to dist/ ──────────────────────────────────────────────────────
BUILD_PARENT="$(dirname "$BUILD")"
PAF="$(find "$BUILD_PARENT" -maxdepth 1 -name "*.paf.exe" 2>/dev/null | head -1)"

if [ -z "$PAF" ]; then
    echo "ERROR: No .paf.exe found in $(dirname "$BUILD") after running the installer." >&2
    echo "  The installer may have failed silently. Check that appinfo.ini is valid." >&2
    exit 1
fi

mkdir -p "$DIST"
mv "$PAF" "$DIST/"

echo ""
echo "PAF: $DIST/$(basename "$PAF")"
echo "Size: $(du -sh "$DIST/$(basename "$PAF")" | cut -f1)"
