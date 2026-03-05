#!/usr/bin/env bats
# Tests for project/scripts/read-context

load 'test_helper'

# ── git-root resolution ───────────────────────────────────────────────────────

@test "git-root: from subdirectory reads <git-root>/project/context.md" {
  local repo
  repo="$(make_git_repo)"
  mkdir -p "$repo/project" "$repo/sub"
  write_context_entries "$repo/project/context.md" "repo root entry"

  run bash -c "cd '$repo/sub' && '$SCRIPTS_DIR/read-context'"

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"repo root entry"* ]]
  rm -rf "$repo"
}

@test "git-root: --file overrides git-root default" {
  local repo custom
  repo="$(make_git_repo)"
  mkdir -p "$repo/project"
  custom="$BATS_TEST_TMPDIR/custom.md"
  write_context_entries "$repo/project/context.md" "repo entry"
  write_context_entries "$custom" "custom entry"

  run bash -c "cd '$repo' && '$SCRIPTS_DIR/read-context' --file '$custom'"

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"custom entry"* ]]
  [[ "$output" != *"repo entry"* ]]
  rm -rf "$repo"
}

@test "git-root: outside git repo reads ./context.md" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  write_context_entries "$tmpdir/context.md" "local fallback"

  run bash -c "cd '$tmpdir' && '$SCRIPTS_DIR/read-context'"

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"local fallback"* ]]
  rm -rf "$tmpdir"
}

# ── reading behaviour ─────────────────────────────────────────────────────────

@test "read: default (no flags) prints last entry" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "entry one" "entry two" "entry three"

  run "$SCRIPTS_DIR/read-context" --file "$f"

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"entry three"* ]]
  [[ "$output" != *"entry one"* ]]
  [[ "$output" != *"entry two"* ]]
}

@test "read: -n 2 prints last two entries" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "entry one" "entry two" "entry three"

  run "$SCRIPTS_DIR/read-context" --file "$f" -n 2

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"entry two"* ]]
  [[ "$output" == *"entry three"* ]]
  [[ "$output" != *"entry one"* ]]
}

@test "read: -n larger than entry count prints all entries" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "only one" "only two"

  run "$SCRIPTS_DIR/read-context" --file "$f" -n 10

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"only one"* ]]
  [[ "$output" == *"only two"* ]]
}

@test "read: -h shows header block but not body" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "secret body text"

  run "$SCRIPTS_DIR/read-context" --file "$f" -h

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"TestAgent"* ]]
  [[ "$output" != *"secret body text"* ]]
}

@test "read: -n 2 -h prints headers of last two entries" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "body one" "body two" "body three"

  run "$SCRIPTS_DIR/read-context" --file "$f" -n 2 -h

  [[ "$status" -eq 0 ]]
  [[ "$output" != *"body one"* ]]
  [[ "$output" != *"body two"* ]]
  [[ "$output" != *"body three"* ]]
  # Two header blocks should be present (two --- pairs)
  local header_count
  header_count=$(echo "$output" | grep -c "^---$" || true)
  [[ "$header_count" -ge 2 ]]
}

# ── error cases ───────────────────────────────────────────────────────────────

@test "error: file not found exits non-zero with message" {
  run bash -c "'$SCRIPTS_DIR/read-context' --file '$BATS_TEST_TMPDIR/no-such-file.md' 2>&1"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]
}

@test "error: -n 0 exits non-zero" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "body"

  run bash -c "'$SCRIPTS_DIR/read-context' --file '$f' -n 0 2>&1"
  [[ "$status" -ne 0 ]]
}

@test "error: -n non-integer exits non-zero" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "body"

  run bash -c "'$SCRIPTS_DIR/read-context' --file '$f' -n abc 2>&1"
  [[ "$status" -ne 0 ]]
}

@test "error: unknown option exits non-zero" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "body"

  run bash -c "'$SCRIPTS_DIR/read-context' --file '$f' --unknown 2>&1"
  [[ "$status" -ne 0 ]]
}
