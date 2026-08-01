#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

blocked_pattern='\.(p12|p8|cer|csr|mobileprovision|provisionprofile|keychain|keychain-db|xcarchive|storekit)$|(^|/)\.env($|\.)|(^|/)Config/Private/'

check_paths() {
    local label="$1"
    local paths="$2"
    local matches
    matches="$(printf '%s\n' "$paths" | grep -E "$blocked_pattern" || true)"
    if [ -n "$matches" ]; then
        echo "ERROR: ${label} contains private signing, purchase, or build files:" >&2
        echo "$matches" >&2
        exit 1
    fi
}

tracked="$(git ls-files)"
staged="$(git diff --cached --name-only --diff-filter=ACMR)"

check_paths "tracked files" "$tracked"
check_paths "staged changes" "$staged"

scan_output="$(mktemp -t kuaiclip-secret-scan.XXXXXX)"
trap 'rm -f "$scan_output"' EXIT
if git grep -I -n -E 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|BEGIN CERTIFICATE' -- . \
    ':(exclude)docs/*' ':(exclude)Readme*' >"$scan_output" 2>/dev/null; then
    echo "ERROR: A tracked file appears to contain a private key or certificate:" >&2
    cat "$scan_output" >&2
    exit 1
fi

echo "Release safety check passed"
