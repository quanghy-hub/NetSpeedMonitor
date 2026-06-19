#!/usr/bin/env bash
set -euo pipefail

APP_NAME="NetSpeedMonitor"
BUNDLE_ID="com.elegracer.NetSpeedMonitor"
MIN_SYSTEM_VERSION="14.0"
BUNDLE_VERSION="1"
BUNDLE_SHORT_VERSION="1.0.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
DEFAULT_CODESIGN_IDENTITY="TranslatZ Local Code Signing"
CODESIGN_IDENTITY="${NETSPEED_CODESIGN_IDENTITY:-$DEFAULT_CODESIGN_IDENTITY}"

migrate_music_blocker_preferences() {
  local legacy_preferences="$HOME/Library/Preferences/$BUNDLE_ID.plist"
  local enabled replacement

  [[ -f "$legacy_preferences" ]] || return

  if ! defaults read "$BUNDLE_ID" XMusicEnabled >/dev/null 2>&1; then
    enabled="$(plutil -extract XMusicEnabled raw -o - "$legacy_preferences" 2>/dev/null || true)"
    case "$enabled" in
      true|1) defaults write "$BUNDLE_ID" XMusicEnabled -bool true ;;
      false|0) defaults write "$BUNDLE_ID" XMusicEnabled -bool false ;;
    esac
  fi

  if ! defaults read "$BUNDLE_ID" XMusicReplacement >/dev/null 2>&1; then
    replacement="$(plutil -extract XMusicReplacement raw -o - "$legacy_preferences" 2>/dev/null || true)"
    if [[ -n "$replacement" ]]; then
      defaults write "$BUNDLE_ID" XMusicReplacement -string "$replacement"
    fi
  fi
}

cd "$ROOT_DIR"

echo "=== Building NetSpeedMonitor ==="

# 1. Compile Swift sources
echo "Compiling Swift files..."
mkdir -p "$DIST_DIR"
swiftc -o "$DIST_DIR/NetSpeedMonitor_bin" \
  $(find NetSpeedMonitor -name "*.swift")


# 2. Package into .app bundle
echo "Structuring $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"

mv "$DIST_DIR/NetSpeedMonitor_bin" "$APP_BINARY"
chmod +x "$APP_BINARY"

# Convert PNG to high-res ICNS App Icon if exists
if [ -f "NetSpeedMonitor/icon.png" ]; then
  echo "Generating AppIcon.icns..."
  ICONSET="$APP_RESOURCES/AppIcon.iconset"
  mkdir -p "$ICONSET"
  sips -z 16 16     NetSpeedMonitor/icon.png --out "$ICONSET/icon_16x16.png" >/dev/null 2>&1
  sips -z 32 32     NetSpeedMonitor/icon.png --out "$ICONSET/icon_16x16@2x.png" >/dev/null 2>&1
  sips -z 32 32     NetSpeedMonitor/icon.png --out "$ICONSET/icon_32x32.png" >/dev/null 2>&1
  sips -z 64 64     NetSpeedMonitor/icon.png --out "$ICONSET/icon_32x32@2x.png" >/dev/null 2>&1
  sips -z 128 128   NetSpeedMonitor/icon.png --out "$ICONSET/icon_128x128.png" >/dev/null 2>&1
  sips -z 256 256   NetSpeedMonitor/icon.png --out "$ICONSET/icon_128x128@2x.png" >/dev/null 2>&1
  sips -z 256 256   NetSpeedMonitor/icon.png --out "$ICONSET/icon_256x256.png" >/dev/null 2>&1
  sips -z 512 512   NetSpeedMonitor/icon.png --out "$ICONSET/icon_256x256@2x.png" >/dev/null 2>&1
  sips -z 512 512   NetSpeedMonitor/icon.png --out "$ICONSET/icon_512x512.png" >/dev/null 2>&1
  sips -z 1024 1024 NetSpeedMonitor/icon.png --out "$ICONSET/icon_512x512@2x.png" >/dev/null 2>&1
  iconutil -c icns "$ICONSET" -o "$APP_RESOURCES/AppIcon.icns"
  rm -rf "$ICONSET"
fi

# 3. Create Info.plist
echo "Creating Info.plist..."
cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleShortVersionString</key>
  <string>$BUNDLE_SHORT_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSAudioCaptureUsageDescription</key>
  <string>NetSpeedMonitor captures app audio locally only to adjust per-app volume. Audio is not recorded or sent anywhere.</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

# 4. Codesign
echo "Signing the App Bundle..."
if security find-identity -v -p codesigning | grep -Fq "\"$CODESIGN_IDENTITY\""; then
  SIGN_VALUE="$CODESIGN_IDENTITY"
  echo "Using signing identity: $CODESIGN_IDENTITY"
else
  SIGN_VALUE="-"
  echo "Signing identity not found, falling back to ad-hoc signing."
fi

if [ -f "NetSpeedMonitor/NetSpeedMonitor.entitlements" ]; then
  /usr/bin/codesign --force --sign "$SIGN_VALUE" --entitlements NetSpeedMonitor/NetSpeedMonitor.entitlements "$APP_BUNDLE"
else
  /usr/bin/codesign --force --sign "$SIGN_VALUE" "$APP_BUNDLE"
fi

echo "=== Build Successful! ==="
echo "App is saved at: $APP_BUNDLE"
echo "Launching app..."

migrate_music_blocker_preferences

# Kill running instance if any
pkill -x "$APP_NAME" || true
sleep 0.5
open "$APP_BUNDLE"
echo "Launched $APP_NAME.app successfully!"
