#!/usr/bin/env bash
# host_dashboard.sh — serve the Godot Model Bench results dashboard over HTTP and open it in the browser.
#
# Usage:
#   ./host_dashboard.sh                 # rebuild + serve + open
#   ./host_dashboard.sh --no-build      # skip regeneration, just serve existing files
#   ./host_dashboard.sh 9000            # pick a port
#
# Env:
#   NO_OPEN=1    don't auto-open the browser (useful for headless/CI)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$HERE/results"
BUILD_SCRIPT="$HERE/build_dashboard.py"
PORT=8000
BUILD=1

for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    [0-9]*) PORT="$arg" ;;
  esac
done

if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "error: no results/ dir in $HERE" >&2
  exit 1
fi

# ── regenerate dashboard data (fast; keeps results fresh) ────────────
if [[ "$BUILD" -eq 1 && -f "$BUILD_SCRIPT" ]]; then
  echo "→ rebuilding dashboard data"
  (cd "$HERE" && python3 build_dashboard.py >/dev/null)
fi

# ── pick a free port ─────────────────────────────────────────────────
while ss -ltn 2>/dev/null | grep -q ":${PORT} "; do
  PORT=$((PORT + 1))
done

# ── serve ────────────────────────────────────────────────────────────
cd "$RESULTS_DIR"
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null' EXIT INT TERM

URL="http://localhost:$PORT/dashboard.html"
echo "→ serving results on $URL"
echo "  (Ctrl+C to stop)"

if [[ "${NO_OPEN:-0}" -ne 1 ]]; then
  # WSL: open in the Windows default browser
  if command -v explorer.exe >/dev/null 2>&1; then
    explorer.exe "$URL" >/dev/null 2>&1 || true
  elif command -v wslview >/dev/null 2>&1; then
    wslview "$URL" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" >/dev/null 2>&1 || true
  else
    echo "  (no browser opener found — open $URL manually)"
  fi
fi

wait "$SERVER_PID"