#!/usr/bin/env bash

set -euo pipefail

ENV_FILE=".env"

load_env() {
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        key="${line%%=*}"
        value="${line#*=}"

        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs)"

        export "$key=$value"
    done < "$1"
}

expand_path() {
    printf '%s\n' "${1/#\~/$HOME}"
}

# Load config
load_env "$ENV_FILE"

LOCAL_BACKUP_DIR="$(expand_path "$LOCAL_BACKUP_DIR")"

# Build rsync flags
RSYNC_FLAGS="-avh"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    RSYNC_FLAGS="$RSYNC_FLAGS --dry-run"
    echo "Running in DRY RUN mode"
fi

echo "Backing up NAS → Local"
echo "Remote: $NAS_USER@$NAS_HOST:$REMOTE_BACKUP_DIR/"
echo "Local:  $LOCAL_BACKUP_DIR/"
echo

mkdir -p "$LOCAL_BACKUP_DIR"

rsync $RSYNC_FLAGS \
    -e "ssh -p $NAS_PORT" \
    "$NAS_USER@$NAS_HOST:$REMOTE_BACKUP_DIR/" \
    "$LOCAL_BACKUP_DIR/"

echo
echo "Backup complete."
