# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using the built-in accelerometer tracking found in Apple Silicon Macs. As you move or tilt your laptop, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Choose any custom image, dial in the perfect sensitivity, and effortlessly snap your center-point to match your current posture.
More features yet to come!

<img width="1470" height="956" alt="Screenshot 2026-03-22 at 3 34 30 AM" src="https://github.com/user-attachments/assets/0d55223e-ad67-46fb-89de-66b6f8963559" />

---

## Features

* Real-time desktop parallax using built-in Apple Silicon accelerometer sensors
* **Center Calibration** to instantly snap the 3D focal point to your current physical desk angle
* Custom, high-resolution background image support 
* Adjustable motion sensitivity for perfectly tuned movement
* Live visual telemetry tracking your X and Y axis pixel offsets
* Extremely clean, native macOS split-view dashboard
* Menu bar integration for quick access

---

## Center Calibration

The **Set Current Angle as Center** feature is a quick-action calibration tool, perfect for when you switch environments (like moving from a flat desk to your lap). It monitors exactly how your MacBook is currently tilted and instantly maps that physical orientation to be the new "zero" point target. 

**Configuration Settings:**
* **Motion Sensitivity:** Adjust how heavily the background shifts in response to your laptop movements. Start with the 'tortoise' and work your way up to 'hare' depending on your preference.
* **Auto-Reset:** Whenever you completely close and reopen the app, your center calibration will seamlessly reset back to true hardware zero.

---

## Requirements

* macOS 12.0 (Monterey) or later
* Mac devices with built-in IOKit hardware accelerometers:
  * MacBook Air (M1, M2, M3)
  * MacBook Pro (M1, M2, M3)
    *(Note: Desktop hardware such as the Mac mini, Mac Studio, and Mac Pro do not include internal motion sensors.)*

---

## How It Works

This application directly integrates directly with the extremely low-level `AppleSPUHIDDevice` APIs using macOS `IOKit`. Because the internal Apple Silicon accelerometer is typically reserved for system-level functions (like screen auto-rotate logic or drop-protection), Parallax Wallpaper intentionally runs outside the strict macOS App Sandbox to capture this raw proprietary sensor data.

The raw X, Y, and Z hardware values are streamed at 100Hz into a low-pass exponential moving average filter. This mathematical backend drastically smooths out all micro-vibrations, processing completely stable horizontal and vertical pixel offsets straight to a borderless desktop-level `NSWindow`.
