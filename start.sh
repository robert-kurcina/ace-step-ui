#!/bin/bash
# Start ACE-Step UI frontend + backend only.
# AIGen deliberately does not start ACE from this script.

set -euo pipefail

if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/node22-env.sh"
aigen_use_node22

if [ ! -d "node_modules" ] || [ ! -d "server/node_modules" ]; then
    echo "Error: dependencies are not installed. Run ./setup.sh first."
    exit 1
fi

PORT="${PORT:-3001}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
AIGEN_MUSIC_API_URL="${AIGEN_MUSIC_API_URL:-http://127.0.0.1:8100}"
ACESTEP_API_URL="${ACESTEP_API_URL:-http://127.0.0.1:8001}"

echo "Starting ACE-Step UI only."
echo "AIGen Music: $AIGEN_MUSIC_API_URL"
echo "ACE-Step:    $ACESTEP_API_URL"
echo

if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 1 "$AIGEN_MUSIC_API_URL/health" >/dev/null 2>&1; then
        echo "AIGen Music local service: reachable"
    else
        echo "AIGen Music local service: not reachable (UI will still start)"
    fi

    if curl -fsS --max-time 1 "$ACESTEP_API_URL/health" >/dev/null 2>&1; then
        echo "ACE-Step runtime: reachable"
    else
        echo "ACE-Step runtime: stopped/unreachable"
    fi
fi

echo

cleanup() {
    kill "${BACKEND_PID:-}" "${FRONTEND_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Starting backend on port $PORT..."
(
    cd server
    npm run dev
) &
BACKEND_PID=$!

sleep 2
if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
    echo "Error: backend failed to start."
    exit 1
fi

echo "Starting frontend on port $FRONTEND_PORT..."
npm run dev -- --port "$FRONTEND_PORT" &
FRONTEND_PID=$!

sleep 1
if ! kill -0 "$FRONTEND_PID" 2>/dev/null; then
    echo "Error: frontend failed to start."
    exit 1
fi

echo
echo "=================================="
echo "  ACE-Step UI Running"
echo "=================================="
echo "Frontend: http://localhost:$FRONTEND_PORT"
echo "Backend:  http://localhost:$PORT"
echo
echo "ACE is NOT started by this command."
echo "Press Ctrl+C to stop UI/backend."
echo

wait
