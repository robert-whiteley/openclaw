#!/bin/bash
set -e # Exit on error

# 1. Write deploy key with preserved newlines
mkdir -p ~/.ssh
chmod 700 ~/.ssh
printf "%b" "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_ed25519_workspace
chmod 600 ~/.ssh/id_ed25519_workspace

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_workspace
ssh-keyscan github.com >> ~/.ssh/known_hosts

# 2. Ensure the Workspace exists on the Persistent Disk
mkdir -p /data/openclaw-workspace
cd /data/openclaw-workspace

# 3. Pull/Clone your WORKSPACE (Identity/Memory)
if [ -d ".git" ]; then
    git pull origin main
else
    # NOTE: Using the -workspace repo here
    git clone git@github.com:robert-whiteley/openclaw-workspace.git .
fi

# 4. Persistence Hack: Link the app's config to the disk
# This ensures skills and logs stay on the disk
mkdir -p /data/openclaw-workspace/system_files
rm -rf ~/.openclaw
ln -s /data/openclaw-workspace/system_files ~/.openclaw

# 5. Install Skills (ClawHub)
if [ ! -d "/data/openclaw-workspace/system_files/clawhub/node_modules" ]; then
    npm install --prefix ~/.openclaw/clawhub clawhub
fi

# 6. Start the actual OpenClaw Gateway
# We use 'exec' so the gateway receives shutdown signals from Render
exec npx openclaw gateway --port $PORT
