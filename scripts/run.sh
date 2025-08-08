#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC_DIR="backend"
PRESET="${1:-debug}"

cd "$SRC_DIR"

cmake --preset "$PRESET"
cmake --build --preset "$PRESET" --parallel

"./build/${PRESET}/cpp_server"
