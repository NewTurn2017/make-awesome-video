#!/usr/bin/env bash
# Integrated loudness, loudness range, true peak, and short-term loudness each second.
# Adapted from motion-video-kit (MIT, (c) 2026 echris6) — see LICENSES/motion-video-kit.txt
# Usage: loudness.sh <video-or-audio>
set -euo pipefail
f="${1:?usage: loudness.sh <video-or-audio>}"
if [[ -z "$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$f")" ]]; then
  echo "no audio stream: $f"; exit 2
fi
out=$(ffmpeg -hide_banner -nostats -i "$f" -af ebur128=peak=true -f null - 2>&1)
echo "$out" | grep -E "^ +(I|LRA|Peak):" | tr -s ' '
echo "short-term (S) per second:"
echo "$out" | awk '
  /Parsed_ebur128.* t: / {
    match($0, /t: *[0-9.]+/); t = substr($0, RSTART + 2, RLENGTH - 2) + 0
    match($0, /S: *-?[0-9.]+/); s = substr($0, RSTART + 2, RLENGTH - 2) + 0
    sec = int(t + 1e-6)
    if (sec != last) { if (s < -70) printf "%d:- ", sec; else printf "%d:%.1f ", sec, s; last = sec }
  }
  BEGIN { last = -1 } END { print "" }'
