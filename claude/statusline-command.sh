#!/bin/bash
# Claude Code status line: model, context used as tokens and a percentage, and
# five hour and seven day usage with their reset times. Each figure stays dim
# gray until it nears its limit, then turns yellow and red: at 80k and 100k
# tokens for context, and at 50% and 80% for the usage windows.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Print a figure's text in dim gray, turning dim yellow once its value reaches
# warn and bright red once it reaches over.
figure() {
    local value=$1 warn=$2 over=$3 text=$4
    local color='\033[2m'
    if awk -v v="$value" -v t="$over" 'BEGIN { exit !(v >= t) }'; then
        color='\033[91m'
    elif awk -v v="$value" -v t="$warn" 'BEGIN { exit !(v >= t) }'; then
        color='\033[2;33m'
    fi
    printf "${color}%s\033[0m" "$text"
}

# Round a percentage to a whole number and add its sign.
percent() {
    awk -v u="$1" 'BEGIN { printf "%.0f%%", u }'
}

printf '\033[2m%s\033[0m' "$model"

if [ -n "$ctx" ]; then
    printf '  '
    if [ -n "$tokens" ]; then
        k=$(awk -v t="$tokens" 'BEGIN { printf "%.0fk", t / 1000 }')
        figure "$tokens" 80000 100000 "$k ($(percent "$ctx"))"
    else
        figure "$ctx" 50 80 "$(percent "$ctx")"
    fi
fi

if [ -n "$five" ]; then
    suffix=""
    if [ -n "$five_reset" ]; then
        suffix=" ↻$(date -r "$five_reset" +%H:%M)"
    fi
    printf '  '
    figure "$five" 50 80 "5h $(percent "$five")$suffix"
fi

if [ -n "$week" ]; then
    suffix=""
    if [ -n "$week_reset" ]; then
        suffix=" ↻$(date -r "$week_reset" +%a)"
    fi
    printf '  '
    figure "$week" 50 80 "7d $(percent "$week")$suffix"
fi
