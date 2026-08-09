import SwiftUI

struct ContentView: View {
    @ObservedObject var sensor: SensorManager
    @ObservedObject var wallpaperController: WallpaperController
    @ObservedObject private var collectionManager = CollectionManager.shared
    
    @State private var selectedTab: AppTab = .parallax
    @State private var showStartAtLoginAlert = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .parallax:
                    MultiLayerEditorView(sensor: sensor, wallpaperController: wallpaperController)
                case .browse:
                    CollectionsGalleryView(
                        wallpaperController: wallpaperController,
                        sensor: sensor,
                        onSwitchToEditor: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTab = .parallax
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Requirement 3: Floating Apple-Style Bottom Navigation Bar
            AppleTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 16)
        }
        .frame(minWidth: 840, minHeight: 640)
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "hasPromptedStartAtLogin") {
                showStartAtLoginAlert = true
            }
        }
        .alert("Start Parallax Wallpaper at Login?", isPresented: $showStartAtLoginAlert) {
            Button("Enable Start at Login") {
                UserDefaults.standard.set(true, forKey: "hasPromptedStartAtLogin")
                LaunchAtLoginHelper.setEnabled(true)
            }
            Button("Don't Enable", role: .cancel) {
                UserDefaults.standard.set(true, forKey: "hasPromptedStartAtLogin")
            }
        } message: {
            Text("Would you like Parallax Wallpaper to launch automatically whenever you log in to your Mac?")
        }
    }
}

#Preview {
    ContentView(sensor: SensorManager(), wallpaperController: WallpaperController())
}
