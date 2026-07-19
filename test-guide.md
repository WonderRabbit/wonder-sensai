# test-guide — wonder-sensai 설치/세팅/테스트 가이드

> 하네스를 opencode에 설치하고 분석을 실행/검증하기까지의 절차. 분석 주체는 하네스(opencode + model)다.

## 1. 사전 설치 (로컬 도구)

- **opencode**(전역) — `~/.opencode/bin/opencode`. 확인: `opencode --version` (≥1.17.18).
- **CLI 도구**: `fd`, `rg`(ripgrep), `ast-grep`(`sg`), `jq`, `yq`(Mike Farah), `mdq`(yshavit), `mmdc`(mermaid-cli + Chromium).
- **확인**: `./bin/sensai doctor tools` → `TOOLS_ADMISSION=READY`.

## 2. 모델 / Provider 세팅

- **lead** `zai/glm-5.2`: opencode auth Z.AI — `opencode providers login` (또는 `~/.local/share/opencode/auth.json`에 zai credential).
- **peer** `sensai-ollama/qwen3.5:9b`: ollama 로컬 serve — `ollama serve` + `ollama pull qwen3.5:9b` (localhost:11434).
- **opencode.json**: `sensai-ollama` provider(localhost) + `model: zai/glm-5.2`(내장 zai) + `small_model: sensai-ollama/qwen3.5:9b`.
- **확인**: `./bin/sensai doctor models` → `MODEL_DISCOVERY=READY` (`zai/glm-5.2` + `sensai-ollama/qwen3.5:9b`).

## 3. 스테이징 / 설치

```sh
# 격리 stage(안전 — 대상 없는 경로)
stage="$(mktemp -d)/opencode"
./bin/sensai stage "$stage"                     # STAGE=PASS (34 leaf 복사 + SHA-256)

# 로드 검증
OPENCODE_CONFIG_DIR="$stage" opencode debug config   # model/agent/command 확인

# 전역 설치(선택 — 대상 없을 때만, exit 73=충돌)
./bin/sensai install "${HOME}/.config/opencode"
```

## 4. 테스트

```sh
# 회귀(happy) — payload 34 leaf + opencode load + recipe parse
./tests/test.sh happy
# 기대: PASS payload leaves=34 / PASS opencode-load agents=2 commands=9 skills=15 / PASS recipe parse

# doctor
./bin/sensai doctor tools    # TOOLS_ADMISSION=READY
./bin/sensai doctor models   # MODEL_DISCOVERY=READY
```

## 5. 분석 run (하네스가 코드 분석)

```sh
# opencode TUI — 격리 config로 실행
OPENCODE_CONFIG_DIR="$stage" opencode

# TUI 안에서:
/sensai/run scope=<코드베이스 root> goal="<미션 목표>"   # F0-F5 전체(HITL 컨펌)
# 또는 단계별
/sensai/analyze scope=<root> output=docs/analysis/trace.json
```

**주의**: GLM 응답 시간. 큰 범위(전체 코드베이스)는 timeout 위험 → 도메인/디렉토리 단위로 좁혀 run.

## 6. 산출 검증

```sh
# trace 무결성
jq -e -f recipes/trace.jq docs/analysis/trace.json    # exit 0
# UI provenance
jq -e --arg kind ui --rawfile artifact docs/analysis/ui-definition.ko.md \
  -f recipes/provenance.jq docs/analysis/trace.json    # exit 0
# convention 확인
jq '.conventions[] | {id, category, statement_ko}' docs/analysis/trace.json
```

## 7. 다음 작업 전환 조건

| 현재 | 통과 조건 | 다음 |
|---|---|---|
| 설치/세팅 | doctor tools/models READY + stage PASS | 테스트(happy) |
| 테스트 | `./tests/test.sh happy` PASS | 분석 run |
| 분석 run | `/sensai/analyze` → `trace.json` 산출 + `trace.jq` exit 0 | 산출 검증 + 사람 AS-IS accept |
| AS-IS accept(hard) | F3 사람 컨펌 | TO-BE(`/sensai/change-design`) |
| TO-BE | `/sensai/deliver` → 5 산출 + `provenance.jq` exit 0 | 미션 accept(F5) |
| live 실측(회사 Qwen) | run 성공 후 metric 확보 | R1-model 옵션 actual / R2-test delta / O3 입학 threshold 확정 |

## 8. 문제 조치

| 증상 | 원인 | 조치 |
|---|---|---|
| doctor tools BLOCKED | opencode/CLI 미설치 또는 PATH | `~/.opencode/bin` PATH 추가, CLI 설치 |
| doctor models BLOCKED | zai auth 없음 / ollama 미serve | `opencode providers login`, `ollama serve` |
| stage exit 73 | 대상 경로 존재 | 다른(absent) 경로 |
| run 5분 timeout | GLM 응답 지연 / 범위 큼 | scope 좁히기(도메인 단위) / timeout 연장 / TUI 직접 |
| trace.jq exit≠0 | 원장 필드/근거 위반 | 로그 확인, 위반 항목 수정 후 재검증 |
