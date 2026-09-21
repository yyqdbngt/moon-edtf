///|
/// The explicit zone spelling is retained. Local, UTC, hour-only shifts and
/// hour-minute shifts are distinct; no implicit host-timezone conversion occurs.
pub(all) enum TimeZone {
  Local
  Utc
  Offset(Int, Int, Int, Bool)
} derive(Eq, @debug.Debug)

///|
/// A complete calendar date followed by HH:MM:SS and an optional zone.
/// Fractions, leap seconds and 24:00 are outside this documented subset.
pub(all) struct EdtfDateTime {
  date : EdtfDate
  hour : Int
  minute : Int
  second : Int
  zone : TimeZone
} derive(Eq, @debug.Debug)

///|
fn two_digits(value : Int) -> String {
  pad4(value)[2:4].to_owned()
}

///|
fn time_zone_to_string(zone : TimeZone) -> String {
  match zone {
    Local => ""
    Utc => "Z"
    Offset(sign, hours, minutes, has_minutes) => {
      let prefix = if sign < 0 { "-" } else { "+" }
      if has_minutes {
        prefix + two_digits(hours) + ":" + two_digits(minutes)
      } else {
        prefix + two_digits(hours)
      }
    }
  }
}

///|
fn date_time_to_string(value : EdtfDateTime) -> String {
  date_to_string(value.date) +
  "T" +
  two_digits(value.hour) +
  ":" +
  two_digits(value.minute) +
  ":" +
  two_digits(value.second) +
  time_zone_to_string(value.zone)
}
