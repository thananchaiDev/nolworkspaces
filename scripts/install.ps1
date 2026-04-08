# Nolworkspaces installer (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/install.ps1 | iex

$ErrorActionPreference = 'Stop'

# -- Config --------------------------------------------------------------------

$NolworkspacesDir = if ($env:NOLWORKSPACES_DIR) { $env:NOLWORKSPACES_DIR } else { Join-Path $HOME '.claude\nolworkspaces' }

$RequiredMarketplaces = @(
    @{ Repo = 'thedotmack/claude-mem';                                  Name = 'thedotmack' }
    @{ Repo = 'affaan-m/everything-claude-code';                        Name = 'everything-claude-code' }
    @{ Repo = 'https://github.com/anthropics/claude-plugins-official.git'; Name = 'claude-plugins-official' }
    @{ Repo = 'mksglu/context-mode';                                    Name = 'context-mode' }
)

$RequiredPlugins = @(
    'claude-mem@thedotmack'
    'everything-claude-code@everything-claude-code'
    'superpowers@claude-plugins-official'
    'frontend-design@claude-plugins-official'
    'typescript-lsp@claude-plugins-official'
    'context-mode@context-mode'
)

# -- Output helpers ------------------------------------------------------------

function Banner {
    Write-Host ''
    Write-Host '  ███╗   ██╗ ██████╗ ██╗     ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗' -ForegroundColor White
    Write-Host '  ████╗  ██║██╔═══██╗██║     ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝' -ForegroundColor White
    Write-Host '  ██╔██╗ ██║██║   ██║██║     ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗' -ForegroundColor White
    Write-Host '  ██║╚██╗██║██║   ██║██║     ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║' -ForegroundColor White
    Write-Host '  ██║ ╚████║╚██████╔╝███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║' -ForegroundColor White
    Write-Host '  ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝' -ForegroundColor White
    Write-Host '  Claude Code + workstation installer' -ForegroundColor DarkGray
    Write-Host ''
}

