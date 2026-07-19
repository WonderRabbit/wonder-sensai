---
description: 02 AS-IS 비즈니스 심층 분석. 엔티티·규칙·흐름·이벤트·상태·불변조건을 B0–B5 게이트로 추출(kind:asis). 01(기술)과 병렬. 근거 없으면 UNKNOWN.
agent: sensai-analysis-lead
subtask: true
---

아래 `입력`은 사용자가 제공한 분석 범위와 출력 계약이다.

입력:
$ARGUMENTS

입력이 비어 있거나 저장소 범위와 `docs/analysis/` 출력 경로를 식별하지 못하면 아무 파일도 쓰지 말고 사용법과 누락 필드를 보고한다.

## 비즈니스 분석 게이트 B0–B5 (02 §5)

- **B0 범위·전제**: root/scope 고정, 사전 존재 파일 hash 보존, 도메인 문서(선택) 확인. 01(기술)과 병렬 가능(세션 분리 권장).
- **B1 비즈니스 엔티티 발견**: DB 스키마/마이그레이션·도메인 모델·ORM 정의에서 엔티티·식별자·속성·관계 추출(`ast-grep`/`yq`/`jq`). Output: `business_entities[]`(근거 포함).
- **B2 비즈니스 규칙 추출** 🔴 핵심: 검증·제약·정책 코드(validator, guard, policy, 계산 로직)에서 규칙 추출. 의미 판단은 lead가 도구로 재확인한 근거만 확정. 근거 없는 규칙 → `UNKNOWN`.
- **B3 프로세스·흐름·이벤트·상태 추출**: 워크플로우·상태 전이·이벤트 발행/구독에서 흐름·상태·이벤트 추출. 기술 호출/이벤트(01)와 cross-ref. Output: `business_flows[]`·`business_events[]`·`business_states[]`·`business_invariants[]`.
- **B4 정규화·적재**: 안정적 ID(`BIZ-<CAT>-<NNN>`, CAT = ENT/RULE/FLOW/EVT/STATE/INV), `kind: asis`, category, status 확정, 원장 `business_*` 적재. 기술 사실 cross-ref 연결. 모순/모순성 보존.
- **B5 검증**: `recipes/trace.jq`로 비즈니스 사실 무결성 검사(근거·ID·상태). unknowns/unsupported 요약.

## 결정적 주입 (Context Handoff, T1 §4)

- 도메인 문서(선택, 있을 때): `@docs/analysis/domain.md`
- 선행 01 기술 분석(있으면): `@docs/analysis/trace.json`
- 선행 컨벤션: `!jq -r '.conventions[] | "\(.id): \(.statement_ko)"' docs/analysis/trace.json`

## 스킬 로드

먼저 `sensai-evidence-first`를 불러온다. B1–B3에서 `sensai-business-trace` 호출. 식별된 스택의 `react`/`vertx`/`spec-trace` 가속기는 01과 공유.

## 비즈니스 사실 형식 (02 §6)

- `BIZ-ENT`(`business_entity`): 엔티티·식별자·속성·관계. `identifiers[]` 필드.
- `BIZ-RULE`(`business_rule`): 검증·제약·정책·계산 규칙.
- `BIZ-FLOW`/`BIZ-EVT`/`BIZ-STATE`/`BIZ-INV`: 흐름·이벤트·상태·불변조건.
- 모든 사실 `kind: asis`, ≥1 `evidence_ids`, 안정적 ID, status(`exact`/`unresolved`/`ambiguous`/`conflict`).

## 용어사전(Glossary, 02 §6.1)

B1/B2에서 도메인 용어를 함께 수집. `docs/analysis/glossary.json` + `.ko.md`. 항목: `term_id`(`GLOSS-NNN`)/`term_ko`/`term_canonical`/`identifier_form`/`definition_ko`/`category`/`evidence_ids`/`maps_to`. 발명 용어 금지, 원장에 근거 연결. 원장 충돌 시 원장 우선.

## 근거 정책 (불변)

코드 근거 1차 + 도메인 문서 보조. 암묪적 규칙 `UNKNOWN`. 모순/모호성 보존. 발명·축약 금지.

## 반환

B0–B5 각 Pass/Blocker, `business_*` 산출, 근거 수, 모순·모호성·미확인·UNSUPPORTED, 01 cross-ref, 다음 탐색.
