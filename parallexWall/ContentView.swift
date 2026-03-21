//
//  ContentView.swift
//  parallexWall
//
//  Created by Avinash S on 3/22/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var sensor = SensorManager()
    @StateObject private var wallpaperController = WallpaperController()
    @State private var selectedImage: NSImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Parallax Wallpaper")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Image Preview/Selection
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 200)
                
                if let image = selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .frame(maxHeight: 180)
                } else {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Image Selected")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onTapGesture {
                showingImagePicker = true
            }
            
            Button(action: { showingImagePicker = true }) {
                Label("Choose Background", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            
            // Sensor Status
            GroupBox(label: Label("Sensor Status", systemImage: "bolt.fill")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("X:")
                        Text(String(format: "%.0f", sensor.rotation.x))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Y:")
                        Text(String(format: "%.0f", sensor.rotation.y))
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            
            // Control
            Button(action: {
                wallpaperController.toggle(image: selectedImage, sensor: sensor)
            }) {
                Text(wallpaperController.isEnabled ? "Deactivate Wallpaper" : "Set as Wallpaper")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
            .buttonStyle(.borderedProminent)
            .tint(wallpaperController.isEnabled ? .red : .blue)
            .disabled(selectedImage == nil)
        }
        .padding(32)
        .frame(width: 400)
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
