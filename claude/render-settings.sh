#!/bin/bash
# Renders ~/.claude/settings.json from the tracked base and this machine's untracked overlay.
# Claude Code writes /config and plugin changes into the rendered file, so a render that finds
# the file changed since the last one saves it as settings.json.drifted and prints the diff.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
base="$here/settings.base.json"
overlay="$claude_dir/settings.machine.json"
out="$claude_dir/settings.json"
last="$claude_dir/.settings.last-render.json"

if [ -f "$out" ]; then
    if [ ! -f "$last" ]; then
        cp "$out" "$out.drifted"
        echo "First render: saved the existing settings.json as settings.json.drifted." >&2
    elif ! diff -q <(jq -S . "$last") <(jq -S . "$out") >/dev/null; then
        cp "$out" "$out.drifted"
        echo "settings.json changed since the last render; saved it as settings.json.drifted." >&2
        echo "Carry what you want to keep into settings.base.json or settings.machine.json:" >&2
        diff <(jq -S . "$last") <(jq -S . "$out") >&2 || true
    fi
fi

tmp=$(mktemp "$claude_dir/.settings.XXXXXX")
trap 'rm -f "$tmp"' EXIT
# Objects merge deeply and an overlay array replaces the base array, except hook lists: the
# overlay's hooks for an event run alongside the base's, so a guard in the base cannot be dropped.
if [ -f "$overlay" ]; then
    jq -s '.[0] as $base | .[1] as $overlay
        | ($base * $overlay)
        | .hooks = reduce (($overlay.hooks // {}) | to_entries[]) as $event
            ($base.hooks // {}; .[$event.key] += $event.value)' "$base" "$overlay" > "$tmp"
else
    jq . "$base" > "$tmp"
fi
cp "$tmp" "$last"
mv "$tmp" "$out"
