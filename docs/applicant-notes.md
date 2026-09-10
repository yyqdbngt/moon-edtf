# Applicant technical fact sheet

This document is a pre-submission technical fact list. It is not a completed
application and does not replace the applicant's own verification.

## Repository and package

- Local path: `D:\Codex\moon-edtf`
- Package name: `yyqdbngt/moon_edtf`
- Version: `0.1.0`
- License: Apache-2.0
- Repository URL recorded in `moon.mod`: https://github.com/yyqdbngt/moon-edtf
- Local git identity: `yyqdbngt <300715189+yyqdbngt@users.noreply.github.com>`
- Public GitHub repository: https://github.com/yyqdbngt/moon-edtf
- MoonCakes publication has not been performed and must be rechecked on submission day.

## Implemented facts

- Pure MoonBit library, zero third-party package dependencies.
- `parse`, `normalize`/`to_string`, `diagnose`, `diagnose_batch`, `compare`.
- Supports exact dates, negative/long years, seasons, uncertainty/approximation,
  masked year digits, intervals, open/unknown endpoints, and choice sets.
- Preserves uncertainty and masks; does not convert them to precise timestamps.
- Stable error codes and original UTF-16 offsets; error values do not echo input.
- Limited comparison only for complete unqualified exact dates; other inputs are
  refused explicitly.

## Verification facts

- MoonBit toolchain: `0.1.20260904`.
- Tests after review fixes: 21 blocks across edtf_test.mbt and regression_test.mbt.
- Targets verified locally per final report: wasm, wasm-gc, js.
- CI matrix covers wasm, wasm-gc, js, native on ubuntu-latest.
- `native` may be skipped locally if the host C compiler is too old; CI still
  covers it.

## Boundary facts

- No natural-language date recognition.
- No complete calendar/timeline calculation.
- No full EDTF Level 1/2, time, timezone, masked month/day, nested sets, or
  open/unknown set endpoints.
- Adjacent to general date libraries such as `brickfrog/tempo`; not a drop-in
  replacement.
- Search miss on MoonCakes/GitHub is not proof of absolute uniqueness.

## Responsibilities before submission

- Read `docs/design.md`, `docs/provenance.md`, and all source/tests.
- Run the verification commands in a clean checkout.
- Personally rewrite the proposal and any public description; do not submit the
  draft in `docs/proposal-draft.md` unchanged as personal work.
- Follow [the submission checklist](submission-checklist.md) for account, commit,
  human-authorship and publication checks. A commit count is not official acceptance.
