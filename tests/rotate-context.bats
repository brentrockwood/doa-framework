#!/usr/bin/env bats
# Tests for project/scripts/rotate-context

load 'test_helper'

# ── no rotation needed ────────────────────────────────────────────────────────

@test "no-rotate: exits 1 when file is under size limit" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "small entry"

  run "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1048576

  [[ "$status" -eq 1 ]]
}

@test "no-rotate: file contents unchanged when under size limit" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "untouched entry"
  local before
  before="$(cat "$f")"

  run "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1048576

  [[ "$status" -eq 1 ]]
  [[ "$(cat "$f")" == "$before" ]]
}

@test "no-rotate: over limit but entry count <= keep exits 1 with warning" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  # Two entries with --keep 2 and tiny --size so file is "over limit"
  write_context_entries "$f" "entry one" "entry two"

  run bash -c "'$SCRIPTS_DIR/rotate-context' --file '$f' --size 1 --keep 2 2>&1"

  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Warning"* ]] || [[ "$output" == *"warning"* ]]
}

# ── rotation occurs ───────────────────────────────────────────────────────────

@test "rotate: exits 0 when file exceeds size and enough entries exist" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "entry one" "entry two" "entry three" "entry four"

  run "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1 --keep 2

  [[ "$status" -eq 0 ]]
}

@test "rotate: overflow file is created" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "entry one" "entry two" "entry three" "entry four"

  run "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1 --keep 2

  [[ "$status" -eq 0 ]]
  local overflow_count
  overflow_count=$(find "$BATS_TEST_TMPDIR" -name "ctx-*.md" | wc -l | tr -d ' ')
  [[ "$overflow_count" -ge 1 ]]
}

@test "rotate: overflow filename is printed to stdout" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "entry one" "entry two" "entry three"

  run "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1 --keep 2

  [[ "$status" -eq 0 ]]
  [[ "$output" == *"ctx-"* ]]
}

@test "rotate: original file retains exactly --keep most-recent entries" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "oldest" "middle" "newest"

  "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1 --keep 2

  # "newest" and "middle" stay; "oldest" moves to overflow
  grep -q "newest" "$f"
  grep -q "middle" "$f"
  ! grep -q "oldest" "$f"
}

@test "rotate: overflow file contains the oldest entries" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "oldest" "middle" "newest"

  "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1 --keep 2

  local overflow
  overflow=$(find "$BATS_TEST_TMPDIR" -name "ctx-*.md" | head -1)
  grep -q "oldest" "$overflow"
  ! grep -q "newest" "$overflow"
}

@test "rotate: --keep 3 retains three most-recent entries" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "e1" "e2" "e3" "e4" "e5"

  "$SCRIPTS_DIR/rotate-context" --file "$f" --size 1 --keep 3

  grep -q "e3" "$f"
  grep -q "e4" "$f"
  grep -q "e5" "$f"
  ! grep -q "e1" "$f"
  ! grep -q "e2" "$f"
}

@test "rotate: custom --size is respected (no rotation when file is under custom limit)" {
  local f="$BATS_TEST_TMPDIR/ctx.md"
  write_context_entries "$f" "e1" "e2" "e3"
  local actual_size
  actual_size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
  local large_limit=$(( actual_size * 10 ))

  run "$SCRIPTS_DIR/rotate-context" --file "$f" --size "$large_limit" --keep 2

  [[ "$status" -eq 1 ]]
}

# ── error cases ───────────────────────────────────────────────────────────────

@test "error: file not found exits 2 with message" {
  run bash -c "'$SCRIPTS_DIR/rotate-context' --file '$BATS_TEST_TMPDIR/no-such-file.md' 2>&1"
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]
}
