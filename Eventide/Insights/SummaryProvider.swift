import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Produces the soft "what stands out lately" sentence from already-computed,
/// deterministic insights. Data is never invented here — only phrased.
protocol SummaryProvider {
    func summary(for result: InsightsResult) async -> String?
}

/// Always-available, deterministic phrasing. The universal fallback, and the path
/// used on devices without Apple Intelligence / Foundation Models.
struct TemplateSummaryProvider: SummaryProvider {
    func summary(for result: InsightsResult) async -> String? {
        guard !result.isEmpty else { return nil }

        let topJoy = result.enjoyedThemes.first?.term
        let topPerson = result.people.first?.name
        let topAny = (result.didWellThemes + result.enjoyedThemes)
            .sorted { $0.count > $1.count }
            .first?.term

        let lead: String
        switch (topJoy, topPerson) {
        case let (joy?, person?):
            lead = "Across \(result.range.phrase), \(joy) and time with \(person) came up most."
        case let (joy?, nil):
            lead = "Across \(result.range.phrase), \(joy) kept returning."
        case let (nil, person?):
            lead = "Across \(result.range.phrase), \(person) was part of many of your days."
        default:
            if let theme = topAny {
                lead = "Across \(result.range.phrase), \(theme) came up most."
            } else {
                let n = result.rhythm.daysReflected
                lead = "You reflected on \(n) \(n == 1 ? "day" : "days")."
            }
        }
        return lead + " Worth holding onto."
    }
}

#if canImport(FoundationModels)

/// Generative phrasing via Apple's on-device Foundation Models (iOS 26+, Apple
/// Intelligence devices). Runs fully on device — no network, matching the app's
/// privacy stance. Constrained to describe ONLY the pre-computed items it's handed,
/// so it adds no facts. Any failure falls back to the deterministic template, so the
/// screen always has a sentence.
@available(iOS 26.0, *)
struct ModelSummaryProvider: SummaryProvider {
    private let fallback = TemplateSummaryProvider()

    private static let instructions = """
        You write a single warm, encouraging sentence (two at most) that reflects \
        gently on a person's own journal patterns. Use ONLY the facts given in the \
        prompt — never invent themes, people, numbers, or events. No greetings, no \
        emoji, no quotation marks, no lists. Stay calm and affirming, never analytical \
        or judgmental. Address the person as "you".
        """

    func summary(for result: InsightsResult) async -> String? {
        guard !result.isEmpty else { return nil }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: Self.prompt(for: result),
                options: GenerationOptions(temperature: 0.5)
            )
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? await fallback.summary(for: result) : text
        } catch {
            // Timeout, guardrail refusal, resource limits, etc. → deterministic phrasing.
            return await fallback.summary(for: result)
        }
    }

    /// Feeds the model only pre-computed, factual items — nothing free-form.
    private static func prompt(for result: InsightsResult) -> String {
        let didWell = result.didWellThemes.prefix(3).map(\.term).joined(separator: ", ")
        let enjoyed = result.enjoyedThemes.prefix(3).map(\.term).joined(separator: ", ")
        let people = result.people.prefix(3)
            .map { "\($0.name) (\($0.days) days)" }
            .joined(separator: ", ")

        var lines = [
            "Time range: \(result.range.phrase).",
            "Days reflected: \(result.rhythm.daysReflected)."
        ]
        if !didWell.isEmpty { lines.append("Recurring things they did well: \(didWell).") }
        if !enjoyed.isEmpty { lines.append("Recurring things they enjoyed: \(enjoyed).") }
        if !people.isEmpty  { lines.append("People they mention often: \(people).") }
        lines.append("Write the gentle reflection now.")
        return lines.joined(separator: "\n")
    }
}

#endif

/// Decides which phrasing source to use. Prefers on-device Foundation Models when the
/// system model reports `.available`; otherwise the deterministic template.
enum SummaryProviderFactory {
    static func make() -> SummaryProvider {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return ModelSummaryProvider()
            }
        }
        #endif
        return TemplateSummaryProvider()
    }
}
