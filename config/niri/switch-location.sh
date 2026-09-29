#!/usr/bin/env bash
# Usage: switch-location.sh [home|office]  (no argument toggles)
set -eu -o pipefail

dir="$(dirname "$(readlink -f "$0")")"
link="$dir/outputs.kdl"

current="$(basename "$(readlink "$link" 2>/dev/null || echo outputs-office.kdl)" .kdl)"
current="${current#outputs-}"

target="${1:-}"
if [ -z "$target" ]; then
    [ "$current" = "home" ] && target="office" || target="home"
fi

if [ ! -f "$dir/outputs-$target.kdl" ]; then
    echo "unknown location: $target" >&2
    exit 1
fi

ln -sfn "outputs-$target.kdl" "$link"
niri msg action load-config-file >/dev/null 2>&1 || true

# open-on-output only applies when a workspace is created, so move existing ones explicitly.
awk '
    /^workspace "/ { split($0, a, "\""); ws = a[2] }
    /open-on-output "/ && ws != "" { split($0, a, "\""); print ws "\t" a[2]; ws = "" }
' "$dir/outputs-$target.kdl" | while IFS="$(printf '\t')" read -r ws output; do
    niri msg action move-workspace-to-monitor --reference "$ws" "$output" >/dev/null 2>&1 || true
done
command -v notify-send >/dev/null && notify-send "niri" "Display layout: $target" || true
echo "$target"
