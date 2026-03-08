#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/util.sh"

: "${CONFIG_DIR:=$HOME/.config/backup}"
load_env "$CONFIG_DIR/global.env"
load_env "$CONFIG_DIR/redundancy.env"

FULL_LOCAL_DIR="$(expand_home "${LOCAL_DIR}")"

FULL_REMOTE_DIRS=()
# prepend nas info
for p in "${REMOTE_DIRS[@]}"; do
	FULL_REMOTE_DIRS+=("$NAS_USER@$NAS_HOST:$p/")
done

rsync -avh --partial \
  -e "ssh -p $NAS_PORT" \
  "$@" \
  "${FULL_REMOTE_DIRS[@]}" \
  "$FULL_LOCAL_DIR/"
