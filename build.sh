#!/usr/bin/env bash
#
# build.sh - Orchestrator: fetch dependencies + package
#
# Usage: bash build.sh
#
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)/scripts"

bash "$SCRIPTS_DIR/fetch.sh"
bash "$SCRIPTS_DIR/package.sh"
