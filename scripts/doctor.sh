#!/bin/bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0

line() {
    printf "%-28s %-5s %s\n" "$1" "$2" "$3"
}

check_cmd() {
    local label="$1"
    local cmd="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        line "$label" "PASS" "$(command -v "$cmd")"
    else
        line "$label" "FAIL" "missing: $cmd"
        fail=1
    fi
}

echo "ACE-Step UI doctor"
echo

check_cmd "node" node
check_cmd "npm" npm
check_cmd "ffmpeg" ffmpeg
check_cmd "ffprobe" ffprobe
check_cmd "curl" curl

if command -v node >/dev/null 2>&1; then
    major="$(node -p 'process.versions.node.split(".")[0]')"
    if [ "$major" = "22" ]; then
        line "Node version" "PASS" "$(node --version)"
    else
        line "Node version" "FAIL" "$(node --version); expected 22.x"
        fail=1
    fi
fi

if [ -d node_modules ]; then
    line "frontend dependencies" "PASS" "installed"
else
    line "frontend dependencies" "WARN" "run ./setup.sh"
fi

if [ -d server/node_modules ]; then
    line "server dependencies" "PASS" "installed"
else
    line "server dependencies" "WARN" "run ./setup.sh"
fi

ACESTEP_PATH="${ACESTEP_PATH:-$HOME/projects/_vendor/ACE-Step-1.5}"
if [ -d "$ACESTEP_PATH" ]; then
    line "ACE-Step checkout" "PASS" "$ACESTEP_PATH"
else
    line "ACE-Step checkout" "INFO" "not required for UI-only startup"
fi

AIGEN_MUSIC_API_URL="${AIGEN_MUSIC_API_URL:-http://127.0.0.1:8100}"
ACESTEP_API_URL="${ACESTEP_API_URL:-http://127.0.0.1:8001}"

if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 1 "$AIGEN_MUSIC_API_URL/health" >/dev/null 2>&1; then
    line "AIGen Music service" "PASS" "$AIGEN_MUSIC_API_URL"
else
    line "AIGen Music service" "INFO" "stopped/unreachable; UI can still run"
fi

if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 1 "$ACESTEP_API_URL/health" >/dev/null 2>&1; then
    line "ACE-Step runtime" "PASS" "$ACESTEP_API_URL"
else
    line "ACE-Step runtime" "INFO" "stopped/unreachable"
fi

echo
if [ "$fail" -ne 0 ]; then
    echo "Doctor found required setup failures."
else
    echo "Required UI prerequisites are ready."
fi
exit "$fail"
