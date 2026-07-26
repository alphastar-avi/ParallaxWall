import SwiftUI

struct DesktopMonitorFrame<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Monitor Bezel & Screen
                ZStack {
                    Color.black
                    content
                }
                .aspectRatio(16/10, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 7)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
