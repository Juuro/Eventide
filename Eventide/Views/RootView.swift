import SwiftUI
import SwiftData

/// App shell. A bottom tab bar is the primary navigation: Today (today's
/// entry), Reflections (past days), and Insights. Today's progress lives in a
/// persistent `ProgressChip` attached to the tab bar — a native bottom accessory
/// on iOS 26+, falling back to a pinned chip above the tab bar on iOS 17–25.
struct RootView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \DayReflection.date, order: .reverse)
    private var allReflections: [DayReflection]

    @State private var today: DayReflection?
    @State private var selection: AppTab = .reflections
    // Today is the home base — the app lands here so the gear in its nav bar
    // is the discoverable entry point to Settings.

    private enum AppTab: Hashable {
        case reflections
        case reflectionsHistory
        case insights
    }

    private var streak: Int {
        DayReflection.currentStreak(from: allReflections)
    }

    var body: some View {
        shell
            .tint(Theme.accent)
            .onAppear(perform: loadToday)
    }

    // MARK: - Tab shell

    @ViewBuilder
    private var shell: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selection) {
                Tab("Today", systemImage: "moon.stars", value: AppTab.reflections) {
                    reflectionsTab
                }
                Tab("Reflections", systemImage: "calendar", value: AppTab.reflectionsHistory) {
                    reflectionsHistoryTab
                }
                Tab("Insights", systemImage: "sparkles", value: AppTab.insights) {
                    insightsTab
                }
            }
            .tabViewBottomAccessory {
                if let today {
                    ChipAccessory(reflection: today, streak: streak)
                }
            }
            // Drives the Apple Music collapse: scrolling down minimizes the tab bar
            // to a single round button (bottom-left) and relocates the accessory
            // inline beside it; scrolling up — or tapping the button — restores it.
            // The system coordinates both animations as one transition.
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            TabView(selection: $selection) {
                reflectionsTab
                    .tabItem { Label("Today", systemImage: "moon.stars") }
                    .tag(AppTab.reflections)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        fallbackChip
                    }
                reflectionsHistoryTab
                    .tabItem { Label("Reflections", systemImage: "calendar") }
                    .tag(AppTab.reflectionsHistory)
                insightsTab
                    .tabItem { Label("Insights", systemImage: "sparkles") }
                    .tag(AppTab.insights)
            }
        }
    }

    private var reflectionsTab: some View {
        NavigationStack {
            Group {
                if let today {
                    HomeView(today: today)
                } else {
                    ProgressView().controlSize(.large)
                }
            }
        }
    }

    private var reflectionsHistoryTab: some View {
        NavigationStack {
            PastEntriesView()
        }
    }

    private var insightsTab: some View {
        NavigationStack {
            InsightsView()
        }
    }

    /// iOS 17–25 fallback: a pinned chip above the tab bar (no system scroll-collapse).
    @ViewBuilder
    private var fallbackChip: some View {
        if let today {
            ProgressChip(
                didWellFilled: today.didWellFilledCount,
                enjoyedFilled: today.enjoyedFilledCount,
                isComplete: today.isComplete,
                streak: streak
            )
            .background(.bar)
        }
    }

    // MARK: - Today

    /// Fetch today's entry, or create and insert a fresh one. Lifted here so both
    /// the editor and the progress chip share a single source of truth.
    private func loadToday() {
        guard today == nil else { return }

        let startOfDay = Calendar.current.startOfDay(for: .now)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DayReflection>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < nextDay }
        )

        if let existing = try? context.fetch(descriptor).first {
            today = existing
        } else {
            let fresh = DayReflection(date: .now)
            context.insert(fresh)
            today = fresh
        }
    }
}

/// Bridges the system's bottom-accessory placement into the chip's density.
/// Only valid inside `tabViewBottomAccessory`, where the placement environment is set.
@available(iOS 26.0, *)
private struct ChipAccessory: View {
    let reflection: DayReflection
    let streak: Int

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        ProgressChip(
            didWellFilled: reflection.didWellFilledCount,
            enjoyedFilled: reflection.enjoyedFilledCount,
            isComplete: reflection.isComplete,
            streak: streak,
            placement: placement == .inline ? .inline : .expanded
        )
    }
}

#Preview {
    RootView()
        .modelContainer(for: DayReflection.self, inMemory: true)
}
