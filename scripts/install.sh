#!/usr/bin/env bash
# Nolworkspaces installer
# Usage: curl -fsSL https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/install.sh | bash

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

NOLWORKSPACES_DIR="${NOLWORKSPACES_DIR:-$HOME/.claude/nolworkspaces}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REQUIRED_MARKETPLACES=(
  "affaan-m/everything-claude-code:ecc"
  "https://github.com/anthropics/claude-plugins-official.git:claude-plugins-official"
  "mksglu/context-mode:context-mode"
)

REQUIRED_PLUGINS=(
  "ecc@ecc"
  "frontend-design@claude-plugins-official"
  "superpowers@claude-plugins-official"
  "typescript-lsp@claude-plugins-official"
  "context-mode@context-mode"
)

# ── Colors ────────────────────────────────────────────────────────────────────

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

banner() {
  printf "\n${BOLD}"
  printf "  ███╗   ██╗ ██████╗ ██╗     ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗\n"
  printf "  ████╗  ██║██╔═══██╗██║     ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝\n"
  printf "  ██╔██╗ ██║██║   ██║██║     ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗\n"
  printf "  ██║╚██╗██║██║   ██║██║     ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║\n"
  printf "  ██║ ╚████║╚██████╔╝███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║\n"
  printf "  ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝\n"
  printf "${NC}"
  printf "  ${DIM}Claude Code + workstation installer${NC}\n\n"
}

info()    { printf "  ${GREEN}✓${NC}  %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!${NC}  %s\n" "$*"; }
error()   { printf "  ${RED}✗${NC}  %s\n" "$*" >&2; exit 1; }
step()    { printf "\n  ${BOLD}%s${NC}\n" "$*"; }
pending() { printf "  ${DIM}→${NC}  %s..." "$*"; }
done_()   { printf " ${GREEN}done${NC}\n"; }

# ── Mode 1: Claude Code + plugins ─────────────────────────────────────────────

check_claude() {
  step "Checking prerequisites"
  if ! command -v claude &>/dev/null; then
    error "Claude Code CLI not found. Install programs first (option 2) or: npm install -g @anthropic-ai/claude-code"
  fi
  info "Claude Code CLI found ($(claude --version 2>/dev/null | head -1))"
  if ! command -v git &>/dev/null; then
    error "git not found."
  fi
  info "git found"
}

add_marketplaces() {
  step "Adding marketplaces"
  for entry in "${REQUIRED_MARKETPLACES[@]}"; do
    repo="${entry%:*}"
    name="${entry##*:}"
    if claude plugin marketplace list 2>/dev/null | grep -q "❯ $name"; then
      info "${name} already added"
    else
      pending "Adding ${name}"
      claude plugin marketplace add "$repo" 2>/dev/null || warn "failed to add $name"
      done_
    fi
  done
}

install_dependencies() {
  step "Installing plugin dependencies"
  for plugin in "${REQUIRED_PLUGINS[@]}"; do
    name="${plugin%@*}"
    if claude plugin list 2>/dev/null | grep -q "❯ ${name}@"; then
      info "${name} already installed"
    else
      pending "Installing ${plugin}"
      claude plugin install "$plugin" 2>/dev/null || warn "failed to install $plugin"
      done_
    fi
  done
}

install_ecc_rules() {
  step "Installing everything-claude-code rules (full profile)"
  ECC_DIR="$HOME/.claude/ecc-source"
  if [ -d "$ECC_DIR" ]; then
    pending "Updating ecc-source"
    git -C "$ECC_DIR" pull --ff-only >/dev/null 2>&1 || warn "pull failed, using existing"
    done_
  else
    pending "Cloning ecc-source"
    git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR" >/dev/null 2>&1
    done_
  fi
  pending "Installing rules"
  (cd "$ECC_DIR" && npm install --silent >/dev/null 2>&1 && ./install.sh --profile full >/dev/null 2>&1)
  done_
}

configure_ecc_env() {
  step "Configuring CLAUDE_PLUGIN_ROOT"
  SETTINGS="$HOME/.claude/settings.json"
  ECC_CACHE="$HOME/.claude/plugins/cache/ecc"
  if [ ! -d "$ECC_CACHE" ]; then
    warn "ECC plugin cache not found — skipping env config"
    return
  fi
  ECC_ORG=$(ls "$ECC_CACHE" | head -1)
  ECC_VER=$(ls "$ECC_CACHE/$ECC_ORG" 2>/dev/null | sort -V | tail -1)
  ECC_PLUGIN_ROOT="$ECC_CACHE/$ECC_ORG/$ECC_VER"
  if ! command -v jq &>/dev/null; then
    warn "jq not found — skipping env config"
    return
  fi
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  UPDATED=$(jq --arg v "$ECC_PLUGIN_ROOT" '.env = (.env // {}) | .env.CLAUDE_PLUGIN_ROOT = $v' "$SETTINGS")
  echo "$UPDATED" > "$SETTINGS"
  info "CLAUDE_PLUGIN_ROOT=$ECC_PLUGIN_ROOT"
}

