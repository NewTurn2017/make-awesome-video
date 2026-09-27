#!/usr/bin/env bash
# One-line install for the make-awesome-video agent skill.
#
#   curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | bash
#
# Options (env vars):
#   MAV_DIR=<path>      install location (default: ~/.claude/skills/make-awesome-video)
#   MAV_SKIP_DEPS=1     only install the skill, skip HyperFrames/Remotion/ffmpeg setup
#   MAV_ENGINE=hyperframes|remotion|both   which renderer(s) to set up (default: both)
set -euo pipefail

REPO="${MAV_REPO:-https://github.com/NewTurn2017/make-awesome-video}"
DEST="${MAV_DIR:-$HOME/.claude/skills/make-awesome-video}"
ENGINE="${MAV_ENGINE:-both}"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

# 1. get the skill
if [[ -L "$DEST" ]]; then
  say "기존 심링크 유지: $DEST -> $(readlink "$DEST")"
elif [[ -d "$DEST/.git" ]]; then
  say "업데이트: $DEST"
  git -C "$DEST" pull --ff-only --quiet
elif [[ -e "$DEST" ]]; then
  echo "이미 존재하지만 git 저장소가 아님: $DEST — 옮기거나 MAV_DIR로 다른 경로를 지정하세요." >&2
  exit 1
else
  say "설치: $DEST"
  mkdir -p "$(dirname "$DEST")"
  if command -v git >/dev/null 2>&1; then
    git clone --depth 1 --quiet "$REPO" "$DEST"
  else
    mkdir -p "$DEST"
    curl -fsSL "$REPO/archive/refs/heads/main.tar.gz" | tar -xz --strip-components=1 -C "$DEST"
  fi
fi
chmod +x "$DEST"/scripts/*.sh "$DEST"/scripts/*.py 2>/dev/null || true

# 2. expose it to other agents (Codex etc. read ~/.agents/skills)
if [[ -d "$HOME/.agents" || -d "$HOME/.codex" ]]; then
  mkdir -p "$HOME/.agents/skills"
  if [[ ! -e "$HOME/.agents/skills/make-awesome-video" ]]; then
    ln -s "$DEST" "$HOME/.agents/skills/make-awesome-video"
    say "링크: ~/.agents/skills/make-awesome-video"
  fi
fi

# 3. renderer + tools
if [[ "${MAV_SKIP_DEPS:-0}" != 1 ]]; then
  say "의존성 확인 및 설치 (HyperFrames / Remotion / ffmpeg / yt-dlp)"
  bash "$DEST/scripts/setup.sh" --engine "$ENGINE" || say "일부 의존성은 수동 설치가 필요합니다 (위 안내 참고). 나중에: bash $DEST/scripts/setup.sh"
fi

say "완료. 에이전트 세션을 새로 열고 이렇게 말해보세요:"
echo '    "우리 제품 런치 영상 만들어줘"  /  "/make-awesome-video"'
