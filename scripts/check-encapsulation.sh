#!/usr/bin/env bash
# Architectural gate (LINE check:encapsulation の Swift 向け最小版).
# - Server と Types は HTTP / ドメイン型のみ（MLX・llama・HF を import しない）
# - LocalPolicy は Foundation のみ（GUI / サーバフレームワークを import しない）
# - CLI は HayabusaKit + Foundation のみ
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
  echo "check-encapsulation: $*" >&2
  exit 1
}

check_no_regex_in_tree() {
  local label="$1"
  local regex="$2"
  shift 2
  local f
  for f in "$@"; do
    test -f "$f" || continue
    if grep -nE "$regex" "$f" >/dev/null 2>&1; then
      echo "--- $f (matched $label) ---" >&2
      grep -nE "$regex" "$f" >&2 || true
      fail "forbidden pattern in $f ($label)"
    fi
  done
}

echo "== check-encapsulation: HayabusaKit/Server (no MLX / llama / HF imports)"
while IFS= read -r -d '' f; do
  check_no_regex_in_tree "server-layer import" \
    '^\s*import\s+(MLX|MLXLLM|MLXLMCommon|MLXHuggingFace|Tokenizers|HuggingFace|CLlama)\b' \
    "$f"
done < <(find "$ROOT/Sources/HayabusaKit/Server" -name '*.swift' -print0 2>/dev/null)

echo "== check-encapsulation: HayabusaKit/Types (Foundation only)"
while IFS= read -r -d '' f; do
  check_no_regex_in_tree "types-layer import" \
    '^\s*import\s+(Hummingbird|HayabusaLocalPolicy|MLX|MLXLLM|HuggingFace|CLlama)\b' \
    "$f"
done < <(find "$ROOT/Sources/HayabusaKit/Types" -name '*.swift' -print0 2>/dev/null)

echo "== check-encapsulation: LocalPolicy/Sources (Foundation only)"
while IFS= read -r -d '' f; do
  check_no_regex_in_tree "local-policy import" \
    '^\s*import\s+(Hummingbird|SwiftUI|Sparkle|MLX|CLlama|HuggingFace|Tokenizers|HayabusaKit)\b' \
    "$f"
done < <(find "$ROOT/LocalPolicy/Sources" -name '*.swift' -print0 2>/dev/null)

echo "== check-encapsulation: HayabusaCLI (HayabusaKit + Foundation only)"
while IFS= read -r -d '' f; do
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*// ]]; then
      continue
    fi
    if [[ "$line" =~ ^import[[:space:]]+ ]]; then
      if [[ "$line" =~ ^import[[:space:]]+Foundation[[:space:]]*$ ]]; then
        continue
      fi
      if [[ "$line" =~ ^import[[:space:]]+HayabusaKit[[:space:]]*$ ]]; then
        continue
      fi
      echo "--- $f (disallowed import) ---" >&2
      echo "$line" >&2
      fail "HayabusaCLI must import only Foundation and HayabusaKit"
    fi
  done < "$f"
done < <(find "$ROOT/Sources/HayabusaCLI" -name '*.swift' -print0 2>/dev/null)

echo "== check-encapsulation OK ==="
