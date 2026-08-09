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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        MenuBarExtra("Parallax", systemImage: wallpaperController.isEnabled ? "power.circle.fill" : "play.circle") {
            Button(wallpaperController.isEnabled ? "Pause Wallpaper" : "Resume Wallpaper") {
                wallpaperController.toggle(sensor: SensorManager())
            }
            
            Divider()
            
            Button("Show Control Panel") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                for window in NSApplication.shared.windows {
                    if window.title == "parallexWall" || window.title.isEmpty {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
            
            Button(LaunchAtLoginHelper.isEnabled ? "Disable Launch at Login" : "Enable Launch at Login") {
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
