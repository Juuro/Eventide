import SwiftUI
import UIKit

private enum FieldID: Hashable {
    case didWell(Int)
    case enjoyed(Int)
}

/// The shared editing surface used by both today's entry and past days. Progress
/// is shown by the persistent `ProgressChip` on the tab bar, not by the editor itself.
struct ReflectionEditor: View {
    @Bindable var reflection: DayReflection

    @FocusState private var focusedField: FieldID?

    var body: some View {
        List {
            section(.didWell, binding: $reflection.didWell)
            section(.enjoyed, binding: $reflection.enjoyed)
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
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
                let fieldID: FieldID = kind == .didWell ? .didWell(index) : .enjoyed(index)
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
            return i < DayReflection.slotsPerSection - 1 ? .didWell(i + 1) : .enjoyed(0)
        case .enjoyed(let i):
            return i < DayReflection.slotsPerSection - 1 ? .enjoyed(i + 1) : nil
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

    private var noNewlineText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                let stripped = newValue.replacingOccurrences(of: "\n", with: "")
                text = stripped
                if newValue.contains("\n") {
                    onSubmit()
                }
            }
        )
    }

    private var isFilled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            indicator
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            TextField(placeholder, text: noNewlineText, axis: .vertical)
                .font(.body)
                .lineLimit(1...4)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
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
