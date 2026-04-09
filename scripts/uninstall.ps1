# Nolworkspaces uninstaller (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/thananchaiDev/Nolworkspaces/main/scripts/uninstall.ps1 | iex

$ErrorActionPreference = 'Stop'

# -- Config --------------------------------------------------------------------

$InstallDir = if ($env:NOLWORKSPACES_DIR) { $env:NOLWORKSPACES_DIR } else { Join-Path $HOME '.claude\nolworkspaces' }

$RemovePlugins = @(
    'mempalace@mempalace'
    'ecc@ecc'
    'frontend-design@claude-plugins-official'
    'superpowers@claude-plugins-official'
    'typescript-lsp@claude-plugins-official'
    'context-mode@context-mode'
)

# NOTE: claude-plugins-official is intentionally excluded — it may be shared
# with other plugins outside Nolworkspaces, so we leave it in place.
$RemoveMarketplaces = @('mempalace', 'ecc', 'context-mode')

# -- Output helpers ------------------------------------------------------------

function Banner {
    Write-Host ''
    Write-Host '  ███╗   ██╗ ██████╗ ██╗     ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗' -ForegroundColor White
    Write-Host '  ████╗  ██║██╔═══██╗██║     ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝' -ForegroundColor White
    Write-Host '  ██╔██╗ ██║██║   ██║██║     ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗' -ForegroundColor White
    Write-Host '  ██║╚██╗██║██║   ██║██║     ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║' -ForegroundColor White
    Write-Host '  ██║ ╚████║╚██████╔╝███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║' -ForegroundColor White
    Write-Host '  ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝' -ForegroundColor White
    Write-Host '  Uninstaller' -ForegroundColor DarkGray
    Write-Host ''
}

function Step($m)    { Write-Host ''; Write-Host "  $m" -ForegroundColor White }
function Info($m)    { Write-Host "  [ok] $m" -ForegroundColor Green }
function Warn($m)    { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Pending($m) { Write-Host "  ->   $m..." -ForegroundColor DarkGray -NoNewline }
function Done        { Write-Host ' done' -ForegroundColor Green }

# -- Uninstall plugins ---------------------------------------------------------

function Uninstall-Plugins {
    Step 'Removing installed plugins'
    $list = (& claude plugin list 2>$null) -join "`n"
    foreach ($plugin in $RemovePlugins) {
        $name = $plugin.Split('@')[0]
        if ($list -match "❯ $([regex]::Escape($name))@") {
            Pending "Uninstalling $name"
            try { & claude plugin uninstall $plugin 2>$null | Out-Null } catch {}
            Done
        } else {
            Warn "$name not installed — skipping"
        }
    }
}

# -- Remove marketplaces -------------------------------------------------------

function Remove-Marketplaces {
    Step 'Removing marketplaces'
    $list = (& claude plugin marketplace list 2>$null) -join "`n"
    foreach ($name in $RemoveMarketplaces) {
        if ($list -match [regex]::Escape($name)) {
            Pending "Removing $name"
            try { & claude plugin marketplace remove $name 2>$null | Out-Null } catch {}
            Done
        } else {
            Warn "$name not found — skipping"
        }
    }
}

# -- Remove MCP servers --------------------------------------------------------

function Remove-McpServers {
    Step 'Removing MCP servers'
    $mcpList = (& claude mcp list 2>$null) -join "`n"
    if ($mcpList -match '(?m)^playwright') {
        Pending 'Removing playwright MCP'
        try { & claude mcp remove playwright --scope user 2>$null | Out-Null } catch {}
        Done
    } else {
        Warn 'playwright MCP not found — skipping'
    }
}

# -- Remove source directory ---------------------------------------------------

function Remove-Source {
    Step 'Removing Nolworkspaces source'
    if (Test-Path $InstallDir) {
        Pending "Deleting $InstallDir"
        Remove-Item -Recurse -Force $InstallDir
        Done
        Info 'Source directory removed'
    } else {
        Warn "$InstallDir not found — skipping"
    }
}

# -- Done ---------------------------------------------------------------------

function Print-Success {
    Write-Host ''
    Write-Host '  Nolworkspaces uninstalled.' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Restart Claude Code to apply changes.' -ForegroundColor DarkGray
    Write-Host ''
}

# -- Main ---------------------------------------------------------------------

Banner
Uninstall-Plugins
Remove-McpServers
Remove-Marketplaces
Remove-Source
Print-Success
