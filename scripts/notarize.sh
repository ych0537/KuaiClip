#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-KuaiClip}"
OUTPUT_DIR="${OUTPUT_DIR:-release}"
APP_DIR="${APP_DIR:-${OUTPUT_DIR}/${APP_NAME}.app}"
PKG_PATH="${PKG_PATH:-${OUTPUT_DIR}/${APP_NAME}.pkg}"
RELEASE_ZIP_PATH="${RELEASE_ZIP_PATH:-${OUTPUT_DIR}/${APP_NAME}.app.zip}"
KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-KuaiClip-notary}"
NOTARY_KEYCHAIN="${NOTARY_KEYCHAIN:-}"
NOTARIZATION_ZIP_PATH="${NOTARIZATION_ZIP_PATH:-${OUTPUT_DIR}/${APP_NAME}-notarization.zip}"

if [ ! -d "${APP_DIR}" ]; then
    echo "Error: ${APP_DIR} does not exist" >&2
    exit 1
fi
if [ ! -f "${PKG_PATH}" ]; then
    echo "Error: ${PKG_PATH} does not exist" >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "${APP_DIR}"
pkgutil --check-signature "${PKG_PATH}"

rm -f "${NOTARIZATION_ZIP_PATH}"
ditto -c -k --keepParent --norsrc "${APP_DIR}" "${NOTARIZATION_ZIP_PATH}"

NOTARY_AUTH=(--keychain-profile "${KEYCHAIN_PROFILE}")
if [ -n "${NOTARY_KEYCHAIN}" ]; then
    NOTARY_AUTH+=(--keychain "${NOTARY_KEYCHAIN}")
fi

xcrun notarytool submit "${NOTARIZATION_ZIP_PATH}" "${NOTARY_AUTH[@]}" --wait

xcrun stapler staple "${APP_DIR}"
xcrun stapler validate "${APP_DIR}"
spctl --assess --type execute --verbose=4 "${APP_DIR}"

rm -f "${RELEASE_ZIP_PATH}"
ditto -c -k --keepParent --norsrc "${APP_DIR}" "${RELEASE_ZIP_PATH}"

xcrun notarytool submit "${PKG_PATH}" "${NOTARY_AUTH[@]}" --wait
xcrun stapler staple "${PKG_PATH}"
xcrun stapler validate "${PKG_PATH}"
spctl --assess --type install --verbose=4 "${PKG_PATH}"

rm -f "${NOTARIZATION_ZIP_PATH}"
echo "✅ App ZIP and PKG notarized, stapled, and accepted by Gatekeeper"
