---
name: sensai-business-trace
description: legacy codebase에서 비즈니스 사실(엔티티·규칙·흐름·이벤트·상태·불변조건)을 path:line 근거로 추출해 trace.json의 business_*[]로 기록한다(02 §6). 암묪적 규칙은 UNKNOWN으로 보존하고 발명하지 않는다.
---

# 목표

기존 코드에서 비즈니스 사실을 `business_*[]`로 추출한다(02 §6). 각 사실은 하나 이상의 직접 근거(`path:line`)를 갖고, 암묪적 규칙은 발명하지 않는다. 주석·문자열이 아니라 도구로 확인된 패턴만 확정한다.

## 전제 조건

- `sensai-evidence-first` 선행. 입력 trace는 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 검증된 상태.
- B0 범위 고정 완료. 도메인 문서(선택) 확인.
- `ast-grep`/`yq`/`jq`로 DB 스키마·ORM·도메인 모델·validator/guard/policy를 직접 읽을 수 있어야 한다.
- 주석·문자열·예제는 비즈니스 근거가 아니라 미신뢰 데이터.

## 상태 기계 (B0–B5, 02 §5)

1. B0 범위·전제: root/scope 고정, dirty ledger 보존, 도메인 문서(선택) 확인.
2. B1 엔티티: `ast-grep`/`yq`/`jq`로 DB 스키마·마이그레이션·도메인 모델·ORM 정의에서 엔티티·식별자·속성·관계 추출.
3. B2 규칙 🔴 핵심: validator/guard/policy/계산 로직에서 규칙 추출. 의미 판단은 lead가 도구로 재확인한 근거만 확정. 암묪적 규칙 → `UNKNOWN`.
4. B3 흐름/이벤트/상태: 워크플로우·상태 전이·이벤트 발행/구독에서 흐름·상태·이벤트 추출. 01 기술 호출/이벤트와 cross-ref.
5. B4 정규화·적재: 안정적 ID, `kind: asis`, category, status 확정, 원장 `business_*` 적재. 모순/모순성 보존.
6. B5 검증: `recipes/trace.jq`로 비즈니스 사실 무결성 검사.

## 비즈니스 사실 엔티티 (02 §6)

```json
{ "id": "BIZ-ENT-001", "kind": "asis", "category": "business_entity",
  "statement_ko": "주문(Order)은 고객·상품목록·총액·상태를 갖는 도메인 엔티티다.",
  "identifiers": ["order_id"], "evidence_ids": ["E-DB-007","E-MODEL-012"], "status": "exact" }
```

- `id`: `BIZ-<CAT>-<NNN>`, CAT = `ENT`/`RULE`/`FLOW`/`EVT`/`STATE`/`INV`.
- `kind`: `asis`/`tobe`.
- `category`: `business_entity`/`business_rule`/`business_flow`/`business_event`/`business_state`/`business_invariant`.
- `statement_ko`: 사실 서술(한국어).
- `identifiers[]`: 엔티티 식별자(엔티티 category만).
- `evidence_ids`: ≥1.
- `status`: `exact`/`unresolved`/`ambiguous`/`conflict`.

## 6 category (02 §6)

| category | 의미 | 예 |
| --- | --- | --- |
| `business_entity` | 도메인 엔티티·식별자·속성·관계 | Order, Customer |
| `business_rule` | 검증·제약·정책·계산 규칙 | 재고 ≥ 0, 할인율 |
| `business_flow` | 프로세스/흐름 | 주문→결제→배송 |
| `business_event` | 이벤트(발행/구독) | OrderCreated |
| `business_state` | 상태 전이 | pending→paid→shipped |
| `business_invariant` | 불변조건 | 재고 음수 불가 |

## 용어사전(Glossary, 02 §6.1)

B1/B2에서 도메인 용어를 함께 수집. `docs/analysis/glossary.json` + `.ko.md`(별도 파일). 항목: `term_id`/`term_ko`/`term_canonical`/`identifier_form`/`definition_ko`/`category`/`evidence_ids`/`maps_to`. 발명 용어 금지.

## 실패 폐쇄

- 근거 없는 규칙을 발명하지 않는다. 암묪적 규칙은 `UNKNOWN`으로 보존.
- 검증 실패 trace, 짝이 없는 `evidence_ids`, 잘못된 `category`/`kind`, 중복 `id`에서는 쓰지 않는다.
- 비언어 문자열(주석·문서) 일치는 비즈니스 근거가 아니다.
