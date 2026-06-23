import Foundation

/// The time windows the insights screen can summarize over.
/// Drives the segmented picker and all filtering.
enum TimeRange: String, CaseIterable, Identifiable, Sendable {
    case last7
    case last30
    case last12mo
    case all

    var id: Self { self }

    /// Short label for the segmented control.
    var label: String {
        switch self {
        case .last7:    return "7 Days"
        case .last30:   return "30 Days"
        case .last12mo: return "Year"
        case .all:      return "All"
        }
    }

    /// Lowercased phrase for prose summaries, e.g. "the last 7 days".
    var phrase: String {
        switch self {
        case .last7:    return "the last 7 days"
        case .last30:   return "the last 30 days"
        case .last12mo: return "the last year"
        case .all:      return "all your reflections"
        }
    }

    /// Earliest day included (inclusive), or nil for all-time.
    func startDate(now: Date = .now, calendar: Calendar = .current) -> Date? {
        let startOfToday = calendar.startOfDay(for: now)
        switch self {
        case .last7:    return calendar.date(byAdding: .day, value: -6, to: startOfToday)
        case .last30:   return calendar.date(byAdding: .day, value: -29, to: startOfToday)
        case .last12mo: return calendar.date(byAdding: .month, value: -12, to: startOfToday)
        case .all:      return nil
        }
    }

    /// Reflections whose day falls within this range (today included).
    func filter(_ snapshots: [ReflectionSnapshot],
                now: Date = .now,
                calendar: Calendar = .current) -> [ReflectionSnapshot] {
        guard let start = startDate(now: now, calendar: calendar) else { return snapshots }
        return snapshots.filter { calendar.startOfDay(for: $0.date) >= start }
    }
}
