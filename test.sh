#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BINARY="${TMPDIR:-/tmp}/NetSpeedMonitorMusicReplacementTests"

trap 'rm -f "$TEST_BINARY"' EXIT

cd "$ROOT_DIR"
swiftc \
  NetSpeedMonitor/Models/ColorArchive.swift \
  NetSpeedMonitor/Models/AudioMixerItem.swift \
  NetSpeedMonitor/Models/MusicReplacement.swift \
  NetSpeedMonitor/Models/SpeedUnit.swift \
  NetSpeedMonitor/Services/BrowserAudioScripts.swift \
  NetSpeedMonitor/Helpers/ColorExtension.swift \
  NetSpeedMonitor/Helpers/SpeedFormatter.swift \
  NetSpeedMonitor/Services/MediaPlayKeyMonitor.swift \
  Tests/*.swift \
  -o "$TEST_BINARY"
"$TEST_BINARY"
