# 참조 영상 → 샷 리스트 역설계

`motion` 모드의 핵심. 참조를 **샷 단위 기법 목록**으로 분해하고, 각 샷을 검증된 구현 수단(HyperFrames 레지스트리 블록 / 애니메이션 룰 / motion-kit 헬퍼)에 매핑한다. 목표는 복제가 아니라 같은 문법으로 사용자 문구를 연출하는 것.

## 1. 뽑기

```bash
bash {baseDir}/scripts/analyze_ref.sh <ref.mp4|URL> refs/<slug> --fps 4
```

- `contact_dense.png`: 초당 4프레임, 타임스탬프 라벨. 모션 그래픽은 1초 간격으로는 기법이 안 보인다. 반드시 이걸 본다.
- `cuts.txt`, `peaks.txt`: 하드 컷과 변화 피크.
- 음악이 있으면 프로젝트에 음원을 넣고 `npx hyperframes beats <project>` → `beats/<audio>.json` (`{beats:[{time,strength}]}`). 컷 타임을 비트와 대조해 "비트 동기 편집인지" 확인한다 (컷의 대부분이 비트 ±1프레임이면 비트 동기).

## 2. 샷 경계 정하기

컷/피크 시점 + 밀도 시트에서 **화면의 주인공이 바뀌는 지점**을 샷 경계로 삼는다. 모션 그래픽은 한 샷 안에서 형태가 계속 변하므로(단어가 쪼개지고, 굵기가 바뀌고, 패널이 들어옴) "컷"이 아니라 "기법이 바뀌는 지점"으로 나눈다. 보통 15초에 8–12샷.

## 3. 샷 리스트 형식 (`shots.md`)

```markdown
| # | 참조 시간 | 우리 시간 | 기법 | 이징·속도 감각 | 모티프 | 구현 | 우리 내용 |
|---|---|---|---|---|---|---|---|
| 1 | 0.0–1.9 | 0.0–1.9 | 사각형 블러 플라이인 → 세로 그리드 라인 드로우 | expo.out, 빠름→정지 | 오렌지 사각형 등장 | kit: whipIn + scaleY 라인 stagger | 동일 |
| 2 | 1.9–3.5 | 1.9–3.5 | 타이핑 + 사각형이 커서→글자 조각으로 | 글자당 0.1s, 스텝 | 사각형 = 커서 | kit: splitChars + typeOn | "CLAUDE" |
```

- **모티프** 열: 컷을 넘어 계속 등장하는 요소(색 사각형, 원, 선). 모션 디자인의 연속성은 여기서 나온다. 없으면 비워둔다.
- **구현** 열에는 아래 매핑표의 이름만 쓴다. 표에 없는 기법이면 "직접 구현"이라고 쓰고 이유를 한 줄 적는다.

## 4. 기법 → 구현 매핑표

이름은 HyperFrames v0.8.x 카탈로그(`npx hyperframes catalog --json`)와 `hyperframes-animation` 스킬에서 확인한 것만 적었다. 블록은 `npx hyperframes add <name>`으로 설치하고, 사용 전 `npx hyperframes catalog --query "<name>"` 로 존재를 다시 확인한다.

### 타이포그래피

| 기법 (참조에서 보이는 것) | 1순위 구현 | 대안 |
|---|---|---|
| **단어가 화면 폭을 꽉 채움** (모션 쇼릴의 기본 스케일) | kit `fitWidth(sel, 1760–1820)` + 가변 폰트 wdth 80–90 (컨덴스드) | 고정 font-size (비권장: 폰트마다 폭이 달라 참조 스케일이 안 나옴) |
| 글자 하나씩 타이핑 | kit `splitChars` + `typeOn` | 블록 `typewriter`, `typed-prompt` |
| 줄/단어가 마스크 안에서 올라옴 | kit `maskRise` | 룰 `discrete-text-sequence` |
| 굵기·너비가 모핑 (Black↔Thin, Condensed↔Wide) | kit `axis` + 가변 폰트 (`.mak-var`) | 블록 `variable-font-flex`, `variable-axis-type`, `weight-wave` |
| 단어가 쪼개지며 패널이 사이로 들어옴 | 블록 `type-match-cut` | kit `panelWipe` + 두 줄 레이아웃 |
| 큰 단어가 쾅 하고 착지 | kit `slam` | 블록 `headline-slam`, 룰 `kinetic-beat-slam` |
| 단어 교체가 비트마다 제자리에서 | 블루프린트 `kinetic-type-beats` | 블록 `kinetic-type-swap`, `line-swap` |
| 글자가 흩어졌다 모임 | 블록 `char-slam-explode` | 룰 `depth-scatter-assemble` |
| 파티클이 모여 글자가 됨 / 글자가 파티클로 흩어짐 | 블록 `particle-text-dissolve` (아래 "블록 사용 메모" 필수) | 블록 `code-particle-assemble` (코드용) |
| 단어 반복 벽 / 체커보드 반전 | kit `wordWall` + `gridStagger` | 블록 `mk-clone-wall-transition` |
| 격자 셀이 순차 등장 | 블록 `stagger-lattice` | kit `gridStagger` |
| 워드마크가 글자 단위로 모이고 액센트 마침표 | 블록 `logo-brand-close` | 블록 `logo-sting`, `titlecard-lockup` |
| 3D 돌출 글자 | kit `depthText` + `extrude` (CSS 레이어) | 룰 `3d-text-depth-layers`; 실제 카메라 회전이 필요하면 `hyperframes-animation/adapters/three.md` |
| 텍스트 위에 줄무늬/텍스처 | `background-clip: text` + `repeating-linear-gradient` | 블록 `texture-mask-text` |
| 세로쓰기 단어 | `writing-mode: vertical-rl` 또는 `rotation: -90` 래퍼 | |

