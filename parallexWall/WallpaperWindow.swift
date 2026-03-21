import AppKit
import SwiftUI
import Combine

class WallpaperWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.hasShadow = false
        
        // Hide the window initially
        self.orderBack(nil)
    }
}

class WallpaperController: ObservableObject {
    private var window: WallpaperWindow?
    @Published var isEnabled = false
    @Published var sensitivity: Double = 0.002
    
    func toggle(image: NSImage?, sensor: SensorManager) {
        if isEnabled {
            window?.close()
            window = nil
            isEnabled = false
        } else {
            guard let screen = NSScreen.main else { return }
            let win = WallpaperWindow(screen: screen)
            
            let parallaxView = ParallaxView(image: image, sensor: sensor, controller: self)
            win.contentView = NSHostingView(rootView: parallaxView)
            
            win.makeKeyAndOrderFront(nil)
            win.orderBack(nil) // Ensure it's behind everything
            
            self.window = win
            isEnabled = true
        }
    }
}
