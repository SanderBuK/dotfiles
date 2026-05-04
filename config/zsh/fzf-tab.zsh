# fzf-tab configuration
# Requires: eza, bat, delta

# Completion styling
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no

# Show hidden files & directories in all tab completions
_comp_options+=(globdots)
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags \
  --bind=alt-bspace:abort \
  --bind=ctrl-h:abort \
  --bind=ctrl-l:abort \
  --bind=ctrl-d:preview-down+preview-down+preview-down+preview-down+preview-down \
  --bind=ctrl-u:preview-up+preview-up+preview-up+preview-up+preview-up \
  --bind=ctrl-f:change-preview-window:90%\|50% \
  --preview-window=wrap
zstyle ':fzf-tab:*' continuous-trigger space
zstyle ':fzf-tab:*' fzf-min-height 50

# Fix: fzf clears terminal state but fast-syntax-highlighting skips re-highlight
# because the buffer is unchanged. Clearing its cache forces re-apply on redisplay.
fzf-tab-complete-and-rehighlight() {
  zle fzf-tab-complete
  _ZSH_HIGHLIGHT_PRIOR_BUFFER=""
  zle redisplay
}
zle -N fzf-tab-complete-and-rehighlight
bindkey '^I' fzf-tab-complete-and-rehighlight

# Disable preview for flags/options — must be before command-specific previews (zstyle uses first match)
zstyle ':fzf-tab:complete:*:options' fzf-preview

# Directory previews (ls/ll/tree alias to eza, cd uses its own)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza -1 --color=always --icons=always $realpath 2>/dev/null'

# File previews (cat aliases to bat, vim aliases to nvim)
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'if [[ -d $realpath ]]; then eza -1 --color=always --icons=always $realpath; elif [[ -f $realpath ]]; then bat --color=always --style=numbers --line-range=:100 ${(Q)realpath}; fi 2>/dev/null'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:100 ${(Q)realpath} 2>/dev/null || eza -1 --color=always --icons=always $realpath 2>/dev/null'

# Git previews (context is "git" for all subcommands)
# $realpath is non-empty for files, empty for flags/branches/refs
zstyle ':fzf-tab:complete:git:*' fzf-preview \
  'word=${word%% }
   diff_output="$(git diff -- "$word" 2>/dev/null; git diff --cached -- "$word" 2>/dev/null)"
   if [[ -n "$diff_output" ]]; then
     echo "$diff_output" | delta --paging=never --file-decoration-style=none
   elif git rev-parse --verify "$word" &>/dev/null; then
     git log --color=always --format="%C(yellow)%h %C(cyan)%ar %C(reset)%s %C(blue)- %an" -20 "$word"
   fi'

# Process previews
zstyle ':fzf-tab:complete:kill:argument-rest:*' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
