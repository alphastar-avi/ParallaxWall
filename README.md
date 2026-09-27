# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using built-in Apple Silicon accelerometer tracking and AirPods spatial head motion detection. As you move your laptop or tilt your head, your desktop background smoothly reacts and pans in real time, creating an immersive 3D depth experience.

<img width="1279" height="934" alt="ParallaxHome" src="https://github.com/user-attachments/assets/c624649b-2f5a-4c01-9e34-49eede2d8aeb" />

<img width="1279" height="934" alt="ParallaxGallary" src="https://github.com/user-attachments/assets/a737408b-b4ff-47b2-89fe-4d2bf5eddc49" />

https://github.com/user-attachments/assets/ec42fb2a-ef2b-417d-a4cd-b392b914c4ed

---

## Features

* **Dual Motion Tracking**: Seamlessly switch between **Mac Accelerometer** (`IOKit` / `AppleSPUHIDDevice`) and **AirPods Spatial Head Tracking** (`CoreMotion` / `CMHeadphoneMotionManager`).
* **Multi-Layer 3D Depth Engine**: Stack multiple PNG/JPEG layers with independent depth offsets, scaling, and real-time interactive canvas mouse positioning.
* **Smart Zero-Overhead Engine**:
  * **0.0% CPU at Rest**: Automatically locks to center baseline when stationary, pausing sensor calculation and graphics rendering.
  * **Continuous Deadband**: Adjustable threshold (up to 16,000 units) to completely filter out typing vibrations and desk drift without sudden jumps.
  * **Occlusion Awareness**: Automatically pauses when full-screen apps or overlaying windows cover the desktop.
* **Interactive Calibration Wizards**: One-click recording modes to auto-profile your desk deadzone and calibrate comfortable tilt sensitivity ($0.1\times$ – $2.0\times$).
* **Menu Bar & System Integration**: Fast preset switching, quick pause/resume controls, and optional start-at-login support.
* **Scene Management**: Save collections locally, preview them statically in the gallery, and export/import portable `.pxwall` scene packages.

---

## Installation

### Option 1: Install via Homebrew (Recommended)

```bash
brew install alphastar-avi/tap/parallexwall
```

To update in the future:
```bash
brew upgrade parallexwall
```

---

### Option 2: Manual Download & macOS Security Note

1. Download `ParallaxWallpaper.dmg` from the [Latest Release](https://github.com/alphastar-avi/ParallaxWall/releases/latest).
2. Open the DMG and drag `parallexWall.app` into `/Applications`.

> [!NOTE]
> Because Parallax Wallpaper runs outside the Mac App Store to read raw hardware sensor telemetry, macOS Gatekeeper may show a warning on first launch. If prompted, run this command in **Terminal**:
> ```bash
> xattr -dr com.apple.quarantine "/Applications/parallexWall.app"
> ```

---

## Requirements

* macOS 12.0 (Monterey) or later
* Motion Tracking Requirements:
  * **Mac Accelerometer**: MacBook Air / MacBook Pro (Apple Silicon M1 and later) with internal SPU sensors.
  * **AirPods Head Tracking**: AirPods Pro, AirPods Max, or AirPods (3rd gen+) with spatial audio head tracking.

---

## Architecture & Sensor Telemetry

```
[ Internal Apple SPU ]
       │ (IOKit / AppleSPUHIDDevice)
       ▼
[ Motion Manager ] ──► [ Continuous Deadband & Calibrated Baseline ]
       │                                     │
       ▼                                     ▼
[ Combine rotationPublisher ] ──► [ CoreAnimation GPU Compositor (CATransform3D) ]
                                             │
                                             ▼
                                  [ Wallpaper NSWindow ]
```

* **Hardware Sensor Telemetry**: Parallax Wallpaper communicates directly with the internal Apple Silicon Sensor Processing Unit (SPU) via `IOKit` matching `AppleSPUHIDDevice`. It reads raw 3-axis accelerometer vector samples (`x`, `y`, `z`) without running high-overhead user-space frameworks.
* **Continuous Deadband Filtering**: Raw physical acceleration is centered against a calibrated baseline and processed through a continuous deadband algorithm (`excess = distance - deadzone`). Typing vibrations, trackpad clicks, and minor desk bumps below the threshold produce zero delta, keeping CPU at 0.0%.
* **GPU Hardware Compositing**: Parallax layer transformations are calculated as 3D matrices (`CATransform3D`) and composited directly on the GPU using CoreAnimation backing layers (`.compositingGroup()`). Only transformation matrices are modified during movement, avoiding expensive view re-renders and preserving battery life.
