# ==============================================================================
# SECURE ARCHIVE UTILITY (ZSH PLUGIN)
#
# Compress, encrypt, and optionally split files for secure transport.
# Produces .tar.xz.enc archives (standard) or base85-encoded split parts.
#
# Dependencies: tar, xz, openssl, split, rsync, python3
# Optional:     pv (progress bar)
# ==============================================================================

# --- Constants ----------------------------------------------------------------

typeset -g  _SA_RED='\033[0;31m'
typeset -g  _SA_GREEN='\033[0;32m'
typeset -g  _SA_YELLOW='\033[0;33m'
typeset -g  _SA_BLUE='\033[0;34m'
typeset -g  _SA_RESET='\033[0m'

typeset -g  _SA_CIPHER='aes-256-cbc'
typeset -gi _SA_PBKDF2_ITER=100000
typeset -g  _SA_DEFAULT_CHUNK='500k'

# Directories and file patterns excluded from rsync during pack.
# Rsync applies these recursively unless they start with '/'.
typeset -ga _SA_EXCLUDE_PATTERNS=(
    "node_modules" "vendor" ".git" ".idea" ".vscode" ".DS_Store"
    "dist" ".output" ".nuxt" "coverage" "*.tar.xz.enc" "*.part*"
    "var" ".pnpm-store" "__pycache__" ".env"
)

# --- Helpers ------------------------------------------------------------------

# Log a colored message: _sa_log <color> <level> <message>
_sa_log() {
    echo -e "${1}[${2}]${_SA_RESET} ${3}"
}

_sa_info()    { _sa_log "$_SA_BLUE"   "INFO"    "$1"; }
_sa_success() { _sa_log "$_SA_GREEN"  "SUCCESS" "$1"; }
_sa_warn()    { _sa_log "$_SA_YELLOW" "WARN"    "$1"; }
_sa_error()   { _sa_log "$_SA_RED"    "ERROR"   "$1"; }

# Format seconds as human-readable duration (e.g. "2m05s" or "8s")
_sa_elapsed() {
    local s=$1
    if (( s >= 60 )); then
        printf "%dm%02ds" $((s / 60)) $((s % 60))
    else
        printf "%ds" "$s"
    fi
}

# Base85 encode stdin → stdout (line-wrapped at 76 chars for split transport)
_sa_b85_encode() {
    python3 -c "
import sys, base64
d = sys.stdin.buffer.read()
e = base64.b85encode(d).decode()
for i in range(0, len(e), 76): print(e[i:i+76])
"
}

# Base85 decode stdin → stdout (strips newlines before decoding)
_sa_b85_decode() {
    python3 -c "
import sys, base64
sys.stdout.buffer.write(base64.b85decode(sys.stdin.read().replace('\n','')))
"
}

# Verify that all listed commands are available on PATH
_sa_check_deps() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            _sa_error "Missing required command: $cmd"
            return 1
        fi
    done
}

# Resolve an output directory to an absolute path (creates it if needed).
# Falls back to $PWD when no argument is given.
_sa_resolve_dir() {
    if [[ -n "$1" ]]; then
        mkdir -p "$1"
        (cd "$1" && pwd)
    else
        pwd
    fi
}

# Verify a file's SHA-256 against a sidecar .sha256 file.
# Returns 0 (pass) if the sidecar is missing — that's a non-fatal warning.
_sa_verify_checksum() {
    local file="$1"
    local sha_file="$2"

    if [[ ! -f "$sha_file" ]]; then
        _sa_warn "No .sha256 sidecar found — skipping integrity check"
        return 0
    fi

    local expected
    expected=$(awk '{print $1}' "$sha_file")
    local actual
    actual=$(shasum -a 256 "$file" | awk '{print $1}')

    if [[ "$expected" == "$actual" ]]; then
        _sa_success "SHA-256 checksum OK"
        return 0
    fi

    _sa_error "SHA-256 mismatch! Expected: ${expected}, Got: ${actual}"
    return 1
}

# Copy a file to the system clipboard (cross-platform).
_sa_copy_to_clipboard() {
    local file="$1"

    for tool in pbcopy clip.exe wl-copy xclip; do
        if ! command -v "$tool" &>/dev/null; then
            continue
        fi

        case "$tool" in
            xclip) xclip -selection clipboard < "$file" ;;
            *)     "$tool" < "$file" ;;
        esac

        _sa_info "Copied to clipboard"
        return 0
    done

    _sa_warn "No clipboard tool found"
}

# Create a tar archive with anonymized ownership, compress with xz -9e.
# Shows a pv progress bar when available. Writes to stdout.
_sa_compress() {
    local work_dir="$1"
    local src_name="$2"

    # Anonymize file ownership (GNU and BSD tar use different flags)
    local -a tar_opts
    if tar --version 2>&1 | grep -q "GNU"; then
        tar_opts=(--owner=0 --group=0 --numeric-owner)
    else
        tar_opts=(--uid 0 --gid 0)
    fi

    if command -v pv &>/dev/null; then
        local bytes
        bytes=$(( $(du -sk "$work_dir/$src_name" 2>/dev/null | cut -f1) * 1024 ))
        tar -C "$work_dir" "${tar_opts[@]}" -cf - "$src_name" \
            | pv -s "$bytes" -N "Compress" \
            | xz -9e
    else
        tar -C "$work_dir" "${tar_opts[@]}" -cf - "$src_name" \
            | xz -9e
    fi
}

