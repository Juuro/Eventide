import SwiftUI
import SwiftData

/// A simple, scrollable history of previous days. Tapping a day opens it for editing.
struct PastEntriesView: View {
    /// Newest first. Excludes today — today lives on the home screen.
    @Query(sort: \DayReflection.date, order: .reverse)
    private var allReflections: [DayReflection]

    @Environment(\.modelContext) private var context

    private var pastDays: [DayReflection] {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return allReflections.filter { $0.date < startOfToday && $0.hasAnyContent }
    }

    private struct MonthGroup: Identifiable {
        let id: String
        let displayName: String
        let days: [DayReflection]
    }

    private var groupedByMonth: [MonthGroup] {
        let sortKeyFormatter = DateFormatter()
        sortKeyFormatter.dateFormat = "yyyy-MM"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: pastDays) { day in
            sortKeyFormatter.string(from: day.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { key, days in
                let date = sortKeyFormatter.date(from: key) ?? .now
                return MonthGroup(
                    id: key,
                    displayName: displayFormatter.string(from: date),
                    days: days.sorted { $0.date > $1.date }
                )
            }
    }

    var body: some View {
        Group {
            if pastDays.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedByMonth) { group in
                        Section {
                            ForEach(group.days) { day in
                                NavigationLink {
                                    DayDetailView(reflection: day)
                                } label: {
                                    EnhancedDayRow(day: day)
                                }
                            }
                            .onDelete { offsets in
                                let daysInGroup = group.days
                                for index in offsets {
                                    context.delete(daysInGroup[index])
                                }
                            }
                        } header: {
                            Text(group.displayName)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reflections")
        .navigationBarTitleDisplayMode(.large)
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Seed", action: seedSampleData)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        #endif
    }

    #if DEBUG
    private func seedSampleData() {
        let calendar = Calendar.current
        let existingDates = Set(allReflections.map { calendar.startOfDay(for: $0.date) })

        let didWellPool: [[String]] = [
            ["Stayed focused during the morning", "Went for a walk at lunch", "Finished the report on time", "Called Mum", "Cooked a proper dinner"],
            ["Got up without hitting snooze", "Helped a colleague debug their code", "Read for 30 minutes", "Kept my inbox at zero", "Did a full workout"],
            ["Shipped the feature I was stuck on", "Ate well all day", "Meditated for 10 minutes", "Wrote in my journal", "Went to bed before midnight"],
            ["Solved a tricky problem at work", "Made time for a friend", "Took a proper lunch break", "Stayed calm in a stressful meeting", "Cleaned the flat"],
            ["Learned something new", "Replied to all messages", "Drank enough water", "Finished a side project task", "Went outside for fresh air"],
            ["Set clear priorities for the day", "Helped someone without being asked", "Kept my phone away during dinner", "Exercised first thing", "Read the book I've been putting off"],
            ["Refactored some messy code", "Took a break when I needed it", "Caught up with an old friend", "Planned the week ahead", "Made a healthy breakfast"],
        ]

        let enjoyedPool: [[String]] = [
            ["Morning coffee in silence", "The smell of rain", "A long podcast walk", "Good music while cooking", "Watching the sunset"],
            ["A really funny video call", "Fresh bread from the bakery", "The quiet of late evening", "An unexpected compliment", "Finally finishing a book"],
            ["That first sip of tea", "A spontaneous lunch outside", "The city lights at night", "A good conversation with no agenda", "Discovering a new album"],
            ["Sleeping in a bit", "The farmers market smell", "A long, uninterrupted shower", "Playing a game I haven't touched in months", "A really good meal"],
            ["Catching up on a series", "The light through the window in the morning", "A productive flow state", "An interesting article", "Stretching before bed"],
            ["A walk without a destination", "Homemade soup", "Texting a friend out of the blue", "Cool air on a warm day", "A film that surprised me"],
            ["The satisfaction of a tidy desk", "Baking something", "A good night's sleep", "A moment of silence after a busy day", "Watching clouds"],
        ]

        for daysAgo in 1...14 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let normalized = calendar.startOfDay(for: date)
            guard !existingDates.contains(normalized) else { continue }

            // Skip a couple of days to make the history feel realistic
            if daysAgo == 4 || daysAgo == 9 { continue }

            let entry = DayReflection(date: date)
            let poolIndex = (daysAgo - 1) % didWellPool.count
            let filledSlots = daysAgo == 2 ? 3 : 5 // one partial day
            entry.didWell = Array(didWellPool[poolIndex].prefix(filledSlots)) + Array(repeating: "", count: 5 - filledSlots)
            entry.enjoyed = Array(enjoyedPool[poolIndex].prefix(filledSlots)) + Array(repeating: "", count: 5 - filledSlots)
            context.insert(entry)
        }
    }
    #endif

    private var emptyState: some View {
        ContentUnavailableView(
            "No past entries yet",
            systemImage: "moon.stars",
            description: Text("Your earlier reflections will gather here, one calm evening at a time.")
        )
    }

    private struct EnhancedDayRow: View {
        let day: DayReflection

        private var previewText: String? {
            (day.didWell + day.enjoyed).first {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }

        var body: some View {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(day.date.reflectionHeader)
                        .font(.body.weight(.medium))
                    if let preview = previewText {
                        Text(preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No entries")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                if day.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityLabel("Complete")
                } else {
                    Text("\(day.filledCount)/\(DayReflection.totalSlots)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
    }


}
