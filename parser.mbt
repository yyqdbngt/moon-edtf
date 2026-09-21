///|
priv struct Parser {
  source : String
  mut pos : Int
}

///|
fn Parser::peek(self : Parser) -> Int {
  self.peek_at(self.pos)
}

///|
fn Parser::peek_at(self : Parser, offset : Int) -> Int {
  if offset >= self.source.length() {
    -1
  } else {
    self.source[offset].to_int()
  }
}

///|
fn is_digit(c : Int) -> Bool {
  c >= 48 && c <= 57
}

///|
fn parse_int_digits(digits : String) -> Int {
  let mut value = 0
  for i = 0; i < digits.length(); i = i + 1 {
    value = value * 10 + (digits[i].to_int() - 48)
  }
  value
}

///|
fn Parser::read_two_digits(
  self : Parser,
  code : String,
) -> String raise EdtfError {
  let start = self.pos
  if self.pos + 2 > self.source.length() {
    raise Syntax(code, self.pos)
  }
  if !is_digit(self.peek()) || !is_digit(self.peek_at(self.pos + 1)) {
    raise Syntax(code, self.pos)
  }
  self.pos += 2
  self.source[start:self.pos].to_owned()
}

///|
fn Parser::parse_qualifier(self : Parser) -> Qualifier {
  match self.peek() {
    63 => {
      self.pos += 1
      { uncertain: true, approximate: false, }
    }
    126 => {
      self.pos += 1
      { uncertain: false, approximate: true, }
    }
    37 => {
      self.pos += 1
      { uncertain: true, approximate: true, }
    }
    _ => Qualifier::none()
  }
}

///|
fn Parser::parse_year(self : Parser) -> (YearSpec, Qualifier) raise EdtfError {
  let start = self.pos
  let mut negative = false
  let extended = self.peek() == 89
  if extended {
    self.pos += 1
  }
  if self.peek() == 45 {
    negative = true
    self.pos += 1
  }
  let digits_start = self.pos
  while is_digit(self.peek()) {
    self.pos += 1
  }
  let digits_end = self.pos
  let x_start = self.pos
  while self.peek() == 88 {
    self.pos += 1
  }
  let x_count = self.pos - x_start
  if digits_end - digits_start == 0 {
    raise Syntax("EXPECTED_YEAR", start)
  }
  if x_count > 0 && is_digit(self.peek()) {
    raise Syntax("INVALID_YEAR", self.pos)
  }
  let digits = self.source[digits_start:digits_end].to_owned()
  let qualifier = self.parse_qualifier()
  if x_count > 0 {
    if negative || extended {
      raise Syntax("INVALID_YEAR", start)
    }
    if digits.length() + x_count != 4 || x_count > 2 {
      raise Syntax("INVALID_YEAR", start)
    }
    return (Masked(digits, x_count), qualifier)
  }
  if digits.length() < 4 {
    raise Syntax("INVALID_YEAR", start)
  }
  if digits.length() > 9 {
    raise Syntax("YEAR_LIMIT", start)
  }
  if (extended && digits.length() <= 4) || (!extended && digits.length() != 4) {
    raise Syntax("INVALID_YEAR", start)
  }
  let value = parse_int_digits(digits)
  if extended && value < 10000 {
    raise Syntax("INVALID_YEAR", start)
  }
  if negative {
    if value == 0 {
      raise Syntax("INVALID_YEAR", start)
    }
    return (Exact(-value), qualifier)
  }
  (Exact(value), qualifier)
}

///|
fn Parser::parse_month(self : Parser) -> (MonthSpec, Qualifier) raise EdtfError {
  let start = self.pos
  self.pos += 1
  if self.peek() == 88 && self.peek_at(self.pos + 1) == 88 {
    self.pos += 2
    return (Masked, self.parse_qualifier())
  }
  let digits = self.read_two_digits("EXPECTED_MONTH")
  let value = parse_int_digits(digits)
  let qualifier = self.parse_qualifier()
  if value >= 1 && value <= 12 {
    return (Exact(value), qualifier)
  }
  if value >= 21 && value <= 24 {
    return (Season(value), qualifier)
  }
  raise Syntax("INVALID_MONTH", start)
}

///|
fn Parser::parse_day(self : Parser) -> (DaySpec, Qualifier) raise EdtfError {
  let start = self.pos
  self.pos += 1
  if self.peek() == 88 && self.peek_at(self.pos + 1) == 88 {
    self.pos += 2
    return (Masked, self.parse_qualifier())
  }
  let digits = self.read_two_digits("EXPECTED_DAY")
  let value = parse_int_digits(digits)
  let qualifier = self.parse_qualifier()
  if value < 1 || value > 31 {
    raise Syntax("INVALID_DAY", start)
  }
  (Exact(value), qualifier)
}

