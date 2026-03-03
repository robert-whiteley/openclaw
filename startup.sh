#!/bin/bash
set -e # We can remove 'x' now that it's working, but 'e' keeps it safe

# 1. SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_render_openclaw
chmod 600 ~/.ssh/id_render_openclaw
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_render_openclaw
ssh-keyscan github.com >> ~/.ssh/known_hosts

# 2. Workspace Setup
mkdir -p /data/openclaw-workspace
cd /data/openclaw-workspace

# 3. Sync Workspace
if [ ! -d ".git" ]; then
    git init -b main
    git remote add origin git@github.com:robert-whiteley/openclaw-workspace.git
fi
git fetch origin main
git reset --hard origin/main

# 4. Link System Files
mkdir -p /data/openclaw-workspace/system_files
rm -rf ~/.openclaw
ln -s /data/openclaw-workspace/system_files ~/.openclaw

# 5. Launch (Added the --allow-unconfigured flag)
echo "Launching OpenClaw Gateway..."
exec npx openclaw gateway --port $PORT --allow-unconfigured
