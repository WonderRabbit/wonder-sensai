---
name: sensai-react-trace
description: 레거시 React의 경로, 화면, 입력, 상태, 동작, HTTP 호출을 JS·JSX·TS·TSX 파서별로 추적한다. React 화면에서 Vert.x HTTP 경계까지 path:line 근거가 있는 후보와 미확인 연결을 만들 때 사용한다.
---

# 목표

`경로 -> 화면 -> 동작 -> 상태 -> HTTP 호출`을 소스 근거로 추적한다. AST 일치는 후보이며 import·정의·리터럴 해소가 끝나기 전에는 의미 연결로 확정하지 않는다.

## 전제 조건

- 입력은 React 소스 루트와 선택적 YAML 설정 파일이다.
- 생성물·번들·외부 의존성·테스트는 별도 partition으로 분리한다.
- 한 partition은 파일 50개 이하이며 `fd`, `rg`, `ast-grep`, `yq`, `jq`를 사용할 수 있어야 한다.

## 상태 기계

1. 네 입력 lane을 따로 만든다.
   - JS: `fd --type f --extension js --print0 . <루트>`
   - JSX: `fd --type f --extension jsx --print0 . <루트>`
   - TS: `fd --type f --extension ts --print0 . <루트>`
   - TSX: `fd --type f --extension tsx --print0 . <루트>`
2. `rg --no-config --json --sort path --line-number --glob '*.{js,jsx,ts,tsx}' -e '<Route' -e 'createBrowserRouter|useRoutes' -e '\bfetch\s*\(' -e '\baxios\.(get|post|put|patch|delete|request)\s*\(' -e 'useState|useReducer|setState|connect\(' <partition>`으로 후보와 1기준 행을 수집한다.
3. 파서를 섞지 않고 구문을 확인한다.
   - JS: `ast-grep run --lang javascript --pattern 'fetch($$$ARGS)' --json=compact <파일.js>`
   - JSX: `ast-grep run --lang javascript --pattern '<Route $$$ATTRS />' --json=compact <파일.jsx>`
   - TS: `ast-grep run --lang typescript --pattern 'React.useReducer($REDUCER, $INIT)' --json=compact <파일.ts>`
   - TSX: `ast-grep run --lang tsx --pattern '<Route $$$ATTRS />' --json=compact <파일.tsx>`
4. 각 일치의 import 또는 같은 범위 정의를 확인한다. 로컬 `Route`, `fetch`, 래퍼 클라이언트처럼 출처가 불명확하면 `UNKNOWN`으로 둔다.
5. 리터럴과 직접 상수 연결만 제한적으로 해소한다. 문자열 결합, 템플릿 변수, spread, 조건부 경로는 원식 `expr`을 보존하고 `literal/normalized`를 `null`로 둔다.
6. YAML 경로·권한 설정이 실제로 참조될 때만 `yq eval -o=json -I=0 '.' <설정.yaml>`로 후보를 읽는다. UI 권한은 `ui_only`이며 서버 권한을 증명하지 않는다.
7. `frontends[]`에 `id, component, route, api_calls, evidence_ids, status`를 기록한다. 호출은 `method, path, evidence_ids, status`를 사용하며 모든 사실은 정확한 `path:line`을 가진다.
8. `TRACE_FILE`을 대상 JSON 경로로 설정하고 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 전체 trace를 검증한다. 후보가 여러 경로나 API에 대응하면 하나를 고르지 않고 `AMBIGUOUS`로 보존한다.

## 확인 범위

- 경로: JSX `Route`, 중첩 경로, route object, `createBrowserRouter`, `useRoutes`, 파일 기반 경로 후보
- 화면: 함수·클래스 컴포넌트와 직접 연결된 render 대상
- 입력·상태: native form, controlled/uncontrolled 값, `useState`, `useReducer`, `this.state`, `setState`
- 동작·호출: submit/click handler, `fetch`, Axios 메서드, 확인된 사용자 클라이언트 래퍼

## 실패 폐쇄

- ast-grep stderr 경고, 잘못된 언어 lane, 출력 한도 초과, 정의 추적 실패는 빈 성공이 아니다.
- 같은 파일에 가까이 있다는 이유로 경로와 화면 또는 동작과 호출을 연결하지 않는다.
- HTTP 메서드나 경로를 추론하지 않는다. 직접 값이 없으면 `UNKNOWN`, 복수 후보면 `AMBIGUOUS`다.
