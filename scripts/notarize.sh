#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-KuaiClip}"
APP_DIR="${APP_DIR:-${APP_NAME}.app}"
KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-KuaiClip-notary}"
NOTARY_KEYCHAIN="${NOTARY_KEYCHAIN:-}"
ZIP_PATH="${ZIP_PATH:-${APP_NAME}-notarization.zip}"

if [ ! -d "${APP_DIR}" ]; then
    echo "Error: ${APP_DIR} does not exist" >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "${APP_DIR}"

rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_DIR}" "${ZIP_PATH}"

NOTARY_AUTH=(--keychain-profile "${KEYCHAIN_PROFILE}")
if [ -n "${NOTARY_KEYCHAIN}" ]; then
    NOTARY_AUTH+=(--keychain "${NOTARY_KEYCHAIN}")
fi

xcrun notarytool submit "${ZIP_PATH}" "${NOTARY_AUTH[@]}" --wait

xcrun stapler staple "${APP_DIR}"
xcrun stapler validate "${APP_DIR}"
spctl --assess --type execute --verbose=4 "${APP_DIR}"

echo "✅ ${APP_DIR} notarized, stapled, and accepted by Gatekeeper"
