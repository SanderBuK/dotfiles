# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
dotfiles/
├── config/          → ~/.config/* (stow -t ~/.config)
│   ├── alacritty/
│   ├── git/         config + global ignore
│   ├── i3/
│   ├── nvim/        NvChad
│   ├── oh-my-posh/
│   ├── tmux/
│   └── zsh/         .zshrc, .zprofile, .zshenv
├── claude/          → ~/.claude/ (stow --no-folding)
└── install.sh
```

## Fresh machine setup

```bash
git clone git@github.com:SanderBuK/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:
1. Install Homebrew, GNU Stow, oh-my-zsh, oh-my-posh, Neovim, tmux + TPM, zoxide, nvm
2. Stow packages and symlink `~/.zshenv`
3. Create `~/.config/zsh/local.zsh` and `~/.config/git/local` as templates

## Secrets

API keys and tokens live in `~/.config/zsh/local.zsh` (never committed, sourced by `.zshrc`).

## Managing packages

```bash
cd ~/dotfiles

# Stow the config package
stow --no-folding -t ~/.config config

# Symlink zshenv (not managed by stow)
ln -sf ~/dotfiles/config/zsh/.zshenv ~/.zshenv

# Remove config symlinks
stow -t ~/.config -D config
```

## zsh + ZDOTDIR

`~/.zshenv` sets `ZDOTDIR=$HOME/.config/zsh` so zsh loads config from
`~/.config/zsh/` instead of `~/`. The config package is stowed with
`--no-folding` so `~/.config/zsh/` remains a real directory, allowing
`local.zsh` to live there untracked.
