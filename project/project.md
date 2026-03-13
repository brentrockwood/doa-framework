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

### 3. Fix `project/scripts/read-context` + BATS tests for all scripts

#### 3a. git-root resolution in `read-context` ✓ Complete (commit 79205c3)

`read-context` defaulted to `./context.md` in the current directory — the same
class of bug fixed in `add-context` (Task 1b). It now resolves its default file
path to `$(git rev-parse --show-toplevel)/project/context.md` when inside a git
repo, with `--file` as the explicit override, and falls back to `./context.md`
outside a git repo.

#### 3b. BATS test suites — all scripts

Task 2 covers the three focused areas of `add-context`. This task adds full
coverage across all scripts in `project/scripts/`. Tests live in `tests/` and
share a common helper in `tests/test_helper.bash` (provides `make_git_repo`
and `write_context_entries` utilities; no bats-support/bats-assert dependency).

**`add-context` — beyond Task 2 scope** (`tests/add-context.bats`, extended)

- **Required-arg validation**: missing `--agent` → non-zero exit + stderr error;
  same for missing `--model`.
- **Body input methods**: positional arg, `--file` (non-empty file), and stdin
  each produce a correctly written entry.
- **`--session` field**: when `--session` is passed, the session line appears in
  the header; when omitted, it does not.
- **Entry format**: written entry contains correct `date`, `hash`, `agent`,
  `model`, and `startCommit` fields in expected positions.
- **Append behaviour**: second call appends a new entry; a blank-line separator
  appears between entries; first call creates the file.
- **`--file` not found**: exits non-zero with a clear stderr message.

**`read-context`** (`tests/read-context.bats`)

- **git-root resolution**: invoking from a subdirectory (no `--file`) reads
  `<repo-root>/project/context.md`; `--file` overrides; outside a git repo
  falls back to `./context.md`.
- **Default read**: no flags → prints last entry.
- **`-n N`**: prints the last N entries in order.
- **`--headers-only` / `-h`**: output contains header block but not body text.
- **Combined `-n N -h`**: headers of last N entries.
- **Error — file not found**: exits non-zero with stderr message.
- **Error — invalid `-n`**: non-integer or zero → non-zero exit + stderr.
- **Error — unknown option**: non-zero exit.

**`rotate-context`** (`tests/rotate-context.bats`)

- **No rotation needed** (file under size limit): exits 1, file unchanged.
- **Rotation occurs** (file over limit, enough entries): exits 0; overflow file
  created; original file contains exactly `--keep` most-recent entries; all
  older entries appear in the overflow file.
- **Over limit but ≤ keep entries**: warning to stderr, exits 1, no overflow
  file created.
- **File not found**: exits 2 with stderr message.
- **Custom `--size` and `--keep`**: both flags respected in rotation logic.

**`add-session-entry`** (`tests/add-session-entry.bats`)

- **Required-arg validation**: missing `--agent` or `--model` → exit 1 +
  stderr; invalid `--type` value → exit 1 + stderr.
- **Body input methods**: positional arg, `--file`, stdin each write a valid
  entry.
- **Empty body**: exits 1 with stderr error regardless of input method.
- **`--file` not found**: exits 1 with stderr error.
- **File initialisation**: when output file does not exist, it is created with
  the standard header before the first entry.
- **Append behaviour**: second call appends without reinitialising the header.
- **Entry format**: output contains `[$TYPE]`, agent, model, and date fields.

**`notify`** (`tests/notify.bats`)

- **No args**: exits 1 with usage message on stderr.
- **Mocked success path**: stub `curl` to return `{"ok":true}`; script exits 0.
- **Mocked API-error path**: stub `curl` to return `{"ok":false,"description":"bad token"}`; script exits 1 with the description on stderr.
- **Network failure (empty response)**: stub `curl` to return empty string;
  script exits 1.
- Note: tests stub `curl` via a wrapper script injected at the front of `PATH`;
  no real Telegram credentials required.
