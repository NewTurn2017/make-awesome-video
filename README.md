[English](README.md) · [한국어](README.ko.md)

# make-awesome-video

An agent skill (Claude Code, Codex, and other skill-aware agents) that directs **pro-level motion-graphics launch videos** instead of one-shot "prompt → video" attempts.

Everyone uses the same model. The context you give it is what makes a video look pro. Without references the agent falls back to its defaults: centered text, a gradient background, and every element fading in. This skill replaces that with a director's workflow:

1. **Reference videos.** Search [whatships.com](https://whatships.com), pick 1–2 videos, and turn them into a measurable style spec covering pacing, type, transitions and palette.
2. **Code-to-MP4 rendering.** [HyperFrames](https://github.com/heygen-com/hyperframes) (default) or [Remotion](https://www.remotion.dev). Every frame is exact, and a change means editing one line and re-rendering.
3. **Real UI components.** Your real screenshots, or [21st](https://21st.dev/mcp) and shadcn components. The agent does not invent UI.
4. **Full context in.** Brand (logo, colors, fonts), product screenshots, references and your braindump, turned into **3 storyboard variants that each take a different direction**.
5. **Still frames before motion.** One hero frame per scene. Fixing a storyboard takes seconds; fixing a render means rendering again.
6. **Director notes.** Camera language like "slow all zooms to 0.7x", "hard cut here" or "push in on the button" is mapped to exact parameter changes.
7. **The builder never grades its own work.** Before you see a render, a fresh sub-agent that knows only the brief and the references judges the actual MP4: frozen time, loudness, empty frames, text collisions, transitions. Each revision is verified item by item by another fresh critic, and every round goes into a ledger.

The agent stops and waits for you at 4 gates: references, storyboard, stills and notes.

### It figures out what kind of video you want

No need to explain the genre. The skill detects the mode from what you give it:

| You give it | Mode | What happens |
|---|---|---|
| Product URL, screenshots, brand | `launch` | whatships references → 3 storyboards → stills → render |
| **A reference video + one word** ("like this, but CLAUDE") | `motion` | Reference is decomposed shot by shot at 4 fps; each technique (weight morph, panel split, word wall, 3D extrusion, noise field, particle type, lockup) is mapped to a HyperFrames block, animation rule or motion-kit helper; cuts are snapped to the music's beats; stills and the final render are compared side by side with the reference |
| Card news / posters / static images | `info` | Signage or kiosk loop sized to the physical screen, with a seamless loop check |
| Vertical, under 20s | `social` | Hook-first short |

A bundled **motion kit** (`assets/motion-kit/`) provides tested, seek-safe GSAP helpers: `fitWidth` (type fills the frame), `typeOn`, `maskRise`, `slam`, variable-font `axis` morphs, `panelWipe`, brand `ringWipe` with loop seam, `wordWall` + `gridStagger`, CSS `depthText` extrusion, deterministic `noiseField`, and beat `snap`. A worked example (a 15-second kinetic-type showreel recreated from a reference) lives in `references/examples/`.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | bash
```

This installs the skill to `~/.claude/skills/make-awesome-video` (and links it into `~/.agents/skills` if you use Codex or other agents). It then checks for the following and **installs whatever is missing**:

| Tool | Why |
|---|---|
| Node.js 22+ | runs HyperFrames / Remotion |
| ffmpeg / ffprobe | rendering and reference analysis |
| yt-dlp | downloads reference videos |
| HyperFrames CLI + Chrome + official agent skills | default renderer |
| Remotion agent skills + `create-video` | alternative renderer |
| 21st MCP | optional. Only checked, never auto-installed (needs your API key) |

Restart your agent session afterwards so the new skills load. Then just ask:

```
Make a launch video for my product
/make-awesome-video
```

### Install options

```bash
# only one renderer
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | MAV_ENGINE=hyperframes bash

# skill only, no dependency setup
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | MAV_SKIP_DEPS=1 bash

# custom location
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | MAV_DIR=~/my-skills/make-awesome-video bash
```

Re-running the installer updates an existing git install (`git pull --ff-only`).

Check or repair dependencies any time:

```bash
bash ~/.claude/skills/make-awesome-video/scripts/setup.sh --check
bash ~/.claude/skills/make-awesome-video/scripts/setup.sh
```

System packages are installed with Homebrew, or with apt/dnf/pacman when passwordless `sudo` is available. Otherwise the script prints the exact manual command.

### Optional: 21st UI components

```
claude plugin marketplace add 21st-dev/magic-mcp
/plugin install 21st
```

Get an API key at [21st.dev/mcp](https://21st.dev/mcp) and set `API_KEY_21ST`.

## What to bring

- Logo (SVG preferred), brand colors (HEX) and font names/files
- **Real product screenshots or screen recordings.** This matters most. A site URL also works, because it can be captured.
- A quick braindump of the video you imagine
- Length, aspect ratio and target channel (defaults: 20–40s, 1920x1080)
- Optional: 1–2 reference videos you love, or let the skill find some

## Bundled scripts

```bash
# search ~2,200 curated launch videos
python3 scripts/find_refs.py "terminal devtool" --category "Developer tools" --limit 8 --details
python3 scripts/find_refs.py --list-categories

# reference -> cut times, change peaks, contact sheet, shots, palette
# --fps 4 adds a timestamp-labeled dense sheet for motion-graphics references
bash scripts/analyze_ref.sh "<X post URL | YouTube URL | local mp4>" refs/<slug> --fps 4

# looping video: first frame must equal last frame
python3 scripts/loop_seam.py renders/out.mp4

# render review: frozen stretches (exit 1 on a hold > 0.6s), loudness, contact sheet
bash scripts/frozen_time.sh renders/v1.mp4 --ignore-tail 1.5
bash scripts/loudness.sh renders/v1.mp4
bash scripts/contact_sheet.sh renders/v1.mp4 review/sheet.jpg 0.25 8 6

# screen sound-effect candidates before listening (boomy / hissy / too long)
python3 scripts/sfx_candidates.py assets/sfx/*.mp3
```

## Project structure

```
make-awesome-video/
├── SKILL.md                      # the workflow + 4 gates
├── install.sh                    # one-line installer
├── agents/openai.yaml            # Codex interface metadata
├── LICENSES/                     # third-party notices (motion-video-kit, MIT)
├── assets/motion-kit/            # kit.js + kit.css (seek-safe GSAP helpers)
├── references/
│   ├── modes.md                  # mode detection: launch / motion / info / social
│   ├── shot-decomposition.md     # reference -> shot list, technique -> block/rule/kit map
│   ├── motion-craft.md           # motif continuity, pacing curve, beat sync, easing, type
│   ├── motion-grammar.md         # scene-to-scene rules, mechanism catalog, 28 launch-film references
│   ├── critic-loop.md            # builder != judge: critic rounds per gate, prompts, ledger
│   ├── audio.md                  # music choice and editing, sound effects, per-band levels, mix targets
│   ├── three-d.md                # deterministic Three.js, lab first, measured hero motion, motion blur
│   ├── gotchas.md                # verified pitfalls and fixes
│   ├── examples/                 # worked example: kinetic-type showreel recreation
│   ├── setup.md                  # HyperFrames / Remotion / 21st commands
│   ├── reference-analysis.md     # reference video -> style spec
│   ├── storyboard-template.md    # brief.md + 3-variant storyboard format
│   ├── director-notes.md         # camera vocabulary -> parameter changes
│   └── quality-bar.md            # measured targets + "reads as cheap" checklist
└── scripts/
    ├── setup.sh                  # check + install dependencies
    ├── find_refs.py              # whatships.com catalog search
    ├── analyze_ref.sh            # reference video analysis
    ├── loop_seam.py              # loop seam check
    ├── frozen_time.sh            # frozen stretches + longest hold in a render
    ├── loudness.sh               # integrated LUFS, LRA, true peak, short-term per second
    ├── contact_sheet.sh          # contact sheets for review and critics
    └── sfx_candidates.py         # sound-effect screening (needs numpy)
```

## Notes

- Reference videos are used to study style only and are never placed in your output.
- Remotion is free for teams of up to 3. Larger companies need a [company license](https://www.remotion.pro/license).
- Not affiliated with HeyGen, Remotion, 21st or What Ships.
- The critic loop, motion grammar, audio rules, 3D notes and the measurement scripts are adapted from [motion-video-kit](https://github.com/echris6/motion-video-kit) by echris6 (MIT). Its notice is in [LICENSES/motion-video-kit.txt](LICENSES/motion-video-kit.txt).

## License

[MIT](LICENSE)