# Encrypt stdin with AES-256-CBC (PBKDF2, 100k iterations). Writes to stdout.
# Usage: _sa_encrypt <password>
_sa_encrypt() {
    export SA_PASS="$1"
    openssl enc -"$_SA_CIPHER" -pbkdf2 -iter "$_SA_PBKDF2_ITER" -salt -pass env:SA_PASS
}

# Decrypt a file with AES-256-CBC. Writes to stdout.
# Usage: _sa_decrypt <enc_file> <password>
_sa_decrypt() {
    export SA_PASS="$2"
    openssl enc -d -"$_SA_CIPHER" -pbkdf2 -iter "$_SA_PBKDF2_ITER" -in "$1" -pass env:SA_PASS
}

# ==============================================================================
# secure_pack — compress, encrypt, and optionally split
# ==============================================================================
secure_pack() {
    (
        set -euo pipefail

        # --- Variables ---
        local source_path=""
        local password=""
        local output_dir=""
        local do_split=false
        local do_copy=false
        local chunk_size="$_SA_DEFAULT_CHUNK"
        local -a user_includes=()
        local -a user_excludes=()
        local work_dir=""

        # --- Traps ---
        trap '[[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"' EXIT
        trap '_sa_warn "Interrupted."; exit 1' INT TERM HUP

        # --- Dependencies ---
        _sa_check_deps tar xz openssl split rsync python3 || return 1

        # --- Argument Parsing ---
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    cat <<'EOF'
Usage: secure_pack <path> [options]

Compress, encrypt, and optionally split a file or directory.

Options:
  --password <pass>       Encryption password (prompted if omitted)
  --split                 Split output into base85-encoded chunks
  --size <size>           Chunk size for split (default: 500k)
  -o, --output <dir>      Output directory (default: cwd)
  --copy                  Copy first chunk to clipboard
  --include <pattern>     Rsync include pattern (repeatable)
  --exclude <pattern>     Rsync exclude pattern (repeatable)
  -h, --help              Show this help

Examples:
  secure_pack ./project --password s3cret --split --size 128k
  secure_pack ./docs --split --copy -o /tmp/output
EOF
                    return 0
                    ;;
                --password)  password="$2";         shift 2 ;;
                --split)     do_split=true;         shift   ;;
                --copy)      do_copy=true;          shift   ;;
                --size)      chunk_size="$2";       shift 2 ;;
                -o|--output) output_dir="$2";       shift 2 ;;
                --include)   user_includes+=("$2"); shift 2 ;;
                --exclude)   user_excludes+=("$2"); shift 2 ;;
                -*)
                    _sa_error "Unknown option: $1"
                    return 1
                    ;;
                *)
                    if [[ -z "$source_path" ]]; then
                        source_path="$1"
                        shift
                    else
                        _sa_error "Multiple source paths."
                        return 1
                    fi
                    ;;
            esac
        done

        # --- Validation ---
        source_path="${source_path%/}"
        if [[ -z "$source_path" ]]; then
            _sa_error "Source path required."
            return 1
        fi
        if [[ ! -e "$source_path" ]]; then
            _sa_error "Path not found: $source_path"
            return 1
        fi

        output_dir=$(_sa_resolve_dir "$output_dir")

        # --- Password (interactive prompt with verification) ---
        if [[ -z "$password" ]]; then
            local password_verify
            echo -n "Enter encryption password: "
            read -s password
            echo
            echo -n "Verify password: "
            read -s password_verify
            echo

            if [[ "$password" != "$password_verify" ]]; then
                _sa_error "Passwords do not match."
                return 1
            fi
        fi

        # --- Workspace Setup ---
        local start_time=$SECONDS
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)

        if [[ -d "$source_path" ]]; then
            source_path=$(cd "$source_path" && pwd)
        fi

        local src_name
        src_name=$(basename "$source_path")
        work_dir="/tmp/secure_pack_${timestamp}"
        mkdir -p "$work_dir"

        # --- Rsync (filtered working copy) ---
        _sa_info "Creating working copy..."

        local -a rsync_args=(-aq)
        for p in "${user_includes[@]}"; do
            rsync_args+=(--include "$p")
        done
        for p in "${user_excludes[@]}"; do
            rsync_args+=(--exclude "$p")
        done
        for p in "${_SA_EXCLUDE_PATTERNS[@]}"; do
            rsync_args+=(--exclude "$p")
        done

        rsync "${rsync_args[@]}" "$source_path" "$work_dir"

        # --- Compress + Encrypt ---
        _sa_info "Compressing and encrypting..."

        local payload="${work_dir}/payload.enc"
        _sa_compress "$work_dir" "$src_name" | _sa_encrypt "$password" > "$payload"

        # --- Checksum ---
        local checksum
        checksum=$(shasum -a 256 "$payload" | awk '{print $1}')
        _sa_info "SHA-256: $checksum"

        local archive_name="${src_name}_${timestamp}.tar.xz.enc"
        echo "$checksum" > "${output_dir}/${archive_name}.sha256"

        # --- Output (split or single file) ---
        if [[ "$do_split" == true ]]; then
            local split_prefix="${output_dir}/${archive_name}.b85.part"

            # Each base85 line is exactly 77 bytes (76 chars + newline).
            # Convert the chunk size to a line count so split -l never
            # cuts a line in the middle — portable across BSD and GNU split.
            local chunk_num="${chunk_size%[kKmMgG]}"
            local chunk_suf="${(L)chunk_size[-1]}"
            local chunk_bytes
            case "$chunk_suf" in
                k) chunk_bytes=$(( chunk_num * 1024 )) ;;
                m) chunk_bytes=$(( chunk_num * 1024 * 1024 )) ;;
                g) chunk_bytes=$(( chunk_num * 1024 * 1024 * 1024 )) ;;
                *) chunk_bytes=$chunk_num ;;
            esac
            local lines_per_chunk=$(( chunk_bytes / 77 ))

            _sa_b85_encode < "$payload" | split -l "$lines_per_chunk" - "$split_prefix"
            _sa_success "Split parts: ${archive_name}.b85.part*"

            if [[ "$do_copy" == true ]]; then
                _sa_copy_to_clipboard "${split_prefix}aa"
            fi
        else
            mv "$payload" "${output_dir}/${archive_name}"
            _sa_success "Archive: ${archive_name}"

            if [[ "$do_copy" == true ]]; then
                _sa_warn "Cannot copy binary to clipboard"
            fi
        fi

        # --- Cleanup ---
        _sa_info "Completed in $(_sa_elapsed $(( SECONDS - start_time )))"
        rm -rf "$work_dir"
        work_dir=""
    )
}

