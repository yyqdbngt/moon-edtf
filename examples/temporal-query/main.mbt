///|
fn main {
  let records = [
    @edtf.TemporalRecord::{
      record_id: "sensor-17",
      category: "observation",
      temporal: "2024-05-18",
    },
    @edtf.TemporalRecord::{
      record_id: "release-9",
      category: "product",
      temporal: "2024-XX",
    },
    @edtf.TemporalRecord::{
      record_id: "grant-2",
      category: "project",
      temporal: "2022/2023",
    },
    @edtf.TemporalRecord::{
      record_id: "event-4",
      category: "event",
      temporal: "2024?",
    },
    @edtf.TemporalRecord::{
      record_id: "api-bad",
      category: "api",
      temporal: "2024-02-30",
    },
  ]
  let report = try! @edtf.query_temporal_records(
    records,
    "2024-05-01",
    "2024-05-31",
    @edtf.IncludePossibleOverlap,
  )
  println("selected=" + report.selected_ids.length().to_string())
  println("invalid=" + report.invalid.to_string())
  println("needs-review=" + report.needs_review.to_string())
  println("outside=" + report.outside.to_string())
  println("within=" + report.within.to_string())
  println("possible-overlap=" + report.possible_overlap.to_string())
  for finding in report.findings {
    println(
      finding.record_id +
      "\t" +
      finding.category +
      "\t" +
      finding.decision.to_string() +
      "\tselected=" +
      finding.selected.to_string(),
    )
  }
}
