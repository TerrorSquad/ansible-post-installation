# ==============================================================================
# SECURE ARCHIVE UTILITY (ZSH PLUGIN)
#
# Compress, encrypt, and optionally split files for secure transport.
# Produces .tar.xz.enc archives (standard) or base85-encoded split parts.
#
# Functions: secure_pack, secure_unpack, secure_list
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
typeset -g  _SA_XZ_LEVEL='9e'          # xz compression level; 1-9 or 9e (extreme)

# SHA-256 command: prefer sha256sum (Linux/WSL), fall back to shasum -a 256 (macOS).
# Detected once at load time so pack and verify always use the same binary.
if command -v sha256sum &>/dev/null; then
    typeset -g _SA_SHA256_CMD='sha256sum'
elif command -v shasum &>/dev/null; then
    typeset -g _SA_SHA256_CMD='shasum -a 256'
else
    typeset -g _SA_SHA256_CMD=''
fi

# Detect tar flavour once at load time (GNU vs BSD have different ownership flags)
if tar --version 2>&1 | grep -q 'GNU'; then
    typeset -ga _SA_TAR_OWNER_OPTS=(--owner=0 --group=0 --numeric-owner)
else
    typeset -ga _SA_TAR_OWNER_OPTS=(--uid 0 --gid 0)
fi

# Directories and file patterns excluded from rsync during pack.
# Rsync applies these recursively unless they start with '/'.
typeset -ga _SA_EXCLUDE_PATTERNS=(
    "node_modules" "vendor" ".git" ".idea" ".vscode" ".DS_Store"
    "dist" ".output" ".nuxt" "coverage" "*.tar.xz.enc" "*.part*"
    "var" ".pnpm-store" "__pycache__" ".env" ".data"
)

# --- Helpers ------------------------------------------------------------------

# Log a colored message: _sa_log <color> <level> <message>
# All log output goes to stderr so stdout can carry pure data (e.g. tar listing).
# Colours are suppressed when $NO_COLOR is set or stderr is not a terminal.
_sa_log() {
    local color="$1" level="$2" msg="$3"
    if [[ -n "${NO_COLOR:-}" || ! -t 2 ]]; then
        echo "[${level}] ${msg}" >&2
    else
        echo -e "${color}[${level}]${_SA_RESET} ${msg}" >&2
    fi
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
try:
    d = sys.stdin.buffer.read()
    e = base64.b85encode(d).decode()
    for i in range(0, len(e), 76): print(e[i:i+76])
except Exception as ex:
    sys.stderr.write('[ERROR] b85 encode: ' + str(ex) + '\\n')
    sys.exit(1)
"
}

# Base85 decode stdin → stdout (strips newlines before decoding)
_sa_b85_decode() {
    python3 -c "
import sys, base64
try:
    sys.stdout.buffer.write(base64.b85decode(sys.stdin.read().replace('\\n','')))
except Exception as ex:
    sys.stderr.write('[ERROR] b85 decode: ' + str(ex) + '\\n')
    sys.exit(1)
"
}

# Verify that all listed commands are available on PATH.
# Reports ALL missing commands before returning, not just the first.
_sa_check_deps() {
    local missing=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            _sa_error "Missing required command: $cmd"
            missing=1
        fi
    done
    return $missing
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

    if [[ -z "$_SA_SHA256_CMD" ]]; then
        _sa_warn "No sha256 tool available — skipping integrity check"
        return 0
    fi

    if [[ ! -f "$sha_file" ]]; then
        _sa_warn "No .sha256 sidecar found — skipping integrity check"
        return 0
    fi

    local expected
    expected=$(awk '{print $1}' "$sha_file")
    local actual
    actual=$(${=_SA_SHA256_CMD} "$file" | awk '{print $1}')

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
    local xz_level="${3:-${_SA_XZ_LEVEL}}"

    if command -v pv &>/dev/null; then
        local bytes
        bytes=$(( $(du -sk "$work_dir/$src_name" 2>/dev/null | cut -f1) * 1024 ))
        tar -C "$work_dir" "${_SA_TAR_OWNER_OPTS[@]}" -cf - "$src_name" \
            | pv -s "$bytes" -N "Compress" \
            | xz -"${xz_level}"
    else
        tar -C "$work_dir" "${_SA_TAR_OWNER_OPTS[@]}" -cf - "$src_name" \
            | xz -"${xz_level}"
    fi
}

