#!/bin/bash
# Shared Node 22 selection for the AIGen macOS profile.
# Source this file, then call: aigen_use_node22

aigen_use_node22() {
    local current_major=""
    if command -v node >/dev/null 2>&1; then
        current_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
        if [ "$current_major" = "22" ]; then
            return 0
        fi
    fi

    local candidates=()
    if command -v brew >/dev/null 2>&1; then
        local brew_prefix=""
        brew_prefix="$(brew --prefix node@22 2>/dev/null || true)"
        if [ -n "$brew_prefix" ]; then
            candidates+=("$brew_prefix/bin")
        fi
    fi
    candidates+=(
        "/opt/homebrew/opt/node@22/bin"
        "/usr/local/opt/node@22/bin"
    )

    local candidate=""
    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate/node" ]; then
            export PATH="$candidate:$PATH"
            hash -r 2>/dev/null || true
            current_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
            if [ "$current_major" = "22" ]; then
                return 0
            fi
        fi
    done

    echo "Error: Node 22 is required for this fork." >&2
    if command -v node >/dev/null 2>&1; then
        echo "Detected: $(node --version) at $(command -v node)" >&2
    else
        echo "Detected: no node executable on PATH" >&2
    fi
    echo >&2
    echo "Install Node 22 with:" >&2
    echo "  brew install node@22" >&2
    echo >&2
    echo "Then rerun the command; the AIGen scripts will select Homebrew Node 22 automatically." >&2
    return 1
}
