import SwiftUI
import UniformTypeIdentifiers

struct LayerRowView: View {
    let layer: ParallaxLayer
    let isSelected: Bool
    let isTop: Bool
    let isBottom: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onToggleVisibility: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            if let image = layer.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(layer.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if isTop {
                        Text("Foreground")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .cornerRadius(4)
                    } else if isBottom {
                        Text("Background")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
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
            
            VStack(spacing: 2) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isTop)
                
                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isBottom)
            }
            .foregroundStyle(.secondary)
            
            Button(action: onToggleVisibility) {
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
        .onTapGesture(perform: onTap)
    }
}

struct MultiLayerEditorView: View {
    @ObservedObject var sensor: SensorManager
    @ObservedObject var wallpaperController: WallpaperController
    
    @State private var showingImagePicker = false
    @State private var selectedLayerId: UUID? = nil
    @State private var draggedItem: ParallaxLayer? = nil
    
    var selectedLayer: ParallaxLayer? {
        wallpaperController.draftLayers.first(where: { $0.id == selectedLayerId })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Side: Fitted Aspect Ratio Preview Canvas
            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                
                if wallpaperController.draftLayers.isEmpty {
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
                    VStack {
                        DesktopMonitorFrame {
                            MultiLayerParallaxView(
                                layers: wallpaperController.draftLayers,
                                sensor: sensor,
                                sensitivity: wallpaperController.draftSensitivity
                            )
                        }
                        .padding(32)
                    }
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                if !wallpaperController.draftLayers.isEmpty {
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
            
            // MARK: - Right Side: Control Sidebar
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header & Status
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
                            .disabled(wallpaperController.draftLayers.isEmpty)
                            .controlSize(.large)
                        }
                        
                        Divider()
                        
                        // MARK: - Global Settings & Sensors
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Global Settings", systemImage: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            // Requirement 5: Motion Source Selector (Mac vs. AirPods)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Motion Source")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                AppleMotionSourcePicker(selection: $sensor.motionSource)
                                
                                if sensor.motionSource == .airpods {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(sensor.isAirPodsConnected ? Color.green : Color.orange)
                                            .frame(width: 8, height: 8)
                                        Text(sensor.isAirPodsConnected ? "AirPods Connected & Tracking Head Motion" : "Searching for AirPods...")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            
                            // Motion Sensitivity
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Motion Sensitivity")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(String(format: "%.2fx", wallpaperController.draftSensitivity))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Slider(value: $wallpaperController.draftSensitivity, in: 0.01...1.0) {
                                    Text("Sensitivity")
                                } minimumValueLabel: {
                                    Image(systemName: "tortoise").foregroundStyle(.secondary)
                                } maximumValueLabel: {
                                    Image(systemName: "hare").foregroundStyle(.secondary)
                                }
                            }
                            
                            // Requirement 2: Motion Damping / Smoothness Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Motion Smoothing")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(sensor.smoothing < 0.04 ? "Ultra Smooth" : (sensor.smoothing > 0.15 ? "Direct/Raw" : "Balanced"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Slider(value: $sensor.smoothing, in: 0.01...0.25) {
                                    Text("Smoothing")
                                } minimumValueLabel: {
                                    Image(systemName: "waveform.path.smooth").foregroundStyle(.secondary)
                                } maximumValueLabel: {
                                    Image(systemName: "waveform.path").foregroundStyle(.secondary)
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
                        
                        // MARK: - Requirement 1: Draggable Layer Stack List
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Layers (\(wallpaperController.draftLayers.count))", systemImage: "layers")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if !wallpaperController.draftLayers.isEmpty {
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
                            
                            if wallpaperController.draftLayers.isEmpty {
                                Text("No layers uploaded yet.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(Array(wallpaperController.draftLayers.enumerated().reversed()), id: \.element.id) { index, layer in
                                        let isSelected = (selectedLayerId == layer.id)
                                        let isTop = (index == wallpaperController.draftLayers.count - 1)
                                        let isBottom = (index == 0)
                                        
                                        LayerRowView(
                                            layer: layer,
                                            isSelected: isSelected,
                                            isTop: isTop,
                                            isBottom: isBottom,
                                            onMoveUp: {
                                                if index < wallpaperController.draftLayers.count - 1 {
                                                    withAnimation {
                                                        wallpaperController.draftLayers.swapAt(index, index + 1)
                                                    }
                                                }
                                            },
                                            onMoveDown: {
                                                if index > 0 {
                                                    withAnimation {
                                                        wallpaperController.draftLayers.swapAt(index, index - 1)
                                                    }
                                                }
                                            },
                                            onToggleVisibility: {
                                                var updated = layer
                                                updated.isVisible.toggle()
                                                wallpaperController.updateLayer(updated)
                                            },
                                            onTap: {
                                                withAnimation {
                                                    selectedLayerId = layer.id
                                                }
                                            }
                                        )
                                        .onDrag {
                                            self.draggedItem = layer
                                            return NSItemProvider(item: layer.id.uuidString as NSString, typeIdentifier: UTType.plainText.identifier)
                                        }
                                        .onDrop(of: [.plainText], delegate: LayerDropDelegate(item: layer, layers: $wallpaperController.draftLayers, draggedItem: $draggedItem))
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Selected Layer Inspector Card
                        if let layer = selectedLayer {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 14) {
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
                                
                                // Depth Multiplier
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
                                
                                // Zoom Crop Scale
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
                                
                                // Opacity
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
                            .padding(14)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
                
                // MARK: - Requirement 4: Fixed Bottom "Apply Changes to Wallpaper" Button
                VStack(spacing: 8) {
                    Divider()
                    
                    VStack(spacing: 6) {
                        if wallpaperController.hasUnsavedChanges {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                Text("Unsaved changes in draft preview")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Button {
                            withAnimation {
                                wallpaperController.applyChangesToWallpaper(sensor: sensor)
                            }
                        } label: {
                            Label("Apply Changes to Wallpaper", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(wallpaperController.hasUnsavedChanges ? .blue : .gray)
                        .disabled(!wallpaperController.hasUnsavedChanges)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(nsColor: .windowBackgroundColor))
                }
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
                if selectedLayerId == nil, let first = wallpaperController.draftLayers.first {
                    selectedLayerId = first.id
                }
            case .failure(let error):
                print("Error picking layer images: \(error)")
            }
        }
    }
}

// MARK: - Drag & Drop Delegate for Layer Reordering
struct LayerDropDelegate: DropDelegate {
    let item: ParallaxLayer
    @Binding var layers: [ParallaxLayer]
    @Binding var draggedItem: ParallaxLayer?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem, draggedItem.id != item.id else { return }
        
        if let fromIndex = layers.firstIndex(of: draggedItem),
           let toIndex = layers.firstIndex(of: item) {
            withAnimation {
                layers.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }
}
