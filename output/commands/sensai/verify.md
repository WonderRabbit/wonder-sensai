---
description: 분석·설계 산출물의 스키마·인용·추적성·UNKNOWN 보존·Mermaid 컴파일을 검증한다.
agent: sensai-analysis-lead
subtask: true
---

아래 `입력`은 검증할 `docs/analysis/` 아래 산출물 경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 대상이 없거나 `docs/analysis/` 밖을 가리키면 아무 파일도 쓰지 말고 사용법과 차단 원인을 보고한다.

## 결정적 주입 (Context Handoff, T1 §4)

검증 대상(canonical trace):
@docs/analysis/trace.json

- trace 무결성: `!jq -e -f recipes/trace.jq docs/analysis/trace.json`
- UI provenance: `!jq -e --arg kind ui --rawfile artifact docs/analysis/ui-definition.ko.md -f recipes/provenance.jq docs/analysis/trace.json`
- Mermaid provenance: `!jq -e --arg kind mermaid --rawfile artifact docs/analysis/sequence.mmd -f recipes/provenance.jq docs/analysis/trace.json`

## 스킬 로드

먼저 `sensai-evidence-first`. 대상에 맞춰 필요 검증 스킬만 추가 로드.

## 검증 항목

- 스키마(schema 2.0), 1부터 시작하는 `path:line` 인용, 근거 ID 참조, 연결 양쪽 근거.
- `UNKNOWN` 보존, 모순·다대다 모호성 보존.
- Mermaid가 있으면 `mmdc` 컴파일 성공 + 비어있지 않은 결과 요구.
- 제품 소스·실패한 산출물을 자동 수정하지 않는다.

## 반환

최종 결과 `PASS` 또는 `FAIL`. 실패한 파일·규칙·근거·권장 다음 조치를 정확히 적는다.
