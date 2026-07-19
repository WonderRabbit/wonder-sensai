---
description: 스택 미가정·발견 기반 분석. A0–A5 게이트(범위→스택식별→후보→컨벤션→적재→검증). 근거 없는 주장은 UNKNOWN으로 보존한다.
agent: sensai-analysis-lead
subtask: true
---

아래 `입력`은 사용자가 제공한 분석 범위와 출력 계약이다.

입력:
$ARGUMENTS

입력이 비어 있거나 저장소 범위와 `docs/analysis/` 출력 경로를 식별하지 못하면 아무 파일도 쓰지 말고 사용법과 누락 필드를 보고한다.

## 분석 게이트 A0–A5 (01 §5)

- **A0 범위 고정**: root/scope를 canonical realpath로 고정. 사전 존재 파일 hash 보존. 허용 도구/경로 확정. symlink root·scope 탈출은 blocker.
- **A1 스택 식별** 🔴 첫 관문: 매니페스트(`package.json`/`go.mod`/`pom.xml`/`requirements.txt`/`Cargo.toml` 등)와 프레임워크 마커를 `fd`/`rg`/`yq`/`jq`로 읽어 스택+버전 식별(각 근거). 매니페스트 근거 없으면 `UNSUPPORTED`(강제 매핑 금지)로 종료.
- **A2 후보 수집**: 식별된 스택의 전용 recipe(`recipes/<stack>.yml`)이 있으면 `ast-grep` 가속기로 사용. **recipe이 없으면(새 스택)**: 코드에서 `ast-grep`으로 일반 패턴(함수/클래스/라우트/호출/상태 선언)을 추출해 새 recipe를 `recipes/<stack>.yml`로 생성·적재 → 이후 같은 스택에서 참조(성장 하네스). 후보는 사실이 아니다.
- **A3 컨벤션 추출** 🔴 핵심: §8의 7개 category별로 컨벤션 추출. 각 컨벤션은 ≥1 `path:line` 근거와 examples로 뒷받침. 의미 판단은 lead가 도구로 재확인한 근거만 확정. 근거 없으면 `UNKNOWN`(삭제 금지).
- **A3.1 컨벤션 → ast-grep 규칙 영속** (I5): A3에서 추출한 naming/structure/api_pattern/state 컨벤션을 ast-grep 규칙으로 변환(`pattern`+`regex`/`constraints`)해 분석 대상 `rules/learned-<stack>-<category>-<NNN>.yml` 에 영속 + 대상 `sgconfig.yml` 갱신(`ruleDirs`에 `rules`). 이후 `sg scan` 재사용으로 모델 추론 스킵(토큰 절약). **코드베이스 변화(git pull/commit/diff) 시 증분 재스캔**(`sg scan $(git diff --name-only <base>..HEAD --diff-filter=d)`)으로 learned 갱신(I5 §3.5).
- **A4 정규화·적재**: 안정적 ID(`CONV-<CAT>-<NNN>`) 부여, `kind: asis`, status(`exact`/`unresolved`/`ambiguous`/`conflict`) 확정, 원장 `conventions[]`+`evidence[]` 적재. 모순/모호성 보존.
- **A5 검증**: `recipes/trace.jq`로 정규 trace + 컨벤션 무결성 검증. exit 0까지 최대 3회 재시도.

## 결정적 주입 (Context Handoff, T1 §4)

레시피 "선택"은 결정적 층(도구+명령), "사용"은 모델 층. 모델이 추측으로 선택하지 않는다.

- A1 매니페스트 근거: `!jq '{deps: (.dependencies // {}), devDeps: (.devDependencies // {}), name: .name}' package.json`
- 스택 매칭 시 레시피(식별된 스택에 한함): `@recipes/react.yml`, `@recipes/vertx.yml`, `@recipes/spring.yml`
- 선행 `docs/analysis/trace.json` 학습 표준: `!jq -r '.conventions[] | "\(.id): \(.statement_ko)"' docs/analysis/trace.json`

## 스킬 로드

먼저 `sensai-evidence-first`를 불러온다. A1 식별 후 해당 스택 가속기(`sensai-react-trace`/`sensai-vertx-trace`/`sensai-spec-evidence`)만 추가 로드. A3에서 `sensai-convention-extract` 호출.

## 근거 정책 (불변)

모든 사실·연결은 `evidence_ids`(≥1). 근거 없으면 `UNKNOWN`, 동적만 결정되면 `unresolved`, 복수 후보면 `ambiguous`/`many_to_many`, 충돌이면 `conflict`. 이름 유사도로 빈 연결을 채우지 않는다. UI 정의서·Mermaid는 이 단계에서 만들지 않는다.

## 반환

A0–A5 각 게이트의 Pass/Blocker, 산출물 경로, 근거 수, 모순·모호성·미확인·UNSUPPORTED, 다음 탐색.
