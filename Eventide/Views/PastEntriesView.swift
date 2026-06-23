import SwiftUI
import SwiftData

/// A simple, scrollable history of previous days. Tapping a day opens it for editing.
struct PastEntriesView: View {
    /// Newest first. Excludes today — today lives on the home screen.
    @Query(sort: \DayReflection.date, order: .reverse)
    private var allReflections: [DayReflection]

    @Environment(\.modelContext) private var context
    @State private var previewDay: DayReflection? = nil

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
                                        .contextMenu {
                                            Button {
                                                previewDay = day
                                            } label: {
                                                Label("Preview", systemImage: "eye")
                                            }
                                        }
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
                .sheet(item: $previewDay) { day in
                    DayPreviewSheet(reflection: day)
                }
            }
        }
        .navigationTitle("Reflections")
        .navigationBarTitleDisplayMode(.large)
    }

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
            (day.didWell + day.rejoiced).first {
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

    private struct DayPreviewSheet: View {
        let reflection: DayReflection
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                List {
                    Section("Did Well") {
                        ForEach(reflection.didWell.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { entry in
                            Text(entry)
                        }
                    }
                    Section("Rejoiced") {
                        ForEach(reflection.rejoiced.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { entry in
                            Text(entry)
                        }
                    }
                }
                .navigationTitle(reflection.date.reflectionHeader)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
