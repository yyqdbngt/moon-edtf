///|
/// Reproducible metadata-ingest scenario using spelling patterns published in
/// the Library of Congress EDTF/RDA guidance. IDs and the batch are illustrative,
/// not downloaded catalog records. The search window is April 1985.
fn main {
  let rows = [
    @edtf.CatalogEntry::{ record_id: "R-01", edtf: "1985-04-XX", },
    @edtf.CatalogEntry::{ record_id: "R-02", edtf: "1985-XX-XX", },
    @edtf.CatalogEntry::{ record_id: "R-03", edtf: "1984?", },
    @edtf.CatalogEntry::{ record_id: "R-04", edtf: "1984-02-30", },
    @edtf.CatalogEntry::{ record_id: "R-05", edtf: "2004-XX", },
    @edtf.CatalogEntry::{ record_id: "R-06", edtf: "[1666,1667]", },
  ]
  let report = try! @edtf.audit_catalog(rows, "1985-04-01", "1985-04-30")
  println("catalog: \{report.findings.length()} rows")
  println(
    "invalid=\{report.invalid} review=\{report.needs_review} outside=\{report.outside} within=\{report.within} possible=\{report.possible_overlap}",
  )
  for row in report.findings {
    println(
      "\{row.record_id}: \{row.input} => \{row.decision.to_string()} \{row.error_code}",
    )
  }
}
