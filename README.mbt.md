# Moon EDTF

Pure-MoonBit parser for a conservative EDTF subset. It preserves uncertainty,
approximation, masked low-order digits, and open/unknown interval endpoints.
Zero third-party package dependencies.

## Consumer example

After adding `yyqdbngt/moon_edtf@0.1.0`, import it in your `moon.pkg`:

```text
import {
  "yyqdbngt/moon_edtf" @edtf,
}
```

```moonbit nocheck
///|
fn main {
  let value = try! @edtf.parse("1984?")
  println(value.to_string())
  let rows = @edtf.diagnose_batch(["1984?", "1984-13"])
  println(rows[0].normalized)
}
```

The source repository contains a runnable version in `examples/basic`.

## Public API

- `parse(input : String) -> EdtfValue raise EdtfError`
- `EdtfValue::to_string(self) -> String`
- `normalize(value : EdtfValue) -> String`
- `diagnose(input : String) -> Diagnostic`
- `diagnose_batch(inputs : Array[String]) -> Array[Diagnostic]`
- `compare(left : EdtfValue, right : EdtfValue) -> Int raise EdtfError`

`EdtfError` is a stable error type with variants `Syntax(code, offset)` and
`Unsupported(code, offset)`. `offset` is a half-open UTF-16 offset into the
original input. Error values do not echo input text.

`Diagnostic` contains `input`, `valid`, `error_code`, `error_offset`, and
`normalized`. Valid rows set `error_code` to `""` and `error_offset` to `-1`.
Invalid rows keep `normalized` as `""`.

## Supported EDTF subset

- Exact dates: `YYYY`, `YYYY-MM`, `YYYY-MM-DD`, negative years, and years with
  more than four digits. Exact years are limited to nine decimal digits to fit
  `Int`.
- Seasons: `YYYY-21` through `YYYY-24` as a documented extension. A season has
  no day component.
- Qualifiers: `?` (uncertain), `~` (approximate), `%` (both). Qualifiers may
  apply to the year, month, or day component.
- Masked low-order year digits: `199X`, `19XX`. Serialization preserves the
  mask instead of inventing `1990` or `1900`.
- Intervals: `start/end` with `..` or an empty side representing an open
  endpoint. Bare `..` is `EdtfValue::Unknown`.
- Choice sets: `[1667,1668]` and `[1667,1668,1670..1672]`. A set-local `a..b`
  range is normalized as an interval `a/b`.
- Batch diagnostics with stable error codes.

Month and day boundaries are validated. For exact years, `02-29` uses the
proleptic Gregorian leap-year rule. For masked years the leap-year status is
unknown, so `02-29` receives only the basic day-range check.

## Explicit non-goals

No natural-language date recognition. No complete calendar/timeline expansion.
No conversion of uncertain/approximate/masked values into precise timestamps.
No time/zone syntax, masked month/day, nested sets, open/unknown set endpoints,
or full EDTF Level 1/2 coverage.

## Comparison contract

`compare` only orders two complete, unqualified exact dates (`YYYY-MM-DD`).
Qualified, partial, masked, interval, set, open, and unknown values raise
`Unsupported` with a stable code; they are never coerced into a fake precise
order.

## License

Apache-2.0. See repository `docs/provenance.md` for EDTF sources, ecosystem
overlap findings, and AI-assisted development disclosure.