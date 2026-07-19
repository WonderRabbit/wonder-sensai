# R2 — 옵션 영향 테스트 방법론

> 모델/도구 옵션 변경이 산출에 미치는 영향을 측정한다. **강제 게이트 아님** — 필요한 때 쓰는 방법론(T2-methodology 기반).

## 절차

1. **베이스라인**: 기본 옵션(lead temperature 0.1 / steps 30 등)으로 run → 산출·validator 결과 기록.
2. **옵션 변경**: 한 변수씩(temperature / top-k / repetition_penalty / steps / variants).
3. **동일 입력 재run**: 같은 코드베이스·스코프·버전에서.
4. **delta 측정**:
   - 근거 정확도(path:line 역대조 통과율)
   - validator(`trace.jq`/`provenance.jq`) exit
   - 산출 ID 안정성(동일 입력 → 동일 ID)
   - 할루시네이션(근거 없는 주장) 발생 수
5. **EXP 레코드 기록**: `docs/research/EXP-*.md` 양식(predicted/actual/delta/출처).

## 임계값(근사치, live 확정)

- 근거 없는 주장: 0
- validator exit: 0
- 산출 ID 안정성: 동일 입력에 동일 ID
- 옵션별 유의미 delta 임계: live 실측 후 확정

## 비고

- 회사 폐쇄망 Qwen live endpoint에서 실측. 집 개발은 GLM stand-in(근사치).
- 강제 게이트 아님 — 품질 회귀 의심 시 적용.
