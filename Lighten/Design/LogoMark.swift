import SwiftUI

/// The Lighten mark: two speech bubbles and a light bulb on deep blue, the same
/// drawing as the app icon (Resources/AppIcon.icon).
struct LogoMark: View {
    var size: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.22)
            .fill(Color(.displayP3, red: 0.0808, green: 0.1526, blue: 0.2965))
            .overlay(
                Image("LogoGlyph")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.17)
            )
            .frame(width: size, height: size)
            .accessibilityLabel(Strings.brand)
    }
}
