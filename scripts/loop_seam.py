#!/usr/bin/env python3
"""Check that a looping video's last frame matches its first frame.

Usage: loop_seam.py <video.mp4> [--threshold 1.0]
Prints the mean absolute pixel difference (0-255 scale, 192x108 downscale). Exit 0 if below threshold.
"""
import argparse, json, subprocess, sys


def frame(path, n, w=192, h=108):
    raw = subprocess.check_output([
        "ffmpeg", "-loglevel", "error", "-i", path,
        "-vf", f"select=eq(n\\,{n}),scale={w}:{h}", "-frames:v", "1",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-",
    ])
    return raw


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--threshold", type=float, default=1.0)
    a = ap.parse_args()
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
        "-show_entries", "stream=nb_read_frames", "-of", "json", a.video,
    ]))
    n = int(probe["streams"][0]["nb_read_frames"])
    first, last = frame(a.video, 0), frame(a.video, n - 1)
    if not first or len(first) != len(last):
        sys.exit("could not read frames")
    diff = sum(abs(x - y) for x, y in zip(first, last)) / len(first)
    ok = diff < a.threshold
    print(f"frames: {n}  mean abs diff first vs last: {diff:.3f}  -> {'SEAMLESS' if ok else 'VISIBLE SEAM'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
