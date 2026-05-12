#!/usr/bin/env bash
# window-status.sh — single solid block per window: [icon name <markers>]
# Args: session window_index window_name pane_path is_current(0|1) window_id pane_in_mode(0|1) pane_current_command zoomed(0|1)

session="$1"
window="$2"
name="$3"
path="$4"
current="$5"
window_id="$6"
in_mode="$7"
current_command="$8"
zoomed="$9"

# In copy mode tmux renames the window to "[tmux]" — fall back to the
# underlying process so you can still tell what's running.
if [ "$in_mode" = "1" ] && [ "$name" = "[tmux]" ] && [ -n "$current_command" ]; then
    name="$current_command"
fi

case "${name,,}" in
  claude)            icon="󰚩" ;;
  nvim|neovim|vim)   icon="" ;;
  zsh|bash|sh|fish)  icon="󰆍" ;;
  ssh)               icon="󰒍" ;;
  npm)               icon="󰎙" ;;
  git|lazygit)       icon="" ;;
  docker|lazydocker) icon="" ;;
  k9s)               icon="󰩃" ;;
  make)              icon="" ;;
  *)                 icon="$window" ;;
esac

waiting=0
[ -f "/tmp/claude-waiting/${session}_${window_id}" ] && waiting=1

# Pill color — priority: copy mode (current) > zoom > current > inactive
if [ "$in_mode" = "1" ] && [ "$current" = "1" ]; then
    fg="#1e1e2e"; bg="#a6e3a1"; bold=",bold"
elif [ "$zoomed" = "1" ] && [ "$current" = "1" ]; then
    fg="#1e1e2e"; bg="#cba6f7"; bold=",bold"
elif [ "$current" = "1" ]; then
    fg="colour232"; bg="#fab387"; bold=""
else
    fg="#1e1e2e"; bg="#89b4fa"; bold=""
fi

# Inline marker glyphs (icon-only, no text)
markers=""
[ "$in_mode" = "1" ] && [ "$current" = "1" ] && markers="$markers "
[ "$zoomed" = "1" ] && [ "$current" = "1" ] && markers="$markers "

# Claude-waiting red dot suffix
suffix=""
if [ "$waiting" = "1" ] && [ "${name,,}" = "claude" ]; then
    suffix=" #[fg=red]●"
fi

printf "#[fg=%s,bg=%s%s] %s %s%s%s #[default]" "$fg" "$bg" "$bold" "$icon" "$name" "$markers" "$suffix"

