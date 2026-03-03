#!/bin/bash
set -e

# 1. SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_ed25519_workspace
chmod 600 ~/.ssh/id_ed25519_workspace
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_workspace
ssh-keyscan github.com >> ~/.ssh/known_hosts

# 2. Workspace Setup on Persistent Disk
mkdir -p /data/openclaw-workspace
cd /data/openclaw-workspace

# 3. Best Practice: Init & Fetch (Avoids "Non-empty directory" errors)
if [ ! -d ".git" ]; then
    echo "Initializing new workspace on disk..."
    git init
    git remote add origin git@github.com:robert-whiteley/openclaw-workspace.git
fi

echo "Syncing workspace from GitHub..."
git fetch origin main
git reset --hard origin/main

# 4. Persistence link for config/skills
# Maps the internal config folder to the persistent disk
mkdir -p /data/openclaw-workspace/.system
rm -rf ~/.openclaw
ln -s /data/openclaw-workspace/.system ~/.openclaw

# 5. Start OpenClaw
# Gateway listens on $PORT (Render default)
echo "Launching OpenClaw Gateway..."
exec npx openclaw gateway --port $PORT
