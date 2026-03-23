## Issue Tracking with bd (beads)

If a `.beads/*.db` file exists in the project, use **bd** for all task tracking. If not, ignore this section.

**Check for bd:**
```bash
ls .beads/*.db 2>/dev/null && echo "bd available" || echo "no bd"
```

**Core workflow:**
```bash
bd ready --json              # Find unblocked work
bd show <id>                 # View issue details
bd update <id> --claim       # Claim work atomically
bd create "Title" --description="Context" -t task -p 2 --json
bd close <id> --reason "Done"
```

**Rules when bd is present:**
- Use bd for ALL task tracking — no markdown TODOs
- Always `--json` flag for programmatic use
- Link discovered work: `--deps discovered-from:<parent-id>`
- Check `bd ready` before asking what to work on
