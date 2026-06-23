import SwiftUI

enum ReflectionSection: CaseIterable, Identifiable {
    case didWell
    case enjoyed

    var id: Self { self }

    var title: String {
        switch self {
        case .didWell:  return "Did Well"
        case .enjoyed: return "Enjoyed"
        }
    }

    // Used in VoiceOver accessibility labels — e.g. "Did well, 1 of 5"
    var shortTitle: String { title }

    var sectionColor: Color {
        switch self {
        case .didWell:  return Theme.accent
        case .enjoyed: return Theme.accentRose
        }
    }

    var prompt: String {
        switch self {
        case .didWell:  return "Small wins count too."
        case .enjoyed: return "What brought you a little joy?"
        }
    }

    var systemImage: String {
        switch self {
        case .didWell:  return "star.fill"
        case .enjoyed: return "heart.fill"
        }
    }

    func placeholder(for index: Int) -> String {
        switch self {
        case .didWell:
            return ["I showed up for…", "I handled…", "I made time for…",
                    "I was kind when…", "I finished…"][index]
        case .enjoyed:
            return ["A moment with…", "I noticed…", "I enjoyed…",
                    "I felt grateful for…", "Something that made me smile…"][index]
        }
    }
}
