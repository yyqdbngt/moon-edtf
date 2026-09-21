///|
test "catalog audit retains every row and classifies a realistic mixed batch" {
  let rows = [
    CatalogEntry::{ record_id: "a", edtf: "1984-06-15", },
    CatalogEntry::{ record_id: "b", edtf: "198X", },
    CatalogEntry::{ record_id: "c", edtf: "2004", },
    CatalogEntry::{ record_id: "d", edtf: "1984?", },
    CatalogEntry::{ record_id: "e", edtf: "1984-02-30", },
    CatalogEntry::{ record_id: "f", edtf: "1984-XX", },
    CatalogEntry::{ record_id: "g", edtf: "../1984", },
    CatalogEntry::{ record_id: "h", edtf: "{1983,1984}", },
    CatalogEntry::{ record_id: "i", edtf: "1984-12/1985-01", },
  ]
  let report = audit_catalog(rows, "1984-01-01", "1984-12-31")
  assert_eq(report.findings.length(), 9)
  assert_eq(report.invalid, 1)
  assert_eq(report.needs_review, 2)
  assert_eq(report.outside, 1)
  assert_eq(report.within, 2)
  assert_eq(report.possible_overlap, 3)
  assert_eq(report.findings[0].decision, WithinWindow)
  assert_eq(report.findings[1].decision, PossibleOverlapWindow)
  assert_eq(report.findings[2].decision, OutsideWindow)
  assert_eq(report.findings[3].decision, NeedsReview)
  assert_eq(report.findings[3].error_code, "ENVELOPE_QUALIFIED")
  assert_eq(report.findings[4].decision, Invalid)
  assert_eq(report.findings[4].error_code, "INVALID_DAY")
  assert_eq(report.findings[4].error_offset, 7)
  assert_eq(report.findings[5].normalized, "1984-XX")
  assert_eq(report.findings[8].decision, PossibleOverlapWindow)
  assert_eq(report.findings[7].decision, PossibleOverlapWindow)
}

///|
test "catalog audit refuses non-day or reversed query before reading rows" {
  let rows = [CatalogEntry::{ record_id: "x", edtf: "1984", }]
  let partial = try {
    ignore(audit_catalog(rows, "1984", "1984-12-31"))
    false
  } catch {
    Unsupported("WINDOW_NEEDS_EXACT_DAY", _) => true
    _ => false
  }
  assert_true(partial)
  let reversed = try {
    ignore(audit_catalog(rows, "1985-01-01", "1984-12-31"))
    false
  } catch {
    Unsupported("WINDOW_REVERSED", _) => true
    _ => false
  }
  assert_true(reversed)
}

///|
test "empty catalog report is well formed" {
  let report = audit_catalog([], "1984-01-01", "1984-12-31")
  assert_eq(report.findings.length(), 0)
  assert_eq(report.invalid, 0)
  assert_eq(report.needs_review, 0)
  assert_eq(report.outside, 0)
  assert_eq(report.within, 0)
  assert_eq(report.possible_overlap, 0)
}

///|
test "thousand-row catalog batch keeps all results and stable counts" {
  let rows : Array[CatalogEntry] = []
  let inputs = ["1985-04-12", "1985-XX-XX", "2004-XX", "1984?", "1984-02-30"]
  for i = 0; i < 1000; i = i + 1 {
    rows.push(CatalogEntry::{ record_id: i.to_string(), edtf: inputs[i % 5], })
  }
  let report = audit_catalog(rows, "1985-04-01", "1985-04-30")
  assert_eq(report.findings.length(), 1000)
  assert_eq(report.within, 200)
  assert_eq(report.possible_overlap, 200)
  assert_eq(report.outside, 200)
  assert_eq(report.needs_review, 200)
  assert_eq(report.invalid, 200)
  assert_eq(report.findings[999].error_code, "INVALID_DAY")
}
