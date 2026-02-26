#!/usr/bin/env bash
# sports.sh — today's games for tmux status bar
# Dotfiles: ~/dotfiles/utils/sports.sh → ~/.config/utils/sports.sh
# Tmux:     set -g status-right '#(~/.config/utils/sports.sh) | ...'
#           set -g status-interval 30

CACHE_FILE="/tmp/.sports_cache"
CACHE_TTL=300  # 5 minutes

# Return cached result if still fresh (avoids hammering APIs on every status poll)
if [[ -f "$CACHE_FILE" ]] && (( $(date +%s) - $(stat -f %m "$CACHE_FILE") < CACHE_TTL )); then
  cat "$CACHE_FILE"
  exit 0
fi

ESPN="https://site.api.espn.com/apis/site/v2/sports"
PARTS=()

# Fetch a team's game from an ESPN scoreboard endpoint.
# Outputs a formatted string or nothing if not playing today.
espn_game() {
  local path="$1" abbr="$2" emoji="$3"
  curl -sf --max-time 5 "$ESPN/$path/scoreboard" | \
  jq -r --arg abbr "$abbr" --arg emoji "$emoji" '
    first(
      .events[] |
      select(any(.competitions[0].competitors[]; .team.abbreviation == $abbr))
    ) // empty |
    (.competitions[0].competitors[] | select(.homeAway == "away") | .team.shortDisplayName) as $away |
    (.competitions[0].competitors[] | select(.homeAway == "home") | .team.shortDisplayName) as $home |
    (.competitions[0].competitors[] | select(.homeAway == "away") | .score) as $ascore |
    (.competitions[0].competitors[] | select(.homeAway == "home") | .score) as $hscore |
    .status.type.state as $s |
    .status.type.shortDetail as $d |
    if $s == "pre"  then "\($emoji) \($away) @ \($home) \($d)"
    elif $s == "in" then "\($emoji) \($away) \($ascore)-\($hscore) \($home) \($d)"
    else                 "\($emoji) \($away) \($ascore)-\($hscore) \($home) Final"
    end
  ' 2>/dev/null | sed 's|[0-9]*/[0-9]* - ||;s/ PM E[SD]T/p/;s/ AM E[SD]T/a/'
}

# F1: any session scheduled for today
f1_today() {
  local today
  today=$(date +%Y-%m-%d)
  curl -sf --max-time 5 "$ESPN/racing/f1/scoreboard" | \
  jq -r --arg today "$today" '
    first(
      .events[] |
      select((.date | split("T")[0]) == $today)
    ) // empty |
    .shortName as $name |
    .status.type.state as $s |
    .status.type.shortDetail as $d |
    if $s == "pre"  then "🏎️  \($name) \($d)"
    elif $s == "in" then "🏎️  \($name) \($d)"
    else                 "🏎️  \($name) Final"
    end
  ' 2>/dev/null | sed 's|[0-9]*/[0-9]* - ||;s/ PM E[SD]T/p/;s/ AM E[SD]T/a/'
}

# Unrivaled: scrape their schedule page for today's first game time
unrivaled_today() {
  local today_pat html times fmt
  today_pat=$(date "+%a, %b %-d, %Y")
  html=$(curl -sf --max-time 5 "https://www.unrivaled.basketball/schedule" 2>/dev/null)
  [[ -z "$html" ]] && return
  echo "$html" | grep -q "$today_pat" || return
  times=$(echo "$html" | grep -A 50 "$today_pat" | grep -oE '[0-9]+:[0-9]+ [AP]M ET' | head -1)
  [[ -z "$times" ]] && return
  fmt=$(echo "$times" | sed 's|[0-9]*/[0-9]* - ||;s/ PM E[SD]T/p/;s/ AM E[SD]T/a/')
  echo "🏀 Unrivaled $fmt"
}

add() { [[ -n "$1" ]] && PARTS+=("$1"); }

add "$(espn_game baseball/mlb                         BAL  ⚾)"
add "$(espn_game basketball/nba                       GS   🏀)"
add "$(espn_game basketball/mens-college-basketball   MSU  🏀M)"
add "$(espn_game basketball/womens-college-basketball MSU  🏀W)"
add "$(unrivaled_today)"
add "$(f1_today)"

# Join with " | " — output nothing if no games
OUTPUT=""
if (( ${#PARTS[@]} > 0 )); then
  OUTPUT="${PARTS[0]}"
  for p in "${PARTS[@]:1}"; do
    OUTPUT+=" | $p"
  done
fi

echo "$OUTPUT" > "$CACHE_FILE"
[[ -n "$OUTPUT" ]] && echo "$OUTPUT"
