# Parallax Wallpaper

Parallax Wallpaper brings your macOS desktop to life using the built-in accelerometer tracking found in Apple Silicon Macs. As you move or tilt your laptop, your desktop background smoothly reacts and pans in real time, creating an immersive sense of 3D depth behind your icons and windows. Choose any custom image, dial in the perfect sensitivity, and effortlessly snap your center-point to match your current posture.
More features yet to come!

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

## Battery Impact

Continuous 100Hz hardware motion tracking runs a background driver which consumes slight system resources, meaning your MacBook battery may drain slightly faster over a long session. Stopping or deactivating the wallpaper from the main dashboard returns battery usage completely to normal. It does not harm hardware whatsoever.

---

## Source and Build

This application disables the strict macOS App Sandbox by design in `project.pbxproj` to legitimately communicate with the extremely low-level proprietary `AppleSPUHIDDevice` APIs that handle internal Apple Silicon tilt events. 
