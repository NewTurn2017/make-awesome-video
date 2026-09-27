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

에이전트는 참조, 스토리보드, 정지 프레임, 노트 네 지점에서 멈추고 사용자의 결정을 기다립니다.

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
bash scripts/analyze_ref.sh "<X post URL | YouTube URL | local mp4>" refs/<slug>
```

## 프로젝트 구조

```
make-awesome-video/
├── SKILL.md                      # 워크플로 + 멈춤 지점 4개
├── install.sh                    # 한 줄 설치 스크립트
├── agents/openai.yaml            # Codex 인터페이스 메타데이터
├── references/
│   ├── setup.md                  # HyperFrames / Remotion / 21st 명령
│   ├── reference-analysis.md     # 참조 영상 → 스타일 스펙
│   ├── storyboard-template.md    # brief.md + 스토리보드 3안 형식
│   ├── director-notes.md         # 카메라 어휘 → 파라미터 변경
│   └── quality-bar.md            # "싸구려로 보이는" 신호 체크리스트
└── scripts/
    ├── setup.sh                  # 의존성 확인 및 설치
    ├── find_refs.py              # whatships.com 카탈로그 검색
    └── analyze_ref.sh            # 참조 영상 분석
```

## 참고

- 참조 영상은 스타일 학습에만 쓰고, 결과물에는 넣지 않습니다.
- Remotion은 3인 이하 팀까지 무료입니다. 그보다 큰 회사는 [회사 라이선스](https://www.remotion.pro/license)가 필요합니다.
- HeyGen, Remotion, 21st, What Ships와 제휴 관계가 없습니다.

## 라이선스

[MIT](LICENSE)
