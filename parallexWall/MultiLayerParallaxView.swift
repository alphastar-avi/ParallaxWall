import SwiftUI
import Combine

struct MultiLayerParallaxView: View {
    let layers: [ParallaxLayer]
    @ObservedObject var sensor: SensorManager = SensorManager()
    let sensitivity: Double
    var isStatic: Bool = false
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
            let canvasWidth = geo.size.width > 0 ? geo.size.width : (NSScreen.main?.frame.width ?? 1920)
            let canvasHeight = geo.size.height > 0 ? geo.size.height : (NSScreen.main?.frame.height ?? 1080)
            let refWidth = NSScreen.main?.frame.width ?? 1920
            let refHeight = NSScreen.main?.frame.height ?? 1080
            
            let scaleFactor = refWidth > 0 ? (canvasWidth / refWidth) : 1.0
            
            ZStack {
                if layers.isEmpty {
                    Color.black
                } else {
                    ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                        if layer.isVisible, let nsImage = layer.image {
                            let scaledOffsetX = layer.offsetX * scaleFactor
                            let scaledOffsetY = layer.offsetY * scaleFactor
                            
                            let targetX = rawOffset.width * layer.depthFactor * scaleFactor + scaledOffsetX
                            let targetY = rawOffset.height * layer.depthFactor * scaleFactor + scaledOffsetY
                            
                            let isBackground = (index == 0)
                            let effectiveScale = isBackground ? max(1.15, layer.scaleEffect) : layer.scaleEffect
                            
                            let offsets: (x: Double, y: Double) = {
                                if isBackground {
                                    let maxOffsetH = max(0, (effectiveScale - 1.0) * canvasWidth / 2)
                                    let maxOffsetV = max(0, (effectiveScale - 1.0) * canvasHeight / 2)
                                    let cX = max(min(targetX, maxOffsetH), -maxOffsetH)
                                    let cY = max(min(targetY, maxOffsetV), -maxOffsetV)
                                    return (x: cX, y: cY)
                                } else {
                                    let maxOffsetH = effectiveScale >= 1.0 ?
                                        max(canvasWidth * 0.25, (effectiveScale - 1.0) * canvasWidth / 2) :
                                        canvasWidth * 0.4
                                    let maxOffsetV = effectiveScale >= 1.0 ?
                                        max(canvasHeight * 0.25, (effectiveScale - 1.0) * canvasHeight / 2) :
                                        canvasHeight * 0.4
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
                                .zIndex(isSelected ? 100 : Double(index))
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
                                                                let deltaX = value.translation.width / scaleFactor
                                                                let deltaY = value.translation.height / scaleFactor
                                                                let newX = dragInitialOffsetX + deltaX
                                                                let newY = dragInitialOffsetY + deltaY
                                                                onLayerPositionChanged?(layer.id, newX, newY)
                                                            }
                                                            .onEnded { _ in
                                                                dragInitialOffsetX = 0
                                                                dragInitialOffsetY = 0
                                                            }
                                                    )
                                                
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
        .onReceive(sensor.rotationPublisher) { rotation in
            guard !isStatic else { return }
            let currentX = rotation.x - sensor.baseRotation.x
            let currentY = rotation.y - sensor.baseRotation.y
            
            let baseScale = 0.005
            let targetX = -currentX * baseScale * sensitivity
            let targetY = currentY * baseScale * sensitivity
            
            let newWidth = targetX.rounded()
            let newHeight = targetY.rounded()
            
            if abs(newWidth - rawOffset.width) >= 0.5 || abs(newHeight - rawOffset.height) >= 0.5 {
                let interval = 1.0 / max(5.0, min(100.0, sensor.targetSamplingRate))
                let springResponse = max(0.32, interval * 1.6)
                withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.85, blendDuration: 0.15)) {
                    rawOffset = CGSize(width: newWidth, height: newHeight)
                }
            }
        }
    }
}
