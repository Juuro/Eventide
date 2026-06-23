import SwiftUI

enum ReflectionSection: CaseIterable, Identifiable {
    case didWell
    case rejoiced

    var id: Self { self }

    var title: String {
        switch self {
        case .didWell:  return "Did Well"
        case .rejoiced: return "Rejoiced"
        }
    }

    // Used in VoiceOver accessibility labels — e.g. "Did well, 1 of 5"
    var shortTitle: String { title }

    var sectionColor: Color {
        switch self {
        case .didWell:  return Theme.accent
        case .rejoiced: return Theme.accentRose
        }
    }

    var prompt: String {
        switch self {
        case .didWell:  return "Small wins count too."
        case .rejoiced: return "What brought you a little joy?"
        }
    }

    var systemImage: String {
        switch self {
        case .didWell:  return "star.fill"
        case .rejoiced: return "heart.fill"
        }
    }

    func placeholder(for index: Int) -> String {
        switch self {
        case .didWell:
            return ["I showed up for…", "I handled…", "I made time for…",
                    "I was kind when…", "I finished…"][index]
        case .rejoiced:
            return ["A moment with…", "I noticed…", "I enjoyed…",
                    "I felt grateful for…", "Something that made me smile…"][index]
        }
    }
}
