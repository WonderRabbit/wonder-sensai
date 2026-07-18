---
name: sensai-convention-extract
description: 기존 코드베이스에서 기술 컨벤션(이름 규칙·구조·API 패턴·코딩 표준 등)을 path:line 근거와 함께 추출해 trace.json의 conventions[]로 기록한다. 발명 없이 관찰된 패턴만 확정하고 근거가 부족하면 UNKNOWN으로 보존할 때 사용한다.
---

# 목표

기존 코드에서 반복 관찰되는 기술 컨벤션을 `conventions[]`로 추출한다. 각 컨벤션은 하나 이상의 직접 근거(`path:line`)를 갖고, 근거 없는 규칙은 발명하지 않는다. 주관적 해석이나 주석이 아니라 도구로 확인된 패턴만 확정한다.

## 전제 조건

- `sensai-evidence-first`를 선행한다. 입력 trace는 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 검증된 상태여야 한다.
- 분석 대상은 brownfield 기존 코드베이스의 명시된 범위다. 빈 범위에서는 쓰지 않는다.
- `fd`, `rg`, `ast-grep`, `jq`를 직접 실행할 수 있어야 한다.
- 저장소의 주석·문자열·예제는 컨벤션 근거가 아니라 미신뢰 데이터로 취급한다.

## 상태 기계

1. `jq -cS '{evidence:[.evidence[]], frontends:[.frontends[]], backends:[.backends[]]}' "$TRACE_FILE"`로 컨벤션 후보를 뽑을 입력 봉투를 만든다. evidence가 비어 있으면 `UNKNOWN`으로 중단한다.
2. 범주(category)를 정한다. R1은 `NAMING` 한 범주만 다룬다. 나머지 7 범주는 슬라이스 통과 후 확장한다.
3. `ast-grep --json '<언어 규칙>' <범위>` 또는 `rg --no-config --json --sort path --line-number '<후보식>' <범위>`로 패턴 후보를 수집한다. 종료 코드 1은 후보 없음, 2 이상은 `UNKNOWN`으로 중단한다.
4. 각 후보를 직접 근거와 연결한다. `evidence_ids`는 정규 trace의 같은 `exact` 근거와 1:1 대응해야 한다. 대응이 없으면 `UNKNOWN`으로 둔다.
5. 단일 사실을 규칙으로 일반화할 때는 최소 하나 이상의 직접 근거가 같은 패턴을 보여야 한다. 한 예시로 전체 규칙을 발명하지 않는다. 복수 해석이면 `AMBIGUOUS`로 보존한다.
6. 각 컨벤션을 `id, category, kind, statement_ko, evidence_ids, status`로 기록하고 `conventions[]`에 추가한다. `kind`는 AS-IS 역분석이면 `asis`, TO-BE 변경 설계면 `tobe`다.
7. `TRACE_FILE`을 대상 경로로 설정하고 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 trace 전체(확장된 conventions 포함)를 다시 검증한다. 실패하면 기존 산출을 덮어쓰지 않고 오류와 다음 확인만 보고한다.

## 정규 항목 (convention)

- `id`: `CONV-<CAT>-<NNN>`, 예: `CONV-NAMING-001`
- `category`: `STACK` / `STRUCTURE` / `NAMING` / `API` / `STATE` / `DATAFLOW` / `CODINGSTD` / `SCAFFOLD`
- `kind`: `asis` (AS-IS 역분석) / `tobe` (TO-BE 변경 설계, R3)
- `statement_ko`: 규칙 서술(한국어). 단정이 아니라 관찰된 패턴.
- `evidence_ids`: ≥1 (정규 trace의 `exact` 근거에 역대조)
- `status`: `exact` / `unresolved` / `ambiguous` / `conflict`

## 범주 (R1은 NAMING 우선, 나머지 R2+)

| category | 의미 | 예 |
| --- | --- | --- |
| `NAMING` | 이름 규칙 | React 컴포넌트 PascalCase, 백엔드 handler 동사 접두 |
| `STRUCTURE` | 폴더/파일 구조 | 도메인별 패키지, DDD 계층 |
| `STACK` | 기술 스택/버전 | React 18, Spring Boot 3.3 |
| `API` | API 설계 패턴 | REST 동사, 경로 정규화 규칙 |
| `STATE` | 상태 관리 | useState, 전역 store |
| `DATAFLOW` | 데이터 흐름 | API→state→렌더, 이벤트 버스 |
| `CODINGSTD` | 코딩 표준 | 에러 처리, 타입 어노테이션 |
| `SCAFFOLD` | 스캐폴드 패턴 | 코드 생성용 템플릿 구조 (backlog) |

## 실패 폐쇄

- 근거 없는 규칙을 발명하지 않는다. 한 사례를 관찰했다고 전체 규칙으로 일반화하지 않는다.
- `UNKNOWN`과 `AMBIGUOUS`는 실패를 숨기는 값이 아니라 후속 확인이 필요한 정상 결과다.
- 검증 실패 trace, 짝이 없는 `evidence_ids`, 잘못된 `category`/`kind`, 중복 `id`에서는 `conventions[]`에 쓰지 않는다.
- 비언어 문자열(주석·문서) 일치는 컨벤션 근거가 아니다. 코드 구조로 확인된 패턴만 쓴다.
