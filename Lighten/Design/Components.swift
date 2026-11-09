import SwiftUI

/// The main button: a raised face that sinks under the finger. One per screen.
struct PrimaryButtonStyle: ButtonStyle {
    var deep: Color = Palette.actionDeep
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Typo.bodyBold)
            .foregroundStyle(Palette.onBright)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radius)
                    .fill(isEnabled ? AnyShapeStyle(Palette.action) : AnyShapeStyle(Palette.line))
            )
            .offset(y: pressed ? Metrics.buttonDepth - 2 : 0)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radius)
                    .fill(isEnabled ? deep : Palette.lineDeep)
                    .offset(y: Metrics.buttonDepth)
            )
            .padding(.bottom, Metrics.buttonDepth)
            .opacity(isEnabled ? 1 : 0.7)
            .animation(Motion.snappy, value: pressed)
    }
}

/// A quiet button: outline, page text.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typo.bodyBold)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radius)
                    .strokeBorder(Palette.line, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// A plain card: border, slightly thicker at the bottom.
struct Card<Content: View>: View {
    var fill: Color = Palette.bg
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Metrics.padding)
            .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2)
            )
    }
}

/// A lesson's visible status: not started, done, being checked (docs/tz.md §9).
struct StatusBadge: View {
    let status: LessonStatus

    var body: some View {
        Text(Strings.status(status))
            .font(Typo.caption)
            .foregroundStyle(status == .done ? Palette.onBright : Palette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(fill))
    }

    private var fill: Color {
        switch status {
        case .notStarted: return Palette.bgTint
        case .inProgress: return Palette.yellowTint
        case .checking: return Palette.blueTint
        case .done: return Palette.green
        }
    }
}

/// A message under a form or a button.
struct NoticeText: View {
    enum Tone { case info, error }
    let text: String
    var tone: Tone = .info

    var body: some View {
        Text(text)
            .font(Typo.body)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radius)
                    .fill(tone == .error ? Palette.coralTint : Palette.blueTint)
            )
    }
}

/// English material: set apart from the Russian interface.
struct MaterialText: View {
    let text: String
    var bold = false

    init(_ text: String, bold: Bool = false) {
        self.text = text
        self.bold = bold
    }

    var body: some View {
        Text(text)
            .font(bold ? Typo.materialBold : Typo.material)
            .foregroundStyle(Palette.ink)
            .environment(\.locale, Locale(identifier: "en"))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Loading, error with "Ещё раз", or the content. Every screen that reads the
/// API goes through it, so a short drop of the connection never leaves a
/// blank page.
enum Loadable<Value> {
    case loading
    case failed(APIError)
    case loaded(Value)
}

struct LoadableView<Value, Content: View>: View {
    let state: Loadable<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            VStack(spacing: 16) {
                NoticeText(text: error.message, tone: .error)
                Button(Strings.retry) { Task { await retry() } }
                    .buttonStyle(.secondary)
            }
            .padding(Metrics.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        }
    }
}

extension View {
    /// The page background and the interface font.
    func screen() -> some View {
        self
            .font(Typo.body)
            .foregroundStyle(Palette.ink)
            .background(Palette.bgTint.ignoresSafeArea())
    }
}
