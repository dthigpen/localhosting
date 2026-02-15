# notify.sh

A tiny, dependency-light email notification script built on top of `msmtp`.

This tool does one thing:

Format a simple email message and hand it off to `msmtp`.

It does NOT:
- Implement SMTP
- Handle TLS
- Manage passwords
- Talk directly to Gmail

That responsibility belongs to `msmtp`, which is exactly what it’s designed for.

This keeps the script small, secure, and easy to reason about.

---

## Overview

The architecture is intentionally simple:

Your Script → msmtp → Gmail SMTP → Recipient

The script formats the message.
`msmtp` handles authentication, TLS, and delivery.

---

## Dependencies

You only need:

- bash (modern version recommended)
- msmtp

### Install msmtp

Debian/Ubuntu:

|||
sudo apt install msmtp
|||

Fedora:

|||
sudo dnf install msmtp
|||

macOS (Homebrew):

|||
brew install msmtp
|||

---

## Step 1 — Create a Dedicated Gmail Account (Recommended)

For best practice:

- Create a separate Gmail account for notifications
- Enable 2-Step Verification
- Generate an App Password (NOT your real password)

This isolates your alerts from your primary email account.

---

## Step 2 — Generate a Gmail App Password

1. Enable 2FA on the Gmail account.
2. Go to Google Account → Security → App passwords.
3. Create a new app password.
4. Save it securely.

You will store this in a file — never inside your script.

---

## Step 3 — Create Password File

Example:

|||
mkdir -p ~/.secrets
echo "your_app_password_here" > ~/.secrets/gmail_app_password
chmod 600 ~/.secrets/gmail_app_password
|||

File permissions must be 600.

---

## Step 4 — Create msmtp Configuration

Create:

|||
~/.config/msmtp/config
|||

Contents:

|||
defaults
auth           on
tls            on
tls_starttls   on
host           smtp.gmail.com
port           587
user           alerts@example.com
passwordeval   "cat ~/.secrets/gmail_app_password"

account default
from alerts@example.com
|||

Then secure it:

|||
chmod 600 ~/.config/msmtp/config
|||

That’s it. `msmtp` is now fully configured.

You can test it manually:

|||
echo -e "Subject: Test\n\nHello world" | msmtp you@example.com
|||

If that works, the system is ready.

---

## Step 5 — The notify.sh Script

Create `notify.sh`:

|||
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
    echo "$BODY"
} | msmtp "$TO"
|||

Make it executable:

|||
chmod +x notify.sh
|||

---

## Usage Examples

### Simple Email

|||
./notify.sh -t you@example.com -s "Backup Complete" -b "Everything succeeded."
|||

---

### Pipe Command Output

|||
backup.sh | ./notify.sh -t you@example.com -s "Backup Log"
|||

---

### Send Log File on Failure

|||
if ! backup.sh >log.txt 2>&1; then
    ./notify.sh -t you@example.com -s "Backup Failed" < log.txt
fi
|||

---

## Security Notes

- Never store your app password in the script.
- Never commit your msmtp config to version control.
- Keep:
  - ~/.config/msmtp/config
  - ~/.secrets/gmail_app_password
  at 600 permissions.

For additional containment:

- Use a dedicated Gmail account for alerts only.
- Generate separate app passwords for different systems if desired.

---

## Why This Design Is Good

This setup:

- Keeps the script under 40 lines
- Eliminates SMTP complexity
- Eliminates TLS handling code
- Eliminates credential parsing logic
- Uses standard Unix tools
- Minimizes attack surface
- Is easy to debug

The script formats mail.
`msmtp` delivers mail.
Each tool does one thing well.

---

## Philosophy

Small tools.
Clear boundaries.
No unnecessary abstraction.
Let the right layer handle the right responsibility.

That’s the Unix way.
