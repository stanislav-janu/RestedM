#!/bin/bash
# Builds an Apple Silicon (arm64), ad-hoc signed "build/RestedM.app".
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS=(--arch arm64)
swift build -c release "${ARCHS[@]}"
BIN_DIR=$(swift build -c release "${ARCHS[@]}" --show-bin-path)

# The icon: Icon/AppIcon.icon -> build/Assets.car + build/AppIcon.icns, rebuilt when it changed.
if [ ! -f build/Assets.car ] || [ -n "$(find Icon/AppIcon.icon -newer build/Assets.car | head -1)" ]; then
    scripts/make-icon.sh
fi

APP="build/RestedM.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/RestedM" "$APP/Contents/MacOS/RestedM"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp build/Assets.car build/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --deep --sign - "$APP"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/RestedM"))"
