# O3 — 입학 게이트(Admission Gates)

> 후보 기능(신규 스킬·codegraph·정형 추출기·yeoman)이 상시 경로로 승격되는 조건 = fixture + metric + threshold + 사람 승인.

## 상태기 (계승)

`REQUIRED_TO_EVALUATE` → `NOT_ADMITTED` | `ADMITTED_NO_VALUE` | `VALUE_PROVEN`. **상시 필수 차선은 `VALUE_PROVEN`만.**

## 게이트 (후보 → 상시)

후보는 아래 모두 통과 시 상시 경로:
1. **정확성 fixture ≥2**: 기존 방식(ast-grep/rg/jq)이 틀리거나 필요한 ambiguity를 잃는 입학 fixture.
2. **재현 가능**: 같은 입력·버전에서 동일 결과(이름 유사도/수동 allowlist 없이).
3. **정량 metric(threshold)**: 아래 metric이 기준 이상.
4. **사람 승인**(O2): 증거 검토 후.

## 후보별 metric/threshold (근사치, live 확정)

| 후보 | metric | threshold(근사치) |
|---|---|---|
| codegraph | 구조 분석 정확도·wall time·RSS vs direct CLI | 정확도 동일 이상 + p95 `2s`/RSS `512MiB` 또는 가치 순증 |
| 신규 스킬(각) | 입학 fixture 통과율·근거 정확도 | 통과율 ≥90% · 근거 없는 주장 0 |
| 정형 추출기(P1) | 10K node/50K edge wall time·정확도 | p95 `2s`/`512MiB` + 기존 방식 회복 불가 증명 |
| yeoman(backlog) | 코드 생성 정확도·컨벤션 준수·비파괴 | 생성 코드가 설계+컨벤션 역추적 + 비파괴 |

## 입학 전/후

- **입학 전**: 후보는 옵션/실험 경로. 상시 파이프라인은 기존 방식(ast-grep/rg/jq).
- **입학 후(VALUE_PROVEN)**: 상시 필수 차선/스킬로 승격 — `permission.skill`·`opencode.json`·agent allowlist에 반영.
- **퇴출**: 회귀(다음 실행 품질 ↓) 시 롤백.

## 로그

입학 평가 결과는 `.omo/evidence/`에 fixture·metric·판정 보존(재현성).
