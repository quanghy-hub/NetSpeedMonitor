#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BINARY="${TMPDIR:-/tmp}/NetSpeedMonitorMusicReplacementTests"

trap 'rm -f "$TEST_BINARY"' EXIT

cd "$ROOT_DIR"
swiftc \
  NetSpeedMonitor/Models/ColorArchive.swift \
  NetSpeedMonitor/Models/MusicReplacement.swift \
  NetSpeedMonitor/Helpers/ColorExtension.swift \
  NetSpeedMonitor/Services/MediaPlayKeyMonitor.swift \
  Tests/MusicReplacementTests.swift \
  -o "$TEST_BINARY"
"$TEST_BINARY"
