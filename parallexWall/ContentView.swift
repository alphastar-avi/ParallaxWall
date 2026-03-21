//
//  ContentView.swift
//  parallexWall
//
//  Created by Avinash S on 3/22/26.
//

import SwiftUI
import UniformTypeIdentifiers

// Telemetry Box sub-component
struct TelemetryBox: View {
    let title: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.system(.title2, design: .monospaced).bold())
                Text("px")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
    }
}

struct ContentView: View {
    @StateObject private var sensor = SensorManager()
    @StateObject private var wallpaperController = WallpaperController()
    @State private var selectedImage: NSImage?
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
                
                if let image = selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
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
                .padding()
                .buttonStyle(.plain) // Simple custom button look for overlay
            }
            
            Divider()
            
            // Right Side: Controls & Telemetry
            ScrollView {
                VStack(spacing: 32) {
                    
                    // App Header
                    VStack(spacing: 8) {
                        Image(systemName: "move.3d")
                            .font(.system(size: 56, weight: .thin))
                            .foregroundStyle(.blue)
                        
                        Text("Parallax Desktop")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 16)
                    
                    Divider()
                    
                    // Main Toggle
                    VStack(spacing: 16) {
                        Image(systemName: wallpaperController.isEnabled ? "checkmark.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(wallpaperController.isEnabled ? .green : .orange)
                            .symbolEffect(.bounce, value: wallpaperController.isEnabled)
                            
                        Text(wallpaperController.isEnabled ? "Actively running in background." : "Wallpaper is currently paused.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            wallpaperController.toggle(image: selectedImage, sensor: sensor)
                        }) {
                            Text(wallpaperController.isEnabled ? "Deactivate Wallpaper" : "Activate Wallpaper")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(wallpaperController.isEnabled ? .red : .blue)
                        .disabled(selectedImage == nil)
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
        .frame(minWidth: 700, minHeight: 600)
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    if let image = NSImage(contentsOf: url) {
                        self.selectedImage = image
                    }
                }
            case .failure(let error):
                print("Error picking image: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
