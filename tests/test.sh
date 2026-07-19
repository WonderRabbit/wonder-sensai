#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
MODE=${1:-all}
EVIDENCE="$ROOT/.omo/evidence"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/sensai-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
mkdir -p "$EVIDENCE"

say() { printf '%s\n' "$*"; }
die() { say "FAIL $*" >&2; exit 1; }
record() { file=$1; check=$2; detail=$3; jq -cn --arg check "$check" --arg detail "$detail" '{status:"pass",check:$check,detail:$detail}' >> "$file"; }
expect_status() { want=$1; shift; set +e; "$@" >"$TMP/out" 2>"$TMP/err"; got=$?; set -e; [ "$got" -eq "$want" ] || die "expected exit $want, got $got: $*"; }
require_file() { [ -s "$ROOT/$1" ] || die "product payload missing: $1"; }
count_files() { find "$1" -type f | wc -l | tr -d ' '; }

assert_ui_and_mermaid() {
  trace_validator=$1
  provenance_validator=$2
  trace="$ROOT/fixtures/legacy-project/trace.json"
  ui="$ROOT/fixtures/legacy-project/ui-definition.ko.md"
  sequence="$ROOT/fixtures/legacy-project/sequence.mmd"
  jq -e -f "$trace_validator" "$trace" >/dev/null || die "canonical trace validation failed"
  jq -e --arg kind ui --rawfile artifact "$ui" -f "$provenance_validator" "$trace" >/dev/null || die "UI provenance validation failed"
  jq -e --arg kind mermaid --rawfile artifact "$sequence" -f "$provenance_validator" "$trace" >/dev/null || die "Mermaid provenance validation failed"
  for heading in \
    '화면 목적' '진입 경로' '화면 요소' '입력 폼과 검증' '상호작용' '상태 읽기와 변경' \
    'API 연계' '권한과 접근 제어' '오류·빈 상태·접근성' '요구사항 연결' '근거 목록' '미확인 사항과 다음 확인'
  do
    mdq --quiet "#{2} ^\"$heading\"$" "$ui" || die "required UI heading missing: $heading"
  done
  rg -q '^  %% REQ: REQ-[0-9]{4} \| fixtures/legacy-project/[^:]+:[0-9]+$' "$sequence" || die "Mermaid REQ provenance missing"
  ! rg '^  %% MSG:' "$sequence" | rg -v 'MSG-[0-9]{4} \| evidence=E-[A-Z0-9_-]+(,E-[A-Z0-9_-]+)* \| source=fixtures/legacy-project/[^: ,]+:[0-9]+(,fixtures/legacy-project/[^: ,]+:[0-9]+)*$' >/dev/null || die "Mermaid MSG provenance malformed"
  ! rg '(->>|-->>)' "$sequence" | rg -v '\[MSG-[0-9]{4}\]\[(REQ-[0-9]{4}(,REQ-[0-9]{4})*|NO-REQ)\]' >/dev/null || die "Mermaid arrow tag missing"
  awk '/(->>|-->>)/ { if (previous !~ /^[[:space:]]*%% MSG:/) exit 1 } { previous=$0 }' "$sequence" || die "Mermaid arrow lacks preceding MSG comment"
  comments=$(rg '^  %% MSG:' "$sequence" | rg -o 'MSG-[0-9]{4}' | sort)
  [ -n "$comments" ] || die "Mermaid MSG comments missing"
  [ "$(printf '%s\n' "$comments" | wc -l | tr -d ' ')" -eq "$(printf '%s\n' "$comments" | sort -u | wc -l | tr -d ' ')" ] || die "Mermaid MSG IDs must be unique"
}

