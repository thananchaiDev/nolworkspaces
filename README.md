# Nolworkspaces

Interactive installer for a Claude Code workspace. On run it asks what you want to install:

1. **Claude Code + plugins** — marketplaces, plugins, `everything-claude-code` rules, Playwright MCP
2. **Programs** — Node.js, package managers, dev tools (macOS / Linux)

## Install

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/install.ps1 | iex
```

Re-run any time to update — every step is idempotent.

## What option 1 installs

**Marketplaces**
- `thedotmack/claude-mem`
- `affaan-m/everything-claude-code`
- `anthropics/claude-plugins-official`
- `mksglu/context-mode`

**Plugins**
- `claude-mem`
- `everything-claude-code`
- `superpowers`
- `frontend-design`
- `typescript-lsp`
- `context-mode`

**Extras**
- Clones `affaan-m/everything-claude-code` to `~/.claude/ecc-source` and runs `./install.sh --profile full`
- Sets `env.CLAUDE_PLUGIN_ROOT` in `~/.claude/settings.json` to the installed ECC plugin path
- Installs `@playwright/mcp` to `~/.claude/nolworkspaces/mcp` and registers it with `claude mcp add` using `--image-responses=omit`

## What option 2 installs

**macOS** (via `scripts/setup-mac.sh`)
- Homebrew + formulae: `bun, gh, lazygit, mas, mysql-client, node, pnpm, python@3.13, yarn, jq, zsh-autosuggestions, zsh-syntax-highlighting`
- Casks: `warp, 1password, visual-studio-code, microsoft-teams, docker, flutter, android-studio`
- Oh My Zsh, Xcode CLT + Xcode (via mas), Claude Code CLI
- macOS Finder / keyboard defaults

**Linux** (via `scripts/setup-linux.sh`, Debian/Ubuntu)
- apt: `build-essential, curl, file, git, jq, mysql-client`, `lazygit`
- Node.js via `nvm` (LTS), `npm@latest`, `yarn`, `pnpm`, `bun`

**Windows** — no bundled program installer; installer prints `winget` hints.

## Uninstall

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/uninstall.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/uninstall.ps1 | iex
```

> Note: the `claude-plugins-official` marketplace is intentionally left in place on uninstall since it may be shared with other plugins.
