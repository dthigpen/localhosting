#!/usr/bin/env bash

msg() { echo >&2 -e "$@"; }

load_env() {
    local file="$1"

    [[ -f "$file" ]] || {
        echo "Config file not found: $file" >&2
        exit 1
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        local key="${line%%=*}"
        local value="${line#*=}"

        # Trim whitespace
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        # Assign in current shell
        printf -v "$key" '%s' "$value"

        # Optional: export if you want child processes to see it
        # export "$key"
    done < "$file"
}

# Usage:
#   csv_to_array "a,b,c" my_array
#   echo "${my_array[@]}"
csv_to_array() {
    local input="$1"
    local -n out_array="$2"   # nameref to caller's array

    local IFS=','
    read -r -a out_array <<< "$input"

    # Trim whitespace on each element
    for i in "${!out_array[@]}"; do
        out_array[$i]="${out_array[$i]#"${out_array[$i]%%[![:space:]]*}"}"
        out_array[$i]="${out_array[$i]%"${out_array[$i]##*[![:space:]]}"}"
    done
}

expand_home_in_array() {
    local -n arr="$1"

    for i in "${!arr[@]}"; do
        arr[$i]="${arr[$i]/#\~/$HOME}"
    done
}

csv_paths_to_array() {
    local input="$1"
    local -n out="$2"

    csv_to_array "$input" out
    expand_home_in_array out
}
