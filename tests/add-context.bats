#!/usr/bin/env bats
# Tests for project/scripts/add-context
# Covers Task 2 (git-root resolution, auto-rotate, empty body)
# and Task 3b (additional add-context coverage).

load 'test_helper'

# ── git-root resolution (Task 2a) ─────────────────────────────────────────────

@test "git-root: from subdirectory writes to <git-root>/project/context.md" {
  local repo
  repo="$(make_git_repo)"
  mkdir -p "$repo/project" "$repo/sub"

  (cd "$repo/sub" && "$SCRIPTS_DIR/add-context" --agent "A" --model "M" "hello from subdir")

  [[ -f "$repo/project/context.md" ]]
  grep -q "hello from subdir" "$repo/project/context.md"
  rm -rf "$repo"
}

@test "git-root: --output overrides git-root default" {
  local repo out
  repo="$(make_git_repo)"
  out="$BATS_TEST_TMPDIR/custom.md"

  (cd "$repo" && "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "custom path")

  [[ -f "$out" ]]
  grep -q "custom path" "$out"
  [[ ! -f "$repo/project/context.md" ]]
  rm -rf "$repo"
}

@test "git-root: outside git repo falls back to ./context.md" {
  local tmpdir
  tmpdir="$(mktemp -d)"

  (cd "$tmpdir" && "$SCRIPTS_DIR/add-context" --agent "A" --model "M" "no git here")

  [[ -f "$tmpdir/context.md" ]]
  grep -q "no git here" "$tmpdir/context.md"
  rm -rf "$tmpdir"
}

# ── auto-rotate integration (Task 2b) ─────────────────────────────────────────

@test "auto-rotate: exits 0 when rotate-context returns 1 (no rotation needed)" {
  local out="$BATS_TEST_TMPDIR/ctx.md"

  run "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "small entry"

  [[ "$status" -eq 0 ]]
}

@test "auto-rotate: overflow file created when output file exceeds 1MB" {
  local out="$BATS_TEST_TMPDIR/ctx.md"

  # Generate ~1.2 MB: 20 entries each with a ~60 KB body.
  # Using few large entries keeps the O(n²) sed cost in rotate-context low.
  local body
  body="$(head -c 60000 /dev/zero | tr '\0' 'x')"
  local i
  for i in $(seq 1 20); do
    printf -- '---\ndate: 2024-01-01T00:00:00+0000\nhash: h\nagent: A\nmodel: M\n---\n\n'
    printf '%s' "$body"
    printf '\n\nEOF\n\n'
  done > "$out"

  run "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "trigger rotation"

  [[ "$status" -eq 0 ]]
  local overflow_count
  overflow_count=$(find "$BATS_TEST_TMPDIR" -name "ctx-*.md" | wc -l | tr -d ' ')
  [[ "$overflow_count" -ge 1 ]]
}

# ── empty body rejection (Task 2c) ────────────────────────────────────────────

@test "empty-body: empty stdin exits non-zero with error message" {
  run bash -c "'$SCRIPTS_DIR/add-context' --agent 'A' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' < /dev/null 2>&1"
  [[ "$status" -ne 0 ]]
  echo "$output" | grep -qi "empty"
}

@test "empty-body: --file pointing to empty file exits non-zero with error message" {
  local empty="$BATS_TEST_TMPDIR/empty.txt"
  touch "$empty"

  run bash -c "'$SCRIPTS_DIR/add-context' --agent 'A' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' --file '$empty' 2>&1"
  [[ "$status" -ne 0 ]]
  echo "$output" | grep -qi "empty"
}

# ── required-arg validation (Task 3b) ─────────────────────────────────────────

@test "args: missing --agent exits non-zero" {
  run bash -c "'$SCRIPTS_DIR/add-context' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' 'body' 2>&1"
  [[ "$status" -ne 0 ]]
}

@test "args: missing --model exits non-zero" {
  run bash -c "'$SCRIPTS_DIR/add-context' --agent 'A' --output '$BATS_TEST_TMPDIR/out.md' 'body' 2>&1"
  [[ "$status" -ne 0 ]]
}

# ── body input methods (Task 3b) ──────────────────────────────────────────────

@test "body: from positional argument" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "positional body text"

  grep -q "positional body text" "$out"
}

@test "body: from --file" {
  local out="$BATS_TEST_TMPDIR/out.md"
  local body_file="$BATS_TEST_TMPDIR/body.txt"
  echo "file body text" > "$body_file"

  "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" --file "$body_file"

  grep -q "file body text" "$out"
}

@test "body: from stdin" {
  local out="$BATS_TEST_TMPDIR/out.md"

  echo "stdin body text" | "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out"

  grep -q "stdin body text" "$out"
}

@test "body: --file not found exits non-zero with error message" {
  run bash -c "'$SCRIPTS_DIR/add-context' --agent 'A' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' --file '$BATS_TEST_TMPDIR/nonexistent.txt' 2>&1"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]
}

# ── --session field (Task 3b) ─────────────────────────────────────────────────

@test "session: --session value appears in header" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --session "sess-42" --output "$out" "body"

  grep -q "^session: sess-42" "$out"
}

@test "session: no --session means no session line in header" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "body"

  ! grep -q "^session:" "$out"
}

# ── entry format (Task 3b) ────────────────────────────────────────────────────

@test "format: entry contains date, hash, agent, model, startCommit fields" {
  local repo out
  repo="$(make_git_repo)"
  out="$BATS_TEST_TMPDIR/out.md"

  (cd "$repo" && "$SCRIPTS_DIR/add-context" --agent "MyAgent" --model "my-model" --output "$out" "format test")

  grep -q "^date:" "$out"
  grep -q "^hash:" "$out"
  grep -q "^agent: MyAgent" "$out"
  grep -q "^model: my-model" "$out"
  grep -q "^startCommit:" "$out"
  grep -q "format test" "$out"
  rm -rf "$repo"
}

# ── append behaviour (Task 3b) ────────────────────────────────────────────────

@test "append: second entry appended to existing file" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "first entry"
  "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "second entry"

  grep -q "first entry" "$out"
  grep -q "second entry" "$out"
}

@test "append: creates output file when it does not exist" {
  local out="$BATS_TEST_TMPDIR/newdir/out.md"
  mkdir -p "$(dirname "$out")"

  run "$SCRIPTS_DIR/add-context" --agent "A" --model "M" --output "$out" "new file"

  [[ "$status" -eq 0 ]]
  [[ -f "$out" ]]
}