///|
fn common_month_days(month : Int) -> Int {
  if month == 2 {
    28
  } else if month == 4 || month == 6 || month == 9 || month == 11 {
    30
  } else {
    31
  }
}

///|
fn is_leap_year(year : Int) -> Bool {
  let y = if year < 0 { -year } else { year }
  y % 400 == 0 || (y % 4 == 0 && y % 100 != 0)
}

///|
fn month_days(year : Int, month : Int) -> Int {
  if month == 2 && is_leap_year(year) {
    29
  } else {
    common_month_days(month)
  }
}

///|
fn validate_day(
  year : YearSpec,
  month : MonthSpec,
  day : DaySpec,
  day_start : Int,
) -> Unit raise EdtfError {
  match (month, day) {
    (Unspecified, Exact(_)) => raise Syntax("INVALID_DATE", day_start)
    (Season(_), Exact(_)) => raise Syntax("INVALID_DATE", day_start)
    (Masked, Exact(_)) => raise Syntax("INVALID_DATE", day_start)
    (Exact(m), Exact(d)) => {
      let limit = match year {
        Exact(y) => month_days(y, m)
        _ => if m == 2 { 29 } else { common_month_days(m) }
      }
      if d > limit {
        raise Syntax("INVALID_DAY", day_start)
      }
    }
    _ => ()
  }
}

///|
fn Parser::parse_date(self : Parser) -> EdtfDate raise EdtfError {
  let (year, year_qualifier) = self.parse_year()
  let mut month : MonthSpec = Unspecified
  let mut month_qualifier = Qualifier::none()
  let mut day : DaySpec = Unspecified
  let mut day_qualifier = Qualifier::none()
  if self.peek() == 45 {
    if year is Masked(_, _) {
      raise Syntax("INVALID_DATE", self.pos)
    }
    let (m, mq) = self.parse_month()
    month = m
    month_qualifier = mq
    if self.peek() == 45 {
      match month {
        Season(_) => raise Syntax("INVALID_DATE", self.pos)
        _ => ()
      }
      let day_start = self.pos
      let (d, dq) = self.parse_day()
      day = d
      day_qualifier = dq
      validate_day(year, month, day, day_start)
    }
  }
  // A suffix qualifies its component and every component to its left.
  month_qualifier = {
    uncertain: month_qualifier.uncertain || day_qualifier.uncertain,
    approximate: month_qualifier.approximate || day_qualifier.approximate,
  }
  let year_qualifier = {
    uncertain: year_qualifier.uncertain || month_qualifier.uncertain,
    approximate: year_qualifier.approximate || month_qualifier.approximate,
  }
  { year, year_qualifier, month, month_qualifier, day, day_qualifier, }
}

///|
fn Parser::parse_endpoint(self : Parser) -> Endpoint raise EdtfError {
  if self.peek() == 46 && self.peek_at(self.pos + 1) == 46 {
    self.pos += 2
    return Open
  }
  Known(self.parse_date())
}

///|
fn Parser::parse_interval_end(self : Parser) -> Endpoint raise EdtfError {
  if self.peek() == -1 {
    return Unknown
  }
  self.parse_endpoint()
}

///|
fn Parser::expect_time_separator(
  self : Parser,
  expected : Int,
  code : String,
) -> Unit raise EdtfError {
  if self.peek() != expected {
    raise Syntax(code, self.pos)
  }
  self.pos += 1
}

///|
fn Parser::parse_datetime(
  self : Parser,
  date : EdtfDate,
) -> EdtfDateTime raise EdtfError {
  let start = self.pos
  match (date.year, date.month, date.day) {
    (Exact(_), Exact(_), Exact(_)) => ()
    _ => raise Syntax("DATETIME_NEEDS_EXACT_DATE", start)
  }
  if date.year_qualifier.uncertain ||
    date.year_qualifier.approximate ||
    date.month_qualifier.uncertain ||
    date.month_qualifier.approximate ||
    date.day_qualifier.uncertain ||
    date.day_qualifier.approximate {
    raise Syntax("DATETIME_QUALIFIED", start)
  }
  self.pos += 1 // T
  let hour_start = self.pos
  let hour = parse_int_digits(self.read_two_digits("EXPECTED_HOUR"))
  if hour > 23 {
    raise Syntax("INVALID_HOUR", hour_start)
  }
  self.expect_time_separator(58, "EXPECTED_TIME_SEPARATOR")
  let minute_start = self.pos
  let minute = parse_int_digits(self.read_two_digits("EXPECTED_MINUTE"))
  if minute > 59 {
    raise Syntax("INVALID_MINUTE", minute_start)
  }
  self.expect_time_separator(58, "EXPECTED_TIME_SEPARATOR")
  let second_start = self.pos
  let second = parse_int_digits(self.read_two_digits("EXPECTED_SECOND"))
  if second > 59 {
    raise Syntax("INVALID_SECOND", second_start)
  }
  let zone = match self.peek() {
    90 => {
      self.pos += 1
      Utc
    }
    43 | 45 => {
      let sign = if self.peek() == 45 { -1 } else { 1 }
      self.pos += 1
      let shift_start = self.pos
      let hours = parse_int_digits(self.read_two_digits("EXPECTED_OFFSET_HOUR"))
      let mut minutes = 0
      let mut has_minutes = false
      if self.peek() == 58 {
        self.pos += 1
        minutes = parse_int_digits(
          self.read_two_digits("EXPECTED_OFFSET_MINUTE"),
        )
        has_minutes = true
      }
      if hours > 14 || minutes > 59 || (hours == 14 && minutes != 0) {
        raise Syntax("INVALID_OFFSET", shift_start)
      }
      Offset(sign, hours, minutes, has_minutes)
    }
    _ => Local
  }
  { date, hour, minute, second, zone, }
}

