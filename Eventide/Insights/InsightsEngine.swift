import Foundation
import NaturalLanguage

/// Deterministic, on-device extraction. Pure, `nonisolated` functions — safe to run
/// off the main actor. Uses Apple's NaturalLanguage framework: works on every device,
/// no network, no Apple Intelligence required. Numbers here are always trustworthy.
enum InsightsEngine {

    static func analyze(_ snapshots: [ReflectionSnapshot], range: TimeRange) -> InsightsResult {
        let inRange = range.filter(snapshots).filter { $0.hasAnyContent }
        guard !inRange.isEmpty else { return .empty(range) }

        let didWellEntries = inRange.flatMap { nonEmpty($0.didWell) }
        let enjoyedEntries = inRange.flatMap { nonEmpty($0.enjoyed) }

        let rhythm = InsightsResult.Rhythm(
            daysReflected: inRange.count,
            didWellTotal: didWellEntries.count,
            enjoyedTotal: enjoyedEntries.count
        )

        return InsightsResult(
            range: range,
            rhythm: rhythm,
            didWellThemes: topics(in: didWellEntries),
            enjoyedThemes: topics(in: enjoyedEntries),
            people: people(in: inRange)
        )
    }

    // MARK: - Themes

    /// Lemmatized noun/verb frequency. Returns the top terms appearing at least twice
    /// (a single mention isn't a "pattern"). Lemmatizing merges walk/walks/walking.
    static func topics(in entries: [String], limit: Int = 5) -> [InsightsResult.Topic] {
        guard !entries.isEmpty else { return [] }

        var counts: [String: Int] = [:]
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]

        for entry in entries {
            tagger.string = entry
            tagger.enumerateTags(in: entry.startIndex..<entry.endIndex,
                                 unit: .word,
                                 scheme: .lexicalClass,
                                 options: options) { tag, tokenRange in
                guard let tag, tag == .noun || tag == .verb else { return true }
                let lemma = (tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue
                             ?? String(entry[tokenRange])).lowercased()
                guard lemma.count > 2, !stopwords.contains(lemma) else { return true }
                counts[lemma, default: 0] += 1
                return true
            }
        }

        let ranked: [(key: String, value: Int)] = counts
            .filter { $0.value >= 2 }
            .sorted { (lhs, rhs) -> Bool in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
        return ranked.prefix(limit).map { InsightsResult.Topic(term: $0.key, count: $0.value) }
    }

    // MARK: - People

    /// Recurring personal names, counted by distinct days mentioned. Requires a name to
    /// appear on at least two days, and filters obvious non-name noise.
    static func people(in snapshots: [ReflectionSnapshot], limit: Int = 5) -> [InsightsResult.Person] {
        var dayCounts: [String: Set<Date>] = [:]
        let tagger = NLTagger(tagSchemes: [.nameType])
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        let calendar = Calendar.current

        for snapshot in snapshots {
            let day = calendar.startOfDay(for: snapshot.date)
            let text = nonEmpty(snapshot.didWell + snapshot.enjoyed).joined(separator: ". ")
            guard !text.isEmpty else { continue }

            tagger.string = text
            tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                                 unit: .word,
                                 scheme: .nameType,
                                 options: options) { tag, tokenRange in
                guard tag == .personalName else { return true }
                guard let name = normalizedName(String(text[tokenRange])) else { return true }
                dayCounts[name, default: []].insert(day)
                return true
            }
        }

        let ranked: [(key: String, value: Set<Date>)] = dayCounts
            .filter { $0.value.count >= 2 }
            .sorted { (lhs, rhs) -> Bool in
                if lhs.value.count != rhs.value.count { return lhs.value.count > rhs.value.count }
                return lhs.key < rhs.key
            }
        return ranked.prefix(limit).map { InsightsResult.Person(name: $0.key, days: $0.value.count) }
    }

    // MARK: - Helpers

    private static func nonEmpty(_ slots: [String]) -> [String] {
        slots
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Accepts proper-noun-looking names, rejects lowercase noise and generic words.
    private static func normalizedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1, let first = trimmed.first, first.isUppercase else { return nil }
        guard !excludedNames.contains(trimmed.lowercased()) else { return nil }
        return trimmed
    }

    /// Common verbs/nouns that survive POS filtering but carry no theme.
    private static let stopwords: Set<String> = [
        "be", "have", "do", "get", "got", "make", "made", "go", "went", "take", "took",
        "keep", "kept", "feel", "felt", "thing", "things", "day", "days", "today",
        "time", "lot", "bit", "way", "stuff", "moment", "today's", "one", "something",
        "everything", "anything", "nothing", "someone", "people", "person"
    ]

    /// Generic kinship/role words a name tagger may surface that aren't proper names.
    private static let excludedNames: Set<String> = [
        "mum", "mom", "dad", "mam", "nan", "gran", "i", "me", "my"
    ]
}
