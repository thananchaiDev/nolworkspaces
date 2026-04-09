#!/bin/bash
set -e

echo "=== Setup Script (mac) ==="
echo ""

# --------------------------------------------------
# 1. Homebrew
# --------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed"
fi

# --------------------------------------------------
# 2. Homebrew formulae
# --------------------------------------------------
# Tap for Bun
brew tap oven-sh/bun 2>/dev/null || true

FORMULAE=(
  oven-sh/bun/bun
  gh
  lazygit
  mas
  mysql-client
  node
  pnpm
  python@3.13
  yarn
  jq
  zsh-autosuggestions
  zsh-syntax-highlighting
)

echo ""
echo "Installing Homebrew formulae..."
for formula in "${FORMULAE[@]}"; do
  if brew list "$formula" &>/dev/null; then
    echo "  $formula already installed"
  else
    brew install "$formula"
  fi
done

# --------------------------------------------------
# 3. Homebrew casks (GUI apps)
# --------------------------------------------------
CASKS=(
  warp
  1password
  visual-studio-code
  microsoft-teams
  docker
  flutter
  android-studio
)

echo ""
echo "Installing Homebrew casks (parallel)..."
for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    echo "  $cask already installed"
  else
    brew install --cask --adopt "$cask" &
  fi
done
wait

# --------------------------------------------------
# 4. Oh My Zsh
# --------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo ""
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo ""
  echo "Oh My Zsh already installed"
fi

# --------------------------------------------------
# 5. Xcode
# --------------------------------------------------
echo ""
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "  Waiting for Xcode CLT to finish before continuing..."
  until xcode-select -p &>/dev/null; do sleep 5; done
fi

if ! mas list | grep -q "497799835"; then
  echo "Installing Xcode from App Store..."
  mas install 497799835
else
  echo "Xcode already installed"
fi

# --------------------------------------------------
# 6. pip packages
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
    pip3 install "$pkg" --break-system-packages
  fi
done

# --------------------------------------------------
# 7. Claude Code CLI
# --------------------------------------------------
if ! command -v claude &>/dev/null; then
  echo ""
  echo "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code 2>/dev/null || echo "  Skipped (npm not available yet — install via bun/node later)"
else
  echo "Claude Code already installed"
fi

# --------------------------------------------------
# 8. macOS defaults
# --------------------------------------------------
echo ""
echo "Applying macOS defaults..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

killall Finder 2>/dev/null || true

# --------------------------------------------------
# Done
# --------------------------------------------------
echo ""
echo "=== Setup complete! ==="
