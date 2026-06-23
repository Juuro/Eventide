import Foundation

/// A plain, `Sendable` value copy of one day's reflection.
/// Used so analysis can run off the main actor without touching SwiftData models
/// (which are bound to their context's thread).
struct ReflectionSnapshot: Sendable {
    let date: Date
    let didWell: [String]
    let enjoyed: [String]

    var hasAnyContent: Bool {
        (didWell + enjoyed).contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

extension DayReflection {
    /// A thread-safe value snapshot for off-main analysis.
    var snapshot: ReflectionSnapshot {
        ReflectionSnapshot(date: date, didWell: didWell, enjoyed: enjoyed)
    }
}

/// Computed, deterministic insights for one time range. Pure data — no view concerns.
struct InsightsResult: Sendable {
    var range: TimeRange
    var rhythm: Rhythm
    var didWellThemes: [Topic]
    var enjoyedThemes: [Topic]
    var people: [Person]

    /// Gentle volume summary for the range — never framed as a goal or score.
    struct Rhythm: Sendable {
        var daysReflected: Int
        var didWellTotal: Int
        var enjoyedTotal: Int

        var total: Int { didWellTotal + enjoyedTotal }
        var hasContent: Bool { total > 0 }
    }

    /// A recurring theme/keyword and how often it appeared.
    struct Topic: Identifiable, Sendable {
        var term: String
        var count: Int
        var id: String { term }
    }

    /// A recurring person and the number of distinct days they were mentioned.
    struct Person: Identifiable, Sendable {
        var name: String
        var days: Int
        var id: String { name }
    }

    /// True when there's essentially nothing to show for this range.
    var isEmpty: Bool { !rhythm.hasContent }

    static func empty(_ range: TimeRange) -> InsightsResult {
        InsightsResult(range: range,
                       rhythm: Rhythm(daysReflected: 0, didWellTotal: 0, enjoyedTotal: 0),
                       didWellThemes: [], enjoyedThemes: [], people: [])
    }
}
