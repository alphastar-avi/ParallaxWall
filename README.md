# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using the built-in accelerometer tracking found in Apple Silicon Macs. As you move or tilt your laptop, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Choose a single high-resolution wallpaper or compose rich, multi-layered 3D depth scenes with custom per-layer motion tuning.

<img width="1470" height="956" alt="Screenshot 2026-03-22 at 3 34 30 AM" src="https://github.com/user-attachments/assets/0d55223e-ad67-46fb-89de-66b6f8963559" />

---

## Features

* Real-time desktop parallax using built-in Apple Silicon accelerometer sensors
* **Apple-Inspired Floating Navigation Bar**: Modern glassmorphic bottom pill navigation bar for switching between single and multi-layer parallax modes
* **Multi-Layer 3D Parallax Engine**: Upload $N$ image layers (PNGs/JPEGs) where the first uploaded image forms the background and the last forms the foreground
* **Per-Layer Fine Tuning**: Individual controls for depth sensitivity multipliers ($0.0\times$ to $3.0\times$), zoom crop scaling, opacity, and layer visibility
* **Auto-Distribute Depths**: One-click automatic calculation to space depth factors across all $N$ layers
* **Center Calibration** to instantly snap the 3D focal point to your current physical desk angle
* Adjustable global motion sensitivity for perfectly tuned movement
* Live visual telemetry tracking your X and Y axis pixel offsets
* Menu bar integration for quick access

---

## Parallax Modes & Settings

### 1. Single Image Mode
The classic 1-image parallax experience. Upload any high-resolution image, dial in global motion sensitivity, and project it cleanly onto your desktop background.

### 2. Multi-Layer Mode
Compose custom 3D depth scenes using multiple stacked image layers (ideal for transparent PNGs):
* **Layer Order**: Layer 1 (first upload) maps to the **Background** (lowest motion depth), and Layer $N$ (last upload) maps to the **Foreground** (highest motion depth).
* **Depth Multipliers**: Tune individual layer reaction speed to physical tilt. Foreground elements shift more dynamically while background elements move subtly.
* **Layer Inspector**: Adjust zoom crop scale, opacity ($0\%$ to $100\%$), visibility toggles, or re-order layers on the fly.

### Center Calibration
The **Set Current Angle as Center** feature is a quick-action calibration tool, perfect for when you switch environments (like moving from a flat desk to your lap). It monitors exactly how your MacBook is currently tilted and instantly maps that physical orientation to be the new "zero" point target. 

---

## Requirements

* macOS 12.0 (Monterey) or later
* Mac devices with built-in IOKit hardware accelerometers:
  * MacBook Air (M1, M2, M3)
  * MacBook Pro (M1, M2, M3)
    *(Note: Desktop hardware such as the Mac mini, Mac Studio, and Mac Pro do not include internal motion sensors.)*

---

## How It Works

This application directly integrates with the extremely low-level `AppleSPUHIDDevice` APIs using macOS `IOKit`. Because the internal Apple Silicon accelerometer is typically reserved for system-level functions (like screen auto-rotate logic or drop-protection), Parallax Wallpaper intentionally runs outside the strict macOS App Sandbox to capture this raw proprietary sensor data.

The raw X, Y, and Z hardware values are streamed at 100Hz into a low-pass exponential moving average filter. This mathematical backend drastically smooths out all micro-vibrations, processing completely stable horizontal and vertical pixel offsets straight to a borderless desktop-level `NSWindow`.
