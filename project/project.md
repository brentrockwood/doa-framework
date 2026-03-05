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
- Testing framework: [BATS](https://github.com/bats-core/bats-core). All tests live in `./tests/`.

## Open Questions

<!-- To be resolved in first planning session -->

## Known Debt / Deferred Items

- doa script patches are surgical sed replacements; verify behaviour on a
  test project before deprecating old repos.
- Framework versioning (TODO #2) not yet implemented.
- See TODO.md for full deferred work list.

## Task List

### 1. Fix `project/scripts/add-context` — Three Improvements

**a) Empty body detection**
The script does not currently detect or reject empty body data. This was
observed as a bug on the takehome project. Needs a guard that exits non-zero
and reports a clear error if the body is empty regardless of input method
(argument, file, or stdin).

**b) Always target repo-root context file**
The script currently writes to whatever context file is passed via
`--output`, or defaults to the current directory. It should always resolve
the output path to `$(git rev-parse --show-toplevel)/project/context.md`
unless explicitly overridden. This removes a class of agent mistakes where
the wrong file gets written because the agent is in a subdirectory or passes
a relative path.

**c) Auto-run `rotate-context` after every write**
After successfully appending a context entry, `add-context` should
automatically invoke `rotate-context`. `rotate-context` is idempotent and
only rotates when the file exceeds its size threshold, so calling it
unconditionally is safe. This removes a required step from the agent's
end-of-session checklist, shrinks the DOA by one explicit instruction, and
makes rotation impossible to forget.

### 2. BATS tests for `project/scripts/add-context`

Write a BATS test suite in `tests/add-context.bats` covering the behaviour
introduced or confirmed in Task 1:

**a) git-root resolution (Task 1b)**
- Invoking `add-context` from a subdirectory without `--output` writes the
  entry to `<repo-root>/project/context.md`.
- Invoking with `--output custom.md` uses that path instead.
- Invoking outside any git repo falls back to `./context.md`.

**b) auto-rotate integration (Task 1c)**
- After a successful write, `rotate-context` is called; its exit code 1
  ("no rotation needed") does not cause `add-context` to fail.
- When the output file exceeds the rotation threshold, rotation occurs and
  an overflow file is created.

**c) empty body rejection (Task 1a)**
- Empty stdin → non-zero exit and a clear error message on stderr.
- `--file` pointing to an empty file → same behaviour.

Each test should set up an isolated temporary git repo, run the script, make
assertions, and clean up. Use BATS helper libraries (`bats-support`,
`bats-assert`) if they simplify assertions.

### 3. Fix `project/scripts/read-context` — git-root resolution

`read-context` defaults to `./context.md` in the current directory, the same
class of bug fixed in `add-context` (Task 1b). It should resolve its default
file path to `$(git rev-parse --show-toplevel)/project/context.md` when inside
a git repo, with `--file` as the explicit override. Outside a git repo it should
fall back to `./context.md`.
