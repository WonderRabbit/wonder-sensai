---
description: O6 미션 시작·전체 흐름 운영. F0-F5 게이트 순서 + 컨펌 게이트(HITL) + OpenCode todo 시각화.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 분석 대상(root/scope) + 미션 goal을 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 root/scope를 식별하지 못하면 사용법과 누락 필드를 보고한다.

## 워크플로우 F0–F5 (O6 §4)

- **F0 미션 시작**: target/goal 식별 → 전체 단계 계획 + OpenCode todo 초기화 + STATUS 뷰 생성. **사용자 계획 컨펌**(hard).
- **F1 AS-IS 기술**(01 `/sensai/analyze`): `trace.json` AS-IS 기술(conventions). soft.
- **F2 AS-IS 비즈니스**(02 `/sensai/analyze-business`): AS-IS 비즈니스. 01과 병렬 가능. soft.
- **F3 AS-IS 산출**(03 `/sensai/design`): AS-IS 4 산출. **hard: AS-IS accept**(TO-BE 진입 전).
- **F4 TO-BE 설계**(04 `/sensai/change-design`): `designs[]`+`bindings[]`. soft.
- **F5 TO-BE 산출**(05 `/sensai/deliver`): TO-BE 5 산출 + 테스트. **hard: 미션 accept**(종료).

각 F 완료 시: (a) OpenCode todo 갱신, (b) `progress.json` checkpoint(O5), (c) STATUS 뷰 갱신, (d) 다음 F 컨펌 게이트.

## 컨펌 게이트 (O2 연계)

- **soft**: F1→F2, F2→F3, F4→F5 (같은 축 내 전환) — 확인 후 진행, 생략 가능(자동 진행 옵션).
- **hard**: F3(AS-IS accept), F5(미션 accept) — **사람 명시적 컨펌 필수**. verdict·시각·사유를 `progress.json`에 기록.

## 결정적 주입 (Context Handoff)

- 현재 progress: `@docs/analysis/progress.json`
- 원장: `@docs/analysis/trace.json`

## 반환

F0 계획, todo 초기 상태, STATUS 뷰, 각 F의 Pass/Blocker, 컨펌 시점.
