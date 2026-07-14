# 제품 방향과 Go 도입 게이트

## 문제, 고쳐야 하는 이유, 최선과 차선

### 무엇이 문제인가

React 화면, Vert.x route·event-bus, OpenAPI, IETF RFC 스타일 명세는 서로 다른 문법과 식별자를 사용한다. 작은 모델이 이들을 한 번에 읽으면 동적 URL을 literal로 오인하거나, 중복 route 중 하나를 임의 선택하거나, 요구사항과 구현 사이에 존재하지 않는 연결을 만들기 쉽다. 산출물이 자연스러운 한국어라는 이유만으로 사실성이 보장되지 않는다.

### 왜 고쳐야 하는가

UI 정의서와 시퀀스 다이어그램은 설계·변경·검토의 입력이 된다. 근거 없는 edge 하나가 잘못된 API 수정, 누락된 권한 검사, 존재하지 않는 RFC 요구사항으로 전파될 수 있다. 따라서 모델의 자신감이 아니라 재실행 가능한 도구 결과, exact join, schema와 경로·줄 근거가 사실 판정자여야 한다.

### 최선

P0의 최선은 OpenCode의 두 agent 역할 분리와 기존 CLI의 structured output을 얇은 POSIX shell로 조합하는 것이다. `trace.json`을 canonical truth로 두고, 확인되지 않은 값은 `UNKNOWN`, `unresolved`, `ambiguous`, `many_to_many`, `conflict`로 보존한다. 한국어 Markdown과 Mermaid SVG는 그 원장에서 다시 검증 가능한 표현물이다. 설치 payload에는 정규 trace 전체를 검사하는 `recipes/trace.jq`와 UI·Mermaid 근거를 trace에 역대조하는 `recipes/provenance.jq`를 포함한다. OpenCode의 permission과 skill loading은 [공식 Agents](https://opencode.ai/docs/agents/)와 [Agent Skills](https://opencode.ai/docs/skills/) 계약을 사용한다.

### 차선

필수 tool 또는 live model admission이 실패하면 범위를 더 작게 나누고 사람이 근거 ledger와 미확인 목록을 검토한다. direct CLI가 표현하지 못한 의미를 임시 정규식이나 모델 추측으로 채우지 않는다. 반복 가능한 `jq`·`yq` filter와 ast-grep rule을 먼저 추가하고, 같은 실패가 정량 게이트를 넘을 때만 작은 Go binary를 검토한다.

## P0: Go 없음

P0 Go 애플리케이션은 없다. Go toolchain도 설치·실행 조건이 아니다. 현재 대표 범위는 다음 upstream CLI가 직접 제공하는 기능으로 처리된다.

| 단계 | 직접 사용하는 기능 | P0 판정 근거 |
| --- | --- | --- |
| 파일 발견 | [`fd --print0`](https://github.com/sharkdp/fd) | 안전한 파일명 경계와 확장자별 범위 열거 |
| 텍스트 후보 | [`rg --json`](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md) | 경로·줄·byte 범위를 JSONL로 수집 |
| 구조 후보 | [`ast-grep --json`](https://ast-grep.github.io/reference/cli.html) | JSX/TSX/Java AST를 언어별로 탐색 |
| OpenAPI 변환 | [Mike Farah `yq`](https://mikefarah.gitbook.io/yq/usage/output-format) | YAML을 명시적인 JSON으로 변환 |
| trace join·검증 | [`jq`](https://jqlang.org/manual/)와 `recipes/trace.jq` | 필드·근거·ID 참조와 exact endpoint 양쪽의 직접 근거를 전체 trace에서 판정 |
| 산출물 provenance | `recipes/provenance.jq` | UI의 evidence·source, requirement·join ID와 Mermaid의 MSG·REQ·evidence·source를 canonical trace에 역대조 |
| 한국어 Markdown QA | [yshavit `mdq`](https://github.com/yshavit/mdq) | 필수 section과 table을 구조적으로 질의 |
| Mermaid QA | [`mmdc`](https://github.com/mermaid-js/mermaid-cli) | 실제 parser와 headless browser로 SVG 생성 |

대표 fixture는 React, Vert.x, OpenAPI, specification, `trace.json`, 한국어 UI 정의서, Mermaid 원본의 7개 파일이다. happy case에서는 두 설치 대상 validator로 exact HTTP join과 산출물 provenance를 교차 확인한다. adversarial case에서는 dynamic URL, duplicate route, dangling reference, requirement conflict, empty·malformed input, 근거가 어긋난 UI·Mermaid와 invalid Mermaid가 성공으로 위장되지 않는지 확인한다. 이는 `./tests/test.sh happy`, `adversarial`, `regression`으로 재현한다.

P0에서 앱을 만들지 않는 이유는 단순히 코드량을 줄이기 위해서가 아니다. 각 CLI의 no-match와 error exit 의미가 다르고 structured output 형식도 JSON, JSONL, YAML, Markdown, SVG로 다르다. 얇은 recipe와 독립 validator는 이 차이를 드러내지만, 범용 wrapper 앱은 이를 하나의 불투명한 성공·실패로 숨길 가능성이 크다.

## build-vs-script 경계

기본 선택은 script다. 다음 조건이면 POSIX shell, 고정된 ast-grep rule, `jq`·`yq` filter를 유지한다.

- 한 번에 한 writer만 있고 임시 파일 뒤 atomic rename으로 충분하다.
- 입력 크기가 대표 fixture와 실제 저장소에서 정해진 시간·메모리 예산 안에 든다.
- join이 exact literal 또는 명시적 ID이고, 변환이 stream·sort·group으로 표현된다.
- 실패를 기존 CLI exit와 stderr, schema validator로 정확히 구분할 수 있다.
- upstream CLI가 이미 parser, renderer 또는 provider protocol을 소유한다.

Go는 다음 두 경우에만 후보가 된다. 입학 조건은 “있으면 편리함”이 아니라 기존 script의 정확성 또는 운영 한계를 실패 fixture와 측정값으로 증명하는 것이다. 모든 정량 조건을 충족하기 전에는 구현하지 않는다.

## P1 후보: `sensai-trace`

### 문제와 이유

`sensai-trace`는 단순 검색 wrapper가 아니라 typed cross-file graph를 결정적으로 추출·검증하는 후보다. receiver/type binding, cross-file constant propagation, recursive 또는 cyclic subrouter, 중복 route의 many-to-many 관계가 direct `ast-grep`·`jq` 조합으로 정확히 표현되지 않을 때만 필요하다.

### 제안 interface

```text
sensai-trace extract --root ROOT --scope SCOPE --rules RULE_DIR --output trace.json
sensai-trace validate --schema schemas/trace.schema.json trace.json
sensai-trace explain --id ID trace.json
```

입력은 repository root, 명시적인 scope, versioned rule directory, React·Vert.x·OpenAPI·specification source다. environment secret, network, LLM 응답을 입력으로 사용하지 않는다. 출력은 schema version, source-derived evidence ID, canonical entity ID, one-based span, exact join, ambiguity·unknown과 tool/rule version을 포함한 canonical JSON이다. 진단은 JSONL로 stderr에 내보내고 partial output을 성공으로 남기지 않는다.

### 입학 조건

다음 조건을 모두 만족해야 P1 구현을 승인한다.

1. receiver/type binding, constant propagation, cyclic subrouter 또는 many-to-many 중 하나 이상 때문에 현재 pipeline이 틀린 edge를 만들거나 필요한 ambiguity를 잃는 adversarial fixture가 최소 2개 있다.
2. 같은 실패가 이름 유사도나 수동 allowlist 없이 재현되고, expected trace가 독립 검토를 통과한다.
3. 대표 workload가 `10,000`개 이상의 node 또는 `50,000`개 이상의 edge를 포함한다.
4. 그 workload에서 기존 direct CLI pipeline의 wall time이 `2s`를 초과하거나 peak RSS가 `512MiB`를 초과한다. 동일한 cold/warm 조건에서 최소 10회 측정하고 원시 결과를 보존한다.
5. 추가 ast-grep rule과 `jq` filter로 정확성과 예산을 동시에 회복할 수 없다는 비교 결과가 있다.

### acceptance criteria

- 두 개 이상의 admission fixture와 기존 happy·adversarial fixture에서 expected node, edge, ambiguity, unknown이 정확히 일치한다.
- 같은 입력·rule version의 출력은 반복 실행 시 byte-identical하다. locale, absolute path, 실행 순서가 ID를 바꾸지 않는다.
- 모든 edge의 양쪽 endpoint와 source span이 존재하고 schema·reference validation이 통과한다. fuzzy join은 없다.
- `10,000` node 또는 `50,000` edge fixture에서 10회 실행의 p95가 `2s` 이하이고 peak RSS가 `512MiB` 이하이거나, 기존 pipeline 대비 두 지표 모두 측정 가능한 개선을 보인다. 기준을 못 맞추면 P1을 채택하지 않는다.
- malformed input, cycle, duplicate, empty scope에서 panic이나 partial canonical output 없이 정의된 nonzero exit를 반환한다.
- 임시 파일과 atomic rename을 사용하고, kill/crash 뒤 기존 valid output의 hash가 변하지 않는다.
- Go binary 없이도 검사 가능한 golden JSON과 shell conformance test를 유지한다.

P1의 차선은 domain별 ast-grep rule을 분리하고 `jq --stream` 또는 정렬된 JSONL로 memory 사용을 낮추는 것이다. 차선이 gate를 회복하면 Go 구현은 취소한다.

## P2 후보: `sensai-ledger`

### 문제와 이유

P0 evidence 기록은 단일 writer가 임시 JSONL을 만든 뒤 rename하는 방식이면 충분하다. `sensai-ledger`는 두 개 이상의 process가 동시에 증거를 append하고, 중간 crash 뒤에도 acknowledged event의 순서·중복·손실을 판정해야 할 때만 필요한 durability 후보다. agent 수가 늘었다는 이유만으로 도입하지 않는다.

### 제안 interface

```text
sensai-ledger append --ledger ledger.jsonl --run-id RUN_ID --event event.json
sensai-ledger verify --ledger ledger.jsonl
sensai-ledger inspect --ledger ledger.jsonl --run-id RUN_ID --output json
```

입력 event는 schema version, run ID, actor, event type, artifact ID, managed artifact hash, timestamp와 payload를 갖는 canonical JSON이다. `append`는 lock 안에서 sequence, previous digest, event digest를 부여하고 성공한 receipt를 stdout JSON으로 반환한다. `verify`와 `inspect`는 읽기 전용이며 chain break, duplicate sequence, truncated tail, unknown schema를 JSON 진단으로 보고한다. secret, 모델 원문 chain-of-thought, unmanaged 파일 내용은 기록하지 않는다.

### 입학 조건

다음 조건을 모두 만족해야 P2 구현을 승인한다.

1. 독립 process writer가 최소 2개이고, single-writer temp-file + `jq` 방식에서 acknowledged event의 손실·중복 또는 ledger corruption이 실제로 재현된다.
2. append의 각 write·flush·rename 경계에 대한 crash injection fixture가 있고 같은 failure가 반복된다.
3. 한 run 또는 보존 구간에 최소 `100,000` events가 있으며 단일 writer serialization이 운영 요구를 충족하지 못한다.
4. OS lock과 기존 SQLite 같은 검증된 저장소를 직접 사용하는 차선이 요구사항을 충족하지 못한다는 build-vs-buy 기록이 있다.

### acceptance criteria

- 2개 이상의 concurrent writer가 합계 `100,000` events를 기록해도 성공 receipt가 있는 event는 정확히 한 번 존재하고 sequence와 digest chain이 유효하다.
- write 경계별 crash injection 후 재시작하면 모든 acknowledged event가 보존되고, truncated 또는 unacknowledged tail은 명시적으로 검출된다. 자동으로 조용히 삭제하지 않는다.
- duplicate, reorder, byte mutation, unknown schema를 `verify`가 nonzero로 검출하고 최초 손상 sequence를 보고한다.
- append 중 reader는 마지막으로 확인된 valid boundary까지만 보며 partial JSON을 성공 event로 읽지 않는다.
- 동일 event와 predecessor는 동일 digest를 만들고, receipt만으로 ledger inclusion을 다시 확인할 수 있다.
- `100,000` events stress test, race detector, filesystem-full과 permission-denied fixture가 통과한다. 성능 수치와 filesystem 조건을 evidence artifact로 보존한다.

P2의 차선은 writer를 하나로 직렬화하고 기존 원자적 temp+rename을 유지하는 것이다. 검증된 표준 저장소가 요구사항을 충족하면 custom ledger format을 만들지 않는다.

## 기각한 애플리케이션

| 후보 | 판정 | 이유와 대안 |
| --- | --- | --- |
| Go installer·doctor | 기각 | manifest copy, identity smoke, same-filesystem rename과 absent-target gate는 POSIX shell로 충분하다. |
| 범용 CLI wrapper | 기각 | tool별 no-match·error와 structured format 차이를 숨긴다. 명시적 recipe와 validator를 유지한다. |
| Mermaid renderer | 기각 | 공식 [`mmdc`](https://github.com/mermaid-js/mermaid-cli)가 parser와 SVG 렌더를 소유한다. |
| model proxy·router | 기각 | OpenCode의 [OpenAI-compatible provider](https://opencode.ai/docs/providers/#openai-compatible)와 exact served alias admission을 사용한다. |
| scheduler·state machine·loop guard | 기각 | OpenCode session, task, 범위·중단 조건을 사용한다. 측정 없는 numeric `steps` cap은 완료를 보장하지 않는다. |
| graph database | P0 기각 | 대표 cross-stack trace는 canonical JSON과 exact `jq` join으로 충분하다. P1 admission 뒤에도 먼저 in-memory deterministic graph를 검토한다. |
| 별도 web UI·API server | 기각 | 제품 산출물은 한국어 Markdown, JSON, Mermaid/SVG이고 OpenCode가 실행 표면이다. |
| tokenizer·context estimator | 기각 | 파일·근거 단위 scope와 explicit blocked 상태로 boundedness를 유지한다. 실제 context failure 측정 없이 앱을 만들지 않는다. |
| TypeScript runtime | 기각 | loader와 workflow가 Markdown, JSON, shell, upstream CLI로 완결된다. 새 package runtime은 검증 면적만 늘린다. |

## 단계별 의사결정

P0는 direct CLI와 외부 validator를 유지한다. P1은 정확성 실패 2건과 `10,000` node 또는 `50,000` edge, 그리고 `2s` 또는 `512MiB` 초과가 모두 증명된 뒤에만 `sensai-trace`를 검토한다. P2는 2개 이상의 writer, crash injection, `100,000` events에서 단일 writer 방식의 durability 실패가 증명된 뒤에만 `sensai-ledger`를 검토한다.

P1과 P2는 roadmap이지 현재 구현이나 완료 약속이 아니다. 실제 Go 코드는 지금 만들지 않으며, gate를 통과하지 못하면 차선인 script·rule·기존 저장소를 계속 사용한다. 실제 전역 설치와 live Qwen 동작도 별도의 admission proof와 사용자 승인이 있기 전에는 제품 완료 근거로 사용하지 않는다.
