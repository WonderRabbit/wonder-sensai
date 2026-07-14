---
description: 분석·설계 산출물의 스키마, 인용, 추적성, 미확인 보존과 Mermaid 컴파일을 검증한다.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 검증할 `docs/analysis/` 아래의 산출물 경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 대상이 없거나 `docs/analysis/` 밖을 가리키면 아무 파일도 쓰지 말고 사용법과 차단 원인을 보고한다.

먼저 `sensai-evidence-first`를 불러온다. 대상에 맞춰 `sensai-react-trace`, `sensai-vertx-trace`, `sensai-spec-evidence`, `sensai-ui-definition`, `sensai-mermaid-sequence` 중 필요한 검증 계약만 불러온다.

스키마, 1부터 시작하는 경로·줄 인용, 근거 ID 참조, 연결의 양쪽 근거, `UNKNOWN` 보존, 모순과 다대다 모호성 보존을 확인한다. Mermaid가 있으면 실제 컴파일 성공과 비어 있지 않은 결과를 요구한다. 제품 소스나 실패한 산출물을 자동 수정하지 않는다.

최종 결과를 `PASS` 또는 `FAIL`로 반환하고 실패한 파일, 규칙, 근거, 권장 다음 조치를 정확히 적는다.
