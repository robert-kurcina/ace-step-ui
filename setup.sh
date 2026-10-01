#!/bin/bash
# ACE-Step UI Setup Script — AIGen macOS development profile

set -euo pipefail

echo "=================================="
echo "  ACE-Step UI Setup"
echo "=================================="
echo

if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js is required."
    echo "Install Node 22 with: brew install node@22"
    exit 1
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" != "22" ]; then
    echo "Error: this fork currently requires Node 22."
    echo "Detected: $(node --version)"
    echo
    echo "Install and select Node 22:"
    echo "  brew install node@22"
    echo '  export PATH="/opt/homebrew/opt/node@22/bin:$PATH"'
    exit 1
fi

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
echo "  ./scripts/doctor.sh"
echo "  ./start.sh"
echo
echo "The UI does not start ACE-Step or unload LM Studio."
