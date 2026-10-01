#!/usr/bin/env bash
# Contact sheet of a render (for self-review and critics): one frame every N seconds, tiled.
# Adapted from motion-video-kit (MIT, (c) 2026 echris6) — see LICENSES/motion-video-kit.txt
# Usage: contact_sheet.sh <video.mp4> <out.jpg> [every_seconds=1] [cols=6] [rows=5] [start=0] [duration]
# Dense transition window example: contact_sheet.sh renders/v2.mp4 review/t12.jpg 0.0333 6 5 11.5 1
set -euo pipefail
f="${1:?usage: contact_sheet.sh <video> <out.jpg> [every] [cols] [rows] [start] [duration]}"
o="${2:?out.jpg required}"; e="${3:-1}"; c="${4:-6}"; r="${5:-5}"; ss="${6:-0}"; d="${7:-}"
mkdir -p "$(dirname "$o")"
ffmpeg -loglevel error -y -ss "$ss" ${d:+-t "$d"} -i "$f" -vf "fps=1/$e,scale=480:-1,tile=${c}x${r}" -frames:v 1 "$o"
echo "$o"
