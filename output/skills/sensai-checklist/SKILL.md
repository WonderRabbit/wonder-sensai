---
name: sensai-checklist
description: 각 게이트 산출의 품질 체크리스트 — 근거/UNKNOWN/validator/권한/ID/모순 보존/잦은 누락 패턴을 점검한다(R6).
---

# 목표

각 게이트(A0-A5/B0-B5/W0-W4/D0-D5/V0-V5) 산출의 필수 품질 항목을 점검한다(R6). 누락·위반을 보고하고 통과/불통과를 판정한다.

## 체크 항목

- **근거**: 모든 사실·설계 ≥1 `path:line` 근거(`evidence_ids`).
- **UNKNOWN 보존**: 근거 없는 주장이 삭제되지 않았는지. `UNKNOWN`/`unresolved`/`ambiguous`/`conflict` 보존.
- **validator**: `recipes/trace.jq` exit 0; `recipes/provenance.jq`(해당 모드) exit 0; `mmdc` exit 0 + 비어있지 않은 SVG.
- **권한**: lead만 `docs/analysis/**` 작성; peer는 읽기 전용(edit/task deny).
- **ID**: 안정적·역대조 가능. 중복·잘못된 형식 없음.
- **모순/모순성**: 하나로 축약되지 않고 보존.
- **일관성 게이트**(04 D4): 각 design ≥1 `follows_convention_ids` + `follows_business_ids`. `bindings[]` gate≠violation.
- **출처**(04): `extension_requirements` 출처 존재; `inferred` 단독 정당성 금지.

## 절차

1. 게이트 산출(`docs/analysis/trace.json` + 산출 파일) 읽기.
2. 체크리스트 항목 점검.
3. 누락·위반 보고(항목·파일·사유).
4. 통과/불통과 판정 + 권장 다음 조치.

## 실패 폐쇄

- 누락된 근거·UNKNOWN 삭제·validator 실패는 불통과.
- 자동 수정하지 않는다(보고만).
