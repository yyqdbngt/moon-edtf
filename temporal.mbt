///|
/// A domain-neutral record whose temporal field is written in the supported
/// EDTF subset. Identifiers and categories are carried through unchanged so
/// callers can join results back to their own data stores.
pub(all) struct TemporalRecord {
  record_id : String
  category : String
  temporal : String
} derive(Eq, @debug.Debug)

///|
/// `WithinOnly` selects only provably contained records. The recall-first
/// policy also selects conservative envelope overlaps.
pub(all) enum MatchPolicy {
  WithinOnly
  IncludePossibleOverlap
} derive(Eq, @debug.Debug)

///|
pub(all) enum TemporalDecision {
  InvalidTemporal
  NeedsTemporalReview
  OutsideTemporalWindow
  WithinTemporalWindow
  PossibleTemporalOverlap
} derive(Eq, @debug.Debug)

///|
pub fn TemporalDecision::to_string(self : TemporalDecision) -> String {
  match self {
    InvalidTemporal => "invalid"
    NeedsTemporalReview => "needs-review"
    OutsideTemporalWindow => "outside"
    WithinTemporalWindow => "within"
    PossibleTemporalOverlap => "possible-overlap"
  }
}

///|
/// Every input produces one finding. Invalid and review rows are never
/// selected automatically.
pub(all) struct TemporalFinding {
  record_id : String
  category : String
  input : String
  normalized : String
  decision : TemporalDecision
  selected : Bool
  error_code : String
  error_offset : Int
  envelope : DateEnvelope?
} derive(Eq, @debug.Debug)

///|
/// `coverage` is the outer bound of all safely bounded rows and is independent
/// of the query window. It is `None` when no row has defensible finite bounds.
pub(all) struct TemporalReport {
  findings : Array[TemporalFinding]
  selected_ids : Array[String]
  invalid : Int
  needs_review : Int
  outside : Int
  within : Int
  possible_overlap : Int
  coverage : DateEnvelope?
} derive(Eq, @debug.Debug)

///|
fn temporal_finding(
  record : TemporalRecord,
  normalized : String,
  decision : TemporalDecision,
  selected : Bool,
  code : String,
  offset : Int,
  envelope : DateEnvelope?,
) -> TemporalFinding {
  {
    record_id: record.record_id,
    category: record.category,
    input: record.temporal,
    normalized,
    decision,
    selected,
    error_code: code,
    error_offset: offset,
    envelope,
  }
}

///|
fn select_temporal(relation : WindowRelation, policy : MatchPolicy) -> Bool {
  match relation {
    Within => true
    PossibleOverlap => policy is IncludePossibleOverlap
    Outside => false
  }
}

///|
fn merge_coverage(current : DateEnvelope?, next : DateEnvelope) -> DateEnvelope {
  match current {
    None => next
    Some(value) => {
      let earliest = if calendar_compare(next.earliest, value.earliest) < 0 {
        next.earliest
      } else {
        value.earliest
      }
      let latest = if calendar_compare(next.latest, value.latest) > 0 {
        next.latest
      } else {
        value.latest
      }
      { earliest, latest, }
    }
  }
}

