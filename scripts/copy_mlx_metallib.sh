#!/usr/bin/env bash
# Copies MLX's prebuilt default.metallib next to the Hayabusa binary as mlx.metallib.
# swift build does not compile Cmlx Metal shaders (see mlx-swift README); Xcode / xcodebuild does.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-release}"
BIN_DIR="$ROOT/.build/arm64-apple-macosx/$CONFIG"
EXEC="$BIN_DIR/Hayabusa"

if [[ ! -x "$EXEC" ]]; then
  echo "Hayabusa not found at $EXEC — run: swift build -c $CONFIG" >&2
  exit 1
fi

METAL=""
PKG="$(basename "$ROOT")"
DERIVED="${HOME}/Library/Developer/Xcode/DerivedData"

find_in_derived() {
  local variant="$1" # Release or Debug
  find "$DERIVED" -path "*${PKG}-*/Build/Products/${variant}/mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib" \
    2>/dev/null | head -1
}

if [[ -n "${MLX_METAL_LIB:-}" ]]; then
  METAL="$MLX_METAL_LIB"
elif [[ -n "${MLX_SWIFT_CHECKOUT:-}" ]]; then
  METAL="$(find "$MLX_SWIFT_CHECKOUT" -name default.metallib 2>/dev/null | head -1)"
else
  # Prefer the SwiftPM resource bundle when present (path varies by toolchain).
  METAL="$(find "$ROOT/.build" -path '*mlx-swift_Cmlx.bundle*' -name default.metallib 2>/dev/null | head -1)"
  if [[ -z "$METAL" ]]; then
    METAL="$(find "$ROOT/.build" -name default.metallib 2>/dev/null | head -1)"
  fi
  # Xcode often puts the bundle only under DerivedData, not under the package .build tree.
  if [[ -z "$METAL" ]]; then
    METAL="$(find_in_derived Release)" || METAL=""
  fi
  if [[ -z "$METAL" ]]; then
    METAL="$(find_in_derived Debug)" || METAL=""
  fi
fi

if [[ -z "$METAL" || ! -f "$METAL" ]]; then
  cat <<'EOF' >&2
Could not find default.metallib.

SwiftPM (swift build) does not build MLX Metal shaders. Build MLX with Metal once
using either:

  • Xcode: Open this repo’s Package.swift, select scheme Hayabusa, build (⌘B).
    The metallib usually lands in ~/Library/Developer/Xcode/DerivedData/<package>-*/Build/Products/
    (this script checks there if .build does not contain it).

  • mlx-swift xcodebuild (see https://github.com/ml-explore/mlx-swift README §
    "xcodebuild"), then either:
      export MLX_SWIFT_CHECKOUT=/path/to/mlx-swift
      scripts/copy_mlx_metallib.sh release
    or:
      export MLX_METAL_LIB=/path/to/default.metallib
      scripts/copy_mlx_metallib.sh release
EOF
  exit 1
fi

cp -f "$METAL" "$BIN_DIR/mlx.metallib"
echo "Installed $BIN_DIR/mlx.metallib (from $METAL)"
