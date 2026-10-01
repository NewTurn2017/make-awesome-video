# 셋업: 빌드 도구 확인과 설치 안내

원칙: **확인 먼저, 빠진 건 설치.** `scripts/setup.sh`가 HyperFrames·Remotion·ffmpeg·yt-dlp를 확인하고 없으면 설치한다. 단, API 키와 Claude 플러그인 설정이 걸린 21st는 안내만 한다.

```bash
bash {baseDir}/scripts/setup.sh --check                 # 상태만
bash {baseDir}/scripts/setup.sh                         # 빠진 것 설치 (둘 다)
bash {baseDir}/scripts/setup.sh --engine hyperframes    # 또는 remotion
```

아래는 스크립트가 하는 일과 수동 명령이다.

## HyperFrames (기본 렌더러)

HTML + CSS + GSAP/Lottie로 장면을 쓰고, 헤드리스 Chrome이 프레임마다 seek 해서 캡처 → FFmpeg로 MP4. 같은 입력이면 같은 출력(결정적)이라 "한 줄 고치고 재렌더"가 가능하다.

```bash
npx hyperframes --help                 # 설치 없이 npx로 동작 (Node 22+ 권장)
npx hyperframes doctor                 # Chrome, ffmpeg 등 의존성 점검
npm install -g hyperframes@latest      # 전역 CLI (setup.sh가 수행)
npx hyperframes browser ensure         # 렌더용 Chrome 준비
npx hyperframes skills update product-launch-video motion-graphics   # 코어 + 워크플로 스킬 설치 (~/.claude/skills, ~/.agents/skills)
```

자주 쓰는 명령 (v0.8.x 기준, 버전이 다르면 `--help`로 재확인):

| 목적 | 명령 |
|---|---|
| 프로젝트 생성 | `npx hyperframes init <name> --non-interactive --resolution landscape` (`portrait`, `square`, `landscape-4k`) |
| 예제에서 시작 | `npx hyperframes init <name> --example swiss-grid --non-interactive` |
| 블록/컴포넌트 검색 | `npx hyperframes catalog --query "push in" --json` / `--tag transition` |
| 블록 설치 | `npx hyperframes add <block-name>` |
| 웹사이트 캡처 | `npx hyperframes capture <url>` |
| 검증 게이트 | `npx hyperframes check <dir>` (애니메이션 없는 정지 타임라인은 실패 처리됨 — 정지 프레임 단계에선 정상) |
| 정지 프레임 | `npx hyperframes snapshot <dir> --at 1.5,5,9 --no-end` |
| 참조와 비교 | `npx hyperframes snapshot <dir> --at 2,6 --against ref.mp4` |
| 변형 비교 시트 | `npx hyperframes compare a/ b/ c/ --at 3 --labels A,B,C --out compare.png` |
| 비트 검출 | `npx hyperframes beats <dir>` |
| 렌더 (`--output`은 cwd 기준 경로) | `npx hyperframes render <dir> --quality draft --output <dir>/renders/draft.mp4` |
| 최종 렌더 | `npx hyperframes render <dir> --quality delivery --output <dir>/renders/final.mp4` |

HTML/GSAP 작성 규칙(`data-*` 트랙 속성, 컴포지션 구조, seek 가능한 애니메이션 등)은 `skills update`로 설치되는 HyperFrames 공식 스킬을 따른다. 이 스킬은 그 위의 **감독/워크플로 레이어**다.

## Remotion (대안)

React 컴포넌트로 장면을 쓰고 싶을 때, 이미 React 디자인 시스템이 있을 때 선택한다. Remotion은 프로젝트별 npm 의존성이라 전역 설치가 없다.

```bash
npx skills add remotion-dev/skills -g -y -a claude-code --skill remotion-best-practices --skill remotion-create --skill remotion-render --skill remotion-studio
npx create-video@latest --yes --blank <name>     # 프로젝트 생성 (비대화형)
cd <name> && npx remotion studio                 # 미리보기
npx remotion compositions                        # 컴포지션 ID 확인
npx remotion render <CompositionId> out/video.mp4  # 렌더
npx remotion still <CompositionId> out/still.png --frame=<n>   # 정지 프레임 (G3)
```

그 밖의 플래그는 기억에 의존하지 말고 `remotion-best-practices` 스킬, 공식 문서(remotion.dev), `npx remotion --help`로 확인한다. Remotion은 3인 이하 팀까지 무료이고 그 이상 회사는 유료 라이선스가 필요하다(remotion.pro/license). 상업용이면 사용자에게 알린다.

HyperFrames 기준으로 쓰인 이 스킬의 게이트(G1–G4)와 참조 파일은 Remotion에도 그대로 적용된다. 정지 프레임은 Remotion의 still 렌더 기능으로 대체한다.

## 21st (실제 UI 컴포넌트)

디자인 엔지니어가 만든 실제 React/Tailwind 버튼·카드·UI 컴포넌트를 검색해 가져오는 MCP. (예전 이름 Magic MCP, 현재 21st MCP)

확인:

```bash
claude mcp list 2>/dev/null | grep -i 21st
claude plugin list 2>/dev/null | grep -i 21st
```

없으면 사용자에게 안내만 한다 (직접 실행하지 않음):

```
claude plugin marketplace add 21st-dev/magic-mcp
/plugin install 21st
# API 키: https://21st.dev/mcp 에서 발급 → 환경변수 API_KEY_21ST
```

21st 컴포넌트를 HyperFrames 장면에 쓰는 법: 컴포넌트의 마크업/Tailwind 클래스를 가져와 장면 HTML에 정적 마크업으로 옮기고(`init --tailwind` 프로젝트면 클래스 그대로), 상태 변화(hover, press, 토글)는 GSAP 타임라인으로 재현한다.

21st가 없을 때의 대체 순서:

1. **실제 제품 스크린샷/화면 녹화** — 항상 1순위. 가짜 UI보다 진짜 UI.
2. shadcn/ui 컴포넌트 마크업
3. HyperFrames 카탈로그 UI 블록 (`macos-notification`, `browser-device-stage`, `simulated-cursor`, `press-ripple` 등)
4. 직접 그리기 — 마지막 수단. [quality-bar.md](quality-bar.md) 의 UI 항목을 전부 지킨다.

## 참조 분석 도구

`scripts/analyze_ref.sh`는 `yt-dlp`, `ffmpeg`, `ffprobe`, `python3`를 쓴다.

```bash
which yt-dlp ffmpeg ffprobe python3
brew install yt-dlp ffmpeg   # 없을 때 (사용자 승인 후)
```

## 측정 도구

`scripts/frozen_time.sh`, `loudness.sh`, `contact_sheet.sh`는 ffmpeg 필터 `tblend`, `signalstats`, `ebur128`, `tile`을 쓴다 (표준 빌드에 포함). `ffmpeg -hide_banner -filters | grep -E "ebur128|tblend|signalstats"`로 확인한다. `scripts/sfx_candidates.py`는 numpy가 필요하다 (`python3 -c "import numpy"`, 없으면 `python3 -m pip install --user numpy`).
