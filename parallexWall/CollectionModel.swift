import Foundation
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Layer Metadata Codable Model
public struct LayerMetadata: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var depthFactor: Double
    public var scaleEffect: CGFloat
    public var opacity: Double
    public var isVisible: Bool
    public var offsetX: Double
    public var offsetY: Double
    public var imageFileName: String
    
    public init(from layer: ParallaxLayer, fileName: String) {
        self.id = layer.id
        self.name = layer.name
        self.depthFactor = layer.depthFactor
        self.scaleEffect = layer.scaleEffect
        self.opacity = layer.opacity
        self.isVisible = layer.isVisible
        self.offsetX = layer.offsetX
        self.offsetY = layer.offsetY
        self.imageFileName = fileName
    }
}

// MARK: - Collection Metadata Codable Model
public struct ParallaxCollectionMetadata: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var sensitivity: Double
    public var layers: [LayerMetadata]
}

// MARK: - In-Memory Collection Model
public struct ParallaxCollection: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var sensitivity: Double
    public var layers: [ParallaxLayer]
    
    public var thumbnailImage: NSImage? {
        layers.last?.image ?? layers.first?.image
    }
    
    public static func == (lhs: ParallaxCollection, rhs: ParallaxCollection) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.layers == rhs.layers
    }
}

// MARK: - Collection Storage & Import/Export Manager
@MainActor
class CollectionManager: ObservableObject {
    static let shared = CollectionManager()
    
    @Published var collections: [ParallaxCollection] = []
    
    private var collectionsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ParallaxWallpaper/Collections", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public init() {
        loadAllCollections()
    }
    
    public func loadAllCollections() {
        var loaded: [ParallaxCollection] = []
        let fm = FileManager.default
        
        guard let subdirs = try? fm.contentsOfDirectory(at: collectionsDirectory, includingPropertiesForKeys: nil) else {
            self.collections = []
            return
        }
        
        for dir in subdirs {
            let metaURL = dir.appendingPathComponent("metadata.json")
            guard let data = try? Data(contentsOf: metaURL),
                  let meta = try? JSONDecoder().decode(ParallaxCollectionMetadata.self, from: data) else {
                continue
            }
            
            var parallaxLayers: [ParallaxLayer] = []
            let imagesDir = dir.appendingPathComponent("images", isDirectory: true)
            
            for layerMeta in meta.layers {
                let imgURL = imagesDir.appendingPathComponent(layerMeta.imageFileName)
                let image = NSImage(contentsOf: imgURL)
                
                let layer = ParallaxLayer(
                    id: layerMeta.id,
                    name: layerMeta.name,
                    image: image,
                    depthFactor: layerMeta.depthFactor,
                    scaleEffect: layerMeta.scaleEffect,
                    opacity: layerMeta.opacity,
                    isVisible: layerMeta.isVisible,
                    offsetX: layerMeta.offsetX,
                    offsetY: layerMeta.offsetY
                )
                parallaxLayers.append(layer)
            }
            
            let collection = ParallaxCollection(
                id: meta.id,
                title: meta.title,
                createdAt: meta.createdAt,
                sensitivity: meta.sensitivity,
                layers: parallaxLayers
            )
            loaded.append(collection)
        }
        
        loaded.sort { $0.createdAt > $1.createdAt }
        self.collections = loaded
    }
    
    // MARK: - Save Draft Layers as New Collection
    
    public func saveCollection(title: String, layers: [ParallaxLayer], sensitivity: Double) -> ParallaxCollection? {
        guard !layers.isEmpty else { return nil }
        
        let collectionId = UUID()
        let fm = FileManager.default
        let collectionDir = collectionsDirectory.appendingPathComponent(collectionId.uuidString, isDirectory: true)
        let imagesDir = collectionDir.appendingPathComponent("images", isDirectory: true)
        
        try? fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        var layerMetas: [LayerMetadata] = []
        
        for (idx, layer) in layers.enumerated() {
            let fileName = "layer_\(idx).png"
            if let image = layer.image, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let pngData = bitmap.representation(using: .png, properties: [:]) {
                let fileURL = imagesDir.appendingPathComponent(fileName)
                try? pngData.write(to: fileURL)
            }
            let meta = LayerMetadata(from: layer, fileName: fileName)
            layerMetas.append(meta)
        }
        
        let collectionMeta = ParallaxCollectionMetadata(
            id: collectionId,
            title: title.isEmpty ? "Untitled Collection" : title,
            createdAt: Date(),
            sensitivity: sensitivity,
            layers: layerMetas
        )
        
        let metaURL = collectionDir.appendingPathComponent("metadata.json")
        if let json = try? JSONEncoder().encode(collectionMeta) {
            try? json.write(to: metaURL)
        }
        
        let newCollection = ParallaxCollection(
            id: collectionId,
            title: collectionMeta.title,
            createdAt: collectionMeta.createdAt,
            sensitivity: collectionMeta.sensitivity,
            layers: layers
        )
        
        loadAllCollections()
        return newCollection
    }
    
    public func deleteCollection(id: UUID) {
        let collectionDir = collectionsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: collectionDir)
        loadAllCollections()
    }
    
    // MARK: - Export Collection to .pxwall File
    
    public func exportCollection(_ collection: ParallaxCollection) {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Parallax Collection"
        savePanel.nameFieldStringValue = "\(collection.title.replacingOccurrences(of: " ", with: "_")).pxwall"
        savePanel.allowedContentTypes = [.data]
        
        savePanel.begin { result in
            guard result == .OK, let destinationURL = savePanel.url else { return }
            
            let sourceDir = self.collectionsDirectory.appendingPathComponent(collection.id.uuidString, isDirectory: true)
            
            let tmpZip = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).zip")
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            task.arguments = ["-r", "-q", tmpZip.path, "."]
            task.currentDirectoryURL = sourceDir
            
            try? task.run()
            task.waitUntilExit()
            
            try? FileManager.default.removeItem(at: destinationURL)
            try? FileManager.default.moveItem(at: tmpZip, to: destinationURL)
        }
    }
    
    // MARK: - Import .pxwall File
    
    public func importCollection(from url: URL) -> Bool {
        let collectionId = UUID()
        let targetDir = collectionsDirectory.appendingPathComponent(collectionId.uuidString, isDirectory: true)
        let fm = FileManager.default
        
        try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        task.arguments = ["-q", "-o", url.path, "-d", targetDir.path]
        
        try? task.run()
        task.waitUntilExit()
        
        // Update collection ID inside metadata JSON to avoid conflicts
        let metaURL = targetDir.appendingPathComponent("metadata.json")
        if let data = try? Data(contentsOf: metaURL),
           var meta = try? JSONDecoder().decode(ParallaxCollectionMetadata.self, from: data) {
            meta.id = collectionId
            if let updatedJson = try? JSONEncoder().encode(meta) {
                try? updatedJson.write(to: metaURL)
            }
        }
        
        loadAllCollections()
        return true
    }
}
