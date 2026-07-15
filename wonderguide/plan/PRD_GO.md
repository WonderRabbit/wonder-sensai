# Go 기능 및 Skill 연동 PRD

## 제품 목표와 범위

이 문서는 wonder-sensai가 Qwen3.6 35B-A3B와 Qwen3.5 9B 모델, 기존 CLI 도구로 React, Vert.x, OpenAPI, IETF RFC 기반 레거시 프로젝트를 분석할 때, 셸 조합만으로 정확성과 재현성을 확보하기 어려운 기능만 Go로 구현하기 위한 의사결정 계약이다.

현재 판정은 **P0 Go 실행 파일 0개**다. `rg`, `fd`, `sg`, `jq`, `yq`, `mdq`, `mmdc`와 기존 skill로 해결되는 문제는 Go로 다시 만들지 않는다. 후보는 아래 수치 게이트를 실제 fixture와 benchmark로 통과한 뒤에만 구현한다.

범위는 다음과 같다.

- React 라우트·컴포넌트·API 호출과 Vert.x 라우트·핸들러·서비스·OpenAPI 연결의 교차 파일 추적
- 근거의 안정 ID, 위치, 신선도, 충돌·모호성, 탐색 한계를 기계적으로 보존하는 계약
- 기존 OpenCode agent, command, skill에서 독립 CLI를 안전하게 호출하는 방식
- 반복 스캔 색인과 다중 작성자 ledger의 도입 조건
- 제품 범위가 확장될 경우의 MyBatis 추적 조건

다음은 범위 밖이다.

- 범용 코드 검색기, 언어 파서, LSP, 그래프 데이터베이스, 모델 게이트웨이
- 브라우저 캡처, Mermaid 렌더링, OpenAPI/RFC 원문 파싱의 재구현
- SAP RFC/JCo/BAPI 분석. 이 제품의 RFC는 IETF 명세를 뜻한다.
- 웹 UI, 서버, 플러그인 플랫폼, 동적 skill loader

## 현재 판정 요약

`docs/PROD.md`가 이 문서보다 상위 권위다. 현재 공식 Go 후보는 P1 `sensai-trace`와 P2 `sensai-ledger` 두 개뿐이다. `sensai-evidence-index`와 `sensai-mybatis-trace`는 **RESEARCH_ONLY**이며, 구현 후보로 승격하려면 같은 PR에서 `docs/PROD.md`의 범위와 수치 gate를 먼저 갱신하고 독립 승인을 받아야 한다.

| 우선순위 | 후보 | 현재 판정 | 구현 시점 |
|---|---|---|---|
| P0 | Go 실행 파일 | 없음 | 기존 CLI와 skill 계약 유지 |
| P1 | `sensai-trace` | 조건부 | 교차 파일 fixture에서 셸 조합의 정확도 또는 결정성이 기준 미달일 때 |
| 조사 | `sensai-evidence-index` | RESEARCH_ONLY | `docs/PROD.md` 갱신과 독립 승인 전 구현 금지 |
| P2 | `sensai-ledger` | 조건부 | 근거를 쓰는 주체가 2개 이상이고 단일 파일 갱신 충돌이 재현될 때 |
| 조사 | `sensai-mybatis-trace` | RESEARCH_ONLY | `docs/PROD.md` 갱신과 독립 승인 전 구현 금지 |

후보 하나가 게이트를 통과해도 나머지를 함께 만들지 않는다. 최초 구현 단위는 최대 하나의 Go module과 하나의 실행 파일이며, 공용 프레임워크를 선행하지 않는다.

## 구현 책임과 변경 단위

lead agent가 측정 결과와 도입 승인을 소유하고, peer agent는 승인된 trace와 receipt를 읽기만 한다. 후보 하나의 구현 PR은 해당 CLI, schema, fixture, 연결되는 기존 skill·command, manifest·permission 변경만 포함한다. 다른 후보나 범용 라이브러리는 같은 PR에 넣지 않는다.

## 의사결정 원칙

진실 우선순위는 `현재 추적된 소스와 설정 > 현재 실행 결과 > fixture > 계획 문서 > reference 자료`다. `reference/`와 형제 프로젝트는 설계 단서를 제공하지만 제품 계약의 독립 증거로 중복 계산하지 않는다.

