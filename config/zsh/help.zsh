# Dotfiles help command — quick reference for installed tools
help() {
  bat --style=plain --paging=always <<'EOF'

  Dotfiles Tool Reference
  =======================

  ALIASED (muscle memory works)
  ─────────────────────────────
  ls       → eza         Colorized file listing with icons
  ll                     eza -la (long listing with hidden files)
  tree                   eza --tree (recursive tree view)
  cat      → bat         Syntax-highlighted file viewer
  top      → btop        Interactive system monitor (CPU/RAM/disk/net)
  du       → dust        Visual disk usage breakdown
  find     → fd          Fast file finder (respects .gitignore)
  grep     → rg          Fast content search (respects .gitignore)
  vim/vi   → nvim        Neovim
  cd       → zoxide      Smart directory jumper (learns your habits)

  STANDALONE
  ──────────
  delta                  Pretty git diffs (auto-configured as git pager)
  fzf                    Fuzzy finder (powers Tab completion)

  QUICK EXAMPLES
  ──────────────
  ls                     List files with icons
  ll                     Detailed listing with permissions, size, git status
  tree -L 2              Tree view, 2 levels deep
  cat file.py            View file with syntax highlighting
  bat file.py            Same (unaliased, with line numbers + header)
  fd .json               Find all .json files
  fd -e py test          Find .py files matching "test"
  rg "TODO"              Search file contents for "TODO"
  rg "func" -t go        Search only Go files
  dust                   Show what's using disk space
  dust -d 2              Disk usage, 2 directories deep

  FZF-TAB (Tab Completion)
  ────────────────────────
  Pressing Tab opens a fuzzy finder with context-aware previews.

  Navigation
    Tab                  Open completions / accept selection
    Esc                  Close without selecting
    Alt+Backspace        Close without selecting
    Ctrl+H               Close (free for tmux navigation)
    Ctrl+L               Close (free for tmux navigation)
    Space                Enter directory (continuous completion)
    < / >                Switch between completion groups
    ↑ / ↓                Navigate completion list
    Type to filter       Fuzzy search narrows the list

  Preview Controls
    Ctrl+D               Scroll preview down
    Ctrl+U               Scroll preview up
    Ctrl+F               Toggle preview size (50% ↔ 90%)

  What Gets Previewed
    cd <Tab>             Directory contents
    ls <Tab>             Directory contents
    cat <Tab>            File contents / directory listing
    nvim <Tab>           File contents / directory listing
    git add <Tab>        Diff of uncommitted changes
    git diff <Tab>       Diff of changes
    git checkout <Tab>   Recent commits on branch
    kill <Tab>           Process command info
    Any flags (--*)      No preview (clean flag list)

  SHELL FEATURES
  ──────────────
  Ghost text             History suggestions as you type
  → (right arrow)        Accept autosuggestion
  Syntax highlighting    Commands colored as you type (red = error)
  Transient prompt       Previous prompts collapse with timestamp
  help                   This reference

EOF
}
