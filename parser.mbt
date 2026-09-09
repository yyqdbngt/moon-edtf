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
    if negative {
      raise Syntax("INVALID_YEAR", start)
    }
    if digits.length() == 0 {
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
  let value = parse_int_digits(digits)
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
    return Open
  }
  self.parse_endpoint()
}

///|
fn Parser::parse_set(self : Parser) -> EdtfValue raise EdtfError {
  let start = self.pos
  self.pos += 1
  if self.peek() == 93 {
    raise Syntax("INVALID_SET", start)
  }
  let items : Array[EdtfValue] = []
  while true {
    if self.peek() == 91 {
      raise Syntax("INVALID_SET", self.pos)
    }
    if self.peek() == -1 {
      raise Syntax("INVALID_SET", self.pos)
    }
    let first = self.parse_endpoint()
    let item = if self.peek() == 47 {
      self.pos += 1
      let second = if self.peek() == 44 ||
        self.peek() == 93 ||
        self.peek() == -1 {
        Open
      } else {
        self.parse_endpoint()
      }
      Interval({ start: first, end: second, })
    } else if self.peek() == 46 && self.peek_at(self.pos + 1) == 46 {
      self.pos += 2
      match first {
        Known(start_date) => {
          let second = self.parse_endpoint()
          match second {
            Known(end_date) =>
              Interval({ start: Known(start_date), end: Known(end_date), })
            Open => raise Syntax("INVALID_SET", self.pos)
          }
        }
        Open => raise Syntax("INVALID_SET", self.pos)
      }
    } else {
      match first {
        Known(d) => Date(d)
        Open => raise Syntax("INVALID_SET", self.pos)
      }
    }
    items.push(item)
    match self.peek() {
      44 => {
        self.pos += 1
        if self.peek() == 93 {
          raise Syntax("INVALID_SET", self.pos)
        }
      }
      93 => {
        self.pos += 1
        return Set(items)
      }
      _ => raise Syntax("INVALID_SET", self.pos)
    }
  }
  raise Syntax("INVALID_SET", start)
}

///|
fn Parser::parse_value(self : Parser) -> EdtfValue raise EdtfError {
  if self.peek() == 91 {
    return self.parse_set()
  }
  let first = if self.peek() == 47 { Open } else { self.parse_endpoint() }
  if self.peek() == 47 {
    self.pos += 1
    let second = self.parse_interval_end()
    return Interval({ start: first, end: second, })
  }
  match first {
    Known(d) => Date(d)
    Open => Unknown
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
