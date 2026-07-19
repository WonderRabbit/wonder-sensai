# O4 — 빌드 / 구현 로드맵

> MVP 이후 전체 빌드 순서(00 §10 + release-plan v2). 하네스 우선·입학 게이트 원칙.

## 빌드 순서 + 현재 상태

| # | 단계 | PRD | 상태 |
|---|---|---|---|
| 1 | setup + 도구 smoke | O1 | ✅ |
| 2 | schema/recipe 2.0 | I1 | ✅ |
| 3 | **MVP 슬라이스 run**(00 §10) | — | ⏳ GLM run timeout — 범위/timeout 조정 대기 |
| 4 | agent/command | I4/I3 | ✅ |
| 5 | 확장 분석(02·03) | 02/03 | ✅ |
| 6 | 확장 산출(dataflow/story/test) | I2 | ✅ |
| 7 | TO-BE(04·05) | 04/05 | ✅ |
| 8 | 입학 게이트(각 스킬·codegraph) | O3 | ⏳ run 성공 후 metric 실측 |
| 9 | backlog(yeoman 코드 생성) | — | 입학 후 별도 SPEC |

## 의존(DAG)

`setup(1) → schema(2) → MVP(3) → agent/command(4, 3에 의존) → 확장(5-7) → 입학(8 병렬) → yeoman(9, 7 이후)`

## 원칙

- 각 단계는 입학 게이트/단위 테스트 통과 후 다음(하네스 우선).
- MVP(3) 통과 전 확장(5-7) 금지 — 단 틀(코드)은 사전 구축 완료(현재 상태).
- 옵션 값·권한은 live 실측으로 확정(근사치 → 실측).

## 현재 위치

- **틀(1-2, 4-7) 전부 완료.** MVP run(3)이 GLM 응답 시간에 걸려 대기.
- 입학(8)은 run 성공 후 metric/threshold 실측.