# ==============================================================================
# secure_unpack — decrypt and extract
# ==============================================================================
secure_unpack() {
    (
        set -euo pipefail

        # --- Variables ---
        local input_pattern=""
        local password=""
        local output_dir=""

        # --- Argument Parsing ---
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    cat <<'EOF'
Usage: secure_unpack <file_or_pattern> [options]

Decrypt and extract an archive created by secure_pack.
Auto-detects standard vs split mode from the input.

Options:
  --password <pass>       Decryption password (prompted if omitted)
  -o, --output <dir>      Output directory (default: cwd)
  -h, --help              Show this help

Examples:
  secure_unpack ./backup.tar.xz.enc
  secure_unpack './backup.tar.xz.enc.b85.part*' --password s3cret
EOF
                    return 0
                    ;;
                --password)  password="$2";   shift 2 ;;
                -o|--output) output_dir="$2"; shift 2 ;;
                -*)
                    _sa_error "Unknown option: $1"
                    return 1
                    ;;
                *)
                    if [[ -z "$input_pattern" ]]; then
                        input_pattern="$1"
                        shift
                    else
                        _sa_error "Multiple inputs."
                        return 1
                    fi
                    ;;
            esac
        done

        # --- Validation ---
        if [[ -z "$input_pattern" ]]; then
            _sa_error "Input file or pattern required."
            return 1
        fi

        if [[ -z "$password" ]]; then
            echo -n "Enter decryption password: "
            read -s password
            echo
        fi

        output_dir=$(_sa_resolve_dir "$output_dir")

        # --- Decrypt ---
        local start_time=$SECONDS
        _sa_info "Decrypting..."

        # Expand glob using zsh's ${~var}(N) — the (N) qualifier suppresses
        # "no matches" errors and produces an empty array instead.
        local -a file_list=(${~input_pattern}(N))
        if [[ ${#file_list[@]} -eq 0 ]]; then
            _sa_error "No files found matching: $input_pattern"
            return 1
        fi

        # Both modes resolve to enc_file + sha_file, then share
        # the same verify → decrypt → extract path below.
        local enc_file=""
        local sha_file=""
        local is_split=false

        if [[ "$input_pattern" == *part* ]]; then
            is_split=true
            _sa_info "Mode: Split Archive"

            sha_file="${file_list[1]%.b85.part*}.sha256"
            enc_file=$(mktemp)
            trap "rm -f '$enc_file'" EXIT INT TERM HUP

            # Concatenate all parts, decode from base85 to binary
            cat "${file_list[@]}" | _sa_b85_decode > "$enc_file"
        else
            _sa_info "Mode: Standard Archive"
            enc_file="${file_list[1]}"
            sha_file="${enc_file}.sha256"
        fi

        # --- Verify + Extract ---
        _sa_verify_checksum "$enc_file" "$sha_file" || return 1
        _sa_decrypt "$enc_file" "$password" | tar -xJf - -C "$output_dir"

        # Clean up the temp file created for split mode
        if [[ "$is_split" == true ]]; then
            rm -f "$enc_file"
        fi

        _sa_success "Extracted in $(_sa_elapsed $(( SECONDS - start_time )))"
    )
}
