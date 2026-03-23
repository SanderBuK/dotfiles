#!/bin/sh

# DP-1 through Thunderbolt dock gets stuck in a ghost state where xrandr
# thinks it's configured but the link is down and no modes are available.
# Fix: turn it off to clear the ghost, then re-enable until the link comes up.

MAX_RETRIES=5

for i in $(seq 1 $MAX_RETRIES); do
    xrandr --output DP-1 --off
    sleep 1
    xrandr --output DP-1 --auto
    sleep 2

    if xrandr | grep -q "^DP-1 connected"; then
        xrandr \
            --output DP-1 --mode 2560x1440 --rate 59.95 --pos 0x0 --rotate normal \
            --output HDMI-1 --mode 1920x1080 --rate 60.00 --pos 2560x791 --rotate normal \
            --output eDP-1 --primary --mode 1920x1080 --rate 60.00 --pos 640x1440 --rotate normal \
            --output DP-2 --off \
            --output DP-3 --off \
            --output DP-4 --off
        echo "DP-1 connected on attempt $i"
        exit 0
    fi
done

echo "DP-1 did not connect after $MAX_RETRIES attempts"
exit 1
