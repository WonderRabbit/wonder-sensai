def strings_nonempty: type == "array" and length > 0 and all(.[]; type == "string" and length > 0);
def unique_values: length == (unique | length);
def status_ok: . == "exact" or . == "unresolved" or . == "ambiguous" or . == "conflict";
def id_ok: type == "string" and test("^[A-Z][A-Z0-9_-]+$");
def convention_id_ok: type == "string" and test("^CONV-(STACK|STRUCTURE|NAMING|API|STATE|CODINGSTD|SCAFFOLD)-[0-9]{3}$");
def path_ok:
  type == "object" and
  (keys | sort) == ["expr", "literal", "normalized"] and
  (.expr | type == "string" and length > 0) and
  (.literal == null or (.literal | type == "string")) and
  (.normalized == null or (.normalized | type == "string"));
def refs_ok($ids):
  type == "array" and length > 0 and unique_values and all(.[]; id_ok and IN($ids[]));
def direct_exact_ref($evidence; $refs; $join_refs; $layer):
  any($refs[];
    . as $eid |
    IN($join_refs[]) and
    any($evidence[]; .id == $eid and .layer == $layer and .status == "exact"));
def evidence_ok:
  type == "object" and
  (keys | sort) == ["claim_ko", "extractor", "id", "layer", "line", "path", "status"] and
  (.id | id_ok) and
  (.layer | IN("react", "vertx", "openapi", "spec")) and
  (.path | type == "string" and length > 0) and
  (.line | type == "number" and floor == . and . >= 1) and
  (.extractor | type == "string" and length > 0) and
  (.claim_ko | type == "string" and length > 0) and
  (.status | status_ok);
def requirement_ok($eids):
  type == "object" and
  (keys | sort) == ["evidence_ids", "id", "keyword", "section", "source", "statement_ko"] and
  (.id | id_ok) and
  (.source | type == "string" and length > 0) and
  (.section | type == "string" and length > 0) and
  (.keyword | IN("MUST", "SHOULD", "MAY")) and
  (.statement_ko | type == "string" and length > 0) and
  (.evidence_ids | refs_ok($eids));
def call_ok($eids):
  type == "object" and
  (keys | sort) == ["evidence_ids", "method", "path", "status"] and
  (.method | IN("GET", "POST", "PUT", "PATCH", "DELETE")) and
  (.path | path_ok) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);
def frontend_ok($eids):
  type == "object" and
  (keys | sort) == ["api_calls", "component", "evidence_ids", "id", "route", "status"] and
  (.id | id_ok) and
  (.component | type == "string" and length > 0) and
  (.route | path_ok) and
  (.api_calls | type == "array" and all(.[]; call_ok($eids))) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);
def backend_ok($eids):
  type == "object" and
  (keys | sort) == ["event_bus_address", "evidence_ids", "handler", "id", "method", "operation_id", "path", "status", "transport"] and
  (.id | id_ok) and
  (.transport == "http") and
  (.method | IN("GET", "POST", "PUT", "PATCH", "DELETE")) and
  (.path | path_ok) and
  (.operation_id == null or (.operation_id | type == "string")) and
  (.handler == null or (.handler | type == "string")) and
  (.event_bus_address == null or (.event_bus_address | type == "string")) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);
def join_shape_ok($eids; $fids; $bids):
  type == "object" and
  (keys | sort) == ["cardinality", "evidence_ids", "id", "kind", "left_id", "method", "path_normalized", "right_ids", "status"] and
  (.id | id_ok) and
  (.kind == "http") and
  (.method | IN("GET", "POST", "PUT", "PATCH", "DELETE")) and
  (.path_normalized == null or (.path_normalized | type == "string" and length > 0)) and
  (.left_id | id_ok and IN($fids[])) and
  (.right_ids | type == "array" and unique_values and all(.[]; id_ok and IN($bids[]))) and
  (.cardinality | IN("one_to_one", "many_to_many", "unresolved")) and
  (.status | status_ok) and
  (.evidence_ids | refs_ok($eids)) and
  (if .status == "exact" then .cardinality == "one_to_one" and (.right_ids | length) == 1 and .path_normalized != null
   elif .status == "unresolved" then .cardinality == "unresolved" and (.right_ids | length) == 0
   elif .status == "ambiguous" then .cardinality == "many_to_many" and (.right_ids | length) > 1
   else true end);
def convention_ok($eids):
  type == "object" and
  (keys | sort) == ["category", "evidence_ids", "examples", "extractor", "id", "kind", "statement_ko", "status"] and
  (.id | convention_id_ok) and
  (.category | IN("stack", "structure", "naming", "api_pattern", "state", "coding_standard", "scaffold_pattern")) and
  (.kind | IN("asis", "tobe")) and
  (.statement_ko | type == "string" and length > 0) and
  (.examples | type == "array" and length > 0 and all(.[]; type == "string" and length > 0)) and
  (.extractor | type == "string" and length > 0) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);
def unknown_ok($eids):
  type == "object" and
  (keys | sort) == ["evidence_ids", "id", "next_probe", "reason", "statement_ko"] and
  (.id | id_ok) and
  (.statement_ko | type == "string" and length > 0) and
  (.reason | type == "string" and length > 0) and
  (.next_probe | type == "string" and length > 0) and
  (.evidence_ids | refs_ok($eids));

def unsupported_ok:
  type == "object" and
  (keys | sort) == ["id", "reason", "statement_ko"] and
  (.id | id_ok) and
  (.statement_ko | type == "string" and length > 0) and
  (.reason | type == "string" and length > 0);
