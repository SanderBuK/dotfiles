#!/usr/bin/env bash

# tmux-resurrect post-save-layout hook
# Rewrites saved claude commands with their actual session IDs
# so that resurrect can restore exact conversations, not just
# "most recent in directory".
#
# Called by resurrect with the save file path as $1.
# Reads ~/.claude/sessions/<pid>.json to map running claude
# processes to their session IDs.

RESURRECT_FILE="$1"
[ -f "$RESURRECT_FILE" ] || exit 0

SESSIONS_DIR="$HOME/.claude/sessions"
[ -d "$SESSIONS_DIR" ] || exit 0

tmp="${RESURRECT_FILE}.tmp"
changed=0

while IFS= read -r line; do
	# Only process pane lines where the command is claude
	# Format: pane\tsession\twindow\t...\tpane_command\t:full_command
	if [[ "$line" == pane$'\t'* ]] && [[ "$line" =~ $'\t'claude$'\t' ]]; then
		# Extract the full command (after last \t:)
		full_cmd="${line##*$'\t:'}"

		# Only upgrade bare "claude" or "claude --continue" (not already --resume/-r)
		if [[ "$full_cmd" == "claude" || "$full_cmd" == "claude --continue" ]]; then
			# Extract pane PID: field 1 of the pane line is the pane info,
			# but we need the tmux pane PID. We can get it from the pane_pid
			# saved in the file... except resurrect doesn't save pane_pid.
			# Instead, walk the running tmux panes to find the match.

			# Extract session_name (field 2), window_number (field 3), pane_index (field 6)
			session_name=$(echo "$line" | cut -f2)
			window_number=$(echo "$line" | cut -f3)
			pane_index=$(echo "$line" | cut -f6)

			# Get the pane's shell PID from tmux
			pane_pid=$(tmux list-panes -t "${session_name}:${window_number}" \
				-F '#{pane_index} #{pane_pid}' 2>/dev/null \
				| awk -v idx="$pane_index" '$1 == idx {print $2}')

			if [ -n "$pane_pid" ]; then
				# Find the claude child process
				claude_pid=$(pgrep -P "$pane_pid" 2>/dev/null | head -1)

				if [ -n "$claude_pid" ] && [ -f "${SESSIONS_DIR}/${claude_pid}.json" ]; then
					# Extract sessionId from the JSON
					session_id=$(grep -o '"sessionId":"[^"]*"' "${SESSIONS_DIR}/${claude_pid}.json" \
						| head -1 | cut -d'"' -f4)

					if [ -n "$session_id" ]; then
						# Replace the full command with claude --resume <id>
						line="${line%$'\t:'*}"$'\t:'"claude --resume ${session_id}"
						changed=1
					fi
				fi
			fi
		fi
	fi
	printf '%s\n' "$line"
done < "$RESURRECT_FILE" > "$tmp"

if [ "$changed" -eq 1 ]; then
	mv "$tmp" "$RESURRECT_FILE"
else
	rm -f "$tmp"
fi
