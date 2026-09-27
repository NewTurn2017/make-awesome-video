#!/usr/bin/env bash
# Turn a reference video into measurable style data.
# Usage: analyze_ref.sh <X/YouTube URL | local video file> <out_dir> [scene_threshold=0.3] [--fps N]
#   --fps N   also write contact_dense.png: N frames/sec with timestamp labels (motion graphics: use 4)
# Outputs in <out_dir>: ref.mp4, scores.tsv, cuts.txt, peaks.txt, stats.txt, contact.png,
#                       contact_dense.png (with --fps), shots/, palette.png
set -euo pipefail

DENSE_FPS=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fps) DENSE_FPS="${2:?--fps needs a number}"; shift 2 ;;
    --fps=*) DENSE_FPS="${1#*=}"; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]}"
SRC="${1:?usage: analyze_ref.sh <url|file> <out_dir> [threshold] [--fps N]}"
OUT="${2:?usage: analyze_ref.sh <url|file> <out_dir> [threshold] [--fps N]}"
TH="${3:-0.3}"

for bin in ffmpeg ffprobe python3; do
  command -v "$bin" >/dev/null || { echo "필요: $bin (brew install ffmpeg python)"; exit 1; }
done
mkdir -p "$OUT/shots"

# 1. obtain ref.mp4
if [[ -f "$SRC" ]]; then
  ffmpeg -loglevel error -y -i "$SRC" -c:v libx264 -crf 18 -c:a aac "$OUT/ref.mp4"
else
  command -v yt-dlp >/dev/null || { echo "필요: yt-dlp (brew install yt-dlp) — 또는 mp4 파일을 직접 전달"; exit 1; }
  if ! yt-dlp -q --no-playlist -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b" \
        --merge-output-format mp4 -o "$OUT/ref.%(ext)s" "$SRC"; then
    echo "다운로드 실패 (X 로그인 벽/삭제된 포스트일 수 있음)."
    echo "대안: 사용자에게 mp4를 받아 'analyze_ref.sh <file> $OUT' 로 재실행, 또는 포스터+시청 기반으로 스펙 작성."
    exit 2
  fi
  [[ -f "$OUT/ref.mp4" ]] || { f=$(ls "$OUT"/ref.* | head -1); ffmpeg -loglevel error -y -i "$f" "$OUT/ref.mp4"; }
fi
V="$OUT/ref.mp4"

# 2. per-frame scene scores (downscaled for speed) -> hard cuts + soft transition peaks
ffmpeg -hide_banner -i "$V" -vf "scale=160:-2,select='gte(scene,0)',metadata=print:key=lavfi.scene_score" \
  -an -f null - 2>&1 | awk '/pts_time:/{match($0,/pts_time:[0-9.]+/);t=substr($0,RSTART+9,RLENGTH-9)}
  /scene_score=/{split($0,a,"scene_score=");print t"\t"a[2]}' > "$OUT/scores.tsv" || true

# 3. stats
python3 - "$V" "$OUT" "$TH" > "$OUT/stats.txt" <<'PY'
import json, statistics, subprocess, sys
v, out, th = sys.argv[1], sys.argv[2], float(sys.argv[3])
p = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-print_format", "json",
    "-show_format", "-show_streams", v]))
vs = next(s for s in p["streams"] if s["codec_type"] == "video")
dur = float(p["format"]["duration"])
num, den = vs.get("avg_frame_rate", "0/1").split("/")
fps = float(num) / float(den) if float(den) else 0
rows = []
for line in open(f"{out}/scores.tsv"):
    try:
        t, s = line.split()
        rows.append((float(t), float(s)))
    except ValueError:
        pass
scores = [s for _, s in rows] or [0.0]

def pick(cands, gap):
    kept = []
    for t, s in sorted(cands, key=lambda r: -r[1]):
        if all(abs(t - k) >= gap for k, _ in kept):
            kept.append((t, s))
    return sorted(t for t, _ in kept)

cuts = pick([r for r in rows if r[1] >= th], 0.2)
# soft transitions: animated wipes/whips/morphs rarely pass the hard-cut threshold
mu, sd = statistics.mean(scores), statistics.pstdev(scores)
soft_th = max(0.06, mu + 4 * sd)
peaks = pick([r for r in rows if r[1] >= soft_th], 0.4)
open(f"{out}/cuts.txt", "w").write("\n".join(f"{c:.2f}" for c in cuts) + ("\n" if cuts else ""))
open(f"{out}/peaks.txt", "w").write("\n".join(f"{c:.2f}" for c in peaks) + ("\n" if peaks else ""))

