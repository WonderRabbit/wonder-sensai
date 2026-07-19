---
name: sensai-spec-evidence
description: OpenAPI와 IETF(RFC 2119/8174) 요구사항 명세에서 원문 modality와 식별자를 보존해 근거로 추출한다. 한국어 해석을 요구사항으로 승격하지 않는다.
---

# 목표

명세(OpenAPI/RFC)에서 요구사항 근거를 추출한다. 원문 `modality`(식별자·키워드)를 보존하고, 근거 없는 한국어 해석을 요구사항으로 승격하지 않는다.

## 대상

- **OpenAPI**: `operationId`, `path`, `method`, 응답 상태.
- **RFC 2119/8174**: `MUST`/`MUST NOT`/`SHOULD`/`SHOULD NOT`/`MAY` 키워드(원문 보존).

## 절차

1. `yq -o=json '.' openapi.yaml`로 OpenAPI YAML을 JSON 정규화.
2. `jq`로 `operationId`/`path`/`method`/응답 추출(`path:line`).
3. `mdq`로 RFC 키워드 구조 질의 — 원문 keyword 보존.

## 근거 정책 (불변)

원문 식별자·키워드 보존. 한국어 해석은 표현이지 요구사항 승격 근거가 아니다. 근거 없으면 `UNKNOWN`.