### 도형·그래픽

| 기법 | 1순위 | 대안 |
|---|---|---|
| 원이 커지며 다음 장면이 됨 (도형 매치 컷) | 블록 `match-cut` | 블록 `iris-reveal`, kit `ringWipe` |
| 동심원 호가 그려짐 | SVG `stroke-dasharray/dashoffset` 트윈 | 룰 `svg-icon-enrichment` |
| 그리드 선이 그려짐 | 선 div `scaleY 0→1` stagger | 블록 `dynamic-grid` |
| 색 패널이 화면을 가름 | kit `panelWipe` | 블록 `comparison-split` |

### 전환·효과

| 기법 | 1순위 | 대안 |
|---|---|---|
| 좌우 휩 | kit `whipIn`/`whipOut` | 블록 `whip-pan-cut`, 셰이더 `whip-pan` |
| 유체/노이즈 필드 (오렌지·흰 마블링, 등고선) | kit `noiseField(canvas, at, dur, {a, b, scale, band, grain})` | 블록 `halftone-field`; 셰이더가 꼭 필요하면 아래 메모 |
| 글리치 | 셰이더 `glitch`, 룰 `chromatic-glitch` | 블록 `scan-band` |
| 모션 블러 스미어 | `hyperframes-animation/references/motion-blur.md` | kit whip의 blur |
| 줌 스루 | 셰이더 `cinematic-zoom` | 블록 `camera-dolly-zoom` |
| 브랜드 링 아이리스 | kit `ringWipe` | 셰이더 `sdf-iris` |

### 블록 사용 메모 (실제 설치해서 확인한 것)

- **"Shader transition with …" 계열(`domain-warp-dissolve` 등)은 끼워 넣는 전환이 아니라 데모 컴포지션이다.** `hyperframes add domain-warp-dissolve`는 자체 콘텐츠(블루프린트 그리드, 자체 폰트)가 들어간 4초짜리 완성 컴포지션을 설치한다. 내 두 장면 사이에 바로 쓸 수 없다. 같은 계열(`glitch`, `whip-pan`, `ridged-burn` …)은 add 후 구조부터 확인하고, 필요하면 셰이더 코드만 이식한다. 셰이더 합성 경로를 타면 루트 배경은 투명 처리되므로 배경색은 전체 크기 자식 요소에 둔다 (`hyperframes-core`).
- **`particle-text-dissolve`** (컴포넌트 서브 컴포지션):
  - 마운트: `data-composition-id="particle-text-dissolve"` + `data-composition-src="compositions/components/particle-text-dissolve.html"` + `data-variable-values='{"text":"…","direction":"in","density":"high","accent":"green","exit":"none"}'` + `data-start/duration/track-index/width/height`.
  - 색은 `accent` 열거값이 CSS 변수에 매핑된다 (green → `--brand`). 원하는 색은 호스트 `:root`에서 `--brand`를 덮어쓴다. 폰트는 `--font-display`.
  - 조립(IN)은 약 2.8s 동안 **왼쪽→오른쪽**으로 진행된다. 슬롯이 1.2s면 단어가 반만 모인 채 컷된다. **2s 이상 확보**하고, 앞 장면 아래에서 미리 시작시켜(앞 장면에 z-index) 드러나는 순간 이미 진행 중이게 한다.
  - 참조가 "모든 글자가 동시에 모임"이면 이 블록과 결이 다르다. 샷 리스트에 차이를 적는다.

## 5. 샷 리스트 승인(G2) 제시 방법

- 표 전체 + 요약 3줄 (길이·샷 수·평균 샷 길이, 모티프, 음악/비트 여부)
- 사용자 문구가 어디에 들어가는지 명시
- "이 샷은 참조와 다르게 가겠다"가 있으면 이유와 함께 표시 (예: 한글 문구라 세로쓰기 샷을 가로로)

## 6. 참조 대비 검증 (G3·G4)

```bash
npx hyperframes snapshot <project> --at <샷별 중간 시점들> --against refs/<slug>/ref.mp4
```

샷마다 render|reference 쌍 이미지를 보고 차이를 **카메라 어휘로** 적는다 (예: "3번: 참조는 패널이 0.3s에 닫히는데 우리는 0.6s → 2배 빠르게", "7번: 참조 체커보드는 6×4, 우리는 4×2 → 셀 늘리기"). 이 목록을 사용자에게 먼저 보여주고 G4 노트를 받는다.
