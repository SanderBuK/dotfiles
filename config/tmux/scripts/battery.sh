#!/usr/bin/env bash
# battery.sh — output battery icon + percentage with color based on level
# Colors: green (>20%), yellow (10-20%), red (<10%) using catppuccin palette

CAPACITY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
[[ -z "$CAPACITY" ]] && exit 0

STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)

if [[ "$STATUS" == "Charging" ]]; then
    ICON="󰂄"
elif (( CAPACITY <= 10 )); then
    ICON="󰁺"
elif (( CAPACITY <= 20 )); then
    ICON="󰁻"
else
    ICON="󰁹"
fi

if (( CAPACITY <= 10 )); then
    BG="#f38ba8"
elif (( CAPACITY <= 20 )); then
    BG="#f9e2af"
else
    BG="#a6e3a1"
fi

echo "#[bg=${BG},fg=#1e1e2e] ${ICON} ${CAPACITY}% "
