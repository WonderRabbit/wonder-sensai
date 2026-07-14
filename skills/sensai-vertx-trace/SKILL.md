---
name: sensai-vertx-trace
description: Vert.x Web HTTP 라우트, 핸들러, 이벤트 버스 request·send·publish·consumer와 OpenAPI operation을 추적한다. React HTTP 후보를 Vert.x 경계와 path:line 근거로 연결하거나 비동기 간극을 보존할 때 사용한다.
---

# 목표

`HTTP 라우트 -> 핸들러 -> 이벤트 버스 -> 응답`을 직접 근거로 기록하고 OpenAPI 선언을 별도 계층으로 교차 확인한다.

## 전제 조건

- 입력은 Java 소스 루트와 선택적 OpenAPI YAML/JSON이다.
- 한 partition은 Java 파일 100개, OpenAPI 파일 20개, 후보 200개 이하이다.
- `fd`, `rg`, `ast-grep`, `yq`, `jq`를 사용할 수 있어야 한다.

## 상태 기계

1. `fd --type f --extension java --print0 . <루트>`와 `fd --type f --extension yaml --extension yml --extension json --print0 . <루트>`로 코드와 계약 파일을 분리한다.
2. `rg --no-config --json --sort path --line-number --glob '*.java' -e 'Router\.router' -e '\.(get|post|put|patch|delete|route)\s*\(' -e '\.handler\s*\(' -e 'eventBus\(\)' -e '\.(consumer|request|send|publish)\s*\(' -e 'setStatusCode|response\(\)' <partition>`으로 후보를 만든다.
3. `ast-grep run --lang java --pattern '$ROUTER.get($PATH).handler($HANDLER)' --json=compact <파일.java>`와 `ast-grep run --lang java --pattern '$BUS.request($ADDRESS, $$$ARGS)' --json=compact <파일.java>`로 라우트와 이벤트 버스 구문을 직접 확인한다.
4. Router 변수의 정의, HTTP 메서드, 경로 표현식, handler 연결을 같은 심볼 체인에서 확인한다. `route()`만 있거나 동적 path이면 원식을 보존하고 `UNKNOWN`으로 둔다.
5. 이벤트 버스의 `consumer/request/send/publish`를 구분하고 address 표현식, payload, reply/failure handler, timeout 또는 응답 경로를 기록한다. address가 동적이거나 생산자·소비자가 복수면 `AMBIGUOUS`다.
6. OpenAPI는 `yq eval -o=json -I=0 '.paths | to_entries | map(.key as $p | .value | to_entries[] | {path:$p, method:(.key|upcase), operation_id:.value.operationId})' <openapi.yaml>`로 읽는다. 선언과 구현의 계층을 합치지 않고 각각 `path:line` 근거를 둔다.
7. `backends[]`에 `id, transport, method, path, operation_id, handler, event_bus_address, evidence_ids, status`를 기록한다. 구현과 OpenAPI가 충돌하면 `conflict`로 두고 임의 선택하지 않는다.
8. React 호출과 연결할 때 양쪽 상태가 `exact`이고 메서드와 정규 경로가 모두 같은 직접 후보만 `one_to_one/exact`로 둔다. 연결의 `evidence_ids`에는 React 호출과 Vert.x 라우트의 직접 근거가 모두 있어야 한다. 0개는 `UNKNOWN`, 2개 이상은 `many_to_many/AMBIGUOUS`다.
9. `TRACE_FILE`을 대상 JSON 경로로 설정하고 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 전체 trace를 검증해야 완료다.

## 실패 폐쇄

- HTTP 근거가 이벤트 버스 소비자를 증명하지 않으며 OpenAPI 선언이 구현을 증명하지 않는다.
- 콜백 성공 경로만 보고 오류·timeout을 발명하지 않는다. 근거가 없으면 `unknowns[]`에 다음 확인을 남긴다.
- 문자열에 등장한 address, 주석, 예제, 비실행 테스트는 실행 연결이 아니다.
