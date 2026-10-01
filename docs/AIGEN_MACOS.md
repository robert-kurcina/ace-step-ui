# AIGen macOS development profile

This fork is being adapted as the interim AIGen Music frontend.

## Runtime separation

The normal development command starts only the React frontend and Express backend:

```bash
./start.sh
```

It does not launch ACE-Step, unload LM Studio, or otherwise manage external ML runtimes.

This allows Storygen or another project to keep LM Studio resident while music UI work continues.

## Supported local toolchain

The current macOS profile is intentionally pinned to Node 22 because the upstream `better-sqlite3` dependency does not build under the Node 26 configuration previously tested on Apple Silicon.

```bash
brew install node@22 ffmpeg
./setup.sh

# setup/start/doctor select Homebrew Node 22 automatically even when another
# Node version manager has a newer node first on PATH.
node --version
```

Expected Node major:

```text
22
```

## Setup

```bash
./setup.sh
bash ./scripts/doctor.sh
./start.sh
```

The UI remains usable for authoring/library development when ACE is stopped.

## Local services

Defaults:

```text
ACE-Step:     http://127.0.0.1:8001
AIGen Music:  http://127.0.0.1:8100
UI backend:   http://127.0.0.1:3001
UI frontend:  http://127.0.0.1:3000
```

Configure with:

```bash
export ACESTEP_API_URL=http://127.0.0.1:8001
export AIGEN_MUSIC_API_URL=http://127.0.0.1:8100
```

## Migration rule

Upstream generation routes currently contain direct ACE/Gradio logic. During the AIGen migration, direct access remains only for legacy features. Governed text-to-music generation will be moved behind the AIGen Music local service before it becomes the default path.

Do not use `start-all.sh` for the AIGen workflow. It starts ACE independently and bypasses the resource-governor lifecycle.
