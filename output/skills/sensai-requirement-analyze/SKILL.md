---
name: sensai-requirement-analyze
description: 고객 수정요청을 파싱·항목화해 extension_requirements[]로 적재한다(04 D1-D2). 출처(user/elicited/inferred) 부여, RFC 2119/8174 키워드 보존, 중복/충돌 검출.
---

# 목표

고객 수정요청을 분석해 `extension_requirements[]`로 정리한다. 출처와 키워드를 보존하고, 중복/충돌을 검출한다.

## 절차

1. 고객 수정요청(자연어/문서) 파싱·항목화.
2. `REQ-EXT-<NNNN>` ID 부여.
3. 출처 부여: `user`(고객 직접) / `elicited`(명시 질문-답) / `inferred`(코드 유추).
4. RFC 2119/8174 키워드(`MUST`/`SHOULD`/`MAY`) 원문 보존.
5. peer로 기존 코드와 관계 조사, 중복/충돌 검출.

## 근거 정책 (불변)

- 출처 강제. 출처 없는 수정요청 = `UNKNOWN`.
- `inferred` 단독 정당성 금지(확인 요청).
- `inferred`를 `user`로 승급 금지.
- 한국어 해석은 표현이지 요구사항 승격 근거가 아님(원문 키워드 우선).
