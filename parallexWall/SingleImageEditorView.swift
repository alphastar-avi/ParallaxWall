import SwiftUI
import UniformTypeIdentifiers

struct SingleImageEditorView: View {
    @ObservedObject var sensor: SensorManager
    @ObservedObject var wallpaperController: WallpaperController
    @State private var showingImagePicker = false
    
    // Computed Telemetry
    private var parallaxOffsetX: Double {
        let currentX = sensor.rotation.x - sensor.baseRotation.x
        return -currentX * 0.005 * wallpaperController.draftSensitivity
    }
    
    private var parallaxOffsetY: Double {
        let currentY = sensor.rotation.y - sensor.baseRotation.y
        return currentY * 0.005 * wallpaperController.draftSensitivity
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Side: Fitted Preview Canvas
            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                
                if let image = wallpaperController.draftSingleImage {
                    DesktopMonitorFrame {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .padding(32)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(.tertiary)
                        
                        Text("No Background Selected")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text("Click anywhere to choose a high-resolution image")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                showingImagePicker = true
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: { showingImagePicker = true }) {
                    Label("Change Image", systemImage: "photo")
                        .padding(8)
                        .background(Material.ultraThin)
                        .cornerRadius(8)
                }
                .padding(20)
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // MARK: - Right Side: Control Sidebar
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Header & Main Activation Toggle
                        VStack(spacing: 12) {
                            Text("Single Image Parallax")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Image(systemName: wallpaperController.isEnabled && wallpaperController.selectedTab == .single ? "checkmark.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(wallpaperController.isEnabled && wallpaperController.selectedTab == .single ? .green : .orange)
                            
                            Text(wallpaperController.isEnabled && wallpaperController.selectedTab == .single ? "Actively running in background." : "Wallpaper is currently paused.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                wallpaperController.toggle(sensor: sensor)
                            }) {
                                Text(wallpaperController.isEnabled ? "Deactivate Wallpaper" : "Activate Wallpaper")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(wallpaperController.isEnabled ? .red : .blue)
                            .disabled(wallpaperController.draftSingleImage == nil)
                            .controlSize(.large)
                        }
                        
                        Divider()
                        
                        // MARK: - Global Settings & Motion Sources
                        VStack(alignment: .leading, spacing: 18) {
                            Label("Settings", systemImage: "slider.horizontal.3")
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
                            VStack(alignment: .leading, spacing: 6) {
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
                            VStack(alignment: .leading, spacing: 6) {
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
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Divider()
                        
                        // Live Telemetry Output
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Live Telemetry", systemImage: "bolt.fill")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                TelemetryBox(title: "Horizontal", value: parallaxOffsetX)
                                TelemetryBox(title: "Vertical", value: parallaxOffsetY)
                            }
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
            .frame(width: 340)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, let image = NSImage(contentsOf: url) {
                    wallpaperController.draftSingleImage = image
                }
            case .failure(let error):
                print("Error picking image: \(error)")
            }
        }
    }
}
