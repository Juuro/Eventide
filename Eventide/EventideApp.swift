import SwiftUI
import SwiftData

@main
struct EventideApp: App {
    /// Shared SwiftData container. Stored locally on-device only — no network, no sync.
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: DayReflection.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
