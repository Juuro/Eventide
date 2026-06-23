import Foundation
import SwiftData

/// One day's reflection: five things done well, five things rejoiced about.
/// Persisted locally via SwiftData. One instance per calendar day.
@Model
final class DayReflection {
    /// Normalized to the start of the day so each calendar day has a single entry.
    var date: Date

    /// Five short notes for "things I did well today".
    var didWell: [String]

    /// Five short notes for "things I rejoiced about today".
    var rejoiced: [String]

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.didWell = Array(repeating: "", count: DayReflection.slotsPerSection)
        self.rejoiced = Array(repeating: "", count: DayReflection.slotsPerSection)
    }

    static let slotsPerSection = 5
    static var totalSlots: Int { slotsPerSection * 2 }

    /// How many of the 10 slots have non-empty text.
    var filledCount: Int {
        (didWell + rejoiced)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
    }

    var isComplete: Bool { filledCount == DayReflection.totalSlots }
    var hasAnyContent: Bool { filledCount > 0 }

    /// Count of filled entries in the "did well" section only.
    var didWellFilledCount: Int {
        didWell.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Count of filled entries in the "rejoiced" section only.
    var rejoicedFilledCount: Int {
        rejoiced.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// First non-empty entry from either section — used as a list row preview.
    var previewText: String? {
        (didWell + rejoiced).first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Consecutive-day streak ending yesterday (not counting today).
    /// Pass all persisted DayReflections from the SwiftData store.
    static func currentStreak(from reflections: [DayReflection]) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let datesWithContent = Set(
            reflections
                .filter { $0.hasAnyContent && calendar.startOfDay(for: $0.date) < startOfToday }
                .map { calendar.startOfDay(for: $0.date) }
        )
        var streak = 0
        guard var checkDate = calendar.date(byAdding: .day, value: -1, to: startOfToday) else { return 0 }
        while datesWithContent.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }
}
