#!/usr/bin/env bash
# session-bar.sh — session list with distinct backgrounds and red dot for waiting
# Colors (catppuccin mocha):
#   non-current: bg=#313244 (surface0), fg=#a6adc8 (subtext0)
#   current:     bg=#cba6f7 (mauve),    fg=#1e1e2e (base)

CURRENT=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0

output=""

while IFS=: read -r session attached; do
    count=$(ls /tmp/claude-waiting/${session}_* 2>/dev/null | wc -l)

    if [[ "$session" == "$CURRENT" ]]; then
        if [[ "$count" -gt 0 ]]; then
            output+="#[bg=#cba6f7,fg=#1e1e2e] ${session} #[fg=red]● #[default]"
        else
            output+="#[bg=#cba6f7,fg=#1e1e2e] ${session} #[default]"
        fi
    else
        if [[ "$count" -gt 0 ]]; then
            output+="#[bg=#313244,fg=#a6adc8] ${session} #[fg=red]● #[default]"
        else
            output+="#[bg=#313244,fg=#a6adc8] ${session} #[default]"
        fi
    fi
done < <(tmux list-sessions -F '#{session_name}:#{session_attached}' 2>/dev/null)

printf '%s' "${output}#[default]   "
