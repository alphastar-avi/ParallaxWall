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
        self.isReleasedWhenClosed = false
        
        // Hide the window initially
        self.orderBack(nil)
    }
}

@MainActor
class WallpaperController: ObservableObject {
    @Published var window: WallpaperWindow?
    @Published var isEnabled = false
    @Published var selectedTab: ParallaxTab = .single
    
    // MARK: - Draft State (used for real-time live preview in app UI)
    @Published var draftSingleImage: NSImage? = nil
    @Published var draftLayers: [ParallaxLayer] = []
    @Published var draftSensitivity: Double = 0.5
    
    // MARK: - Applied State (used for actual desktop wallpaper window)
    @Published var appliedSingleImage: NSImage? = nil
    @Published var appliedLayers: [ParallaxLayer] = []
    @Published var appliedSensitivity: Double = 0.5
    
    // MARK: - Unsaved Changes Tracking
    var hasUnsavedChanges: Bool {
        if selectedTab == .single {
            return draftSingleImage !== appliedSingleImage || draftSensitivity != appliedSensitivity
        } else {
            return draftLayers != appliedLayers || draftSensitivity != appliedSensitivity
        }
    }
    
    // MARK: - Layer Stack Draft Operations
    
    func addLayers(urls: [URL]) {
        for url in urls {
            if let image = NSImage(contentsOf: url) {
                let filename = url.deletingPathExtension().lastPathComponent
                let count = draftLayers.count + 1
                let layerName = filename.isEmpty ? "Layer \(count)" : filename
                let newLayer = ParallaxLayer(
                    name: layerName,
                    image: image,
                    depthFactor: 1.0
                )
                draftLayers.append(newLayer)
            }
        }
        autoDistributeDepths()
    }
    
    func removeLayer(id: UUID) {
        draftLayers.removeAll { $0.id == id }
        autoDistributeDepths()
    }
    
    func moveLayers(fromOffsets source: IndexSet, toOffset destination: Int) {
        draftLayers.move(fromOffsets: source, toOffset: destination)
    }
    
    func updateLayer(_ updatedLayer: ParallaxLayer) {
        if let idx = draftLayers.firstIndex(where: { $0.id == updatedLayer.id }) {
            draftLayers[idx] = updatedLayer
        }
    }
    
    func autoDistributeDepths() {
        guard !draftLayers.isEmpty else { return }
        if draftLayers.count == 1 {
            draftLayers[0].depthFactor = 1.0
            return
        }
        
        let minDepth = 0.2
        let maxDepth = 1.8
        let step = (maxDepth - minDepth) / Double(draftLayers.count - 1)
        
        for i in 0..<draftLayers.count {
            draftLayers[i].depthFactor = (minDepth + step * Double(i))
        }
    }
    
    func clearLayers() {
        draftLayers.removeAll()
    }
    
    // MARK: - Save & Apply Changes to Wallpaper
    
    func applyChangesToWallpaper(sensor: SensorManager) {
        appliedSingleImage = draftSingleImage
        appliedLayers = draftLayers
        appliedSensitivity = draftSensitivity
        
        if isEnabled, let win = window {
            attachHostingView(to: win, sensor: sensor)
        }
    }
    
    // MARK: - Desktop Wallpaper Toggle & Host Management
    
    func toggle(sensor: SensorManager) {
        if isEnabled {
            window?.close()
            window = nil
            isEnabled = false
        } else {
            // Apply current draft state when enabling
            appliedSingleImage = draftSingleImage
            appliedLayers = draftLayers
            appliedSensitivity = draftSensitivity
            
            guard let screen = NSScreen.main else { return }
            let win = WallpaperWindow(screen: screen)
            
            attachHostingView(to: win, sensor: sensor)
            
            win.orderBack(nil)
            self.window = win
            isEnabled = true
        }
    }
    
    private func attachHostingView(to win: WallpaperWindow, sensor: SensorManager) {
        if selectedTab == .single {
            let view = ParallaxView(image: appliedSingleImage, sensor: sensor, controller: self)
            win.contentView = NSHostingView(rootView: view)
        } else {
            let view = MultiLayerParallaxView(layers: appliedLayers, sensor: sensor, sensitivity: appliedSensitivity)
            win.contentView = NSHostingView(rootView: view)
        }
    }
}
