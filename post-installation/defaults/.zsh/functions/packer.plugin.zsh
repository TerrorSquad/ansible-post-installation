# ==============================================================================
# SECURE ARCHIVE UTILITY (ZSH MODULE)
# Role: Archiving, Cleaning, Encryption, and Data Mimicry
# Stack: Zsh, OpenSSL, Tar/XZ, Python3
# Usage: Source this file in .zshrc -> 'source ~/path/to/secure_functions.zsh'
# ==============================================================================

# --- Internal Helper: Python Mimic Script ---
_sa_get_mimic_script() {
    cat << 'EOF'
import sys, random, base64, datetime

MARKER = "TraceID:"
CHUNK_SIZE = 512

def generate_noise():
    components = ["kernel", "auth", "scheduler", "httpd", "sshd", "php-fpm"]
    levels = ["INFO", "DEBUG"]
    messages = [
        "Connection established",
        "Cache miss for key user_preference",
        "Worker process started",
        "Db connection pool health check: OK",
        "Garbage collection triggered",
        "Index rebuild complete",
        "User session refreshed",
        "Packet received from 192.168.1.x",
        "Job queue processed 0 items"
    ]
    return random.choice(components), random.choice(levels), random.choice(messages)

def pack():
    try:
        payload = sys.stdin.buffer.read()
    except AttributeError:
        payload = sys.stdin.read()

    payload_b64 = base64.b64encode(payload).decode('utf-8')
    raw_chunks = [payload_b64[i:i+CHUNK_SIZE] for i in range(0, len(payload_b64), CHUNK_SIZE)]

    wrapped_packets = []
    for i, chunk in enumerate(raw_chunks):
        packet_str = f"{i}|{chunk}"
        packet_b64 = base64.b64encode(packet_str.encode()).decode('utf-8')
        wrapped_packets.append(packet_b64)

    random.shuffle(wrapped_packets)

    curr_time = datetime.datetime.now() - datetime.timedelta(days=1)

    for packet in wrapped_packets:
        for _ in range(random.randint(0, 1)):
            curr_time += datetime.timedelta(milliseconds=random.randint(5, 500))
            ts = curr_time.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
            comp, lvl, msg = generate_noise()
            print(f"[{ts}] [{lvl}] [{comp}] {msg}")

        curr_time += datetime.timedelta(milliseconds=random.randint(1, 20))
        ts = curr_time.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        print(f"[{ts}] [DEBUG] [app-core] Transaction commit. {MARKER} {packet}")

def unpack():
    fragments = []
    for line in sys.stdin:
        if MARKER in line:
            try:
                blob = line.strip().split(MARKER)[1].strip()
                packet = base64.b64decode(blob).decode('utf-8')
                if "|" in packet:
                    idx_str, data = packet.split("|", 1)
                    fragments.append((int(idx_str), data))
            except Exception:
                continue

    fragments.sort(key=lambda x: x[0])
    full_b64 = "".join(f[1] for f in fragments)

    try:
        sys.stdout.buffer.write(base64.b64decode(full_b64))
    except AttributeError:
        sys.stdout.write(base64.b64decode(full_b64))

if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == 'pack': pack()
    elif mode == 'unpack': unpack()
EOF
}

# --- Internal Helper: Logging ---
_sa_log() {
    local color="$1"
    local level="$2"
    local message="$3"
    local RESET='\033[0m'
    echo -e "${color}[${level}]${RESET} ${message}"
}

# --- Internal Helper: Clipboard ---
_sa_copy_to_clipboard() {
    local file="$1"
    local content=$(cat "$file")
    local BLUE='\033[0;34m'
    local RED='\033[0;31m'
    local RESET='\033[0m'

    if command -v pbcopy &> /dev/null; then
        # MacOS
        cat "$file" | pbcopy
        _sa_log "$BLUE" "INFO" "Content copied to clipboard (MacOS)."
    elif command -v clip.exe &> /dev/null; then
        # WSL / Windows
        cat "$file" | clip.exe
        _sa_log "$BLUE" "INFO" "Content copied to clipboard (WSL)."
    elif command -v wl-copy &> /dev/null; then
        # Wayland
        cat "$file" | wl-copy
        _sa_log "$BLUE" "INFO" "Content copied to clipboard (Wayland)."
    elif command -v xclip &> /dev/null; then
        # X11
        cat "$file" | xclip -selection clipboard
        _sa_log "$BLUE" "INFO" "Content copied to clipboard (X11)."
    else
        _sa_log "$RED" "WARN" "Clipboard tool not found. Could not copy."
    fi
}