///|
fn validate_set_range(
  start : EdtfDate,
  end : EdtfDate,
  offset : Int,
) -> Unit raise EdtfError {
  if is_qualified(start) || is_qualified(end) {
    raise Syntax("INVALID_SET_RANGE", offset)
  }
  match (start.year, end.year) {
    (Exact(_), Exact(_)) => ()
    _ => raise Syntax("INVALID_SET_RANGE", offset)
  }
  match (start.month, end.month) {
    (Unspecified, Unspecified) | (Exact(_), Exact(_)) => ()
    _ => raise Syntax("INVALID_SET_RANGE", offset)
  }
  match (start.day, end.day) {
    (Unspecified, Unspecified) | (Exact(_), Exact(_)) => ()
    _ => raise Syntax("INVALID_SET_RANGE", offset)
  }
  if calendar_compare(date_edge(start, false), date_edge(end, true)) > 0 {
    raise Syntax("INVALID_SET_RANGE", offset)
  }
}

///|
fn Parser::parse_set(self : Parser) -> EdtfValue raise EdtfError {
  let start = self.pos
  let all_members = self.peek() == 123
  let closing = if all_members { 125 } else { 93 }
  self.pos += 1
  if self.peek() == closing {
    raise Syntax("INVALID_SET", start)
  }
  let items : Array[EdtfValue] = []
  while true {
    if self.peek() == 91 || self.peek() == 123 {
      raise Syntax("INVALID_SET", self.pos)
    }
    if self.peek() == -1 {
      raise Syntax("INVALID_SET", self.pos)
    }
    let range_start = self.pos
    let first = self.parse_date()
    let item = if self.peek() == 46 && self.peek_at(self.pos + 1) == 46 {
      self.pos += 2
      let end = self.parse_date()
      validate_set_range(first, end, range_start)
      Range(first, end)
    } else {
      Date(first)
    }
    items.push(item)
    match self.peek() {
      44 => {
        self.pos += 1
        if self.peek() == closing {
          raise Syntax("INVALID_SET", self.pos)
        }
      }
      _ => {
        if self.peek() == closing {
          self.pos += 1
          return if all_members { AllSet(items) } else { Set(items) }
        }
        raise Syntax("INVALID_SET", self.pos)
      }
    }
  }
  raise Syntax("INVALID_SET", start)
}

///|
fn Parser::parse_value(self : Parser) -> EdtfValue raise EdtfError {
  if self.peek() == 91 || self.peek() == 123 {
    return self.parse_set()
  }
  let first = if self.peek() == 47 { Unknown } else { self.parse_endpoint() }
  if self.peek() == 84 {
    return match first {
      Known(date) => DateTime(self.parse_datetime(date))
      _ => raise Syntax("DATETIME_NEEDS_EXACT_DATE", self.pos)
    }
  }
  if self.peek() == 47 {
    self.pos += 1
    let second = self.parse_interval_end()
    return Interval({ start: first, end: second, })
  }
  match first {
    Known(d) => Date(d)
    Open | Unknown => raise Syntax("EXPECTED_INTERVAL", self.pos)
  }
}

///|
/// Parse a strict EDTF subset. Raises `EdtfError::Syntax(code, offset)` on
/// invalid input and never guesses missing components or uncertain markers.
pub fn parse(input : String) -> EdtfValue raise EdtfError {
  if input.length() == 0 {
    raise Syntax("EMPTY_INPUT", 0)
  }
  let p = Parser::{ source: input, pos: 0, }
  let value = p.parse_value()
  if p.pos != input.length() {
    raise Syntax("EXTRA_CONTENT", p.pos)
  }
  value
}
