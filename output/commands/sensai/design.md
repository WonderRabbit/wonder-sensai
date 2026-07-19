---
description: 03 AS-IS 산출. 검증된 trace(AS-IS)에서 UI 정의서·시퀀스·데이터플로우·사용자스토리를 투영(kind:asis). W0–W4 게이트.
agent: sensai-analysis-lead
subtask: true
---

아래 `입력`은 검증된 근거 산출물과 `docs/analysis/` 출력 경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 근거 파일이 없거나 출력이 `docs/analysis/` 밖을 가리키면 아무 파일도 쓰지 말고 사용법과 차단 원인을 보고한다.

## AS-IS 산출 게이트 W0–W4 (03 §5)

- **W0 전제 확인**: `trace.json` AS-IS 구간(01 기술 + 02 비즈니스) + 검증 통과. 어느 한쪽 없으면 해당 PRD(01/02) 회귀.
- **W1 산출 범위 확정**: 어느 AS-IS 사실이 어느 산출로 투영되는지 mapping.
- **W2 AS-IS 투영** 🔴: 4 산출(UI 정의서·시퀀스·데이터플로우·사용자스토리)을 AS-IS 사실에서 투영. 각 요소에 AS-IS 사실 ID. 현재 코드에 없는 것은 발명 금지, 근거 없으면 `UNKNOWN`. **MVP(00 §10)는 UI 정의서 1개**.
- **W3 provenance 검증**: `recipes/provenance.jq`로 역대조. 모든 ID가 원장 AS-IS 사실에 1:1 exact 대응.
- **W4 렌더·적재**: Mermaid류 `mmdc` 렌더(exit 0 + SVG). 산출 경로·근거 ID·렌더 결과를 원장에 기록.

## 결정적 주입 (Context Handoff, T1 §4)

검증된 근거(canonical trace):
@docs/analysis/trace.json

- 선행 컨벤션: `!jq -r '.conventions[] | "\(.id): \(.statement_ko)"' docs/analysis/trace.json`
- 선행 비즈니스(02 있을 때): `!jq -r '.business_entities // empty' docs/analysis/trace.json`

## 스킬 로드

`sensai-evidence-first` → `sensai-ui-definition`(A-1)·`sensai-mermaid-sequence`(A-2). 데이터플로우/스토리 스킬은 입학 후.

## 근거 정책 (불변)

`path:line` 근거. 근거 없으면 `UNKNOWN`/`unresolved`/`ambiguous`/`conflict`. 발명·축약 금지.

## 반환

W0–W4 Pass/Blocker, 산출 경로, 근거 ID, 모순·모호성·미확인, 다음 탐색.
