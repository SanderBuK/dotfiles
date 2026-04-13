#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"

echo "==> Installing dotfiles from $DOTFILES_DIR"

# ── Dependencies ────────────────────────────────────────────────────────────

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "--> Installing Homebrew (Linuxbrew)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    echo "--> Homebrew already installed"
  fi
}

install_stow() {
  if ! command -v stow &>/dev/null; then
    echo "--> Installing GNU Stow..."
    sudo apt-get install -y stow 2>/dev/null || brew install stow
  else
    echo "--> GNU Stow already installed"
  fi
}

install_zsh_tools() {
  # oh-my-zsh
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "--> Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # zsh-autosuggestions
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [[ ! -d "$custom/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
  fi

  # zsh-syntax-highlighting
  if [[ ! -d "$custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
  fi
}

install_oh_my_posh() {
  if ! command -v oh-my-posh &>/dev/null; then
    echo "--> Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
  fi
}

install_nvim() {
  if ! command -v nvim &>/dev/null; then
    echo "--> Installing Neovim..."
    local version="v0.10.4"
    curl -LO "https://github.com/neovim/neovim/releases/download/$version/nvim-linux-x86_64.tar.gz"
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  fi
}

install_tmux() {
  if ! command -v tmux &>/dev/null; then
    echo "--> Installing tmux..."
    sudo apt-get install -y tmux 2>/dev/null || brew install tmux
  fi
  # TPM (Tmux Plugin Manager)
  if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
  fi
}

install_zoxide() {
  if ! command -v zoxide &>/dev/null; then
    echo "--> Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi
}

install_fzf() {
  if ! command -v fzf &>/dev/null; then
    echo "--> Installing fzf..."
    brew install fzf
  fi
}

install_nvm() {
  if [[ ! -d "$HOME/.nvm" ]]; then
    echo "--> Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
}

install_arandr() {
  if ! command -v arandr &>/dev/null; then
    echo "--> Installing arandr (GUI for arranging monitors)..."
    sudo apt-get install -y arandr 2>/dev/null || true
  fi
}

# ── Stow packages ────────────────────────────────────────────────────────────

stow_packages() {
  cd "$DOTFILES_DIR"

  echo "--> Stowing packages..."

  # config: all XDG ~/.config/* tools in one package (target is ~/.config, not ~)
  # --no-folding keeps dirs real so untracked files (local.zsh, tmux plugins/) can coexist
  stow --no-folding --target="$TARGET_DIR/.config" config

  # zshenv: must live at ~/.zshenv (zsh doesn't support XDG for this file)
  ln -sf "dotfiles/config/zsh/.zshenv" "$TARGET_DIR/.zshenv"

  # claude: ~/.claude/ settings, hooks, keybindings
  # --no-folding so cache, history, plugins/ etc. can live there untracked
  stow --no-folding --target="$TARGET_DIR" claude

  echo "--> All packages stowed"
}

# ── Post-stow setup ───────────────────────────────────────────────────────────

setup_local_zsh() {
  local local_zsh="$HOME/.config/zsh/local.zsh"
  if [[ ! -f "$local_zsh" ]]; then
    echo "--> Creating $local_zsh (add your secrets here)..."
    cat > "$local_zsh" <<'EOF'
# Local secrets — NOT tracked in dotfiles
# Populate these values on each machine.

# export OPENAI_API_KEY=
# export GEMINI_API_KEY=

# ------- Work-specific aliases & kubernetes -------
# Add your work aliases here
EOF
    echo "    Edit $local_zsh and fill in your secrets."
  else
    echo "--> $local_zsh already exists, skipping"
  fi
}

setup_local_gitconfig() {
  local local_git="$HOME/.config/git/local"
  if [[ ! -f "$local_git" ]]; then
    echo "--> Creating $local_git (add your git email here)..."
    mkdir -p "$HOME/.config/git"
    cat > "$local_git" <<'EOF'
[user]
	email = you@example.com
EOF
    echo "    Edit $local_git and set your email."
  else
    echo "--> $local_git already exists, skipping"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

install_homebrew
install_stow
install_zsh_tools
install_oh_my_posh
install_nvim
install_tmux
install_zoxide
install_fzf
install_nvm
install_arandr
stow_packages
setup_local_zsh
setup_local_gitconfig

echo ""
echo "Done! Restart your shell or run: source ~/.zshenv && source \$ZDOTDIR/.zshrc"
