# Dotfiles

GNU Stow-based dotfiles repo. Target is `~` (parent dir).

## Stow Packages

| Package | Command | Target |
|---------|---------|--------|
| config | `stow --no-folding -t ~/.config config` | All XDG `~/.config/*` tools (nvim, i3, tmux, alacritty, zsh, git, oh-my-posh) |
| claude | `stow --no-folding claude` | `~/.claude/` (settings, hooks, keybindings) |
| — | `ln -sf` (manual) | `~/.zshenv` → `config/zsh/.zshenv` |

## After Making Changes

Run `./update.sh` to re-stow all packages. This uses `--restow` to clean stale symlinks and re-create them.

## Devcontainer

`devcontainer/` contains a base Docker image for running Claude Code in an isolated sandbox with a default-deny firewall.

**Build the base image once:**
```bash
./devcontainer/build.sh
```

**Use in a project** — copy `devcontainer/devcontainer.json` into the project as `.devcontainer/devcontainer.json`, then customize with features:
```json
{
  "name": "Claude Code Sandbox",
  "image": "claude-sandbox:latest",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {}
  }
}
```

**Launch from terminal:**
```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . claude
```

The container mounts `~/.claude` from host for auth. Rebuild the base image after updating the Dockerfile or firewall script.

## Key Rules

- Use `--no-folding` on all stow commands so directories stay real (allows untracked local files like `local.zsh`, tmux `plugins/`, etc.)
- Secrets go in `~/.config/zsh/local.zsh` (not tracked)
- Machine-specific git email goes in `~/.config/git/local` (not tracked)
- Global gitignore is at `~/.config/git/ignore` (stow ignores files named `.gitignore`)
- Do not add `.config/` nesting inside package dirs — the `config` package targets `~/.config` directly
