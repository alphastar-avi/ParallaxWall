import SwiftUI
import UniformTypeIdentifiers

struct MultiLayerEditorView: View {
    @ObservedObject var sensor: SensorManager
    @ObservedObject var wallpaperController: WallpaperController
    
    @State private var showingImagePicker = false
    @State private var selectedLayerId: UUID? = nil
    
    // Telemetry computation
    private var parallaxOffsetX: Double {
        let currentX = sensor.rotation.x - sensor.baseRotation.x
        return -currentX * 0.005 * wallpaperController.sensitivity
    }
    
    private var parallaxOffsetY: Double {
        let currentY = sensor.rotation.y - sensor.baseRotation.y
        return currentY * 0.005 * wallpaperController.sensitivity
    }
    
    var selectedLayer: ParallaxLayer? {
        wallpaperController.layers.first(where: { $0.id == selectedLayerId })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Side: Multi-Layer Preview Canvas
            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                
                if wallpaperController.layers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.3.layers.3d.down.right")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundStyle(.tertiary)
                        
                        Text("No Layers Added")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Text("Click below to add PNG image layers from background to foreground")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                        
                        Button {
                            showingImagePicker = true
                        } label: {
                            Label("Upload PNG Layers", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else {
                    // Live Multi-Layer Preview
                    MultiLayerParallaxView(
                        layers: wallpaperController.layers,
                        sensor: sensor,
                        sensitivity: wallpaperController.sensitivity
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
                    .padding(24)
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                if !wallpaperController.layers.isEmpty {
                    Button(action: { showingImagePicker = true }) {
                        Label("Add More Layers", systemImage: "plus.circle")
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                    .padding(20)
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // MARK: - Right Side: Layer Controls & Fine Tuning
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header & Activation Status
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "square.3.layers.3d.down.right.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Text("Multi-Layer Parallax")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        Text(wallpaperController.isEnabled && wallpaperController.selectedTab == .multiLayer ?
                             "Active on Desktop" : "Wallpaper Paused")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(wallpaperController.isEnabled && wallpaperController.selectedTab == .multiLayer ? Color.green.opacity(0.2) : Color.secondary.opacity(0.2))
                            .foregroundStyle(wallpaperController.isEnabled && wallpaperController.selectedTab == .multiLayer ? .green : .secondary)
                            .clipShape(Capsule())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            wallpaperController.toggle(sensor: sensor)
                        }) {
                            Label(wallpaperController.isEnabled ? "Deactivate Wallpaper" : "Activate Desktop Wallpaper",
                                  systemImage: wallpaperController.isEnabled ? "power" : "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(wallpaperController.isEnabled ? .red : .blue)
                        .disabled(wallpaperController.layers.isEmpty)
                        .controlSize(.large)
                    }
                    
                    Divider()
                    
                    // Global Motion Settings
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Global Settings", systemImage: "slider.horizontal.3")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Motion Sensitivity")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.2fx", wallpaperController.sensitivity))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $wallpaperController.sensitivity, in: 0.01...1.0) {
                                Text("Sensitivity")
                            } minimumValueLabel: {
                                Image(systemName: "tortoise").foregroundStyle(.secondary)
                            } maximumValueLabel: {
                                Image(systemName: "hare").foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(action: {
                            withAnimation {
                                sensor.calibrate()
                            }
                        }) {
                            Label("Set Angle as Center Zero", systemImage: "scope")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    // MARK: - Layer Stack List
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Layers (\(wallpaperController.layers.count))", systemImage: "layers")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if !wallpaperController.layers.isEmpty {
                                Button("Auto Depths") {
                                    withAnimation {
                                        wallpaperController.autoDistributeDepths()
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.borderless)
                                
                                Button("Clear") {
                                    withAnimation {
                                        wallpaperController.clearLayers()
                                        selectedLayerId = nil
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                                .buttonStyle(.borderless)
                            }
                        }
                        
                        if wallpaperController.layers.isEmpty {
                            Text("No layers uploaded yet.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                        } else {
                            VStack(spacing: 8) {
                                // Render top layer (Foreground N) down to bottom layer (Background 1)
                                ForEach(Array(wallpaperController.layers.enumerated().reversed()), id: \.element.id) { index, layer in
                                    let isSelected = (selectedLayerId == layer.id)
                                    let isTop = (index == wallpaperController.layers.count - 1)
                                    let isBottom = (index == 0)
                                    
                                    HStack(spacing: 12) {
                                        // Layer thumbnail
                                        if let image = layer.image {
                                            Image(nsImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 36, height: 36)
                                                .background(Color.black.opacity(0.1))
                                                .cornerRadius(6)
                                        } else {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 36, height: 36)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(layer.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
                                                
                                                if isTop {
                                                    Text("Foreground")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.2))
                                                        .foregroundStyle(.blue)
                                                        .cornerRadius(4)
                                                } else if isBottom {
                                                    Text("Background")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(Color.purple.opacity(0.2))
                                                        .foregroundStyle(.purple)
                                                        .cornerRadius(4)
                                                }
                                            }
                                            
                                            Text("Depth: \(String(format: "%.1fx", layer.depthFactor)) | Opacity: \(Int(layer.opacity * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Visibility toggle button
                                        Button {
                                            var updated = layer
                                            updated.isVisible.toggle()
                                            wallpaperController.updateLayer(updated)
                                        } label: {
                                            Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                                                .font(.caption)
                                                .foregroundStyle(layer.isVisible ? .primary : .tertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .background(isSelected ? Color(nsColor: .selectedControlColor).opacity(0.3) : Color(nsColor: .windowBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation {
                                            selectedLayerId = layer.id
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Selected Layer Inspector Card
                    if let layer = selectedLayer {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Layer Tuning", systemImage: "slider.vertical.3")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(layer.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                            }
                            
                            // 1. Depth Multiplier Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Depth Multiplier")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.2fx", layer.depthFactor))
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { layer.depthFactor },
                                        set: { newVal in
                                            var updated = layer
                                            updated.depthFactor = newVal
                                            wallpaperController.updateLayer(updated)
                                        }
                                    ),
                                    in: 0.0...3.0
                                )
                            }
                            
                            // 2. Scale / Crop Zoom Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Zoom Crop Scale")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.2fx", layer.scaleEffect))
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(layer.scaleEffect) },
                                        set: { newVal in
                                            var updated = layer
                                            updated.scaleEffect = CGFloat(newVal)
                                            wallpaperController.updateLayer(updated)
                                        }
                                    ),
                                    in: 1.0...2.5
                                )
                            }
                            
                            // 3. Opacity Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Opacity")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(layer.opacity * 100))%")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { layer.opacity },
                                        set: { newVal in
                                            var updated = layer
                                            updated.opacity = newVal
                                            wallpaperController.updateLayer(updated)
                                        }
                                    ),
                                    in: 0.0...1.0
                                )
                            }
                            
                            // Layer Order & Delete Controls
                            HStack(spacing: 12) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        wallpaperController.removeLayer(id: layer.id)
                                        selectedLayerId = nil
                                    }
                                } label: {
                                    Label("Remove Layer", systemImage: "trash")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(14)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .frame(width: 360)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                wallpaperController.addLayers(urls: urls)
                if selectedLayerId == nil, let first = wallpaperController.layers.first {
                    selectedLayerId = first.id
                }
            case .failure(let error):
                print("Error picking layer images: \(error)")
            }
        }
    }
}
