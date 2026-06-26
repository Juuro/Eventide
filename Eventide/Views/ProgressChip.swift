import SwiftUI

/// Visual density for the progress chip, mirroring `TabViewBottomAccessoryPlacement`.
/// `.expanded` is the default full-width chip that sits above the tab bar; `.inline`
/// is the condensed form the system attaches inside the tab bar row when scrolled.
enum ProgressChipPlacement {
    case expanded
    case inline
}

/// Persistent progress chip for today's reflection. Replaces the old `BottomProgressBadge`.
///
/// Hosted by `RootView` as a `tabViewBottomAccessory` (iOS 26+) or via a
/// `safeAreaInset(.bottom)` fallback (iOS 17–25). Adapts its layout to the
/// placement and presents the full breakdown in a sheet on tap.
struct ProgressChip: View {
    let didWellFilled: Int
    let enjoyedFilled: Int
    let isComplete: Bool
    let streak: Int
    var placement: ProgressChipPlacement = .expanded

    @State private var showingDetail = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let slots = DayReflection.slotsPerSection
    private var total: Int { slots * 2 }
    private var filled: Int { didWellFilled + enjoyedFilled }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            content
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.25), value: isComplete)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reflection progress")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Opens the full progress breakdown")
        .sheet(isPresented: $showingDetail) {
            ProgressDetailSheet(
                didWellFilled: didWellFilled,
                enjoyedFilled: enjoyedFilled,
                isComplete: isComplete,
                streak: streak
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch placement {
        case .expanded: expanded
        case .inline: inline
        }
    }

    // MARK: - Expanded (default, above the tab bar)

    private var expanded: some View {
        HStack(alignment: .center, spacing: 16) {
            dotGroup(filled: didWellFilled, color: Theme.accent, label: "Did Well")
            dotGroup(filled: enjoyedFilled, color: Theme.accentRose, label: "Enjoyed")
            Spacer(minLength: 8)
            status
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Inline (compact, attached in the tab bar row when scrolled)

    private var inline: some View {
        HStack(spacing: 8) {
            if isComplete {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(Theme.accent)
                Text("All done")
                    .font(.subheadline.weight(.medium))
            } else {
                Text("\(filled)/\(total)")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                if streak >= 2 {
                    Label("\(streak)d", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Pieces

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
    private var status: some View {
        if isComplete {
            Label("All done.", systemImage: "moon.stars.fill")
                .font(Theme.completionFont.italic())
                .foregroundStyle(Theme.accent)
                .symbolEffect(.bounce, value: isComplete)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else if streak >= 2 {
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(filled)/\(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Label("\(streak)d", systemImage: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("\(filled)/\(total)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityValue: String {
        if isComplete {
            return "Complete. All ten filled."
        }
        var value = "\(filled) of \(total) filled. Did Well: \(didWellFilled) of \(slots). Enjoyed: \(enjoyedFilled) of \(slots)."
        if streak >= 2 {
            value += " Streak: \(streak) days."
        }
        return value
    }
}

/// Full progress breakdown shown when the chip is tapped.
private struct ProgressDetailSheet: View {
    let didWellFilled: Int
    let enjoyedFilled: Int
    let isComplete: Bool
    let streak: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let slots = DayReflection.slotsPerSection

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text(isComplete ? "Reflection complete" : "Today's progress")
                    .font(.title3.bold())
                Spacer()
                if isComplete {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.bounce, value: isComplete)
                }
            }

            detailRow(filled: didWellFilled, color: Theme.accent,
                      symbol: ReflectionSection.didWell.systemImage, label: "Did Well")
            detailRow(filled: enjoyedFilled, color: Theme.accentRose,
                      symbol: ReflectionSection.enjoyed.systemImage, label: "Enjoyed")

            if streak >= 2 {
                Label("\(streak)-day streak", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationBackground(.regularMaterial)
    }

    private func detailRow(filled: Int, color: Color, symbol: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                Text(label)
                    .font(.headline)
                Spacer()
                Text("\(filled)/\(slots)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                ForEach(0..<slots, id: \.self) { i in
                    Capsule()
                        .fill(i < filled ? color : Color.secondary.opacity(0.2))
                        .frame(height: 6)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65),
                            value: filled
                        )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(filled) of \(slots) filled.")
    }
}

#Preview("Expanded") {
    ProgressChip(didWellFilled: 3, enjoyedFilled: 2, isComplete: false, streak: 4)
        .background(.bar)
}

#Preview("Inline") {
    ProgressChip(didWellFilled: 3, enjoyedFilled: 2, isComplete: false, streak: 4, placement: .inline)
        .background(.bar)
}
