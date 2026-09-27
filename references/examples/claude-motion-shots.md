# 작업 예: 15초 키네틱 타이포 쇼릴 재현 — "CLAUDE"

입력은 참조 mp4 한 개 + 단어 "CLAUDE"뿐이었다. 모드 `motion`. 아래는 그대로 승인 가능한 형태의 샷 리스트와, 실제 빌드에서 확인한 구현 메모다. 전체 컴포지션 소스: [claude-motion-index.html](claude-motion-index.html) (참조 음원·폰트·블록 파일은 포함하지 않음).

참조: 15.0s, 1280×720 30fps, 음악 있음 (`hyperframes beats` → 256bpm, 0.234s 간격; 하드 컷 10개 중 대부분이 비트 ±1프레임 → 비트 동기 편집)

모드: motion · 1920×1080 30fps 15.0s · 샷 13개 · 모티프: 오렌지 사각형 (#FE4A1D)
팔레트: paper #E3E1DB / ink #131313 / orange #FE4A1D / dark #101010 · 폰트: Archivo Variable (wght 100–900, wdth 62–125), JetBrains Mono 라벨
문구 치환: MOTION → CLAUDE, TYPE → THINK, TIME → CODE, FORM → MAKE

| # | 참조 | 우리 | 기법 | 이징 | 모티프 | 구현 | 내용 |
|---|---|---|---|---|---|---|---|
| 1 | 0.0–1.9 | 0.00–1.92 | 사각형 블러 플라이인, 세로 그리드 라인 드로우, 스와시 | expo.out / power4.in | 등장 → 이동 → 스와시 | kit whipIn + 라인 scaleY stagger | 그리드 |
| 2 | 1.9–4.2 | 1.92–4.26 | 타이핑, 사각형이 커서 | 스텝 | 커서 | kit splitChars + typeOn | CLAUDE |
| 3 | 4.2–4.5 | 4.26–4.50 | 오렌지 패널 오른쪽에서 진입 | expo.inOut | 패널로 확장 | kit panelWipe | |
| 4 | 4.5–5.2 | 4.50–5.20 | 단어 분할 두 줄 + 패널 확장 | expo.inOut | | kit 직접 (split 두 줄) | CLA / UDE |
| 5 | 5.2–5.5 | 5.20–5.43 | 배경 오렌지, 굵기 Black→Thin 흰색 | power3.inOut | | kit axis | CLA / UDE |
| 6 | 5.5–6.0 | 5.43–5.90 | 얇고 넓은 단어 → Black | power3.inOut | 좌상단 작은 사각형 | kit axis | THINK |
| 7 | 6.0–6.1 | 5.90–6.14 | 회전 휩 아웃 + 블러 | power4.in | | kit whipOut + rotation | THINK |
| 8 | 6.1–6.6 | 6.14–6.61 | 세로 단어 + 오렌지 패널 속 검은 원 | expo.out | 작은 사각형 | kit pop | CODE |
| 9 | 6.6–7.1 | 6.61–7.08 | 동심원 호 드로우 + 단어 | expo.out | 작은 사각형 | SVG dashoffset | MAKE |
| 10 | 7.1–7.5 | 7.08–7.54 | 화면 폭 단어 + 사각형 | 하드 컷 | 단어 아래 | kit slam | CLAUDE |
| 11 | 7.5–9.0 | 7.54–8.95 | 단어 벽 2 → 2×2 → 4×2 → 12×8 (체커 반전, 오렌지 셀) | 비트마다 하드 컷 | 오렌지 셀 | kit wordWall + gridStagger | CLAUDE |
| 12 | 9.0–11.2 | 8.95–11.29 | 다크 톤 반전, 3D 돌출 소문자 + 줄무늬, 색 교대 | power3.out, 느린 트래킹 | 다크 속 사각형 | kit depthText + extrude | claude |
| 13 | 11.2–12.2 | 11.29–12.23 | 유체 노이즈 필드 오렌지/흰 | linear | | kit noiseField (domain-warp 블록은 데모 컴포지션이라 불가) | |
| 14 | 12.2–13.4 | 12.23–13.40 | 파티클이 모여 단어 | 블록 기본 | | 블록 particle-text-dissolve | CLAUDE |
| 15 | 13.4–15.0 | 13.40–15.00 | 패널 와이프 → 분할 락업, 액센트 마침표, 라벨, 홀드 | expo.inOut → 정지 | 마침표 | kit panelWipe + pop | CLAUDE. / Motion Design |

## 구현 메모 (빌드에서 확인)

- 빌드는 `document.fonts.load(...).then(build)` 안에서. 커서 위치·마침표 위치·`fitWidth`가 글자 크기를 재기 때문.
- `fitWidth` 목표 폭: 메인 단어 1760–1820px, 두 줄 분할 각 1060px, 락업 1300px. 가변 폰트 기본 상태 `wght 900 / wdth 84`.
- 샷 4 분할: 두 줄 각각 `width: max-content` (블록 요소면 fitWidth가 컨테이너 폭을 잰다). 패널은 글자를 덮지 않게 `xPercent 62`에서 멈춤, 글자는 `z-index`.
- 샷 6 THINK: 얇고 넓게(wght 110, wdth 125) → 굵게(wght 900, **wdth 84 = fit 기준값**). 끝 상태를 fit 기준과 다르게 두면 화면 밖으로 넘침.
- 샷 12 3D: `depthText` 22레이어, 뒷면 #707070 (다크 배경 대비 3:1 확보), `rotationY` 28→14→6 + `transformPerspective 1400`. 원근·조명·반사 바닥이 있는 참조 3D와는 차이가 남는다 (Three.js 영역).
- 샷 13–14: 파티클 블록을 11.29s(노이즈 아래)부터 시작해 2.1s 확보, 노이즈 섹션 `z-index:5`. 블록 색은 `:root { --brand: #fff; --font-display: "Archivo" }`.
- 최종 `check` 통과 (lint 0 오류, 레이아웃 0 오류, 대비 35/35). 렌더 15.0s 1920×1080 30fps, 약 10초.

## 참조 대비 남은 차이 (G4 노트 후보)

1. 3D 샷: 참조는 실제 3D(원근, 림 라이트, 반사 바닥, 글자별 깊이). CSS 레이어로는 두께만 난다 → Three.js 이식 필요.
2. 파티클: 참조는 모든 글자가 동시에 입자 → 선명. 블록은 왼쪽→오른쪽 진행.
3. 노이즈: 참조가 조금 더 부드럽고 입자감이 크다 → `noiseField` `scale` 140, `grain` 0.5 시도.
4. 오프닝 사각형: 참조가 약 1.5배 크다.
