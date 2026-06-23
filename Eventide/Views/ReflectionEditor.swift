import SwiftUI
import SwiftData
import UIKit

private enum FieldID: Hashable {
    case didWell(Int)
    case rejoiced(Int)
}

struct ReflectionEditor: View {
    @Bindable var reflection: DayReflection
    var showsHeader: Bool = true

    @FocusState private var focusedField: FieldID?

    @Query(sort: \DayReflection.date, order: .reverse)
    private var allReflections: [DayReflection]

    private var streak: Int {
        DayReflection.currentStreak(from: allReflections)
    }

    var body: some View {
        List {
            section(.didWell, binding: $reflection.didWell)
            section(.rejoiced, binding: $reflection.rejoiced)
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsHeader {
                BottomProgressBadge(
                    didWellFilled: reflection.didWellFilledCount,
                    rejoicedFilled: reflection.rejoicedFilledCount,
                    isComplete: reflection.isComplete,
                    streak: streak
                )
            }
        }
        .onChange(of: reflection.isComplete) { _, newValue in
            if newValue {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                AccessibilityNotification.Announcement("Reflection complete. All ten filled.").post()
            }
        }
    }

    // MARK: - Section

    private func section(_ kind: ReflectionSection, binding: Binding<[String]>) -> some View {
        Section {
            ForEach(0..<DayReflection.slotsPerSection, id: \.self) { index in
                let fieldID: FieldID = kind == .didWell ? .didWell(index) : .rejoiced(index)
                ReflectionRow(
                    text: binding[index],
                    placeholder: kind.placeholder(for: index),
                    accessibilityLabel: "\(kind.shortTitle), \(index + 1) of \(DayReflection.slotsPerSection)",
                    index: index,
                    sectionColor: kind.sectionColor,
                    fieldID: fieldID,
                    focusedField: $focusedField,
                    onSubmit: { focusedField = nextField(after: fieldID) }
                )
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: kind.systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(kind.sectionColor)
                Text(kind.title)
            }
            .font(.headline)
            .textCase(nil)
            .foregroundStyle(.primary)
        } footer: {
            Text(kind.prompt)
                .font(.footnote)
        }
    }

    // MARK: - Focus

    private func nextField(after id: FieldID) -> FieldID? {
        switch id {
        case .didWell(let i):
            return i < DayReflection.slotsPerSection - 1 ? .didWell(i + 1) : .rejoiced(0)
        case .rejoiced(let i):
            return i < DayReflection.slotsPerSection - 1 ? .rejoiced(i + 1) : nil
        }
    }
}

private struct ReflectionRow: View {
    @Binding var text: String
    let placeholder: String
    let accessibilityLabel: String
    let index: Int
    let sectionColor: Color
    let fieldID: FieldID
    var focusedField: FocusState<FieldID?>.Binding
    let onSubmit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFilled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            indicator
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(1...4)
                .textInputAutocapitalization(.sentences)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint("Write a brief reflection")
                .focused(focusedField, equals: fieldID)
                .onSubmit(onSubmit)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .onChange(of: isFilled) { _, filled in
            if filled && !UIAccessibility.isReduceMotionEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private var indicator: some View {
        ZStack {
            Text("\(index + 1)")
                .font(.system(size: 15).monospacedDigit())
                .foregroundStyle(.secondary.opacity(0.4))
                .scaleEffect(isFilled ? 0.5 : 1)
                .opacity(isFilled ? 0 : 1)

            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(sectionColor)
                .scaleEffect(isFilled ? 1 : 0.4)
                .opacity(isFilled ? 1 : 0)
                .symbolEffect(.bounce, value: isFilled)
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.55),
            value: isFilled
        )
    }
}

// Merged progress badge — capsule dots + section labels + status.
// Anchored to the bottom via safeAreaInset; always visible regardless of scroll position.
private struct BottomProgressBadge: View {
    let didWellFilled: Int
    let rejoicedFilled: Int
    let isComplete: Bool
    let streak: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let slots = DayReflection.slotsPerSection

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            dotGroup(filled: didWellFilled, color: Theme.accent, label: "Did Well")
            dotGroup(filled: rejoicedFilled, color: Theme.accentRose, label: "Rejoiced")
            Spacer()
            statusView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.25), value: isComplete)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(
            isComplete
                ? "Complete. All ten filled."
                : "\(didWellFilled + rejoicedFilled) of \(slots * 2) filled. Did Well: \(didWellFilled) of \(slots). Rejoiced: \(rejoicedFilled) of \(slots)."
        )
    }

    private func dotGroup(filled: Int, color: Color, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<slots, id: \.self) { i in
                    Capsule()
                        .fill(i < filled ? color : Color.secondary.opacity(0.2))
                        .frame(width: i < filled ? 14 : 10, height: 4)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65),
                            value: filled
                        )
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if isComplete {
            Label("All done.", systemImage: "moon.stars.fill")
                .font(Theme.completionFont.italic())
                .foregroundStyle(Theme.accent)
                .symbolEffect(.bounce, value: isComplete)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else if streak >= 2 {
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(didWellFilled + rejoicedFilled)/\(slots * 2)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Label("\(streak)d", systemImage: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("\(didWellFilled + rejoicedFilled)/\(slots * 2)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
