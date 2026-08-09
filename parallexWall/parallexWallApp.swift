import SwiftUI
import ServiceManagement

struct LaunchAtLoginHelper {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    static func setEnabled(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to change launch at login status: \(error)")
            }
        }
    }
}

@main
struct parallexWallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var wallpaperController = WallpaperController()
    @StateObject private var sensor = SensorManager()
    @StateObject private var collectionManager = CollectionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        MenuBarExtra("Parallax Wallpaper", systemImage: "square.3.layers.3d.down.right") {
            // Status Info Header
            Text(wallpaperController.isEnabled ? "Wallpaper: Active on Desktop" : "Wallpaper: Paused")
                .font(.caption)
                .foregroundStyle(wallpaperController.isEnabled ? .green : .secondary)
            
            Button(wallpaperController.isEnabled ? "Pause Desktop Wallpaper" : "Activate Desktop Wallpaper") {
                wallpaperController.toggle(sensor: sensor)
            }
            .disabled(wallpaperController.draftLayers.isEmpty && !wallpaperController.isEnabled)
            
            Divider()
            
            // Motion Calibration
            Button("Set Current Angle as Center Zero") {
                sensor.calibrate()
            }
            
            Divider()
            
            // Quick Saved Collections Submenu
            if !collectionManager.collections.isEmpty {
                Menu("Apply Saved Collection (\(collectionManager.collections.count))") {
                    ForEach(collectionManager.collections) { collection in
                        Button(collection.title) {
                            wallpaperController.draftLayers = collection.layers
                            wallpaperController.draftSensitivity = collection.sensitivity
                            wallpaperController.applyChangesToWallpaper(sensor: sensor)
                        }
                    }
                }
                
                Divider()
            }
            
            // Open Main Control Panel
            Button("Open Parallax Control Panel") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                for window in NSApplication.shared.windows {
                    if window.title == "parallexWall" || window.title.isEmpty {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
            
            // Start at Login Option
            Button(LaunchAtLoginHelper.isEnabled ? "✓ Launch at Login Enabled" : "Enable Launch at Login") {
                LaunchAtLoginHelper.setEnabled(!LaunchAtLoginHelper.isEnabled)
            }
            
            Divider()
            
            Button("Quit Parallax Wallpaper") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
