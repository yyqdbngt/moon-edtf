# Design and EDTF subset boundaries

The UTF-16 cursor parser preserves precision and uncertainty. It neither trims
input nor guesses missing components. This is a selected syntax subset, not a
claim of full EDTF Level 0, 1 or 2 conformance.

## Representation and normalization

- YearSpec::Exact(Int) or Masked(prefix, x_count); missing month/day components are
  represented as Unspecified, while explicitly written `XX` has its own Masked variant.
- Qualifier fields store effective uncertainty/approximation. Suffixes apply to
  that component and all components to its left; normalization removes redundant markers.
- Endpoint::Known(date), Open (double dot) and Unknown (empty interval side) are distinct.
- EdtfValue::Date, DateTime, Interval, Set (one-of selection), AllSet (all members)
  and Range(start,end). DateTime retains Local/Z/offset spelling without conversion.
  Range is used inside sets and serializes with double dots, never a slash.
- Round trips apply to parser-produced values, not invalid public-constructor trees.

## Supported spellings

| Input | Meaning / normalization |
| --- | --- |
| `1984`, `1984-06`, `1984-06-15` | year/month/day precision retained |
| `-0999`, `Y10000`, `Y-10000` | signed years; more than four digits require Y |
| `199X`, `19XX` | four positions, one or two trailing X; no negative masks |
| `2004-XX`, `1985-04-XX`, `1985-XX-XX` | explicit unknown month/day digits; no masked year plus month |
| `1985-04-12T23:20:30Z`, `...-04`, `...+04:30` | complete exact date-time; local/Z/offset kept distinct |
| `1984-21` through `1984-24` | seasons, no day component |
| `1984?-06-11` | year uncertain |
| `1984-06?` | year and month uncertain |
| `1984-06-11%` | year, month and day uncertain and approximate |
| `2004-01-01/2005` | interval with independent endpoint precision |
| `1984/`, `/1984` | unknown endpoint retained as empty |
| `1984/..`, `../1984` | open endpoint retained as double dot |
| `[1667,1670..1672]` | one of the listed years; spelling preserved |
| `{1667,1668,1670..1672}` | all members included; not interchangeable with `[...]` |

## Validation and comparison

Exact years use proleptic Gregorian calendar checks. Masked years are accepted
only in year-only expressions; month/day `XX` preserve unknown digits without
inventing a concrete day. Years have at most nine decimal digits. Extended years
require Y and magnitude >=10000. Date-time requires complete exact date and
HH:MM:SS; hours 00–23, minutes/seconds 00–59, zone offsets at most ±14:00.

compare validates BOTH complete unqualified exact dates BEFORE comparing any
component. Different years/months cannot bypass precision checks. Unsupported
comparisons raise Unsupported(code, offset).

`date_envelope` computes inclusive outer calendar bounds only for parse-produced
unqualified dates, closed intervals and bounded sets/ranges. A set's envelope
may include dates that are not actual members. `window_relation` uses an
inclusive exact-day query: Outside and Within are safe relative to the envelope;
PossibleOverlap is only a conservative candidate. Qualified dates, seasons,
unbounded endpoints and date-times are refused, never silently coerced.
`audit_catalog` applies the same logic to structured fields and separates
syntax errors from cases requiring human review.

`query_temporal_records` is the domain-neutral integration layer. It retains
the caller's record ID and category, guarantees one finding per input, supports
strict or recall-first selection, and reports safe aggregate coverage.
`temporal_relation` compares two conservative envelopes for order and
containment. These APIs do not know about CSV, JSON, databases, or any business
domain, so adapters can remain in the consuming application.

diagnose catches typed errors; batch mode reports every row. Error offsets are
zero-based UTF-16 positions in the original input. Error values do not echo
input text; diagnostic records intentionally retain their input field.

## Explicit exclusions

Natural language, scientific years, date-time fractions, leap seconds, 24:00,
timezone conversion, individual prefix qualifiers, nested sets, open/unknown
set members, slash intervals inside sets, standalone double dot and date
enumeration. Intervals are parsed, not expanded. There is no streaming or IO layer.

## Verification

`edtf_test.mbt`, `regression_test.mbt`, `datetime_test.mbt`, `envelope_test.mbt`,
`catalog_test.mbt` and `temporal_test.mbt` cover calendar checks, qualification scope, date-time
boundaries, distinct endpoint states, set ranges, round trips, conservative
window relations, policy selection and 10,000-row batch counts. CI checks/builds/tests/runs all examples
on four MoonBit targets.

Specification: [Library of Congress EDTF](https://www.loc.gov/standards/datetime/).
