# V1 — Test / Fixture 전략

> 하네스 검증 전략(단위·통합·회귀). 기존 `tests/test.sh` 확장.

## 1. 단위 테스트

- **jq recipe/validator**: `trace.jq`·`provenance.jq`(5모드)·`glossary.jq` 입출력 fixture(유효/무효 trace·산출).
- **schema**: `trace.schema.json` 2.0 + `progress.schema.json` 유효/위반 fixture.
- **ID 체계**: 패턴 매칭(CONV/BIZ/DESIGN/REQ-EXT/GLOSS).

## 2. 통합 테스트

- **MVP 슬라이스 end-to-end**(00 §10) → 각 단계 확장 시 해당 경로.
- **provenance 체인**: 산출 ID → 원장 사실 역대조(asis/tobe).
- **일관성 게이트**: 위반 fixture가 불통과로 판정되는지(D4).

## 3. 회귀 테스트 (tests/test.sh 유지·확장)

- **happy**: manifest leaf·load·trace·provenance·한국어 문서·Mermaid SVG.
- **adversarial**: dynamic URL·duplicate route·dangling·요구사항 충돌·empty/malformed·어긋난 evidence + (확장) 컨벤션 위반·비즈니스 규칙 충돌·스택 미식별.
- **regression**: topology·ID·스크립트 무결·한국어.

## 4. CI

변경 시: lint + (해당 시) type + 단위/통합/회귀. 증거는 `.omo/evidence/`에 JSONL/SVG 보존(재현성).

## 5. fixture 관리

- **분석 대상 = 사용자 코드베이스**(현재 `../partner/agent-jang`) — 하네스가 분석(A1 발견 기반).
- **다중 스택 fixture**(Vue·Next·redux-saga) — 입학 후 확장.
- **비즈니스 복잡 fixture** — 상태 전이·이벤트 다수 도메인.
- **대립(adversarial) fixture** — 각 게이트 위반 케이스.
- 각 fixture는 expected trace/산출(golden) 보존해 회귀 판정.

## 6. 입학 연계

입학 게이트(O3)의 fixture·metric이 본 전략의 fixture·단위 테스트를 재사용.
