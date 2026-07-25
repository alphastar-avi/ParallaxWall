import SwiftUI

struct MultiLayerParallaxView: View {
    let layers: [ParallaxLayer]
    @ObservedObject var sensor: SensorManager
    let sensitivity: Double
    
    @State private var rawOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if layers.isEmpty {
                    Color.black
                } else {
                    ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                        if layer.isVisible, let nsImage = layer.image {
                            // Compute layer-specific offset based on its depthFactor
                            let targetX = rawOffset.width * layer.depthFactor + layer.offsetX
                            let targetY = rawOffset.height * layer.depthFactor + layer.offsetY
                            
                            // Limit max offset to prevent viewing past edge of image crop
                            let screenWidth = geo.size.width > 0 ? geo.size.width : (NSScreen.main?.frame.width ?? 1920)
                            let screenHeight = geo.size.height > 0 ? geo.size.height : (NSScreen.main?.frame.height ?? 1080)
                            
                            let maxOffsetH = max(0, (layer.scaleEffect - 1.0) * screenWidth / 2)
                            let maxOffsetV = max(0, (layer.scaleEffect - 1.0) * screenHeight / 2)
                            
                            let clampedX = max(min(targetX, maxOffsetH), -maxOffsetH)
                            let clampedY = max(min(targetY, maxOffsetV), -maxOffsetV)
                            
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(layer.scaleEffect)
                                .opacity(layer.opacity)
                                .offset(x: clampedX, y: clampedY)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onReceive(sensor.$rotation) { rotation in
            let currentX = rotation.x - sensor.baseRotation.x
            let currentY = rotation.y - sensor.baseRotation.y
            
            let baseScale = 0.005
            let targetX = -currentX * baseScale * sensitivity
            let targetY = currentY * baseScale * sensitivity
            
            rawOffset = CGSize(width: targetX, height: targetY)
        }
    }
}
