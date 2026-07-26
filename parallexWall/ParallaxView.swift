import SwiftUI

struct ParallaxView: View {
    let image: NSImage?
    @ObservedObject var sensor: SensorManager
    @ObservedObject var controller: WallpaperController
    
    // Configurable parameters
    let scaleEffect: CGFloat = 1.2 // Crop margin to allow for larger parallax movement
    
    @State private var currentOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let nsImage = image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(scaleEffect)
                        .offset(currentOffset)
                } else {
                    Color.black
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onReceive(sensor.$rotation) { rotation in
            let currentX = rotation.x - sensor.baseRotation.x
            let currentY = rotation.y - sensor.baseRotation.y
            
            let baseScale = 0.005
            let targetX = -currentX * baseScale * controller.appliedSensitivity 
            let targetY = currentY * baseScale * controller.appliedSensitivity
            
            let screenWidth = NSScreen.main?.frame.width ?? 1920
            let screenHeight = NSScreen.main?.frame.height ?? 1080
            
            let maxOffsetH = (scaleEffect - 1.0) * screenWidth / 2
            let maxOffsetV = (scaleEffect - 1.0) * screenHeight / 2
            
            let clampedX = max(min(targetX, maxOffsetH), -maxOffsetH)
            let clampedY = max(min(targetY, maxOffsetV), -maxOffsetV)
            
            currentOffset = CGSize(width: clampedX, height: clampedY)
        }
    }
}
