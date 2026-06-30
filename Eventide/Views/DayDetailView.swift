import SwiftUI

/// Edit a past day. Reuses the same editor; auto-saves like the home screen.
struct DayDetailView: View {
    @Bindable var reflection: DayReflection

    var body: some View {
        ReflectionEditor(reflection: reflection)
            .navigationTitle(reflection.date.reflectionHeader)
            .navigationBarTitleDisplayMode(.large)
    }
}
