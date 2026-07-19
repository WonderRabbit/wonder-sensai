---
name: sensai-mermaid-sequence
description: trace의 exact joins를 Mermaid sequenceDiagram으로 투영한다. %% REQ/MSG 주석 + [MSG][REQ] 라벨, 확정 호출만(03 §6 A-2 / 05 §6 3-2).
---

# 목표

`trace.json`의 확정 호출(`joins[]`, `status: exact`)을 Mermaid `sequenceDiagram`으로 투영한다. 근거 없는 화살표는 만들지 않는다.

## 형식

- `%% REQ`/`%% MSG` 주석 + 화살표 라벨 `[MSG][REQ]`.
- **확정 호출(exact joins)만**. 동적/모호한 호출은 제외 또는 `UNKNOWN`.
- 한도: ≤20req / ≤12participant / ≤50msg.
- `kind`: AS-IS면 `asis`, TO-BE면 `tobe`.

## 절차

1. `jq -c '.joins[] | select(.status=="exact")' "$TRACE_FILE"`로 확정 조인 읽기.
2. 시퀀스 다이어그램으로 투영 — 참여자·메시지·요청.
3. 각 화살표에 `MSG-ID`/`REQ-ID`/`evidence` 대조.
4. `provenance.jq`(mermaid 모드)로 역대조, `mmdc` 렌더(exit 0 + SVG).

## 근거 정책 (불변)

exact joins만. 이름 유사도로 화살표 채우지 않음. 근거 없으면 `UNKNOWN`.
