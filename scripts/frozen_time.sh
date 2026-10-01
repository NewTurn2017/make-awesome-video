#!/usr/bin/env bash
# Find frozen stretches in a render: frame-to-frame luma difference below a threshold.
# Adapted from motion-video-kit (MIT, (c) 2026 echris6) — see LICENSES/motion-video-kit.txt
#
# Usage: frozen_time.sh <video.mp4> [threshold=0.35] [--fps 10] [--min 0.3] [--ignore-tail 2.0]
#   threshold    mean abs luma difference (0-255) below which a step counts as frozen
#   --min        only list stretches at least this long (seconds)
#   --ignore-tail  exclude the last N seconds (the lockup/CTA hold is allowed to be still)
# Prints each frozen stretch, the total, and the longest hold. Exit 1 if a hold > 0.6s occurs outside the tail.
set -euo pipefail
FPS=10; MIN=0.3; TAIL=0; ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fps) FPS="$2"; shift 2 ;;
    --min) MIN="$2"; shift 2 ;;
    --ignore-tail) TAIL="$2"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
f="${ARGS[0]:?usage: frozen_time.sh <video.mp4> [threshold] [--fps N] [--min S] [--ignore-tail S]}"
th="${ARGS[1]:-0.35}"
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
ffmpeg -hide_banner -i "$f" -vf "fps=$FPS,scale=320:-1,format=gray,tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG" -an -f null - 2>&1 \
 | grep -o "YAVG=[0-9.]*" | awk -F= -v th="$th" -v fps="$FPS" -v min="$MIN" -v dur="$dur" -v tail="$TAIL" '
   function flush(end_t,   len) {
     if (start < 0) return
     if (tail > 0 && start >= dur - tail) { start = -1; return }
     if (tail > 0 && end_t > dur - tail) end_t = dur - tail   # count only up to the allowed tail
     len = end_t - start
     if (len > 0.0001) {
       total += len; if (len > longest) { longest = len; lat = start }
       if (len > 0.6) bad++
       if (len >= min) printf "  %6.2f–%6.2fs  %.1fs\n", start, end_t, len
     }
     start = -1
   }
   BEGIN { start = -1; printf "frozen stretches (YAVG < %s, %s fps):\n", th, fps }
   { t = NR / fps; if ($2 < th) { if (start < 0) start = t - 1/fps } else flush(t - 1/fps) }
   END {
     flush(NR / fps)
     printf "total frozen: %.1fs of %.1fs", total, dur
     if (tail > 0) printf " (last %ss excluded)", tail
     printf "\nlongest hold: %.1fs", longest; if (longest > 0) printf " at %.2fs", lat
     printf "\nholds > 0.6s: %d\n", bad
     exit (bad > 0)
   }'