Go는 다음 조건을 모두 만족할 때만 선택한다.

1. 문제가 셸 파이프라인의 표현력보다 **타입 있는 상태 전이, 그래프 결합, 원자적 갱신**을 요구한다.
2. 기존 도구를 고정 argv로 호출하고 그 결과를 정규화하는 방식이 언어 파서를 재구현하는 것보다 작다.
3. 동일 입력에서 byte-identical 출력, 명시적 실패, 이전 정상 산출물 보존을 자동 검증할 수 있다.
4. 구현하지 않을 때의 측정 가능한 실패와 구현 후 종료 조건이 있다.

## 공통 실행 계약

조건부 후보가 승인되면 모든 Go CLI는 다음 계약을 따른다.

- 입력 경로는 저장소 루트 기준 상대 경로로 정규화한다. 루트 밖 경로, 심볼릭 링크 탈출, 비밀 파일 패턴은 거부한다.
- 외부 도구는 shell string이 아니라 고정 argv로 실행한다. 사용자가 임의 플래그나 명령을 주입할 수 없다.
- stdout에는 성공 결과 또는 짧은 receipt만 출력하고, stderr에는 버전이 있는 JSONL 진단을 출력한다.
- 정상적인 no-match와 도구 실행 실패·파싱 실패를 다른 exit code로 구분한다.
- 출력은 임시 파일에 쓴 뒤 fsync와 atomic rename으로 교체한다. 실패 시 이전 정상 파일의 hash가 유지되어야 한다.
- 순서가 의미 없는 배열은 명시한 키로 정렬한다. derived trace에는 실행 시각·호스트명·절대 경로를 넣지 않는다.
- 경계가 있는 탐색은 `truncated`, `omitted`, `unresolved`, `ambiguous`, `conflict`를 누락 없이 기록한다.
- receipt에는 CLI version, schema version, 입력 content hash, 사용한 도구·rule version을 포함한다.

공통 exit code는 현재 `bin/` 계약을 따른다: `0=성공·정상 no-match·well-formed ambiguity/conflict`, `64=사용법·입력 계약 위반`, `65=malformed data·schema 위반·reference-integrity 실패`, `69=필수 외부 도구 사용 불가`, `73=출력 파일 생성 실패`, `75=lock·원자적 교체 등 일시 실패`다. 잘 형성된 `unresolved`, `ambiguous`, `conflict`는 canonical 결과에 보존하고 validate도 `0`을 반환한다.

## 공통 검증 기준

승인된 후보는 happy path뿐 아니라 no-match, malformed input, 외부 도구 실패, stale hash, 모호성·충돌, 탐색 한계, symlink 탈출, 쓰기 실패 fixture를 통과해야 한다. 동일 입력 20회 결과 hash, 실패 전후 기존 산출물 hash, 실행 시간과 RSS를 함께 기록한다. 측정값이 후보별 게이트에 못 미치면 기능을 축소하지 않고 Go 도입 자체를 철회한다.

## P1 후보: sensai-trace

### 해결할 문제와 비목표

React와 Vert.x의 실제 연결은 파일 하나의 정규식으로 끝나지 않는다. receiver type, 상수 경로, 중첩 router, 재수출, OpenAPI operation을 여러 파일에서 결합해야 하며, 하나의 endpoint가 여러 UI 호출이나 handler로 이어지는 many-to-many 관계도 보존해야 한다.

`sensai-trace`는 `rg`, `sg`, `yq`가 추출한 사실을 내부 typed graph로 결합한 뒤 기존 trace shape로 결정적으로 투영한다. 내부 node/edge는 계산용이며 직렬화하지 않는다. JavaScript/TypeScript/Java/YAML 파서를 새로 만들거나 LSP를 내장하지 않는다. Mermaid도 생성하지 않고, diagram skill이 trace를 읽어 `mmdc`에 넘기게 한다.

### 도입 게이트

아래를 모두 만족할 때만 P1 구현을 시작한다.

