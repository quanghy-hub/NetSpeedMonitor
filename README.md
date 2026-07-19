# NetSpeedMonitor

NetSpeedMonitor is a macOS menu bar app for quick network, system, and audio controls.

The menu bar icon shows upload/download speed and optional CPU, RAM, and battery usage bars. The menu also includes update interval settings, start-at-login control, an audio mixer for audible apps/browser tabs, and an optional Apple Music/iTunes blocker with replacement launch support.

Use at your own risk.

# Functions

1. Start at login.
2. Show upload/download speed in the menu bar.
3. Toggle CPU, RAM, and battery indicators with persistent colors.
4. Set update intervals: 1s, 2s, 5s, 10s, 30s.
5. Adjust volume for audible apps and supported Safari/Chrome media tabs.
6. Block Apple Music/iTunes and optionally launch a replacement app or website.
7. Open Activity Monitor when abnormal network traffic needs investigation.

# Note

Per-process network traffic monitoring usually requires `nettop`, which is too CPU-heavy to keep running in the background. This app keeps the menu-bar network display focused on interface-level traffic.

The UI is built with SwiftUI as an `LSUIElement` menu-bar app. The Xcode project includes `NSAudioCaptureUsageDescription` because the per-app audio mixer uses local CoreAudio process taps.

To build the app:
Open `NetSpeedMonitor.xcodeproj` in Xcode, select the `NetSpeedMonitor` target, and click Build or Run.

Any PR for feature enhancement or compatibility improvement is welcome.

# Screenshot

![](./screenshot.png)
