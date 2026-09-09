# Provenance and overlap notes

## EDTF specification source

The implemented subset is based on the public EDTF specification hosted by the
Library of Congress:

- https://www.loc.gov/standards/datetime/edtf.html

Only the explicitly documented date/subset features are implemented. This
project is not an exhaustive EDTF implementation and does not claim full
Level 1 or Level 2 conformance.

## Code provenance

The MoonBit code is written for this project in `D:\Codex\moon-edtf`. It does
not copy the feature logic of the reference project `moon-json-repair`; that
project was used only as a local syntax/engineering-structure reference for
`moon.mod`, `moon.pkg`, `test {}` blocks, and CI shape.

The Apache-2.0 `LICENSE` text is the standard Apache License 2.0 text copied
from the reference repository, as permitted by the license. No third-party
runtime code is vendored.

## MoonCakes / GitHub duplicate search

Search terms included `moon_edtf`, `moon-edtf`, `MoonBit EDTF`, and related
datetime/EDTF terms. The search did not find an existing MoonBit package or
GitHub repository with this exact package name.

Search miss is not absolute proof that no similar project exists. Similar
functionality may exist under different names, in private repositories, or in
unindexed branches. This project does not claim to be the first or only EDTF
library.

## Relationship to other date libraries

General-purpose date libraries such as `brickfrog/tempo` usually focus on
precise date/time arithmetic, formatting, time zones, and timeline operations.
Moon EDTF is adjacent rather than a replacement: it focuses on parsing an EDTF
text subset while preserving uncertainty/approximation/masks, plus batch
diagnostics. It deliberately refuses to turn uncertain EDTF into a precise
timestamp.

## AI-assisted development disclosure

The code, tests, and documentation were developed by the maintainer with AI
programming assistance. The maintainer is responsible for reviewing the
generated code, running all verification commands, understanding the design,
and personally rewriting application materials as required by the hackathon
rules.