import SwiftUI
import SwiftData

/// "Looking back" — a calm digest of patterns across the user's reflections.
/// Reached from a quiet toolbar icon on Home; never surfaced on the entry screen.
struct InsightsView: View {
    @Query(sort: \DayReflection.date, order: .reverse)
    private var allReflections: [DayReflection]

    @State private var range: TimeRange = .last30
    @State private var result: InsightsResult = .empty(.last30)
    @State private var summary: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let summaryProvider = SummaryProviderFactory.make()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                rangePicker

                if result.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Looking Back")
        .navigationBarTitleDisplayMode(.large)
        .task(id: range) { await recompute() }
    }

    // MARK: - Cards

    @ViewBuilder
    private var content: some View {
        if let summary {
            SummaryCard(text: summary)
        }

        RhythmCard(rhythm: result.rhythm)

        if !result.didWellThemes.isEmpty {
            ThemesCard(title: "You did well, often",
                       systemImage: ReflectionSection.didWell.systemImage,
                       tint: Theme.accent,
                       topics: result.didWellThemes)
        }

        if !result.enjoyedThemes.isEmpty {
            ThemesCard(title: "Small joys that keep returning",
                       systemImage: ReflectionSection.enjoyed.systemImage,
                       tint: Theme.accentRose,
                       topics: result.enjoyedThemes)
        }

        if !result.people.isEmpty {
            PeopleCard(people: result.people)
        }
    }

    private var rangePicker: some View {
        Picker("Time range", selection: $range) {
            ForEach(TimeRange.allCases) { r in
                Text(r.label).tag(r)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Patterns are still forming", systemImage: "sparkles")
        } description: {
            Text("A few more days of reflecting and gentle insights will start to gather here.")
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    // MARK: - Compute

    /// Snapshot on the main actor (SwiftData models are thread-bound), then analyze
    /// off the main thread. The deterministic cards render first; the soft summary
    /// streams in after and never blocks the screen.
    private func recompute() async {
        let snapshots = allReflections.map(\.snapshot)
        let selected = range

        let computed = await Task.detached(priority: .userInitiated) {
            InsightsEngine.analyze(snapshots, range: selected)
        }.value
        guard selected == range else { return }

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            result = computed
            summary = nil
        }

        let text = await summaryProvider.summary(for: computed)
        guard selected == range else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            summary = text
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(for: DayReflection.self, inMemory: true)
}
