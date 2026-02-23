#!/usr/bin/env zsh
# ==============================================================================
# Tests for packer.plugin.zsh
#
# Usage:
#   zsh post-installation/defaults/.zsh/functions/packer.test.zsh
#
# Exit code: 0 all tests passed, 1 one or more failed.
# ==============================================================================

set -uo pipefail

# --- Source plugin ------------------------------------------------------------

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/packer.plugin.zsh"

# --- Test framework -----------------------------------------------------------

typeset -gi _T_PASS=0 _T_FAIL=0 _T_SKIP=0

_pass() { echo "  \033[0;32m✓\033[0m $1"; (( _T_PASS++ )); }
_fail() { echo "  \033[0;31m✗\033[0m $1"; (( _T_FAIL++ )); }
_skip() { echo "  \033[0;33m-\033[0m $1 (skipped)"; (( _T_SKIP++ )); }

_assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        _pass "$desc"
    else
        _fail "$desc — expected: '$expected', got: '$actual'"
    fi
}

# Assert that running the function (with args) succeeds (exit 0).
_assert_ok() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then _pass "$desc"; else _fail "$desc"; fi
}

# Assert that running the function (with args) fails (non-zero exit).
_assert_fail() {
    local desc="$1"; shift
    if ! "$@" >/dev/null 2>&1; then _pass "$desc"; else _fail "$desc"; fi
}

# Assert that a string contains a regex pattern.
_assert_contains() {
    local desc="$1" pattern="$2" text="$3"
    if echo "$text" | grep -qE "$pattern"; then
        _pass "$desc"
    else
        _fail "$desc — pattern '${pattern}' not found"
    fi
}

# Assert that a string does NOT contain a regex pattern.
_assert_not_contains() {
    local desc="$1" pattern="$2" text="$3"
    if ! echo "$text" | grep -qE "$pattern"; then
        _pass "$desc"
    else
        _fail "$desc — pattern '${pattern}' unexpectedly found"
    fi
}

# --- Global setup -------------------------------------------------------------

TMP=$(mktemp -d)
chmod 700 "$TMP"

SRC="${TMP}/testdata"
mkdir -p "${SRC}/sub"
echo "hello world"        > "${SRC}/a.txt"
echo "nested content"     > "${SRC}/sub/b.txt"
echo "another file"       > "${SRC}/sub/c.txt"
printf '%0.s x' {1..1000} > "${SRC}/pad.bin"   # ~2 KB padding to make splits meaningful

PASS="h0rse-battery-staple"

trap 'rm -rf "$TMP"' EXIT

# ==============================================================================
echo ""
echo "━━━ Unit: _sa_elapsed ━━━"

_assert_eq "_sa_elapsed 0"    "0s"    "$(_sa_elapsed 0)"
_assert_eq "_sa_elapsed 1"    "1s"    "$(_sa_elapsed 1)"
_assert_eq "_sa_elapsed 59"   "59s"   "$(_sa_elapsed 59)"
_assert_eq "_sa_elapsed 60"   "1m00s" "$(_sa_elapsed 60)"
_assert_eq "_sa_elapsed 61"   "1m01s" "$(_sa_elapsed 61)"
_assert_eq "_sa_elapsed 125"  "2m05s" "$(_sa_elapsed 125)"
_assert_eq "_sa_elapsed 3600" "60m00s" "$(_sa_elapsed 3600)"

# ==============================================================================
echo ""
echo "━━━ Unit: _sa_check_deps ━━━"

_assert_ok   "_sa_check_deps: present command"   _sa_check_deps ls
_assert_ok   "_sa_check_deps: multiple present"  _sa_check_deps ls tar
_assert_fail "_sa_check_deps: missing command"   _sa_check_deps _sa_nonexistent_cmd_abc123
_assert_fail "_sa_check_deps: one of two missing" _sa_check_deps ls _sa_nonexistent_cmd_abc123

# Verify it reports ALL missing, not just the first
missing_out=$(PATH=/usr/bin _sa_check_deps tar xz python3 _missing_a_ _missing_b_ 2>&1 || true)
_assert_contains "_sa_check_deps: reports all missing" "_missing_a_" "$missing_out"
_assert_contains "_sa_check_deps: reports all missing (2nd)" "_missing_b_" "$missing_out"

# ==============================================================================
echo ""
echo "━━━ Unit: SHA-256 command detection ━━━"

