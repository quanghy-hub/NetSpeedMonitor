#!/usr/bin/env bash
set -euo pipefail

# Build a universal (arm64 + x86_64) NetSpeedMonitor.app bundle.
# Usage: ./build.sh [--no-launch]

SCHEME="NetSpeedMonitor"
CONFIGURATION="Release"
BUILD_DIR="build"
DIST_DIR="dist"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "🔨 Building $SCHEME (universal)..."

xcodebuild -project NetSpeedMonitor.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  -arch arm64 -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build 2>&1 | tail -5

APP_PATH=$(find "$BUILD_DIR" -name "NetSpeedMonitor.app" -type d | head -1)

if [[ -z "$APP_PATH" ]]; then
  echo "❌ Build failed: NetSpeedMonitor.app not found in $BUILD_DIR"
  exit 1
fi

rm -rf "$DIST_DIR/NetSpeedMonitor.app"
cp -R "$APP_PATH" "$DIST_DIR/"

echo "✅ Built: $DIST_DIR/NetSpeedMonitor.app"

if [[ "${1:-}" != "--no-launch" ]]; then
  open "$DIST_DIR/NetSpeedMonitor.app"
fi
