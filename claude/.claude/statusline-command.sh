#!/usr/bin/env bash
# Claude Code statusLine script
# Reads JSON from stdin and outputs a colored status line string

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ANSI color codes
RESET='\033[0m'
WHITE='\033[97m'
CYAN='\033[96m'
YELLOW='\033[33m'
MUTED='\033[90m'
GREEN='\033[32m'
YELLOW_BOLD='\033[1;33m'
RED='\033[31m'

# Shorten home directory to ~
if [ -n "$cwd" ]; then
  home_dir="$HOME"
  cwd="${cwd/#$home_dir/\~}"
fi

# Git branch and dirty/clean state (skip optional locks)
git_branch=""
git_colored=""
if [ -n "$cwd" ]; then
  expanded_cwd="${cwd/#\~/$HOME}"
  git_branch=$(git -C "$expanded_cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    changed_files=$(git -C "$expanded_cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l)
    changed_files=$(echo "$changed_files" | tr -d '[:space:]')
    if [ "$changed_files" -gt 0 ]; then
      git_colored="${CYAN}${git_branch}${RESET} ${YELLOW}±${changed_files}${RESET}"
    else
      git_colored="${CYAN}${git_branch}${RESET}"
    fi
  fi
fi

# Context color: green -> yellow -> red based on usage
ctx_color="$GREEN"
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used" 2>/dev/null || echo "0")
  if [ "$used_int" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="$YELLOW_BOLD"
  fi
fi

# Build status line
line="${WHITE}${cwd}${RESET}"

if [ -n "$git_colored" ]; then
  line="${line} ${MUTED}(${RESET}${git_colored}${MUTED})${RESET}"
fi

if [ -n "$model" ]; then
  line="${line} ${MUTED}| ${model}${RESET}"
fi

if [ -n "$used" ]; then
  printf_used=$(printf "%.0f" "$used" 2>/dev/null || echo "$used")
  line="${line} ${MUTED}[ctx: ${ctx_color}${printf_used}%${RESET}${MUTED}]${RESET}"
fi

printf "%b" "$line"
