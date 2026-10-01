#!/usr/bin/env python3
"""Rank sound-effect candidates before anyone has to listen.
Adapted from motion-video-kit (MIT, (c) 2026 echris6) — see LICENSES/motion-video-kit.txt

Usage: sfx_candidates.py file1.mp3 file2.wav ...   (needs ffmpeg + numpy)
Reports active duration, rise time, spectral centroid, share of energy below 150 Hz (rumble/boom)
and above 6 kHz (hiss/click), and a verdict. Reject: rumble > 50%, highs > 40% (UI sounds),
whooshes longer than 0.8 s for repeated transitions.
"""
import subprocess
import sys

import numpy as np

SR = 44100


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for f in sys.argv[1:]:
        raw = subprocess.run(
            ["ffmpeg", "-v", "error", "-i", f, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
            capture_output=True,
        ).stdout
        y = np.frombuffer(raw, np.float32)
        if not len(y):
            print(f"{f}: unreadable")
            continue
        env = np.sqrt(np.convolve(y**2, np.ones(441) / 441, "same"))
        act = np.where(env > env.max() * 0.05)[0]
        dur = (act[-1] - act[0]) / SR
        rise = (np.argmax(env) - act[0]) / SR * 1000
        F = np.abs(np.fft.rfft(y)) ** 2
        fr = np.fft.rfftfreq(len(y), 1 / SR)
        tot = F.sum() + 1e-20
        cen = (F * fr).sum() / tot
        lo = F[fr < 150].sum() / tot
        hi = F[fr > 6000].sum() / tot
        why = [w for w, bad in [("boomy", lo > 0.5), ("hissy/clicky", hi > 0.4), ("long", dur > 0.8)] if bad]
        verdict = "REJECT: " + ", ".join(why) if why else "ok"
        print(f"{f}: {dur:.2f}s rise {rise:.0f}ms centroid {cen:.0f}Hz <150Hz {lo*100:.0f}% >6k {hi*100:.0f}%  -> {verdict}")


if __name__ == "__main__":
    main()
