# Git worktree manager -- interactive fzf picker
# Usage: run `wt` inside any git repo

wt() {
  # Must be in a git repo
  local repo_root
  repo_root=$(git rev-parse --git-common-dir 2>/dev/null) || {
    echo "Not in a git repository" >&2
    return 1
  }
  # --git-common-dir returns the .git dir (possibly relative); resolve to absolute then take parent
  repo_root="$(cd "$repo_root" && pwd)"
  repo_root="${repo_root%/.git}"

  # Require fzf
  if ! command -v fzf &>/dev/null; then
    echo "fzf is required: brew install fzf" >&2
    return 1
  fi

  local current_dir="$PWD"
  local wt_dir="$repo_root/.worktrees"

  # Build worktree list: "path<TAB>label"
  # Porcelain format: blocks separated by blank lines, each block has
  # "worktree <path>", "HEAD <sha>", optionally "branch refs/heads/<name>", etc.
  # Detect default branch (main or master)
  local default_branch
  default_branch=$(git -C "$repo_root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  [[ -z "$default_branch" ]] && default_branch="main"

  local -a entries=()
  local wt_path="" wt_branch="" dirty="" changed="" marker="" label="" behind_ahead="" counts="" behind="" ahead="" parts=""
  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      wt_path="${line#worktree }"
      wt_branch=""
    elif [[ "$line" == branch\ * ]]; then
      wt_branch="${line#branch refs/heads/}"
    elif [[ "$line" == detached ]]; then
      wt_branch="(detached)"
    elif [[ -z "$line" && -n "$wt_path" ]]; then
      # Blank line = end of block
      [[ -z "$wt_branch" ]] && wt_branch="(detached)"

      # ANSI color codes
      local c_reset=$'\033[0m'
      local c_green=$'\033[32m'
      local c_magenta=$'\033[35m'
      local c_yellow=$'\033[33m'
      local c_cyan=$'\033[36m'
      local c_dim=$'\033[2m'

      dirty=""
      changed=$(git -C "$wt_path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if (( changed > 0 )); then
        dirty=" ${c_yellow}${changed} changed${c_reset}"
      fi

      behind_ahead=""
      if [[ "$wt_branch" != "(detached)" && "$wt_branch" != "$default_branch" ]]; then
        counts=$(git -C "$repo_root" rev-list --left-right --count "origin/${default_branch}...${wt_branch}" 2>/dev/null)
        if [[ -n "$counts" ]]; then
          behind=${counts%%$'\t'*}
          ahead=${counts##*$'\t'}
          parts=""
          (( behind > 0 )) && parts+="${c_cyan}↓${behind}${c_reset}"
          (( ahead > 0 )) && parts+="${parts:+ }${c_green}↑${ahead}${c_reset}"
          [[ -n "$parts" ]] && behind_ahead=" ${parts}"
        fi
      fi

      marker=""
      [[ "$wt_path" == "$(git -C "$current_dir" rev-parse --show-toplevel 2>/dev/null)" ]] && marker=" ${c_magenta}*${c_reset}"

      local branch_display="${wt_branch}"
      if [[ "$wt_path" == "$repo_root" ]]; then
        label="${branch_display} ${c_dim}(repo root)${c_reset}${marker}${dirty}${behind_ahead}"
      else
        label="${branch_display}${marker}${dirty}${behind_ahead}"
      fi
      entries+=("${wt_path}	${label}")
      wt_path=""
      wt_branch=""
    fi
  done < <(git worktree list --porcelain 2>/dev/null; echo)

  # Add "new branch" option
  entries+=("__new__	[+ new branch]")
  entries+=("__existing__	[+ existing branch]")

  # Run fzf picker
  local selected
  selected=$(
    printf '%s\n' "${entries[@]}" |
    awk -F'\t' '{ print $2 "\t" $1 }' |
    fzf --ansi \
        --no-sort \
        --height=~40% \
        --layout=reverse \
        --no-input \
        --no-separator \
        --header="enter:switch  d:delete  ctrl-c:cancel" \
        --header-first \
        --with-nth=1 \
        --delimiter=$'\t' \
        --expect=d \
        --bind='d:accept,j:down,k:up'
  )

  [[ -z "$selected" ]] && return 0

  local key action_path
  key=$(head -1 <<< "$selected")
  local selection
  selection=$(tail -1 <<< "$selected")
  action_path=$(echo "$selection" | awk -F'\t' '{ print $NF }')

  # Handle delete
  if [[ "$key" == "d" ]]; then
    if [[ "$action_path" == "__new__" || "$action_path" == "__existing__" ]]; then
      return 0
    fi
    _wt_delete "$action_path" "$repo_root"
    return $?
  fi

  # Handle new branch
  if [[ "$action_path" == "__new__" ]]; then
    _wt_create "$repo_root"
    return $?
  fi

  # Handle existing branch
  if [[ "$action_path" == "__existing__" ]]; then
    _wt_checkout_existing "$repo_root"
    return $?
  fi

  # Switch to selected worktree
  cd "$action_path" || return 1
}

_wt_create() {
  local repo_root="$1"
  local wt_dir="$repo_root/.worktrees"

  printf "Branch name: "
  local branch
  read -r branch
  [[ -z "$branch" ]] && return 0

  mkdir -p "$wt_dir"
  # Sanitize branch name for directory (replace / with -)
  local dir_name="${branch//\//-}"
  local wt_path="$wt_dir/$dir_name"

  # Check if remote branch exists
  if git -C "$repo_root" show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
    git -C "$repo_root" worktree add "$wt_path" "$branch" || return 1
    echo "Tracking remote branch: $branch"
  else
    git -C "$repo_root" worktree add -b "$branch" "$wt_path" || return 1
    echo "Created new branch: $branch"
  fi

  cd "$wt_path" || return 1
}

_wt_checkout_existing() {
  local repo_root="$1"
  local wt_dir="$repo_root/.worktrees"

  # Collect branches that already have worktrees
  local -a wt_branches=()
  local line
  while IFS= read -r line; do
    if [[ "$line" == branch\ * ]]; then
      wt_branches+=("${line#branch refs/heads/}")
    fi
  done < <(git worktree list --porcelain 2>/dev/null)

  # Build deduplicated branch list (local first, then remote-only)
  local -a branches=()
  local -A seen=()
  local ref short

  while IFS= read -r ref; do
    short="${ref#refs/heads/}"
    seen[$short]=1
    branches+=("$short")
  done < <(git -C "$repo_root" for-each-ref --format='%(refname)' refs/heads/)

  while IFS= read -r ref; do
    short="${ref#refs/remotes/origin/}"
    [[ "$short" == "HEAD" ]] && continue
    [[ -n "${seen[$short]+x}" ]] && continue
    seen[$short]=1
    branches+=("$short")
  done < <(git -C "$repo_root" for-each-ref --format='%(refname)' refs/remotes/origin/)

  # Filter out branches that already have a worktree
  local -a available=()
  local b wb skip
  for b in "${branches[@]}"; do
    skip=0
    for wb in "${wt_branches[@]}"; do
      [[ "$b" == "$wb" ]] && { skip=1; break; }
    done
    (( skip )) || available+=("$b")
  done

  if (( ${#available[@]} == 0 )); then
    echo "No available branches without worktrees" >&2
    return 1
  fi

  # fzf picker with search enabled for fuzzy finding
  local branch
  branch=$(
    printf '%s\n' "${available[@]}" |
    fzf --ansi \
        --height=~40% \
        --layout=reverse \
        --no-separator \
        --header="Select branch (type to filter)" \
        --header-first
  )

  [[ -z "$branch" ]] && return 0

  # Create worktree for the selected branch
  mkdir -p "$wt_dir"
  local dir_name="${branch//\//-}"
  local wt_path="$wt_dir/$dir_name"

  if git -C "$repo_root" show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
    git -C "$repo_root" worktree add "$wt_path" "$branch" || return 1
    echo "Tracking remote branch: $branch"
  else
    git -C "$repo_root" worktree add "$wt_path" "$branch" || return 1
    echo "Checked out local branch: $branch"
  fi

  cd "$wt_path" || return 1
}

_wt_delete() {
  local wt_path="$1"
  local repo_root="$2"

  if [[ "$wt_path" == "$repo_root" ]]; then
    echo "Cannot delete the main worktree" >&2
    return 1
  fi

  local branch
  branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)

  printf "Delete worktree '%s'? [y/N] " "$branch"
  local confirm
  read -r confirm
  [[ "$confirm" != [yY] ]] && return 0

  # Move out if we're inside the worktree being deleted
  if [[ "$PWD" == "$wt_path"* ]]; then
    cd "$repo_root" || return 1
  fi

  git -C "$repo_root" worktree remove "$wt_path" --force 2>/dev/null ||
    git -C "$repo_root" worktree remove "$wt_path"

  git -C "$repo_root" worktree prune
  echo "Removed worktree: $branch"

  printf "Also delete branch '%s'? [y/N] " "$branch"
  local del_branch
  read -r del_branch
  if [[ "$del_branch" == [yY] ]]; then
    git -C "$repo_root" branch -d "$branch" 2>/dev/null ||
      git -C "$repo_root" branch -D "$branch"
    echo "Deleted branch: $branch"
  fi
}
