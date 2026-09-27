#!/usr/bin/env bash
# Check and install everything make-awesome-video needs.
#
#   setup.sh                    # check, then install whatever is missing (HyperFrames + Remotion)
#   setup.sh --check            # report only, change nothing
#   setup.sh --engine hyperframes|remotion|both
#
# Installs: Node.js >= 22, ffmpeg/ffprobe, yt-dlp, HyperFrames CLI + Chrome + agent skills,
#           Remotion agent skills (+ warms the create-video scaffolder).
# Never touches: 21st MCP (needs your API key) — it only prints how to add it.
set -uo pipefail

MODE=install
ENGINE=both
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE=check ;;
    --engine) ENGINE="${2:?}"; shift ;;
    --engine=*) ENGINE="${1#*=}" ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
  shift
done
case "$ENGINE" in hyperframes|remotion|both) ;; *) echo "--engine must be hyperframes|remotion|both"; exit 1 ;; esac

LOG="$(mktemp -t make-awesome-video-setup.XXXXXX)"
MISSING=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; MISSING=$((MISSING+1)); }
info() { printf '  \033[33m→\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# install a system package with whatever package manager exists (no interactive sudo)
pkg_install() {
  local brew_name="$1" apt_name="${2:-$1}"
  if have brew; then brew install "$brew_name"
  elif have apt-get && sudo -n true 2>/dev/null; then sudo apt-get update -qq && sudo apt-get install -y "$apt_name"
  elif have dnf && sudo -n true 2>/dev/null; then sudo dnf install -y "$apt_name"
  elif have pacman && sudo -n true 2>/dev/null; then sudo pacman -S --noconfirm "$apt_name"
  elif have winget; then winget install -e --id "$apt_name"
  else return 1
  fi
}

skill_installed() {  # any agent skill dir that has this skill
  local name="$1" d
  for d in "$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.codex/skills"; do
    [[ -f "$d/$name/SKILL.md" ]] && return 0
  done
  return 1
}


echo "make-awesome-video setup ($MODE, engine=$ENGINE)"

# 1. Node.js >= 22 ---------------------------------------------------------------
echo "[1/6] Node.js"
node_major() { node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0; }
if have node && [[ "$(node_major)" -ge 22 ]]; then
  ok "node $(node -v)"
else
  bad "Node.js 22+ 필요 (현재: $(have node && node -v || echo 없음))"
  if [[ $MODE == install ]]; then
    if pkg_install node nodejs; then ok "node 설치됨 $(node -v 2>/dev/null)"; MISSING=$((MISSING-1))
    else info "수동 설치: https://nodejs.org 또는 'curl -fsSL https://fnm.vercel.app/install | bash && fnm install 22'"; fi
  fi
fi
if ! have npx; then echo "npx 없음 — Node.js 설치 후 다시 실행하세요."; exit 1; fi

# 2. ffmpeg / ffprobe ------------------------------------------------------------
echo "[2/6] ffmpeg"
if have ffmpeg && have ffprobe; then
  ok "$(ffmpeg -version | head -1 | cut -d' ' -f1-3)"
else
  bad "ffmpeg/ffprobe 없음 (렌더와 참조 분석에 필요)"
  if [[ $MODE == install ]]; then
    if pkg_install ffmpeg ffmpeg; then ok "ffmpeg 설치됨"; MISSING=$((MISSING-1))
    else info "수동 설치: brew install ffmpeg / sudo apt install ffmpeg / winget install Gyan.FFmpeg"; fi
  fi
fi

# 3. yt-dlp (reference video download) -------------------------------------------
echo "[3/6] yt-dlp"
if have yt-dlp; then
  ok "yt-dlp $(yt-dlp --version 2>/dev/null)"
else
  bad "yt-dlp 없음 (참조 영상 다운로드용, 없으면 mp4를 직접 받아 분석)"
  if [[ $MODE == install ]]; then
    if pkg_install yt-dlp yt-dlp || (have pipx && pipx install yt-dlp) || python3 -m pip install --user -q yt-dlp; then
      ok "yt-dlp 설치됨"; MISSING=$((MISSING-1))
    else info "수동 설치: https://github.com/yt-dlp/yt-dlp#installation"; fi
  fi
fi

# 4. HyperFrames ------------------------------------------------------------------
if [[ $ENGINE != remotion ]]; then
  echo "[4/6] HyperFrames"
  if have hyperframes; then
    ok "hyperframes CLI $(hyperframes --version 2>/dev/null | head -1)"
  else
    bad "hyperframes CLI 전역 설치 안 됨 (npx로도 동작하지만 전역 설치 권장)"
    if [[ $MODE == install ]]; then
      if npm install -g hyperframes@latest >/dev/null 2>&1; then ok "npm i -g hyperframes 완료"; MISSING=$((MISSING-1))
      else info "전역 설치 실패(권한). 'npx hyperframes'로 계속 사용 가능"; MISSING=$((MISSING-1)); fi
    fi
  fi
  HF=(npx -y hyperframes); have hyperframes && HF=(hyperframes)

  if [[ $MODE == install ]]; then
    "${HF[@]}" browser ensure >/dev/null 2>&1 && ok "렌더용 Chrome 준비됨" || info "Chrome 준비 실패 — 'npx hyperframes browser ensure' 수동 실행"
  else
    "${HF[@]}" browser path >/dev/null 2>&1 && ok "렌더용 Chrome 있음" || bad "렌더용 Chrome 없음 (hyperframes browser ensure)"
  fi

  HF_SKILLS=(hyperframes product-launch-video motion-graphics)
  miss=(); for s in "${HF_SKILLS[@]}"; do skill_installed "$s" || miss+=("$s"); done
  if [[ ${#miss[@]} -eq 0 ]]; then
    ok "HyperFrames 에이전트 스킬 (${HF_SKILLS[*]})"
  else
    bad "HyperFrames 에이전트 스킬 없음: ${miss[*]}"
    if [[ $MODE == install ]]; then
      if "${HF[@]}" skills update product-launch-video motion-graphics >"$LOG" 2>&1; then
        ok "HyperFrames 스킬 설치됨 (~/.claude/skills, ~/.agents/skills)"; MISSING=$((MISSING-1))
      else tail -5 "$LOG"; info "수동: npx hyperframes skills update product-launch-video motion-graphics"; fi
    fi
  fi
fi

# 5. Remotion ---------------------------------------------------------------------
if [[ $ENGINE != hyperframes ]]; then
  echo "[5/6] Remotion"
  RM_SKILLS=(remotion-best-practices remotion-create remotion-render remotion-studio)
  miss=(); for s in "${RM_SKILLS[@]}"; do skill_installed "$s" || miss+=("$s"); done
  if [[ ${#miss[@]} -eq 0 ]]; then
    ok "Remotion 에이전트 스킬 (${RM_SKILLS[*]})"
  else
    bad "Remotion 에이전트 스킬 없음: ${miss[*]}"
    if [[ $MODE == install ]]; then
      AF=(-a claude-code); [[ -d "$HOME/.codex" ]] && AF+=(-a codex)  # agents present on this machine
      sk=(); for s in "${RM_SKILLS[@]}"; do sk+=(--skill "$s"); done
      if npx -y skills add remotion-dev/skills -g -y "${AF[@]}" "${sk[@]}" >"$LOG" 2>&1; then
        ok "Remotion 스킬 설치됨"; MISSING=$((MISSING-1))
      else tail -5 "$LOG"; info "수동: npx skills add remotion-dev/skills -g"; fi
    fi
  fi
  # Remotion itself is a per-project dependency; warm the scaffolder so project creation is instant
  if [[ $MODE == install ]]; then
    npx -y create-video@latest --help >/dev/null 2>&1 && ok "create-video 준비됨 (프로젝트 생성: npx create-video@latest --yes --blank <name>)" \
      || info "create-video 캐시 실패 — 네트워크 확인"
  else
    info "Remotion은 프로젝트별 의존성: npx create-video@latest --yes --blank <name>"
  fi
fi

# 6. 21st (optional, never auto-installed) ---------------------------------------
echo "[6/6] 21st UI components (선택)"
if (have claude && claude mcp list 2>/dev/null | grep -qi 21st) || [[ -d "$HOME/.claude/plugins" && -n "$(ls "$HOME/.claude/plugins" 2>/dev/null | grep -i 21st)" ]]; then
  ok "21st 연결됨"
else
  info "21st 미설치 (선택). 원하면 Claude Code에서:"
  info "  claude plugin marketplace add 21st-dev/magic-mcp  →  /plugin install 21st"
  info "  API 키: https://21st.dev/mcp → 환경변수 API_KEY_21ST"
fi

echo
if [[ $MISSING -le 0 ]]; then
  echo "준비 완료. 새로 설치된 에이전트 스킬은 에이전트 세션을 재시작해야 로드됩니다."
  exit 0
else
  echo "누락 ${MISSING}개. $([[ $MODE == check ]] && echo "설치하려면: bash $0" || echo "위 안내대로 수동 설치 후 다시 실행하세요.")"
  exit 1
fi
