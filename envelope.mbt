///|
/// One exact calendar day. This type is used only as a conservative bound;
/// it must not be confused with the precision of the source EDTF value.
pub(all) struct CalendarDay {
  year : Int
  month : Int
  day : Int
} derive(Eq, @debug.Debug)

///|
pub fn CalendarDay::to_string(self : CalendarDay) -> String {
  exact_year_to_string(self.year) +
  "-" +
  pad4(self.month)[2:4].to_owned() +
  "-" +
  pad4(self.day)[2:4].to_owned()
}

///|
/// Inclusive lower and upper bounds of an unqualified date or closed
/// interval. An envelope can include days that the source expression does not
/// actually denote; callers must not treat it as a complete date expansion.
pub(all) struct DateEnvelope {
  earliest : CalendarDay
  latest : CalendarDay
} derive(Eq, @debug.Debug)

///|
pub(all) enum WindowRelation {
  Outside
  Within
  PossibleOverlap
} derive(Eq, @debug.Debug)

///|
fn calendar_compare(a : CalendarDay, b : CalendarDay) -> Int {
  if a.year != b.year {
    return if a.year < b.year { -1 } else { 1 }
  }
  if a.month != b.month {
    return if a.month < b.month { -1 } else { 1 }
  }
  if a.day != b.day {
    return if a.day < b.day { -1 } else { 1 }
  }
  0
}

///|
fn is_qualified(date : EdtfDate) -> Bool {
  date.year_qualifier.uncertain ||
  date.year_qualifier.approximate ||
  date.month_qualifier.uncertain ||
  date.month_qualifier.approximate ||
  date.day_qualifier.uncertain ||
  date.day_qualifier.approximate
}

///|
fn year_bounds(year : YearSpec) -> (Int, Int) {
  match year {
    Exact(value) => (value, value)
    Masked(prefix, x_count) => {
      let mut factor = 1
      for _ in 0..<x_count {
        factor *= 10
      }
      let first = parse_int_digits(prefix) * factor
      (first, first + factor - 1)
    }
  }
}

///|
fn date_edge(date : EdtfDate, latest : Bool) -> CalendarDay raise EdtfError {
  if is_qualified(date) {
    // An uncertain or approximate label has no defensible numeric margin.
    raise Unsupported("ENVELOPE_QUALIFIED", 0)
  }
  let (first_year, last_year) = year_bounds(date.year)
  let year = if latest { last_year } else { first_year }
  match date.month {
    Unspecified | Masked => {
      if date.day is Exact(_) {
        raise Unsupported("ENVELOPE_INVALID_MODEL", 0)
      }
      {
        year,
        month: if latest {
          12
        } else {
          1
        },
        day: if latest {
          31
        } else {
          1
        },
      }
    }
    Season(_) => raise Unsupported("ENVELOPE_SEASON", 0)
    Exact(month) => {
      if date.year is Masked(_, _) || month < 1 || month > 12 {
        raise Unsupported("ENVELOPE_INVALID_MODEL", 0)
      }
      let day = match date.day {
        Unspecified | Masked => if latest { month_days(year, month) } else { 1 }
        Exact(value) => {
          if value < 1 || value > month_days(year, month) {
            raise Unsupported("ENVELOPE_INVALID_MODEL", 0)
          }
          value
        }
      }
      { year, month, day, }
    }
  }
}

///|
/// Give a safe inclusive envelope for a parser-produced date or closed
/// interval. Masked digits widen the bound; missing components widen it to
/// their entire calendar period. Qualified dates, seasons, open/unknown
/// endpoints are refused rather than guessed. Sets and ranges receive only
/// their outer envelope, which can include gaps with no actual member.
pub fn date_envelope(value : EdtfValue) -> DateEnvelope raise EdtfError {
  match value {
    Date(date) => {
      let earliest = date_edge(date, false)
      let latest = date_edge(date, true)
      { earliest, latest, }
    }
    Interval(interval) =>
      match (interval.start, interval.end) {
        (Known(start), Known(end)) => {
          let earliest = date_edge(start, false)
          let latest = date_edge(end, true)
          if calendar_compare(earliest, latest) > 0 {
            raise Unsupported("ENVELOPE_REVERSED_INTERVAL", 0)
          }
          { earliest, latest, }
        }
        _ => raise Unsupported("ENVELOPE_UNBOUNDED", 0)
      }
    DateTime(_) => raise Unsupported("ENVELOPE_DATETIME", 0)
    Range(start, end) => {
      let earliest = date_edge(start, false)
      let latest = date_edge(end, true)
      if calendar_compare(earliest, latest) > 0 {
        raise Unsupported("ENVELOPE_REVERSED_RANGE", 0)
      }
      { earliest, latest, }
    }
    Set(items) | AllSet(items) => {
      if items.length() == 0 {
        raise Unsupported("ENVELOPE_EMPTY_SET", 0)
      }
      let first = date_envelope(items[0])
      let mut earliest = first.earliest
      let mut latest = first.latest
      for i = 1; i < items.length(); i = i + 1 {
        let bounds = date_envelope(items[i])
        if calendar_compare(bounds.earliest, earliest) < 0 {
          earliest = bounds.earliest
        }
        if calendar_compare(bounds.latest, latest) > 0 {
          latest = bounds.latest
        }
      }
      { earliest, latest, }
    }
  }
}

///|
fn exact_query_day(value : EdtfValue) -> CalendarDay raise EdtfError {
  match value {
    Date(date) => {
      if is_qualified(date) {
        raise Unsupported("WINDOW_NEEDS_EXACT_DAY", 0)
      }
      match (date.year, date.month, date.day) {
        (Exact(year), Exact(month), Exact(day)) => { year, month, day, }
        _ => raise Unsupported("WINDOW_NEEDS_EXACT_DAY", 0)
      }
    }
    _ => raise Unsupported("WINDOW_NEEDS_EXACT_DAY", 0)
  }
}

///|
/// Classify an EDTF value against an inclusive exact-day search window.
/// `PossibleOverlap` means only the conservative envelope intersects, not
/// that a particular day is known to occur. The query endpoints must each be
/// a complete, unqualified `YYYY-MM-DD` EDTF date.
pub fn window_relation(
  value : EdtfValue,
  query_start : String,
  query_end : String,
) -> WindowRelation raise EdtfError {
  let start = exact_query_day(parse(query_start))
  let end = exact_query_day(parse(query_end))
  if calendar_compare(start, end) > 0 {
    raise Unsupported("WINDOW_REVERSED", 0)
  }
  let envelope = date_envelope(value)
  relation_for_envelope(envelope, start, end)
}

///|
fn relation_for_envelope(
  envelope : DateEnvelope,
  start : CalendarDay,
  end : CalendarDay,
) -> WindowRelation {
  if calendar_compare(envelope.latest, start) < 0 ||
    calendar_compare(envelope.earliest, end) > 0 {
    Outside
  } else if calendar_compare(envelope.earliest, start) >= 0 &&
    calendar_compare(envelope.latest, end) <= 0 {
    Within
  } else {
    PossibleOverlap
  }
}
