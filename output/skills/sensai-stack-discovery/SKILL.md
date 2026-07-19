---
name: sensai-stack-discovery
description: 매니페스트(package.json/go.mod/pom.xml/requirements.txt/Cargo.toml 등)와 프레임워크 마커로 스택+버전을 식별한다(01 A1). 매니페스트 근거가 없으면 UNSUPPORTED, 강제 매핑 금지.
---

# 목표

root/scope에서 매니페스트와 프레임워크 마커로 사용 기술과 버전을 식별한다(01 §5 A1). 최소 하나의 언어/런타임이 매니페스트 근거로 입증되어야 통과.

## 절차

1. `fd`/`rg`로 매니페스트 파일 탐지 — `package.json`/`go.mod`/`pom.xml`/`requirements.txt`/`Cargo.toml`/`build.gradle` 등.
2. `jq`/`yq`로 의존성·버전 추출(`path:line` 근거).
3. 프레임워크 마커(설정 파일·의존성 이름·디렉토리 규칙) 확인.
4. 식별된 스택+버전 목록(각 근거) 또는 `UNSUPPORTED`.

## 근거 정책 (불변)

매니페스트 근거 강제. 근거 없는 스타 승격 금지 → `UNSUPPORTED`. 이름 유사도/가장 가까운 후보로 매핑하지 않는다.
