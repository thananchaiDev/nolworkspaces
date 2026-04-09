#!/bin/bash
set -e

echo "=== Setup Script (linux) ==="
echo ""

# --------------------------------------------------
# 1. Build dependencies
# --------------------------------------------------
echo "Ensuring build dependencies..."
if command -v apt-get &>/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq build-essential curl file git jq mysql-client
  echo "Installing lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
fi

# --------------------------------------------------
# 2. Node.js (via nvm)
# --------------------------------------------------
if ! command -v node &>/dev/null; then
  echo ""
  echo "Installing Node.js via nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
  nvm alias default node
else
  echo "Node.js already installed: $(node -v)"
fi

# --------------------------------------------------
# 3. npm (bundled with Node.js — upgrade to latest)
# --------------------------------------------------
echo ""
if command -v npm &>/dev/null; then
  echo "Upgrading npm to latest..."
  npm install -g npm@latest
else
  echo "npm not found — it should come with Node.js"
fi

# --------------------------------------------------
# 4. Yarn
# --------------------------------------------------
echo ""
if ! command -v yarn &>/dev/null; then
  echo "Installing Yarn..."
  npm install -g yarn
else
  echo "Yarn already installed: $(yarn -v)"
fi

# --------------------------------------------------
# 5. pnpm
# --------------------------------------------------
echo ""
if ! command -v pnpm &>/dev/null; then
  echo "Installing pnpm..."
  npm install -g pnpm
else
  echo "pnpm already installed: $(pnpm -v)"
fi

# --------------------------------------------------
# 6. Bun
# --------------------------------------------------
echo ""
if ! command -v bun &>/dev/null; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
else
  echo "Bun already installed: $(bun -v)"
fi

# --------------------------------------------------
# 7. pip packages
# --------------------------------------------------
echo ""
echo "Installing pip packages..."
PIP_PACKAGES=(
  mempalace
)

for pkg in "${PIP_PACKAGES[@]}"; do
  if pip3 show "$pkg" &>/dev/null 2>&1; then
    echo "  $pkg already installed"
  else
    pip3 install "$pkg" --break-system-packages 2>/dev/null || pip3 install "$pkg"
  fi
done

# --------------------------------------------------
# Done
# --------------------------------------------------
echo ""
echo "=== Setup complete! ==="
echo ""
echo "NOTE: Restart your terminal (or run 'source ~/.bashrc') to apply PATH changes."
