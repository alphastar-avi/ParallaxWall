import SwiftUI

struct ParallaxView: View {
    let image: NSImage?
    @ObservedObject var sensor: SensorManager
    @ObservedObject var controller: WallpaperController
    
    // Configurable parameters
    let smoothing: Double = 0.1
    let scaleEffect: CGFloat = 1.1 // Image scaled up to allow for movement
    
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
                        .animation(.interactiveSpring(), value: currentOffset)
                } else {
                    Color.black
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onReceive(sensor.$rotation) { rotation in
            // Calculate target offset based on X and Y (Roll and Pitch)
            // Sensor values on M1/M2 are raw, need to be normalized
            // Let's assume the center is 0.0 and max tilt is +/- 16000
            
            let baseScale = 0.000001
            let targetX = -rotation.x * baseScale * controller.sensitivity 
            let targetY = rotation.y * baseScale * controller.sensitivity
            
            // Limit the offset to prevent seeing the edges
            let maxOffsetH = (scaleEffect - 1.0) * NSScreen.main!.frame.width / 2
            let maxOffsetV = (scaleEffect - 1.0) * NSScreen.main!.frame.height / 2
            
            let clampedX = max(min(targetX, maxOffsetH), -maxOffsetH)
            let clampedY = max(min(targetY, maxOffsetV), -maxOffsetV)
            
            currentOffset = CGSize(width: clampedX, height: clampedY)
        }
    }
}
