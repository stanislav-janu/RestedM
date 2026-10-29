#!/bin/bash
# Builds an Apple Silicon (arm64), ad-hoc signed "build/RestedM.app".
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS=(--arch arm64)
swift build -c release "${ARCHS[@]}"
BIN_DIR=$(swift build -c release "${ARCHS[@]}" --show-bin-path)

if [ ! -f build/AppIcon.icns ]; then
    mkdir -p build/AppIcon.iconset
    swift scripts/make-icon.swift build/icon-1024.png
    for size in 16 32 128 256 512; do
        sips -z $size $size build/icon-1024.png --out "build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
        double=$((size * 2))
        sips -z $double $double build/icon-1024.png --out "build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
fi

APP="build/RestedM.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/RestedM" "$APP/Contents/MacOS/RestedM"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/RestedM"))"
