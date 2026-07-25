import SwiftUI
import UniformTypeIdentifiers

struct SingleImageEditorView: View {
    @ObservedObject var sensor: SensorManager
    @ObservedObject var wallpaperController: WallpaperController
    @State private var showingImagePicker = false
    
    // Computed Telemetry
    private var parallaxOffsetX: Double {
        let currentX = sensor.rotation.x - sensor.baseRotation.x
        return -currentX * 0.005 * wallpaperController.sensitivity
    }
    
    private var parallaxOffsetY: Double {
        let currentY = sensor.rotation.y - sensor.baseRotation.y
        return currentY * 0.005 * wallpaperController.sensitivity
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Side: Image Preview & Selection
            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                
                if let image = wallpaperController.singleImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
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
            
            // Right Side: Controls & Telemetry
            ScrollView {
                VStack(spacing: 32) {
                    
                    // App Header
                    VStack(spacing: 8) {
                        Text("Single Image Parallax")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Main Toggle
                    VStack(spacing: 16) {
                        Image(systemName: wallpaperController.isEnabled && wallpaperController.selectedTab == .single ? "checkmark.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(wallpaperController.isEnabled && wallpaperController.selectedTab == .single ? .green : .orange)
                            .symbolEffect(.bounce, value: wallpaperController.isEnabled)
                            
                        Text(wallpaperController.isEnabled && wallpaperController.selectedTab == .single ? "Actively running in background." : "Wallpaper is currently paused.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            wallpaperController.toggle(sensor: sensor)
                        }) {
                            Text(wallpaperController.isEnabled ? "Deactivate Wallpaper" : "Activate Wallpaper")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(wallpaperController.isEnabled ? .red : .blue)
                        .disabled(wallpaperController.singleImage == nil)
                        .controlSize(.large)
                    }
                    
                    Divider()
                    
                    // Parallax Settings
                    VStack(alignment: .leading, spacing: 20) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Motion Sensitivity")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Slider(value: $wallpaperController.sensitivity, in: 0.01...1.0) {
                                Text("Sensitivity")
                            } minimumValueLabel: {
                                Image(systemName: "tortoise")
                                    .foregroundStyle(.secondary)
                            } maximumValueLabel: {
                                Image(systemName: "hare")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(action: {
                            withAnimation {
                                sensor.calibrate()
                            }
                        }) {
                            Label("Set Current Angle as Center", systemImage: "scope")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    
                    Divider()
                    
                    // Live Telemetry Output
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Live Telemetry", systemImage: "bolt.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            TelemetryBox(title: "Horizontal", value: parallaxOffsetX)
                            TelemetryBox(title: "Vertical", value: parallaxOffsetY)
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
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
                if let url = urls.first {
                    if let image = NSImage(contentsOf: url) {
                        wallpaperController.singleImage = image
                    }
                }
            case .failure(let error):
                print("Error picking image: \(error)")
            }
        }
    }
}
