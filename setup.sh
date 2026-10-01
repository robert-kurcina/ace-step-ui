#!/bin/bash
# ACE-Step UI Setup Script — AIGen macOS development profile

set -euo pipefail

echo "=================================="
echo "  ACE-Step UI Setup"
echo "=================================="
echo

# Select the supported Node runtime even when another version manager has
# placed a newer Node ahead of Homebrew on PATH.
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/node22-env.sh"
aigen_use_node22
echo "Node runtime: $(node --version) ($(command -v node))"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: ffmpeg is required."
    echo "Install with: brew install ffmpeg"
    exit 1
fi

ACESTEP_PATH="${ACESTEP_PATH:-../ACE-Step-1.5}"
if [ -d "$ACESTEP_PATH" ]; then
    ACESTEP_PATH="$(cd "$ACESTEP_PATH" && pwd)"
    echo "ACE-Step checkout: $ACESTEP_PATH"
else
    echo "Warning: ACE-Step checkout not found at $ACESTEP_PATH"
    echo "The UI can still be installed and used for authoring/library work."
    echo "Generation remains unavailable until a governed ACE runtime is present."
fi

AIGEN_MUSIC_API_URL="${AIGEN_MUSIC_API_URL:-http://127.0.0.1:8100}"

echo
echo "Creating .env file..."
cat > .env << EOF
# ACE-Step UI Configuration

# ACE-Step checkout. The UI does not start ACE automatically.
ACESTEP_PATH=$ACESTEP_PATH
ACESTEP_API_URL=http://127.0.0.1:8001

# Governed AIGen Music local service
AIGEN_MUSIC_API_URL=$AIGEN_MUSIC_API_URL

# Server ports
PORT=3001
FRONTEND_PORT=3000
FRONTEND_URL=http://localhost:3000

# Database
DATABASE_PATH=./server/data/acestep.db
EOF

chmod +x scripts/doctor.sh 2>/dev/null || true

echo
echo "Installing frontend dependencies..."
npm install

echo
echo "Installing server dependencies..."
(
    cd server
    npm install
)

echo
echo "Initializing database..."
(
    cd server
    npm run db:migrate 2>/dev/null || echo "Database migration did not run; backend will retry on startup."
)

echo
echo "=================================="
echo "  Setup Complete"
echo "=================================="
echo
echo "Run:"
echo "  bash ./scripts/doctor.sh"
echo "  ./start.sh"
echo
echo "The UI does not start ACE-Step or unload LM Studio."
