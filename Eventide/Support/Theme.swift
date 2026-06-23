import SwiftUI

/// Calm, minimal visual constants. Uses system materials so it adapts to light/dark
/// and respects accessibility contrast settings automatically.
enum Theme {
    /// Soft tinted background for the evening-ritual feel.
    static let background = Color(.systemGroupedBackground)

    /// Accent used sparingly for progress and the done state.
    static let accent = Color.indigo

    /// Warm rose accent for the "rejoiced" section — system adaptive for light/dark.
    static let accentRose = Color(.systemPink)

    /// Font style for the completion celebration message.
    static let completionFont: Font = .callout

    static let cardSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 28
    static let cornerRadius: CGFloat = 14
}

extension Date {
    /// "Monday, 22 June" — prominent, human header for the day.
    var reflectionHeader: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: self)
    }

    /// Compact label for list rows, e.g. "22 Jun 2026".
    var reflectionListLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f.string(from: self)
    }
}
