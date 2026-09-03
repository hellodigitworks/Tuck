#!/bin/zsh
# Builds Tuck.app from source. Run: zsh scripts/make-app.sh [--install]
set -e
cd "$(dirname "$0")/.."

APP_NAME="Tuck"
BUNDLE_ID="com.hdw.tuck"
VERSION="1.0.0"
BUILD_NUMBER="1"

# Build outside the Google Drive folder: Drive sync corrupts incremental
# build state (files appear where directories should be).
SCRATCH="$HOME/Library/Caches/tuck-build"
swift build -c release --scratch-path "$SCRATCH"

APP="build/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$SCRATCH/release/Tuck" "$APP/Contents/MacOS/Tuck"

if [ ! -f icons/AppIcon.icns ]; then
  swift scripts/make-icon.swift
fi
cp icons/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>Tuck</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Ad-hoc signature: enough for a locally built app to run and remember its settings.
codesign --force --deep --sign - "$APP"
echo "Built: $APP"

# Install to /Applications so it behaves like a real app and can start at login.
if [ "${1:-}" = "--install" ]; then
  pkill -x Tuck 2>/dev/null || true
  sleep 1
  rm -rf "/Applications/$APP_NAME.app"
  cp -R "$APP" "/Applications/$APP_NAME.app"
  echo "Installed: /Applications/$APP_NAME.app"
fi
