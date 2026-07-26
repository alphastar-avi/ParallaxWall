import SwiftUI

struct AppleMotionSourcePicker: View {
    @Binding var selection: MotionSource
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(MotionSource.allCases) { source in
                let isSelected = (selection == source)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selection = source
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: source.iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                        
                        Text(source.displayName)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(nsColor: .controlColor))
                                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                                .matchedGeometryEffect(id: "activeSourcePill", in: animationNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
