---
description: 검증된 분석 근거를 한국어 UI 정의서와 근거 기반 Mermaid 시퀀스로 설계한다.
agent: sensai-analysis-lead
subtask: false
---

아래 `입력`은 검증된 근거 산출물과 `docs/analysis/` 아래의 출력 경로를 지정한다.

입력:
$ARGUMENTS

입력이 비어 있거나 근거 파일이 없거나 출력이 `docs/analysis/` 밖을 가리키면 아무 파일도 쓰지 말고 사용법과 차단 원인을 보고한다.

`sensai-evidence-first`로 입력 근거의 상태와 인용을 확인한 다음 `sensai-ui-definition`과 `sensai-mermaid-sequence`를 불러온다. 명세 또는 RFC 의미를 확인해야 할 때만 `sensai-spec-evidence`를 추가로 불러온다.

검증된 근거가 뒷받침하는 화면, 상태, 상호작용, 호출과 반환만 설계한다. 원문 식별자와 값을 보존하고 해석은 한국어로 작성한다. 근거가 없는 동작은 만들지 말고 `UNKNOWN`으로 남기며, 모순과 다대다 모호성을 숨기지 않는다.

상태, 작성한 UI 정의서와 다이어그램 경로, 사용한 근거 ID, 모순, 모호성, 미확인 사항을 반환한다.
