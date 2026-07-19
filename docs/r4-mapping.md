# R4 task→agent→skill→CLI/permission 매핑표

> 각 게이트의 에이전트·스킬·CLI 배치를 정합한다(R4, T1 §3). 결정적 층(command가 처방)이 순서를 정하고, 모델은 주입된 컨텍스트 위에서 수행한다.

## Axis A 단계

| 단계 | 게이트 | command | agent | skills(로드 순서) | CLI |
| --- | --- | --- | --- | --- | --- |
| 01 기술 분석 | A0–A5 | `/sensai/analyze` | lead | evidence-first → stack-discovery → convention-extract → (식별 스택) react/vertx/spec-trace | fd/rg/ast-grep/jq/yq |
| 02 비즈니스 | B0–B5 | `/sensai/analyze-business` | lead | evidence-first → business-trace → (가속기) | ast-grep/jq/yq |
| 03 AS-IS 산출 | W0–W4 | `/sensai/design` | lead | evidence-first → ui-definition → mermaid-sequence | jq/mdq/mmdc |
| 04 변경 설계 | D0–D5 | `/sensai/change-design` | lead | evidence-first → requirement-analyze → change-design | jq/ast-grep/rg |
| 05 TO-BE 산출 | V0–V5 | `/sensai/deliver` | lead | evidence-first → ui-definition → mermaid-sequence → dataflow-chart → user-story → test-scenario | jq/mdq/mmdc |
| 검증 | — | `/sensai/verify` | lead | evidence-first → (대상 스킬) | jq(trace/provenance)/mmdc |

## 워크플로우 (O6)

| 단계 | command | agent | CLI |
| --- | --- | --- | --- |
| 미션 시작·운영 | `/sensai/run` | lead | jq(progress) |
| 재개 | `/sensai/resume` | lead | jq(progress/trace) |
| 전체 뷰 | `/sensai/status` | lead | jq(progress) |

## peer (읽기 전용, lead 위임)

| 조사 | agent | 허용 스킬 | 권한 |
| --- | --- | --- | --- |
| 근거·모순·모순성·미확인 수집 | `sensai-evidence-peer` | evidence-first + react/vertx/spec-trace | read-only (edit/task deny) |

## 입학 후보 (O3 통과 시 상시 편입)

- 입학 전(after 슬라이스 통과 전): `stack-discovery`, `business-trace`, `dataflow-chart`, `user-story`, `test-scenario`, `requirement-analyze`, `change-design` — 후보 경로.
- 입학 후(`VALUE_PROVEN`): 상시 필수 차선/스킬로 승격 — `permission.skill`·`opencode.json`·agent allowlist에 반영.

## 원칙

- 결정적 층(command 본문 Context Handoff)이 스킬 로드 순서를 처방 → 모델이 추측으로 선택하지 않는다.
- lead만 `docs/analysis/**` 작성·최종 판정. peer는 읽기 전용.
