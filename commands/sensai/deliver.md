---
description: 05 TO-BE 산출. designs(tobe)를 5 산출(UI·시퀀스·데이터플로우·스토리·테스트)로 투영(kind:tobe). V0–V5 게이트.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 `trace.json`(TO-BE designs)과 `docs/analysis/` 출력 경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 04 designs가 없거나 출력이 `docs/analysis/` 밖이면 아무 파일도 쓰지 말고 사용법과 차단 원인을 보고한다.

## TO-BE 산출 게이트 V0–V5 (05 §5)

- **V0 전제**: 04 `designs[]` 존재·검증. 없으면 04 회귀.
- **V1 산출 범위**: design→산출 mapping.
- **V2 TO-BE 투영** 🔴: 5 산출(UI 정의서·시퀀스·데이터플로우·사용자스토리·테스트시나리오)을 TO-BE designs에서 투영(`kind: tobe`). 각 요소에 design/req/convention/business ID. 발명 금지.
- **V3 provenance 검증**: `recipes/provenance.jq`(5모드) 역대조. 모든 ID가 원장 design/requirement/convention/business에 1:1 exact 대응.
- **V4 Mermaid 렌더**: `mmdc` exit 0 + 비어있지 않은 SVG.
- **V5 적재·검증**: 산출 색인 기록. → backlog(yeoman) 인계.

## 결정적 주입 (Context Handoff, T1 §4)

@docs/analysis/trace.json

- designs: `!jq -c '.designs[]' docs/analysis/trace.json`
- requirements: `!jq -r '.extension_requirements[] | .statement_ko' docs/analysis/trace.json`

## 스킬 로드

`sensai-evidence-first` → `sensai-ui-definition`(3-1)·`sensai-mermaid-sequence`(3-2)·`sensai-dataflow-chart`(3-3)·`sensai-user-story`(3-4)·`sensai-test-scenario`(3-5).

## 산출 형식 (05 §6)

- **3-1 UI 정의서**: Mermaid 와이어프레임 + Markdown. `` `E-ID` @ `path:line` `` + `REQ`/`J`/`DESIGN-ID`.
- **3-2 시퀀스**: `%% REQ/MSG` + `[MSG][REQ]` + `DESIGN-ID`. 한도 ≤20req/≤12participant/≤50msg.
- **3-3 데이터플로우**: Mermaid `flowchart`. `%% DATA`/`%% DESIGN`, 엣지 `[DATA][DESIGN]`.
- **3-4 사용자 스토리**: 한글 역할/행동/가치. `STORY-ID`+`REQ-ID`+`DESIGN-ID`.
- **3-5 테스트 시나리오**: `GIVEN/WHEN/THEN`. `TEST-ID`+`STORY-ID`+`DESIGN-ID`.
- 모든 산출 `kind: tobe`.

## 근거 정책 (불변)

역대조 + `UNKNOWN`/`AMBIGUOUS` 보존. 발명·축약 금지.

## 반환

V0–V5 각 Pass/Blocker, 산출 경로, 근거 ID, 모순·미확인, 다음 탐색.
