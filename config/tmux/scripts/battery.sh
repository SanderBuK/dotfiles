#!/usr/bin/env bash
# battery.sh — output battery icon + percentage, or empty if no battery

CAPACITY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
[[ -z "$CAPACITY" ]] && exit 0

STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
if [[ "$STATUS" == "Charging" ]]; then
    echo "󰂄 ${CAPACITY}%"
else
    echo "󰁹 ${CAPACITY}%"
fi
