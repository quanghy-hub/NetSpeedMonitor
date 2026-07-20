#!/usr/bin/env bash
set -euo pipefail

# Run the NetSpeedMonitor test suite.
# Usage: ./test.sh

echo "🧪 Running NetSpeedMonitor tests..."

xcodebuild test \
  -project NetSpeedMonitor.xcodeproj \
  -scheme NetSpeedMonitor \
  -destination 'platform=macOS' \
  -resultBundlePath build/TestResults \
  2>&1 | tail -20

echo "✅ Tests completed"
