///|
/// One structured date field supplied by an ingest pipeline. The library
/// deliberately does not read CSV, MARC, JSON or network data itself.
pub(all) struct CatalogEntry {
  record_id : String
  edtf : String
} derive(Eq, @debug.Debug)

///|
/// A row may be invalid syntax, require a human judgment, or have a safe
/// envelope relationship to the requested exact-day window.
pub(all) enum CatalogDecision {
  Invalid
  NeedsReview
  OutsideWindow
  WithinWindow
  PossibleOverlapWindow
} derive(Eq, @debug.Debug)

///|
pub fn CatalogDecision::to_string(self : CatalogDecision) -> String {
  match self {
    Invalid => "invalid"
    NeedsReview => "needs-review"
    OutsideWindow => "outside"
    WithinWindow => "within"
    PossibleOverlapWindow => "possible-overlap"
  }
}

///|
/// An `Invalid` row has `error_offset` in the original UTF-16 input;
/// `NeedsReview` carries an unsupported-operation code with offset -1.
/// Rows with a window decision have a conservative envelope but no error.
pub(all) struct CatalogFinding {
  record_id : String
  input : String
  normalized : String
  decision : CatalogDecision
  error_code : String
  error_offset : Int
  envelope : DateEnvelope?
} derive(Eq, @debug.Debug)

///|
pub(all) struct CatalogReport {
  findings : Array[CatalogFinding]
  invalid : Int
  needs_review : Int
  outside : Int
  within : Int
  possible_overlap : Int
} derive(Eq, @debug.Debug)

///|
fn catalog_finding(
  entry : CatalogEntry,
  normalized : String,
  decision : CatalogDecision,
  code : String,
  offset : Int,
  envelope : DateEnvelope?,
) -> CatalogFinding {
  {
    record_id: entry.record_id,
    input: entry.edtf,
    normalized,
    decision,
    error_code: code,
    error_offset: offset,
    envelope,
  }
}

///|
fn analyze_catalog_entry(
  entry : CatalogEntry,
  start : CalendarDay,
  end : CalendarDay,
) -> CatalogFinding {
  let value = parse(entry.edtf) catch {
    Syntax(code, offset) =>
      return catalog_finding(entry, "", Invalid, code, offset, None)
    Unsupported(code, offset) =>
      return catalog_finding(entry, "", Invalid, code, offset, None)
  }
  let normalized = value.to_string()
  let envelope = date_envelope(value) catch {
    Unsupported(code, _) =>
      return catalog_finding(entry, normalized, NeedsReview, code, -1, None)
    Syntax(code, _) =>
      return catalog_finding(entry, normalized, NeedsReview, code, -1, None)
  }
  let decision = match relation_for_envelope(envelope, start, end) {
    Outside => OutsideWindow
    Within => WithinWindow
    PossibleOverlap => PossibleOverlapWindow
  }
  catalog_finding(entry, normalized, decision, "", -1, Some(envelope))
}

///|
/// Validate and screen a catalog batch against an inclusive exact-day window.
/// Invalid date fields are not silently dropped; uncertainty, approximation,
/// seasons, sets and open/unknown intervals go to `NeedsReview` rather than
/// receiving fabricated bounds. `PossibleOverlapWindow` is deliberately
/// conservative and can include false positives; it is not an exact match.
/// An invalid query window raises before any row is examined.
pub fn audit_catalog(
  entries : Array[CatalogEntry],
  query_start : String,
  query_end : String,
) -> CatalogReport raise EdtfError {
  let start = exact_query_day(parse(query_start))
  let end = exact_query_day(parse(query_end))
  if calendar_compare(start, end) > 0 {
    raise Unsupported("WINDOW_REVERSED", 0)
  }
  let findings : Array[CatalogFinding] = []
  let mut invalid = 0
  let mut needs_review = 0
  let mut outside = 0
  let mut within = 0
  let mut possible_overlap = 0
  for entry in entries {
    let finding = analyze_catalog_entry(entry, start, end)
    match finding.decision {
      Invalid => invalid += 1
      NeedsReview => needs_review += 1
      OutsideWindow => outside += 1
      WithinWindow => within += 1
      PossibleOverlapWindow => possible_overlap += 1
    }
    findings.push(finding)
  }
  { findings, invalid, needs_review, outside, within, possible_overlap, }
}
