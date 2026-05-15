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

# Ensure ~/.claude exists
mkdir -p "$HOME/.claude"

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

# Use Node to merge settings without clobbering existing config
node - "$SETTINGS" "$MARKETPLACE_KEY" "$PLUGIN_KEY" <<'EOF'
const fs = require('fs');
const [,, settingsPath, marketplaceKey, pluginKey] = process.argv;

let settings = {};
try {
  settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
} catch (e) {
  console.error('Error: settings.json contains invalid JSON. Please fix it before installing.');
  process.exit(1);
}

const alreadyInstalled = settings.extraKnownMarketplaces?.[marketplaceKey];
if (alreadyInstalled) {
  console.log('\x1b[33mAlready installed.\x1b[0m Updating marketplace entry...');
}

settings.extraKnownMarketplaces = settings.extraKnownMarketplaces || {};
settings.extraKnownMarketplaces[marketplaceKey] = {
  source: {
    source: 'github',
    repo: 'jazzsequence/claude-skill-nextjs-scaffold',
  },
  autoUpdate: true,
};

settings.enabledPlugins = settings.enabledPlugins || {};
settings.enabledPlugins[pluginKey] = true;

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
EOF

echo -e "${GREEN}✓${NC} Marketplace registered: $MARKETPLACE_KEY"
echo -e "${GREEN}✓${NC} Plugin enabled: $PLUGIN_KEY"
echo ""
echo "Start a new Claude Code session to use /scaffold-cpub-nextjs"