install_mcp_servers() {
  step "Installing MCP servers"
  if ! command -v npm &>/dev/null; then
    error "npm not found. Run option 2 first to install Node.js."
  fi
  mkdir -p "$NOLWORKSPACES_DIR/mcp"
  if [ ! -f "$NOLWORKSPACES_DIR/mcp/node_modules/@playwright/mcp/package.json" ]; then
    pending "Installing @playwright/mcp into $NOLWORKSPACES_DIR/mcp"
    (cd "$NOLWORKSPACES_DIR/mcp" && npm init -y >/dev/null 2>&1 && npm install @playwright/mcp@latest >/dev/null 2>&1)
    done_
  else
    info "@playwright/mcp already installed in $NOLWORKSPACES_DIR/mcp"
  fi
  PLAYWRIGHT_BIN="$NOLWORKSPACES_DIR/mcp/node_modules/.bin/playwright-mcp"
  [ -x "$PLAYWRIGHT_BIN" ] || error "playwright MCP binary not found at $PLAYWRIGHT_BIN"
  if claude mcp list 2>/dev/null | grep -q "^playwright"; then
    pending "Re-registering playwright MCP"
    claude mcp remove playwright --scope user 2>/dev/null || true
  else
    pending "Registering playwright MCP"
  fi
  claude mcp add playwright --scope user -- "$PLAYWRIGHT_BIN" --extension --image-responses=omit --output-dir .playwright-mcp 2>/dev/null
  done_
}

create_global_claude_md() {
  step "Creating ~/.claude/CLAUDE.md"
  CLAUDE_MD="$HOME/.claude/CLAUDE.md"
  if [ -f "$CLAUDE_MD" ]; then
    info "CLAUDE.md already exists — skipping"
    return
  fi
  pending "Downloading CLAUDE.md"
  local url="https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/templates/CLAUDE.md"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$CLAUDE_MD"
  elif command -v wget &>/dev/null; then
    wget -qO "$CLAUDE_MD" "$url"
  else
    # fallback: copy from local if script was cloned
    cp "$SCRIPT_DIR/../templates/CLAUDE.md" "$CLAUDE_MD" 2>/dev/null || \
      { warn "Cannot download CLAUDE.md — no curl/wget and not running from a clone"; return; }
  fi
  done_
}

install_claude_stack() {
  check_claude
  add_marketplaces
  install_dependencies
  install_ecc_rules
  configure_ecc_env
  install_mcp_servers
  create_global_claude_md
  printf "\n  ${GREEN}${BOLD}Claude Code stack installed!${NC}\n\n"
  printf "  ${DIM}Restart Claude Code to apply changes.${NC}\n\n"
}

# ── Mode 2: Programs (system tools) ──────────────────────────────────────────

install_programs() {
  step "Installing programs"
  case "$(uname -s)" in
    Darwin)
      info "Detected macOS — running setup-mac.sh"
      bash "$SCRIPT_DIR/setup-mac.sh"
      ;;
    Linux)
      info "Detected Linux — running setup-linux.sh"
      bash "$SCRIPT_DIR/setup-linux.sh"
      ;;
    *)
      error "Unsupported OS: $(uname -s). Use scripts/setup-*.sh manually."
      ;;
  esac
  printf "\n  ${GREEN}${BOLD}Programs installed!${NC}\n\n"
}

# ── Menu ──────────────────────────────────────────────────────────────────────

menu() {
  printf "  ${BOLD}What do you want to install?${NC}\n\n"
  printf "    ${BOLD}1)${NC} Claude Code + plugins  ${DIM}(marketplaces, plugins, ECC rules, MCP)${NC}\n"
  printf "    ${BOLD}2)${NC} Programs               ${DIM}(Node, package managers, dev tools)${NC}\n\n"
  printf "  Choice [1/2]: "
  read -r choice </dev/tty
  case "$choice" in
    1) install_claude_stack ;;
    2) install_programs ;;
    *) error "Invalid choice: $choice" ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  banner
  menu
}

main "$@"
