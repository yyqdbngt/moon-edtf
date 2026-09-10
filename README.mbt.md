# Moon EDTF

Pure-MoonBit parser for a conservative EDTF subset. It preserves uncertainty,
approximation, masked low-order digits, and open/unknown interval endpoints.
Zero third-party package dependencies.

## Consumer example

After publication is confirmed, add `yyqdbngt/moon_edtf@0.1.0` and import it
in your `moon.pkg`. Source-based verification is documented in the repository README.

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
  more than four digits with a mandatory Y prefix (Y10000, Y-10000). Exact years are limited to nine decimal digits to fit
  `Int`.
- Seasons: `YYYY-21` through `YYYY-24` as a documented extension. A season has
  no day component.
- Qualifiers: `?` (uncertain), `~` (approximate), `%` (both). Qualifiers may
  appear as suffixes and apply to that component and all components to its left.
  Fields store effective qualifications; normalization may remove redundant markers.
- Masked low-order year digits: `199X`, `19XX`. Serialization preserves the
  mask instead of inventing `1990` or `1900`.
- Intervals: `start/end`; `Endpoint::Open` is `..`, while `Endpoint::Unknown`
  is an empty side. The distinction is preserved. Bare `..` is rejected.
- Choice sets: `[1667,1668]` and `[1667,1668,1670..1672]`. A set-local `a..b`
  range remains `a..b` and is stored as `EdtfValue::Range`, not `Interval`.
- Batch diagnostics with stable error codes.

Month and day boundaries are validated. For exact years, `02-29` uses the
proleptic Gregorian leap-year rule. For masked years the leap-year status is
unknown, so February 29 is allowed; February 30 and April 31 are still rejected.

## Explicit non-goals

No natural-language date recognition. No complete calendar/timeline expansion.
No conversion of uncertain/approximate/masked values into precise timestamps.
No time/zone syntax, masked month/day, nested sets, open/unknown set endpoints,
individual prefix qualifiers, curly-brace all-member sets or slash intervals
inside choice sets. No complete EDTF conformance level is claimed, including Level 0.

The round-trip contract applies to parser-produced values. Public constructors
can represent invalid combinations and are not a substitute for parse validation.

## Comparison contract

`compare` only orders two complete, unqualified exact dates (`YYYY-MM-DD`).
Qualified, partial, masked, interval, set, open, and unknown values raise
`Unsupported` with a stable code; they are never coerced into a fake precise
order.

## License

Apache-2.0. See repository `docs/provenance.md` for EDTF sources, ecosystem
overlap findings, and AI-assisted development disclosure.
