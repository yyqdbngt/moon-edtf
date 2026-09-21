# Moon EDTF

Pure-MoonBit parser for a conservative EDTF subset. It preserves uncertainty,
approximation, masked low-order digits, and open/unknown interval endpoints.
Zero third-party package dependencies.

## Consumer example

The published MoonCakes version is `0.1.0`; this repository's `0.2.0` is
pending CI and publication. To use the new APIs before release, build from
source. After release, add `yyqdbngt/moon_edtf@0.2.0` and import it in `moon.pkg`.

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
- `date_envelope(value : EdtfValue) -> DateEnvelope raise EdtfError`
- `window_relation(value, query_start, query_end) -> WindowRelation raise EdtfError`
- `audit_catalog(entries, query_start, query_end) -> CatalogReport raise EdtfError`

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
- Masked low-order year digits: `199X`, `19XX`, in year-only expressions.
  Unspecified month/day shapes include `2004-XX`, `1985-04-XX`, and
  `1985-XX-XX`. Serialization preserves missing precision.
- Complete date-times with HH:MM:SS and local, Z, hour-only, or hour-minute
  offsets. Zone spelling is preserved, not converted.
- Intervals: `start/end`; `Endpoint::Open` is `..`, while `Endpoint::Unknown`
  is an empty side. The distinction is preserved. Bare `..` is rejected.
- Choice sets: `[1667,1668]` and `[1667,1668,1670..1672]`. A set-local `a..b`
  range remains `a..b` and is stored as `EdtfValue::Range`, not `Interval`.
- All-member sets use `{...}` and remain distinct from one-of `[...]` sets.
- Batch diagnostics with stable error codes.
- Conservative date envelopes and inclusive exact-day window screening.
  Qualified dates, seasons, unbounded intervals and date-times require review;
  `PossibleOverlap` can be a false positive where an envelope has gaps.
- Structured catalog batch audit with invalid/review/outside/within/possible
  findings and counts. See `examples/catalog-audit` in the repository.

Month and day boundaries are validated. Exact years use the proleptic Gregorian
leap-year rule. Masked years are year-only; `19XX-02-29` is rejected in this subset.

## Explicit non-goals

No natural-language date recognition. No complete calendar/timeline expansion.
No conversion of uncertain/approximate/masked values into precise timestamps.
No date-time fractions, leap seconds, 24:00, timezone conversion, nested sets,
open/unknown set endpoints, individual prefix qualifiers or slash intervals
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
