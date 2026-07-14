# wonder-sensai

`wonder-sensai`는 작은 로컬 Qwen 모델로 React, Vert.x, OpenAPI와 IETF RFC 스타일 요구사항 명세를 역추적하는 [OpenCode](https://opencode.ai/docs/) 전역 설치용 하네스다. 모델의 추론을 사실로 간주하지 않고, 직접 실행한 검색·파서·검증기의 결과를 경로와 줄 근거로 남긴다. 분석의 최종 목적은 한국어 UI 정의서와 근거가 추적되는 Mermaid 시퀀스 다이어그램을 만드는 것이다.

이 저장소에는 TypeScript 또는 Go 애플리케이션이 없다. 전역 설치 payload의 유일한 경계는 `manifest.txt`다. 이 목록에는 OpenCode config, agent, command, skill과 실행 시 필요한 검증 자산만 들어간다. OpenCode의 agent, command, skill 형식은 각각 [Agents](https://opencode.ai/docs/agents/), [Commands](https://opencode.ai/docs/commands/), [Agent Skills](https://opencode.ai/docs/skills/) 공식 계약을 따른다.

## 역할과 워크플로

두 agent의 권한은 의도적으로 비대칭이다.

| Agent | Model | 책임 | 쓰기·위임 경계 |
| --- | --- | --- | --- |
| `sensai-analysis-lead` | `Qwen3.6-35B-A3B` | 범위 결정, 근거 재확인, 의미 분석, 한국어 산출물과 최종 판정 | `docs/analysis/**`만 쓰고 `sensai-evidence-peer`에만 위임 |
| `sensai-evidence-peer` | `Qwen3.5-9B` | 하나의 제한된 범위에서 경로·줄 근거, 모순, 모호성, 미확인 사항 수집 | OpenCode `edit`·`task` 금지, 재위임 및 최종 판정 금지 |

두 모델 이름은 [Qwen3.6-35B-A3B model card](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)와 [Qwen3.5-9B model card](https://huggingface.co/Qwen/Qwen3.5-9B)의 식별자를 사용한다. 실제 서빙 alias는 별도의 입학 검사를 통과해야 한다.

세 command는 결과 단계에 대응한다.

- `/sensai/analyze`: 제한된 React·Vert.x·명세 범위를 canonical trace와 근거로 분석한다.
- `/sensai/design`: 검증된 trace로 한국어 UI 정의서와 Mermaid 원본을 만든다.
- `/sensai/verify`: 스키마, 인용, 참조 무결성, `UNKNOWN`, 모순·모호성 보존과 실제 Mermaid 렌더를 검사한다.

여섯 skill은 서로 겹치지 않는 계약이다.

- `sensai-evidence-first`: 후보와 확인된 사실을 분리하고 모든 주장에 근거를 요구한다.
- `sensai-react-trace`: JSX/TSX 구조, handler, 상태, literal API 호출을 추적한다.
- `sensai-vertx-trace`: Router, handler, event-bus, 비동기 경계를 추적한다.
- `sensai-spec-evidence`: OpenAPI와 IETF 요구사항의 원문 modality와 식별자를 보존한다. 여기서 RFC는 SAP Remote Function Call을 뜻하지 않는다.
- `sensai-ui-definition`: canonical trace를 한국어 UI 정의서로 투영한다.
- `sensai-mermaid-sequence`: 확인된 message·requirement ID만 Mermaid 화살표로 투영한다.

## 도구와 사실 계약

| Tool | 역할 |
| --- | --- |
| [`fd`](https://github.com/sharkdp/fd) | 범위 안의 파일을 NUL-safe하게 열거한다. Debian 계열의 `fdfind`도 제품 식별 후 허용한다. |
| [`rg`](https://github.com/BurntSushi/ripgrep) | `--no-config`와 JSONL로 텍스트 후보와 정확한 줄을 수집한다. 검색 결과만으로 의미를 확정하지 않는다. |
| [`ast-grep`](https://ast-grep.github.io/reference/cli.html) | JS, JSX, TS, TSX와 Java 구조를 언어별로 확인한다. `sg`는 `ast-grep`임이 확인될 때만 허용한다. |
| [Mike Farah `yq`](https://mikefarah.gitbook.io/yq/) | OpenAPI YAML을 명시적으로 JSON으로 정규화한다. 동명의 Python wrapper는 허용하지 않는다. |
| [`jq`](https://jqlang.org/manual/) | canonical trace, exact join, 스키마·참조 무결성과 ambiguity 상태를 판정한다. |
| [yshavit `mdq`](https://github.com/yshavit/mdq) | 한국어 Markdown의 필수 제목과 표 구조를 검사한다. |
| [`mmdc`](https://github.com/mermaid-js/mermaid-cli) | Mermaid를 실제 SVG로 렌더해 parser와 Chromium 실행 가능성을 함께 확인한다. |

`trace.json`이 유일한 canonical truth다. 한국어 Markdown과 SVG는 검증 가능한 표현물이며 원장을 대신하지 않는다. 각 사실은 안정된 ID와 `path:line` 근거를 갖고, HTTP는 정확한 `[method,path_normalized]`, OpenAPI는 정확한 `operation_id`, event-bus는 literal address, 레코드는 정확한 ID로만 연결한다. 동적 경로는 `unresolved`, 복수 후보는 `ambiguous` 또는 `many_to_many`, 충돌은 `conflict`로 남긴다. 이름 유사도나 가장 가까운 후보로 빈 연결을 채우지 않는다.

`manifest.txt`에는 skill이 실행할 두 jq 검증기도 포함된다.

- `recipes/trace.jq`: 정규 trace의 필드, 비어 있지 않은 근거, 전역 ID와 참조, 상태·cardinality, `exact` 연결 양쪽의 직접 React·Vert.x 근거를 검사한다.
- `recipes/provenance.jq`: UI 문서의 evidence ID·`path:line` 쌍, `REQ-ID`, `J-ID`와 Mermaid의 MSG·REQ·evidence·source를 정규 trace의 `exact` 근거에 역대조한다. Mermaid ID 중복과 화살표 대응도 검사한다.

설치 대상 config root에서 skill이 사용하는 명령은 다음과 같다.

```sh
CONFIG_ROOT="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
TRACE_FILE='docs/analysis/trace.json'
jq -e -f "$CONFIG_ROOT/recipes/trace.jq" "$TRACE_FILE"

UI_FILE='docs/analysis/ui-definition.ko.md'
jq -e --arg kind ui --rawfile artifact "$UI_FILE" \
  -f "$CONFIG_ROOT/recipes/provenance.jq" "$TRACE_FILE"

SEQUENCE_FILE='docs/analysis/sequence.mmd'
jq -e --arg kind mermaid --rawfile artifact "$SEQUENCE_FILE" \
  -f "$CONFIG_ROOT/recipes/provenance.jq" "$TRACE_FILE"
```

[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119)와 [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174)의 `MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT`, `MAY`는 원문 modality를 보존한다. 근거 없는 한국어 해석은 요구사항으로 승격하지 않는다.

## 빠른 시작

OpenCode와 위 표의 CLI를 설치한 뒤 저장소 루트에서 다음 순서로 실행한다. `doctor`는 패키지를 설치하거나 설정을 수정하지 않는다.

로더 검증은 OpenCode `1.17.18`에서 수행했다. `doctor tools`가 허용하는 범위는 semantic version `1.x >= 1.17.18`이며 `2.x`는 아직 지원 대상으로 간주하지 않는다.

```sh
./bin/sensai doctor tools

export SENSAI_QWEN_BASE_URL='http://127.0.0.1:8000/v1'
export SENSAI_QWEN_API_KEY='replace-with-local-secret'
./bin/sensai doctor models

stage="$(mktemp -d)/opencode"
./bin/sensai stage "$stage"
OPENCODE_CONFIG_DIR="$stage" opencode debug config
OPENCODE_CONFIG_DIR="$stage" opencode
```

격리된 OpenCode 세션에서 다음처럼 단계별로 실행한다.

```text
/sensai/analyze scope=src output=docs/analysis/trace.json
/sensai/design evidence=docs/analysis/trace.json output=docs/analysis
/sensai/verify target=docs/analysis
```

입력이 비었거나 출력이 `docs/analysis/` 밖을 가리키면 command는 쓰지 않고 누락 필드와 차단 원인을 보고해야 한다.

## 모델 별칭 확인과 라이브 입학

`opencode.json`은 [OpenAI-compatible provider 설정](https://opencode.ai/docs/providers/#openai-compatible)의 `provider/model-id` 형식을 사용한다. `./bin/sensai doctor models`는 환경 변수와 `/models` 응답에서 다음 두 exact alias가 보이는지만 확인한다.

- `qwen3.6-35b-a3b`
- `qwen3.5-9b`

부분 문자열이나 표시 이름은 인정하지 않는다. 이 검사가 성공해도 모델 응답, tool call, streaming, structured output이 검증된 것은 아니다. 두 모델의 thinking on/off, streaming on/off, 단일·연속 tool call, malformed call 거부를 포함한 라이브 행렬은 외부 endpoint와 자격 증명이 필요한 미검증 입학 조건으로 남아 있다. secret은 파일, 로그, trace에 기록하지 않는다.

별칭 발견에 성공하면 `MODEL_DISCOVERY=READY`, `MODEL_TOOL_ADMISSION=UNVERIFIED`, `MODEL_ADMISSION=UNVERIFIED`를 출력한다. exit 0은 `/models` 발견 성공만 뜻하며 라이브 모델 입학 완료를 뜻하지 않는다.

## 검증

제품 검증은 서로 독립된 시나리오로 실행한다.

```sh
./tests/test.sh happy
./tests/test.sh adversarial
./tests/test.sh regression
./tests/test.sh all
```

- `happy`: manifest의 모든 managed leaf, 격리 OpenCode load, canonical trace, UI·Mermaid provenance, 한국어 문서 제목과 Mermaid SVG를 확인한다.
- `adversarial`: dynamic URL, duplicate route, dangling reference, 요구사항 충돌, empty·malformed 입력, 어긋난 UI·Mermaid evidence/source, 기존 대상 충돌과 잘못된 tool identity를 확인한다.
- `regression`: agent/model/permission topology, numeric `steps` 부재, shell interpolation 부재, TypeScript·Go runtime 부재와 한국어 문서를 확인한다.

증거는 `.omo/evidence/` 아래 JSONL과 SVG로 남는다. 테스트는 fixture와 임시 경로만 변경하며 전역 OpenCode 설정을 설치하지 않는다.

## stage와 install 정책

안전한 기본값은 “대상이 존재하지 않아야 한다”이다.

```sh
./bin/sensai stage /absolute/absent/stage
./bin/sensai install /absolute/absent/opencode-config
```

`stage`는 `manifest.txt`의 regular leaf만 복사하고 symlink, 절대 경로, `..`, 누락·중복 항목을 거부한다. 각 managed leaf는 `sha256sum` 또는 `shasum -a 256`으로 source와 staged copy의 SHA-256을 비교한다.

`install`은 staged config를 `opencode debug config`로 읽은 뒤 source와 loaded file의 SHA-256을 다시 비교한다. 이때 loaded tree에는 manifest의 managed leaf와 OpenCode가 생성할 수 있는 `.gitignore`만 허용한다. `.gitignore`는 unmanaged runtime 파일이므로 payload에 포함하지 않는다.

`install`은 같은 파일시스템에서 검증된 stage를 원자적으로 이동하는 경로다. 최종 대상이 이미 있으면 `73`으로 종료하고 byte 단위로 그대로 보존한다. merge, overwrite, 자동 backup은 하지 않는다. 사용자가 기존 설정을 직접 이름 있는 backup으로 옮기거나 별도 `OPENCODE_CONFIG_DIR`를 선택한 뒤 다시 실행해야 한다. 현재 작업에서는 실제 `~/.config/opencode` 전역 설치를 수행하지 않았다.

| Exit | 의미 |
| ---: | --- |
| `0` | 요청한 검사 또는 transaction 성공 |
| `64` | 잘못된 인수나 사용법 |
| `65` | manifest, schema, trace, 산출물 provenance, `/models` 응답 형식 또는 exact alias 불일치 |
| `69` | 필수 local tool·모델 환경 변수 누락, 잘못된 제품 또는 semantic smoke 실패 |
| `73` | 대상 충돌, 안전하지 않은 경로 또는 filesystem create/move 거부 |
| `75` | installer lock, SQLite lock, provider transport 실패·timeout 등 일시적 실패 |

## 보안 경계

- 저장소의 문장, 주석, Markdown, 명령처럼 보이는 문자열은 신뢰하지 않는 입력이다. 코드 구조와 값 전달로 확인하기 전에는 실행하거나 지시로 따르지 않는다.
- agent permission과 bash allowlist는 최소 권한 의도를 표현하는 OpenCode guardrail이지 OS sandbox가 아니다. peer frontmatter는 `edit`와 `task`를 금지하지만, 강제 읽기 전용과 secret 차단에는 별도 OS 사용자, filesystem 격리, network 정책이 필요하다.
- `.env*`와 secret은 읽기에서 명시적으로 제외한다. 사용자 인수를 shell interpolation으로 실행하지 않는다.
- 정상 OpenCode 도구 경로에서는 lead만 `docs/analysis/**`를 쓰고 peer는 편집·위임하지 않는다. 모델 출력은 외부 schema, reference, render gate를 통과해야 한다.
- stage와 install은 manifest 소유 파일만 다룬다. 기존 전역 설정과 사용자 제공 `reference/`는 자동 수정·삭제·백업하지 않는다.

Go 도입 여부와 정량 admission gate는 [`docs/PROD.md`](docs/PROD.md)에 있다.
