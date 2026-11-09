import SwiftUI
import UIKit

/// The opening: the light comes on.
///
/// The screen starts as dark as the system launch screen (LaunchBackground),
/// so there is no flash between the two. A dim bulb flickers twice, like a
/// real one catching, then lights: the sunrise of the app icon spreads out of
/// it and fills the screen, the L cut out of the bulb glows with it, and the
/// name rises underneath. About 1.8 seconds, then `onFinish`.
///
/// Motion is springs only. Reduce Motion shows the lit state at once.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var bulbOpacity = 0.12
    @State private var bulbScale = 0.92
    @State private var lit = false
    @State private var glow = false
    @State private var showName = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let bulb = min(size.width, size.height) * 0.42
            let center = CGPoint(x: size.width / 2, y: size.height * 0.44)
            // The light has to reach the farthest corner from the bulb.
            let reach = 2 * hypot(max(center.x, size.width - center.x), max(center.y, size.height - center.y))

            ZStack {
                Palette.splashBackground

                // The light spreading out of the bulb: the icon's sunrise over the
                // whole screen, uncovered by a circle growing from the bulb.
                Rectangle()
                    .fill(Palette.action)
                    .mask(
                        Circle()
                            .frame(width: reach, height: reach)
                            .scaleEffect(lit ? 1 : 0.001)
                            .position(center)
                    )

                // A soft halo that breathes once as the bulb catches.
                Circle()
                    .fill(RadialGradient(
                        colors: [Palette.actionFrom.opacity(0.7), .clear],
                        center: .center, startRadius: 0, endRadius: bulb * 0.9))
                    .frame(width: bulb * 1.8, height: bulb * 1.8)
                    .scaleEffect(glow ? 1.15 : 0.6)
                    .opacity(glow ? 0 : 0.9)
                    .position(center)
                    .opacity(lit ? 1 : 0)

                Image("LogoGlyph")
                    .resizable()
                    .scaledToFit()
                    .frame(width: bulb, height: bulb)
                    .scaleEffect(bulbScale)
                    .opacity(bulbOpacity)
                    .position(center)

                Text(Strings.brand)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.onBright)
                    .opacity(showName ? 1 : 0)
                    .offset(y: showName ? 0 : 16)
                    .position(x: center.x, y: center.y + bulb * 0.62)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement()
        .accessibilityLabel(Strings.brand)
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            bulbOpacity = 1
            bulbScale = 1
            lit = true
            showName = true
            await pause(0.7)
            onFinish()
            return
        }

        await pause(0.25)
        // The filament catches: two flickers, instant, like a real bulb.
        for level in [0.55, 0.2, 0.8, 0.35] {
            bulbOpacity = level
            await pause(0.07)
        }

        // On.
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
            bulbOpacity = 1
            bulbScale = 1
        }
        withAnimation(.spring(response: 0.75, dampingFraction: 0.9)) { lit = true }
        withAnimation(.spring(response: 0.9, dampingFraction: 1)) { glow = true }

        await pause(0.35)
        withAnimation(Motion.soft) { showName = true }

        await pause(0.85)
        onFinish()
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}

#Preview {
    SplashView {}
}
