import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable {
    case parallax = "Parallax"
    case browse = "Browse Collections"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .parallax:
            return "square.3.layers.3d.down.right"
        case .browse:
            return "rectangle.grid.2x2.fill"
        }
    }
}

struct AppleTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabNamespace
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = (selectedTab == tab)
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
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
                                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)
                                .matchedGeometryEffect(id: "activeAppTabPill", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