function Step($m)    { Write-Host ''; Write-Host "  $m" -ForegroundColor White }
function Info($m)    { Write-Host "  [ok] $m" -ForegroundColor Green }
function Warn($m)    { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Fail($m)    { Write-Host "  [x]  $m" -ForegroundColor Red; exit 1 }
function Pending($m) { Write-Host "  ->   $m..." -ForegroundColor DarkGray -NoNewline }
function Done        { Write-Host ' done' -ForegroundColor Green }

function Has-Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# -- Mode 1: Claude Code + plugins --------------------------------------------

function Check-Claude {
    Step 'Checking prerequisites'
    if (-not (Has-Cmd 'claude')) {
        Fail 'Claude Code CLI not found. Install it first: npm install -g @anthropic-ai/claude-code'
    }
    $version = (& claude --version 2>$null | Select-Object -First 1)
    Info "Claude Code CLI found ($version)"
    if (-not (Has-Cmd 'git')) { Fail 'git not found.' }
    Info 'git found'
}

function Add-Marketplaces {
    Step 'Adding marketplaces'
    $list = (& claude plugin marketplace list 2>$null) -join "`n"
    foreach ($m in $RequiredMarketplaces) {
        if ($list -match "❯ $([regex]::Escape($m.Name))") {
            Info "$($m.Name) already added"
        } else {
            Pending "Adding $($m.Name)"
            try { & claude plugin marketplace add $m.Repo 2>$null | Out-Null } catch { Warn "failed to add $($m.Name)" }
            Done
        }
    }
}

function Install-Dependencies {
    Step 'Installing plugin dependencies'
    $list = (& claude plugin list 2>$null) -join "`n"
    foreach ($plugin in $RequiredPlugins) {
        $name = $plugin.Split('@')[0]
        if ($list -match "❯ $([regex]::Escape($name))@") {
            Info "$name already installed"
        } else {
            Pending "Installing $plugin"
            try { & claude plugin install $plugin --scope user 2>$null | Out-Null } catch { Warn "failed to install $plugin" }
            Done
        }
    }
}

function Install-EccRules {
    Step 'Installing everything-claude-code rules (full profile)'
    $eccDir = Join-Path $HOME '.claude\ecc-source'
    if (Test-Path $eccDir) {
        Pending 'Updating ecc-source'
        try { & git -C $eccDir pull --ff-only *> $null } catch { Warn 'pull failed, using existing' }
        Done
    } else {
        Pending 'Cloning ecc-source'
        & git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git $eccDir *> $null
        Done
    }
    Pending 'Installing rules'
    Push-Location $eccDir
    try {
        & npm install --silent *> $null
        if (Test-Path './install.sh') {
            if (Has-Cmd 'bash') {
                & bash ./install.sh --profile full *> $null
            } else {
                Warn 'bash not found — cannot run ECC install.sh on Windows; install Git Bash or WSL'
            }
        }
    } finally { Pop-Location }
    Done
}

function Configure-EccEnv {
    Step 'Configuring CLAUDE_PLUGIN_ROOT'
    $settings = Join-Path $HOME '.claude\settings.json'
    $eccCache = Join-Path $HOME '.claude\plugins\cache\everything-claude-code'
    if (-not (Test-Path $eccCache)) { Warn 'ECC plugin cache not found — skipping'; return }
    $org = Get-ChildItem $eccCache | Select-Object -First 1
    if (-not $org) { Warn 'ECC org dir not found — skipping'; return }
    $ver = Get-ChildItem $org.FullName | Sort-Object Name | Select-Object -Last 1
    if (-not $ver) { Warn 'ECC version dir not found — skipping'; return }
    $eccPluginRoot = $ver.FullName
    if (-not (Test-Path $settings)) { '{}' | Set-Content -Path $settings -Encoding utf8 }
    $json = Get-Content $settings -Raw | ConvertFrom-Json
    if (-not $json.env) { $json | Add-Member -NotePropertyName env -NotePropertyValue (@{}) -Force }
    $json.env | Add-Member -NotePropertyName CLAUDE_PLUGIN_ROOT -NotePropertyValue $eccPluginRoot -Force
    $json | ConvertTo-Json -Depth 10 | Set-Content -Path $settings -Encoding utf8
    Info "CLAUDE_PLUGIN_ROOT=$eccPluginRoot"
}

function Install-McpServers {
    Step 'Installing MCP servers'
    if (-not (Has-Cmd 'npm')) { Fail 'npm not found. Please install Node.js and try again.' }
    $mcpDir = Join-Path $NolworkspacesDir 'mcp'
    New-Item -ItemType Directory -Force -Path $mcpDir | Out-Null
    $pkgJson = Join-Path $mcpDir 'node_modules\@playwright\mcp\package.json'
    if (-not (Test-Path $pkgJson)) {
        Pending "Installing @playwright/mcp into $mcpDir"
        Push-Location $mcpDir
        try {
            & npm init -y *> $null
            & npm install '@playwright/mcp@latest' *> $null
        } finally { Pop-Location }
        Done
    } else {
        Info "@playwright/mcp already installed in $mcpDir"
    }
    $playwrightBin = Join-Path $mcpDir 'node_modules\.bin\playwright-mcp.cmd'
    if (-not (Test-Path $playwrightBin)) {
        $playwrightBin = Join-Path $mcpDir 'node_modules\.bin\playwright-mcp'
    }
    if (-not (Test-Path $playwrightBin)) { Fail "playwright MCP binary not found in $mcpDir\node_modules\.bin" }
    $mcpList = (& claude mcp list 2>$null) -join "`n"
    if ($mcpList -match '(?m)^playwright') {
        Pending 'Re-registering playwright MCP'
        & claude mcp remove playwright --scope user 2>$null | Out-Null
    } else {
        Pending 'Registering playwright MCP'
    }
    & claude mcp add playwright --scope user -- $playwrightBin --extension --image-responses=omit --output-dir .playwright-mcp 2>$null | Out-Null
    Done
}

function Install-ClaudeStack {
    Check-Claude
    Add-Marketplaces
    Install-Dependencies
    Install-EccRules
    Configure-EccEnv
    Install-McpServers
    Write-Host ''
    Write-Host '  Claude Code stack installed!' -ForegroundColor Green
    Write-Host '  Restart Claude Code to apply changes.' -ForegroundColor DarkGray
    Write-Host ''
}

# -- Mode 2: Programs ---------------------------------------------------------

function Install-Programs {
    Step 'Installing programs'
    Warn 'No Windows program installer is bundled yet.'
    Write-Host '  Suggested manual setup (PowerShell as admin):' -ForegroundColor DarkGray
    Write-Host '    winget install OpenJS.NodeJS.LTS' -ForegroundColor DarkGray
    Write-Host '    winget install Git.Git' -ForegroundColor DarkGray
    Write-Host '    winget install GitHub.cli' -ForegroundColor DarkGray
    Write-Host '    npm install -g @anthropic-ai/claude-code yarn pnpm' -ForegroundColor DarkGray
    Write-Host ''
}

# -- Menu ---------------------------------------------------------------------

function Show-Menu {
    Write-Host '  What do you want to install?' -ForegroundColor White
    Write-Host ''
    Write-Host '    1) Claude Code + plugins  (marketplaces, plugins, ECC rules, MCP)' -ForegroundColor White
    Write-Host '    2) Programs               (Windows: shows winget hints)' -ForegroundColor White
    Write-Host ''
    $choice = Read-Host '  Choice [1/2]'
    switch ($choice) {
        '1' { Install-ClaudeStack }
        '2' { Install-Programs }
        default { Fail "Invalid choice: $choice" }
    }
}

# -- Main ---------------------------------------------------------------------

Banner
Show-Menu
