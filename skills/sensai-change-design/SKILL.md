---
name: sensai-change-design
description: 수정요청 + AS-IS(컨벤션+비즈니스)로 새/수정 페이지·서비스·API·엔티티 변경 설계를 designs[](kind:tobe)로 만든다(04 D3). 일관성 게이트 — follows_convention_ids + follows_business_ids ≥1 강제.
---

# 목표

`extension_requirements[]` + AS-IS(기술 컨벤션 + 비즈니스)를 소비해 변경 설계(`designs[]`, `kind: tobe`)를 만든다. 각 설계는 AS-IS 컨벤션/비즈니스에 binding한다(일관성 게이트).

## 절차

1. `extension_requirements[]` + `conventions[]` + `business_*[]` 읽기.
2. 설계(`designs[]`) 도출 — type: `page`/`service`/`api`/`entity`.
3. **D4 일관성 게이트**: 각 설계 ≥1 `follows_convention_ids` + ≥1 `follows_business_ids`.
4. `bindings[]` 기록: `design_id ↔ convention_id|business_id`, `gate: pass|violation`.
5. 위반/binding 없음 → 불통과.

## design 엔티티 (04 §9)

```json
{ "id": "DESIGN-PAGE-001", "kind": "tobe", "type": "page",
  "statement_ko": "주문 상세 페이지를 /orders/:id에 추가한다.",
  "requirement_ids": ["REQ-EXT-0001"],
  "follows_convention_ids": ["CONV-STRUCTURE-001","CONV-SCAFFOLD-001"],
  "follows_business_ids": ["BIZ-RULE-001"],
  "evidence_ids": ["E-STRUCT-007"], "status": "exact" }
```

## 근거 정책 (불변)

binding 강제. 위반 = `gate: violation`(불통과). 출처 불명 = `UNKNOWN`. 이름 유사도로 binding 채우기 금지.
