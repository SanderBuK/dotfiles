#!/usr/bin/env python3
"""
PreToolUse hook: auto-approve Bash commands where every part of a compound
command (split on ||, &&, |, ;) is safe and read-only.
"""
import json
import re
import sys

SAFE_PREFIXES = [
    # File listing & navigation
    "cd", "ls", "tree", "pwd", "realpath", "readlink", "stat", "file",
    # File reading
    "cat", "head", "tail", "less", "more",
    # Search
    "grep", "rg", "ag", "ack", "find", "locate",
    # Text processing (read-only; sed and find validated separately)
    "echo", "printf", "wc", "sort", "uniq", "cut", "tr", "column",
    "diff", "jq", "yq", "sed",
    # System info (env excluded — it executes arbitrary commands)
    "printenv", "whoami", "hostname", "id", "date", "uname",
    "uptime", "ps", "df", "du", "which", "whereis", "type",
    # Archives (unzip restricted to -l by prefix)
    "unzip -l", "zipinfo",
    # Checksums
    "md5sum", "sha256sum", "shasum",
    # Git (read-only)
    "git status", "git log", "git diff", "git show", "git branch",
    "git remote", "git ls-files", "git describe",
    "git config --get", "git config --list", "git stash list",
    "git tag", "git shortlog", "git rev-parse", "git rev-list",
    "git cat-file", "git ls-tree",
    # GitHub CLI (read-only; gh api excluded — prompting is fine)
    "gh pr view", "gh pr list", "gh pr diff", "gh issue view",
    "gh issue list", "gh repo view", "gh release list",
    "gh workflow list", "gh run list", "gh run view",
    # GitLab CLI (read-only)
    "glab mr view", "glab mr list", "glab mr diff",
    "glab issue view", "glab issue list",
    "glab repo view",
    "glab release list", "glab release view",
    "glab pipeline list", "glab pipeline view",
    "glab ci view", "glab ci status",
    "glab job list",
    "glab label list",
    "glab milestone list",
    "glab user view",
    "glab config get",
    "glab auth status",
    # Docker (read-only)
    "docker ps", "docker images", "docker logs", "docker inspect",
    "docker version", "docker info", "docker stats",
    # Package managers (read-only)
    "npm --version", "npm list", "npm ls", "npm view", "npm outdated",
    "yarn --version", "yarn list",
    "pip --version", "pip list", "pip show",
    "node --version", "python --version", "python3 --version",
    "pip3 --version", "pip3 list", "pip3 show",
    # Misc
    "bd", "true", "false", "test", "[[", "[",
    "tmux list", "tmux show", "tmux display", "tmux info",
    "systemctl status", "journalctl",
    "lsof", "netstat", "ss", "ip addr", "ip route",
    "curl --head", "curl -I",
    "nmap",
    # Azure DevOps CLI (read-only)
    "az devops project list", "az devops project show",
    "az repos list", "az repos show", "az repos ref list",
    "az repos pr list", "az repos pr show", "az repos pr diff",
    "az repos pr reviewer list", "az repos pr work-item list",
    "az repos policy list", "az repos policy show",
    "az pipelines list", "az pipelines show", "az pipelines runs list",
    "az pipelines runs show", "az pipelines variable list",
    "az pipelines variable-group list", "az pipelines variable-group show",
    "az boards work-item show", "az boards query",
    "az boards iteration project list", "az boards area project list",
]

# Per-command validators applied after prefix match.
# Return True = safe to allow, False = unsafe (fall through to normal prompt).
COMMAND_VALIDATORS = {
    # sed -i / --in-place modifies files
    "sed": lambda cmd: not re.search(
        r'(?:^|\s)-[a-zA-Z]*i[a-zA-Z]*(?:\s|$)|(?:^|\s)--in-place(?:\s|=|$)', cmd
    ),
    # find -exec/-delete runs or removes arbitrary files
    "find": lambda cmd: not re.search(
        r'(?:^|\s)(?:-exec|-execdir|-delete|-ok|-okdir)\b', cmd
    ),
}


def strip_safe_redirects(cmd):
    """Remove redirections that are inherently safe (to /dev/null or between fds)."""
    cmd = re.sub(r'\s*\d*>>/dev/null', '', cmd)
    cmd = re.sub(r'\s*\d*>/dev/null', '', cmd)
    cmd = re.sub(r'\s*\d*>&\d+', '', cmd)
    return cmd.strip()


def has_file_redirect(cmd):
    """Return True if cmd writes output to a real file (not /dev/null)."""
    cleaned = strip_safe_redirects(cmd)
    return bool(re.search(r'(?<![<>!])>>?\s*\S', cleaned))


def has_command_substitution(cmd):
    """Return True if cmd contains subshell or process substitution."""
    return bool(re.search(r'\$\(|`|<\(|>\(', cmd))


def split_compound(cmd):
    """Split a compound shell command into individual parts on ||, &&, |, ;"""
    parts = re.split(r'\s*(?:\|\||&&|;|\|)\s*', cmd)
    return [p.strip() for p in parts if p.strip()]


def is_safe(cmd):
    # Reject shell output redirects to real files
    if has_file_redirect(cmd):
        return False

    # Reject command/process substitution — inner commands are not checked
    if has_command_substitution(cmd):
        return False

    cmd = strip_safe_redirects(cmd)

    # Strip leading env var assignments like: FOO=bar command
    cmd = re.sub(r'^(?:[A-Z_][A-Z0-9_]*=\S*\s+)+', '', cmd)
    # Strip sudo prefix (transparent — we check the underlying command)
    if cmd.startswith("sudo "):
        cmd = cmd[5:].strip()
    if not cmd:
        return True

    # Check against safe prefix list
    matched = any(
        cmd == prefix or cmd.startswith(prefix + " ") or cmd.startswith(prefix + "\t")
        for prefix in SAFE_PREFIXES
    )
    if not matched:
        return False

    # Run per-command validator if one exists
    for key, validator in COMMAND_VALIDATORS.items():
        if cmd == key or cmd.startswith(key + " ") or cmd.startswith(key + "\t"):
            return validator(cmd)

    return True


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    command = data.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    parts = split_compound(command)
    if parts and all(is_safe(p) for p in parts):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Safe read-only command"
            }
        }))

    sys.exit(0)


if __name__ == "__main__":
    main()
