#!/usr/bin/env bash
# Hayabusa Swift harness — local merge gates and CI entrypoint.
#   ./scripts/harness.sh fast   — check-encapsulation + LocalPolicy tests + HayabusaApp build（ルート swift / llama 不要）
#   ./scripts/harness.sh full   — encapsulation + LocalPolicy + llama + server release + swift test + App release
#   ./scripts/harness.sh check — alias for full（CI と同じ）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

cpu_jobs() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sysctl -n hw.ncpu 2>/dev/null || echo 8
  else
    nproc 2>/dev/null || echo 8
  fi
}

run_check_encapsulation() {
  echo "== check-encapsulation"
  "$ROOT/scripts/check-encapsulation.sh"
}

run_local_policy_tests() {
  echo "== LocalPolicy: swift test"
  (cd "$ROOT/LocalPolicy" && swift test)
}

run_hayabusa_app_build() {
  local config="${1:-}"
  echo "== HayabusaApp: swift build ${config:+-c $config}"
  if [[ -n "$config" ]]; then
    (cd "$ROOT/HayabusaApp" && swift build -c "$config")
  else
    (cd "$ROOT/HayabusaApp" && swift build)
  fi
}

ensure_llama() {
  local llama_root="$ROOT/vendor/llama.cpp"
  local build_dir="$llama_root/build"
  local lib="$build_dir/src/libllama.dylib"

  if [[ ! -d "$llama_root/.git" ]] && [[ ! -f "$llama_root/CMakeLists.txt" ]]; then
    echo "== llama.cpp: clone"
    mkdir -p "$ROOT/vendor"
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git "$llama_root"
  fi

  if [[ -f "$lib" ]]; then
    echo "== llama.cpp: already built ($lib)"
    return 0
  fi

  echo "== llama.cpp: cmake build (Metal)"
  cmake -S "$llama_root" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_METAL=ON \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=Apple \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON
  cmake --build "$build_dir" --config Release -j"$(cpu_jobs)"
}

run_hayabusa_server_build() {
  local config="${1:-release}"
  echo "== Hayabusa server: swift build -c $config"
  swift build -c "$config"
}

run_root_swift_tests() {
  local config="${1:-release}"
  echo "== Hayabusa package: swift test -c $config"
  swift test -c "$config"
}

cmd_fast() {
  echo "=== harness:fast (encapsulation + policy tests + App debug build) ==="
  run_check_encapsulation
  run_local_policy_tests
  run_hayabusa_app_build ""
  echo "=== harness:fast OK ==="
}

cmd_full() {
  echo "=== harness:full (encapsulation + policy + llama + server + tests + App release) ==="
  run_check_encapsulation
  run_local_policy_tests
  ensure_llama
  run_hayabusa_server_build release
  run_root_swift_tests release
  run_hayabusa_app_build release
  echo "=== harness:full OK ==="
}

usage() {
  echo "Usage: $0 fast | full | check" >&2
  exit 1
}

main() {
  case "${1:-}" in
    fast) cmd_fast ;;
    full|check) cmd_full ;;
    -h|--help|help) usage ;;
    *) usage ;;
  esac
}

main "$@"
