import SwiftUI

struct MultiLayerParallaxView: View {
    let layers: [ParallaxLayer]
    @ObservedObject var sensor: SensorManager
    let sensitivity: Double
    var selectedLayerId: UUID? = nil
    
    // Optional callbacks for canvas mouse drag actions
    var onLayerPositionChanged: ((UUID, Double, Double) -> Void)? = nil
    var onLayerScaleChanged: ((UUID, CGFloat) -> Void)? = nil
    
    @State private var rawOffset: CGSize = .zero
    @State private var dragInitialOffsetX: Double = 0
    @State private var dragInitialOffsetY: Double = 0
    @State private var dragInitialScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if layers.isEmpty {
                    Color.black
                } else {
                    ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                        if layer.isVisible, let nsImage = layer.image {
                            let targetX = rawOffset.width * layer.depthFactor + layer.offsetX
                            let targetY = rawOffset.height * layer.depthFactor + layer.offsetY
                            
                            let screenWidth = geo.size.width > 0 ? geo.size.width : (NSScreen.main?.frame.width ?? 1920)
                            let screenHeight = geo.size.height > 0 ? geo.size.height : (NSScreen.main?.frame.height ?? 1080)
                            
                            let isBackground = (index == 0)
                            let effectiveScale = isBackground ? max(1.15, layer.scaleEffect) : layer.scaleEffect
                            
                            // User Directive: Strict edge bounds and .fill aspect ratio for background layer (index 0) only
                            let offsets: (x: Double, y: Double) = {
                                if isBackground {
                                    let maxOffsetH = max(0, (effectiveScale - 1.0) * screenWidth / 2)
                                    let maxOffsetV = max(0, (effectiveScale - 1.0) * screenHeight / 2)
                                    let cX = max(min(targetX, maxOffsetH), -maxOffsetH)
                                    let cY = max(min(targetY, maxOffsetV), -maxOffsetV)
                                    return (x: cX, y: cY)
                                } else {
                                    let maxOffsetH = effectiveScale >= 1.0 ?
                                        max(screenWidth * 0.25, (effectiveScale - 1.0) * screenWidth / 2) :
                                        screenWidth * 0.4
                                    let maxOffsetV = effectiveScale >= 1.0 ?
                                        max(screenHeight * 0.25, (effectiveScale - 1.0) * screenHeight / 2) :
                                        screenHeight * 0.4
                                    let cX = max(min(targetX, maxOffsetH), -maxOffsetH)
                                    let cY = max(min(targetY, maxOffsetV), -maxOffsetV)
                                    return (x: cX, y: cY)
                                }
                            }()
                            
                            let clampedX = offsets.x
                            let clampedY = offsets.y
                            let isSelected = (selectedLayerId == layer.id)
                            
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: isBackground ? .fill : .fit)
                                .scaleEffect(effectiveScale)
                                .opacity(layer.opacity)
                                .offset(x: clampedX, y: clampedY)
                                .overlay(
                                    Group {
                                        if isSelected {
                                            ZStack(alignment: .topTrailing) {
                                                // Canvas Position Move Selection Outline
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                                    .contentShape(Rectangle())
                                                    .gesture(
                                                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
                                                            .onChanged { value in
                                                                if dragInitialOffsetX == 0 && dragInitialOffsetY == 0 {
                                                                    dragInitialOffsetX = layer.offsetX
                                                                    dragInitialOffsetY = layer.offsetY
                                                                }
                                                                let newX = dragInitialOffsetX + value.translation.width
                                                                let newY = dragInitialOffsetY + value.translation.height
                                                                onLayerPositionChanged?(layer.id, newX, newY)
                                                            }
                                                            .onEnded { _ in
                                                                dragInitialOffsetX = 0
                                                                dragInitialOffsetY = 0
                                                            }
                                                    )
                                                
                                                // Requirement 2: Directional Handle Scale Drag (Up = Scale Up, Down = Scale Down)
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 20, height: 20)
                                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                                                    .contentShape(Circle())
                                                    .offset(x: 10, y: -10)
                                                    .gesture(
                                                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
                                                            .onChanged { value in
                                                                if dragInitialScale == 1.0 {
                                                                    dragInitialScale = effectiveScale
                                                                }
                                                                // Dragging UP (negative translation.height) scales UP
                                                                // Dragging DOWN (positive translation.height) scales DOWN
                                                                let scaleDelta = -value.translation.height / 150.0
                                                                let newScale = max(0.15, min(3.0, dragInitialScale + scaleDelta))
                                                                onLayerScaleChanged?(layer.id, newScale)
                                                            }
                                                            .onEnded { _ in
                                                                dragInitialScale = 1.0
                                                            }
                                                    )
                                            }
                                            .scaleEffect(effectiveScale * 0.98)
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
