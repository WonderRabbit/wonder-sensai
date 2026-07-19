---
name: sensai-vertx-trace
description: Vert.x(식별된 스택)의 Router·handler·event-bus·비동기 경계를 추적하는 가속기. A1이 Vert.x를 식별했을 때만 로드된다(스택 미가정 원칙).
---

# 목표

Vert.x 코드의 구조를 추적해 근거 후보를 수집한다(01 A2 가속기). HTTP 라우트·handler·event-bus 메시지 흐름을 `path:line`과 함께 모은다. **후보는 사실이 아니다.**

## 대상

- `Router.router(...)`, `$ROUTER.<method>($PATH).handler(...)`.
- event-bus: `consumer`/`request`/`send`/`publish`.
- `vertx.eventBus()` 경유 호출.

## 절차

1. `ast-grep --json`으로 Vert.x 패턴 후보 수집(`path:line`).
2. Router→handler→event-bus 메시지 흐름 추적.
3. HTTP 메서드·경로·address·reply/failure 연결 확인.

## 비고

A1이 Vert.x를 매니페스트 근거로 식별했을 때만 로드. 미식별 시 사용 금지.