[[ -n "$_SA_SHA256_CMD" ]] \
    && _pass "sha256: _SA_SHA256_CMD detected ('$_SA_SHA256_CMD')" \
    || _fail "sha256: no sha256 tool found — _SA_SHA256_CMD is empty"

# Verify the detected command actually produces 64-char hex output
if [[ -n "$_SA_SHA256_CMD" ]]; then
    sha_out=$(echo "test" | ${=_SA_SHA256_CMD} 2>/dev/null | awk '{print $1}')
    [[ ${#sha_out} -eq 64 ]] \
        && _pass "sha256: produces 64-char hex digest" \
        || _fail "sha256: unexpected digest length (${#sha_out})"
fi

# ==============================================================================
echo ""
echo "━━━ Unit: NO_COLOR support ━━━"

# With NO_COLOR set, log output must contain no ANSI escape sequences.
no_color_out=$(NO_COLOR=1 secure_pack "$SRC" --password "$PASS" -o "${TMP}/out_nocolor" 2>&1 >/dev/null)
_assert_not_contains "NO_COLOR: no ANSI codes in stderr" $'\033' "$no_color_out"
_assert_contains     "NO_COLOR: plain [INFO] tag present" "\[INFO\]" "$no_color_out"

# Without NO_COLOR on a non-terminal (pipe), colours should also be absent.
non_tty_out=$(secure_pack "$SRC" --password "$PASS" -o "${TMP}/out_nontty" 2>&1 >/dev/null)
_assert_not_contains "non-tty stderr: no ANSI codes" $'\033' "$non_tty_out"

# ==============================================================================
echo ""
echo "━━━ Unit: _sa_verify_checksum ━━━"

CSUM_FILE="${TMP}/checksum_test.txt"
CSUM_SHA="${TMP}/checksum_test.txt.sha256"
echo "checksum me" > "$CSUM_FILE"
${=_SA_SHA256_CMD} "$CSUM_FILE" | awk '{print $1}' > "$CSUM_SHA"

_assert_ok   "checksum: correct hash passes"   _sa_verify_checksum "$CSUM_FILE" "$CSUM_SHA"
echo "badhash00000000000000000000000000000000000000000000000000000000" > "$CSUM_SHA"
_assert_fail "checksum: wrong hash fails"      _sa_verify_checksum "$CSUM_FILE" "$CSUM_SHA"
_assert_ok   "checksum: missing sidecar skips" _sa_verify_checksum "$CSUM_FILE" "${TMP}/no_such.sha256"

# ==============================================================================
echo ""
echo "━━━ Unit: _sa_resolve_dir ━━━"

NEW_DIR="${TMP}/resolve_me/nested"
result=$(_sa_resolve_dir "$NEW_DIR")
[[ -d "$NEW_DIR" ]] && _pass "_sa_resolve_dir: creates missing dir" \
                     || _fail "_sa_resolve_dir: creates missing dir"
_assert_eq "_sa_resolve_dir: returns absolute path" "$NEW_DIR" "$result"
_assert_eq "_sa_resolve_dir: no arg returns cwd" "$PWD" "$(_sa_resolve_dir '')"

# ==============================================================================
echo ""
echo "━━━ secure_pack: argument validation ━━━"

VOUT="${TMP}/out_validation"
mkdir -p "$VOUT"

out=$(secure_pack 2>&1); [[ $? -ne 0 ]] \
    && _pass "rejects: missing source arg" \
    || _fail "rejects: missing source arg"

out=$(secure_pack /nonexistent_path_abc123 --password x 2>&1); [[ $? -ne 0 ]] \
    && _pass "rejects: nonexistent source path" \
    || _fail "rejects: nonexistent source path"

out=$(secure_pack "$SRC" --password "" -o "$VOUT" 2>&1); [[ $? -ne 0 ]] \
    && _pass "rejects: empty password" \
    || _fail "rejects: empty password"

out=$(secure_pack "$SRC" --password x --split --size bad_val -o "$VOUT" 2>&1); [[ $? -ne 0 ]] \
    && _pass "rejects: invalid --size value" \
    || _fail "rejects: invalid --size value"

out=$(secure_pack "$SRC" --split --size 0k --password x -o "$VOUT" 2>&1); [[ $? -ne 0 ]] \
    && _pass "rejects: --size 0k" \
    || _fail "rejects: --size 0k"

out=$(secure_pack "$SRC" --password x --size 128k -o "$VOUT" 2>&1)
_assert_contains "--size without --split: warns" "WARN" "$out"
_assert_not_contains "--size without --split: still packs" "ERROR" "$out"

out=$(secure_pack "$SRC" --unknown-flag --password x -o "$VOUT" 2>&1); [[ $? -ne 0 ]] \
    && _pass "rejects: unknown flag" \
    || _fail "rejects: unknown flag"

# ==============================================================================
echo ""
echo "━━━ secure_pack + secure_unpack: standard archive ━━━"

STD_OUT="${TMP}/out_standard"
STD_EXTRACT="${TMP}/extract_standard"
mkdir -p "$STD_OUT" "$STD_EXTRACT"

pack_out=$(secure_pack "$SRC" --password "$PASS" -o "$STD_OUT" 2>&1)
ENC=(${STD_OUT}/*.tar.xz.enc(N))
[[ ${#ENC[@]} -eq 1 ]] \
    && _pass "standard: archive created" \
    || _fail "standard: archive created (found ${#ENC[@]})"
[[ -f "${ENC[1]}.sha256" ]] \
    && _pass "standard: sha256 sidecar created" \
    || _fail "standard: sha256 sidecar created"
_assert_contains "standard: pre-pack summary in output" "Packing:"    "$pack_out"
_assert_contains "standard: output size in log"         "Output size:" "$pack_out"

secure_unpack "${ENC[1]}" --password "$PASS" -o "$STD_EXTRACT" 2>&1 | cat
[[ -f "${STD_EXTRACT}/testdata/a.txt" ]] \
    && _pass "standard: top-level file extracted" \
    || _fail "standard: top-level file extracted"
[[ -f "${STD_EXTRACT}/testdata/sub/b.txt" ]] \
    && _pass "standard: nested file extracted" \
    || _fail "standard: nested file extracted"
_assert_eq "standard: file content correct" "hello world" "$(cat ${STD_EXTRACT}/testdata/a.txt)"

# Unpack success message should include the output directory path
unpack_out=$(secure_unpack "${ENC[1]}" --password "$PASS" -o "${STD_EXTRACT}" 2>&1 || true)
_assert_contains "standard: unpack reports destination" "$STD_EXTRACT" "$unpack_out"

out=$(secure_unpack "${ENC[1]}" --password "wrongpass" -o "$STD_EXTRACT" 2>&1); [[ $? -ne 0 ]] \
    && _pass "standard: wrong password rejected" \
    || _fail "standard: wrong password rejected"

# ==============================================================================
echo ""
echo "━━━ secure_pack + secure_unpack: split archive ━━━"

SPL_OUT="${TMP}/out_split"
SPL_EXTRACT="${TMP}/extract_split"
mkdir -p "$SPL_OUT" "$SPL_EXTRACT"

secure_pack "$SRC" --password "$PASS" --split --size 512 -o "$SPL_OUT" >/dev/null 2>&1
PARTS=(${SPL_OUT}/*.b85.part*(N))
[[ ${#PARTS[@]} -ge 2 ]] \
    && _pass "split: multiple parts created (${#PARTS[@]})" \
    || _fail "split: multiple parts created (found ${#PARTS[@]})"
[[ -f "${PARTS[1]%.b85.part*}.sha256" ]] \
    && _pass "split: sha256 sidecar for split archive" \
    || _fail "split: sha256 sidecar for split archive"

PARTAA=(${SPL_OUT}/*.b85.partaa(N))
secure_unpack "${PARTAA[1]}" --password "$PASS" -o "$SPL_EXTRACT" >/dev/null 2>&1
[[ -f "${SPL_EXTRACT}/testdata/a.txt" ]] \
    && _pass "split: top-level file extracted" \
    || _fail "split: top-level file extracted"
[[ -f "${SPL_EXTRACT}/testdata/sub/b.txt" ]] \
    && _pass "split: nested file extracted" \
    || _fail "split: nested file extracted"
_assert_eq "split: file content correct" "hello world" "$(cat ${SPL_EXTRACT}/testdata/a.txt)"

out=$(secure_unpack "${PARTAA[1]}" --password "wrongpass" -o "$SPL_EXTRACT" 2>&1); [[ $? -ne 0 ]] \
    && _pass "split: wrong password rejected" \
    || _fail "split: wrong password rejected"

# ----------- Round-trip diff -------------------------------------------------
DIFF_OUT="${TMP}/extract_diff"
mkdir -p "$DIFF_OUT"
secure_unpack "${PARTAA[1]}" --password "$PASS" -o "$DIFF_OUT" >/dev/null 2>&1
if diff -rq "$SRC" "${DIFF_OUT}/testdata" >/dev/null 2>&1; then
    _pass "split: round-trip diff clean"
else
    _fail "split: round-trip diff clean"
fi

# ==============================================================================
echo ""
echo "━━━ secure_list ━━━"

LIST_OUT="${TMP}/out_list"
mkdir -p "$LIST_OUT"
secure_pack "$SRC" --password "$PASS" -o "$LIST_OUT" >/dev/null 2>&1
LIST_ENC=(${LIST_OUT}/*.tar.xz.enc(N))

list_short=$(secure_list "${LIST_ENC[1]}" --password "$PASS" 2>/dev/null)
_assert_contains "secure_list: shows source dir"    "testdata"  "$list_short"
_assert_contains "secure_list: shows nested file"   "b.txt"     "$list_short"
_assert_not_contains "secure_list: short has no permissions" "^[-d]rw" "$list_short"

list_long=$(secure_list "${LIST_ENC[1]}" --password "$PASS" --long 2>/dev/null)
_assert_contains "secure_list --long: shows permissions"  "rw"          "$list_long"
_assert_contains "secure_list --long: shows file sizes"   "[0-9]+"      "$list_long"
_assert_contains "secure_list --long: shows nested file"  "b.txt"       "$list_long"

out=$(secure_list "${LIST_ENC[1]}" --password "wrongpass" 2>&1); [[ $? -ne 0 ]] \
    && _pass "secure_list: wrong password rejected" \
    || _fail "secure_list: wrong password rejected"

out=$(secure_list "/nonexistent.tar.xz.enc" --password "$PASS" 2>&1); [[ $? -ne 0 ]] \
    && _pass "secure_list: missing file rejected" \
    || _fail "secure_list: missing file rejected"

# secure_list on split archive
LIST_SPL_OUT="${TMP}/out_list_split"
mkdir -p "$LIST_SPL_OUT"
secure_pack "$SRC" --password "$PASS" --split --size 512 -o "$LIST_SPL_OUT" >/dev/null 2>&1
LIST_PARTAA=(${LIST_SPL_OUT}/*.b85.partaa(N))
list_split=$(secure_list "${LIST_PARTAA[1]}" --password "$PASS" 2>/dev/null)
_assert_contains "secure_list: split archive shows dir"  "testdata" "$list_split"
_assert_contains "secure_list: split archive shows file" "a.txt"    "$list_split"

# ==============================================================================
echo ""
echo "━━━ --name flag ━━━"

NAME_OUT="${TMP}/out_name"
mkdir -p "$NAME_OUT"
secure_pack "$SRC" --password "$PASS" --name mybackup -o "$NAME_OUT" >/dev/null 2>&1
[[ -f "${NAME_OUT}/mybackup.tar.xz.enc" ]] \
    && _pass "--name: standard archive uses custom filename" \
    || _fail "--name: standard archive uses custom filename (expected mybackup.tar.xz.enc)"
[[ -f "${NAME_OUT}/mybackup.tar.xz.enc.sha256" ]] \
    && _pass "--name: sha256 sidecar uses custom filename" \
    || _fail "--name: sha256 sidecar uses custom filename"

# Verify it's actually a valid archive
NAME_EXTRACT="${TMP}/extract_name"
mkdir -p "$NAME_EXTRACT"
secure_unpack "${NAME_OUT}/mybackup.tar.xz.enc" --password "$PASS" -o "$NAME_EXTRACT" >/dev/null 2>&1
[[ -f "${NAME_EXTRACT}/testdata/a.txt" ]] \
    && _pass "--name: archive is extractable" \
    || _fail "--name: archive is extractable"

# Test --name with --split
NAME_SPL_OUT="${TMP}/out_name_split"
mkdir -p "$NAME_SPL_OUT"
secure_pack "$SRC" --password "$PASS" --name mysplit --split --size 512 -o "$NAME_SPL_OUT" >/dev/null 2>&1
NAME_PARTS=(${NAME_SPL_OUT}/mysplit.tar.xz.enc.b85.part*(N))
[[ ${#NAME_PARTS[@]} -ge 2 ]] \
    && _pass "--name --split: parts use custom filename" \
    || _fail "--name --split: parts use custom filename (found ${#NAME_PARTS[@]})"
[[ -f "${NAME_SPL_OUT}/mysplit.tar.xz.enc.sha256" ]] \
    && _pass "--name --split: sha256 sidecar uses custom filename" \
    || _fail "--name --split: sha256 sidecar uses custom filename"

# ==============================================================================
echo ""
echo "━━━ Log output separation ━━━"

# All [INFO]/[SUCCESS]/[WARN]/[ERROR] lines must go to stderr.
# secure_list stdout must be pure tar listing — no log noise.
LOG_LIST_STDOUT=$(secure_list "${LIST_ENC[1]}" --password "$PASS" 2>/dev/null)
_assert_not_contains "stdout: no [INFO] lines"    "\[INFO\]"    "$LOG_LIST_STDOUT"
_assert_not_contains "stdout: no [SUCCESS] lines" "\[SUCCESS\]" "$LOG_LIST_STDOUT"
_assert_not_contains "stdout: no [WARN] lines"    "\[WARN\]"    "$LOG_LIST_STDOUT"
_assert_contains     "stdout: tar listing present" "testdata"   "$LOG_LIST_STDOUT"

# Capture stderr only (redirect stdout to /dev/null)
# Use secure_pack which always emits multiple log lines
LOG_PACK_STDERR=$(secure_pack "$SRC" --password "$PASS" \
    -o "${TMP}/log_sep_pack_out" 2>&1 >/dev/null)
_assert_contains "stderr: [INFO] log lines go to stderr"    "\[INFO\]"    "$LOG_PACK_STDERR"
_assert_contains "stderr: [SUCCESS] log lines go to stderr" "\[SUCCESS\]" "$LOG_PACK_STDERR"

# secure_pack stdout should also be empty (all output is log/stderr)
LOG_PACK_STDOUT=$(secure_pack "${LIST_ENC[1]%/*}" --password "$PASS" \
    -o "${TMP}/log_check_out" 2>/dev/null || true)
_assert_eq "pack: stdout is empty" "" "$LOG_PACK_STDOUT"

# ==============================================================================
echo ""
echo "━━━ secure_pack --verify ━━━"

VFY_OUT="${TMP}/out_verify"
mkdir -p "$VFY_OUT"

out=$(secure_pack "$SRC" --password "$PASS" --verify -o "$VFY_OUT" 2>&1)
_assert_contains "--verify: success message present" "[Vv]erif" "$out"
[[ $? -eq 0 ]] && _pass "--verify: exits 0 on good archive" || _fail "--verify: exits 0 on good archive"

VFY_SPL_OUT="${TMP}/out_verify_split"
mkdir -p "$VFY_SPL_OUT"
out=$(secure_pack "$SRC" --password "$PASS" --split --size 512 --verify -o "$VFY_SPL_OUT" 2>&1)
_assert_contains "--verify --split: success message" "[Vv]erif" "$out"

# ==============================================================================
echo ""
echo "━━━ Workspace permissions ━━━"

# Pack and confirm chmod 700 didn't break anything
PERM_OUT="${TMP}/out_perm"
mkdir -p "$PERM_OUT"
secure_pack "$SRC" --password "$PASS" -o "$PERM_OUT" >/dev/null 2>&1
PERM_ENC=(${PERM_OUT}/*.tar.xz.enc(N))
[[ -f "${PERM_ENC[1]}" ]] \
    && _pass "chmod 700 workspace: pack succeeds" \
    || _fail "chmod 700 workspace: pack succeeds"

# Verify no world/group-readable temp dirs were left behind
# (mktemp -d creates /tmp/tmp.XXXXX — we verify none with 755+ perms exist under TMP)
PERM_EXTRACT="${TMP}/extract_perm"
mkdir -p "$PERM_EXTRACT"
secure_unpack "${PERM_ENC[1]}" --password "$PASS" -o "$PERM_EXTRACT" >/dev/null 2>&1
[[ -f "${PERM_EXTRACT}/testdata/a.txt" ]] \
    && _pass "chmod 700 workspace: unpack still works" \
    || _fail "chmod 700 workspace: unpack still works"

# ==============================================================================
echo ""
echo "━━━ Environment variable leak ━━━"

# _sa_encrypt and _sa_decrypt now run in subshells; _SA_OPENSSL_PASS must
# never appear in the parent shell environment after invocation.
echo "dummy" | _sa_encrypt "leaktest" >/dev/null 2>&1 || true
if [[ -z "${_SA_OPENSSL_PASS+x}" ]]; then
    _pass "env: _SA_OPENSSL_PASS not set after _sa_encrypt"
else
    _fail "env: _SA_OPENSSL_PASS leaked into parent shell!"
fi

# Simulate a failed decrypt (bad data) — env must still be clean
echo "bad" | _sa_decrypt /dev/stdin "leaktest" >/dev/null 2>&1 || true
if [[ -z "${_SA_OPENSSL_PASS+x}" ]]; then
    _pass "env: _SA_OPENSSL_PASS not set after failed _sa_decrypt"
else
    _fail "env: _SA_OPENSSL_PASS leaked after failed _sa_decrypt!"
fi

# ==============================================================================
echo ""
echo "━━━ Checksums & tamper detection ━━━"

TAMPER_OUT="${TMP}/out_tamper"
mkdir -p "$TAMPER_OUT"
secure_pack "$SRC" --password "$PASS" -o "$TAMPER_OUT" >/dev/null 2>&1
TAMPER_ENC=(${TAMPER_OUT}/*.tar.xz.enc(N))

# Corrupt one byte in the middle of the archive
python3 -c "
import sys
data = bytearray(open('${TAMPER_ENC[1]}', 'rb').read())
data[len(data)//2] ^= 0xFF
open('${TAMPER_ENC[1]}', 'wb').write(data)
"

out=$(secure_unpack "${TAMPER_ENC[1]}" --password "$PASS" 2>&1); [[ $? -ne 0 ]] \
    && _pass "tamper: corrupted archive rejected at extract" \
    || _fail "tamper: corrupted archive accepted (should have failed)"

# sha256 sidecar mismatch detection
SIDECAR_SHA="${TAMPER_ENC[1]}.sha256"
echo "0000000000000000000000000000000000000000000000000000000000000000" > "$SIDECAR_SHA"
out=$(secure_unpack "${TAMPER_ENC[1]}" --password "$PASS" 2>&1); [[ $? -ne 0 ]] \
    && _pass "tamper: sha256 mismatch detected (unpack)" \
    || _fail "tamper: sha256 mismatch not detected (unpack)"

# secure_list must also reject a tampered archive (sha256 mismatch)
out=$(secure_list "${TAMPER_ENC[1]}" --password "$PASS" 2>&1); [[ $? -ne 0 ]] \
    && _pass "tamper: sha256 mismatch detected (secure_list)" \
    || _fail "tamper: sha256 mismatch not detected (secure_list)"

# secure_list without sidecar — should warn but succeed
rm -f "$SIDECAR_SHA"
list_out=$(secure_list "${TAMPER_ENC[1]}" --password "$PASS" 2>&1 || true)
_assert_contains "tamper: missing sidecar warns in secure_list" "WARN" "$list_out"

# ==============================================================================
echo ""
echo "━━━ --exclude / --include filters ━━━"

FILT_OUT="${TMP}/out_filter"
FILT_EXTRACT="${TMP}/extract_filter"
mkdir -p "$FILT_OUT" "$FILT_EXTRACT"

# Exclude sub/ directory
secure_pack "$SRC" --password "$PASS" --exclude "sub" -o "$FILT_OUT" >/dev/null 2>&1
FILT_ENC=(${FILT_OUT}/*.tar.xz.enc(N))
secure_unpack "${FILT_ENC[1]}" --password "$PASS" -o "$FILT_EXTRACT" >/dev/null 2>&1
[[ -f "${FILT_EXTRACT}/testdata/a.txt" ]] \
    && _pass "exclude: non-excluded file present" \
    || _fail "exclude: non-excluded file present"
[[ ! -d "${FILT_EXTRACT}/testdata/sub" ]] \
    && _pass "exclude: excluded dir absent" \
    || _fail "exclude: excluded dir absent"

# ==============================================================================
echo ""

TOTAL=$(( _T_PASS + _T_FAIL + _T_SKIP ))
echo "━━━ Results: ${_T_PASS}/${TOTAL} passed, ${_T_FAIL} failed, ${_T_SKIP} skipped ━━━"
echo ""

(( _T_FAIL == 0 ))
