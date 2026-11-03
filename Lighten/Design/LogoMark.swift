import SwiftUI

/// The Lighten mark, concept A from docs/brand: a lowercase l with light at
/// its tip. Provisional until the owner picks a concept.
struct LogoMark: View {
    var size: CGFloat = 64

    var body: some View {
        let unit = size / 1024
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22).fill(Palette.onBright)
            Circle().fill(Palette.yellow.opacity(0.16)).frame(width: 380 * unit)
                .position(x: 512 * unit, y: 300 * unit)
            Circle().fill(Palette.yellow.opacity(0.32)).frame(width: 256 * unit)
                .position(x: 512 * unit, y: 300 * unit)
            Circle().fill(Palette.yellow).frame(width: 164 * unit)
                .position(x: 512 * unit, y: 300 * unit)
            Capsule().fill(Color(hex: 0xEDF0FA)).frame(width: 112 * unit, height: 420 * unit)
                .position(x: 512 * unit, y: 640 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Strings.brand)
    }
}
