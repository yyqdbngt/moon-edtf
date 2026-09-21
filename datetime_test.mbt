///|
test "complete EDTF date-times retain local UTC and offset spellings" {
  for
    s in [
      "1985-04-12T23:20:30", "1985-04-12T23:20:30Z", "1985-04-12T23:20:30-04", "1985-04-12T23:20:30+04:30",
      "1985-04-12T00:00:00+14:00",
    ] {
    let value = parse(s)
    assert_eq(value.to_string(), s)
    assert_eq(parse(value.to_string()), value)
  }
}

///|
test "date-time zone is structured and not silently converted" {
  match parse("1985-04-12T23:20:30-04") {
    DateTime(
      { hour: 23, minute: 20, second: 30, zone: Offset(-1, 4, 0, false), .. }
    ) => ()
    _ => fail("hour-only shift must be retained")
  }
  assert_true(
    parse("1985-04-12T23:20:30Z") != parse("1985-04-12T23:20:30+00:00"),
  )
}

///|
test "invalid clock and zone values report original offsets" {
  for
    (input, code, offset) in [
      ("1985-04-12T24:00:00", "INVALID_HOUR", 11),
      ("1985-04-12T23:60:00", "INVALID_MINUTE", 14),
      ("1985-04-12T23:20:60", "INVALID_SECOND", 17),
      ("1985-04-12T23:20:30+14:01", "INVALID_OFFSET", 20),
      ("1985-04-12T23:20:30-15", "INVALID_OFFSET", 20),
    ] {
    let row = diagnose(input)
    assert_false(row.valid)
    assert_eq(row.error_code, code)
    assert_eq(row.error_offset, offset)
  }
}

///|
test "time requires a complete exact date and full seconds" {
  for
    s in [
      "1985T23:20:30", "1985-04T23:20:30", "1985-04-XXT23:20:30", "1985-04-12?T23:20:30",
      "1985-04-12T23:20", "1985-04-12T23:20:30+04:60", "1985-04-12T23:20:30+04:3",
      "1985-04-12T23:20:30.5Z", "1985-04-12T23:20:30/1986", "1985-04-12t23:20:30z",
    ] {
    assert_false(diagnose(s).valid)
  }
}

///|
test "date-time has no date-only envelope or implicit comparison" {
  let value = parse("1985-04-12T23:20:30Z")
  assert_eq(envelope_error(value.to_string()), "ENVELOPE_DATETIME")
  let rejected = try {
    ignore(compare(value, parse("1985-04-12")))
    false
  } catch {
    Unsupported("COMPARE_UNSUPPORTED", _) => true
    _ => false
  }
  assert_true(rejected)
}
