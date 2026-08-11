#!/bin/bash
# Build a signed, notarized, stapled release DMG of KeyboardCleaner.
#
# Requires:
#   - A "Developer ID Application" identity in the keychain
#   - create-dmg (brew install create-dmg)
#   - Notarization credentials, one of:
#       NOTARY_PROFILE=<profile>                      (xcrun notarytool store-credentials)
#       APPLE_ID + APPLE_TEAM_ID + NOTARY_PASSWORD    (app-specific password)
#
# Output: dist/KeyboardCleaner-<version>.dmg

set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="KeyboardCleaner"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
DIST="dist"
STAGING="$DIST/staging"
APP_BUNDLE="$STAGING/$APP_NAME.app"
DMG="$DIST/$APP_NAME-$VERSION.dmg"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application}"

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "ERROR: no Developer ID Application identity in the keychain" >&2
    exit 1
fi

rm -rf "$DIST"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo "==> Building universal binary ($VERSION)"
swiftc KeyboardCleaner.swift -O -target arm64-apple-macos12.0 -o "$DIST/$APP_NAME-arm64" \
    -framework Cocoa -framework ApplicationServices -framework Foundation
swiftc KeyboardCleaner.swift -O -target x86_64-apple-macos12.0 -o "$DIST/$APP_NAME-x86_64" \
    -framework Cocoa -framework ApplicationServices -framework Foundation
lipo -create "$DIST/$APP_NAME-arm64" "$DIST/$APP_NAME-x86_64" \
    -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
rm "$DIST/$APP_NAME-arm64" "$DIST/$APP_NAME-x86_64"
lipo -info "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cp Info.plist "$APP_BUNDLE/Contents/"
cp assets/KeyboardCleaner.icns "$APP_BUNDLE/Contents/Resources/"

echo "==> Signing (Developer ID, hardened runtime)"
codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
codesign --verify --strict --verbose=2 "$APP_BUNDLE"

notarize() {
    if [ -n "${NOTARY_PROFILE:-}" ]; then
        xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait
    elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${NOTARY_PASSWORD:-}" ]; then
        xcrun notarytool submit "$1" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" \
            --password "$NOTARY_PASSWORD" --wait
    else
        echo "ERROR: no notarization credentials (set NOTARY_PROFILE or APPLE_ID/APPLE_TEAM_ID/NOTARY_PASSWORD)" >&2
        exit 1
    fi
}

echo "==> Notarizing app"
ditto -c -k --keepParent "$APP_BUNDLE" "$DIST/$APP_NAME.zip"
notarize "$DIST/$APP_NAME.zip"
rm "$DIST/$APP_NAME.zip"
xcrun stapler staple "$APP_BUNDLE"

echo "==> Building DMG"
# create-dmg drives Finder via AppleScript, which occasionally flakes on CI — retry.
for attempt in 1 2 3; do
    rm -f "$DMG"
    if create-dmg \
        --volname "$APP_NAME" \
        --volicon assets/KeyboardCleaner.icns \
        --background assets/dmg-background.tiff \
        --window-size 660 420 \
        --icon-size 128 \
        --icon "$APP_NAME.app" 165 200 \
        --app-drop-link 495 200 \
        --hide-extension "$APP_NAME.app" \
        --no-internet-enable \
        "$DMG" "$STAGING"; then
        break
    fi
    echo "create-dmg attempt $attempt failed, retrying..."
    sleep 5
done
[ -f "$DMG" ]

codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"

echo "==> Notarizing DMG"
notarize "$DMG"
xcrun stapler staple "$DMG"

echo "==> Gatekeeper verification"
spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"

echo ""
echo "✓ Release ready: $DMG"