- receiver/type binding, constant propagation, cyclic subrouter 또는 many-to-many 중 하나 이상 때문에 현재 pipeline이 틀린 edge를 만들거나 필요한 ambiguity를 잃는 adversarial fixture가 최소 2개 재현된다.
- 같은 실패가 이름 유사도나 수동 allowlist 없이 재현되고, expected trace가 독립 검토를 통과한다.
- 측정 corpus가 trace node 10,000개 이상 또는 edge 50,000개 이상이다.
- 동일한 cold/warm 조건에서 기존 pipeline을 최소 10회 실행해 raw 결과를 보존하고, wall time p95가 2초를 초과하거나 최대 RSS가 512 MiB를 초과한다.
- `sg` rule 또는 `jq` projection을 추가해도 정확도 실패와 시간·메모리 예산을 동시에 회복할 수 없다는 비교 결과가 있다.

게이트가 충족되지 않으면 구현하지 않고 기존 skill과 `jq` projection을 유지한다.

### 알고리즘

1. `rg`, `sg`, `yq`를 고정 argv로 실행하거나 동일 schema의 추출 파일을 입력받는다.
2. 추출 fact를 내부 `source`, `symbol`, `route`, `call`, `spec-operation` node로 정규화한다.
3. `kind`, 저장소 상대 경로, 1-based start/end span, symbol 또는 안정 index로 stable ID를 계산한다. 내용 hash는 ID에서 분리해 `content_sha256` freshness 필드로 기록한다.
4. 상수 전파, import/re-export, receiver type, router prefix를 제한된 규칙으로 해석한다.
5. exact key만 자동 결합한다. 후보가 여럿이면 추측하지 않고 `ambiguous`, 없으면 `unresolved`, 상충하면 `conflict` edge를 만든다.
6. 시작점별 bounded BFS를 수행한다. 기본 깊이는 8, 노드 상한은 10,000이다. `max-edges`는 50,000이며 초과분을 receipt에 기록한다.
7. 내부 node는 `(kind, path, span, stable_id)`, 내부 edge는 `(from, relation, to)` 순서로 정렬한다.
8. 내부 graph를 기존 `evidence`, `requirements`, `frontends`, `backends`, `joins`, `unknowns`로 결정적 projection하고 trace 2.0 branch로 검증한 뒤 임시 파일과 atomic rename으로 쓴다.

### CLI와 입출력

최초 구현은 실행 파일 하나와 세 subcommand만 둔다.

```text
sensai-trace extract --root ROOT --scope SCOPE --rules RULE_DIR --output trace.json
sensai-trace validate --schema ${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/schemas/trace.schema.json trace.json
sensai-trace explain --id ID trace.json
```

`extract` 입력은 저장소와 versioned rule bundle이며, 출력은 additive trace 2.0 JSON과 stderr 진단이다. JSON Schema는 closed shape, field type, schema version만 검증한다. Go와 `recipes/trace.jq`는 global ID uniqueness, reference integrity, exact join semantics의 semantic verdict parity를 가져야 한다. 최종 CLI verdict는 schema 검증과 두 semantic 검증 결과의 논리곱이다. `recipes/provenance.jq`는 schema version이나 additional key를 판정하지 않고 UI·Mermaid의 source reference만 검증한다. `explain`은 canonical entity ID 또는 evidence ID를 조회해 source span, join 근거, freshness와 실패 상태를 보여 주되 원본 trace를 변경하지 않는다.

trace 2.0은 새 그래프 shape가 아니라 trace 1.0의 additive 최소 변경이다.

- trace 1.0의 `schema_version`, `run_id`, `scope`, `evidence`, `requirements`, `frontends`, `backends`, `joins`, `unknowns`를 그대로 보존한다.
- 각 `evidence`에 1-based `span`, `content_sha256`, `freshness`, `extractor_version`, `extractor_mode`를 추가한다.
- 최상위에는 `completeness`와 `producer`만 추가한다.
- `completeness`가 bounded traversal의 `max_depth`, `max_nodes`, `truncated`, `omitted_count`를 기록한다.
- 같은 `completeness`에 `max_edges`도 기록한다.

### 실패, fallback, 철회

정상 source의 cyclic subrouter는 bounded traversal 결과로, duplicate route는 `many_to_many`로 보존하고 `0`을 반환한다. 반면 malformed input, duplicate canonical ID, dangling/broken reference, bound 안에서 안전하게 종료할 수 없는 malformed graph는 `65`를 반환하고 이전 trace를 유지한다. empty scope는 입력 계약 위반으로 nonzero, 외부 도구 실패는 `69`다. Go binary 없이도 실행 가능한 golden JSON과 shell conformance test를 유지한다.

