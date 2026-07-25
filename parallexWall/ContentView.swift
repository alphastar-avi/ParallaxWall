//
//  ContentView.swift
//  parallexWall
//
//  Created by Avinash S on 3/22/26.
//

import SwiftUI

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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Tab Content
            Group {
                switch wallpaperController.selectedTab {
                case .single:
                    SingleImageEditorView(sensor: sensor, wallpaperController: wallpaperController)
                case .multiLayer:
                    MultiLayerEditorView(sensor: sensor, wallpaperController: wallpaperController)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Apple-Style Floating Bottom Navigation Bar
            AppleTabBar(selectedTab: $wallpaperController.selectedTab)
                .padding(.bottom, 20)
        }
        .frame(minWidth: 780, minHeight: 640)
    }
}

#Preview {
    ContentView()
}
