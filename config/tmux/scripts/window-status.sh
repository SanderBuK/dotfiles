#!/usr/bin/env bash
# window-status.sh — single solid block per window: [icon name]
# Args: session window_index window_name pane_path is_current(0|1)

session="$1"
window="$2"
name="$3"
path="$4"
current="$5"
window_id="$6"

case "${name,,}" in
  claude)            icon="󰚩" ;;
  nvim|neovim|vim)   icon="" ;;
  zsh|bash|sh|fish)  icon="󰆍" ;;
  ssh)               icon="󰒍" ;;
  npm)               icon="󰎙" ;;
  git|lazygit)       icon="" ;;
  docker|lazydocker) icon="" ;;
  k9s)               icon="󰩃" ;;
  *)                 icon="$window" ;;
esac

waiting=0
[ -f "/tmp/claude-waiting/${session}_${window_id}" ] && waiting=1

if [ "$waiting" = "1" ] && [ "${name,,}" = "claude" ]; then
    if [ "$current" = "1" ]; then
        printf '#[fg=colour232,bg=#fab387] %s %s #[fg=red]● #[default]' "$icon" "$name"
    else
        printf '#[fg=#1e1e2e,bg=#89b4fa] %s %s #[fg=red]● #[default]' "$icon" "$name"
    fi
elif [ "$current" = "1" ]; then
    printf '#[fg=colour232,bg=#fab387] %s %s #[default]' "$icon" "$name"
else
    printf '#[fg=#1e1e2e,bg=#89b4fa] %s %s #[default]' "$icon" "$name"
fi