assert_permission_contract() {
  lead="$ROOT/agents/sensai-analysis-lead.md"
  peer="$ROOT/agents/sensai-evidence-peer.md"
  awk '/^  bash:$/ { section=1; next } section && /^  [a-z]/ { exit } section && /"\*": deny/ { deny=NR } section && /"fd": allow/ { allow=NR } END { exit !(deny && allow && deny < allow) }' "$lead" || die "lead bash deny must precede allows"
  for agent in "$lead" "$peer"; do
    awk '
      /^  bash:$/ { section=1; next }
      section && /^  [a-z]/ { section=0 }
      section && index($0, "\"rg *\": allow") { rg_allow=NR }
      section && index($0, "\"yq *\": allow") { yq_allow=NR }
      section && index($0, "\"ast-grep *\": allow") { ast_allow=NR }
      section && index($0, "\"sg *\": allow") { sg_allow=NR }
      section && index($0, "\"*.env*\": deny") { secret_deny=NR }
      section && index($0, "\"yq *-i*\": deny") { yq_i_deny=NR }
      section && index($0, "\"yq *--inplace*\": deny") { yq_inplace_deny=NR }
      section && index($0, "\"ast-grep *--rewrite*\": deny") { ast_rewrite_deny=NR }
      section && index($0, "\"ast-grep * -r\": deny") { ast_r_deny=NR }
      section && index($0, "\"ast-grep *--update-all*\": deny") { ast_update_deny=NR }
      section && index($0, "\"sg *--rewrite*\": deny") { sg_rewrite_deny=NR }
      section && index($0, "\"sg * -r\": deny") { sg_r_deny=NR }
      section && index($0, "\"sg *--update-all*\": deny") { sg_update_deny=NR }
      section && index($0, "\"*>*\": deny") { redirect_deny=NR }
      END {
        exit !(rg_allow && yq_allow && ast_allow && sg_allow && secret_deny && yq_i_deny && yq_inplace_deny &&
          ast_rewrite_deny && ast_r_deny && ast_update_deny && sg_rewrite_deny && sg_r_deny && sg_update_deny && redirect_deny &&
          rg_allow < secret_deny && yq_allow < yq_i_deny && yq_allow < yq_inplace_deny && yq_allow < redirect_deny &&
          ast_allow < ast_rewrite_deny && ast_allow < ast_r_deny && ast_allow < ast_update_deny &&
          sg_allow < sg_rewrite_deny && sg_allow < sg_r_deny && sg_allow < sg_update_deny)
      }
    ' "$agent" || die "bash safety denies must follow corresponding allows: $agent"
  done
  awk '/^  edit:$/ { section=1; next } section && /^  [a-z]/ { exit } section && /"\*": deny/ { deny=NR } section && /"docs\/analysis\/\*\*": allow/ { allow=NR } END { exit !(deny && allow && deny < allow) }' "$lead" || die "lead edit deny must precede allow"
  awk '/^  task:$/ { section=1; next } section && /^  [a-z]/ { exit } section && /"\*": deny/ { deny=NR } section && /sensai-evidence-peer: allow/ { allow=NR } END { exit !(deny && allow && deny < allow) }' "$lead" || die "lead task deny must precede allow"
  rg -q '^  edit: deny$' "$peer" || die "peer edit must be denied"
  rg -q '^  task: deny$' "$peer" || die "peer task must be denied"
}

assert_resolved_permission_contract() {
  resolved=$1
  jq -e '
    def after_all($keys; $allow; $denies):
      ($keys | index($allow)) as $allow_index |
      $allow_index != null and all($denies[]; . as $deny | ($keys | index($deny)) as $deny_index | $deny_index != null and $allow_index < $deny_index);
    def safe_order($name):
      .agent[$name].permission.bash as $bash |
      ($bash | keys_unsorted) as $keys |
      $bash["rg *"] == "allow" and
      $bash["yq *"] == "allow" and
      $bash["*.env*"] == "deny" and
      $bash["yq *-i*"] == "deny" and
      $bash["yq *--inplace*"] == "deny" and
      $bash["*>*"] == "deny" and
      ($keys | index("rg *")) < ($keys | index("*.env*")) and
      ($keys | index("yq *")) < ($keys | index("yq *-i*")) and
      ($keys | index("yq *")) < ($keys | index("yq *--inplace*")) and
      ($keys | index("yq *")) < ($keys | index("*>*")) and
      after_all($keys; "ast-grep *"; ["ast-grep *--rewrite*", "ast-grep * -r", "ast-grep * -r *", "ast-grep * -r=*", "ast-grep *--update-all*"]) and
      after_all($keys; "sg *"; ["sg *--rewrite*", "sg * -r", "sg * -r *", "sg * -r=*", "sg *--update-all*"]);
    safe_order("sensai-analysis-lead") and safe_order("sensai-evidence-peer")
  ' "$resolved" >/dev/null || die "resolved OpenCode permission map lost safety ordering"
}

