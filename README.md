# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using built-in Apple Silicon accelerometer tracking and AirPods spatial head motion detection. As you move your laptop or tilt your head, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Choose a single high-resolution wallpaper or compose rich, multi-layered 3D depth scenes with custom per-layer motion tuning.

<img width="1470" height="956" alt="Screenshot 2026-03-22 at 3 34 30 AM" src="https://github.com/user-attachments/assets/0d55223e-ad67-46fb-89de-66b6f8963559" />

---

## Features

* **Dual Motion Tracking Sources**: Switch seamlessly between **Mac Accelerometer** (`IOKit` `AppleSPUHIDDevice`) and **AirPods Spatial Head Tracking** (`CoreMotion` `CMHeadphoneMotionManager`).
* **Apple-Inspired Floating Navigation Bar**: Glassmorphic bottom pill navigation bar for switching between single and multi-layer parallax modes.
* **Apple-Style Block Motion Selector**: Custom Control Center style single-block slider switch to toggle between Mac and AirPods motion tracking.
* **Multi-Layer 3D Parallax Engine**: Upload $N$ image layers (PNGs/JPEGs) where the first uploaded image forms the background and the last forms the foreground.
* **Interactive Canvas Drag & Resize**:
  * Drag any layer directly inside the preview canvas to position it on screen.
  * Drag the **top-right circular handle dot** on the selection bounding box to visually resize layer scale ($0.15\times$ to $2.5\times$).
* **Draggable Layer Reordering**: Drag-and-drop or reorder layers in the sidebar stack.
* **Inverted Motion Smoothing Control**: Intuitive motion damping slider ($0.0$ Raw/Direct to $1.0$ Ultra Smooth).
* **Live Draft Preview vs. Applied Wallpaper**: Tweak layer settings with instant live preview in the window, then click **"Apply Changes to Wallpaper"** to project onto your desktop.
* **Aspect-Fitted Monitor Preview**: Custom $16:10$ Mac screen monitor preview frame.
* **Center Calibration**: One-click calibration to snap the 3D focal point to your current physical desk angle or head position.
* **Menu Bar Integration**: Quick access icon in the macOS menu bar.

---

## Installation & macOS Security Note

When downloading compiled `.dmg` builds from GitHub Releases, macOS Gatekeeper may display a warning such as *"Parallax Wallpaper is damaged and can’t be opened"* or *"Unidentified Developer"*.

### Reason
Parallax Wallpaper intentionally bypasses the macOS App Sandbox to read raw, unclipped hardware motion data directly from the internal Mac SPU accelerometer (`AppleSPUHIDDevice` via `IOKit`) and AirPods spatial motion sensors (`CMHeadphoneMotionManager`). Because the application is distributed as a free open-source release outside the Mac App Store, macOS automatically attaches a `com.apple.quarantine` extended attribute to the downloaded app bundle.

### Quick Fix Command
After dragging `parallexWall.app` into your `/Applications` folder, open **Terminal** and run the following command to strip the quarantine attribute:

```bash
xattr -dr com.apple.quarantine "/Applications/parallexWall.app"
```

Once executed, launch `parallexWall.app` normally from Launchpad or Finder.

---

## Parallax Modes & Settings

### 1. Single Image Mode
The classic 1-image parallax experience. Upload any high-resolution image, dial in motion sensitivity and motion smoothing, and project it cleanly onto your desktop background.

### 2. Multi-Layer Mode
Compose custom 3D depth scenes using multiple stacked image layers (ideal for transparent PNGs):
* **Layer Order**: Layer 1 (first upload) maps to the **Background** (lowest motion depth), and Layer $N$ (last upload) maps to the **Foreground** (highest motion depth).
* **Depth Multipliers**: Tune individual layer reaction speed to physical tilt. Foreground elements shift more dynamically while background elements move subtly.
* **Layer Inspector**: Adjust zoom crop scale ($0.15\times$ to $2.5\times$), opacity ($0\%$ to $100\%$), visibility toggles, or re-order layers on the fly.
* **Canvas Interactivity**: Select a layer and drag it on the preview canvas to position it, or drag the top-right blue handle dot to resize its scale.

---

## Requirements

* macOS 12.0 (Monterey) or later
* Motion Tracking Requirements:
  * **Mac Accelerometer**: MacBook Air (M1, M2, M3, M4) or MacBook Pro (M1, M2, M3, M4) with internal SPU sensors.
  * **AirPods Head Tracking**: AirPods Pro, AirPods Max, or AirPods (3rd gen+) with head motion tracking support.

---

## How It Works

This application directly integrates with low-level `AppleSPUHIDDevice` APIs using macOS `IOKit` for Mac motion and `CMHeadphoneMotionManager` for AirPods head tracking. 

The raw rotational and attitude data vectors are streamed into a low-pass exponential moving average filter governed by the **Motion Smoothing** slider. This mathematical backend smooths out all micro-vibrations, rendering stable horizontal and vertical pixel offsets directly onto a borderless desktop-level `NSWindow` behind your icons.
