#!/usr/bin/env bash
set -euo pipefail

die() {
    echo "Error: $*" >&2
    exit 1
}

usage() {
    echo "Usage: notify -t recipient -s subject [-b body]"
    exit 1
}

TO=""
SUBJECT=""
BODY=""

while getopts ":t:s:b:" opt; do
    case "$opt" in
        t) TO="$OPTARG" ;;
        s) SUBJECT="$OPTARG" ;;
        b) BODY="$OPTARG" ;;
        *) usage ;;
    esac
done

[[ -n "$TO" ]] || usage
[[ -n "$SUBJECT" ]] || usage

# If body not provided via -b, read from stdin
if [[ -z "$BODY" ]]; then
    if ! [ -t 0 ]; then
        BODY="$(cat)"
    else
        die "Body required via -b or stdin"
    fi
fi

HOSTNAME="$(hostname)"

{
    echo "To: $TO"
    echo "Subject: [$HOSTNAME] $SUBJECT"
    echo ""
    echo -e "$BODY"
} | msmtp "$TO"
