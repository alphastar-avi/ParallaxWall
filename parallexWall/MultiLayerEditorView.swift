import SwiftUI
import UniformTypeIdentifiers

struct TelemetryBox: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.system(.subheadline, design: .monospaced).bold())
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(6)
    }
}

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

struct LayerRowView: View {
    let layer: ParallaxLayer
    let isSelected: Bool
    let isTop: Bool
    let isBottom: Bool
    @Binding var layers: [ParallaxLayer]
    @Binding var draggedItem: ParallaxLayer?
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
                
                Text("Depth: \(String(format: "%.1fx", layer.depthFactor)) | Scale: \(String(format: "%.2fx", layer.scaleEffect))")
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
        .onDrag {
            self.draggedItem = layer
            return NSItemProvider(object: layer.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: LayerDropDelegate(item: layer, layers: $layers, draggedItem: $draggedItem))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct MultiLayerEditorView: View {
    @ObservedObject var sensor: SensorManager
    @ObservedObject var wallpaperController: WallpaperController
    @ObservedObject var collectionManager: CollectionManager = CollectionManager.shared
    
    @State private var showingImagePicker = false
    @State private var selectedLayerId: UUID? = nil
    @State private var draggedItem: ParallaxLayer? = nil
    
    // Requirement 2: Save Collection Pop-up Modal State
    @State private var showingSaveModal = false
    @State private var collectionNameInput = ""
    @State private var showSavedToast = false
    
    var selectedLayer: ParallaxLayer? {
        wallpaperController.draftLayers.first(where: { $0.id == selectedLayerId })
    }
    
    // Live Telemetry Calculations
    var currentTiltX: Double {
        sensor.rotation.x - sensor.baseRotation.x
    }
    var currentTiltY: Double {
        sensor.rotation.y - sensor.baseRotation.y
    }
    var offsetX: Double {
        -currentTiltX * 0.005 * wallpaperController.draftSensitivity
    }
    var offsetY: Double {
        currentTiltY * 0.005 * wallpaperController.draftSensitivity
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
                            Label("Upload Wallpaper / PNG Layers", systemImage: "plus.circle.fill")
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
                                sensitivity: wallpaperController.draftSensitivity,
                                selectedLayerId: selectedLayerId,
                                onLayerPositionChanged: { layerId, newX, newY in
                                    if let idx = wallpaperController.draftLayers.firstIndex(where: { $0.id == layerId }) {
                                        var updated = wallpaperController.draftLayers[idx]
                                        updated.offsetX = newX
                                        updated.offsetY = newY
                                        wallpaperController.updateLayer(updated)
                                    }
                                },
                                onLayerScaleChanged: { layerId, newScale in
                                    if let idx = wallpaperController.draftLayers.firstIndex(where: { $0.id == layerId }) {
                                        var updated = wallpaperController.draftLayers[idx]
                                        updated.scaleEffect = newScale
                                        wallpaperController.updateLayer(updated)
                                    }
                                }
                            )
                        }
                        .padding(32)
                        .overlay(alignment: .topLeading) {
                            if let layer = selectedLayer {
                                HStack(spacing: 6) {
                                    Image(systemName: "hand.draw")
                                        .font(.caption2)
                                    Text("Selected '\(layer.name)' | Drag body to position, drag top-right blue dot up/down to scale")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .cornerRadius(6)
                                .padding(40)
                            }
                        }
                        // Requirement 2: Apple-style "Save Collection" button at bottom-left of preview window
                        .overlay(alignment: .bottomLeading) {
                            Button {
                                collectionNameInput = "My Scene \(collectionManager.collections.count + 1)"
                                showingSaveModal = true
                            } label: {
                                Label("Save Collection", systemImage: "bookmark.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(40)
                        }
                    }
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            
            Divider()
            
            // MARK: - Right Side: Control Sidebar
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 18) {
                        
                        // Header & Status
                        VStack(spacing: 12) {
                            HStack {
                                // Requirement 1: Icon updated to square.3.layers.3d.down.right
                                Image(systemName: "square.3.layers.3d.down.right")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                Text("Parallax Wallpaper")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            Text(wallpaperController.isEnabled ?
                                 "Active on Desktop" : "Wallpaper Paused")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(wallpaperController.isEnabled ? Color.green.opacity(0.2) : Color.secondary.opacity(0.2))
                                .foregroundStyle(wallpaperController.isEnabled ? .green : .secondary)
                                .clipShape(Capsule())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                wallpaperController.toggle(sensor: sensor)
                            }) {
                                Label(wallpaperController.isEnabled ? "Pause Desktop Wallpaper" : "Activate Desktop Wallpaper",
                                      systemImage: wallpaperController.isEnabled ? "power" : "play.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(wallpaperController.isEnabled ? .red : .blue)
                            .disabled(wallpaperController.draftLayers.isEmpty)
                            .controlSize(.large)
                        }
                        
                        // Minimalist Telemetry Bar
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text("Horizontal:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%+.1f px", offsetX))
                                    .font(.system(.caption, design: .monospaced).bold())
                            }
                            
                            Text("|")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            
                            HStack(spacing: 4) {
                                Text("Vertical:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%+.1f px", offsetY))
                                    .font(.system(.caption, design: .monospaced).bold())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(6)
                        
                        Divider()
                        
                        // MARK: - Global Settings & Sensors
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Global Settings", systemImage: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
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
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Motion Smoothing")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(sensor.userSmoothing > 0.8 ? "Ultra Smooth" : (sensor.userSmoothing < 0.2 ? "Direct/Raw" : "Balanced"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Slider(value: $sensor.userSmoothing, in: 0.0...1.0) {
                                    Text("Smoothing")
                                } minimumValueLabel: {
                                    Image(systemName: "waveform.path").foregroundStyle(.secondary)
                                } maximumValueLabel: {
                                    Image(systemName: "waveform.path.smooth").foregroundStyle(.secondary)
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
                        
                        // MARK: - Layers Section Header with "+ Add Layer" Button
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Layers (\(wallpaperController.draftLayers.count))", systemImage: "square.3.layers.3d")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Button {
                                    showingImagePicker = true
                                } label: {
                                    Label("Add Layer", systemImage: "plus")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            if !wallpaperController.draftLayers.isEmpty {
                                HStack {
                                    Button("Auto Depths") {
                                        withAnimation {
                                            wallpaperController.autoDistributeDepths()
                                        }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.borderless)
                                    
                                    Spacer()
                                    
                                    Button("Clear All") {
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
                                            layers: $wallpaperController.draftLayers,
                                            draggedItem: $draggedItem,
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
                                
                                // Zoom Crop Scale slider from 0.15x to 3.0x
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Zoom / Layer Scale")
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
                                        in: 0.15...3.0
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
                                
                                // Reset position offsets button
                                if layer.offsetX != 0 || layer.offsetY != 0 {
                                    Button {
                                        var updated = layer
                                        updated.offsetX = 0
                                        updated.offsetY = 0
                                        wallpaperController.updateLayer(updated)
                                    } label: {
                                        Label("Reset Position Offsets", systemImage: "arrow.counterclockwise")
                                            .font(.caption)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
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
                
                // Fixed Bottom Apply Button
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
        // Requirement 2: Save Collection Pop-up Modal Sheet
        .sheet(isPresented: $showingSaveModal) {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Save Scene Collection")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                Text("Enter a name for this parallax scene collection to save it to your local gallery and enable .pxwall file exports.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("Collection Name", text: $collectionNameInput)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                
                HStack {
                    Button("Cancel") {
                        showingSaveModal = false
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Save Collection") {
                        _ = collectionManager.saveCollection(
                            title: collectionNameInput,
                            layers: wallpaperController.draftLayers,
                            sensitivity: wallpaperController.draftSensitivity
                        )
                        showingSaveModal = false
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(collectionNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 380)
        }
    }
}
