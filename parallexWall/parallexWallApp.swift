import SwiftUI

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
