///|
fn normalized(input : String) -> String {
  parse(input).to_string() catch {
    _ => "INVALID"
  }
}

///|
fn is_invalid(input : String) -> Bool {
  try {
    ignore(parse(input))
    false
  } catch {
    _ => true
  }
}

///|
test "exact dates parse and normalize" {
  for
    s in ["1984", "1984-06", "1984-06-15", "-0999", "Y10000", "Y-10000", "0000"] {
    assert_eq(normalized(s), s)
  }
}

///|
test "month boundaries are enforced" {
  for s in ["1984-00", "1984-13", "1984-1", "1984-6"] {
    assert_true(is_invalid(s))
  }
  for s in ["1984-01", "1984-12"] {
    assert_eq(normalized(s), s)
  }
}

///|
test "day boundaries and illegal calendar dates are rejected" {
  for
    s in ["1984-00-10", "1984-01-00", "1984-01-32", "1984-04-31", "1984-02-30"] {
    assert_true(is_invalid(s))
  }
}

///|
test "leap-day rules are applied for exact years" {
  assert_eq(normalized("2000-02-29"), "2000-02-29")
  assert_eq(normalized("2004-02-29"), "2004-02-29")
  assert_true(is_invalid("1900-02-29"))
  assert_true(is_invalid("2001-02-29"))
}

///|
test "uncertain and approximate markers are preserved" {
  for s in ["1984?", "1984~", "1984%"] {
    assert_eq(normalized(s), s)
  }
}

///|
test "component-level qualifiers are preserved" {
  for s in ["1984?-06-11", "1984-06?", "1984-06~", "1984-06%", "1984-06-11?"] {
    assert_eq(normalized(s), s)
  }
}

///|
test "masked low-order digits never become exact years" {
  for s in ["199X", "19XX", "200X"] {
    assert_eq(normalized(s), s)
  }
  assert_eq(normalized("199X"), "199X")
  assert_true(normalized("199X") != "1990")
}

///|
test "intervals parse each endpoint and preserve open states" {
  assert_eq(normalized("2004-01-01/2005"), "2004-01-01/2005")
  assert_eq(normalized("../1984"), "../1984")
  assert_eq(normalized("1984/.."), "1984/..")
  assert_eq(normalized("2004/.."), "2004/..")
  assert_true(is_invalid(".."))
  assert_eq(normalized("1984/"), "1984/")
  assert_eq(normalized("/1984"), "/1984")
}

///|
test "choice sets and range shorthand are supported" {
  assert_eq(normalized("[1667,1668]"), "[1667,1668]")
  assert_eq(normalized("[1667,1668,1670..1672]"), "[1667,1668,1670..1672]")
}

///|
test "batch diagnostics distinguish valid and invalid rows" {
  let rows = diagnose_batch(["1984?", "1984-13", "19XX"])
  assert_eq(rows.length(), 3)
  assert_true(rows[0].valid)
  assert_eq(rows[0].normalized, "1984?")
  assert_false(rows[1].valid)
  assert_eq(rows[1].error_code, "INVALID_MONTH")
  assert_eq(rows[1].error_offset, 4)
  assert_true(rows[2].valid)
  assert_eq(rows[2].normalized, "19XX")
}

///|
test "invalid offsets point at the offending UTF-16 position" {
  let d = diagnose("1984-02-30")
  assert_false(d.valid)
  assert_eq(d.error_code, "INVALID_DAY")
  assert_eq(d.error_offset, 7)
}

///|
test "common malformed inputs are rejected" {
  for
    s in [
      "", "84", "198", "+1984", "1984?~", "1984-06-1", "1984-06-1X", "1984/1985/1986",
      "[1667", "1984-13?",
    ] {
    assert_true(is_invalid(s))
  }
}

///|
test "round-trip preserves semantics for supported values" {
  for
    s in [
      "1984", "1984-06-15", "-0999", "Y10000", "1984?", "1984%", "199X", "19XX",
      "2004-01-01/2005", "../1984", "1984/..", "1984/", "[1667,1668,1670..1672]",
    ] {
    let once = parse(s)
    let twice = parse(normalize(once))
    assert_eq(once, twice)
  }
}

///|
test "exact-date comparison orders complete unqualified dates" {
  let a = parse("1984-06-15")
  let b = parse("1984-06-16")
  assert_eq(compare(a, b), -1)
  assert_eq(compare(b, a), 1)
  assert_eq(compare(a, a), 0)
}

///|
test "comparison refuses qualified or partial dates" {
  let qualified = parse("1984?")
  let exact = parse("1984")
  let rejected = try {
    ignore(compare(qualified, exact))
    false
  } catch {
    Unsupported(_, _) => true
    _ => false
  }
  assert_true(rejected)
}

///|
test "season syntax is parsed as a documented extension" {
  assert_eq(normalized("1984-21"), "1984-21")
  assert_eq(normalized("1984-24"), "1984-24")
  assert_true(is_invalid("1984-20"))
}