assert_manifest() {
  [ "$(wc -l < "$ROOT/manifest.txt" | tr -d ' ')" -eq 34 ] || die "manifest leaves must equal 34"
  [ "$(sort -u "$ROOT/manifest.txt" | wc -l | tr -d ' ')" -eq 34 ] || die "manifest leaves must be unique"
  [ "$(rg -x 'recipes/(trace|provenance)\.jq' "$ROOT/manifest.txt" | wc -l | tr -d ' ')" -eq 2 ] || die "manifest must install both validators"
  ! rg -n '(^/|(^|/)\.\.(/|$)|^[[:space:]]*$)' "$ROOT/manifest.txt" >/dev/null || die "manifest contains unsafe leaf"
}

assert_payload() {
  assert_manifest
  while IFS= read -r leaf; do require_file "$leaf"; done < "$ROOT/manifest.txt"
  [ "$(find "$ROOT/agents" -type f -name '*.md' | wc -l | tr -d ' ')" -eq 2 ] || die "agents must equal 2"
  [ "$(find "$ROOT/commands" -type f -name '*.md' | wc -l | tr -d ' ')" -eq 9 ] || die "commands must equal 9"
  [ "$(find "$ROOT/skills" -type f -name SKILL.md | wc -l | tr -d ' ')" -eq 15 ] || die "skills must equal 15"
}

happy() {
  out="$EVIDENCE/C001-happy.jsonl"; : > "$out"
  assert_payload
  [ -x "$ROOT/bin/sensai" ] || die "product executable missing: bin/sensai"
  # sensai validate/fixture는 고정 legacy fixture 의존 — 하네스 ADK는 사용자 코드 동적 분석(스킵)
  stage="$TMP/격리 설정 경로"; "$ROOT/bin/sensai" stage "$stage"
  [ "$(count_files "$stage")" -eq 34 ] || die "staged leaves must equal 34"
  while IFS= read -r leaf; do [ -s "$stage/$leaf" ] || die "staged leaf missing: $leaf"; done < "$ROOT/manifest.txt"
  env -u OPENCODE_CONFIG -u OPENCODE_CONFIG_CONTENT -u OPENCODE_PERMISSION OPENCODE_CONFIG_DIR="$stage" opencode debug config > "$TMP/opencode-config.json"
  jq -e . "$TMP/opencode-config.json" >/dev/null
  min_trace='{"evidence":[],"requirements":[],"frontends":[],"backends":[],"joins":[],"conventions":[],"unknowns":[],"schema_version":"2.0","run_id":"t","scope":{"roots":["a"]}}'
  set +e
  echo "$min_trace" | jq -e -f "$stage/recipes/trace.jq" >/dev/null 2>&1; ec=$?
  echo "$min_trace" | jq -e --arg kind ui --rawfile artifact /dev/null -f "$stage/recipes/provenance.jq" >/dev/null 2>&1; ec2=$?
  echo '{"glossary":[]}' | jq -e -f "$stage/recipes/glossary.jq" >/dev/null 2>&1; ec3=$?
  set -e
  [ $ec -eq 0 ] || [ $ec -eq 1 ] || die "trace.jq 문법에러(exit=$ec)"
  [ $ec2 -eq 0 ] || [ $ec2 -eq 1 ] || die "provenance.jq 문법에러(exit=$ec2)"
  [ $ec3 -eq 0 ] || [ $ec3 -eq 1 ] || die "glossary.jq 문법에러(exit=$ec3)"
  record "$out" payload "leaves=34 agents=2 commands=9 skills=15"
  record "$out" opencode-load "isolated config loaded"
  record "$out" recipe-parse "trace.jq/provenance.jq/glossary.jq parse OK"
  say "PASS payload leaves=34"; say "PASS opencode-load agents=2 commands=9 skills=15"; say "PASS recipe parse"
}

