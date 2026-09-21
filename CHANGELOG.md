# Changelog

## 0.2.0 — catalog screening and expanded EDTF subset (2026-09-21)

- Add explicit `XX` month/day forms and distinguish all-member `{...}` sets from
  one-of `[...]` sets; bound same-precision set ranges.
- Add complete date-time parsing with local, UTC and numeric offset spellings;
  no implicit timezone conversion or claim of full Level 0 conformance.
- Add conservative date envelopes, inclusive search-window relations and
  structured catalog batch auditing with invalid/review/possible categories.
- Add a six-row, reproducible metadata-ingest example and regression tests.
- 39 test blocks pass on wasm, wasm-gc, js and native. Production MoonBit is
  1,229 lines in six root files; examples and tests are counted separately.
- Breaking correction: masked years are now year-only; `19XX-02-29` is rejected
  because the supported unspecified-digit grammar does not allow that form.
- MoonCakes publication of this version requires separate verification.

## Unreleased — 2026-09-10 review fixes

- Distinguish empty Unknown interval endpoints from Open (`..`) endpoints.
- Keep choice-set ranges as Range with `..`, not slash intervals.
- Propagate suffix qualification to components on the left and preserve round trips.
- Validate full precision before comparison; require Y for extended years and bound masks.
- Reject unsupported standalone `..` and slash intervals inside choice sets.
- Public model change: replace EdtfValue::Unknown with Endpoint::Unknown and add Range.
- Add five regression test blocks and correct documentation and application preparation notes.
- Source updates only; MoonCakes publication must be checked separately.

## 0.1.0 — initial source implementation

- Initial pure-MoonBit EDTF subset parser.
- Exact, masked, uncertain/approximate dates; intervals and open/unknown endpoints.
- Optional choice sets with `[...,a..b]` range shorthand.
- Stable diagnostics with UTF-16 offsets and no input echo in error values.
- Limited exact-date comparison that refuses qualified/partial/masked values.
- Tests for parsing, validation, round-trip, diagnostics, comparison, and examples.
- Apache-2.0 license and public GitHub development history.
