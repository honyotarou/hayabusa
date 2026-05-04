#!/usr/bin/env bash
# Install git hooks from lefthook.yml (one-time per clone).
# Requires: brew install lefthook  (or https://github.com/evilmartians/lefthook)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if ! command -v lefthook >/dev/null 2>&1; then
  echo "lefthook not found. Install: brew install lefthook" >&2
  exit 1
fi
lefthook install
echo "lefthook install OK (pre-commit runs check-encapsulation + harness fast)"
