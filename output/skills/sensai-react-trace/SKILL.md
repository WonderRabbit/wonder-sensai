---
name: sensai-react-trace
description: React(식별된 스택)의 JSX/TSX 구조·handler·상태·literal API 호출을 추적하는 가속기. A1이 React를 식별했을 때만 로드된다(스택 미가정 원칙).
---

# 목표

React 코드의 구조를 추적해 근거 후보를 수집한다(01 A2 가속기). 컴포넌트·라우트·상태·API 호출을 `path:line`과 함께 모은다. **후보는 사실이 아니다** — `sensai-evidence-first`로 재확인 후 확정.

## 대상

- 컴포넌트(PascalCase), `<Route>`, `createBrowserRouter`/`useRoutes`.
- `useState`/`useReducer`, `useEffect`.
- `axios`/`fetch` 호출, literal 경로(`/api/...`).

## 절차

1. `ast-grep --json` 또는 `rg --json`으로 React 패턴 후보 수집(`path:line`).
2. 컴포넌트→라우트→상태→API 호출 관계 추적.
3. 후보를 `evidence[]` 후보로 정리(확정은 lead가 도구로 재확인).

## 비고

A1이 React를 매니페스트 근거로 식별했을 때만 로드. 미식별 시 사용 금지(`UNSUPPORTED`).
