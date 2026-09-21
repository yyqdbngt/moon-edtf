///|
fn envelope_error(input : String) -> String {
  try {
    ignore(date_envelope(parse(input)))
    ""
  } catch {
    Unsupported(code, _) => code
    Syntax(code, _) => code
  }
}

///|
test "complete and partial dates have inclusive calendar envelopes" {
  let exact = date_envelope(parse("1984-06-15"))
  assert_eq(exact.earliest.to_string(), "1984-06-15")
  assert_eq(exact.latest.to_string(), "1984-06-15")
  let month = date_envelope(parse("2000-02"))
  assert_eq(month.earliest.to_string(), "2000-02-01")
  assert_eq(month.latest.to_string(), "2000-02-29")
  let year = date_envelope(parse("1900"))
  assert_eq(year.earliest.to_string(), "1900-01-01")
  assert_eq(year.latest.to_string(), "1900-12-31")
}

///|
test "masked digits widen bounds without changing source value" {
  let decade = date_envelope(parse("201X"))
  assert_eq(decade.earliest.to_string(), "2010-01-01")
  assert_eq(decade.latest.to_string(), "2019-12-31")
  let century = date_envelope(parse("19XX"))
  assert_eq(century.earliest.to_string(), "1900-01-01")
  assert_eq(century.latest.to_string(), "1999-12-31")
  let month = date_envelope(parse("1985-XX"))
  assert_eq(month.earliest.to_string(), "1985-01-01")
  assert_eq(month.latest.to_string(), "1985-12-31")
  let day = date_envelope(parse("1985-04-XX"))
  assert_eq(day.earliest.to_string(), "1985-04-01")
  assert_eq(day.latest.to_string(), "1985-04-30")
}

///|
test "qualified seasons and unbounded values have no fabricated envelope" {
  assert_eq(envelope_error("1984?"), "ENVELOPE_QUALIFIED")
  assert_eq(envelope_error("1984-06~"), "ENVELOPE_QUALIFIED")
  assert_eq(envelope_error("1984-21"), "ENVELOPE_SEASON")
  assert_eq(envelope_error("../1984"), "ENVELOPE_UNBOUNDED")
  assert_eq(envelope_error("1984/"), "ENVELOPE_UNBOUNDED")
  assert_eq(envelope_error("[1667?,1668]"), "ENVELOPE_QUALIFIED")
}

///|
test "closed interval envelope follows independent endpoint precision" {
  let e = date_envelope(parse("2004-06/2005-02"))
  assert_eq(e.earliest.to_string(), "2004-06-01")
  assert_eq(e.latest.to_string(), "2005-02-28")
  assert_eq(envelope_error("2005-02/2004-06"), "ENVELOPE_REVERSED_INTERVAL")
}

///|
test "set envelopes are conservative outer bounds and can include gaps" {
  let one = date_envelope(parse("[1667,1668,1670..1672]"))
  assert_eq(one.earliest.to_string(), "1667-01-01")
  assert_eq(one.latest.to_string(), "1672-12-31")
  let all = date_envelope(parse("{1667,1668,1670..1672}"))
  assert_eq(all, one)
  assert_eq(
    window_relation(parse("[1984,2004]"), "1990-01-01", "1990-12-31"),
    PossibleOverlap,
  )
  assert_eq(
    window_relation(parse("[1666,1667]"), "1985-04-01", "1985-04-30"),
    Outside,
  )
}

///|
test "window relation is conservative for incomplete dates" {
  assert_eq(
    window_relation(parse("1984-06-15"), "1984-01-01", "1984-12-31"),
    Within,
  )
  assert_eq(window_relation(parse("201X"), "2000-01-01", "2009-12-31"), Outside)
  assert_eq(
    window_relation(parse("201X"), "2014-01-01", "2016-12-31"),
    PossibleOverlap,
  )
  assert_eq(window_relation(parse("201X"), "2010-01-01", "2019-12-31"), Within)
}

///|
test "window requires exact ordered query endpoints" {
  let partial = try {
    ignore(window_relation(parse("1984"), "1984", "1985-01-01"))
    false
  } catch {
    Unsupported("WINDOW_NEEDS_EXACT_DAY", _) => true
    _ => false
  }
  assert_true(partial)
  let reversed = try {
    ignore(window_relation(parse("1984"), "1985-01-01", "1984-01-01"))
    false
  } catch {
    Unsupported("WINDOW_REVERSED", _) => true
    _ => false
  }
  assert_true(reversed)
}
