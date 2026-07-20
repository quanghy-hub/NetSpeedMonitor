# Contributing to NetSpeedMonitor

Thank you for your interest in contributing! This document outlines the process for getting involved, building the project, and submitting changes.

## Prerequisites

To build and run NetSpeedMonitor, you need the following:

- **macOS:** 14.6 or later
- **Xcode:** 16.0 or later (with Swift 6 compatibility)

## Local Development

### Building the App

1. Clone the repository to your local machine.
2. Open `NetSpeedMonitor.xcodeproj` in Xcode.
3. Select the `NetSpeedMonitor` target.
4. Ensure your active scheme is set to run on "My Mac".
5. Click **Run** (Command + R) to build and start the application.

### Testing

Currently, the project focuses heavily on system APIs (CoreAudio, network interfaces), which are primarily tested manually. When adding features:
- Ensure the app builds without warnings.
- Manually test UI functionality in the menu bar.
- Verify system resource usage using Activity Monitor to ensure background services are efficient.

## Code Style

Consistency makes the codebase easier to maintain. We use standard Swift styling principles.

- If modifying or adding files, format them to match the surrounding code.
- If a `.clang-format` or SwiftLint configuration is present in the repository, ensure your changes adhere to those rules before submitting.

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/). This makes generating changelogs easier and keeps history readable.

Common prefixes:
- `feat:` A new feature
- `fix:` A bug fix
- `docs:` Documentation only changes
- `style:` Changes that do not affect the meaning of the code (white-space, formatting)
- `refactor:` A code change that neither fixes a bug nor adds a feature
- `chore:` Changes to the build process or auxiliary tools

Example: `feat: add support for separate upload/download units`

## Pull Request Process

1. Fork the repository and create your branch from `main`.
2. Make your changes, testing them locally.
3. Update the `CHANGELOG.md` or `README.md` if your change affects user-facing functionality.
4. Open a Pull Request, describing the changes you made, the motivation, and how they were tested.
5. Address any feedback from maintainers.

Any PR for feature enhancements, performance optimization, or compatibility improvements is highly welcomed!