채택 기준은 모든 fixture의 expected edge·ambiguity·conflict 판정, 동일 입력의 byte-identical 출력, 양단 1-based start/end span, JSON Schema의 구조 검증 통과, Go와 `recipes/trace.jq`의 semantic verdict parity, 세 결과의 논리곱인 최종 CLI 성공, p95 2초 이하와 RSS 512 MiB 이하 또는 기존 대비 두 지표 모두 개선, crash 지점별 이전 정상 산출물 보존을 모두 만족하는 것이다.

회귀가 발견되면 skill은 즉시 기존 `rg`/`sg`/`jq` 절차로 fallback한다. 위 채택 기준이 깨지거나 false join이 재발하면 CLI를 기본 경로에서 제거하고 실험 상태로 되돌린다.

### Skill, command, agent 연동

- `sensai-react-trace`: 선택된 경우 bounded React scope, rule, fact 후보만 만든다. extractor를 호출하지 않는다.
- `sensai-vertx-trace`: 선택된 경우 bounded Vert.x scope, rule, fact 후보만 만든다. extractor를 호출하지 않는다.
- `sensai-spec-evidence`: 선택된 경우 OpenAPI와 IETF RFC의 bounded scope, rule, fact 후보만 만든다. extractor를 호출하지 않는다.
- `sensai-evidence-first`: 정책·routing skill이다. lead는 필요한 domain 후보를 합친 scope에 `sensai-trace extract`를 정확히 한 번 호출한다. JSON Schema의 shape·type·version 결과와 Go·`recipes/trace.jq`의 ID·reference·exact-join semantic parity를 확인하고, 그 논리곱만 최종 성공으로 인정한다. 별도 `merge` subcommand는 만들지 않는다.
- `sensai-ui-definition`: 검증된 trace를 UI 정의서의 화면·행위·API 근거로 투영한다.
- `sensai-mermaid-sequence`: 검증된 trace만 읽어 Mermaid source를 만들고 `mmdc`로 렌더링한다.
- `/sensai/analyze`: lead가 요청 범위에 필요한 domain skill만 선택한 뒤 합친 scope로 `sensai-trace extract`를 한 번 호출하고 receipt를 사용자에게 보여 준다.
- `/sensai/verify`: `validate`와 source hash 재검사를 실행한다.
- `/sensai/design`: extractor를 다시 호출하지 않고 검증된 trace만 UI 정의서와 sequence diagram으로 투영한다.
- lead agent만 합친 scope로 CLI를 호출한다. peer agent는 같은 `sensai-evidence-first`의 read-only evidence·validation 절차만 사용하고 CLI를 호출하거나 trace·ledger에 쓰지 않는다.

새 `sensai-trace` skill은 만들지 않는다. 기능이 기존 도메인 skill에 속하므로 skill 수를 늘리지 않고 기존 skill의 단계만 교체한다.

## 조사 전용: sensai-evidence-index

### 문제와 도입 게이트

반복 질의의 전체 재스캔과 stale 구분 비용을 줄이는 아이디어지만 현재 100,000 evidence workload, 조회 병목, stale 오판 증거가 없어 **RESEARCH_ONLY**다. 구현·CLI·schema·topology는 확정하지 않는다.

승격에는 100,000 evidence, 동일 cold/warm lookup 10회의 `jq` p95 2초 초과 또는 RSS 512 MiB 초과, rename·delete·content-change stale fixture 각 1개, SQLite build-vs-buy 실패가 모두 필요하다. prototype은 trace 2.0 또는 동등 source-reference contract를 전제로 warm p95 500ms 이하, `jq` 대비 4배 개선, stale 오판 0건을 만족해야 한다. 미달이면 canonical trace 직접 조회로 기각한다.

승격 시 연동 후보(확정 아님)는 `sensai-evidence-first`다. 구현 후보가 되기 전에 같은 PR에서 `docs/PROD.md` 범위·gate를 갱신하고 독립 승인을 받아야 한다.

## P2 후보: sensai-ledger

### 문제와 도입 게이트

