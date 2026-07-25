import Foundation
import AppKit
import SwiftUI

public struct ParallaxLayer: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var image: NSImage?
    public var depthFactor: Double // 0.0 = static background, 1.0 = standard, 2.0+ = strong foreground movement
    public var scaleEffect: CGFloat // Zoom factor to allow parallax movement without edge clipping
    public var opacity: Double
    public var isVisible: Bool
    public var offsetX: Double
    public var offsetY: Double
    
    public init(
        id: UUID = UUID(),
        name: String,
        image: NSImage? = nil,
        depthFactor: Double = 1.0,
        scaleEffect: CGFloat = 1.2,
        opacity: Double = 1.0,
        isVisible: Bool = true,
        offsetX: Double = 0.0,
        offsetY: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.depthFactor = depthFactor
        self.scaleEffect = scaleEffect
        self.opacity = opacity
        self.isVisible = isVisible
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
    
    public static func == (lhs: ParallaxLayer, rhs: ParallaxLayer) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.depthFactor == rhs.depthFactor &&
            lhs.scaleEffect == rhs.scaleEffect &&
            lhs.opacity == rhs.opacity &&
            lhs.isVisible == rhs.isVisible &&
            lhs.offsetX == rhs.offsetX &&
            lhs.offsetY == rhs.offsetY &&
            lhs.image === rhs.image
    }
}
