import SwiftUI

/// The white button of the app. A secondary button has a dark fill.
struct PolyButtonStyle: ButtonStyle {
    var primary = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Karla.font(15, .bold))
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .foregroundStyle(primary ? Palette.onAccent : Palette.textPrimary)
            .background(primary ? Palette.accent : Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: corner))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(primary ? .clear : Palette.outline))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PolyButtonStyle {
    static var polyPrimary: PolyButtonStyle { PolyButtonStyle(primary: true) }
    static var polySecondary: PolyButtonStyle { PolyButtonStyle(primary: false) }
}

/// The title of a section.
struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Karla.font(18, .bold, relativeTo: .headline))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The large title at the top of a screen.
struct ScreenTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Karla.font(30, .bold, relativeTo: .largeTitle))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A grey text and an optional button in the middle of an empty screen.
struct EmptyMessage: View {
    let text: String
    var action: String?
    var perform: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            Text(text)
                .font(Karla.font(15))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action, action: perform)
                    .buttonStyle(.polyPrimary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A small label with an outline, such as "Lab" or "Odd weeks".
struct Chip: View {
    let text: String
    var filled = false

    var body: some View {
        Text(text)
            .font(Karla.font(12, .bold, relativeTo: .caption))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(filled ? Palette.onAccent : Palette.textPrimary)
            .background(filled ? Palette.accent : .clear, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(filled ? .clear : Palette.outline))
    }
}