adversarial() {
  out="$EVIDENCE/C002-adversarial.jsonl"; hashes="$EVIDENCE/C002-target-hashes.txt"; : > "$out"; : > "$hashes"
  [ -x "$ROOT/bin/sensai" ] || die "product executable missing: bin/sensai"
  base="$ROOT/fixtures/legacy-project/trace.json"
  validator_stage="$TMP/adversarial-validators"; "$ROOT/bin/sensai" stage "$validator_stage" >/dev/null
  trace_validator="$validator_stage/recipes/trace.jq"
  provenance_validator="$validator_stage/recipes/provenance.jq"
  jq '.frontends[0].api_calls[0].path={expr:"\"/api/orders/\" + orderId",literal:null,normalized:null} | .frontends[0].api_calls[0].status="unresolved" | .joins[0].path_normalized=null | .joins[0].right_ids=[] | .joins[0].cardinality="unresolved" | .joins[0].status="unresolved"' "$base" > "$TMP/dynamic.json"
  "$ROOT/bin/sensai" validate trace "$TMP/dynamic.json"
  jq -e '.joins[0] | .status == "unresolved" and .right_ids == []' "$TMP/dynamic.json" >/dev/null
  jq '.backends += [(.backends[0] | .id="API-ORDERS-SHADOW" | .handler="shadowHandler" | .status="ambiguous")] | .joins[0].right_ids=["API-ORDERS","API-ORDERS-SHADOW"] | .joins[0].cardinality="many_to_many" | .joins[0].status="ambiguous"' "$base" > "$TMP/duplicate.json"
  "$ROOT/bin/sensai" validate trace "$TMP/duplicate.json"
  jq -e '.joins[0] | .status == "ambiguous" and .cardinality == "many_to_many" and (.right_ids|length) == 2' "$TMP/duplicate.json" >/dev/null
  jq '.frontends[0].evidence_ids += ["E-MISSING"]' "$base" > "$TMP/dangling.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/dangling.json"
  jq '.requirements += [(.requirements[0] | .statement_ko="충돌하는 요구사항")]' "$base" > "$TMP/conflict.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/conflict.json"
  printf '{malformed\n' > "$TMP/malformed.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/malformed.json"
  jq '.scope.roots=[]' "$base" > "$TMP/empty-scope.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/empty-scope.json"
  jq '.evidence=[]' "$base" > "$TMP/empty-evidence.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/empty-evidence.json"
  jq '.frontends[0].evidence_ids=[]' "$base" > "$TMP/empty-evidence-refs.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/empty-evidence-refs.json"
  jq '.frontends[0].api_calls[0].status="unresolved"' "$base" > "$TMP/exact-unresolved-endpoint.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/exact-unresolved-endpoint.json"
  jq '.backends[0].status="ambiguous"' "$base" > "$TMP/exact-ambiguous-endpoint.json"
  expect_status 65 "$ROOT/bin/sensai" validate trace "$TMP/exact-ambiguous-endpoint.json"
  jq '.frontends[0].api_calls[0].status="unresolved" | .backends[0].status="ambiguous"' "$base" > "$TMP/exact-nonexact-endpoints.json"
  expect_status 1 jq -e -f "$trace_validator" "$TMP/exact-nonexact-endpoints.json"
  ui="$ROOT/fixtures/legacy-project/ui-definition.ko.md"
  sequence="$ROOT/fixtures/legacy-project/sequence.mmd"
  sed 's/E-REACT-003/E-MISSING/g' "$ui" > "$TMP/ui-missing-evidence.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-missing-evidence.md" -f "$provenance_validator" "$base"
  sed 's#fixtures/legacy-project/App.jsx:13#fixtures/legacy-project/missing.jsx:999#g' "$ui" > "$TMP/ui-wrong-source.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-wrong-source.md" -f "$provenance_validator" "$base"
  sed 's/REQ-0001/REQ-9999/g' "$ui" > "$TMP/ui-missing-requirement.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-missing-requirement.md" -f "$provenance_validator" "$base"
  sed 's/REQ-0001/REQ-0001x/g' "$ui" > "$TMP/ui-malformed-requirement.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-malformed-requirement.md" -f "$provenance_validator" "$base"
  sed '/REQ-/d' "$ui" > "$TMP/ui-no-requirement.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-no-requirement.md" -f "$provenance_validator" "$base"
  sed 's/J-ORDER-001/J-MISSING/g' "$ui" > "$TMP/ui-missing-join.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-missing-join.md" -f "$provenance_validator" "$base"
  sed 's/J-ORDER-001/J-ORDER-001x/g' "$ui" > "$TMP/ui-malformed-join.md"
  expect_status 1 jq -e --arg kind ui --rawfile artifact "$TMP/ui-malformed-join.md" -f "$provenance_validator" "$base"
  sed 's/E-REACT-001/E-MISSING/g' "$sequence" > "$TMP/sequence-missing-evidence.mmd"
  expect_status 1 jq -e --arg kind mermaid --rawfile artifact "$TMP/sequence-missing-evidence.mmd" -f "$provenance_validator" "$base"
  sed 's/REQ-0001/REQ-9999/g' "$sequence" > "$TMP/sequence-missing-requirement.mmd"
  expect_status 1 jq -e --arg kind mermaid --rawfile artifact "$TMP/sequence-missing-requirement.mmd" -f "$provenance_validator" "$base"
  sed 's#fixtures/legacy-project/App.jsx:7#fixtures/legacy-project/missing.jsx:999#g' "$sequence" > "$TMP/sequence-wrong-source.mmd"
  expect_status 1 jq -e --arg kind mermaid --rawfile artifact "$TMP/sequence-wrong-source.mmd" -f "$provenance_validator" "$base"
  sed 's/%% MSG: MSG-0001/%% MSG: MSG-9999/' "$sequence" > "$TMP/sequence-comment-tag-mismatch.mmd"
  expect_status 1 jq -e --arg kind mermaid --rawfile artifact "$TMP/sequence-comment-tag-mismatch.mmd" -f "$provenance_validator" "$base"
  printf 'sequenceDiagram\nA->>\n' > "$TMP/malformed.mmd"
  set +e; mmdc --quiet --input "$TMP/malformed.mmd" --output "$TMP/malformed.svg" >/dev/null 2>&1; rc=$?; set -e
  [ "$rc" -ne 0 ] || die "malformed Mermaid must fail"
  target="$TMP/existing-target"; mkdir -p "$target"; printf '보존\n' > "$target/marker.txt"
  before=$(shasum -a 256 "$target/marker.txt" | awk '{print $1}'); printf 'before %s\n' "$before" >> "$hashes"
  expect_status 73 "$ROOT/bin/sensai" stage "$target"
  after=$(shasum -a 256 "$target/marker.txt" | awk '{print $1}'); printf 'after %s\n' "$after" >> "$hashes"; [ "$before" = "$after" ] || die "existing target changed"
  expect_status 69 env PATH=/usr/bin:/bin "$ROOT/bin/sensai" doctor tools
  fake="$TMP/fake"; mkdir -p "$fake"; printf '#!/bin/sh\nprintf "yq 4.0.0 (python wrapper)\\n"\n' > "$fake/yq"; chmod +x "$fake/yq"
  expect_status 69 env PATH="$fake:$PATH" "$ROOT/bin/sensai" doctor tools
  record "$out" dynamic "dynamic path remained unresolved"
  record "$out" duplicate "duplicate backend remained many_to_many"
  record "$out" invalid "dangling conflict malformed empty evidence and exact/nonexact endpoints rejected"
  record "$out" provenance "UI and Mermaid missing evidence, requirement or join, wrong source, and comment/tag mismatch rejected by installed validator"
  record "$out" target "existing target unchanged after exit 73"
  record "$out" tools "missing and wrong tools rejected with 69"
  say "PASS adversarial unresolved ambiguous malformed provenance collision tools"
}

