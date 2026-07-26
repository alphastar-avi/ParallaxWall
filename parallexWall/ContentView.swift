import SwiftUI

struct ContentView: View {
    @StateObject private var sensor = SensorManager()
    @StateObject private var wallpaperController = WallpaperController()
    @StateObject private var collectionManager = CollectionManager.shared
    
    @State private var selectedTab: AppTab = .parallax
    
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
    }
}

#Preview {
    ContentView()
}
