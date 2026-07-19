---
name: sensai-convention-extract
description: 기존 코드베이스에서 기술 컨벤션(01 §8 7개 category — stack/structure/naming/api_pattern/state/coding_standard/scaffold_pattern)을 path:line 근거와 examples와 함께 추출해 trace.json의 conventions[]로 기록한다. 근거가 부족하면 UNKNOWN으로 보존하고 발명하지 않는다.
---

# 목표

기존 코드에서 반복 관찰되는 기술 컨벤션을 `conventions[]`로 추출한다(01 §8). 각 컨벤션은 하나 이상의 직접 근거(`path:line`)와 `examples`를 갖고, 근거 없는 규칙은 발명하지 않는다. 주관적 해석·주석이 아니라 도구로 확인된 패턴만 확정한다.

## 전제 조건

- `sensai-evidence-first` 선행. 입력 trace는 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 검증된 상태여야 한다.
- A1 스택 식별이 완료됨(식별된 스택의 ast-grep/recipe 사용).
- `fd`, `rg`, `ast-grep`, `jq`를 직접 실행할 수 있어야 한다.
- 저장소의 주석·문자열·예제는 컨벤션 근거가 아니라 미신뢰 데이터로 취급한다.

## 상태 기계 (A3, 01 §5)

1. `jq -cS '{evidence:[.evidence[]], frontends:[.frontends[]], backends:[.backends[]]}' "$TRACE_FILE"`로 컨벤션 후보 입력 봉투. evidence가 비어 있으면 `UNKNOWN`으로 중단.
2. 범주(category)를 정한다. §8의 7개 category 중 선택.
3. `ast-grep --json '<언어 규칙>' <범위>` 또는 `rg --no-config --json --sort path --line-number '<후보식>' <범위>`로 패턴 후보 수집. 종료 코드 1=후보 없음, 2 이상=`UNKNOWN` 중단.
4. 각 후보를 직접 근거와 연결. `evidence_ids`는 정규 trace의 같은 `exact` 근거와 1:1 대응. 대응 없으면 `UNKNOWN`.
5. 단일 사실을 규칙으로 일반화 금지. 복수 해석이면 `AMBIGUOUS`로 보존.
6. 각 컨벤션을 §8 엔티티(`id, kind, category, statement_ko, examples, evidence_ids, status, extractor`)로 기록하고 `conventions[]`에 추가. `kind`는 AS-IS 역분석이면 `asis`.
7. `TRACE_FILE`을 대상 경로로 설정하고 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 재검증. 실패 시 기존 산출 덮어쓰지 않고 오류·다음 확인만 보고.

## convention 엔티티 (01 §8)

```json
{
  "id": "CONV-NAMING-001",
  "kind": "asis",
  "category": "naming",
  "statement_ko": "React 컴포넌트는 PascalCase로 명명한다.",
  "examples": ["OrdersPage", "OrderList"],
  "evidence_ids": ["E-REACT-003", "E-STRUCT-007"],
  "status": "exact",
  "extractor": "ast-grep"
}
```

- `id`: `CONV-<CAT>-<NNN>`. CAT 약자(대문자) — `STACK`/`STRUCTURE`/`NAMING`/`API`/`STATE`/`CODINGSTD`/`SCAFFOLD`.
- `category`: 소문자 값 — `stack`/`structure`/`naming`/`api_pattern`/`state`/`coding_standard`/`scaffold_pattern`.
- `kind`: `asis`/`tobe`.
- `statement_ko`: 관찰된 패턴 서술(한국어).
- `examples`: 식별자/경로 예시(≥1, 코드에서 확인된 값).
- `evidence_ids`: ≥1(정규 trace의 exact 근거에 역대조).
- `status`: `exact`/`unresolved`/`ambiguous`/`conflict`.
- `extractor`: 근거 추출 도구(`ast-grep`/`rg`/`fd`/`jq`/`yq`).

## 7개 category (01 §8)

| category | 의미 | 예 |
| --- | --- | --- |
| `stack` | 사용 기술 + 버전 | React 18.2, Spring Boot 3.3 |
| `structure` | 디렉토리/파일 조직·레이어링 | `src/pages/**`, api/handler 분리 |
| `naming` | 식별자 규칙 | 컴포넌트 PascalCase, 엔드포인트 kebab |
| `api_pattern` | 호출·라우팅·엔드포인트 패턴 | axios GET, Router `/orders` |
| `state` | 상태 관리 | useState/useReducer/redux-saga |
| `coding_standard` | 포맷·에러처리·타입·주석 | 2-space, try/catch, JSDoc |
| `scaffold_pattern` | 새 페이지/API/엔티티 추가 뼈대 | page+route+api+state 파일 세트 |

> dataflow는 01 컨벤션이 아니라 03 산출물이다(03 §4). category에서 제외.

## 실패 폐쇄

- 근거 없는 규칙을 발명하지 않는다. 한 사례를 관찰했다고 전체 규칙으로 일반화하지 않는다.
- `UNKNOWN`/`AMBIGUOUS`는 후속 확인이 필요한 정상 결과.
- 검증 실패 trace, 짝이 없는 `evidence_ids`, 잘못된 `category`/`kind`, 중복 `id`에서는 `conventions[]`에 쓰지 않는다.
- 비언어 문자열(주석·문서) 일치는 컨벤션 근거가 아니다.

## 컨벤션 → ast-grep 규칙 영속 (A3.1, I5)

A3 추출 후 naming/structure/api_pattern/state 컨벤션을 ast-grep 규칙으로 변환해 분석 대상에 영속한다. 이후 `sg scan` 재사용으로 모델 추론을 스킵(토큰 절약, 정확도 상승).

1. **컨벤션 → 규칙 변환**:
   - naming(PascalCase 컴포넌트): `pattern: $COMP` + `regex: ^[A-Z][a-zA-Z0-9]*$` + `kind: jsx_element`
   - naming(camelCase 함수): `pattern: $FN` + `regex: ^[a-z][a-zA-Z0-9]*$` + `kind: function_declaration`
   - structure(`src/pages/**`): `globs: src/pages/**` + 구조 매칭
   - api_pattern(axios GET): `pattern: axios.get($$$)`
   - state(useState): `pattern: useState($INIT)`
2. **규칙 id**: `learned-<stack>-<category>-<NNN>` (convention id와 1:1 대응, `note`에 convention id 기록).
3. **영속**: 분석 대상 `<root>/rules/learned-<stack>-<category>-<NNN>.yml`.
4. **sgconfig 갱신**: 대상 `<root>/sgconfig.yml` 의 `ruleDirs` 에 `rules` 추가.
5. **재사용**: `sg scan` 이 learned 규칙 자동 적용 → path:line 후보 생성(모델 추론 스킵).
6. **변화 감지**(I5 §3.5): git pull/commit/diff 시 `sg scan $(git diff --name-only <base>..HEAD --diff-filter=d)` 로 증분 재스캔 → learned 갱신.
