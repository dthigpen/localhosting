#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/util.sh"

: "${CONFIG_DIR:=$HOME/.config/backup}"
load_env "$CONFIG_DIR/global.env"
load_env "$CONFIG_DIR/phone_photos.env"

# turn comma separated LOCAL_DIRS into array
csv_paths_to_array "${LOCAL_DIRS}" LOCAL_DIRS_ARR

rsync -avh --partial \
  -e "ssh -p $NAS_PORT" \
  "$@" \
  "${LOCAL_DIRS_ARR[@]}" \
  "$NAS_USER@$NAS_HOST:$REMOTE_DIR/"
