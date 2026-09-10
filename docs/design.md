# Design and EDTF subset boundaries

The UTF-16 cursor parser preserves precision and uncertainty. It neither trims
input nor guesses missing components. This is a selected syntax subset, not a
claim of full EDTF Level 0, 1 or 2 conformance.

## Representation and normalization

- YearSpec::Exact(Int) or Masked(prefix, x_count); absent month/day remain Unspecified.
- Qualifier fields store effective uncertainty/approximation. Suffixes apply to
  that component and all components to its left; normalization removes redundant markers.
- Endpoint::Known(date), Open (double dot) and Unknown (empty interval side) are distinct.
- EdtfValue::Date, Interval, Set (one-of selection) and Range(start,end).
  Range is used inside sets and serializes with double dots, never a slash.
- Round trips apply to parser-produced values, not invalid public-constructor trees.

## Supported spellings

| Input | Meaning / normalization |
| --- | --- |
| `1984`, `1984-06`, `1984-06-15` | year/month/day precision retained |
| `-0999`, `Y10000`, `Y-10000` | signed years; more than four digits require Y |
| `199X`, `19XX` | four positions, one or two trailing X; no negative masks |
| `1984-21` through `1984-24` | seasons, no day component |
| `1984?-06-11` | year uncertain |
| `1984-06?` | year and month uncertain |
| `1984-06-11%` | year, month and day uncertain and approximate |
| `2004-01-01/2005` | interval with independent endpoint precision |
| `1984/`, `/1984` | unknown endpoint retained as empty |
| `1984/..`, `../1984` | open endpoint retained as double dot |
| `[1667,1670..1672]` | one of the listed years; spelling preserved |

## Validation and comparison

Exact years use proleptic Gregorian calendar checks. Masked years permit February
29 because leap status is unknown, but reject February 30 and April 31. Years
have at most nine decimal digits. Extended years require Y and magnitude >=10000.

compare validates BOTH complete unqualified exact dates BEFORE comparing any
component. Different years/months cannot bypass precision checks. Unsupported
comparisons raise Unsupported(code, offset).

diagnose catches typed errors; batch mode reports every row. Error offsets are
zero-based UTF-16 positions in the original input. Error values do not echo
input text; diagnostic records intentionally retain their input field.

## Explicit exclusions

Time/timezone, natural language, scientific years, masked month/day, individual
prefix qualifiers, all-member curly-brace sets, nested sets, open/unknown set
members, slash intervals inside sets, standalone double dot and date enumeration.
Intervals are parsed, not ordered or expanded. There is no streaming or IO layer.

## Verification

edtf_test.mbt and regression_test.mbt cover calendar checks, qualifier scope,
distinct endpoint states, set ranges, precision rejection and semantic round trips.
CI checks/builds/tests/runs examples on four MoonBit targets.

Specification: [Library of Congress EDTF](https://www.loc.gov/standards/datetime/).
