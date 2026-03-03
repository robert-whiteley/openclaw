#!/bin/bash

# 1. Write deploy key from env to a file and add it
mkdir -p ~/.ssh
echo "$OPENCLAW_DEPLOY_KEY" > ~/.ssh/id_ed25519_workspace
chmod 600 ~/.ssh/id_ed25519_workspace
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_workspace

# 2. Ensure workspace exists
mkdir -p /data/openclaw-workspace
cd /data/openclaw-workspace

# 3. Pull latest OpenClaw repo
if [ -d ".git" ]; then
    git reset --hard
    git pull origin main
else
    git clone git@github.com:robert-whiteley/openclaw.git .
fi

# 4. Install ClawHub if missing
if [ ! -d "$HOME/.openclaw/clawhub/node_modules" ]; then
    npm install --prefix ~/.openclaw/clawhub clawhub
fi

# 5. Install gitclaw skill non-interactively
~/.openclaw/clawhub/node_modules/.bin/clawhub install gitclaw --no-input --force
