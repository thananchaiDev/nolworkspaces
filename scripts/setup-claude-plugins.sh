#!/bin/bash
set -e

echo "=== Claude Code Plugin Setup ==="
echo ""

if ! command -v claude &>/dev/null; then
  echo "ERROR: Claude Code CLI not found. Install it first:"
  echo "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# --------------------------------------------------
# Helpers
# --------------------------------------------------
marketplace_exists() {
  claude plugin marketplace list 2>/dev/null | grep -q "❯ $1"
}

plugin_installed() {
  claude plugin list 2>/dev/null | grep -q "❯ $1"
}

add_marketplace() {
  local name="$1" source="$2"
  if marketplace_exists "$name"; then
    echo "  [skip] marketplace '$name' already registered"
  else
    echo "  Adding marketplace: $name"
    claude plugin marketplace add "$source" && echo "    Done" || echo "    WARN: failed"
  fi
}

install_plugin() {
  local name="$1"
  if plugin_installed "$name"; then
    echo "  [skip] plugin '$name' already installed"
  else
    echo "  Installing plugin: $name"
    claude plugin install "$name" && echo "    Done" || echo "    WARN: failed"
  fi
}

# --------------------------------------------------
# 1. Marketplaces
# --------------------------------------------------
echo "--- Marketplaces ---"
add_marketplace "thedotmack"              "thedotmack/claude-mem"
add_marketplace "everything-claude-code"  "affaan-m/everything-claude-code"
add_marketplace "claude-plugins-official" "https://github.com/anthropics/claude-plugins-official.git"
add_marketplace "context-mode"            "mksglu/context-mode"
echo ""

# --------------------------------------------------
# 2. Plugins
# --------------------------------------------------
echo "--- Plugins ---"
install_plugin "claude-mem@thedotmack"
install_plugin "everything-claude-code@everything-claude-code"
install_plugin "frontend-design@claude-plugins-official"
install_plugin "superpowers@claude-plugins-official"
install_plugin "context-mode@context-mode"
echo ""

# --------------------------------------------------
# 3. everything-claude-code rules (required, not bundled in plugin)
# --------------------------------------------------
echo "--- everything-claude-code rules ---"
ECC_DIR="$HOME/.claude/ecc-source"

if [ -d "$ECC_DIR" ]; then
  echo "  Updating repo..."
  git -C "$ECC_DIR" pull --ff-only 2>/dev/null || echo "  WARN: pull failed, using existing"
else
  echo "  Cloning repo..."
  git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR"
fi

echo "  Installing rules (full profile)..."
cd "$ECC_DIR"
npm install --silent
./install.sh --profile full
cd - > /dev/null
echo "  Done"
echo ""

# --------------------------------------------------
# 4. Claude Code env — CLAUDE_PLUGIN_ROOT for ECC hooks
# --------------------------------------------------
echo "--- Claude Code env ---"
SETTINGS="$HOME/.claude/settings.json"

# Detect latest ECC plugin version from cache
ECC_CACHE="$HOME/.claude/plugins/cache/everything-claude-code"
if [ -d "$ECC_CACHE" ]; then
  ECC_ORG=$(ls "$ECC_CACHE" | head -1)
  ECC_VER=$(ls "$ECC_CACHE/$ECC_ORG" 2>/dev/null | sort -V | tail -1)
  ECC_PLUGIN_ROOT="$ECC_CACHE/$ECC_ORG/$ECC_VER"
else
  ECC_PLUGIN_ROOT=""
fi

if [ -n "$ECC_PLUGIN_ROOT" ] && [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  UPDATED=$(jq --arg v "$ECC_PLUGIN_ROOT" '.env.CLAUDE_PLUGIN_ROOT = $v' "$SETTINGS")
  echo "$UPDATED" > "$SETTINGS"
  echo "  CLAUDE_PLUGIN_ROOT=$ECC_PLUGIN_ROOT"
  echo "  Done"
elif ! command -v jq &>/dev/null; then
  echo "  WARN: jq not found, skipping env config"
else
  echo "  WARN: ECC plugin cache not found, skipping"
fi
echo ""

# --------------------------------------------------
# Done
# --------------------------------------------------
echo "=== Done! ==="
echo ""
echo "Verify with:"
echo "  claude plugin list"
echo "  claude mcp list"
