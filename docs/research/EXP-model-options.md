# EXP — R1 모델 옵션 근사치 (predicted)

> Qwen/GLM 역할별 옵션 근사치. **live 실측 필요**(회사 폐쇄망 Qwen endpoint). 집 개발은 GLM stand-in.

## lead — `zai/glm-5.2` (또는 회사 Qwen3.6-35B-A3B)

| 옵션 | 근사치(predicted) | 근거 | live 실측 |
|---|---|---|---|
| temperature | 0.1 | 저무작위 — 근거 정확도 우선 | 대기 |
| steps | 30 | 할루시네이션 루프 방지 상한 | 대기 |
| top_p | ~0.9 | 모델 카드 일반적 | 대기 |
| repetition_penalty | ~1.1 | 반복 억제 근사치 | 대기 |
| variants(reasoning effort) | — | Qwen 지원 시 high/max — T2 실측 | 대기 |

## peer — `sensai-ollama/qwen3.5:9b` (또는 회사 Qwen3.5-9B)

| 옵션 | 근사치 | 근거 | live 실측 |
|---|---|---|---|
| temperature | 0.1 | 동일(근거 조사) | 대기 |
| steps | 15 | peer는 더 짧은 범위 | 대기 |

## 비고

- 근사치(predicted) — 출처: 모델 카드/공식 문서/경험. "더 좋아진 것 같다" 금지(측정).
- live endpoint(회사 Qwen vLLM/ollama)에서 실측 후 이 EXP 갱신(actual/delta).
- variants(reasoning effort) — Qwen 지원 여부 T2 실측(R2-test로 영향 측정).
- compaction 품질(소형 모델 peer 요약 근거 손실) — T2/R6 실측.
