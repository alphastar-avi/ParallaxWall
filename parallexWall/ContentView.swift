import SwiftUI

struct ContentView: View {
    @StateObject private var sensor = SensorManager()
    @StateObject private var wallpaperController = WallpaperController()
    
    var body: some View {
        MultiLayerEditorView(sensor: sensor, wallpaperController: wallpaperController)
            .frame(minWidth: 840, minHeight: 640)
    }
}

#Preview {
    ContentView()
}
