# Xcode & Project Context for Coding Agents

## Project Details
- **Project File**: `parallexWall.xcodeproj`
- **Primary Scheme**: `parallexWall`
- **Target**: `parallexWall` (macOS Application)
- **Deployment Target**: macOS 12.0+
- **Architectures**: Apple Silicon (arm64) / Universal

## Architecture & Hardware Integrations
- **Core Motion & Sensors**:
  - `AppleSPUHIDDevice` via `IOKit`: Reads raw Mac accelerometer hardware telemetry.
  - `CMHeadphoneMotionManager` via `CoreMotion`: Spatial head tracking via connected AirPods Pro/Max.
- **Rendering**:
  - Multi-layer SwiftUI parallax engine with depth-based offset scaling.
  - Custom `NSWindow` desktop wallpaper backing window (`WallpaperWindow`).

## Build & Validation
- **Xcode Tools**: Connected via `xcrun mcpbridge` (Xcode MCP Server).
