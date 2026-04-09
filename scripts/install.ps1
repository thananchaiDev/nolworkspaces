# Nolworkspaces installer (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/thananchaiDev/nolworkspaces/main/scripts/install.ps1 | iex

$ErrorActionPreference = 'Stop'

# -- Config --------------------------------------------------------------------

$NolworkspacesDir = if ($env:NOLWORKSPACES_DIR) { $env:NOLWORKSPACES_DIR } else { Join-Path $HOME '.claude\nolworkspaces' }

$RequiredMarketplaces = @(
    @{ Repo = 'milla-jovovich/mempalace';                               Name = 'milla-jovovich' }
    @{ Repo = 'affaan-m/everything-claude-code';                        Name = 'ecc' }
    @{ Repo = 'https://github.com/anthropics/claude-plugins-official.git'; Name = 'claude-plugins-official' }
    @{ Repo = 'mksglu/context-mode';                                    Name = 'context-mode' }
)

$RequiredPlugins = @(
    'mempalace@milla-jovovich'
    'ecc@ecc'
    'frontend-design@claude-plugins-official'
    'superpowers@claude-plugins-official'
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
            try { & claude plugin install $plugin 2>$null | Out-Null } catch { Warn "failed to install $plugin" }
            Done
        }
    }
}

function Invoke-Quiet {
    # Run a native command and swallow all output (stdout+stderr) without
    # tripping $ErrorActionPreference='Stop' on stderr writes.
    param([string]$File, [string[]]$Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $File @Args 2>&1 | Out-Null
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Install-EccRules {
    Step 'Installing everything-claude-code rules (full profile)'
    $eccDir = Join-Path $HOME '.claude\ecc-source'
    if (Test-Path $eccDir) {
        Pending 'Updating ecc-source'
        $code = Invoke-Quiet 'git' @('-C', $eccDir, 'pull', '--ff-only')
        if ($code -ne 0) { Done; Warn 'pull failed, using existing' } else { Done }
    } else {
        Pending 'Cloning ecc-source'
        $code = Invoke-Quiet 'git' @('clone', '--depth', '1', 'https://github.com/affaan-m/everything-claude-code.git', $eccDir)
        if ($code -ne 0) { Write-Host ''; Warn "git clone failed (exit $code) — skipping ECC rules"; return }
        Done
    }
    Pending 'Installing rules'
    Push-Location $eccDir
    try {
        Invoke-Quiet 'npm' @('install', '--silent') | Out-Null
        if (Test-Path './install.sh') {
            if (Has-Cmd 'bash') {
                Invoke-Quiet 'bash' @('./install.sh', '--profile', 'full') | Out-Null
                Done
            } else {
                Write-Host ''
                Warn 'bash not found — cannot run ECC install.sh on Windows; install Git Bash or WSL'
            }
        } else {
            Done
        }
    } finally { Pop-Location }
}

function Configure-EccEnv {
    Step 'Configuring CLAUDE_PLUGIN_ROOT'
    $settings = Join-Path $HOME '.claude\settings.json'
    $eccCache = Join-Path $HOME '.claude\plugins\cache\ecc'
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

function Create-GlobalClaudeMd {
    Step 'Creating ~/.claude/CLAUDE.md'
    $claudeMd = Join-Path $HOME '.claude\CLAUDE.md'
    if (Test-Path $claudeMd) { Info 'CLAUDE.md already exists — skipping'; return }
    Pending 'Writing CLAUDE.md'
    $content = @'
## Language
- สื่อสารกับผู้ใช้เป็นภาษาไทยเสมอ (ยกเว้น code, commit message, และไฟล์ .md ที่ต้องเขียนเป็นภาษาอังกฤษ)

## Design Principles
- **Single Source of Truth + DRY** — เวลาดีไซน์หรือ refactor โปรเจคใดก็ตาม ให้ logic/config/state อยู่ที่เดียว ไม่ duplicate ข้ามไฟล์ ถ้ามีหลายไฟล์ใช้ข้อมูลเดียวกัน ให้ import จากแหล่งเดียว อย่า copy (Don't Repeat Yourself)
- **SOLID** — เวลาเขียน OOP ให้ยึดหลัก SOLID เสมอ:
  - **S** Single Responsibility — class/module ทำหน้าที่เดียว
  - **O** Open/Closed — เปิดให้ extend, ปิดไม่ให้แก้ของเดิม
  - **L** Liskov Substitution — subclass แทน parent ได้เสมอโดยไม่พัง
  - **I** Interface Segregation — ไม่บังคับ implement method ที่ไม่ใช้
  - **D** Dependency Inversion — ขึ้นกับ abstraction ไม่ใช่ concrete class

## Code Reading
- **Read deeply, never skim** — when reading code, trace every function call to its actual implementation. Do not stop at variable names or function signatures and assume behavior. Follow the entire call chain to understand what really happens.
- If a function calls another function, read that inner function too. Repeat until you reach the actual logic. Surface-level reading leads to wrong conclusions.

## Debugging
- **ห้ามเดา** — ถ้าอยากรู้ behavior ของ code/library/protocol ให้เพิ่ม log/inspect เพื่อยืนยันเสมอ ห้ามเดาจากการอ่านโค้ดอย่างเดียว
- เมื่อไม่แน่ใจว่า data flow ไปถึงจุดไหน → เพิ่ม logger/interceptor ก่อนทำอย่างอื่น
- ถ้าแก้โค้ดไปแล้ว 2 ครั้งแต่ user ยังบอกว่าผิดอยู่ → หยุดเดา แล้วเพิ่ม debug log เข้าไปในโค้ดเพื่อตรวจสอบค่าจริงก่อนแก้ต่อ

## Documentation
- All `.md` files must be written in English only

## Git
- ห้ามใส่ `Co-Authored-By` ใน commit message ทุกกรณี
- Commit message ใส่แค่ title บรรทัดเดียว ไม่ต้องมี description/body

## Configuration & Constants
- **ห้าม hardcode ค่าใดๆ ในโค้ด** — ทุก config, secret, constant, URL, หรือค่าที่อาจเปลี่ยนแปลงได้ ต้องเก็บในไฟล์ config หรือ environment variable เสมอ (เช่น `.env`, `config.ts`, `constants.ts`)
- ถ้าเจอค่า hardcode ในโค้ดที่มีอยู่แล้ว ให้ย้ายออกมาก่อนทำงานต่อ

## Error Handling
- **No fallback systems** — if an operation fails, throw the error immediately. Do not implement fallback/retry/graceful-degradation patterns. If there is a problem, the error must surface so it can be diagnosed and fixed properly.

## Performance
- เมื่อมีงานที่ทำ parallel ได้ (ไม่มี dependency ระหว่างกัน) ให้ spawn agent หลายตัวพร้อมกันเสมอ เพื่อให้เสร็จเร็วที่สุด

## Frontend Aesthetics
- Avoid generic "AI slop" design. Make creative, distinctive frontends that surprise and delight.
- **Typography**: Choose beautiful, unique fonts. Avoid Inter, Roboto, Arial, system fonts. Pick distinctive fonts that elevate the aesthetic.
- **Color & Theme**: Commit to a cohesive aesthetic with CSS variables. Use dominant colors with sharp accents — avoid timid, evenly-distributed palettes. Draw from IDE themes and cultural aesthetics.
- **Motion**: Use animations for micro-interactions. Prefer CSS-only for HTML, Motion library for React. One well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.
- **Backgrounds**: Create atmosphere and depth — layer CSS gradients, geometric patterns, or contextual effects instead of solid colors.
- **Avoid**: purple gradients on white, predictable layouts, cookie-cutter components, overused font families (Space Grotesk included).
- Vary between light/dark themes and different aesthetics per project context. Think outside the box every time.
'@
    [System.IO.File]::WriteAllText($claudeMd, $content, [System.Text.Encoding]::UTF8)
    Done
}

function Install-ClaudeStack {
    Check-Claude
    Add-Marketplaces
    Install-Dependencies
    Install-EccRules
    Configure-EccEnv
    Install-McpServers
    Create-GlobalClaudeMd
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