# ==============================================================================
# FUNCTION: PACK
# ==============================================================================
secure_pack() {
    # Run in subshell to contain set -e and variables
    (
        set -euo pipefail

        # Defaults
        local DEFAULT_CHUNK_SIZE="500k"
        local RED='\033[0;31m'
        local GREEN='\033[0;32m'
        local BLUE='\033[0;34m'

        # Maximize compression for chat transport
        export XZ_OPT="-9e"

        # Logic Vars
        local source_path=""
        local password=""
        local do_split=false
        local do_mimic=false
        local do_copy=false
        local chunk_size="$DEFAULT_CHUNK_SIZE"
        local user_includes=()
        local user_excludes=()

        # Dependency Check
        for cmd in tar xz openssl base64 split rsync python3; do
            if ! command -v "$cmd" &> /dev/null; then
                 _sa_log "$RED" "ERROR" "Missing required command: $cmd"; return 1
            fi
        done

        # Default Excludes
        # Note: rsync applies these recursively unless they start with '/'
        local -a exclude_patterns=(
            "node_modules" "vendor" ".git" ".idea" ".vscode" ".DS_Store"
            "dist" ".output" ".nuxt" "coverage" "*.tar.xz.enc" "*.part*" "*_debug.log"
            "var" ".pnpm-store" "__pycache__" ".env"
        )

        # Argument Parsing
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --password) password="$2"; shift 2 ;;
                --split) do_split=true; shift ;;
                --mimic) do_mimic=true; shift ;;
                --copy) do_copy=true; shift ;;
                --size) chunk_size="$2"; shift 2 ;;
                --include) user_includes+=("$2"); shift 2 ;;
                --exclude) user_excludes+=("$2"); shift 2 ;;
                -*) _sa_log "$RED" "ERROR" "Unknown option: $1"; return 1 ;;
                *)
                    if [[ -z "$source_path" ]]; then
                        source_path="$1"
                        shift
                    else
                        _sa_log "$RED" "ERROR" "Multiple source paths provided."; return 1
                    fi
                    ;;
            esac
        done

        if [[ -z "$source_path" ]]; then
            _sa_log "$RED" "ERROR" "Source path required."; return 1
        fi

        if [[ ! -e "$source_path" ]]; then
            _sa_log "$RED" "ERROR" "Path not found: $source_path"; return 1
        fi

        # Password Interaction
        if [[ -z "$password" ]]; then
            echo -n "Enter encryption password: "
            read -s password
            echo
            echo -n "Verify password: "
            read -s password_verify
            echo
            if [[ "$password" != "$password_verify" ]]; then
                _sa_log "$RED" "ERROR" "Passwords do not match."; return 1
            fi
        fi

        # Setup Workspace
        local timestamp=$(date +%Y%m%d_%H%M%S)
        if [[ -d "$source_path" ]]; then
            source_path=$(cd "$source_path" && pwd)
        fi
        local basename=$(basename "$source_path")
        local work_dir="/tmp/secure_pack_${timestamp}"

        mkdir -p "$work_dir"
        _sa_log "$BLUE" "INFO" "Creating optimized working copy..."

        # Rsync Construction
        local -a rsync_args=(-aq)
        for p in "${user_includes[@]}"; do rsync_args+=(--include "$p"); done
        for p in "${user_excludes[@]}"; do rsync_args+=(--exclude "$p"); done
        for p in "${exclude_patterns[@]}"; do rsync_args+=(--exclude "$p"); done

        rsync "${rsync_args[@]}" "$source_path" "$work_dir"

        # Processing
        _sa_log "$BLUE" "INFO" "Compressing (Max) and Encrypting (Index-Shuffled)..."
        local raw_archive="${work_dir}/payload.enc"

        # Tar Anonymization Logic (Detect GNU vs BSD)
        local tar_opts=""
        if tar --version 2>&1 | grep -q "GNU"; then
            # Linux/WSL: Strip owner/group ID
            tar_opts="--owner=0 --group=0 --numeric-owner"
        else
            # MacOS/BSD: Strip owner/group ID
            tar_opts="--uid 0 --gid 0"
        fi

        # shellcheck disable=SC2086
        tar -C "$work_dir" $tar_opts -cJf - "$basename" \
        | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass "pass:$password" \
        > "$raw_archive"

        local output_name=""
        local target_file_for_clipboard=""

        if [[ "$do_mimic" == "true" ]]; then
            local mimic_file="${work_dir}/${basename}.log"
            _sa_log "$BLUE" "INFO" "Applying data mimicry (Fake Logs)..."

            cat "$raw_archive" | python3 -c "$(_sa_get_mimic_script)" pack > "$mimic_file"

            if [[ "$do_split" == "true" ]]; then
                output_name="${basename}_${timestamp}_debug.log"
                local split_prefix="${output_name}.part"
                split -b "$chunk_size" "$mimic_file" "${split_prefix}"
                _sa_log "$GREEN" "SUCCESS" "Created split logs: ${split_prefix}*"
                # For clipboard, pick the first part as a sample
                target_file_for_clipboard="${split_prefix}aa"
            else
                output_name="${basename}_${timestamp}_debug.log"
                mv "$mimic_file" "$output_name"
                _sa_log "$GREEN" "SUCCESS" "Created log file: $output_name"
                target_file_for_clipboard="$output_name"
            fi
        elif [[ "$do_split" == "true" ]]; then
            output_name="${basename}_${timestamp}.tar.xz.enc"
            local split_prefix="${output_name}.b64.part"
            cat "$raw_archive" | base64 | split -b "$chunk_size" - "${split_prefix}"
            _sa_log "$GREEN" "SUCCESS" "Created split parts: ${split_prefix}*"
            target_file_for_clipboard="${split_prefix}aa"
        else
            output_name="${basename}_${timestamp}.tar.xz.enc"
            mv "$raw_archive" "$output_name"
            _sa_log "$GREEN" "SUCCESS" "Created archive: $output_name"
            # Cannot copy binary file to clipboard reliably
            target_file_for_clipboard=""
        fi

        # Clipboard Action
        if [[ "$do_copy" == "true" ]]; then
            if [[ -f "$target_file_for_clipboard" ]]; then
                if [[ "$do_split" == "true" ]]; then
                     _sa_log "$BLUE" "INFO" "Split mode: Copying ONLY the first part to clipboard..."
                fi
                _sa_copy_to_clipboard "$target_file_for_clipboard"
            else
                _sa_log "$RED" "WARN" "Clipboard: Cannot copy binary output or file not found."
            fi
        fi

        # Cleanup
        rm -rf "$work_dir"
    )
}

