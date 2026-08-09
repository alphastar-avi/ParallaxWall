# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using built-in Apple Silicon accelerometer tracking and AirPods spatial head motion detection. As you move your laptop or tilt your head, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Compose rich, multi-layered 3D depth scenes with custom per-layer motion tuning, save custom scene collections locally, and export/import them via portable `.pxwall` packages.

<img width="1279" height="934" alt="ParallaxHome" src="https://github.com/user-attachments/assets/c624649b-2f5a-4c01-9e34-49eede2d8aeb" />

<img width="1279" height="934" alt="ParallaxGallary" src="https://github.com/user-attachments/assets/a737408b-b4ff-47b2-89fe-4d2bf5eddc49" />

https://github.com/user-attachments/assets/ec7228fd-3008-4200-bd6c-154a25245725

---

## What's New in v3.2.0

* **Start at Login Support**: Automatic prompt on first launch and option to launch Parallax Wallpaper seamlessly when logging into macOS (`SMAppService`).
* **Multi-Level Layer Undo Stack**: Undo button (`arrow.uturn.backward`) next to "Clear All" allowing you to easily roll back structural changes (adding, removing, reordering, and layer tuning edits).
* **Smooth Resizable Settings Sidebar**: Interactive left/right drag handle with zero-jitter global coordinate tracking to expand or shrink the settings inspector sidebar.
* **Battery-Efficient Static Gallery Previews**: Gallery collection cards render static composite previews containing all stacked PNG layers with zero motion-sensor CPU or battery overhead.
* **Universal Layer Selection & Resizing**: Any selected layer (background, midground, or foreground) brings its outline and scale handle to the top of the Z-stack (`.zIndex(100)`), enabling direct canvas mouse drag position and scaling on any layer.
* **Preview Canvas to Desktop Wallpaper Accuracy**:
  * **Dynamic Aspect Ratio Matching**: Preview monitor frame (`DesktopMonitorFrame`) dynamically adopts your Mac display's native proportions (`NSScreen.main?.frame` aspect ratio e.g., 16:10 or 16:9).
  * **Proportional Position & Offset Scaling**: Positional offsets, motion parallax targets, clamping bounds, and mouse drag translations scale proportionally by `scaleFactor = canvasWidth / refWidth`, guaranteeing 100% visual accuracy between editor preview and full-screen desktop wallpaper.
* **Browse Gallery Enhancements**: Display file sizes in MB alongside creation timestamp (e.g. `Aug 10, 2026, 12:15 AM • 14.2 MB`) and enlarged action controls.
* **Refined Menu Bar Extra**:
  * Updated menu bar icon (`square.3.layers.3d.down.right`) matching the Parallax tab.
  * **Real-Time State Sync**: Selecting a saved collection from the menu bar instantly applies the wallpaper AND updates the app window preview canvas in real time.
  * Quick action controls (**"Update Current Angle"**, **"Open ParallaxWall"**, **"Pause/Activate Desktop Wallpaper"**).
* **Polished Apple-Native Styling**: Red-accented "Clear All" and "Remove Layer" buttons, gold bookmark icon on "Save Collection", and centered live telemetry readout positioned right above the monitor frame.

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
