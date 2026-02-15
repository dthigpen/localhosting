#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# set -x
########################################
# Argument Parsing
########################################

DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Running in DRY RUN mode (no changes will be made)"
fi

########################################
# Load .env Safely (No source / No eval)
########################################

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    echo ".env file not found!"
    exit 1
fi

while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading/trailing whitespace
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    # Skip blank lines
    [ -z "$line" ] && continue

    # Skip comments
    case "$line" in
        \#*) continue ;;
    esac

    # Only parse KEY=VALUE lines
    if [[ "$line" == *"="* ]]; then
        key="${line%%=*}"
        value="${line#*=}"

        # Trim whitespace
        key="$(echo "$key" | sed 's/[[:space:]]*$//')"
        value="$(echo "$value" | sed 's/^[[:space:]]*//')"

        case "$key" in
            DEVICE_NAME) DEVICE_NAME="$value" ;;
            NAS_USER) NAS_USER="$value" ;;
            NAS_HOST) NAS_HOST="$value" ;;
            NAS_PORT) NAS_PORT="$value" ;;
            NAS_BASE_PATH) NAS_BASE_PATH="$value" ;;
            DEVICE_FOLDERS) DEVICE_FOLDERS="$value" ;;
            *)
                echo "Warning: Unknown key '$key' ignored"
                ;;
        esac
    else
        echo "Malformed line in .env: $line"
        exit 1
    fi
done < "$ENV_FILE"

########################################
# Validate Required Variables
########################################

required_vars=(
    DEVICE_NAME
    NAS_USER
    NAS_HOST
    NAS_PORT
    NAS_BASE_PATH
    DEVICE_FOLDERS
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Missing required config value: $var"
        exit 1
    fi
done

########################################
# Prepare Variables
########################################

SSH_TARGET="$NAS_USER@$NAS_HOST"
DEST_BASE="$NAS_BASE_PATH/$DEVICE_NAME"

IFS=',' read -ra FOLDERS <<< "$DEVICE_FOLDERS"

########################################
# Ensure Device Base Directory Exists
########################################

echo "Ensuring device directory exists on NAS..."

if [ "$DRY_RUN" = false ]; then
    ssh -p "$NAS_PORT" "$SSH_TARGET" "mkdir -p '$DEST_BASE'"
else
    echo "[DRY RUN] Would create: $DEST_BASE"
fi

expand_path() {
    local path="$1"
    printf '%s\n' "${path/#\~/$HOME}"
}

########################################
# Rsync Each Folder
########################################

for raw_path in "${FOLDERS[@]}"; do
    # SRC="$HOME/storage/dcim/$folder"
    # trim whitespace
    echo "raw_path $raw_path"
    raw_path="$(echo "$raw_path" | xargs)"
    echo "trimmed $raw_path"
    # expand ~ if present
    SRC="$(expand_path "$raw_path")"
    DEST="$DEST_BASE/$(basename $SRC)"

    echo "Source: $SRC"
    echo "Destination: $DEST"

    if [ ! -d "$SRC" ]; then
        echo "Warning: Source folder does not exist, skipping: $SRC"
        continue
    fi

    if [ "$DRY_RUN" = false ]; then
        ssh -p "$NAS_PORT" "$SSH_TARGET" "mkdir -p '$DEST'"

        rsync -avh \
            -e "ssh -p $NAS_PORT" \
            "$SRC/" \
            "$SSH_TARGET:$DEST/"
    else
        echo "[DRY RUN] Would create: $DEST"

        rsync -avh --delete --dry-run \
            -e "ssh -p $NAS_PORT" \
            "$SRC/" \
            "$SSH_TARGET:$DEST/"
    fi
    
done

echo ""
echo "Backup process complete."
