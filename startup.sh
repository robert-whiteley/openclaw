#!/bin/bash

# === 1. Start SSH agent and add the deploy key ===
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_workspace

# === 2. Ensure the workspace exists ===
mkdir -p "$HOME/persistent/openclaw"
cd "$HOME/persistent/openclaw"

# === 3. Pull latest OpenClaw repo changes ===
if [ -d ".git" ]; then
    git pull origin main
else
    git clone git@github.com:robert-whiteley/openclaw.git .
fi

# === 4. Install clawhub if missing ===
if [ ! -d "$HOME/.openclaw/clawhub/node_modules" ]; then
    npm install --prefix ~/.openclaw/clawhub clawhub
fi

# === 5. Ensure gitclaw skill is installed ===
~/.openclaw/clawhub/node_modules/.bin/clawhub install gitclaw --no-input

# === 6. Start OpenClaw ===
openclaw-agent start