def business_fact_ok($eids):
  type == "object" and
  (.id | test("^BIZ-(ENT|RULE|FLOW|EVT|STATE|INV)-[0-9]{3}$")) and
  (.kind | IN("asis","tobe")) and
  (.category | IN("business_entity","business_rule","business_flow","business_event","business_state","business_invariant")) and
  (.statement_ko | type == "string" and length > 0) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);
def design_ok($eids):
  type == "object" and
  (.id | test("^DESIGN-(PAGE|SERVICE|API|ENTITY)-[0-9]{3}$")) and
  (.kind == "tobe") and
  (.type | IN("page","service","api","entity")) and
  (.statement_ko | type == "string" and length > 0) and
  (.requirement_ids | type == "array" and all(.[]; type == "string" and length > 0)) and
  (.follows_convention_ids | type == "array" and length > 0) and
  (.follows_business_ids | type == "array" and length > 0) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);
def binding_ok:
  type == "object" and
  (.design_id | type == "string" and length > 0) and
  (.target_kind | IN("convention","business")) and
  (.target_id | type == "string" and length > 0) and
  (.gate | IN("pass","violation"));
def ext_req_ok($eids):
  type == "object" and
  (.id | test("^REQ-EXT-[0-9]{4}$")) and
  (.statement_ko | type == "string" and length > 0) and
  (.source | IN("user","elicited","inferred")) and
  (.evidence_ids | refs_ok($eids)) and
  (.status | status_ok);

. as $root |
($root.evidence | map(.id)) as $eids |
($root.requirements | map(.id)) as $rids |
($root.frontends | map(.id)) as $fids |
($root.backends | map(.id)) as $bids |
($root.joins | map(.id)) as $jids |
($root.conventions | map(.id)) as $cids |
($root.unknowns | map(.id)) as $uids |
type == "object" and
(has("schema_version") and has("run_id") and has("scope") and has("evidence") and has("requirements") and has("frontends") and has("backends") and has("joins") and has("conventions") and has("unknowns")) and
.schema_version == "2.0" and
(.run_id | type == "string" and length > 0) and
(.scope | type == "object" and (keys == ["roots"]) and (.roots | strings_nonempty and unique_values)) and
(.evidence | type == "array" and length > 0 and all(.[]; evidence_ok)) and
($eids | unique_values) and
(.requirements | type == "array" and all(.[]; requirement_ok($eids))) and
($rids | unique_values) and
(.frontends | type == "array" and all(.[]; frontend_ok($eids))) and
($fids | unique_values) and
(.backends | type == "array" and all(.[]; backend_ok($eids))) and
($bids | unique_values) and
(.joins | type == "array" and all(.[]; join_shape_ok($eids; $fids; $bids))) and
($jids | unique_values) and
(.conventions | type == "array" and all(.[]; convention_ok($eids))) and
($cids | unique_values) and
(.unknowns | type == "array" and all(.[]; unknown_ok($eids))) and
($uids | unique_values) and
((has("unsupported") and (.unsupported | type == "array" and all(.[]; unsupported_ok))) or (has("unsupported") | not)) and
((has("business_entities") and (.business_entities | type == "array" and all(.[]; business_fact_ok($eids)))) or (has("business_entities") | not)) and
((has("business_rules") and (.business_rules | type == "array" and all(.[]; business_fact_ok($eids)))) or (has("business_rules") | not)) and
((has("business_flows") and (.business_flows | type == "array" and all(.[]; business_fact_ok($eids)))) or (has("business_flows") | not)) and
((has("business_events") and (.business_events | type == "array" and all(.[]; business_fact_ok($eids)))) or (has("business_events") | not)) and
((has("business_states") and (.business_states | type == "array" and all(.[]; business_fact_ok($eids)))) or (has("business_states") | not)) and
((has("business_invariants") and (.business_invariants | type == "array" and all(.[]; business_fact_ok($eids)))) or (has("business_invariants") | not)) and
((has("designs") and (.designs | type == "array" and all(.[]; design_ok($eids)))) or (has("designs") | not)) and
((has("bindings") and (.bindings | type == "array" and all(.[]; binding_ok))) or (has("bindings") | not)) and
((has("extension_requirements") and (.extension_requirements | type == "array" and all(.[]; ext_req_ok($eids)))) or (has("extension_requirements") | not)) and
([ $eids[], $rids[], $fids[], $bids[], $jids[], $cids[], $uids[] ] | unique_values) and
all($root.joins[];
  . as $join |
  if $join.status == "exact" then
    any($root.frontends[];
      .id == $join.left_id and
      any(.api_calls[];
        . as $call |
        $call.status == "exact" and
        $call.method == $join.method and
        $call.path.normalized == $join.path_normalized and
        direct_exact_ref($root.evidence; $call.evidence_ids; $join.evidence_ids; "react"))) and
    all($join.right_ids[];
      . as $rid |
      any($root.backends[];
        .id == $rid and
        .status == "exact" and
        .method == $join.method and
        .path.normalized == $join.path_normalized and
        direct_exact_ref($root.evidence; .evidence_ids; $join.evidence_ids; "vertx")))
  else
    any($root.frontends[];
      .id == $join.left_id and
      any(.api_calls[];
        .method == $join.method and
        (.path.normalized == $join.path_normalized or $join.path_normalized == null))) and
    all($join.right_ids[];
      . as $rid |
      any($root.backends[];
        .id == $rid and
        .method == $join.method and
        .path.normalized == $join.path_normalized))
  end)
