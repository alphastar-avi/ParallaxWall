import SwiftUI

struct MultiLayerParallaxView: View {
    let layers: [ParallaxLayer]
    @ObservedObject var sensor: SensorManager
    let sensitivity: Double
    var selectedLayerId: UUID? = nil
    
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
                            
                            let screenWidth = geo.size.width > 0 ? geo.size.width : (NSScreen.main?.frame.width ?? 1920)
                            let screenHeight = geo.size.height > 0 ? geo.size.height : (NSScreen.main?.frame.height ?? 1080)
                            
                            // For layers scaled down (<1.0), allow generous parallax motion without freezing
                            let maxOffsetH = layer.scaleEffect >= 1.0 ?
                                max(screenWidth * 0.25, (layer.scaleEffect - 1.0) * screenWidth / 2) :
                                screenWidth * 0.4
                            let maxOffsetV = layer.scaleEffect >= 1.0 ?
                                max(screenHeight * 0.25, (layer.scaleEffect - 1.0) * screenHeight / 2) :
                                screenHeight * 0.4
                            
                            let clampedX = max(min(targetX, maxOffsetH), -maxOffsetH)
                            let clampedY = max(min(targetY, maxOffsetV), -maxOffsetV)
                            let isSelected = (selectedLayerId == layer.id)
                            
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(layer.scaleEffect)
                                .opacity(layer.opacity)
                                .offset(x: clampedX, y: clampedY)
                                .overlay(
                                    Group {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                                .scaleEffect(layer.scaleEffect * 0.98)
                                                .offset(x: clampedX, y: clampedY)
                                        }
                                    }
                                )
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
