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

struct LiveTelemetryBarView: View {
    @ObservedObject var sensor: SensorManager
    let sensitivity: Double
    @State private var offsetX: Double = 0
    @State private var offsetY: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Horizontal:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%+.0f px", offsetX))
                    .font(.system(.caption, design: .monospaced).bold())
            }
            
            Text("|")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            HStack(spacing: 4) {
                Text("Vertical:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%+.0f px", offsetY))
                    .font(.system(.caption, design: .monospaced).bold())
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onReceive(sensor.rotationPublisher) { rot in
            let curX = rot.x - sensor.baseRotation.x
            let curY = rot.y - sensor.baseRotation.y
            let rawX = -curX * 0.005 * sensitivity
            let rawY = curY * 0.005 * sensitivity
            let roundedX = rawX.rounded()
            let roundedY = rawY.rounded()
            if roundedX != offsetX || roundedY != offsetY {
                offsetX = roundedX
                offsetY = roundedY
            }
        }
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
    
    // Resizable Sidebar State
    @State private var sidebarWidth: CGFloat = 360
    @State private var isDraggingSidebar = false
    @State private var dragStartSidebarWidth: CGFloat? = nil
    @State private var dragStartGlobalX: CGFloat? = nil
    
    // Performance Engine Tuning Panel State
    @State private var showingPerformancePanel = false
    
    // Interactive Calibration State
    @State private var isRecordingDeadzone = false
    @State private var recordedDeadzonePeak: Double = 0
    @State private var liveDeadzoneCurrent: Double = 0
    
    @State private var isRecordingSensitivity = false
    @State private var recordedTiltPeak: Double = 0
    @State private var liveTiltCurrent: Double = 0
    
    @State private var calibrationStatusMessage: String? = nil
    
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
                            Label("Upload Wallpaper / PNG Layers", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else {
                    previewCanvasView
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            
            // MARK: - Resizable Splitter Handle
            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
                
                Rectangle()
                    .fill(isDraggingSidebar ? Color.blue.opacity(0.4) : Color.clear)
                    .frame(width: 6)
            }
            .frame(width: 8)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { gesture in
                        if dragStartSidebarWidth == nil {
                            dragStartSidebarWidth = sidebarWidth
                            dragStartGlobalX = gesture.location.x
                            isDraggingSidebar = true
                        }
                        if let startWidth = dragStartSidebarWidth, let startX = dragStartGlobalX {
                            let delta = startX - gesture.location.x
                            let newWidth = startWidth + delta
                            sidebarWidth = min(max(newWidth, 280), 600)
                        }
                    }
                    .onEnded { _ in
                        dragStartSidebarWidth = nil
                        dragStartGlobalX = nil
                        isDraggingSidebar = false
                    }
            )
            
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
                                
                                Slider(value: $wallpaperController.draftSensitivity, in: 0.01...2.0) {
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
                                    Image(systemName: "waveform.path.ecg").foregroundStyle(.secondary)
                                }
                            }
                            
                            // MARK: - Smart Calibration Tools
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Smart Calibration")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                
                                // Quick Center Zero Button
                                Button(action: {
                                    withAnimation {
                                        sensor.calibrate()
                                        calibrationStatusMessage = "Angle calibrated as center zero!"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                            if calibrationStatusMessage == "Angle calibrated as center zero!" {
                                                calibrationStatusMessage = nil
                                            }
                                        }
                                    }
                                }) {
                                    Label("Set Angle as Center Zero", systemImage: "scope")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                
                                // Interactive Action Buttons: Deadzone Calibrate & Sensitivity Auto-Tune
                                HStack(spacing: 8) {
                                    // 1. Deadzone Calibrate Button
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            if isRecordingDeadzone {
                                                finishDeadzoneCalibration()
                                            } else {
                                                isRecordingSensitivity = false
                                                isRecordingDeadzone = true
                                                recordedDeadzonePeak = 0
                                                liveDeadzoneCurrent = 0
                                                calibrationStatusMessage = nil
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: isRecordingDeadzone ? "stop.circle.fill" : "record.circle")
                                                .foregroundStyle(isRecordingDeadzone ? .red : .blue)
                                            Text(isRecordingDeadzone ? "Done (Save)" : "Calibrate Deadzone")
                                                .fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(isRecordingDeadzone ? .red : .primary)
                                    
                                    // 2. Sensitivity & Smoothing Auto-Tune Button
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            if isRecordingSensitivity {
                                                finishSensitivityCalibration()
                                            } else {
                                                isRecordingDeadzone = false
                                                isRecordingSensitivity = true
                                                recordedTiltPeak = 0
                                                liveTiltCurrent = 0
                                                calibrationStatusMessage = nil
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: isRecordingSensitivity ? "stop.circle.fill" : "wand.and.stars")
                                                .foregroundStyle(isRecordingSensitivity ? .orange : .purple)
                                            Text(isRecordingSensitivity ? "Done (Apply)" : "Auto-Tune Sensitivity")
                                                .fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(isRecordingSensitivity ? .orange : .primary)
                                }
                                
                                // Status / Feedback Message
                                if let msg = calibrationStatusMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption2)
                                        Text(msg)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                // Live Deadzone Recording Panel
                                if isRecordingDeadzone {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 7, height: 7)
                                                Text("RECORDING MINIMUM THRESHOLD")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.red)
                                            }
                                            Spacer()
                                            Button("Cancel") {
                                                withAnimation { isRecordingDeadzone = false }
                                            }
                                            .font(.caption2)
                                            .buttonStyle(.plain)
                                            .foregroundStyle(.secondary)
                                        }
                                        
                                        Text("Tilt your Mac slightly to the minimum angle where parallax should activate, or leave it resting on your desk to filter typing vibrations.")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        // Live Metrics
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Current Tilt")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                Text(String(format: "%.0f", liveDeadzoneCurrent))
                                                    .font(.system(.subheadline, design: .monospaced).bold())
                                            }
                                            
                                            Divider().frame(height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Peak Detected")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                Text(String(format: "%.0f", recordedDeadzonePeak))
                                                    .font(.system(.subheadline, design: .monospaced).bold())
                                                    .foregroundStyle(.blue)
                                            }
                                            
                                            Spacer()
                                            
                                            Button("Set to Peak") {
                                                withAnimation { finishDeadzoneCalibration() }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                        }
                                        
                                        // Progress Bar
                                        GeometryReader { barGeo in
                                            let pct = min(1.0, max(0.0, recordedDeadzonePeak / 16000.0))
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.secondary.opacity(0.2))
                                                    .frame(height: 6)
                                                Capsule()
                                                    .fill(Color.blue)
                                                    .frame(width: max(6, barGeo.size.width * pct), height: 6)
                                            }
                                        }
                                        .frame(height: 6)
                                    }
                                    .padding(10)
                                    .background(Color(nsColor: .windowBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                // Live Sensitivity Auto-Tune Panel
                                if isRecordingSensitivity {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(Color.orange)
                                                    .frame(width: 7, height: 7)
                                                Text("MEASURING NATURAL TILT RANGE")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.orange)
                                            }
                                            Spacer()
                                            Button("Cancel") {
                                                withAnimation { isRecordingSensitivity = false }
                                            }
                                            .font(.caption2)
                                            .buttonStyle(.plain)
                                            .foregroundStyle(.secondary)
                                        }
                                        
                                        Text("Tilt your Mac comfortably in all directions (left, right, back, forward) to your natural maximum angle.")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        let recommendedSens = calculateRecommendedSensitivity(peakTilt: recordedTiltPeak)
                                        
                                        // Live Metrics
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Current Angle")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                Text(String(format: "%.0f", liveTiltCurrent))
                                                    .font(.system(.subheadline, design: .monospaced).bold())
                                            }
                                            
                                            Divider().frame(height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Max Range")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                Text(String(format: "%.0f", recordedTiltPeak))
                                                    .font(.system(.subheadline, design: .monospaced).bold())
                                            }
                                            
                                            Divider().frame(height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Recommended")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                Text(String(format: "%.2fx", recommendedSens))
                                                    .font(.system(.subheadline, design: .monospaced).bold())
                                                    .foregroundStyle(.purple)
                                            }
                                            
                                            Spacer()
                                            
                                            Button("Apply") {
                                                withAnimation { finishSensitivityCalibration() }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                            .tint(.purple)
                                        }
                                        
                                        // Progress Bar
                                        GeometryReader { barGeo in
                                            let pct = min(1.0, max(0.0, recordedTiltPeak / 16000.0))
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.secondary.opacity(0.2))
                                                    .frame(height: 6)
                                                Capsule()
                                                    .fill(Color.purple)
                                                    .frame(width: max(6, barGeo.size.width * pct), height: 6)
                                            }
                                        }
                                        .frame(height: 6)
                                    }
                                    .padding(10)
                                    .background(Color(nsColor: .windowBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            
                            // MARK: - Smart Performance & Tuning (Dev / Debug Mode)
                            DisclosureGroup(isExpanded: $showingPerformancePanel) {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Live Engine Status
                                    HStack {
                                        Text("Engine Status")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(sensor.engineState == .active ? Color.green : (sensor.engineState == .resting ? Color.blue : Color.orange))
                                                .frame(width: 7, height: 7)
                                            Text(sensor.engineState.badgeTitle)
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(sensor.engineState == .active ? .green : (sensor.engineState == .resting ? .blue : .orange))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    (sensor.engineState == .active ? Color.green : (sensor.engineState == .resting ? Color.blue : Color.orange)).opacity(0.12)
                                                )
                                        )
                                    }
                                    
                                    // Sampling Rate Slider
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Sampling Rate")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(Int(sensor.targetSamplingRate)) Hz")
                                                .font(.caption)
                                                .monospacedDigit()
                                                .fontWeight(.bold)
                                                .foregroundStyle(.secondary)
                                        }
                                        Slider(value: $sensor.targetSamplingRate, in: 5.0...100.0, step: 1.0) {
                                            Text("Sampling Rate")
                                        } minimumValueLabel: {
                                            Text("5Hz").font(.caption2).foregroundStyle(.secondary)
                                        } maximumValueLabel: {
                                            Text("100Hz").font(.caption2).foregroundStyle(.secondary)
                                        }
                                        Text("GPU spring curve keeps motion buttery-smooth even at 15Hz–30Hz")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    // Idle Noise Deadzone Slider
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Desk Rest Deadzone")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text(String(format: "%.0f", sensor.idleDeadzone))
                                                .font(.caption)
                                                .monospacedDigit()
                                                .fontWeight(.bold)
                                                .foregroundStyle(.secondary)
                                        }
                                        Slider(value: $sensor.idleDeadzone, in: 5.0...16000.0, step: 25.0) {
                                            Text("Deadzone")
                                        } minimumValueLabel: {
                                            Text("5").font(.caption2).foregroundStyle(.secondary)
                                        } maximumValueLabel: {
                                            Text("16k").font(.caption2).foregroundStyle(.secondary)
                                        }
                                        Text("Set higher (e.g. 500–2500) so resting on desk or lap completely zeros out all motion & GPU")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    // Reset to Recommended Defaults
                                    Button {
                                        withAnimation {
                                            sensor.resetPerformanceDefaults()
                                        }
                                    } label: {
                                        Label("Reset to Recommended", systemImage: "arrow.counterclockwise")
                                            .font(.caption)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.top, 8)
                            } label: {
                                HStack(spacing: 6) {
                                    Label("Engine & Performance", systemImage: "gauge.with.dots.needle.bottom.50percent")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(Int(sensor.targetSamplingRate))Hz • \(sensor.engineState == .resting ? "0% CPU" : sensor.engineState.rawValue)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                            }
                            
                            if !wallpaperController.draftLayers.isEmpty || wallpaperController.canUndo {
                                HStack(spacing: 8) {
                                    if !wallpaperController.draftLayers.isEmpty {
                                        Button {
                                            withAnimation {
                                                wallpaperController.autoDistributeDepths()
                                            }
                                        } label: {
                                            Label("Auto Depths", systemImage: "wand.and.stars")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.regular)
                                    }
                                    
                                    Spacer()
                                    
                                    if wallpaperController.canUndo {
                                        Button {
                                            withAnimation {
                                                wallpaperController.undo()
                                            }
                                        } label: {
                                            Label("Undo", systemImage: "arrow.uturn.backward")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.regular)
                                    }
                                    
                                    if !wallpaperController.draftLayers.isEmpty {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                wallpaperController.clearLayers()
                                                selectedLayerId = nil
                                            }
                                        } label: {
                                            Label("Clear All", systemImage: "trash")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                        .controlSize(.regular)
                                    }
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
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
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
            .frame(width: sidebarWidth)
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
        .onReceive(sensor.rotationPublisher) { rot in
            if isRecordingDeadzone {
                let deltaX = abs(rot.x - sensor.baseRotation.x)
                let deltaY = abs(rot.y - sensor.baseRotation.y)
                let currentDist = sqrt(deltaX * deltaX + deltaY * deltaY)
                liveDeadzoneCurrent = currentDist
                if currentDist > recordedDeadzonePeak {
                    recordedDeadzonePeak = currentDist
                }
            } else if isRecordingSensitivity {
                let deltaX = abs(rot.x - sensor.baseRotation.x)
                let deltaY = abs(rot.y - sensor.baseRotation.y)
                let currentDist = sqrt(deltaX * deltaX + deltaY * deltaY)
                liveTiltCurrent = currentDist
                if currentDist > recordedTiltPeak {
                    recordedTiltPeak = currentDist
                }
            }
        }
    }
    
    // MARK: - Smart Calibration Logic
    
    private func finishDeadzoneCalibration() {
        isRecordingDeadzone = false
        let targetDeadzone: Double
        if recordedDeadzonePeak < 25 {
            targetDeadzone = 50.0
        } else {
            targetDeadzone = min(16000.0, max(25.0, (recordedDeadzonePeak * 1.1).rounded()))
        }
        sensor.idleDeadzone = targetDeadzone
        calibrationStatusMessage = "Deadzone calibrated to \(Int(targetDeadzone)) units!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if calibrationStatusMessage?.starts(with: "Deadzone") == true {
                calibrationStatusMessage = nil
            }
        }
    }
    
    private func calculateRecommendedSensitivity(peakTilt: Double) -> Double {
        guard peakTilt > 100 else { return 0.50 }
        let raw = 35000.0 / peakTilt
        return max(0.10, min(2.0, (raw * 100).rounded() / 100))
    }
    
    private func finishSensitivityCalibration() {
        isRecordingSensitivity = false
        let recommended = calculateRecommendedSensitivity(peakTilt: recordedTiltPeak)
        wallpaperController.draftSensitivity = recommended
        sensor.userSmoothing = 0.50
        calibrationStatusMessage = "Sensitivity tuned to \(String(format: "%.2fx", recommended))!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if calibrationStatusMessage?.starts(with: "Sensitivity") == true {
                calibrationStatusMessage = nil
            }
        }
    }
    
    @ViewBuilder
    private var previewCanvasView: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            
            // Isolated Live Telemetry Bar: Never invalidates parent MultiLayerEditorView body!
            LiveTelemetryBarView(sensor: sensor, sensitivity: wallpaperController.draftSensitivity)
            
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
                    .padding(20)
                }
            }
            
            // Save Collection Button (Positioned cleanly at bottom-left below the preview window)
            HStack {
                Button {
                    collectionNameInput = "My Scene \(collectionManager.collections.count + 1)"
                    showingSaveModal = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(Color.yellow)
                        Text("Save Collection")
                            .foregroundStyle(.primary)
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 4)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }
}
