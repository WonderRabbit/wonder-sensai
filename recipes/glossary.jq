# glossary.jq — 용어사전 검증 (02 §6.1, I1 §4)
# 입력: glossary.json — { glossary: [ { term_id, term_ko, term_canonical, identifier_form, definition_ko, category, evidence_ids, maps_to, status } ] }
# 출력: exit 0 = 유효, nonzero = 항목 결함(발명 용어/근거 없음/형식 위반)
# term_id: GLOSS-NNN. evidence_ids ≥1(근거 강제, 발명 용어 거부). status exact/unresolved/ambiguous/conflict.
def term_id_ok: type == "string" and test("^GLOSS-[0-9]{3}$");
def term_ok:
  type == "object" and
  (keys | sort) == ["category", "definition_ko", "evidence_ids", "identifier_form", "maps_to", "status", "term_canonical", "term_id", "term_ko"] and
  (.term_id | term_id_ok) and
  (.term_ko | type == "string" and length > 0) and
  has("term_canonical") and
  (.evidence_ids | type == "array" and length > 0 and all(.[]; type == "string" and length > 0)) and
  (.status | IN("exact", "unresolved", "ambiguous", "conflict"));
type == "object" and
has("glossary") and
(.glossary | type == "array" and all(.[]; term_ok))
