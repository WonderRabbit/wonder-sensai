# AGENTS.md — wonder-sensai 하네스 (opencode 전역 지시)

> opencode가 세션 시작 시 읽는 지시. 본 하네스는 legacy codebase를 **도구 결과로만** 분석한다. 모델 추측으로 파일을 찾거나 사실을 단정하지 마라 — 반드시 아래 도구로 확인하고 `path:line` 근거를 남겨라.

## opencode 설정 (참조)

- `opencode.json`: provider `sensai-ollama`(ollama localhost:11434) + `model: zai/glm-5.2`(lead, opencode auth Z.AI) + `small_model: sensai-ollama/qwen3.5:9b`(peer).
- `agents/`: `sensai-analysis-lead`(primary, 작성/판정) · `sensai-evidence-peer`(subagent, 읽기 전용).
- `commands/sensai/`: 9 명령(analyze/analyze-business/design/verify/change-design/deliver/run/resume/status).
- `skills/`: 15(on-demand). `recipes/`: jq 검증기(trace/provenance/glossary) + 스택 레시피(react/vertx/spring).

## 도구 사용 (사실 판정자 — 모델 추측 금지, 도구 결과만 사실)

| 도구 | 용도 | 사용 예 |
|---|---|---|
| `fd` | 파일 발견(NUL-safe) | `fd -t f . <scope>` — 범위 내 파일 목록. **파일 경로 추측 금지**, 반드시 fd로 찾아라. |
| `rg` (ripgrep) | 텍스트 후보·`path:line` | `rg --no-config --json --sort path --line-number '<패턴>' <scope>` — 호출·라우트·문자열·의존성 후보. |
| `ast-grep` (`sg`) | 구조 후보(언어별) | `ast-grep --json '<규칙>' <파일>` — 컴포넌트·handler·상태·라우트·이벤트 구조. `sg`는 ast-grep임이 확인될 때만. |
| `jq` | 원장 조작·매니페스트·검증 | `jq -e -f recipes/trace.jq docs/analysis/trace.json`(검증), `jq '.dependencies' package.json`(매니페스트 독해). |
| `yq` (Mike Farah) | OpenAPI/YAML → JSON | `yq -o=json '.' openapi.yaml` — operationId/path/응답 추출. Python wrapper 아님. |
| `mdq` | 한국어 Markdown 구조 질의 | `mdq '#{2} ^"화면 목적"' docs/analysis/ui-definition.ko.md` — 필수 제목·표 검증. |
| `mmdc` | Mermaid → SVG 렌더 | `mmdc --quiet --input <in>.mmd --output <out>.svg` — parser + Chromium 실행 검증. 비어있지 않은 SVG 요구. |
| `codegraph` | 구조 그래프(입학 후) | `VALUE_PROVEN`(O3) 후만. 기본은 `ast-grep`/`rg` direct. |

## 파일 검색 전략 (추측 금지 — 단계별 도구 사용)

1. **파일 발견**: `fd -t f . <scope>` 로 범위 내 파일. 절대 경로를 추측하지 마라.
2. **내용 후보**: `rg --json --line-number '<패턴>' <scope>` 로 path:line 후보. **후보는 사실이 아니다.**
3. **구조 확인**: `ast-grep --json '<규칙>' <파일>` 로 언어별 구조(컴포넌트·handler·라우트·상태).
4. **사실 확정**: lead가 도구 결과를 직접 재확인 → `evidence_ids`. 미확인은 `UNKNOWN`(삭제 금지).
5. **검증**: `jq -e -f recipes/trace.jq docs/analysis/trace.json` exit 0.

## 스택 식별 (A1)

- 매니페스트(`package.json`/`go.mod`/`pom.xml`/`build.gradle`/`Cargo.toml`/`requirements.txt`)를 `fd`/`rg`로 찾고 `jq`/`yq`로 의존성·버전 추출.
- 프레임워크 마커(설정 파일·의존성 이름·디렉토리 규칙)를 `rg`/`ast-grep`으로 확인.
- 매니페스트 근거 없으면 `UNSUPPORTED`(강제 매핑 금지)로 종료.

## 컨벤션 추출 (A3)

- `ast-grep`(구조) 또는 `rg`(텍스트)로 패턴 후보 수집(`path:line`).
- 각 후보를 직접 근거와 연결(`evidence_ids`, 정규 trace exact에 역대조).
- 근거 없는 규칙은 발명 금지. 단일 사례로 일반화 금지. `UNKNOWN`/`AMBIGUOUS` 보존.

## 사실 판정 (절대 원칙)

- **도구 결과(`path:line`)만 사실.** 모델 추측·이름 유사도·가장 가까운 후보로 빈 연결을 채우지 마라.
- 근거 없으면 `UNKNOWN`(삭제 금지). 동적만 결정=`unresolved`, 복수 후보=`ambiguous`/`many_to_many`, 충돌=`conflict`.
- 주석·문자열·예제는 근거가 아니다(코드 구조와 값 전달로 확인).
- `recipes/trace.jq`(원장 무결성) · `recipes/provenance.jq`(산출 역대조, 5모드) · `recipes/glossary.jq`(용어사전) — 각 exit 0 요구.

## 명령 (commands/sensai/)

| command | 단계 | 게이트 |
|---|---|---|
| `/sensai/run` | 미션 전체 | F0–F5 + 컨펌 게이트 |
| `/sensai/analyze` | 01 기술 | A0–A5(fd/rg/ast-grep로 스택·컨벤션) |
| `/sensai/analyze-business` | 02 비즈니스 | B0–B5(ast-grep/jq/yq로 엔티티·규칙) |
| `/sensai/design` | 03 AS-IS 산출 | W0–W4(jq/mmdc/mdq) |
| `/sensai/verify` | 검증 | jq(trace/provenance/glossary)+mmdc |
| `/sensai/change-design` | 04 TO-BE 설계 | D0–D5(일관성 게이트, jq/ast-grep) |
| `/sensai/deliver` | 05 TO-BE 산출 | V0–V5(jq/mmdc/mdq) |
| `/sensai/resume` | 재개 | O5(progress + precondition) |
| `/sensai/status` | 전체 뷰 | jq(progress/trace) |

## 워크플로우 (F0–F5)

```
F0 시작(계획, hard 컨펌) → F1 기술(01) → F2 비즈니스(02, 병렬)
→ F3 AS-IS 산출(03, hard: AS-IS accept) → F4 TO-BE 설계(04)
→ F5 TO-BE 산출(05, hard: 미션 accept)
```

## 역할

- **lead**(`zai/glm-5.2`): 범위 결정·**도구 재확인**·의미 판단·한국어 산출·최종 판정·`docs/analysis/**` 유일 작성자.
- **peer**(`sensai-ollama/qwen3.5:9b`): 읽기 전용 근거 조사(lead 위임만). `edit`/`task`/판정 금지.

## 산출

- `docs/analysis/trace.json` — 단일 canonical 원장(schema 2.0, `kind: asis|tobe`).
- `docs/analysis/progress.json` — 미션 진행(O5).
- UI 정의서·시퀀스·데이터플로우·스토리·테스트 — `docs/analysis/` 아래.

## 반드시 (다시)

- 파일을 찾을 때 `fd`/`rg` 없이 경로를 추측하지 마라.
- 코드 구조를 말할 때 `ast-grep`/`rg` 없이 단정하지 마라.
- 근거 없는 주장은 `UNKNOWN`으로 두고 발명하지 마라.
