---
name: sensai-dataflow-chart
description: trace의 호출/이벤트와 비즈니스 흐름/상태를 Mermaid flowchart로 투영한다(03 A-3 / 05 3-3). %% DATA/%% BIZ-FLOW 주석, 엣지 [DATA][BIZ-FLOW], provenance(dataflow) 역대조.
---

# 목표

`trace.json`의 호출·이벤트(01) + 비즈니스 흐름/상태(02)를 Mermaid `flowchart`로 투영한다. 근거 없는 노드/엣지는 발명하지 않는다.

## 형식

- Mermaid `flowchart`.
- `%% DATA`/`%% BIZ-FLOW` 주석, 엣지 라벨 `[DATA]`/`[BIZ-FLOW]`.
- `kind`: AS-IS면 `asis`(03), TO-BE면 `tobe`(05).

## 절차

1. `jq`로 `joins[]`(호출) + `business_flows[]`/`business_states[]` 읽기.
2. 노드(엔티티/서비스/상태)·엣지(데이터 흐름) 투영.
3. 각 요소에 `DATA-ID`/`DESIGN-ID`/`BIZ-FLOW` 대조.
4. `provenance.jq`(dataflow 모드) 역대조, `mmdc` 렌더.

## 근거 정책 (불변)

`exact` 근거만. 근거 없으면 `UNKNOWN`. 발명·축약 금지.
