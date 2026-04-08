#!/usr/bin/env bash
# Nolworkspaces uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/thananchaiDev/Nolworkspaces/main/scripts/uninstall.sh | bash

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

INSTALL_DIR="${NOLWORKSPACES_DIR:-$HOME/.claude/nolworkspaces}"

# Plugins to remove on uninstall (installed by install.sh).
REMOVE_PLUGINS=(
  "claude-mem@thedotmack"
  "everything-claude-code@everything-claude-code"
  "superpowers@claude-plugins-official"
  "frontend-design@claude-plugins-official"
  "typescript-lsp@claude-plugins-official"
  "context-mode@context-mode"
)

# Marketplaces to remove on uninstall.
# NOTE: claude-plugins-official is intentionally excluded — it may be shared
# with other plugins outside Nolworkspaces, so we leave it in place.
REMOVE_MARKETPLACES=(
  "thedotmack"
  "everything-claude-code"
  "context-mode"
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
  printf "  ${DIM}Uninstaller${NC}\n\n"
}

info()    { printf "  ${GREEN}✓${NC}  %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!${NC}  %s\n" "$*"; }
error()   { printf "  ${RED}✗${NC}  %s\n" "$*" >&2; exit 1; }
step()    { printf "\n  ${BOLD}%s${NC}\n" "$*"; }
pending() { printf "  ${DIM}→${NC}  %s..." "$*"; }
done_()   { printf " ${GREEN}done${NC}\n"; }

# ── Uninstall plugins ─────────────────────────────────────────────────────────

uninstall_plugins() {
  step "Removing installed plugins"

  for plugin in "${REMOVE_PLUGINS[@]}"; do
    name="${plugin%@*}"
    if claude plugin list 2>/dev/null | grep -q "❯ ${name}@"; then
      pending "Uninstalling ${name}"
      claude plugin uninstall "$plugin" 2>/dev/null || true
      done_
    else
      warn "${name} not installed — skipping"
    fi
  done
}

# ── Remove marketplaces ───────────────────────────────────────────────────────

remove_marketplaces() {
  step "Removing marketplaces"

  for name in "${REMOVE_MARKETPLACES[@]}"; do
    if claude plugin marketplace list 2>/dev/null | grep -q "$name"; then
      pending "Removing ${name}"
      claude plugin marketplace remove "$name" 2>/dev/null || true
      done_
    else
      warn "${name} not found — skipping"
    fi
  done
}

# ── Remove MCP servers ────────────────────────────────────────────────────────

remove_mcp_servers() {
  step "Removing MCP servers"

  if claude mcp list 2>/dev/null | grep -q "^playwright"; then
    pending "Removing playwright MCP"
    claude mcp remove playwright --scope user 2>/dev/null || true
    done_
  else
    warn "playwright MCP not found — skipping"
  fi
}

# ── Remove source directory ───────────────────────────────────────────────────

remove_source() {
  step "Removing Nolworkspaces source"

  if [ -d "$INSTALL_DIR" ]; then
    pending "Deleting $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    done_
    info "Source directory removed"
  else
    warn "$INSTALL_DIR not found — skipping"
  fi
}

# ── Done ──────────────────────────────────────────────────────────────────────

print_success() {
  printf "\n"
  printf "  ${GREEN}${BOLD}Nolworkspaces uninstalled.${NC}\n\n"
  printf "  ${DIM}Restart Claude Code to apply changes.${NC}\n\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  banner
  uninstall_plugins
  remove_mcp_servers
  remove_marketplaces
  remove_source
  print_success
}

main "$@"
