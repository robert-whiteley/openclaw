#!/bin/bash
set -euo pipefail

# 1. SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_render_openclaw
chmod 600 ~/.ssh/id_render_openclaw
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_render_openclaw
ssh-keyscan github.com >> ~/.ssh/known_hosts

# 2. Workspace Setup & Identity
mkdir -p /data/openclaw-workspace
cd /data/openclaw-workspace
git config --global user.email "rcwhiteley@hotmail.co.uk"
git config --global user.name "Robert Whiteley"
git config --global --add safe.directory /data/openclaw-workspace

# 3. Sync Workspace
if [ ! -d ".git" ]; then
    git init -b main
    git remote add origin git@github.com:robert-whiteley/openclaw-workspace.git
fi
git fetch origin main
git reset --hard origin/main

# 4. Link System Files
mkdir -p /data/openclaw-workspace/system_files
mkdir -p /data/openclaw-workspace/system_files/agents/main/sessions
mkdir -p /data/openclaw-workspace/system_files/credentials
rm -rf ~/.openclaw
ln -s /data/openclaw-workspace/system_files ~/.openclaw

# 5. Launch
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-/app/openclaw.json}"
export OPENCLAW_CONFIG_PATH

if [ -f "$OPENCLAW_CONFIG_PATH" ]; then
    echo "Validating OpenClaw config at $OPENCLAW_CONFIG_PATH..."
    chmod 600 "$OPENCLAW_CONFIG_PATH" || true
    # Strict preflight: fails on schema/env var issues before gateway startup.
    npx openclaw config get gateway.bind >/dev/null
else
    echo "Warning: Config file not found at $OPENCLAW_CONFIG_PATH; using default config discovery."
fi

echo "Launching OpenClaw Gateway..."
exec npx openclaw gateway --port "${PORT:-8080}" --allow-unconfigured
