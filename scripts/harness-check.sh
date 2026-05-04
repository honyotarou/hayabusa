#!/usr/bin/env bash
# Same as: ./scripts/harness.sh check
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/harness.sh" check
