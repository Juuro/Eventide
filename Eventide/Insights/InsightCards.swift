import SwiftUI

// MARK: - Shared chrome

/// Calm card container: rounded, padded, subtle elevated background.
struct InsightCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

/// Consistent card title row.
struct CardHeader: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Summary

struct SummaryCard: View {
    let text: String

    var body: some View {
        InsightCard {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(text)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("What stands out. \(text)")
    }
}

// MARK: - Rhythm

struct RhythmCard: View {
    let rhythm: InsightsResult.Rhythm

    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(title: "Your rhythm", systemImage: "moon.stars", tint: Theme.accent)
                Text(daysLine)
                    .font(.body)
                    .foregroundStyle(.secondary)
                balanceBar
                HStack {
                    legend(color: Theme.accent, label: "Did Well", value: rhythm.didWellTotal)
                    Spacer()
                    legend(color: Theme.accentRose, label: "Enjoyed", value: rhythm.enjoyedTotal)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Your rhythm. \(daysLine) Did Well, \(rhythm.didWellTotal) notes. Enjoyed, \(rhythm.enjoyedTotal) notes."
        )
    }

    private var daysLine: String {
        "You reflected on \(rhythm.daysReflected) \(rhythm.daysReflected == 1 ? "day" : "days")."
    }

    private var balanceBar: some View {
        GeometryReader { geo in
            let total = CGFloat(max(rhythm.total, 1))
            let didWellWidth = geo.size.width * CGFloat(rhythm.didWellTotal) / total
            HStack(spacing: 0) {
                Rectangle().fill(Theme.accent).frame(width: didWellWidth)
                Rectangle().fill(Theme.accentRose)
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }

    private func legend(color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text("\(value)").font(.caption.monospacedDigit()).foregroundStyle(.primary)
        }
    }
}

// MARK: - Themes

struct ThemesCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    let topics: [InsightsResult.Topic]

    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(title: title, systemImage: systemImage, tint: tint)
                FlowLayout(spacing: 8) {
                    ForEach(topics) { topic in
                        Text(topic.term)
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(tint.opacity(0.12)))
                            .foregroundStyle(tint)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(topics.map(\.term).joined(separator: ", "))")
    }
}

// MARK: - People

struct PeopleCard: View {
    let people: [InsightsResult.Person]

    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(title: "People in your days", systemImage: "person.2", tint: Theme.accent)
                VStack(spacing: 10) {
                    ForEach(people) { person in
                        HStack {
                            Text(person.name).font(.body)
                            Spacer()
                            Text("\(person.days) \(person.days == 1 ? "day" : "days")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "People in your days. " +
            people.map { "\($0.name), \($0.days) \($0.days == 1 ? "day" : "days")" }.joined(separator: ". ")
        )
    }
}

// MARK: - Flow layout

/// Minimal wrapping layout for theme chips. Reflows naturally with Dynamic Type.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widestRow = max(widestRow, x - spacing)
        }
        return CGSize(width: min(maxWidth, widestRow), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