# ==============================================================================
# FUNCTION: UNPACK
# ==============================================================================
secure_unpack() {
    (
        set -euo pipefail

        local RED='\033[0;31m'
        local GREEN='\033[0;32m'
        local BLUE='\033[0;34m'

        local input_pattern=""
        local password=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --password) password="$2"; shift 2 ;;
                -*) _sa_log "$RED" "ERROR" "Unknown option: $1"; return 1 ;;
                *)
                    if [[ -z "$input_pattern" ]]; then
                        input_pattern="$1"
                        shift
                    else
                        _sa_log "$RED" "ERROR" "Multiple inputs provided."; return 1
                    fi
                    ;;
            esac
        done

        if [[ -z "$input_pattern" ]]; then
            _sa_log "$RED" "ERROR" "Input file or pattern required."; return 1
        fi

        if [[ -z "$password" ]]; then
            echo -n "Enter decryption password: "
            read -s password
            echo
        fi

        _sa_log "$BLUE" "INFO" "Decrypting..."

        # Zsh Glob Expansion Handling
        # The (N) flag in zsh prevents error if no match found
        local -a file_list
        file_list=(${~input_pattern}(N))

        if [[ ${#file_list[@]} -eq 0 ]]; then
             _sa_log "$RED" "ERROR" "No files found matching: $input_pattern"; return 1
        fi

        local first_file="${file_list[1]}" # Zsh arrays start at 1

        if [[ "$first_file" == *".log"* ]]; then
            _sa_log "$BLUE" "INFO" "Mode: Mimicry Log (Unshuffling & Decrypting)"
            cat ${~input_pattern} \
            | python3 -c "$(_sa_get_mimic_script)" unpack \
            | openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:$password" \
            | tar -xJf -
        elif [[ "$input_pattern" == *"part"* ]]; then
            _sa_log "$BLUE" "INFO" "Mode: Split Archive"
            cat ${~input_pattern} \
            | base64 -d \
            | openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:$password" \
            | tar -xJf -
        else
            _sa_log "$BLUE" "INFO" "Mode: Standard Archive"
            openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "$first_file" -pass "pass:$password" \
            | tar -xJf -
        fi

        _sa_log "$GREEN" "SUCCESS" "Extraction complete."
    )
}
