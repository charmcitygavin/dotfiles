#!/usr/bin/env bash
# sports.sh — today's games dashboard
# Usage: watch -n 60 ~/.config/utils/sports.sh
# Dotfiles: ~/dotfiles/utils/sports.sh → ~/.config/utils/sports.sh

CACHE_DIR="/tmp/.sports_cache"
mkdir -p "$CACHE_DIR"
CACHE_TTL=300  # 5 minutes

ESPN="https://site.api.espn.com/apis/site/v2/sports"
GAMES=()

# Fetch from ESPN with per-endpoint caching
espn_fetch() {
  local path="$1"
  local cache="$CACHE_DIR/$(echo "$path" | tr '/' '_')"
  if [[ -f "$cache" ]] && (( $(date +%s) - $(stat -f %m "$cache") < CACHE_TTL )); then
    cat "$cache"
  else
    local result
    result=$(curl -sf --max-time 5 "$ESPN/$path/scoreboard?dates=$(date +%Y%m%d)")
    echo "$result" > "$cache"
    echo "$result"
  fi
}

# Format a single ESPN team's game
espn_game() {
  local path="$1" abbr="$2" emoji="$3" label="$4"
  local result
  result=$(espn_fetch "$path" | jq -r --arg abbr "$abbr" '
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
    if $s == "pre"  then "pre|\($away) @ \($home)|\($d)"
    elif $s == "in" then "live|\($away) @ \($home)|\($ascore)-\($hscore) \($d)"
    else                 "final|\($away) @ \($home)|\($ascore)-\($hscore) Final"
    end
  ' 2>/dev/null)
  [[ -z "$result" ]] && return
  local state matchup detail
  IFS='|' read -r state matchup detail <<< "$result"
  local detail_fmt
  detail_fmt=$(echo "$detail" | sed 's|[0-9]*/[0-9]* - ||; s/ PM ET/p/; s/ AM ET/a/; s/ PM EST/p/; s/ AM EST/a/; s/ PM EDT/p/; s/ AM EDT/a/')
  printf "%-4s %-24s %s\n" "$emoji" "$matchup" "$detail_fmt"
}

# F1: any session today
f1_today() {
  local today cache result
  today=$(date +%Y-%m-%d)
  cache="$CACHE_DIR/f1"
  if [[ -f "$cache" ]] && (( $(date +%s) - $(stat -f %m "$cache") < CACHE_TTL )); then
    result=$(cat "$cache")
  else
    result=$(curl -sf --max-time 5 "$ESPN/racing/f1/scoreboard?dates=$(date +%Y%m%d)")
    echo "$result" > "$cache"
  fi
  echo "$result" | jq -r --arg today "$today" '
    first(
      .events[] |
      select((.date | split("T")[0]) == $today)
    ) // empty |
    .shortName as $name |
    .status.type.state as $s |
    .status.type.shortDetail as $d |
    if $s == "pre"  then "pre|\($name)|\($d)"
    elif $s == "in" then "live|\($name)|\($d)"
    else                 "final|\($name)|Final"
    end
  ' 2>/dev/null | (
    IFS='|' read -r state name detail || return
    [[ -z "$name" ]] && return
    detail_fmt=$(echo "$detail" | sed 's|[0-9]*/[0-9]* - ||; s/ PM ET/p/; s/ AM ET/a/; s/ PM EST/p/; s/ AM EST/a/')
    printf "%-4s %-24s %s\n" "🏎️ " "$name" "$detail_fmt"
  )
}

# Header
printf "\n  🏟  TODAY'S GAMES — %s\n" "$(date '+%a %b %-d')"
printf "  %s\n" "──────────────────────────────────"

# Collect games
orioles=$(espn_game  baseball/mlb                         BAL  ⚾   "Orioles")
ravens=$(espn_game   football/nfl                         BAL  🏈   "Ravens")
warriors=$(espn_game basketball/nba                       GS   🏀   "Warriors")
msu_m=$(espn_game   basketball/mens-college-basketball   MSU  "🏀M" "MSU Men")
msu_w=$(espn_game   basketball/womens-college-basketball MSU  "🏀W" "MSU Women")
f1=$(f1_today)

any=0
for game in "$orioles" "$ravens" "$warriors" "$msu_m" "$msu_w" "$f1"; do
  if [[ -n "$game" ]]; then
    echo "  $game"
    any=1
  fi
done

[[ $any -eq 0 ]] && echo "  No games today."

printf "  %s\n" "──────────────────────────────────"
printf "  Updated %s\n\n" "$(date '+%-I:%M%p' | tr '[:upper:]' '[:lower:]')"
