---
name: sensai-ui-definition
description: 검증된 React 추적과 요구사항을 한글 UI 정의서로 투영한다. 화면 목적, 구성, 상호작용, 상태, API, 검증, 접근성, 근거와 미확인 사항을 발명 없이 문서화할 때 사용한다.
---

# 목표

정규 trace JSON을 사람이 검토할 수 있는 한글 UI 정의서로 투영한다. Markdown은 JSON의 뷰이며 별도 진실 원천이 아니다.

## 전제 조건

- `TRACE_FILE`을 대상 JSON 경로로 설정하고 `jq -e -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/trace.jq" "$TRACE_FILE"`로 입력 trace 전체를 검증해야 한다.
- 한 문서는 하나의 `frontends[].id`만 다룬다.
- 선택한 화면의 직접 근거와 요구사항 참조가 없으면 문서를 만들지 않는다.
- `jq`, `mdq`, `rg`를 사용할 수 있어야 한다.

## 상태 기계

1. `jq -e --arg id '<UI-ID>' '.frontends[] | select(.id == $id)' <trace.json>`로 화면이 정확히 하나인지 확인한다. 0개면 `UNKNOWN`, 2개 이상이면 `AMBIGUOUS`로 중단한다.
2. `jq -cS --arg id '<UI-ID>' '{screen:(.frontends[]|select(.id==$id)), requirements:[.requirements[]], evidence:[.evidence[]], unknowns:[.unknowns[]]}' <trace.json>`으로 제한된 입력 봉투를 만든다.
3. 확인된 필드만 아래 한글 제목에 투영한다. 원본 컴포넌트·경로·메서드·식별자는 번역하거나 다시 이름 짓지 않는다.
4. 근거 없는 업무명은 만들지 않고 `미확인 화면 (<component>)`으로 쓴다. 빈 상태, 오류, 재시도, 검증, 권한, 접근성 근거가 없으면 `UNKNOWN`과 다음 확인을 적는다.
5. 모든 사실 뒤에 `` `E-ID` @ `전체/path:line` `` 쌍을 붙인다. `REQ-ID`와 `J-ID`는 이 형식에 넣지 않는다. 한 사실에 복수 후보가 있으면 `AMBIGUOUS` 목록으로 모두 보존한다.
6. 모든 근거 ID와 `path:line` 토큰을 정규 trace의 같은 `exact` 근거와 1:1 대응시키고, 모든 `REQ-ID`와 `J-ID`가 정규 trace의 요구사항과 `exact` join인지 확인한다. `UI_FILE`을 산출물 경로로 설정하고 `jq -e --arg kind ui --rawfile artifact "$UI_FILE" -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/recipes/provenance.jq" "$TRACE_FILE"`을 실행한다.
7. `mdq --quiet '#{2} ^"화면 목적"$' "$UI_FILE"`, `mdq --quiet '#{2} ^"화면 요소"$' "$UI_FILE"`, `mdq --quiet '#{2} ^"상호작용"$' "$UI_FILE"`를 포함해 모든 필수 제목을 검사한다. `rg --no-config -n 'UNKNOWN|AMBIGUOUS' "$UI_FILE"` 결과도 검토한다.

## 필수 한글 제목

```markdown
# UI 정의서: <근거 기반 이름>
## 화면 목적
## 진입 경로
## 화면 요소
## 입력 폼과 검증
## 상호작용
## 상태 읽기와 변경
## API 연계
## 권한과 접근 제어
## 오류·빈 상태·접근성
## 요구사항 연결
## 근거 목록
## 미확인 사항과 다음 확인
```

## 정규 항목

- 요소: `element_id, source_text, control_kind, state, interaction, validation, accessibility, requirement_ids, evidence_ids, status`
- `element_id`는 ASCII 대문자·숫자·`_`·`-`만 사용하며 소스 항목과 안정적으로 대응한다.
- 상태와 전이는 직접 관찰된 조건·handler·state write가 있을 때만 쓴다.

## 실패 폐쇄

- 검증 실패 trace, 짝이 없거나 서로 바뀐 근거 ID·`path:line`, 미승인 요구사항, 빈 화면 범위에서는 새 문서를 쓰지 않는다.
- 디자인, 문구, 오류 정책, 접근성 동작을 일반 상식으로 보충하지 않는다.