# Encrypt stdin with AES-256-CBC (PBKDF2, 100k iterations). Writes to stdout.
# Runs in a subshell so _SA_OPENSSL_PASS is discarded even if openssl fails.
# Usage: _sa_encrypt <password>
_sa_encrypt() {
    (
        export _SA_OPENSSL_PASS="$1"
        openssl enc -"$_SA_CIPHER" -pbkdf2 -iter "$_SA_PBKDF2_ITER" -salt -pass env:_SA_OPENSSL_PASS
    )
}

# Decrypt a file with AES-256-CBC. Writes to stdout.
# Runs in a subshell so _SA_OPENSSL_PASS is discarded even if openssl fails.
# Shows a pv progress bar when pv is available and file size is known.
# Usage: _sa_decrypt <enc_file> <password>
_sa_decrypt() {
    (
        export _SA_OPENSSL_PASS="$2"
        local _dec_cipher="-${_SA_CIPHER}"
        local _dec_args=(-d "$_dec_cipher" -pbkdf2 -iter "$_SA_PBKDF2_ITER" -pass env:_SA_OPENSSL_PASS)
        if command -v pv &>/dev/null && [[ -f "$1" ]]; then
            local bytes
            bytes=$(wc -c < "$1")
            pv -s "$bytes" -N "Decrypt" "$1" | openssl enc "${_dec_args[@]}"
        else
            openssl enc "${_dec_args[@]}" -in "$1"
        fi
    )
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
        local password_provided=false
        local output_dir=""
        local do_split=false
        local do_copy=false
        local chunk_size="$_SA_DEFAULT_CHUNK"
        local user_set_size=false
        local do_verify=false
        local do_dry_run=false
        local do_force=false
        local archive_base=""
        local xz_level="$_SA_XZ_LEVEL"
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
  --verify                Verify the archive is readable after packing
  --name <basename>       Override output filename (default: <src>_<timestamp>)
  --level <1-9|9e>        xz compression level (default: 9e)
  --dry-run               Show what would be packed without creating any files
  --force                 Overwrite existing output files without prompting
  -h, --help              Show this help

Examples:
  secure_pack ./project --password s3cret --split --size 128k
  secure_pack ./docs --split --copy --verify -o /tmp/output
  secure_pack ./docs --name docs_v2 -o /tmp/release
EOF
                    return 0
                    ;;
                --password)  password="$2"; password_provided=true; shift 2 ;;
                --split)     do_split=true;                    shift   ;;
                --copy)      do_copy=true;                     shift   ;;
                --size)      chunk_size="$2"; user_set_size=true; shift 2 ;;
                -o|--output) output_dir="$2";                  shift 2 ;;
                --include)   user_includes+=("$2"); shift 2 ;;
                --exclude)   user_excludes+=("$2"); shift 2 ;;
                --verify)    do_verify=true;         shift   ;;
                --name)      archive_base="$2";      shift 2 ;;
                --level)     xz_level="$2";          shift 2 ;;
                --dry-run)   do_dry_run=true;        shift   ;;
                --force)     do_force=true;          shift   ;;
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
        if [[ "$do_split" == true ]] && ! [[ "$chunk_size" =~ ^[1-9][0-9]*[kKmMgG]?$ ]]; then
            _sa_error "Invalid --size value: '$chunk_size'. Expected e.g. 500k, 10m, 1g."
            return 1
        fi
        if [[ "$user_set_size" == true && "$do_split" == false ]]; then
            _sa_warn "--size has no effect without --split"
        fi
        if ! [[ "$xz_level" =~ ^[1-9]e?$ ]]; then
            _sa_error "Invalid --level value: '$xz_level'. Expected 1-9 or 9e."
            return 1
        fi

        output_dir=$(_sa_resolve_dir "$output_dir")

        # --- Password (interactive prompt with verification) ---
        if [[ "$password_provided" == false ]]; then
            local password_verify
            echo -n "Enter encryption password: " >/dev/tty
            read -s password </dev/tty
            echo >/dev/tty
            echo -n "Verify password: " >/dev/tty
            read -s password_verify </dev/tty
            echo >/dev/tty

            if [[ "$password" != "$password_verify" ]]; then
                _sa_error "Passwords do not match."
                return 1
            fi
        fi
        if [[ -z "$password" ]]; then
            _sa_error "Password cannot be empty."
            return 1
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
        work_dir=$(mktemp -d)
        chmod 700 "$work_dir"

        # Resolve archive base name: user-supplied or auto-generated
        if [[ -z "$archive_base" ]]; then
            archive_base="${src_name}_${timestamp}"
        fi

        # --- Rsync (filtered working copy) ---
        _sa_info "Creating working copy..."

        local -a rsync_args=(-aq)
        for p in "${user_includes[@]}"; do
            rsync_args+=(--include "$p")
        done
        for p in "${user_excludes[@]}"; do
            rsync_args+=(--exclude "$p")
        done
        # Honour .gitignore files found anywhere in the source tree
        rsync_args+=(--filter=':- .gitignore')
        for p in "${_SA_EXCLUDE_PATTERNS[@]}"; do
            rsync_args+=(--exclude "$p")
        done

        rsync "${rsync_args[@]}" "$source_path" "$work_dir"

        # --- Pre-pack Summary ---
        local file_count dir_size
        file_count=$(find "$work_dir/$src_name" -type f | wc -l | tr -d ' ')
        dir_size=$(du -sh "$work_dir/$src_name" 2>/dev/null | cut -f1)
        _sa_info "Packing: $file_count files, ~$dir_size uncompressed"

        # --- Sensitive-File Check ---
        local -a _sf_find_args=()
        local _sf_pat
        for _sf_pat in '*.env' '.env' '*.pem' '*.key' '*.p12' '*.pfx' '*.p8' \
                       'id_rsa*' 'id_dsa*' 'id_ecdsa*' 'id_ed25519*' \
                       '*_token*' '*secret*' '*password*' '*credentials*' \
                       '*.vault' '*.gpg' '*.asc'; do
            [[ ${#_sf_find_args[@]} -gt 0 ]] && _sf_find_args+=(-o)
            _sf_find_args+=(-name "$_sf_pat")
        done
        local _sf_hits
        _sf_hits=$(find "$work_dir/$src_name" -type f \( "${_sf_find_args[@]}" \) 2>/dev/null)
        if [[ -n "$_sf_hits" ]]; then
            while IFS= read -r _sf_hit; do
                _sa_warn "Sensitive file included: ${_sf_hit#${work_dir}/${src_name}/}"
            done <<< "$_sf_hits"
        fi

        # --- Dry Run ---
        if [[ "$do_dry_run" == true ]]; then
            _sa_info "Dry run — files that would be packed:"
            find "$work_dir/$src_name" -type f | sed "s|${work_dir}/${src_name}/||" | sort >&2
            return 0
        fi

        # --- Compress + Encrypt ---
        _sa_info "Compressing and encrypting..."

        local payload="${work_dir}/payload.enc"
        _sa_compress "$work_dir" "$src_name" "$xz_level" | _sa_encrypt "$password" > "$payload"

        # --- Checksum ---
        local checksum
        checksum=$(${=_SA_SHA256_CMD} "$payload" | awk '{print $1}')
        _sa_info "SHA-256: $checksum"

        local archive_name="${archive_base}.tar.xz.enc"

        # --- Collision Guard ---
        if [[ "$do_force" == false ]]; then
            local _col_conflict=false
            if [[ "$do_split" == true ]]; then
                # First split part would be ${archive_name}.b85.partaa
                local -a _col_existing=(${output_dir}/${archive_name}.b85.part*(N))
                [[ ${#_col_existing[@]} -gt 0 ]] && _col_conflict=true
            else
                [[ -f "${output_dir}/${archive_name}" ]] && _col_conflict=true
            fi
            [[ -f "${output_dir}/${archive_name}.sha256" ]] && _col_conflict=true
            if [[ "$_col_conflict" == true ]]; then
                _sa_error "Output already exists: ${output_dir}/${archive_name} — use --force to overwrite."
                return 1
            fi
        fi

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
            (( lines_per_chunk < 1 )) && lines_per_chunk=1

            _sa_b85_encode < "$payload" | split -l "$lines_per_chunk" - "$split_prefix"
            local parts_size
            parts_size=$(du -shc ${split_prefix}*(N) 2>/dev/null | tail -1 | cut -f1)
            _sa_success "Split parts: ${archive_name}.b85.part*"
            _sa_info    "Output size: ~${parts_size} total"

            if [[ "$do_copy" == true ]]; then
                _sa_copy_to_clipboard "${split_prefix}aa"
            fi
        else
            mv "$payload" "${output_dir}/${archive_name}"
            local enc_size
            enc_size=$(du -sh "${output_dir}/${archive_name}" 2>/dev/null | cut -f1)
            _sa_success "Archive: ${archive_name}"
            _sa_info    "Output size: ${enc_size}"

            if [[ "$do_copy" == true ]]; then
                _sa_warn "Cannot copy binary to clipboard"
            fi
        fi

        # --- Verify (optional) ---
        if [[ "$do_verify" == true ]]; then
            _sa_info "Verifying archive (test decrypt)..."
            local verify_input
            if [[ "$do_split" == true ]]; then
                verify_input="${split_prefix}aa"
            else
                verify_input="${output_dir}/${archive_name}"
            fi
            if secure_list "$verify_input" --password "$password" >/dev/null 2>&1; then
                _sa_success "Archive verified — decrypt and listing OK"
            else
                _sa_error "Archive verification failed — the output may be corrupt."
                return 1
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
        local password_provided=false
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
  secure_unpack ./backup.tar.xz.enc.b85.partaa --password s3cret
EOF
                    return 0
                    ;;
                --password)  password="$2"; password_provided=true; shift 2 ;;
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

        # --- Dependencies ---
        _sa_check_deps tar xz openssl python3 || return 1

        # --- Validation ---
        if [[ -z "$input_pattern" ]]; then
            _sa_error "Input file or pattern required."
            return 1
        fi

        if [[ "$password_provided" == false ]]; then
            echo -n "Enter decryption password: " >/dev/tty
            read -s password </dev/tty
            echo >/dev/tty
        fi
        if [[ -z "$password" ]]; then
            _sa_error "Password cannot be empty."
            return 1
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

        # If the user provided a single part file (e.g. docs.enc.partaa),
        # automatically expand it to include all parts.
        if [[ ${#file_list[@]} -eq 1 && "${file_list[1]}" == *part* ]]; then
            local base_name="${file_list[1]%part*}"
            file_list=(${base_name}part*(N))
            _sa_info "Auto-detected ${#file_list[@]} parts for split archive"
        fi

        # Both modes resolve to enc_file + sha_file, then share
        # the same verify → decrypt → extract path below.
        local enc_file=""
        local sha_file=""
        local is_split=false

        if [[ "${file_list[1]}" == *part* ]]; then
            is_split=true
            _sa_info "Mode: Split Archive"

            enc_file=$(mktemp)
            trap "rm -f '$enc_file'" EXIT INT TERM HUP

            # Determine the base name for the sidecar file
            if [[ "${file_list[1]}" == *.b85.part* ]]; then
                sha_file="${file_list[1]%.b85.part*}.sha256"
            else
                sha_file="${file_list[1]%.part*}.sha256"
            fi

            # Concatenate all parts and decode from base85 to binary.
            # Shows a pv progress bar when available.
            if command -v pv &>/dev/null; then
                local total_bytes=0
                local _pv_f
                for _pv_f in "${file_list[@]}"; do
                    (( total_bytes += $(wc -c < "$_pv_f") ))
                done
                cat "${file_list[@]}" | pv -s "$total_bytes" -N "Reassemble" | _sa_b85_decode > "$enc_file"
            else
                cat "${file_list[@]}" | _sa_b85_decode > "$enc_file"
            fi
        else
            _sa_info "Mode: Standard Archive"
            enc_file="${file_list[1]}"
            sha_file="${enc_file}.sha256"
        fi

        # --- Verify + Extract ---
        _sa_verify_checksum "$enc_file" "$sha_file" || return 1

        # Count entries via a listing pass, then extract.
        local extracted_count
        extracted_count=$(_sa_decrypt "$enc_file" "$password" | tar -tJf - 2>/dev/null | wc -l | tr -d ' ')
        _sa_decrypt "$enc_file" "$password" | tar -xJf - -C "$output_dir"

        # Clean up the temp file created for split mode
        if [[ "$is_split" == true ]]; then
            rm -f "$enc_file"
        fi

        _sa_success "Extracted ${extracted_count} files in $(_sa_elapsed $(( SECONDS - start_time ))) → $output_dir"
    )
}

# ==============================================================================
# secure_list — inspect archive contents without extracting
# ==============================================================================
secure_list() {
    (
        set -euo pipefail

        # --- Variables ---
        local input_pattern=""
        local password=""
        local password_provided=false
        local do_long=false

        # --- Argument Parsing ---
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    cat <<'EOF'
Usage: secure_list <file_or_pattern> [options]

List the contents of an archive created by secure_pack without extracting.

Options:
  --password <pass>       Decryption password (prompted if omitted)
  -l, --long              Detailed listing (permissions, size, timestamps)
  -h, --help              Show this help

Examples:
  secure_list ./backup.tar.xz.enc
  secure_list ./backup.tar.xz.enc.b85.partaa --password s3cret
  secure_list ./backup.tar.xz.enc --long
EOF
                    return 0
                    ;;
                --password)  password="$2"; password_provided=true; shift 2 ;;
                -l|--long)   do_long=true;  shift   ;;
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

        # --- Dependencies ---
        _sa_check_deps tar xz openssl python3 || return 1

        # --- Validation ---
        if [[ -z "$input_pattern" ]]; then
            _sa_error "Input file or pattern required."
            return 1
        fi

        if [[ "$password_provided" == false ]]; then
            echo -n "Enter decryption password: " >/dev/tty
            read -s password </dev/tty
            echo >/dev/tty
        fi
        if [[ -z "$password" ]]; then
            _sa_error "Password cannot be empty."
            return 1
        fi

        # --- Expand + Assemble ---
        local -a file_list=(${~input_pattern}(N))
        if [[ ${#file_list[@]} -eq 0 ]]; then
            _sa_error "No files found matching: $input_pattern"
            return 1
        fi

        if [[ ${#file_list[@]} -eq 1 && "${file_list[1]}" == *part* ]]; then
            local base_name="${file_list[1]%part*}"
            file_list=(${base_name}part*(N))
            _sa_info "Auto-detected ${#file_list[@]} parts for split archive"
        fi

        local enc_file=""
        local sha_file=""
        local is_split=false

        if [[ "${file_list[1]}" == *part* ]]; then
            is_split=true
            enc_file=$(mktemp)
            trap "rm -f '$enc_file'" EXIT INT TERM HUP
            # Derive sidecar path (mirrors secure_unpack logic)
            if [[ "${file_list[1]}" == *.b85.part* ]]; then
                sha_file="${file_list[1]%.b85.part*}.sha256"
            else
                sha_file="${file_list[1]%.part*}.sha256"
            fi
            if command -v pv &>/dev/null; then
                local total_bytes=0
                local _pv_f
                for _pv_f in "${file_list[@]}"; do
                    (( total_bytes += $(wc -c < "$_pv_f") ))
                done
                cat "${file_list[@]}" | pv -s "$total_bytes" -N "Reassemble" | _sa_b85_decode > "$enc_file"
            else
                cat "${file_list[@]}" | _sa_b85_decode > "$enc_file"
            fi
        else
            enc_file="${file_list[1]}"
            sha_file="${enc_file}.sha256"
        fi

        # --- Verify ---
        _sa_verify_checksum "$enc_file" "$sha_file" || return 1

        # --- Decrypt & List ---
        local -a tar_list_flags
        if [[ "$do_long" == true ]]; then
            tar_list_flags=(-t -v -J -f)
        else
            tar_list_flags=(-t -J -f)
        fi
        local listing entry_count
        listing=$(_sa_decrypt "$enc_file" "$password" | tar "${tar_list_flags[@]}" -)
        [[ -n "$listing" ]] && printf '%s\n' "$listing"
        entry_count=0
        [[ -n "$listing" ]] && entry_count=$(printf '%s\n' "$listing" | wc -l | tr -d ' ')
        local _sl_noun; [[ "$entry_count" -eq 1 ]] && _sl_noun="entry" || _sl_noun="entries"
        _sa_info "── ${entry_count} ${_sl_noun}"

        if [[ "$is_split" == true ]]; then
            rm -f "$enc_file"
        fi
    )
}

# ==============================================================================
# ZSH Completions
# ==============================================================================

_secure_pack() {
    _arguments \
        '(-h --help)'{-h,--help}'[Show this help]' \
        '--password[Encryption password]:password' \
        '--split[Split output into base85-encoded chunks]' \
        '--size[Chunk size for split (default: 500k)]:size:(128k 256k 500k 1m 5m)' \
        '--copy[Copy first chunk to clipboard]' \
        '--verify[Verify the archive is readable after packing]' \
        '--name[Override output filename (without extension)]:basename' \
        '--level[xz compression level (1-9 or 9e)]:level:(1 2 3 4 5 6 7 8 9 9e)' \
        '--dry-run[Show what would be packed without creating any files]' \
        '--force[Overwrite existing output files without prompting]' \
        '(-o --output)'{-o,--output}'[Output directory]:directory:_files -/' \
        '*--include[Rsync include pattern]:pattern' \
        '*--exclude[Rsync exclude pattern]:pattern' \
        '1:source path:_files'
}

_secure_unpack() {
    _arguments \
        '(-h --help)'{-h,--help}'[Show this help]' \
        '--password[Decryption password]:password' \
        '(-o --output)'{-o,--output}'[Output directory]:directory:_files -/' \
        '1:archive file:_files -g "*.enc *.b85.partaa *.partaa"'
}

_secure_list() {
    _arguments \
        '(-h --help)'{-h,--help}'[Show this help]' \
        '--password[Decryption password]:password' \
        '(-l --long)'{-l,--long}'[Detailed listing (permissions, size, timestamps)]' \
        '1:archive file:_files -g "*.enc *.b85.partaa *.partaa"'
}

if (( $+functions[compdef] )); then
    compdef _secure_pack   secure_pack
    compdef _secure_unpack secure_unpack
    compdef _secure_list   secure_list
fi