regression() {
  out="$EVIDENCE/C003-regression.jsonl"; : > "$out"
  assert_payload
  rg -q '^mode:[[:space:]]*primary$' "$ROOT/agents/sensai-analysis-lead.md" || die "lead must be primary"
  rg -q 'Qwen3\.6-35B-A3B' "$ROOT/agents/sensai-analysis-lead.md" || die "lead model mismatch"
  rg -q '^mode:[[:space:]]*subagent$' "$ROOT/agents/sensai-evidence-peer.md" || die "peer must be subagent"
  rg -q 'Qwen3\.5-9B' "$ROOT/agents/sensai-evidence-peer.md" || die "peer model mismatch"
  rg -n '^steps:[[:space:]]*[0-9]+' "$ROOT/agents" >/dev/null || die "agents must set numeric steps (loop prevention, I4)"
  rg -n 'sensai-analysis-lead' "$ROOT/commands" >/dev/null || die "commands must bind sensai-analysis-lead agent"
  expected_assets=$(printf '%s\n' recipes/provenance.jq recipes/trace.jq)
  actual_assets=$(rg -o --no-filename 'recipes/[A-Za-z0-9_.-]+' "$ROOT/skills" | sort -u)
  [ "$actual_assets" = "$expected_assets" ] || die "installed skills must reference only the two managed validators"
  ! rg -n '(^|[[:space:]`])schemas/' "$ROOT/skills" >/dev/null || die "installed skills must not depend on unmanaged schemas"
  [ -z "$(find "$ROOT" -path "$ROOT/reference" -prune -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.go' \) -print)" ] || die "TypeScript/Go runtime forbidden"
  assert_permission_contract
  permission_stage="$TMP/regression-permissions"
  "$ROOT/bin/sensai" stage "$permission_stage" >/dev/null
  env -u OPENCODE_CONFIG -u OPENCODE_CONFIG_CONTENT -u OPENCODE_PERMISSION OPENCODE_CONFIG_DIR="$permission_stage" opencode debug config > "$TMP/regression-permissions.json"
  assert_resolved_permission_contract "$TMP/regression-permissions.json"
  assert_ui_and_mermaid "$permission_stage/recipes/trace.jq" "$permission_stage/recipes/provenance.jq"
  for doc in README.md docs/PROD.md; do require_file "$doc"; rg -q '[가-힣]' "$ROOT/$doc" || die "Korean document required: $doc"; done
  rg -q 'P0.*Go.*없' "$ROOT/docs/PROD.md" || die "PROD must state P0 Go none"
  rg -q 'P1' "$ROOT/docs/PROD.md" && rg -q 'P2' "$ROOT/docs/PROD.md" || die "PROD must define P1/P2 gates"
  rg -q '10,?000|10000' "$ROOT/docs/PROD.md" || die "PROD must include measurable scale gate"
  record "$out" topology "agents=2 commands=3 skills=6"
  record "$out" model-permission "35B lead and 9B peer"
  record "$out" simplicity "no numeric steps shell interpolation runtime recipes schemas TypeScript or Go"
  record "$out" artifact-contracts "installed trace and provenance validators, UI headings, Mermaid provenance, and permission ordering"
  record "$out" docs "Korean docs and P0/P1/P2 Go admission gates"
  say "PASS regression topology models permissions simplicity docs"
}

case "$MODE" in
  happy) happy ;;
  adversarial) adversarial ;;
  regression) regression ;;
  all) happy; adversarial; regression ;;
  *) die "usage: $0 happy|adversarial|regression|all" ;;
esac