현재는 lead agent 한 명만 산출물을 쓰고 peer는 read-only이므로 ledger가 필요 없다. 다음을 모두 만족할 때만 다중 작성자 append 계약을 구현한다.

- 독립 writer가 2개 이상으로 승인된다.
- 현재 파일 갱신 방식에서 유실·중복·손상이 재현된다.
- write, fsync, rename 경계마다 crash fixture가 있다.
- 100,000개 이상 event의 보존과 복구가 실제 요구 사항이다.
- OS file lock 또는 SQLite를 직접 사용해도 요구를 충족하지 못한다는 build-vs-buy 근거가 있다. 둘 중 하나가 충족하면 custom `sensai-ledger`는 기각하고 그 표준 대안을 직접 사용한다.

### 알고리즘, CLI, 입출력

OS file lock과 SQLite를 같은 fixture로 먼저 비교하며, 둘 다 실패한 증거가 있을 때만 custom Go 구현을 승인한다. custom event는 `schema_version`, `run_id`, `actor`, `event_type`, `artifact_id`, `managed_artifact_hash`, `timestamp`, `payload`를 가진 canonical JSON이다. append는 lock 안에서 `sequence`, `previous_digest`, `event_digest`를 부여하고 성공 receipt를 stdout JSON으로 반환한다. recovery는 마지막 유효 checksum 이후의 불완전 tail을 명시적으로 격리한다. 임의 event 수정이나 분산 합의는 지원하지 않는다.

ledger의 `timestamp`는 caller가 제공하고 정규화한 event field로 digest에 포함한다. implicit current time과 receipt 생성 시각은 canonical event에서 제외한다.

```text
sensai-ledger append --ledger ledger.jsonl --run-id RUN_ID --event event.json
sensai-ledger verify --ledger ledger.jsonl
sensai-ledger inspect --ledger ledger.jsonl --run-id RUN_ID --output json
```

입력 event는 versioned JSON schema를 통과해야 한다. `verify`와 `inspect`는 read-only이며 chain break, duplicate sequence, truncated tail, unknown schema를 보고한다. lock timeout, sequence 충돌, checksum 오류는 실패하고 기존 유효 prefix를 보존한다. 실패 시 단일 writer lead 방식으로 fallback한다.

### 연동과 채택 판정

도입 시에만 `sensai-ledger` skill을 추가하고, lead agent가 writer 허용 목록을 소유한다. `/sensai/analyze`는 완료 receipt를 append하고 `/sensai/verify`는 chain을 검사한다. acceptance는 다음을 모두 요구한다: receipt가 승인한 event의 exactly-once 존재, receipt의 `sequence`와 `event_digest`만으로 ledger inclusion 재확인, write·flush·rename crash 경계 뒤 acknowledged event 보존, mutation·reorder·unknown schema의 nonzero 검출, reader가 마지막 valid boundary까지만 읽기, 동일 event와 predecessor의 deterministic digest, 합계 100,000 event concurrent test, race detector, filesystem-full과 permission-denied fixture 통과. 두 명 이상의 writer가 실제 운영되지 않거나 기준을 충족하지 못하면 custom ledger를 제거하고 표준 대안 또는 단일 writer로 돌아간다.

## 조사 전용: sensai-mybatis-trace

### 문제와 도입 게이트

MyBatis mapper와 Java 호출 연결은 현재 제품 범위도, 20 files/100 statements corpus도 없어 **RESEARCH_ONLY**다. 구현·CLI·schema·topology는 확정하지 않으며 SAP JCo/BAPI 의미를 추측해 만들지 않는다.

승격에는 정식 범위 승인, 20 files/100 statements, 기존 `rg`/XML의 false join 또는 recall 95% 미만 증거가 필요하다. prototype은 precision 100%, recall 95%, byte-identical 출력, bounded cycle, p95 2초 이하, RSS 512 MiB 이하를 모두 만족해야 한다. 미달·회귀 시 기각하고 `rg`/XML query로 돌아간다.

승격 시 연동 후보(확정 아님)는 조건부 `sensai-mybatis-trace` skill과 `/sensai/analyze` opt-in이다. 구현 후보가 되기 전에 같은 PR에서 `docs/PROD.md` 범위·gate를 갱신하고 독립 승인을 받아야 한다.

