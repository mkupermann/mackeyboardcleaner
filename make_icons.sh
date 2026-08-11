#!/bin/bash
# Regenerate app icon (.icns) and README logos from the SVG sources in assets/.
# Requires: rsvg-convert (brew install librsvg) and iconutil (macOS).

set -e
cd "$(dirname "$0")"

ICONSET="$(mktemp -d)/KeyboardCleaner.iconset"
mkdir -p "$ICONSET"

# Small sizes use the simplified variant, large sizes the detailed one
rsvg-convert -w 16   -h 16   assets/icon-small.svg > "$ICONSET/icon_16x16.png"
rsvg-convert -w 32   -h 32   assets/icon-small.svg > "$ICONSET/icon_16x16@2x.png"
rsvg-convert -w 32   -h 32   assets/icon-small.svg > "$ICONSET/icon_32x32.png"
rsvg-convert -w 64   -h 64   assets/icon-small.svg > "$ICONSET/icon_32x32@2x.png"
rsvg-convert -w 128  -h 128  assets/icon.svg       > "$ICONSET/icon_128x128.png"
rsvg-convert -w 256  -h 256  assets/icon.svg       > "$ICONSET/icon_128x128@2x.png"
rsvg-convert -w 256  -h 256  assets/icon.svg       > "$ICONSET/icon_256x256.png"
rsvg-convert -w 512  -h 512  assets/icon.svg       > "$ICONSET/icon_256x256@2x.png"
rsvg-convert -w 512  -h 512  assets/icon.svg       > "$ICONSET/icon_512x512.png"
rsvg-convert -w 1024 -h 1024 assets/icon.svg       > "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o assets/KeyboardCleaner.icns

# README logos (light/dark)
rsvg-convert -w 820 assets/logo-light.svg > assets/logo-light.png
rsvg-convert -w 820 assets/logo-dark.svg  > assets/logo-dark.png

# README cat illustration (FILLBG = page background so the cat occludes the deck lines)
sed 's/FILLBG/#FFFFFF/' assets/cat-illustration.svg | rsvg-convert -w 1000 > assets/cat-light.png
sed 's/FILLBG/#0D1117/' assets/cat-illustration.svg | rsvg-convert -w 1000 > assets/cat-dark.png

# DMG background (multi-resolution TIFF so Finder renders it crisp on Retina)
DMGBG="$(mktemp -d)"
rsvg-convert -w 660  assets/dmg-background.svg > "$DMGBG/bg.png"
rsvg-convert -w 1320 assets/dmg-background.svg > "$DMGBG/bg@2x.png"
tiffutil -cathidpicheck "$DMGBG/bg.png" "$DMGBG/bg@2x.png" -out assets/dmg-background.tiff
rm -rf "$DMGBG"

rm -rf "$(dirname "$ICONSET")"
echo "Generated assets/KeyboardCleaner.icns, assets/logo-light.png, assets/logo-dark.png"
