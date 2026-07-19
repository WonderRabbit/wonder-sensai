# R5 — 오케스트레이션 토폴로지

> orchestrator(lead) ↔ worker(peer) 토폴로지. H9(오케스트레이션 메타기계 금지) 준수 — OpenCode native(todo·subtask·skill) + 파일(progress·trace)만.

## 토폴로지

- **lead**(`sensai-analysis-lead`, primary): 범위 결정, 의미 판단, 최종 판정, `docs/analysis/**` 유일 작성자, peer 위임.
- **peer**(`sensai-evidence-peer`, subagent·hidden): 제한된 읽기 전용 조사. lead가 지정한 좁은 범위에서 근거·모순·모호성·미확인 수집. edit/task/판정 금지.

## 원칙

- **H9 메타기계 금지**: boulder/ledger/multi-round-adversarial-verify 같은 상태기계 구축 금지. OpenCode 내장(todo·subtask) + 파일(progress.json·trace.json)이면 충분.
- **비대칭 권한**: lead만 edit + 판정. peer는 read-only.
- **단일 작성자**: `docs/analysis/trace.json` 쓰기는 lead만(직렬화, 동시 write 금지).
- **결정적 층 우선**: command(Context Handoff)가 순서·주입을 처방. 모델이 추측으로 정하지 않는다.

## 병렬/분할

- 01(기술)·02(비즈니스) 병렬 가능 — 별 세션/child session(T3 세션 분리).
- 분석/조사 단계는 `subtask: true`로 메인 컨텍스트 격리.
- 동일 trace.json 쓰기는 직렬화(advisory lock 또는 입학 후 sensai-ledger).

## 입학 후보

- codegraph(구조 분석 차선) — `VALUE_PROVEN` 시 상시.
- Go wrapper(정적 바이너리) — 입학 후 thin wrapper.
