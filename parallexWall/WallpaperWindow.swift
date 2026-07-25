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
    @Published var sensitivity: Double = 0.5
    @Published var selectedTab: ParallaxTab = .single
    
    // Multi-layer stack state (index 0 = Background / bottom, index N-1 = Foreground / top)
    @Published var layers: [ParallaxLayer] = []
    
    // Active single image selection
    @Published var singleImage: NSImage? = nil
    
    // MARK: - Layer Stack Operations
    
    func addLayers(urls: [URL]) {
        for (index, url) in urls.enumerated() {
            if let image = NSImage(contentsOf: url) {
                let filename = url.deletingPathExtension().lastPathComponent
                let count = layers.count + 1
                let layerName = filename.isEmpty ? "Layer \(count)" : filename
                let newLayer = ParallaxLayer(
                    name: layerName,
                    image: image,
                    depthFactor: 1.0
                )
                layers.append(newLayer)
            }
        }
        autoDistributeDepths()
        refreshWallpaperViewIfActive()
    }
    
    func removeLayer(id: UUID) {
        layers.removeAll { $0.id == id }
        autoDistributeDepths()
        refreshWallpaperViewIfActive()
    }
    
    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
        autoDistributeDepths()
        refreshWallpaperViewIfActive()
    }
    
    func updateLayer(_ updatedLayer: ParallaxLayer) {
        if let idx = layers.firstIndex(where: { $0.id == updatedLayer.id }) {
            layers[idx] = updatedLayer
            refreshWallpaperViewIfActive()
        }
    }
    
    func autoDistributeDepths() {
        guard !layers.isEmpty else { return }
        if layers.count == 1 {
            layers[0].depthFactor = 1.0
            return
        }
        
        let minDepth = 0.2
        let maxDepth = 1.8
        let step = (maxDepth - minDepth) / Double(layers.count - 1)
        
        for i in 0..<layers.count {
            layers[i].depthFactor = (minDepth + step * Double(i))
        }
    }
    
    func clearLayers() {
        layers.removeAll()
        refreshWallpaperViewIfActive()
    }
    
    // MARK: - Desktop Wallpaper Toggle & Refresh
    
    func toggle(sensor: SensorManager) {
        if isEnabled {
            window?.close()
            window = nil
            isEnabled = false
        } else {
            guard let screen = NSScreen.main else { return }
            let win = WallpaperWindow(screen: screen)
            
            attachHostingView(to: win, sensor: sensor)
            
            win.orderBack(nil) // Ensure it stays behind desktop icons/windows
            self.window = win
            isEnabled = true
        }
    }
    
    func refreshWallpaperViewIfActive() {
        guard isEnabled, let win = window else { return }
        // Fetch current sensor instance from active scene if possible
    }
    
    func attachHostingView(to win: WallpaperWindow, sensor: SensorManager) {
        if selectedTab == .single {
            let view = ParallaxView(image: singleImage, sensor: sensor, controller: self)
            win.contentView = NSHostingView(rootView: view)
        } else {
            let view = MultiLayerParallaxView(layers: layers, sensor: sensor, sensitivity: sensitivity)
            win.contentView = NSHostingView(rootView: view)
        }
    }
}
