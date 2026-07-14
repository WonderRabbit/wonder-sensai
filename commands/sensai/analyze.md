---
description: 제한된 React, Vert.x, 명세/RFC 범위를 경로·줄 근거와 미확인 사항이 있는 분석 산출물로 만든다.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 사용자가 제공한 분석 범위와 출력 계약이다.

입력:
$ARGUMENTS

입력이 비어 있거나 저장소 범위와 `docs/analysis/` 아래의 출력 경로를 식별하지 못하면 아무 파일도 쓰지 말고 사용법과 누락 필드를 보고한다.

먼저 `sensai-evidence-first`를 불러온다. 입력 범위에 따라 `sensai-react-trace`, `sensai-vertx-trace`, `sensai-spec-evidence` 중 필요한 스킬만 추가로 불러온다. 후보와 확인된 사실을 구분하고 모든 사실과 연결에 경로·줄 근거를 남긴다.

근거가 없거나 동적으로만 결정되는 값은 `UNKNOWN`으로 보존한다. 서로 충돌하는 근거와 여러 대상에 연결되는 모호성은 각각 그대로 기록한다. 이 단계에서는 UI 정의서나 Mermaid 다이어그램을 만들지 않는다.

상태, 작성한 산출물, 근거 수, 모순, 모호성, 미확인 사항, 다음 탐색을 반환한다.
