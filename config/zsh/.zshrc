# ------------------ CUSTOM COMMANDS ------------------
# ------- Common Aliases -------
alias vim="nvim"
alias vi="nvim"
alias avenv="source .venv/bin/activate"

# ------- Tokens -------
# Secrets live in local.zsh which is NOT tracked in dotfiles
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# ------- Git Worktree Manager -------
[[ -f "$ZDOTDIR/worktree.zsh" ]] && source "$ZDOTDIR/worktree.zsh"
source "$ZDOTDIR/help.zsh"

# ------- Add tools to path -------
export EDITOR=nvim
# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# nvim
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# go
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/bin/go"
export PATH="$PATH:$HOME/bin/go/bin"
# misc
export PATH=$PATH:$HOME/bin

# ------- Add tools to path -------
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Auto-start tmux for interactive shells
if [[ -z "$TMUX" && -n "$PS1" ]]; then
  tmux attach -t main || tmux new -s main
fi

# Claude settings
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000

# ------------------ CUSTOM COMMANDS FINISHED ------------------  

# Configure history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Scaleway CLI autocomplete initialization.
command -v scw >/dev/null 2>&1 && eval "$(scw autocomplete script shell=zsh)"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# Which plugins would you like to load?
# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker kubectl npm python pip)

source $ZSH/oh-my-zsh.sh

# Modern replacements (must be after oh-my-zsh to override its aliases)
alias ls="eza --icons=always"
alias ll="eza --icons=always -la"
alias tree="eza --icons=always --tree"
alias cat="bat"
alias top="btop"
alias du="dust"
alias find="fd"
alias grep="rg"

# External plugins (managed as git submodules in dotfiles)
source "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Oh-My-Posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

# Source after oh-my-posh to avoid widget conflicts
source "$ZDOTDIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
source "$ZDOTDIR/plugins/fzf-tab/fzf-tab.plugin.zsh"
source "$ZDOTDIR/fzf-tab.zsh"

# Zoxide
eval "$(zoxide init zsh --cmd cd)"

