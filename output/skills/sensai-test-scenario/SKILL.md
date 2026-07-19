---
name: sensai-test-scenario
description: 사용자 스토리에서 GIVEN/WHEN/THEN 테스트 시나리오를 생성한다(05 3-5). TEST-ID + STORY-ID + DESIGN-ID. provenance(test) 역대조, 파이프라인 자동화 + per-run 수동 트리거.
---

# 목표

사용자 스토리(`STORY-*`)에서 테스트 시나리오(`TEST-*`)를 생성한다. 스토리 기반이며, 근거 없는 시나리오는 발명하지 않는다.

## 형식

- Markdown `GIVEN`/`WHEN`/`THEN`.
- `TEST-ID` + `STORY-ID` + `DESIGN-ID`.
- `kind: tobe`(05 TO-BE 산출).

## 절차

1. `jq`로 `stories[]`(05 산출) 읽기.
2. 각 스토리에서 검증 가능한 시나리오 도출(GIVEN 조건 / WHEN 행동 / THEN 기대).
3. `TEST-<NNNN>` ID 부여, 스토리/설계에 역대조.
4. `provenance.jq`(test 모드) 역대조.
5. 파이프라인 자동화 + per-run 수동 트리거 옵션.

## 근거 정책 (불변)

스토리 기반. 근거 없는 시나리오 금지. `UNKNOWN` 보존.
