import SwiftUI
import UIKit

/// Colors from packages/ui/src/tokens.css. One color for one role; no colors
/// outside this list.
///
/// Text on a bright fill is always `onBright` (it does not change between
/// themes). White text on green, blue, rose or the action gradient fails
/// contrast: never use it.
enum Palette {
    /// The main action: the app icon's sunrise, yellow at the bottom to
    /// red-orange at the top (decision of 9 November). The only gradient in
    /// the system, and only on the primary button. Its label is `onBright`:
    /// 4.7:1 at the red end, 9.6:1 at the yellow; white fails.
    static let actionFrom = Color(hex: 0xFFB800)   // bottom
    static let actionTo = Color(hex: 0xFF3F00)     // top
    static let actionDeep = Color(hex: 0xD97706)   // thickness under the action button
    static let action = LinearGradient(colors: [actionTo, actionFrom], startPoint: .top, endPoint: .bottom)

    /// The dark behind the splash, the same as the system launch screen
    /// (Assets: LaunchBackground), so the two meet without a flash.
    static let splashBackground = Color("LaunchBackground")

    static let green = Color(hex: 0x2FBF71)       // correct answer, progress. Not an action
    static let greenDeep = Color(hex: 0x1F8A50)
    static let yellow = Color(hex: 0xFFD23F)
    static let blue = Color(hex: 0x3A86FF)        // secondary action, selection, live lessons
    static let blueDeep = Color(hex: 0x2A63C4)
    /// Mistake. Rose rather than coral, so it never looks like the red-orange action.
    static let coral = Color(hex: 0xF2557A)
    static let coralDeep = Color(hex: 0xC93A5C)
    static let onBright = Color(hex: 0x1B1B3A)

    static let greenText = Color(light: 0x15803D, dark: 0x4ADE80)
    static let blueText = Color(light: 0x2A63C4, dark: 0x93B8FF)
    static let coralText = Color(light: 0xC8264F, dark: 0xFF9BB5)

    static let ink = Color(light: 0x1B1B3A, dark: 0xEDF0FA)
    static let inkSoft = Color(light: 0x6A6F8C, dark: 0xA3AAC9)
    static let bg = Color(light: 0xFFFFFF, dark: 0x1A1C33)
    static let bgTint = Color(light: 0xF3F6FB, dark: 0x121327)
    static let line = Color(light: 0xDDE3EE, dark: 0x2E3150)
    static let lineDeep = Color(light: 0xC3CCDD, dark: 0x3F4470)

    static let greenTint = green.opacity(0.14)
    static let yellowTint = yellow.opacity(0.22)
    static let blueTint = blue.opacity(0.12)
    static let coralTint = coral.opacity(0.14)

    /// A fill and the text that sits on it.
    struct Tone {
        let fill: Color
        let text: Color
    }

    /// One look per section, the same as on the site
    /// (apps/web/components/stories/sections.ts).
    static func tone(_ section: SectionCode) -> Tone {
        switch section {
        case .grammar: return Tone(fill: green, text: onBright)
        case .listening: return Tone(fill: yellow, text: onBright)
        case .reading: return Tone(fill: coral, text: onBright)
        case .exercise: return Tone(fill: blue, text: onBright)
        case .writing: return Tone(fill: onBright, text: Color(hex: 0xEDF0FA))   // dark plate
        case .speaking: return Tone(fill: bg, text: ink)                          // paper
        }
    }

    static func bright(_ fill: Color) -> Tone { Tone(fill: fill, text: onBright) }
}

/// Two typefaces (docs/dev-plan.md §6–7): the Russian interface in a rounded
/// sans, the English material in a serif, so the two never look alike. Both are
/// system faces with full Cyrillic. Body text stays at 17 pt or more.
enum Typo {
    static let body = Font.system(.body, design: .rounded)
    static let bodyBold = Font.system(.body, design: .rounded).weight(.bold)
    static let caption = Font.system(.subheadline, design: .rounded).weight(.semibold)
    static let card = Font.system(.title3, design: .rounded).weight(.heavy)
    static let title = Font.system(.title, design: .rounded).weight(.heavy)
    static let big = Font.system(.largeTitle, design: .rounded).weight(.black)
    /// English material: texts, questions, options.
    static let material = Font.system(.body, design: .serif)
    static let materialBold = Font.system(.body, design: .serif).weight(.semibold)
}

/// Spring only: no linear or ease-in-out (packages/ui/src/springs.json).
enum Motion {
    static let snappy = Animation.spring(response: 0.38, dampingFraction: 0.72)
    static let soft = Animation.spring(response: 0.52, dampingFraction: 0.8)
}

enum Metrics {
    static let radius: CGFloat = 16
    static let radiusSmall: CGFloat = 8
    static let buttonHeight: CGFloat = 56
    static let buttonDepth: CGFloat = 6
    static let padding: CGFloat = 20
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// A color that follows the light or dark theme of the phone.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