def shots(bounds):
    b = [0.0] + bounds + [dur]
    return [round(y - x, 2) for x, y in zip(b, b[1:]) if y - x > 0.05]

print(f"duration: {dur:.2f}s")
print(f"resolution: {vs['width']}x{vs['height']}  fps: {fps:.2f}")
print(f"has_audio: {any(s['codec_type']=='audio' for s in p['streams'])}")
for label, marks in (("hard cuts (score>=%.2f)" % th, cuts), ("change peaks (score>=%.3f)" % soft_th, peaks)):
    sh = shots(marks)
    print(f"\n[{label}] count {len(marks)}  per 10s {len(marks)/dur*10:.1f}")
    print(f"  beat length avg {sum(sh)/len(sh):.2f}s  min {min(sh):.2f}s  max {max(sh):.2f}s")
    print("  times:", " ".join(f"{m:.2f}" for m in marks))
print("\nnote: hard cuts = instant scene changes; change peaks also catch whips/wipes/morphs.")
print("continuous camera moves and slow crossfades are still missed; verify against contact.png.")
PY

# 4. contact sheet (1 frame/sec, 6 columns)
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$V")
ROWS=$(python3 -c "import math;print(max(1,math.ceil(float('$DUR')/6)))")
ffmpeg -loglevel error -y -i "$V" -vf "fps=1,scale=320:-2,tile=6x${ROWS}:padding=4:color=white" \
  -frames:v 1 "$OUT/contact.png"

# 5. first frame after each cut (+ opening frame)
i=0
for t in 0.1 $(sort -n -u "$OUT/cuts.txt" "$OUT/peaks.txt" | awk '{printf "%.2f\n", $1+0.15}'); do
  i=$((i+1))
  ffmpeg -loglevel error -y -ss "$t" -i "$V" -frames:v 1 -vf "scale=960:-2" \
    "$(printf '%s/shots/%02d_%ss.png' "$OUT" "$i" "$t")" || true
done

# 5b. dense labeled contact sheet (motion graphics change within a shot; 1 fps hides the technique)
if [[ -n "$DENSE_FPS" ]]; then
  rm -rf "$OUT/dense"; mkdir -p "$OUT/dense"
  ffmpeg -loglevel error -y -i "$V" -vf "fps=$DENSE_FPS,scale=384:-2" "$OUT/dense/f_%04d.png"
  python3 - "$OUT" "$DENSE_FPS" <<'PY'
import glob, math, sys
from PIL import Image, ImageDraw
out, fps = sys.argv[1], float(sys.argv[2])
frames = sorted(glob.glob(f"{out}/dense/f_*.png"))
if frames:
    w, h = Image.open(frames[0]).size
    cols = 6
    rows = math.ceil(len(frames) / cols)
    sheet = Image.new("RGB", (cols * (w + 4), rows * (h + 4)), "black")
    for i, f in enumerate(frames):
        im = Image.open(f).convert("RGB")
        d = ImageDraw.Draw(im)
        label = f"{i / fps:.2f}s"
        d.rectangle([0, 0, 8 + 8 * len(label), 20], fill=(0, 0, 0))
        d.text((4, 4), label, fill=(255, 230, 0))
        sheet.paste(im, ((i % cols) * (w + 4), (i // cols) * (h + 4)))
    sheet.save(f"{out}/contact_dense.png")
    print(f"contact_dense.png: {len(frames)} frames @ {fps:g} fps")
PY
  rm -rf "$OUT/dense"
fi

# 6. palette
ffmpeg -loglevel error -y -i "$V" -vf "fps=2,scale=320:-2,palettegen=max_colors=12:stats_mode=full" \
  -frames:v 1 "$OUT/palette_raw.png"
ffmpeg -loglevel error -y -i "$OUT/palette_raw.png" -vf "scale=384:32:flags=neighbor" "$OUT/palette.png"
rm -f "$OUT/palette_raw.png"

echo "done → $OUT"
cat "$OUT/stats.txt"
echo "next: open contact.png and shots/, then write refs/style-spec.md (see references/reference-analysis.md)"
