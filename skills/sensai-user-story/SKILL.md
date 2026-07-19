---
name: sensai-user-story
description: 비즈니스 규칙/흐름과 화면을 한국어 사용자 스토리("<역할>은 <행동>을 할 수 있다. 이유: <가치>")로 투영한다(03 A-4 / 05 3-4). STORY-ID + REQ-ID + DESIGN-ID/BIZ-ID.
---

# 목표

비즈니스 사실과 화면을 사용자 스토리로 투영한다. 근거 없는 스토리는 발명하지 않는다.

## 형식

- 한글 "`<역할>`은 `<행동>`을 할 수 있다. 이유: `<가치>`."
- `STORY-ID` + `REQ-ID` + `DESIGN-ID`/`BIZ-ID`.
- `kind`: AS-IS면 `asis`(03), TO-BE면 `tobe`(05).

## 절차

1. `jq`로 `business_rules[]`/`business_flows[]` + `frontends[]` 읽기.
2. 역할·행동·가치를 도출해 스토리로 투영.
3. 각 스토리에 근거 ID 연결.
4. `provenance.jq`(story 모드) 역대조.

## 근거 정책 (불변)

`BIZ-ID`/`REQ-ID` 근거. 발명 금지. 근거 없으면 `UNKNOWN`.
