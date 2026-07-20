# NetSpeedMonitor Architecture

This document provides a high-level overview of the NetSpeedMonitor architecture, outlining how its core components interact to provide system stats and audio control through a macOS menu bar UI.

## App Lifecycle

```text
macOS -> NetSpeedMonitorApp (@main)
           |
           v
    Initializes Services
           |
           v
  Instantiates MenuBarState
           |
           v
  Renders MenuBarExtra (SwiftUI)
           |
           v
  Event Loop (Timer & User Actions)
```

## Layer Architecture

The application follows a clear separation of concerns, structured primarily into Views, State Management, Services, and Models.

```text
+-----------------------+      +-----------------------+
|        Views          |      |      Models           |
|  (MenuContentView)    |      | (AudioMixerItem,      |
+-----------------------+      |  NetTrafficStat)      |
           |                   +-----------------------+
           v                              ^
+-----------------------+                 |
|   MenuBarState        |-----------------+
|  (StateObject)        |                 
+-----------------------+                 
           |                              
           v                              
+-----------------------+                 
|      Services         |                 
| (SystemStatsMonitor,  |                 
|  AudioSessionCatalog) |                 
+-----------------------+                 
```

## Concurrency Model

Concurrency in NetSpeedMonitor relies heavily on Swift's modern concurrency features, balancing UI responsiveness with efficient background processing.

- **`@MainActor`**: The `MenuBarState` and UI Views are bound to the MainActor. This ensures that all UI updates, including the menu bar icon refresh and popover data rendering, are safely executed on the main thread.
- **`actor`**: Core services like `SystemStatsMonitor`, `NetTrafficStatReceiver`, and `AudioSessionCatalog` are implemented as Swift `actor`s. This provides thread-safe access to underlying system resources (like `sysctl`, `getifaddrs`, and CoreAudio APIs) while executing in the background, preventing main thread stalls.
- **`DispatchQueue`**: A `DispatchSourceTimer` drives the primary update loop in `MenuBarState`, pushing scheduled updates across actor boundaries.

## Data Flow

1. **Timer Trigger**: `MenuBarState` fires a timer based on the user-configured interval (e.g., 1s, 2s).
2. **Service Request**: The timer callback asynchronously calls the respective service actors (e.g., `NetTrafficStatReceiver.getSpeed`, `SystemStatsMonitor.getStats`).
3. **Hardware / System Call**: The actors perform low-level calls (`sysctl`, `ifaddrs`, CoreAudio) safely isolated from the main thread.
4. **State Update**: The returned data is routed back to the MainActor to update `@Published` properties on `MenuBarState`.
5. **View Re-render**: SwiftUI automatically re-renders the `MenuBarExtra` icon and `MenuContentView` using the updated published properties.

## Key Design Decisions

- **LSUIElement App**: The app runs purely in the menu bar with no dock icon, minimizing user intrusion while offering quick access.
- **`nettop` Avoidance**: Per-process network traffic is avoided because parsing `nettop` output is computationally expensive. Interface-level statistics (`getifaddrs`) are used instead for battery-friendly network speed rendering.
- **CoreAudio Process Taps**: The volume mixer leverages `NSAudioCaptureUsageDescription` and local process taps (macOS 14.4+) rather than system-wide HAL plugins to adjust volume per app.
- **Declarative SwiftUI**: The migration to SwiftUI in v1.8 simplifies view state management over the traditional AppKit `NSStatusItem` and `NSMenu` imperative approach.
