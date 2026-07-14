def unique_values: length == (unique | length);
def nonempty_strings: type == "array" and length > 0 and all(.[]; type == "string" and length > 0);
def csv: split(",") | map(gsub("^\\s+|\\s+$"; ""));
def source:
  capture("^(?<path>.+):(?<line>[1-9][0-9]*)$") |
  .line |= tonumber;
def exact_evidence($trace; $id; $source):
  any($trace.evidence[];
    .id == $id and
    .status == "exact" and
    .path == $source.path and
    .line == $source.line);
def exact_requirement($trace; $id; $source):
  any($trace.requirements[];
    .id == $id and
    any(.evidence_ids[]; . as $eid | exact_evidence($trace; $eid; $source)));

def mermaid($trace; $text):
  ($text | split("\n")) as $lines |
  ($lines | map(select(test("^\\s*%% MSG:")))) as $msg_lines |
  ($lines | map(select(test("^\\s*%% REQ:")))) as $req_lines |
  ($lines | map(select(test("(->>|-->>)")))) as $arrow_lines |
  ($msg_lines | map(
    capture("^\\s*%% MSG: (?<id>MSG-[0-9]{4}) \\| evidence=(?<evidence>[^|]+) \\| source=(?<sources>.+)$") |
    .evidence = (.evidence | csv) |
    .sources = (.sources | csv | map(source)))) as $messages |
  ($req_lines | map(
    capture("^\\s*%% REQ: (?<id>REQ-[0-9]{4}) \\| (?<source>.+)$") |
    .source |= source)) as $requirements |
  ($arrow_lines | map(
    capture("\\[(?<msg>MSG-[0-9]{4})\\]\\[(?<requirements>NO-REQ|REQ-[0-9]{4}(,REQ-[0-9]{4})*)\\]") |
    .requirements = (if .requirements == "NO-REQ" then [] else (.requirements | csv) end))) as $arrows |
  ($messages | length > 0) and
  ($arrows | length == ($messages | length)) and
  ($messages | map(.id) | unique_values) and
  ($requirements | map(.id) | unique_values) and
  ($arrows | map(.msg) | unique_values) and
  all($messages[];
    . as $message |
    ($message.evidence | nonempty_strings and unique_values) and
    (($message.sources | length) == ($message.evidence | length)) and
    all(range(0; $message.evidence | length);
      . as $index |
      exact_evidence($trace; $message.evidence[$index]; $message.sources[$index]))) and
  all($requirements[]; exact_requirement($trace; .id; .source)) and
  all($messages[].id; . as $id | any($arrows[]; .msg == $id)) and
  all($arrows[];
    . as $arrow |
    any($messages[]; .id == $arrow.msg) and
    ($arrow.requirements | unique_values) and
    all($arrow.requirements[];
      . as $id |
      any($requirements[]; .id == $id) and
      any($trace.requirements[]; .id == $id))) and
  all($requirements[].id; . as $id | any($arrows[].requirements[]; . == $id));

def ui($trace; $text):
  ([$text | scan("E-[A-Z0-9_-]+") ]) as $evidence_ids |
  ([$text | scan("(?<![A-Za-z0-9_-])REQ-[A-Za-z0-9_-]+(?![A-Za-z0-9_-])") ]) as $requirement_ids |
  ([$text | scan("(?<![A-Za-z0-9_-])J-[A-Za-z0-9_-]+(?![A-Za-z0-9_-])") ]) as $join_ids |
  ([$text | scan("[A-Za-z0-9_./-]+\\.[A-Za-z0-9]+:[1-9][0-9]*") ]) as $source_tokens |
  ([$text | scan("`E-[A-Z0-9_-]+` @ `[A-Za-z0-9_./-]+\\.[A-Za-z0-9]+:[1-9][0-9]*`") ] |
    map(capture("^`(?<id>E-[A-Z0-9_-]+)` @ `(?<source>[A-Za-z0-9_./-]+\\.[A-Za-z0-9]+:[1-9][0-9]*)`$") |
      .source |= source)) as $pairs |
  ($text | test("[A-Za-z0-9_./-]+\\.[A-Za-z0-9]+:[1-9][0-9]*-[0-9]+") | not) and
  ($pairs | length > 0) and
  (($evidence_ids | sort) == ($pairs | map(.id) | sort)) and
  (($source_tokens | sort) == ($pairs | map(.source | "\(.path):\(.line)") | sort)) and
  all($pairs[]; exact_evidence($trace; .id; .source)) and
  ($requirement_ids | length > 0) and
  all($requirement_ids[];
    test("^REQ-[A-Z0-9_-]+$") and
    (. as $id | any($trace.requirements[]; .id == $id))) and
  all($join_ids[];
    test("^J-[A-Z0-9_-]+$") and
    (. as $id | any($trace.joins[]; .id == $id and .status == "exact")));

. as $trace |
if $kind == "mermaid" then mermaid($trace; $artifact)
elif $kind == "ui" then ui($trace; $artifact)
else error("kind는 mermaid 또는 ui여야 한다")
end
