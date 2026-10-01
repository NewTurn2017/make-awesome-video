[English](README.md) · [한국어](README.ko.md)

# make-awesome-video

"프롬프트 한 번 → 영상"이 아니라, **프로 수준의 모션그래픽 런치 영상**을 감독하듯 만들게 해주는 에이전트 스킬입니다. Claude Code, Codex 등 스킬을 지원하는 에이전트에서 동작합니다.

모두가 같은 모델을 씁니다. 영상을 프로처럼 보이게 만드는 건 모델에 주는 컨텍스트입니다. 참조가 없으면 에이전트는 기본값으로 돌아갑니다. 중앙 정렬 텍스트, 그라데이션 배경, 모든 게 페이드 인. 이 스킬은 그 자리를 감독의 워크플로로 바꿉니다.

1. **참조 영상.** [whatships.com](https://whatships.com)에서 1–2개를 골라 페이싱·타이포·트랜지션·팔레트를 측정 가능한 스타일 스펙으로 바꿉니다.
2. **코드로 MP4 렌더링.** [HyperFrames](https://github.com/heygen-com/hyperframes)(기본) 또는 [Remotion](https://www.remotion.dev)을 씁니다. 모든 프레임이 정확하고, 수정은 한 줄 고치고 다시 렌더링하면 됩니다.
3. **실제 UI 컴포넌트.** 실제 스크린샷이나 [21st](https://21st.dev/mcp)·shadcn 컴포넌트를 씁니다. 에이전트가 UI를 즉석에서 지어내지 않습니다.
4. **컨텍스트 전부 투입.** 브랜드(로고·색·폰트), 제품 스크린샷, 참조, 브레인덤프를 넣어 **방향이 서로 다른 스토리보드 3안**을 받습니다.
5. **움직이기 전에 정지 프레임.** 장면마다 대표 프레임을 1장씩 만듭니다. 스토리보드 수정은 몇 초면 되지만, 렌더 수정은 다시 렌더링해야 합니다.
6. **감독 노트.** "모든 줌을 0.7x로 느리게", "여기 하드 컷", "버튼에 푸시 인" 같은 카메라 언어를 정확한 파라미터 변경으로 옮깁니다.
7. **만든 에이전트가 채점하지 않습니다.** 렌더를 보여주기 전에, 브리프와 참조만 아는 새 서브에이전트가 실제 MP4로 판정합니다(정지 구간, 음량, 빈 화면, 글자 충돌, 전환). 수정할 때마다 또 다른 새 크리틱이 항목별로 확인하고, 모든 라운드는 원장에 남습니다.

에이전트는 참조, 스토리보드, 정지 프레임, 노트 네 지점에서 멈추고 사용자의 결정을 기다립니다.

### 어떤 영상인지 설명하지 않아도 됩니다

주어진 입력만 보고 모드를 판별합니다.

| 주는 것 | 모드 | 진행 |
|---|---|---|
| 제품 URL, 스크린샷, 브랜드 | `launch` | whatships 참조 → 스토리보드 3안 → 정지 프레임 → 렌더 |
| **참조 영상 + 단어 하나** ("이것처럼, 단어는 CLAUDE") | `motion` | 참조를 초당 4프레임으로 샷 단위 분해하고, 기법(굵기 모핑, 패널 분할, 단어 벽, 3D 돌출, 노이즈 필드, 파티클 글자, 락업)마다 HyperFrames 블록·애니메이션 룰·모션 킷 헬퍼를 연결합니다. 컷은 음악 비트에 맞추고, 정지 프레임과 최종 렌더를 참조와 나란히 비교합니다 |
| 카드뉴스·포스터 등 정적 이미지 | `info` | 실제 화면 크기에 맞춘 사이니지·키오스크 루프, 루프 이음새 검증 |
| 세로, 20초 이하 | `social` | 훅 중심 숏폼 |

**모션 킷**(`assets/motion-kit/`)에는 검증된 seek-safe GSAP 헬퍼가 들어 있습니다: `fitWidth`(글자가 화면 폭을 채움), `typeOn`, `maskRise`, `slam`, 가변 폰트 `axis` 모핑, `panelWipe`, 루프 이음새까지 처리하는 브랜드 `ringWipe`, `wordWall` + `gridStagger`, CSS `depthText` 돌출, 결정적 `noiseField`, 비트 `snap`. 참조 영상으로 15초 키네틱 타이포 쇼릴을 재현한 작업 예가 `references/examples/`에 있습니다.

## 빠른 시작

```bash
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | bash
```

스킬을 `~/.claude/skills/make-awesome-video`에 설치합니다. Codex 등 다른 에이전트를 쓰면 `~/.agents/skills`에도 링크합니다. 그다음 아래 도구를 확인하고 **빠진 것을 설치**합니다.

| 도구 | 용도 |
|---|---|
| Node.js 22+ | HyperFrames / Remotion 실행 |
| ffmpeg / ffprobe | 렌더링, 참조 분석 |
| yt-dlp | 참조 영상 다운로드 |
| HyperFrames CLI + Chrome + 공식 에이전트 스킬 | 기본 렌더러 |
| Remotion 에이전트 스킬 + `create-video` | 대안 렌더러 |
| 21st MCP | 선택 사항. 확인만 하고 자동 설치하지 않음 (API 키 필요) |

설치 후 에이전트 세션을 재시작해야 새 스킬이 로드됩니다. 그다음 이렇게 말하면 됩니다.

```
우리 제품 런치 영상 만들어줘
/make-awesome-video
```

### 설치 옵션

```bash
# 렌더러 하나만
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | MAV_ENGINE=hyperframes bash

# 스킬만 설치, 의존성 설정 생략
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | MAV_SKIP_DEPS=1 bash

# 설치 위치 지정
curl -fsSL https://raw.githubusercontent.com/NewTurn2017/make-awesome-video/main/install.sh | MAV_DIR=~/my-skills/make-awesome-video bash
```

설치 명령을 다시 실행하면 기존 git 설치를 업데이트합니다(`git pull --ff-only`).

의존성은 언제든 확인하거나 복구할 수 있습니다.

```bash
bash ~/.claude/skills/make-awesome-video/scripts/setup.sh --check
bash ~/.claude/skills/make-awesome-video/scripts/setup.sh
```

시스템 패키지는 Homebrew로, 또는 비밀번호 없는 `sudo`가 가능하면 apt/dnf/pacman으로 설치합니다. 둘 다 안 되면 스크립트가 수동 설치 명령을 출력합니다.

### 선택: 21st UI 컴포넌트

```
claude plugin marketplace add 21st-dev/magic-mcp
/plugin install 21st
```

[21st.dev/mcp](https://21st.dev/mcp)에서 API 키를 발급받아 `API_KEY_21ST`에 설정합니다.

## 준비물

- 로고(SVG 권장), 브랜드 색(HEX), 폰트 이름 또는 파일
- **실제 제품 스크린샷이나 화면 녹화.** 가장 중요합니다. 사이트 URL만 있어도 캡처할 수 있습니다.
- 머릿속에 그리는 영상에 대한 짧은 브레인덤프
- 길이, 비율, 게시 채널 (기본값: 20–40초, 1920x1080)
- 선택: 마음에 드는 참조 영상 1–2개. 없으면 스킬이 찾아줍니다.

## 포함된 스크립트

```bash
# 큐레이션된 런치 영상 약 2,200개 검색
python3 scripts/find_refs.py "terminal devtool" --category "Developer tools" --limit 8 --details
python3 scripts/find_refs.py --list-categories

# 참조 영상 → 컷 시점, 변화 피크, 컨택트 시트, 샷, 팔레트
# --fps 4: 모션 그래픽 참조용 타임스탬프 밀도 시트 추가
bash scripts/analyze_ref.sh "<X post URL | YouTube URL | local mp4>" refs/<slug> --fps 4

# 루프 영상: 첫 프레임과 마지막 프레임 일치 검증
python3 scripts/loop_seam.py renders/out.mp4

# 렌더 검수: 정지 구간(0.6초 넘는 홀드가 있으면 exit 1), 음량, 컨택트 시트
bash scripts/frozen_time.sh renders/v1.mp4 --ignore-tail 1.5
bash scripts/loudness.sh renders/v1.mp4
bash scripts/contact_sheet.sh renders/v1.mp4 review/sheet.jpg 0.25 8 6

# 듣기 전에 효과음 후보 거르기 (붕붕거림 / 쉿 소리 / 너무 김)
python3 scripts/sfx_candidates.py assets/sfx/*.mp3
```

## 프로젝트 구조

```
make-awesome-video/
├── SKILL.md                      # 워크플로 + 멈춤 지점 4개
├── install.sh                    # 한 줄 설치 스크립트
├── agents/openai.yaml            # Codex 인터페이스 메타데이터
├── LICENSES/                     # 서드파티 고지 (motion-video-kit, MIT)
├── assets/motion-kit/            # kit.js + kit.css (seek-safe GSAP 헬퍼)
├── references/
│   ├── modes.md                  # 모드 판별: launch / motion / info / social
│   ├── shot-decomposition.md     # 참조 → 샷 리스트, 기법 → 블록·룰·킷 매핑
│   ├── motion-craft.md           # 모티프 연속성, 페이싱 곡선, 비트 동기, 이징, 타이포
│   ├── motion-grammar.md         # 장면 사이 규칙, 메커니즘 카탈로그, 런치 영상 참조 28편
│   ├── critic-loop.md            # 빌더 ≠ 판정자: 게이트별 크리틱 라운드, 프롬프트, 원장
│   ├── audio.md                  # 음악 선택·편집, 효과음, 대역별 레벨, 믹스 목표
│   ├── three-d.md                # 결정적 Three.js, 랩 먼저, 히어로 모션 실측, 모션 블러
│   ├── gotchas.md                # 실전에서 확인된 함정과 해결
│   ├── examples/                 # 작업 예: 키네틱 타이포 쇼릴 재현
│   ├── setup.md                  # HyperFrames / Remotion / 21st 명령
│   ├── reference-analysis.md     # 참조 영상 → 스타일 스펙
│   ├── storyboard-template.md    # brief.md + 스토리보드 3안 형식
│   ├── director-notes.md         # 카메라 어휘 → 파라미터 변경
│   └── quality-bar.md            # 측정 기준 + "싸구려로 보이는" 신호 체크리스트
└── scripts/
    ├── setup.sh                  # 의존성 확인 및 설치
    ├── find_refs.py              # whatships.com 카탈로그 검색
    ├── analyze_ref.sh            # 참조 영상 분석
    ├── loop_seam.py              # 루프 이음새 검증
    ├── frozen_time.sh            # 렌더의 정지 구간·최장 홀드
    ├── loudness.sh               # 통합 LUFS, LRA, true peak, 초당 short-term
    ├── contact_sheet.sh          # 검수·크리틱용 컨택트 시트
    └── sfx_candidates.py         # 효과음 후보 거르기 (numpy 필요)
```

## 참고

- 참조 영상은 스타일 학습에만 쓰고, 결과물에는 넣지 않습니다.
- Remotion은 3인 이하 팀까지 무료입니다. 그보다 큰 회사는 [회사 라이선스](https://www.remotion.pro/license)가 필요합니다.
- HeyGen, Remotion, 21st, What Ships와 제휴 관계가 없습니다.
- 크리틱 루프, 모션 문법, 오디오 규칙, 3D 노트, 측정 스크립트는 echris6의 [motion-video-kit](https://github.com/echris6/motion-video-kit)(MIT)을 옮겨 고친 것입니다. 원 저작권 고지는 [LICENSES/motion-video-kit.txt](LICENSES/motion-video-kit.txt)에 있습니다.

## 라이선스

[MIT](LICENSE)
