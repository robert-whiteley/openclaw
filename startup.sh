#!/bin/bash
set -ex  # The 'x' turns on detailed execution logging

# 1. SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Using the NEW filename we generated
echo "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_render_openclaw
chmod 600 ~/.ssh/id_render_openclaw

eval "$(ssh-agent -s)"
# CRITICAL: This must match the filename above
ssh-add ~/.ssh/id_render_openclaw
ssh-keyscan github.com >> ~/.ssh/known_hosts

# 2. Workspace Setup
mkdir -p /data/openclaw-workspace
cd /data/openclaw-workspace

# 3. Best Practice Sync
if [ ! -d ".git" ]; then
    echo "Initializing workspace..."
    git init -b main
    git remote add origin git@github.com:robert-whiteley/openclaw-workspace.git
fi

echo "Syncing workspace from GitHub..."
git fetch origin main
git reset --hard origin/main

# 4. Link System Files
mkdir -p /data/openclaw-workspace/system_files
rm -rf ~/.openclaw
ln -s /data/openclaw-workspace/system_files ~/.openclaw

# 5. Launch
echo "Launching OpenClaw Gateway..."
exec npx openclaw gateway --port $PORT
