#!/usr/bin/env bash
#
# build.sh - Orchestrator: fetch dependencies + package
#
# Usage:
#   bash build.sh              # fetch + package
#   bash build.sh --zip        # fetch + package + ZIP
#   bash build.sh --paf        # fetch + package + PAF installer (Windows only)
#   bash build.sh --zip --paf  # all three
#
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)/src/scripts"

DO_ZIP=false
DO_PAF=false
for arg in "$@"; do
    case "$arg" in
        --zip) DO_ZIP=true ;;
        --paf) DO_PAF=true ;;
        *) echo "Unknown flag: $arg" >&2; exit 1 ;;
    esac
done

bash "$SCRIPTS_DIR/fetch.sh"
bash "$SCRIPTS_DIR/package.sh"

"$DO_ZIP" && bash "$SCRIPTS_DIR/zip.sh"
"$DO_PAF" && bash "$SCRIPTS_DIR/paf.sh"

true
