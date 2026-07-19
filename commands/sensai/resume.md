---
description: O5 미션 재개. progress.json + trace.json 읽어 상태 재구성, precondition 검증 후 결정적 주입으로 이어서.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 재개할 미션 식별자/경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 `docs/analysis/progress.json`이 없으면 사용법과 차단 원인을 보고한다.

## 재개 프로토콜 (O5 §5)

1. 상태 읽기: `@docs/analysis/progress.json` + `@docs/analysis/trace.json`.
2. 재구성: `pipeline_position`(현재 단계) · `completed[]` · `todo_snapshot` · `next[]` · `blocked[]`.
3. **precondition 검증**: git HEAD · `trace.json` hash · 필수 파일 존재 · 모델/도구 버전이 기록과 일치?
   - 불일치 → abort 또는 재베이스라인(병렬 세션/외부 변경 감지).
4. 결정적 주입:
   - `!jq -r '.pipeline_position' docs/analysis/progress.json`
   - `!jq -r '.next[] | .task' docs/analysis/progress.json`
   - `!jq -r '.blocked[] | .reason' docs/analysis/progress.json`
5. todo 복원(persisted snapshot → in-session todo) → 이어서.

## 진실 우선순위 (O5 §6)

원장(`trace.json`) > `progress.json` > todo(뷰). 충돌 시 원장. `/clear` 후에도 원장+파일에서 복원.

## 반환

현재 F 단계, 완료 task, next, blocking, 원장/progress 경로, precondition 검증 결과.
