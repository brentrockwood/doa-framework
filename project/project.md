# doa-framework

## Purpose

doa-framework is the single surviving repository for the DOA Framework — a
system for structured AI agent collaboration on software projects.

It consolidates what was previously spread across four repos:
- `new-project` → tool layer, now the `doa` script
- `prjTemplate` → project scaffold, now `template/`
- `doa` → canonical rules document, now `project/doa.md` and `template/project/doa.md`
- `doa-framework` → README/overview, merged into this repo's README

## Ratified Decisions

- Single repo. All others deprecated.
- Script renamed `new-project` → `doa`.
- `prjTemplate` promoted to `template/` subdirectory.
- Single canonical `doa.md`: `project/doa.md` is the source of truth.
  `template/project/doa.md` is the copy planted into new projects.
- `doa` uses local `template/` copy when available; falls back to remote clone.
- This repo governs itself via the DOA process.

## Open Questions

<!-- To be resolved in first planning session -->

## Known Debt / Deferred Items

- doa script patches are surgical sed replacements; verify behaviour on a
  test project before deprecating old repos.
- Framework versioning (TODO #2) not yet implemented.
- See TODO.md for full deferred work list.
