---
name: sensai-spec-evidence
description: IETF RFC와 일반 요구사항 명세에서 BCP 14 규범 문장을 추출해 근거 연결 요구사항으로 정규화한다. MUST·SHOULD·MAY 계열의 의무와 금지를 정확한 절·path:line으로 추적할 때 사용한다.
---

# 목표

규범 문장과 설명·예시를 분리하고, 원문 절과 행을 잃지 않은 요구사항 목록을 만든다.

## 전제 조건

- 입력은 IETF RFC 또는 일반 요구사항 명세 파일 20개 이하이다.
- 한 번에 규범 후보 200개 이하를 처리한다.
- `fd`, `rg`, `mdq`, `jq`, 필요 시 `yq`를 사용할 수 있어야 한다.

## 상태 기계

1. `fd --type f --extension md --extension txt --extension yaml --extension yml --extension json --print0 . <명세루트>`로 입력을 고정한다. 문서 종류와 버전을 확인하지 못하면 중단한다.
2. Markdown 절은 `mdq --output json '#{2} *' <명세.md>`로 읽고, 필요한 절 존재 여부는 `mdq --quiet '#{2} ^"<절>"$' <명세.md>`로 확인한다.
3. `rg --no-config --json --sort path --line-number '\b(MUST NOT|SHALL NOT|SHOULD NOT|NOT RECOMMENDED|MUST|REQUIRED|SHALL|SHOULD|RECOMMENDED|MAY|OPTIONAL)\b' <명세>`로 대문자 후보와 정확한 행을 수집한다.
4. 문서가 BCP 14 의미를 선언했는지 확인한다. 선언이 없으면 대문자 일치를 자동 규범으로 확정하지 않고 `UNKNOWN`으로 둔다. 코드 블록·예시·인용은 별도 후보로 분리한다.
5. 한 요구사항은 `id, source, section, keyword, statement_ko, evidence_ids`로 기록한다. `REQUIRED/SHALL`은 `MUST`, `RECOMMENDED`는 `SHOULD`, `OPTIONAL`은 `MAY`로 정규화한다. 부정형은 문장 자체에 금지 의미를 그대로 보존한다.
6. 문장 범위와 예외·조건을 함께 보존한다. 같은 ID의 다른 문장, 상충 규범, 불명확한 주어 또는 범위는 `AMBIGUOUS`나 `conflict`로 두고 임의 통합하지 않는다.
7. YAML 명세는 `yq eval -o=json -I=0 '.' <명세.yaml>`로 읽고, JSON 결과는 `jq -cS '.'`로 정규화한다. 원문 행 근거를 별도로 유지한다.
8. `TRACE_FILE`을 대상 JSON 경로로 설정하고 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 전체 trace를 검증하기 전에는 UI나 시퀀스 입력으로 승인하지 않는다.

## 실패 폐쇄

- 소문자 표현, 단순 미래형, 설명적 권고를 BCP 14 요구사항으로 승격하지 않는다.
- 절·행·원문 조건이 없는 요구사항은 만들지 않는다.
- 출처가 둘 이상이면 하나를 대표로 고르지 말고 각각 보존하여 충돌 여부를 판정한다.
