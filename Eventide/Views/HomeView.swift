import SwiftUI
import SwiftData

/// Today's reflection. Receives the entry for the current day from `RootView`
/// (the shared source of truth).
struct HomeView: View {
    let today: DayReflection

    @AppStorage("eventide_hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showWelcome = false

    var body: some View {
        ReflectionEditor(reflection: today)
            .navigationTitle(today.date.reflectionHeader)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !hasLaunchedBefore {
                    showWelcome = true
                }
            }
            .sheet(isPresented: $showWelcome) {
                WelcomeView {
                    hasLaunchedBefore = true
                    showWelcome = false
                }
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
