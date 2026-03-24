#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"

echo "==> Updating dotfiles symlinks from $DOTFILES_DIR"

cd "$DOTFILES_DIR"

# Remove manual zshenv symlink before restow (stow doesn't own it and gets confused)
rm -f "$TARGET_DIR/.zshenv"

# Re-stow config package (--restow cleans stale links then re-creates)
stow --no-folding --restow --target="$TARGET_DIR/.config" config

# Re-link zshenv with relative path (must be manual — zsh doesn't support XDG for this file)
ln -sf "dotfiles/config/zsh/.zshenv" "$TARGET_DIR/.zshenv"

# Re-stow claude package
stow --no-folding --restow --target="$TARGET_DIR" claude

echo "==> Symlinks updated"
