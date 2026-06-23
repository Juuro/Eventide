import SwiftUI
import SwiftData

/// Today's reflection. Fetches the entry for the current day, creating one if needed.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @State private var today: DayReflection?
    @AppStorage("eventide_hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showWelcome = false

    var body: some View {
        Group {
            if let today {
                ReflectionEditor(reflection: today)
                    .navigationTitle(today.date.reflectionHeader)
                    .navigationBarTitleDisplayMode(.large)
            } else {
                ProgressView().controlSize(.large)
            }
        }
        .onAppear(perform: loadToday)
        .sheet(isPresented: $showWelcome) {
            WelcomeView {
                hasLaunchedBefore = true
                showWelcome = false
            }
        }
    }

    /// Fetch the entry for today, or create and insert a fresh one.
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

        if !hasLaunchedBefore {
            showWelcome = true
        }
    }

    private struct WelcomeView: View {
        let onDismiss: () -> Void

        var body: some View {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                Text("Evening Reflection")
                    .font(.title2.bold())
                Text("A space to notice what went well and what brought you joy today.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button("Begin", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Theme.accent)
                Spacer()
            }
            .presentationDetents([.medium])
        }
    }
}
