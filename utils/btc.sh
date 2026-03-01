#!/usr/bin/env bash
# btc.sh — BTC price + colored sparkline via Coinbase (no API key)

CACHE="/tmp/.btc_cache"
CACHE_TTL=300

if [[ -f "$CACHE" ]] && (( $(date +%s) - $(stat -f %m "$CACHE") < CACHE_TTL )); then
  cat "$CACHE"
  exit 0
fi

DATA=$(curl -sf --max-time 10 'https://api.coinbase.com/v2/prices/BTC-USD/historic?period=day')
[[ -z "$DATA" ]] && echo "BTC unavailable" && exit 1

SPOT=$(curl -sf --max-time 5 'https://api.coinbase.com/v2/prices/BTC-USD/spot' | jq -r '.data.amount')
PRICE=$(printf "%'.0f" "$SPOT")

# Last 30 price points for sparkline
PRICES=$(echo "$DATA" | jq -r '[.data.prices[] | .price | tonumber] | reverse | .[-30:] | .[]')

SPARKS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
MIN=$(echo "$PRICES" | sort -n | head -1)
MAX=$(echo "$PRICES" | sort -n | tail -1)
RANGE=$(echo "$MAX - $MIN" | bc)

# Build sparkline with per-bar color (green=up, red=down vs prev bar)
SPARKLINE=""
PREV_P=""
while IFS= read -r p; do
  if (( $(echo "$RANGE == 0" | bc -l) )); then
    IDX=3
  else
    IDX=$(echo "scale=0; ($p - $MIN) / $RANGE * 7" | bc -l | awk '{printf "%d", $1}')
  fi
  [[ $IDX -gt 7 ]] && IDX=7

  if [[ -n "$PREV_P" ]]; then
    if (( $(echo "$p >= $PREV_P" | bc -l) )); then
      COLOR="\033[32m"  # green
    else
      COLOR="\033[31m"  # red
    fi
  else
    COLOR="\033[33m"  # yellow for first bar
  fi

  SPARKLINE+="${COLOR}${SPARKS[$IDX]}\033[0m"
  PREV_P="$p"
done <<< "$PRICES"

# 24h change
FIRST=$(echo "$DATA" | jq -r '[.data.prices[] | .price | tonumber] | .[-1]')
CHANGE=$(echo "scale=2; ($SPOT - $FIRST) / $FIRST * 100" | bc)
if (( $(echo "$CHANGE >= 0" | bc -l) )); then
  ARROW="↑" ; SIGN="+" ; PCOLOR="\033[32m"
else
  ARROW="↓" ; SIGN="" ; PCOLOR="\033[31m"
fi

# Layout: price+change on left (colored), sparkline right-aligned
CELL_WIDTH=62
LEFT_PLAIN="  ₿  \$${PRICE}  ${ARROW}${SIGN}${CHANGE}%"
LEFT_COLORED="  ₿  ${PCOLOR}\$${PRICE}  ${ARROW}${SIGN}${CHANGE}%\033[0m"
LEFT_LEN=${#LEFT_PLAIN}
# sparkline display width = number of bars (ANSI codes don't count)
SPARK_BARS=$(echo "$PRICES" | wc -l | tr -d ' ')
PAD=$(( CELL_WIDTH - LEFT_LEN - SPARK_BARS ))
[[ $PAD -lt 1 ]] && PAD=1
SPACES=$(printf '%*s' "$PAD" '')

OUTPUT="\n${LEFT_COLORED}${SPACES}${SPARKLINE}\n"
echo -e "$OUTPUT" | tee "$CACHE"
