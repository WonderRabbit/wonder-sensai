---
description: 04 TO-BE 변경 설계. 고객 수정요청 + AS-IS(컨벤션+비즈니스)로 designs[](kind:tobe)+bindings[]를 D0–D5 게이트로 생성. 일관성 게이트 강제.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 `trace.json`(AS-IS 양쪽) + 고객 수정요청과 `docs/analysis/` 출력 경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 AS-IS 양쪽 분석이 없거나 출력이 `docs/analysis/` 밖이면 아무 파일도 쓰지 말고 사용법과 차단 원인을 보고한다.

## 설계 게이트 D0–D5 (04 §5)

- **D0 전제 확인**: AS-IS 양쪽(01 기술 + 02 비즈니스) 존재·검증. 어느 한쪽 없으면 해당 PRD 회귀.
- **D1 수정요청 수집(intake)**: 고객 수정요청 파싱·항목화. 결손는 명시 질문(`elicited`) 또는 `UNKNOWN`. 임의 채움 금지.
- **D2 수정요청 분석(analyze)**: `REQ-EXT-<NNNN>` ID, 키워드(MUST/SHOULD/MAY) 보존, 중복/충돌 검출, peer로 기존 코드와 관계 조사.
- **D3 변경 설계(design)** 🔴: 새/수정 페이지·API·엔티티 설계. 컨벤션(네이밍·구조·API패턴·상태·scaffold) **및 비즈니스 규칙**을 제약으로 소비.
- **D4 일관성 게이트(consistency gate)** 🔴: 각 설계가 binding한 컨벤션/비즈니스가 입증됐고 위반 없는지 검증. `bindings[]`로 결과 기록. 위반/binding 없음 → 불통과.
- **D5 TO-BE 적재·검증**: 원장 TO-BE 적재, `trace.jq` 검증. → 05 인계.

## 결정적 주입 (Context Handoff, T1 §4)

@docs/analysis/trace.json

- 컨벤션: `!jq -r '.conventions[] | "\(.id): \(.statement_ko)"' docs/analysis/trace.json`
- 비즈니스 규칙: `!jq -r '.business_rules[] | "\(.id): \(.statement_ko)"' docs/analysis/trace.json`

## 스킬 로드

`sensai-evidence-first` → `sensai-requirement-analyze`(D1-D2) → `sensai-change-design`(D3, 일관성 게이트).

## 설계 형식 (04 §9)

- `designs[]`: `DESIGN-<TYPE>-<NNN>`(TYPE=PAGE/SERVICE/API/ENTITY), `kind: tobe`, `follows_convention_ids`(≥1) + `follows_business_ids`(≥1), `requirement_ids`, `evidence_ids`.
- `bindings[]`: `design_id ↔ convention_id|business_id`, `gate: pass|violation`.

## 근거 정책 (불변)

binding 강제. 위반 = `gate: violation`(불통과). 출처 불명 = `UNKNOWN`. `inferred` 단독 정당성 금지. 이름 유사도로 binding 채우기 금지.

## 반환

D0–D5 각 Pass/Blocker, `designs`/`bindings`, 근거 ID, 모순·미확인·`UNKNOWN`, 다음 탐색.