## Go로 구현하지 않는 기능

| 기능 | 기각 이유 | 대체 수단 |
|---|---|---|
| evidence pack 생성기 | bounded projection으로 충분함 | `jq` recipe |
| 범용 toolbox/semantic wrapper | 책임과 실패 경계가 불명확함 | 각 도메인 skill |
| scheduler, loop guard, 상태 머신 | 현재 2-agent topology에 불필요함 | lead agent 절차 |
| 모델 proxy, gateway, router | OpenCode provider 책임을 중복함 | OpenCode 설정 |
| 브라우저/UI 캡처 | Go가 소유할 문제가 아님 | Playwright |
| Mermaid 렌더러 | 검증된 도구 재구현임 | `mmdc` |
| OpenAPI/RFC parser | `yq`와 원문 도구로 충분함 | `yq`, `rg`, RFC source |
| installer/doctor | 현재 payload가 작고 정적임 | manifest 검증 command |
| tokenizer/context estimator | 모델별 추정 오차가 큼 | bounded input 계약 |
| graph DB | 현재 규모와 질의가 이를 요구하지 않음 | canonical JSON, 조건부 SQLite |
| LSP daemon | cold-start 문제가 측정되지 않음 | 필요 시 기존 LSP 호출 |
| 동적 skill loader | OpenCode native skill discovery와 중복됨 | `SKILL.md` |

## OpenCode 통합 계약

Go 실행 파일은 PATH에 설치하는 독립 CLI다. OpenCode global skill은 `~/.config/opencode/skills/<name>/SKILL.md`에서 이를 bash로 호출한다. 이 제품은 global 설치만 대상으로 하며 프로젝트별 override를 배포하지 않는다.

OpenCode custom tool의 typed 경로는 JavaScript/TypeScript와 Zod wrapper이며, MCP도 typed integration 경로다. 전자는 no-TypeScript 기준 때문에 재승인이 필요하고, 후자는 server·context 비용과 다중 client 요구 부재 때문에 defer한다. 현재 기본 통합은 `SKILL.md -> 허용된 bash pattern -> Go CLI`다.

permission은 default deny를 유지하고 실행 파일별 subcommand prefix만 허용한다. OpenCode pattern은 실행 승인 경계일 뿐 fixed argv나 OS sandbox가 아니다. Go CLI가 root·symlink 경계를 검증하고 upstream `rg`·`sg`·`yq`를 fixed argv로 호출해야 한다. permission은 last-match-wins이므로 넓은 allow를 먼저, 구체적인 민감 deny를 나중에 두며 민감 deny 뒤에 넓은 allow를 두지 않는다. 예시는 `sensai-trace extract *`, `sensai-trace validate *`, `sensai-trace explain *`이며 최종 순서를 fixture로 검증한다.

trace 1.0은 closed schema이므로 in-place 필드 추가를 금지한다. P1 승격 PR 하나에서 `docs/PROD.md`, schema, recipes, consumers, writer를 함께 변경하되 다음 순서를 지킨다.

현행 exact-key `recipes/trace.jq`가 additive 2.0을 거부하는 것은 정상이다. `recipes/provenance.jq`는 schema version이나 additional key를 판정하지 않으므로 schema validator처럼 취급하지 않는다.

1. 기존 `schemas/trace.schema.json` 안에 `schema_version` dispatch(`oneOf` 등)로 closed 1.0 branch와 closed 2.0 branch를 두고 fixture를 추가한다. 별도 schema 파일을 만들지 않는다.
2. `recipes/trace.jq`만 1.0/2.0 version dispatch로 변경한다. `recipes/provenance.jq`는 두 버전 golden parity로 동작을 확인하고 실제 source-reference 차이 때문에 변경이 필요할 때만 수정한다.
3. 기존 skill과 command consumer를 dual-read로 변경한다.
4. Go CLI shadow writer는 정확히 `schema_version: 2.0`인 output만 single-write하고 기존 1.0 기본 경로와 비교한다.
5. shadow acceptance 뒤 2.0을 기본으로 전환한다. 현재 14-leaf payload에는 없는 `schemas/trace.schema.json`을 managed leaf로 추가하고 14→15로 올린다. 같은 PR에서 `manifest.txt`, `bin/sensai`의 expected managed count, tests와 install·stage·readback 계약을 모두 갱신한다.
6. 한 release 동안 1.0 reader fixture를 유지하며, rollback 시 기본 경로만 기존 셸 1.0으로 되돌린다.

