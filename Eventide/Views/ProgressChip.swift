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

    private var animation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.4)
    }

    // MARK: - Expanded (default, above the tab bar)
    //
    // Hierarchy: hero fraction (primary) → two quiet category tracks (secondary)
    // → streak / completion (tertiary). One accent, system material, no shadow.

    private var expanded: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("\(filled)/\(total)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(filled)))

            VStack(spacing: 7) {
                track(symbol: ReflectionSection.didWell.systemImage,
                      label: ReflectionSection.didWell.title, filled: didWellFilled)
                track(symbol: ReflectionSection.enjoyed.systemImage,
                      label: ReflectionSection.enjoyed.title, filled: enjoyedFilled)
            }

            trailingStatus
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    /// One category: faint symbol + label, a continuous proportional rail, exact count.
    private func track(symbol: String, label: String, filled: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Theme.accent.opacity(0.7))
                .frame(width: 12)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(Theme.accent.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(filled) / CGFloat(slots))
                        .animation(animation, value: filled)
                }
            }
            .frame(height: 4)

            Text("\(filled)/\(slots)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var trailingStatus: some View {
        if isComplete {
            Image(systemName: "moon.stars")
                .font(.subheadline)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Theme.accent)
                .transition(.opacity)
        } else if streak >= 2 {
            HStack(spacing: 3) {
                Image(systemName: "flame")
                    .symbolRenderingMode(.hierarchical)
                Text("\(streak)")
                    .monospacedDigit()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Inline (compact, attached in the tab bar row when scrolled)
    //
    // Total-first: a hairline overall ring + fraction, streak demoted behind a middot.

    private var inline: some View {
        HStack(spacing: 8) {
            if isComplete {
                Image(systemName: "moon.stars")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.accent)
                Text("Done")
                    .font(.subheadline.weight(.medium))
            } else {
                miniRing
                Text("\(filled)/\(total)")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .contentTransition(.numericText(value: Double(filled)))
                if streak >= 2 {
                    Text("·").foregroundStyle(.tertiary)
                    HStack(spacing: 3) {
                        Image(systemName: "flame")
                            .symbolRenderingMode(.hierarchical)
                        Text("\(streak)").monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    /// Overall-progress ring for the compact state — calmer than a fraction alone.
    private var miniRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 2)
            Circle()
                .trim(from: 0, to: CGFloat(filled) / CGFloat(total))
                .stroke(Theme.accent.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(animation, value: filled)
        }
        .frame(width: 16, height: 16)
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
