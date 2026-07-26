# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using built-in Apple Silicon accelerometer tracking and AirPods spatial head motion detection. As you move your laptop or tilt your head, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Compose rich, multi-layered 3D depth scenes with custom per-layer motion tuning, save custom scene collections locally, and export/import them via portable `.pxwall` packages.

<img width="1470" height="956" alt="Screenshot 2026-03-22 at 3 34 30 AM" src="https://github.com/user-attachments/assets/0d55223e-ad67-46fb-89de-66b6f8963559" />

---

## What's New in v3.0.0

* **Apple-Style Floating Bottom Navigation Bar**: Seamlessly switch between the **Parallax Editor** and **Browse Collections** gallery using a modern glassmorphic pill bar.
* **Collections Gallery View**: Apple Photos / Launchpad style grid displaying all saved parallax collections with 3D thumbnail previews, layer counts, quick wallpaper activation, and editor loading.
* **Save Scene Collection**: Click **Save Collection** on the preview canvas to save your draft scene to your private local collection storage (`~/Library/Application Support/ParallaxWallpaper/Collections/`).
* **Privacy & Local Collection Storage**: Saved collections are kept 100% local on your Mac and automatically ignored from Git source control.
* **Portable `.pxwall` Package Format**:
  * **Export**: Export any collection to a portable `.pxwall` compressed bundle containing full-resolution lossless PNG/JPEG layer images and complete JSON metadata (depths, zoom crop scales, opacities, $X$/$Y$ offsets).
  * **Import & Drag and Drop**: Import `.pxwall` files via button or drag and drop any `.pxwall` file directly onto the Browse Collections gallery page.
* **Refined Sidebar Header Icon**: Sidebar icon updated to `square.3.layers.3d.down.right`.
* **Background Layer Edge Protection**: Background Layer 0 uses `.aspectRatio(contentMode: .fill)` with minimum $1.15\times$ scale padding and strict offset bounds (`maxOffset = (scaleEffect - 1.0) * screen / 2`) so tilting never exposes black borders.
* **Stable Directional Handle Scaling**: Top-right circular handle dot scales layer zoom smoothly without ghosting or moving layer position.

---

## Features

* **Dual Motion Tracking Sources**: Switch seamlessly between **Mac Accelerometer** (`IOKit` `AppleSPUHIDDevice`) and **AirPods Spatial Head Tracking** (`CoreMotion` `CMHeadphoneMotionManager`).
* **Multi-Layer 3D Parallax Engine**: Upload $N$ image layers (PNGs/JPEGs) where the first uploaded image forms the background and the last forms the foreground.
* **Interactive Canvas Mouse Controls**:
  * Drag any selected layer's body directly inside the preview canvas to position it on screen.
  * Drag the **top-right blue circular handle dot** up or down to visually scale layer zoom ($0.15\times$ to $3.0\times$).
* **Menu Bar Quick Actions**: Toggle **Pause Wallpaper** / **Resume Wallpaper** instantly from the macOS status bar icon menu.
* **Live Telemetry Bar**: Real-time analytical readouts tracking horizontal and vertical pixel offsets.
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
