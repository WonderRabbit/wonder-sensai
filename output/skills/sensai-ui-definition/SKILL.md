---
name: sensai-ui-definition
description: canonical trace의 frontends/화면 사실을 한국어 UI 정의서(Mermaid 와이어프레임 중심 + Markdown 보조)로 투영한다. 각 요소에 E-ID@path:line + CONV/BIZ-ID 근거를 단다(03 §6 A-1).
---

# 목표

`trace.json`의 화면 사실(`frontends[]`)을 한국어 UI 정의서로 투영한다(03 §6 A-1 / 05 §6 3-1). 근거가 없는 요소는 발명하지 않고 `UNKNOWN`으로 보존한다.

## 형식

- 화면마다 **Mermaid 와이어프레임 중심** + Markdown 보조.
- 각 요소: `` `E-ID` @ `path:line` `` + `CONV-ID`/`BIZ-ID`(현재 화면·엔티티).
- `kind`: AS-IS 산출이면 `asis`(03), TO-BE면 `tobe`(05).

## 절차

1. `jq -c '.frontends[]' "$TRACE_FILE"`로 화면 사실을 읽는다.
2. 각 화면을 와이어프레임으로 투영 — 컴포넌트·라우트·상태·API 호출·표시 항목.
3. 각 요소에 근거 ID(`evidence_ids`)를 단다. 근거 없으면 `UNKNOWN`.
4. `provenance.jq`(ui 모드)로 역대조 검증.

## 근거 정책 (불변)

`path:line` 강제. 현재 코드에 없는 요소 발명 금지. 모순·모호성 보존.
