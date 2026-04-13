#!/usr/bin/env bash
# battery-warn.sh — send desktop notifications at low battery thresholds
# All notifications use critical urgency so they stay until dismissed.
# Thresholds: 20% (warning), 10% (low), 5% (critical)

LAST_THRESHOLD=100

while true; do
    CAPACITY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)

    if [[ -z "$CAPACITY" ]]; then
        sleep 60
        continue
    fi

    if (( CAPACITY > 20 )); then
        LAST_THRESHOLD=100
    elif (( CAPACITY <= 5 && LAST_THRESHOLD > 5 )); then
        notify-send --urgency=critical "Battery Critical — ${CAPACITY}%" \
            "Plug in immediately or the system will shut down."
        LAST_THRESHOLD=5
    elif (( CAPACITY <= 10 && LAST_THRESHOLD > 10 )); then
        notify-send --urgency=critical "Battery Low — ${CAPACITY}%" \
            "Find a charger soon."
        LAST_THRESHOLD=10
    elif (( CAPACITY <= 20 && LAST_THRESHOLD > 20 )); then
        notify-send --urgency=critical "Battery Warning — ${CAPACITY}%" \
            "Battery is getting low."
        LAST_THRESHOLD=20
    fi

    sleep 60
done
