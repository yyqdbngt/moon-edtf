///|
/// Stable public error surface. Every failure is a code plus a half-open
/// UTF-16 offset into the original input. Error values never echo input text.
pub(all) suberror EdtfError {
  Syntax(String, Int)
  Unsupported(String, Int)
} derive(Eq, @debug.Debug)

///|
/// Uncertainty and approximation markers attached to one date component.
pub(all) struct Qualifier {
  uncertain : Bool
  approximate : Bool
} derive(Eq, @debug.Debug)

///|
/// No marker.
pub fn Qualifier::none() -> Qualifier {
  { uncertain: false, approximate: false, }
}

///|
/// An exact year, or a year whose least-significant digits are unspecified.
/// `Masked` keeps the written digit prefix and the number of trailing `X`
/// positions so `19XX` never becomes a fake `1900`.
pub(all) enum YearSpec {
  Exact(Int)
  Masked(String, Int)
} derive(Eq, @debug.Debug)

///|
pub(all) enum MonthSpec {
  Unspecified
  Exact(Int)
  Season(Int)
} derive(Eq, @debug.Debug)

///|
pub(all) enum DaySpec {
  Unspecified
  Exact(Int)
} derive(Eq, @debug.Debug)

///|
/// A parsed EDTF date. Precision is explicit: absent month/day components are
/// represented as `Unspecified`, never as fake 01 values.
pub(all) struct EdtfDate {
  year : YearSpec
  year_qualifier : Qualifier
  month : MonthSpec
  month_qualifier : Qualifier
  day : DaySpec
  day_qualifier : Qualifier
} derive(Eq, @debug.Debug)

///|
/// One interval endpoint. `Open` is the EDTF `..` boundary (also accepted as
/// an empty side in `1984/` or `/1984`).
pub(all) enum Endpoint {
  Known(EdtfDate)
  Open
} derive(Eq, @debug.Debug)

///|
pub(all) struct EdtfInterval {
  start : Endpoint
  end : Endpoint
} derive(Eq, @debug.Debug)

///|
/// The public value union for the supported EDTF subset.
pub(all) enum EdtfValue {
  Date(EdtfDate)
  Interval(EdtfInterval)
  Set(Array[EdtfValue])
  Unknown
} derive(Eq, @debug.Debug)

///|
/// Batch diagnostic record. Valid rows set `error_code` to the empty string
/// and `error_offset` to -1; invalid rows keep `normalized` empty.
pub(all) struct Diagnostic {
  input : String
  valid : Bool
  error_code : String
  error_offset : Int
  normalized : String
} derive(Eq, @debug.Debug)
