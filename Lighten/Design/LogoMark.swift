import SwiftUI

/// The Lighten mark: a light bulb with an L, on an orange-to-yellow
/// gradient. The same drawing as the app icon (Resources/AppIcon.icon).
struct LogoMark: View {
    var size: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.22)
            .fill(LinearGradient(
                colors: [
                    Color(.displayP3, red: 1, green: 0.3294, blue: 0.1686),
                    Color(.displayP3, red: 1, green: 0.7373, blue: 0.1961),
                ],
                startPoint: .top, endPoint: .bottom))
            .overlay(Image("LogoGlyph").resizable().scaledToFit())
            .frame(width: size, height: size)
            .accessibilityLabel(Strings.brand)
    }
}
