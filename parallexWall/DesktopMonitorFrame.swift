import SwiftUI

struct DesktopMonitorFrame<Content: View>: View {
    let content: Content
    
    private var screenAspectRatio: CGFloat {
        if let mainScreen = NSScreen.main {
            let w = mainScreen.frame.width
            let h = mainScreen.frame.height
            if w > 0 && h > 0 {
                return w / h
            }
        }
        return 16.0 / 10.0
    }
    
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
                .aspectRatio(screenAspectRatio, contentMode: .fit)
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
