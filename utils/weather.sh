#!/usr/bin/env bash
# weather.sh — current conditions for Baltimore via Open-Meteo (no API key)

CACHE="/tmp/.weather_cache"
CACHE_TTL=900  # 15 minutes

if [[ -f "$CACHE" ]] && (( $(date +%s) - $(stat -f %m "$CACHE") < CACHE_TTL )); then
  cat "$CACHE"
  exit 0
fi

DATA=$(curl -sf --max-time 10 \
  'https://api.open-meteo.com/v1/forecast?latitude=39.2904&longitude=-76.6122&current=temperature_2m,apparent_temperature,weathercode,windspeed_10m,relativehumidity_2m&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&temperature_unit=fahrenheit&windspeed_unit=mph&forecast_days=1&timezone=America/New_York')

[[ -z "$DATA" ]] && echo "Weather unavailable" && exit 1

# WMO weather code to description
decode_wmo() {
  case $1 in
    0) echo "Clear ☀️" ;;
    1|2|3) echo "Cloudy ⛅" ;;
    45|48) echo "Fog 🌫" ;;
    51|53|55) echo "Drizzle 🌧" ;;
    61|63|65) echo "Rain 🌧" ;;
    71|73|75) echo "Snow ❄️" ;;
    80|81|82) echo "Showers 🌦" ;;
    95|96|99) echo "Storms ⚡" ;;
    *) echo "Unknown" ;;
  esac
}

TEMP=$(echo "$DATA" | jq '.current.temperature_2m')
FEELS=$(echo "$DATA" | jq '.current.apparent_temperature')
WIND=$(echo "$DATA" | jq '.current.windspeed_10m')
HUMID=$(echo "$DATA" | jq '.current.relativehumidity_2m')
CODE=$(echo "$DATA" | jq '.current.weathercode')
HIGH=$(echo "$DATA" | jq '.daily.temperature_2m_max[0]')
LOW=$(echo "$DATA" | jq '.daily.temperature_2m_min[0]')
PREC=$(echo "$DATA" | jq '.daily.precipitation_probability_max[0]')
DESC=$(decode_wmo "$CODE")

OUTPUT=$(printf "\n  Baltimore, MD\n  %s\n\n  🌡  %s°F  (feels like %s°F)\n  💨  Wind: %s mph\n  💧  Humidity: %s%%\n  ↑ High: %s°F  ↓ Low: %s°F\n  ☔ Rain chance: %s%%\n" \
  "$DESC" "$TEMP" "$FEELS" "$WIND" "$HUMID" "$HIGH" "$LOW" "$PREC")

echo "$OUTPUT" | tee "$CACHE"
