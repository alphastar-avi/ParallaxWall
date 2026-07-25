import SwiftUI

public enum ParallaxTab: String, CaseIterable, Identifiable {
    case single = "Single Image"
    case multiLayer = "Multi-Layer"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .single:
            return "photo.fill"
        case .multiLayer:
            return "square.3.layers.3d.down.right.fill"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .single:
            return "Classic 1-Image Parallax"
        case .multiLayer:
            return "N-Layer Depth Composition"
        }
    }
}

struct AppleTabBar: View {
    @Binding var selectedTab: ParallaxTab
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(ParallaxTab.allCases) { tab in
                let isSelected = (selectedTab == tab)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color(nsColor: .controlColor))
                                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                                .matchedGeometryEffect(id: "activeTabCapsule", in: animationNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        AppleTabBar(selectedTab: .constant(.multiLayer))
    }
    .frame(width: 500, height: 200)
}
