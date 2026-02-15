#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/util.sh"

: "${CONFIG_DIR:=$HOME/.config/backup}"
load_env "$CONFIG_DIR/global.env"
load_env "$CONFIG_DIR/phone_photos.env"

# turn comma separated dirs into array
csv_paths_to_array "${REMOTE_DIRS}" REMOTE_DIRS_ARR

FULL_REMOTE_DIRS=()
# prepend nas info
for p in "${REMOTE_DIRS_ARR[@]}"; do
	FULL_REMOTE_DIRS+=("$NAS_USER@$NAS_HOST:$p/")
done

rsync -avh --partial \
  -e "ssh -p $NAS_PORT" \
  "$@" \
  "${FULL_REMOTE_DIRS[@]}" \
  "$LOCAL_DIR/"
