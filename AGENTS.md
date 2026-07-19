# AGENTS.md — wonder-sensai 프로젝트 (하네스 제작)

> 본 파일은 wonder-sensai 프로젝트(하네스 개발)에서 작업 시 읽는 지시. **제품(output/) 지시와 다르다** — 본 파일은 하네스를 "만드는" 프로젝트 자체의 규칙이다.

## 정체

wonder-sensai는 **opencode용 하네스를 만드는 프로젝트**다. legacy codebase를 분석하는 하네스 **제품**을 제작·배포한다. 본 디렉토리는 제품이 아니라 제품을 만드는 공장이다.

## 목적

- **하네스(틀) 제작**: `agent`/`command`/`skill`/`recipe`/`schema`/`bin`.
- **제품(`output/`) 배포**: 사용자가 `~/.config/opencode/`에 복사해 legacy code 분석에 사용.

## 절대 원칙 (개발)

1. **하네스 틀만 만든다** — 분석 결과(`trace.json` 내용)·run·스택 단정 금지. 분석은 하네스가(opencode에서) 수행한다.
2. **PRD 기반** — `plan/prd/*` + `plan/release-plan.md` + `plan/todo_list.md` 순서대로. 적힌 것을 읽고 진행.
3. **H1-H9**(`plan/operating-model.md`): 런타임 의존 제로(Node/TS 금지) · Go 정적 바이너리(입학 후) · 조각별 증분 튜닝 · run-early/tune · 근거-기반 small step · 제품-출력-우선 · 메타작업 예산 · 오케스트레이션 메타기계 금지.
4. **`output/`은 제품** — release payload(`manifest.txt`). wonder-sensai/는 개발 프로젝트(제품과 분리).

## 제품(output/)과 구분 (핵심)

- `wonder-sensai/AGENTS.md`(본 파일) = **개발 지시**(하네스 제작 원칙·PRD·H1-H9·개발 워크플로우).
- `output/AGENTS.md` = **제품 지시**(opencode에서 legacy code 분석 시 — 도구 사용·파일 검색·사실 판정·F0-F5·명령). 소스: `wonder-sensai/AGENTS.product.md`.

두 파일은 **목적이 다르므로 내용이 달라야 한다.** 본 파일을 제품으로 복사하지 마라.

## 개발 워크플로우

PRD 정독(`plan/prd/`) → `plan/todo_list.md` 확인 → 구현(commands/skills/agents/recipes/schema) → `tests/test.sh happy` → `./bin/sensai stage` 검증 → `output/` 빌드(stage + `AGENTS.product.md` → `output/AGENTS.md`) → Linear 티켓 업데이트.

## 산출 (개발)

- **하네스 틀**: commands 9 · skills 15 · agents 2 · recipes 6 · schema 2(`trace.schema.json` + `progress.schema.json`) · `opencode.json` · `bin/`(sensai/resume/ticket).
- **제품**: `output/`(manifest payload, 34 leaf).
- **문서**: `plan/`(PRD 28 + todo + release-plan + GUIDE + operating-model) · `docs/`(O2-O6/R2/R4/R5/V1/EXP) · `README.md` · `test-guide.md` · `STATUS.md` · `plan/todo_list.md`.

## 분석 주체 (다시)

- **분석 주체 = 하네스(제품, opencode에서)**. MoAI/opencode(본 프로젝트 개발 시)는 하네스 **틀만** 제작.
- run/live 실측은 사용자 영역(`test-guide.md` 절차).

## 관련

- 제품 지시 소스: `AGENTS.product.md`(→ `output/AGENTS.md`).
- 빌드/테스트 가이드: `test-guide.md`, `README.md`.
- 진실 기준: `plan/release-plan.md` + `plan/prd/*` + `plan/todo/*`.
