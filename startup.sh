#!/bin/bash
set -euo pipefail

# 1. SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_render_openclaw
chmod 600 ~/.ssh/id_render_openclaw
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_render_openclaw
touch ~/.ssh/known_hosts
ssh-keygen -F github.com >/dev/null || ssh-keyscan github.com >> ~/.ssh/known_hosts

# 2. Workspace Setup & Identity
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
WORKSPACE_REPO="${OPENCLAW_WORKSPACE_REPO:-git@github.com:robert-whiteley/openclaw-workspace.git}"
WORKSPACE_BRANCH="${OPENCLAW_WORKSPACE_BRANCH:-main}"

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

git config --global user.email "rcwhiteley@hotmail.co.uk"
git config --global user.name "Robert Whiteley"
git config --global --add safe.directory "$WORKSPACE_DIR"

# 3. Sync Workspace (safe, non-destructive)
if [ ! -d ".git" ]; then
    git init -b "$WORKSPACE_BRANCH"
    git remote add origin "$WORKSPACE_REPO"
fi

git remote set-url origin "$WORKSPACE_REPO"
git fetch origin "$WORKSPACE_BRANCH"

if [ -n "$(git status --porcelain)" ]; then
    echo "Workspace has local changes; skipping pull to avoid overwrite."
else
    git checkout "$WORKSPACE_BRANCH"
    git pull --ff-only origin "$WORKSPACE_BRANCH"
fi

# 3.5 Apply versioned cron payload (best effort)
if [ -f "$WORKSPACE_DIR/scripts/sync-cron-job.js" ]; then
  node "$WORKSPACE_DIR/scripts/sync-cron-job.js" || echo "cron sync skipped/failed (non-fatal)"
fi

# 4. Link System Files
mkdir -p "$WORKSPACE_DIR/system_files"
mkdir -p "$WORKSPACE_DIR/system_files/agents/main/sessions"
mkdir -p "$WORKSPACE_DIR/system_files/credentials"
rm -rf ~/.openclaw
ln -s "$WORKSPACE_DIR/system_files" ~/.openclaw

# 5. Launch
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-/app/openclaw.json}"
export OPENCLAW_CONFIG_PATH

if [ -f "$OPENCLAW_CONFIG_PATH" ]; then
    echo "Validating OpenClaw config at $OPENCLAW_CONFIG_PATH..."
    chmod 600 "$OPENCLAW_CONFIG_PATH" || true
    npx openclaw config get gateway.bind >/dev/null
else
    echo "Warning: Config file not found at $OPENCLAW_CONFIG_PATH; using default config discovery."
fi

echo "Launching OpenClaw Gateway..."
exec npx openclaw gateway --port "${PORT:-8080}" --allow-unconfigured
