# Design and EDTF support matrix

## Parsing model

The parser walks the original UTF-16 string with a cursor (`source[pos]` uses
UTF-16 code units). It is a strict recursive-descent parser; it does not trim
whitespace, perform dictionary lookup, or infer missing components.

Parsing is separated from normalization. `parse` returns a typed value tree;
`normalize`/`to_string` renders that tree back to a legal EDTF spelling.

## Internal representation

- `YearSpec::Exact(Int)` stores a signed integer year.
- `YearSpec::Masked(String, Int)` stores the written digit prefix and the
  number of trailing `X` positions. This preserves `19XX` semantics without
  turning it into `1900`.
- `MonthSpec` distinguishes `Unspecified`, `Exact(Int)`, and `Season(Int)`.
- `DaySpec` distinguishes `Unspecified` and `Exact(Int)`.
- `Qualifier` stores `uncertain` and `approximate` booleans per date component.
- `Endpoint` distinguishes `Known(EdtfDate)` and `Open`.
- `EdtfValue` is `Date`, `Interval`, `Set`, or `Unknown`.

Uncertainty and approximation are data, not parse-time side effects. A bare
year is not padded with month/day 01 and an uncertain year is not converted to
a timestamp.

## Date grammar implemented

```text
date        = year [ "-" month [ "-" day ] ]
year        = [ "-" ] digits [ "X"* ] qualifier
month       = 2DIGIT qualifier          ; 01..12 or 21..24
day         = 2DIGIT qualifier          ; 01..31 before calendar check
qualifier   = "" | "?" | "~" | "%"
interval    = endpoint "/" endpoint
endpoint    = ".." | date | ""
set         = "[" item ("," item)* "]"
item        = date | date "/" endpoint | date ".." date
```

Empty interval sides (`1984/`, `/1984`) are accepted and normalized to `..`.
Bare `..` is `EdtfValue::Unknown`.

## Calendar checks

For exact years, `month` must be 01..12 or the documented season extension
21..24. `day` must fit the month using the proleptic Gregorian leap-year rule.
For masked years, February 29 is allowed because leap status is unknown; only
the 01..31 range is checked.

## Diagnostics

`diagnose` catches `EdtfError` and returns a record rather than throwing.
Error codes are stable strings and offsets are half-open UTF-16 code-unit
offsets into the original input. Error payloads do not contain the input text.
Batch mode never stops at the first invalid row.

## Comparison policy

`compare` only supports two complete, unqualified exact dates. Everything else
raises `Unsupported` with a stable code. This is intentional: partial or
masked dates describe ranges or uncertain meanings, so a single precise order
would be a false claim.

## Support matrix

| Input | Parse | Normalize | Notes |
| --- | --- | --- | --- |
| `1984` | yes | `1984` | exact year |
| `1984-06` | yes | `1984-06` | exact month |
| `1984-06-15` | yes | `1984-06-15` | exact day |
| `-0999` | yes | `-0999` | negative four-digit year |
| `10000` | yes | `10000` | long year |
| `1984-21` | yes | `1984-21` | documented season extension |
| `1984?` | yes | `1984?` | uncertain |
| `1984~` | yes | `1984~` | approximate |
| `1984%` | yes | `1984%` | both |
| `1984?-06-11` | yes | `1984?-06-11` | year-level qualifier |
| `1984-06?` | yes | `1984-06?` | month-level qualifier |
| `199X` / `19XX` | yes | same | masked year |
| `2004-01-01/2005` | yes | same | interval |
| `../1984` | yes | same | open start |
| `1984/..` / `2004/..` | yes | same | open end |
| `..` | yes | `..` | unknown |
| `[1667,1668,1670..1672]` | yes | `[1667,1668,1670/1672]` | choice set |
| `1984-13` | no | — | invalid month |
| `1900-02-29` | no | — | Gregorian leap rule |
| `1984-06-1` | no | — | day must be two digits |
| `+1984` | no | — | plus sign not accepted |
| `1984?~` | no | — | one qualifier per component |
| `1984/1985/1986` | no | — | one interval slash |

## Limits

- Exact year digits: 4..9 (fits MoonBit `Int`).
- No time, timezone, masked month/day, nested sets, open/unknown set endpoints.
- No streaming API; the parser receives an owned `String`.