///|
/// Validate and query temporal fields from any application domain. Suitable
/// inputs include observations, availability windows, project milestones,
/// legal validity ranges, event indexes, and archival metadata. The query is
/// validated before rows are read, and no invalid row disappears silently.
pub fn query_temporal_records(
  records : Array[TemporalRecord],
  query_start : String,
  query_end : String,
  policy : MatchPolicy,
) -> TemporalReport raise EdtfError {
  let start = exact_query_day(parse(query_start))
  let end = exact_query_day(parse(query_end))
  if calendar_compare(start, end) > 0 {
    raise Unsupported("WINDOW_REVERSED", 0)
  }
  let findings : Array[TemporalFinding] = []
  let selected_ids : Array[String] = []
  let mut invalid = 0
  let mut needs_review = 0
  let mut outside = 0
  let mut within = 0
  let mut possible_overlap = 0
  let mut coverage : DateEnvelope? = None
  for record in records {
    let value = parse(record.temporal) catch {
      Syntax(code, offset) => {
        invalid += 1
        findings.push(
          temporal_finding(
            record,
            "",
            InvalidTemporal,
            false,
            code,
            offset,
            None,
          ),
        )
        continue
      }
      Unsupported(code, offset) => {
        invalid += 1
        findings.push(
          temporal_finding(
            record,
            "",
            InvalidTemporal,
            false,
            code,
            offset,
            None,
          ),
        )
        continue
      }
    }
    let normalized = value.to_string()
    let envelope = date_envelope(value) catch {
      Unsupported(code, _) => {
        needs_review += 1
        findings.push(
          temporal_finding(
            record,
            normalized,
            NeedsTemporalReview,
            false,
            code,
            -1,
            None,
          ),
        )
        continue
      }
      Syntax(code, _) => {
        needs_review += 1
        findings.push(
          temporal_finding(
            record,
            normalized,
            NeedsTemporalReview,
            false,
            code,
            -1,
            None,
          ),
        )
        continue
      }
    }
    coverage = Some(merge_coverage(coverage, envelope))
    let relation = relation_for_envelope(envelope, start, end)
    let selected = select_temporal(relation, policy)
    let decision = match relation {
      Outside => {
        outside += 1
        OutsideTemporalWindow
      }
      Within => {
        within += 1
        WithinTemporalWindow
      }
      PossibleOverlap => {
        possible_overlap += 1
        PossibleTemporalOverlap
      }
    }
    if selected {
      selected_ids.push(record.record_id)
    }
    findings.push(
      temporal_finding(
        record,
        normalized,
        decision,
        selected,
        "",
        -1,
        Some(envelope),
      ),
    )
  }
  {
    findings,
    selected_ids,
    invalid,
    needs_review,
    outside,
    within,
    possible_overlap,
    coverage,
  }
}

///|
/// A provable relationship between two conservative temporal envelopes.
pub(all) enum TemporalRelation {
  DefinitelyBefore
  DefinitelyAfter
  SameCoverage
  ContainsCoverage
  WithinCoverage
  PossibleOverlapCoverage
} derive(Eq, @debug.Debug)

///|
pub fn TemporalRelation::to_string(self : TemporalRelation) -> String {
  match self {
    DefinitelyBefore => "definitely-before"
    DefinitelyAfter => "definitely-after"
    SameCoverage => "same-coverage"
    ContainsCoverage => "contains-coverage"
    WithinCoverage => "within-coverage"
    PossibleOverlapCoverage => "possible-overlap"
  }
}

///|
/// Compare two EDTF values without inventing exact timestamps. Inputs without
/// defensible finite envelopes are rejected instead of guessed.
pub fn temporal_relation(
  left : EdtfValue,
  right : EdtfValue,
) -> TemporalRelation raise EdtfError {
  let a = date_envelope(left)
  let b = date_envelope(right)
  if calendar_compare(a.latest, b.earliest) < 0 {
    DefinitelyBefore
  } else if calendar_compare(a.earliest, b.latest) > 0 {
    DefinitelyAfter
  } else {
    let starts_same = calendar_compare(a.earliest, b.earliest) == 0
    let ends_same = calendar_compare(a.latest, b.latest) == 0
    if starts_same && ends_same {
      SameCoverage
    } else if calendar_compare(a.earliest, b.earliest) <= 0 &&
      calendar_compare(a.latest, b.latest) >= 0 {
      ContainsCoverage
    } else if calendar_compare(a.earliest, b.earliest) >= 0 &&
      calendar_compare(a.latest, b.latest) <= 0 {
      WithinCoverage
    } else {
      PossibleOverlapCoverage
    }
  }
}
