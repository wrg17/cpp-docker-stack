#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC_DIR="backend"
BUILD_DIR="$SRC_DIR/build"

mkdir -p "$BUILD_DIR"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug
cmake --build "$BUILD_DIR" -j

"$BUILD_DIR/cpp_server"
