import SwiftUI
import UniformTypeIdentifiers

struct CollectionCardView: View {
    let collection: ParallaxCollection
    let onApply: () -> Void
    let onLoad: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail Container
            ZStack {
                Color.black.opacity(0.2)
                
                if let thumb = collection.thumbnailImage {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                } else {
                    Image(systemName: "square.3.layers.3d.down.right")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.tertiary)
                }
                
                // Layer Count Badge
                VStack {
                    HStack {
                        Spacer()
                        Text("\(collection.layers.count) Layers")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                            .padding(8)
                    }
                    Spacer()
                }
            }
            .frame(height: 150)
            .cornerRadius(10)
            
            // Collection Details
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(collection.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onApply) {
                    Label("Apply", systemImage: "play.fill")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: onLoad) {
                    Image(systemName: "square.and.pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .help("Load into Parallax Editor")
                
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .help("Export Collection (.pxwall)")
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .help("Delete Collection")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isHovered ? Color.blue.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: isHovered ? 1.5 : 1)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.12) : Color.clear, radius: 8, x: 0, y: 4)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hover
            }
        }
    }
}

struct CollectionsGalleryView: View {
    @ObservedObject var collectionManager: CollectionManager = CollectionManager.shared
    @ObservedObject var wallpaperController: WallpaperController
    @ObservedObject var sensor: SensorManager
    let onSwitchToEditor: () -> Void
    
    @State private var isTargetedForDrop = false
    
    let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.grid.2x2.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("Saved Collections")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("\(collectionManager.collections.count) collections available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Requirement 5: Top Corner Export / Import Button
                Button {
                    let openPanel = NSOpenPanel()
                    openPanel.title = "Import Parallax Collection (.pxwall)"
                    openPanel.allowedContentTypes = [.data]
                    openPanel.allowsMultipleSelection = true
                    
                    openPanel.begin { result in
                        guard result == .OK else { return }
                        for url in openPanel.urls {
                            _ = collectionManager.importCollection(from: url)
                        }
                    }
                } label: {
                    Label("Import .pxwall Collection", systemImage: "square.and.arrow.down")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Main Gallery View
            ScrollView {
                if collectionManager.collections.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        
                        Image(systemName: "photo.stack")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundStyle(.tertiary)
                        
                        Text("No Collections Saved Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create multi-layer parallax scenes in the Parallax Editor and click 'Save Collection', or drop a .pxwall file anywhere to import!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                        
                        Button("Create New Parallax Scene") {
                            onSwitchToEditor()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Spacer(minLength: 80)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(collectionManager.collections) { collection in
                            CollectionCardView(
                                collection: collection,
                                onApply: {
                                    wallpaperController.draftLayers = collection.layers
                                    wallpaperController.draftSensitivity = collection.sensitivity
                                    wallpaperController.applyChangesToWallpaper(sensor: sensor)
                                },
                                onLoad: {
                                    wallpaperController.draftLayers = collection.layers
                                    wallpaperController.draftSensitivity = collection.sensitivity
                                    onSwitchToEditor()
                                },
                                onExport: {
                                    collectionManager.exportCollection(collection)
                                },
                                onDelete: {
                                    withAnimation {
                                        collectionManager.deleteCollection(id: collection.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(28)
                }
            }
            .background(Color(nsColor: .underPageBackgroundColor))
            .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url, url.pathExtension.lowercased() == "pxwall" || url.pathExtension.lowercased() == "zip" {
                            DispatchQueue.main.async {
                                _ = collectionManager.importCollection(from: url)
                            }
                        }
                    }
                }
                return true
            }
        }
    }
}
