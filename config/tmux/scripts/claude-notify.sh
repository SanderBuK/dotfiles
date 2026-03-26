#!/usr/bin/env bash
# claude-notify.sh — set or clear Claude waiting flag files
# Usage: claude-notify.sh set | clear

set -euo pipefail

ACTION="${1:-}"
LOG="/tmp/claude-notify-debug.log"

if [[ -z "$ACTION" ]]; then
  echo "Usage: claude-notify.sh set|clear" >&2
  exit 1
fi

# Guard: skip if not inside tmux
if [[ -z "${TMUX:-}" ]] || [[ -z "${TMUX_PANE:-}" ]]; then
  echo "$(date '+%H:%M:%S') $ACTION SKIP no-tmux TMUX=${TMUX:-} PANE=${TMUX_PANE:-}" >> "$LOG"
  exit 0
fi

SESSION=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null) || { echo "$(date '+%H:%M:%S') $ACTION SKIP session-fail pane=$TMUX_PANE" >> "$LOG"; exit 0; }
WINDOW=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null) || { echo "$(date '+%H:%M:%S') $ACTION SKIP window-fail pane=$TMUX_PANE" >> "$LOG"; exit 0; }
FLAG="/tmp/claude-waiting/${SESSION}_${WINDOW}"

case "$ACTION" in
  set)
    mkdir -p /tmp/claude-waiting
    touch "$FLAG"
    echo "$(date '+%H:%M:%S') SET ${SESSION}_${WINDOW} pane=$TMUX_PANE" >> "$LOG"
    tmux refresh-client -a -S 2>/dev/null || true
    notify-send -i ~/.claude/claude.png 'Claude Code' 'Awaiting user input' 2>/dev/null || true
    ;;
  clear)
    if [[ -f "$FLAG" ]]; then
      # Skip clear if flag was set less than 2 seconds ago (race with parallel tool calls)
      flag_age=$(( $(date +%s) - $(stat -c %Y "$FLAG" 2>/dev/null || echo 0) ))
      if [[ "$flag_age" -lt 2 ]]; then
        echo "$(date '+%H:%M:%S') CLEAR ${SESSION}_${WINDOW} pane=$TMUX_PANE SKIPPED age=${flag_age}s" >> "$LOG"
      else
        echo "$(date '+%H:%M:%S') CLEAR ${SESSION}_${WINDOW} pane=$TMUX_PANE age=${flag_age}s" >> "$LOG"
        rm -f "$FLAG"
        tmux refresh-client -a -S 2>/dev/null || true
      fi
    fi
    ;;
  *)
    echo "Usage: claude-notify.sh set|clear" >&2
    exit 1
    ;;
esac
