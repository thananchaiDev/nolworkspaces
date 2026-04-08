# CLAUDE.md

## What this repo is

Nolworkspaces is a **set of installer scripts** for bootstrapping a Claude Code workspace. It is not a plugin and has no runtime — its only artifacts live under `scripts/`.

## Layout

```
scripts/
├── install.sh / install.ps1        # interactive entry point — menu of two modes
├── uninstall.sh / uninstall.ps1
├── setup-claude-plugins.sh         # standalone Claude plugin installer (reference / not invoked)
├── setup-linux.sh                  # programs for Debian/Ubuntu (called by install.sh option 2)
└── setup-mac.sh                    # programs for macOS (called by install.sh option 2)
```

## Two install modes

`install.sh` / `install.ps1` show a menu:

1. **Claude Code + plugins** — adds `REQUIRED_MARKETPLACES`, installs `REQUIRED_PLUGINS`, clones `everything-claude-code` and runs its `install.sh --profile full`, sets `env.CLAUDE_PLUGIN_ROOT` in `~/.claude/settings.json`, installs Playwright MCP under `$NOLWORKSPACES_DIR/mcp`.
2. **Programs** — detects OS and runs `setup-mac.sh` or `setup-linux.sh`. Windows prints `winget` hints (no bundled program installer).

`scripts/setup-claude-plugins.sh` is the original upstream reference script — it is **not** invoked by `install.sh`. The Bash and PowerShell installers each implement option 1 themselves so behavior stays in lockstep across platforms.

## Source-of-truth arrays

| File | Plugin list | Marketplace list |
|---|---|---|
| `scripts/install.sh` | `REQUIRED_PLUGINS` | `REQUIRED_MARKETPLACES` |
| `scripts/install.ps1` | `$RequiredPlugins` | `$RequiredMarketplaces` |
| `scripts/uninstall.sh` | `REMOVE_PLUGINS` | `REMOVE_MARKETPLACES` |
| `scripts/uninstall.ps1` | `$RemovePlugins` | `$RemoveMarketplaces` |

When adding or removing a plugin/marketplace, update **all four** files. Bash + PowerShell parity is mandatory.

## Conventions

- **Every step idempotent.** Use the check-then-install pattern already in the scripts.
- **No `jq` in the bash installer except for the `CLAUDE_PLUGIN_ROOT` step**, which warns and skips when `jq` is missing.
- **`claude-plugins-official` marketplace is never removed** by the uninstaller — it may be shared with other plugins outside Nolworkspaces.
- **All `.md` files in English.** Chat may be Thai; committed docs must be English.
