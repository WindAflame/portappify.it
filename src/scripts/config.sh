#!/usr/bin/env bash
#
# config.sh - Shared configuration for all build scripts
#
# Usage: source src/scripts/config.sh
#

# ── Project root ─────────────────────────────────────────────────────────
# Resolve from this script's location (src/scripts/ -> src/ -> project root)
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

# ── Load .env overrides ─────────────────────────────────────────────────
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source <(grep -E '^\s*[A-Z_]+=.' "$ENV_FILE" | tr -d '\r' || true)
    set +a
fi

# ── User-configurable (via .env) ────────────────────────────────────────
GAME_VERSION="${GAME_VERSION:-v24.02.02.0-stable}"
TEMPLATE_VERSION="${TEMPLATE_VERSION:-3.9.0}"
ROM_PATH="${ROM_PATH:-}"

# ── Derived paths ────────────────────────────────────────────────────────
RESOURCES="$PROJECT_ROOT/resources"
SRC="$PROJECT_ROOT/src/template"
BUILD="$PROJECT_ROOT/build/Sonic3AIRPortable"

TEMPLATE_ZIP="$RESOURCES/PortableApps.com_Application_Template_${TEMPLATE_VERSION}.zip"
TEMPLATE_DIR="$RESOURCES/PortableApps.com_Application_Template_${TEMPLATE_VERSION}"
TEMPLATE="$TEMPLATE_DIR/AppNamePortable"

GAME_ZIP="$RESOURCES/sonic3air_game.zip"
GAME="$RESOURCES/Sonic 3 A.I.R"

ROM_FILENAME="Sonic_Knuckles_wSonic3.bin"
ROM_STAGING="$GAME/$ROM_FILENAME"
METADATA_FILE="$GAME/data/metadata.json"

# ── URLs ─────────────────────────────────────────────────────────────────
TEMPLATE_URL="https://downloads.sourceforge.net/portableapps/PortableApps.com_Application_Template_${TEMPLATE_VERSION}.zip"
GAME_URL="https://github.com/Eukaryot/sonic3air/releases/download/${GAME_VERSION}/sonic3air_game.zip"
ROM_FAQ_URL="https://docs.google.com/document/d/1oSud8dJHvdfrYbkGCfllAOp3JuTks7z4K5SwtVkXkx0"
