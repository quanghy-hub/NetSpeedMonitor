# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Comprehensive architecture and contributing documentation.
- Project guidelines via `CONTRIBUTING.md`.

## [1.8.0]
### Added
- Audio mixer to independently adjust the volume of audible apps and browser tabs.
- Integrated Apple Music / iTunes blocker service, allowing users to automatically launch a replacement app or website.
### Changed
- Complete UI rewrite using SwiftUI, offering a modern, declarative menu bar experience.
- Minimum system version increased to macOS 14.6.
- Refactored core services using Swift `actor` to improve concurrency and thread safety.
- Improved app startup speed through the new `AutoLaunchManager`.

## [1.7.0]
### Added
- Customizable colors for CPU, RAM, and Battery indicators.
- Selectable unit options for data transfer speeds.
### Changed
- Enhanced `sysctl` logic for more accurate CPU and RAM reporting.

## [1.0.0]
### Added
- Initial release.
- Menu bar integration with upload/download speeds.
- Simple toggle indicators for CPU, RAM, and battery state.
