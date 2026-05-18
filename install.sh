#!/usr/bin/env bash
set -euo pipefail

MARKETPLACE_KEY="claude-skill-nextjs-scaffold"
PLUGIN_KEY="scaffold-cpub-nextjs@claude-skill-nextjs-scaffold"
SETTINGS="$HOME/.claude/settings.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Installing Claude Skill: Next.js Scaffold..."
echo ""

# Node.js is guaranteed for this skill's target audience (Next.js developers)
if ! command -v node &>/dev/null; then
  echo -e "${RED}Error:${NC} Node.js is required but not installed."
  echo "Install it from https://nodejs.org"
  exit 1
fi

# claude CLI is required to formally install the plugin
if ! command -v claude &>/dev/null; then
  echo -e "${RED}Error:${NC} Claude Code CLI is required but not installed."
  echo "Install it from https://claude.ai/code"
  exit 1
fi

# Ensure ~/.claude exists
mkdir -p "$HOME/.claude"

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

# Step 1: Register the marketplace in settings.json via Node
node - "$SETTINGS" "$MARKETPLACE_KEY" <<'EOF'
const fs = require('fs');
const [,, settingsPath, marketplaceKey] = process.argv;

let settings = {};
try {
  settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
} catch (e) {
  console.error('Error: settings.json contains invalid JSON. Please fix it before installing.');
  process.exit(1);
}

const alreadyRegistered = settings.extraKnownMarketplaces?.[marketplaceKey];
if (alreadyRegistered) {
  console.log('\x1b[33mMarketplace already registered.\x1b[0m Updating entry...');
}

settings.extraKnownMarketplaces = settings.extraKnownMarketplaces || {};
settings.extraKnownMarketplaces[marketplaceKey] = {
  source: {
    source: 'github',
    repo: 'jazzsequence/claude-skill-nextjs-scaffold',
  },
  autoUpdate: true,
};

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
EOF

echo -e "${GREEN}✓${NC} Marketplace registered: $MARKETPLACE_KEY"

# Step 2: Install the plugin via the Claude CLI so it's tracked and updatable
echo "Installing plugin..."
claude plugin install "$PLUGIN_KEY" 2>&1

echo ""
echo "Start a new Claude Code session to use /scaffold-cpub-nextjs"
echo "To update later: claude plugin update scaffold-cpub-nextjs@claude-skill-nextjs-scaffold"
