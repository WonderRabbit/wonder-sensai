# UI 정의서: 주문 목록

## 화면 목적

주문 목록을 조회해 표시한다. 업무 의미는 내부 명세 `REQ-0001`의 범위만 사용한다. (`E-REACT-001` @ `fixtures/legacy-project/App.jsx:7`; `E-REACT-004` @ `fixtures/legacy-project/App.jsx:9`; `E-SPEC-001` @ `fixtures/legacy-project/spec.md:7`)

## 진입 경로

`/orders`로 진입해 `OrdersPage`를 표시한다. (`E-REACT-002` @ `fixtures/legacy-project/App.jsx:13`)

## 화면 요소

- 화면 컴포넌트: `OrdersPage` (`E-REACT-003` @ `fixtures/legacy-project/App.jsx:4`)
- 제목: `주문 목록` (`E-REACT-004` @ `fixtures/legacy-project/App.jsx:9`)
- 주문 식별자와 이름을 목록으로 표시한다. (`E-REACT-004` @ `fixtures/legacy-project/App.jsx:9`)

## 입력 폼과 검증

`UNKNOWN`: 입력 폼과 입력 검증 근거가 없다. 다음 확인은 `OrdersPage`가 가져오는 하위 컴포넌트 범위다.

## 상호작용

화면 진입 시 `GET /api/orders`를 호출한다. (`E-REACT-001` @ `fixtures/legacy-project/App.jsx:7`)

## 상태 읽기와 변경

`orders` 상태를 선언하고 응답 본문으로 갱신한 뒤 목록에 표시한다. (`E-REACT-005` @ `fixtures/legacy-project/App.jsx:5`; `E-REACT-001` @ `fixtures/legacy-project/App.jsx:7`; `E-REACT-004` @ `fixtures/legacy-project/App.jsx:9`)

## API 연계

`J-ORDER-001`은 React와 Vert.x의 `GET /api/orders`를 `one_to_one/exact`로 연결한다. (`E-REACT-001` @ `fixtures/legacy-project/App.jsx:7`; `E-VERTX-001` @ `fixtures/legacy-project/ApiVerticle.java:8`; `E-OPENAPI-001` @ `fixtures/legacy-project/openapi.yaml:7`)

## 권한과 접근 제어

`UNKNOWN`: UI 및 백엔드 권한 검사 근거가 없다. 다음 확인은 라우터 앞단과 인증 미들웨어다.

## 오류·빈 상태·접근성

`UNKNOWN`: 오류, 빈 상태, 재시도, 접근성 동작 근거가 없다. 다음 확인은 응답 실패 처리와 접근성 속성이다.

## 요구사항 연결

- `REQ-0001`: 주문 목록 화면은 `GET /api/orders`를 호출해야 한다. (`E-SPEC-001` @ `fixtures/legacy-project/spec.md:7`)

## 근거 목록

- `E-REACT-001` @ `fixtures/legacy-project/App.jsx:7`
- `E-REACT-002` @ `fixtures/legacy-project/App.jsx:13`
- `E-REACT-003` @ `fixtures/legacy-project/App.jsx:4`
- `E-REACT-004` @ `fixtures/legacy-project/App.jsx:9`
- `E-REACT-005` @ `fixtures/legacy-project/App.jsx:5`
- `E-VERTX-001` @ `fixtures/legacy-project/ApiVerticle.java:8`
- `E-OPENAPI-001` @ `fixtures/legacy-project/openapi.yaml:7`
- `E-SPEC-001` @ `fixtures/legacy-project/spec.md:7`

## 미확인 사항과 다음 확인

- `UNKNOWN`: 오류·빈 상태·접근성 정책. 실패 응답 처리와 UI 상태 분기를 확인한다.
- `UNKNOWN`: 권한 정책. Vert.x 라우터 앞단과 React 라우트 가드를 확인한다.
