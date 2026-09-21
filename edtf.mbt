///|
fn pad4(value : Int) -> String {
  if value < 10 {
    "000" + value.to_string()
  } else if value < 100 {
    "00" + value.to_string()
  } else if value < 1000 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
fn exact_year_to_string(value : Int) -> String {
  if value < 0 {
    let magnitude = -value
    if magnitude < 10000 {
      "-" + pad4(magnitude)
    } else {
      "Y-" + magnitude.to_string()
    }
  } else if value < 10000 {
    pad4(value)
  } else {
    "Y" + value.to_string()
  }
}

///|
fn qualifier_to_string(q : Qualifier) -> String {
  if q.uncertain && q.approximate {
    "%"
  } else if q.uncertain {
    "?"
  } else if q.approximate {
    "~"
  } else {
    ""
  }
}

///|
fn year_to_string(year : YearSpec) -> String {
  match year {
    Exact(value) => exact_year_to_string(value)
    Masked(prefix, x_count) => prefix + "X".repeat(x_count)
  }
}

///|
fn month_to_string(month : MonthSpec) -> String {
  match month {
    Unspecified => ""
    Exact(value) => pad4(value)[2:4].to_owned()
    Masked => "XX"
    Season(value) => pad4(value)[2:4].to_owned()
  }
}

///|
fn day_to_string(day : DaySpec) -> String {
  match day {
    Unspecified => ""
    Exact(value) => pad4(value)[2:4].to_owned()
    Masked => "XX"
  }
}

///|
fn date_to_string(date : EdtfDate) -> String {
  // Omit suffix bits already encoded by a qualifier to the right.
  let year_suffix = {
    uncertain: date.year_qualifier.uncertain && !date.month_qualifier.uncertain,
    approximate: date.year_qualifier.approximate &&
    !date.month_qualifier.approximate,
  }
  let month_suffix = {
    uncertain: date.month_qualifier.uncertain && !date.day_qualifier.uncertain,
    approximate: date.month_qualifier.approximate &&
    !date.day_qualifier.approximate,
  }
  let year = year_to_string(date.year) + qualifier_to_string(year_suffix)
  match date.month {
    Unspecified => year
    _ => {
      let month = "-" +
        month_to_string(date.month) +
        qualifier_to_string(month_suffix)
      match date.day {
        Unspecified => year + month
        _ =>
          year +
          month +
          "-" +
          day_to_string(date.day) +
          qualifier_to_string(date.day_qualifier)
      }
    }
  }
}

///|
fn endpoint_to_string(endpoint : Endpoint) -> String {
  match endpoint {
    Known(date) => date_to_string(date)
    Open => ".."
    Unknown => ""
  }
}

///|
fn value_to_string(value : EdtfValue) -> String {
  match value {
    Date(date) => date_to_string(date)
    DateTime(date_time) => date_time_to_string(date_time)
    Interval(interval) =>
      endpoint_to_string(interval.start) +
      "/" +
      endpoint_to_string(interval.end)
    Set(items) | AllSet(items) => {
      let (open, close) = match value {
        AllSet(_) => ("{", "}")
        _ => ("[", "]")
      }
      let mut out = open
      for i = 0; i < items.length(); i = i + 1 {
        if i > 0 {
          out = out + ","
        }
        out = out + value_to_string(items[i])
      }
      out + close
    }
    Range(start, end) => date_to_string(start) + ".." + date_to_string(end)
  }
}

///|
/// Return a normalized EDTF spelling. Normalization never promotes an
/// uncertain/approximate/masked value to a precise timestamp.
pub fn EdtfValue::to_string(self : EdtfValue) -> String {
  value_to_string(self)
}

///|
/// Convenience alias for `value.to_string()`.
pub fn normalize(value : EdtfValue) -> String {
  value.to_string()
}

///|
/// Return a single diagnostic record. Invalid rows carry a stable error code
/// and the original UTF-16 offset; valid rows carry the normalized EDTF string.
pub fn diagnose(input : String) -> Diagnostic {
  try {
    let value = parse(input)
    {
      input,
      valid: true,
      error_code: "",
      error_offset: -1,
      normalized: value.to_string(),
    }
  } catch {
    Syntax(code, offset) =>
      {
        input,
        valid: false,
        error_code: code,
        error_offset: offset,
        normalized: "",
      }
    Unsupported(code, offset) =>
      {
        input,
        valid: false,
        error_code: code,
        error_offset: offset,
        normalized: "",
      }
  }
}

///|
/// Batch-diagnose an array of EDTF candidate strings without throwing.
pub fn diagnose_batch(inputs : Array[String]) -> Array[Diagnostic] {
  let out : Array[Diagnostic] = []
  for i = 0; i < inputs.length(); i = i + 1 {
    out.push(diagnose(inputs[i]))
  }
  out
}

///|
fn as_date(value : EdtfValue) -> EdtfDate raise EdtfError {
  match value {
    Date(date) => date
    _ => raise Unsupported("COMPARE_UNSUPPORTED", 0)
  }
}

///|
fn assert_unqualified(date : EdtfDate) -> Unit raise EdtfError {
  if date.year_qualifier.uncertain ||
    date.year_qualifier.approximate ||
    date.month_qualifier.uncertain ||
    date.month_qualifier.approximate ||
    date.day_qualifier.uncertain ||
    date.day_qualifier.approximate {
    raise Unsupported("COMPARE_QUALIFIED", 0)
  }
}

///|
fn exact_year(date : EdtfDate) -> Int raise EdtfError {
  match date.year {
    Exact(value) => value
    Masked(_, _) => raise Unsupported("COMPARE_PRECISION", 0)
  }
}

///|
fn exact_month(date : EdtfDate) -> Int raise EdtfError {
  match date.month {
    Exact(value) => value
    _ => raise Unsupported("COMPARE_PRECISION", 0)
  }
}

///|
fn exact_day(date : EdtfDate) -> Int raise EdtfError {
  match date.day {
    Exact(value) => value
    _ => raise Unsupported("COMPARE_PRECISION", 0)
  }
}

///|
/// Compare only complete, unqualified exact dates. Qualified, partial, masked,
/// open, unknown, set, and interval values raise `Unsupported` instead of
/// pretending to have a precise order.
pub fn compare(left : EdtfValue, right : EdtfValue) -> Int raise EdtfError {
  let a = as_date(left)
  let b = as_date(right)
  assert_unqualified(a)
  assert_unqualified(b)
  let year_a = exact_year(a)
  let year_b = exact_year(b)
  let month_a = exact_month(a)
  let month_b = exact_month(b)
  let day_a = exact_day(a)
  let day_b = exact_day(b)
  if year_a != year_b {
    return if year_a < year_b { -1 } else { 1 }
  }
  if month_a != month_b {
    return if month_a < month_b { -1 } else { 1 }
  }
  if day_a != day_b {
    return if day_a < day_b { -1 } else { 1 }
  }
  0
}