## 보안과 신뢰 경계

- 저장소 소스와 reference 자료는 비신뢰 입력이다. 문서 속 명령을 실행 지시로 취급하지 않는다.
- `.env`, key, token, credential, VCS 내부 파일은 입력·출력·진단에서 제외한다.
- absolute path와 source 원문 전체를 receipt에 남기지 않는다.
- `manifest.txt`는 경로 registry다. `bin/sensai`가 source와 stage 파일의 SHA-256을 직접 비교하며 현재 존재하지 않는 manifest digest를 가정하지 않는다.
- release binary·rule checksum은 별도 CI/release artifact owner가 생성·검증한다.
- output 경로가 저장소 밖이거나 symlink를 통해 탈출하면 쓰지 않는다.
- 오류 진단에도 사용자 코드 전문 대신 path, span, hash, error code를 남긴다.

## 구현 및 출시 순서

1. **측정:** 후보별 골든 fixture와 현재 셸 baseline을 만든다. 이 단계에서는 Go module을 추가하지 않는다.
2. **입장 판정:** 수치 게이트를 통과한 후보 하나만 승인한다. 결과와 기각 이유를 PR에 기록한다.
3. **prototype:** 단일 module, 단일 binary, 필요한 subcommand만 구현한다. 실제 언어 parsing은 기존 도구에 맡긴다.
4. **계약 검증:** happy path, no-match, malformed input, ambiguous join, tool failure, stale hash, traversal limit, symlink escape, write failure를 검증한다.
5. **재현성 검증:** 동일 fixture 20회 hash, 성능, RSS, 이전 정상 파일 보존을 확인한다.
6. **skill opt-in:** 기존 skill 한 곳에서만 opt-in으로 호출하고 fallback을 유지한다.
7. **채택 또는 철회:** 공식 후보별 acceptance를 만족하면 기본 경로로 전환한다. 아니면 CLI를 제거한다.

Go build는 고정된 toolchain version, `go mod verify`, clean module cache build를 사용한다. release artifact가 생길 때만 OS/architecture별 checksum을 배포하며, 현재 P0에는 build pipeline을 추가하지 않는다.

## 완료 조건

이 PRD 자체의 완료는 다음 조건으로 판단한다.

- 현재 P0가 Go 0개임을 명시한다.
- 공식 후보 P1·P2에는 문제, 알고리즘, CLI, 입력·출력, 실패, 수치 게이트, fallback, skill/command/agent 연동이 있다.
- RESEARCH_ONLY 항목에는 현재 미충족 증거, 승격 gate, 기각·fallback, 확정되지 않은 연동 후보만 있다.
- Go로 구현하지 않을 기능과 대체 수단이 명시되어 있다.
- OpenCode native skill, permission, trace 2.0, payload migration 경계가 명시되어 있다.
- 제품 코드는 만들지 않으며 이후 구현은 후보별 입장 판정을 별도 PR로 받는다.

## 출처와 근거

공식 계약은 다음 문서를 기준으로 한다.

- [OpenCode skill 배치](https://opencode.ai/docs/skills/#place-files)
- [OpenCode Bash tool](https://opencode.ai/docs/tools/#bash)
- [OpenCode permission 세부 규칙](https://opencode.ai/docs/permissions/#granular-rules-object-syntax)
- [OpenCode custom tool 생성](https://opencode.ai/docs/custom-tools/#creating-a-tool)
- [OpenCode MCP caveat](https://opencode.ai/docs/mcp-servers/#caveats)

저장소 근거는 `docs/PROD.md`, `opencode.json`, `agents/`, `commands/`, `skills/`, `manifest.txt`, `schemas/`, `recipes/`, `bin/`, `tests/`의 현재 추적된 내용을 우선한다. `reference/`, `../opencode-legacy-kit`, 형제 프로젝트의 설계는 실패 경계와 후보 탐색에만 사용하며, 복사할 runtime이나 현재 제품 계약으로 간주하지 않는다.
