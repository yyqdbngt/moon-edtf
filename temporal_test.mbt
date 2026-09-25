///|
test "domain-neutral query supports strict and recall-first policies" {
  let rows = [
    TemporalRecord::{
      record_id: "sensor-1",
      category: "observation",
      temporal: "2024-05-18",
    },
    TemporalRecord::{
      record_id: "release-1",
      category: "product",
      temporal: "2024-XX",
    },
    TemporalRecord::{
      record_id: "project-1",
      category: "milestone",
      temporal: "2022/2023",
    },
    TemporalRecord::{
      record_id: "event-1",
      category: "event",
      temporal: "2024?",
    },
    TemporalRecord::{
      record_id: "bad-1",
      category: "api",
      temporal: "2024-02-30",
    },
  ]
  let strict = query_temporal_records(
    rows,
    "2024-05-01",
    "2024-05-31",
    WithinOnly,
  )
  assert_eq(strict.findings.length(), 5)
  assert_eq(strict.selected_ids, ["sensor-1"])
  assert_eq(strict.within, 1)
  assert_eq(strict.possible_overlap, 1)
  assert_eq(strict.outside, 1)
  assert_eq(strict.needs_review, 1)
  assert_eq(strict.invalid, 1)
  assert_eq(strict.findings[3].error_code, "ENVELOPE_QUALIFIED")
  assert_eq(strict.findings[4].error_code, "INVALID_DAY")
  assert_eq(strict.findings[4].error_offset, 7)
  let recall = query_temporal_records(
    rows,
    "2024-05-01",
    "2024-05-31",
    IncludePossibleOverlap,
  )
  assert_eq(recall.selected_ids, ["sensor-1", "release-1"])
}

///|
test "report coverage summarizes only defensible finite rows" {
  let report = query_temporal_records(
    [
      TemporalRecord::{ record_id: "a", category: "x", temporal: "201X", },
      TemporalRecord::{ record_id: "b", category: "x", temporal: "2024-06", },
      TemporalRecord::{ record_id: "c", category: "x", temporal: "2020?", },
    ],
    "2024-01-01",
    "2024-12-31",
    IncludePossibleOverlap,
  )
  match report.coverage {
    Some(value) => {
      assert_eq(value.earliest.to_string(), "2010-01-01")
      assert_eq(value.latest.to_string(), "2024-06-30")
    }
    None => fail("expected coverage")
  }
}

///|
test "relation distinguishes order containment equality and overlap" {
  assert_eq(temporal_relation(parse("2020"), parse("2021")), DefinitelyBefore)
  assert_eq(temporal_relation(parse("2022"), parse("2021")), DefinitelyAfter)
  assert_eq(temporal_relation(parse("2020"), parse("2020-XX")), SameCoverage)
  assert_eq(
    temporal_relation(parse("2020"), parse("2020-05")),
    ContainsCoverage,
  )
  assert_eq(temporal_relation(parse("2020-05"), parse("2020")), WithinCoverage)
  assert_eq(
    temporal_relation(parse("2020-05/2021-02"), parse("2021")),
    PossibleOverlapCoverage,
  )
}

///|
test "relation refuses values without defensible bounds" {
  let qualified = try {
    ignore(temporal_relation(parse("2020?"), parse("2021")))
    false
  } catch {
    Unsupported("ENVELOPE_QUALIFIED", _) => true
    _ => false
  }
  assert_true(qualified)
  let unbounded = try {
    ignore(temporal_relation(parse("../2020"), parse("2021")))
    false
  } catch {
    Unsupported("ENVELOPE_UNBOUNDED", _) => true
    _ => false
  }
  assert_true(unbounded)
}

///|
test "ten-thousand mixed records preserve results and stable counts" {
  let rows : Array[TemporalRecord] = []
  let values = ["2024-05-18", "2024-XX", "2022/2023", "2024?", "2024-02-30"]
  for i = 0; i < 10000; i = i + 1 {
    rows.push(TemporalRecord::{
      record_id: i.to_string(),
      category: "load-test",
      temporal: values[i % 5],
    })
  }
  let report = query_temporal_records(
    rows,
    "2024-05-01",
    "2024-05-31",
    IncludePossibleOverlap,
  )
  assert_eq(report.findings.length(), 10000)
  assert_eq(report.selected_ids.length(), 4000)
  assert_eq(report.within, 2000)
  assert_eq(report.possible_overlap, 2000)
  assert_eq(report.outside, 2000)
  assert_eq(report.needs_review, 2000)
  assert_eq(report.invalid, 2000)
}
