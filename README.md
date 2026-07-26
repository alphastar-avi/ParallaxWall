# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using built-in Apple Silicon accelerometer tracking and AirPods spatial head motion detection. As you move your laptop or tilt your head, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Upload a single wallpaper or compose multi-layered 3D depth scenes with custom per-layer motion tuning.

<img width="1470" height="956" alt="Screenshot 2026-03-22 at 3 34 30 AM" src="https://github.com/user-attachments/assets/0d55223e-ad67-46fb-89de-66b6f8963559" />

---

## Features

* **Dual Motion Tracking Sources**: Switch seamlessly between **Mac Accelerometer** (`IOKit` `AppleSPUHIDDevice`) and **AirPods Spatial Head Tracking** (`CoreMotion` `CMHeadphoneMotionManager`).
* **Unified Parallax Editor**: Single streamlined editor. Upload 1 image for a protected background wallpaper or upload $N$ image layers for rich 3D depth parallax.
* **Background Layer Edge Protection**: Strict edge clamping for the background layer (Layer 0) to ensure tilting never exposes black canvas borders.
* **Interactive Canvas Mouse Controls**:
  * Drag any selected layer's body directly inside the preview canvas to position it on screen.
  * Drag the **top-right blue circular handle dot** on the selection bounding box to visually resize layer scale ($0.15\times$ to $3.0\times$).
* **Menu Bar Quick Actions**:
  * Toggle **Pause Wallpaper** / **Resume Wallpaper** instantly from the macOS status bar icon menu.
* **Live Telemetry HUD**: Real-time analytical readouts tracking X/Y tilt angles and pixel offsets.
* **Draggable Layer Reordering**: Drag-and-drop or reorder layers in the sidebar stack.
* **Inverted Motion Smoothing Control**: Intuitive slider control ($0.0$ Raw/Direct to $1.0$ Ultra Smooth).
* **Live Draft Preview vs. Applied Wallpaper**: Tweak layer settings with instant live preview in the window, then click **"Apply Changes to Wallpaper"** to project onto your desktop.
* **Aspect-Fitted Monitor Preview**: Custom $16:10$ Mac screen monitor preview frame.
* **Center Calibration**: One-click calibration to snap the 3D focal point to your current physical desk angle or head position.

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

## Requirements

* macOS 12.0 (Monterey) or later
* Motion Tracking Requirements:
  * **Mac Accelerometer**: MacBook Air (M1, M2, M3, M4) or MacBook Pro (M1, M2, M3, M4) with internal SPU sensors.
  * **AirPods Head Tracking**: AirPods Pro, AirPods Max, or AirPods (3rd gen+) with head motion tracking support.

---

## How It Works

This application directly integrates with low-level `AppleSPUHIDDevice` APIs using macOS `IOKit` for Mac motion and `CMHeadphoneMotionManager` for AirPods head tracking. 

The raw rotational and attitude data vectors are streamed into a low-pass exponential moving average filter governed by the **Motion Smoothing** slider. This mathematical backend smooths out all micro-vibrations, rendering stable horizontal and vertical pixel offsets directly onto a borderless desktop-level `NSWindow` behind your icons.
