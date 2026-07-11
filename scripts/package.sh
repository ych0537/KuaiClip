#!/bin/bash
set -e

APP_NAME="KuaiClip"
BUILD_DIR="${BUILD_DIR:-.build/debug}"
VERSION="${VERSION:-1.0.0}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
if [[ ! "${VERSION}" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
    VERSION="1.0.0"
fi
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Packaging ${APP_NAME}.app..."

# Clean up any existing app
rm -rf "${APP_DIR}"

# Create directory structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy the binary
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/"

# Generate Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>KuaiClip</string>
    <key>CFBundleExecutable</key>
    <string>KuaiClip</string>
    <key>CFBundleIdentifier</key>
    <string>com.kuaiclip.clipboard</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>KuaiClip</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "✅ Created Info.plist"

# Generate .icns from PNGs
ICONSET_DIR="Sources/KuaiClip/Resources/Assets.xcassets/AppIcon.appiconset"

# Create temporary iconset directory
TEMP_ICONSET="${RESOURCES_DIR}/AppIcon.iconset"
mkdir -p "${TEMP_ICONSET}"

# Copy and resize PNG for various sizes
# We have 256.png and 512.png - use sips to create all needed sizes

BASE_256="${ICONSET_DIR}/appicon-256.png"
BASE_512="${ICONSET_DIR}/appicon-512.png"

if [ -f "${BASE_512}" ]; then
    # Generate all required icon sizes from 512px source
    if command -v magick &>/dev/null; then
        magick "${BASE_512}" -resize 16x16     -depth 8 "PNG32:${TEMP_ICONSET}/icon_16x16.png"
        magick "${BASE_512}" -resize 32x32     -depth 8 "PNG32:${TEMP_ICONSET}/icon_16x16@2x.png"
        magick "${BASE_512}" -resize 32x32     -depth 8 "PNG32:${TEMP_ICONSET}/icon_32x32.png"
        magick "${BASE_512}" -resize 64x64     -depth 8 "PNG32:${TEMP_ICONSET}/icon_32x32@2x.png"
        magick "${BASE_512}" -resize 128x128   -depth 8 "PNG32:${TEMP_ICONSET}/icon_128x128.png"
        magick "${BASE_512}" -resize 256x256   -depth 8 "PNG32:${TEMP_ICONSET}/icon_128x128@2x.png"
        magick "${BASE_512}" -resize 256x256   -depth 8 "PNG32:${TEMP_ICONSET}/icon_256x256.png"
        magick "${BASE_512}" -resize 512x512   -depth 8 "PNG32:${TEMP_ICONSET}/icon_256x256@2x.png"
        magick "${BASE_512}" -resize 512x512   -depth 8 "PNG32:${TEMP_ICONSET}/icon_512x512.png"
        magick "${BASE_512}" -resize 1024x1024 -depth 8 "PNG32:${TEMP_ICONSET}/icon_512x512@2x.png"
    else
        sips -z 16 16     "${BASE_512}" --out "${TEMP_ICONSET}/icon_16x16.png" > /dev/null 2>&1
        sips -z 32 32     "${BASE_512}" --out "${TEMP_ICONSET}/icon_16x16@2x.png" > /dev/null 2>&1
        sips -z 32 32     "${BASE_512}" --out "${TEMP_ICONSET}/icon_32x32.png" > /dev/null 2>&1
        sips -z 64 64     "${BASE_512}" --out "${TEMP_ICONSET}/icon_32x32@2x.png" > /dev/null 2>&1
        sips -z 128 128   "${BASE_512}" --out "${TEMP_ICONSET}/icon_128x128.png" > /dev/null 2>&1
        sips -z 256 256   "${BASE_512}" --out "${TEMP_ICONSET}/icon_128x128@2x.png" > /dev/null 2>&1
        sips -z 256 256   "${BASE_512}" --out "${TEMP_ICONSET}/icon_256x256.png" > /dev/null 2>&1
        sips -z 512 512   "${BASE_512}" --out "${TEMP_ICONSET}/icon_256x256@2x.png" > /dev/null 2>&1
        sips -z 512 512   "${BASE_512}" --out "${TEMP_ICONSET}/icon_512x512.png" > /dev/null 2>&1
        sips -z 1024 1024 "${BASE_512}" --out "${TEMP_ICONSET}/icon_512x512@2x.png" > /dev/null 2>&1
    fi

    # Use iconutil to create .icns. Some toolchains reject generated iconsets;
    # fall back to sips so packaging still produces a usable app icon.
    if ! iconutil -c icns "${TEMP_ICONSET}" -o "${RESOURCES_DIR}/AppIcon.icns"; then
        sips -s format icns "${BASE_512}" --out "${RESOURCES_DIR}/AppIcon.icns" > /dev/null 2>&1
    fi
    rm -rf "${TEMP_ICONSET}"
    echo "✅ Created AppIcon.icns"
elif [ -f "${BASE_256}" ]; then
    # Fallback: copy 256 as icns (single size)
    sips -z 256 256   "${BASE_256}" --out "${RESOURCES_DIR}/AppIcon.icns" > /dev/null 2>&1
    echo "⚠️  Created basic AppIcon.icns from 256px"
else
    echo "⚠️  No icon found, skipping"
fi

# Remove extended attributes
xattr -cr "${APP_DIR}" 2>/dev/null || true

# Make binary executable
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Sign for distribution when a Developer ID identity is supplied. Keep ad-hoc
# signing as the default for local development and pull-request builds.
if [ "${SIGN_IDENTITY}" = "-" ]; then
    codesign --force --deep --sign - "${APP_DIR}"
    echo "✅ Ad-hoc signed"
else
    codesign \
        --force \
        --deep \
        --options runtime \
        --timestamp \
        --sign "${SIGN_IDENTITY}" \
        "${APP_DIR}"
    codesign --verify --deep --strict --verbose=2 "${APP_DIR}"
    echo "✅ Developer ID signed and verified"
fi

echo ""
echo "🎉 ${APP_NAME}.app packaged successfully!"
echo "   Location: $(pwd)/${APP_DIR}"
ls -la "${APP_DIR}/Contents/MacOS/${APP_NAME}"
