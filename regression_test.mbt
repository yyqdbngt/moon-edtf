///|
test "unknown and open endpoints retain different meanings" {
  assert_true(parse("1984/") != parse("1984/.."))
  assert_true(parse("/1984") != parse("../1984"))
  for s in ["1984/", "/1984", "../1984", "1984/.."] {
    let value = parse(s)
    assert_eq(value.to_string(), s)
    assert_eq(parse(value.to_string()), value)
  }
  match parse("1984/") {
    Interval({ end: Unknown, .. }) => ()
    _ => fail("empty endpoint must be Unknown")
  }
}

///|
test "choice ranges are not slash intervals" {
  let value = parse("[1667,1670..1672]")
  match value {
    Set([Date(_), Range(_, _)]) => ()
    _ => fail("range must remain a set range")
  }
  assert_eq(value.to_string(), "[1667,1670..1672]")
  assert_false(diagnose("[1667,1670/1672]").valid)
}

///|
test "suffix qualifier scope includes all preceding components" {
  match parse("1984-06-11?") {
    Date(d) => {
      assert_true(d.year_qualifier.uncertain)
      assert_true(d.month_qualifier.uncertain)
      assert_true(d.day_qualifier.uncertain)
    }
    _ => fail("expected date")
  }
  match parse("1984-06?") {
    Date(d) => {
      assert_true(d.year_qualifier.uncertain)
      assert_true(d.month_qualifier.uncertain)
      assert_false(d.day_qualifier.uncertain)
    }
    _ => fail("expected date")
  }
  for s in ["1984?-06~-11", "1984%-06-11?", "1984?-06?-11?", "1984-06%-11~"] {
    let v = parse(s)
    assert_eq(parse(v.to_string()), v)
  }
}

///|
test "comparison validates full precision before early ordering" {
  for
    (a, b) in [
      ("1984", "1985"),
      ("1984-06", "1984-07"),
      ("1984", "1985-01-01"),
      ("1984-21", "1985-01-01"),
    ] {
    for (left, right) in [(a, b), (b, a)] {
      let rejected = try {
        ignore(compare(parse(left), parse(right)))
        false
      } catch {
        Unsupported("COMPARE_PRECISION", _) => true
        _ => false
      }
      assert_true(rejected)
    }
  }
}

///|
test "extended and masked years obey documented grammar limits" {
  for
    s in [
      "10000", "-10000", "Y1984", "Y00000", "1X", "199XX", "1XXX", "Y19XX", "19XX-04-31",
      "19XX-02-30", "19XX-02-29",
    ] {
    assert_false(diagnose(s).valid)
  }
  for s in ["Y10000", "Y-10000", "Y999999999", "199X", "19XX"] {
    assert_eq(parse(s).to_string(), s)
  }
}
