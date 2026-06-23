import SwiftUI

/// App shell: today's reflection with a calm path to past days.
struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            InsightsView()
                        } label: {
                            Image(systemName: "sparkles")
                                .accessibilityLabel("Looking back")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            PastEntriesView()
                        } label: {
                            Image(systemName: "calendar")
                                .accessibilityLabel("Past days")
                        }
                    }
                }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .modelContainer(for: DayReflection.self, inMemory: true)
}
