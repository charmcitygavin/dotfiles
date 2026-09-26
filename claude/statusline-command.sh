#!/bin/bash
# Claude Code status line: model, context used, five hour usage with its reset
# time, and seven day usage. Each figure is colored by how close it is to full.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Print a dim percentage, shifting toward red as it climbs.
figure() {
    local used=$1 label=$2 suffix=$3
    local pct color
    pct=$(awk -v u="$used" 'BEGIN { printf "%.0f", u }')
    if awk -v u="$used" 'BEGIN { exit !(u >= 80) }'; then
        color='\033[2;31m'
    elif awk -v u="$used" 'BEGIN { exit !(u >= 50) }'; then
        color='\033[2;33m'
    else
        color='\033[2;32m'
    fi
    printf "${color}%s %s%%%s\033[0m" "$label" "$pct" "$suffix"
}

printf '\033[2m%s\033[0m' "$model"

if [ -n "$ctx" ]; then
    printf '  '
    figure "$ctx" "ctx" ""
fi

if [ -n "$five" ]; then
    suffix=""
    if [ -n "$five_reset" ]; then
        suffix=" ↻$(date -r "$five_reset" +%H:%M)"
    fi
    printf '  '
    figure "$five" "5h" "$suffix"
fi

if [ -n "$week" ]; then
    printf '  '
    figure "$week" "7d" ""
fi
