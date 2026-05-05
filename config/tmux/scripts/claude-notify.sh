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

# Skip if invoked from an SDK-spawned claude (sub-agent or background daemon —
# e.g. claude-mem's worker-service spawns claude via the Agent SDK to analyze
# observations). Those processes inherit TMUX_PANE from whichever interactive
# session first launched them and would otherwise spam notifications
# attributed to that pane long after it's gone idle.
if [[ -n "${CLAUDE_AGENT_SDK_VERSION:-}" ]]; then
  echo "$(date '+%H:%M:%S') $ACTION SKIP sdk-claude pane=$TMUX_PANE" >> "$LOG"
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
    tmux refresh-client -S 2>/dev/null || true
    notify-send -i ~/.claude/claude.png 'Claude Code' 'Awaiting user input' 2>/dev/null || true
    ;;
  clear)
    if [[ -f "$FLAG" ]]; then
      echo "$(date '+%H:%M:%S') CLEAR ${SESSION}_${WINDOW} pane=$TMUX_PANE" >> "$LOG"
      rm -f "$FLAG"
      tmux refresh-client -S 2>/dev/null || true
    fi
    ;;
  *)
    echo "Usage: claude-notify.sh set|clear" >&2
    exit 1
    ;;
esac
