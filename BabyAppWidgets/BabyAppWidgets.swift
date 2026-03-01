import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct BabyAppTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BabyAppEntry {
        BabyAppEntry(
            date: Date(),
            lastSleep: "8h 30m",
            lastFeeding: "hace 2h",
            diaperCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BabyAppEntry) -> Void) {
        let entry = BabyAppEntry(
            date: Date(),
            lastSleep: "8h 30m",
            lastFeeding: "hace 2h",
            diaperCount: 5
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BabyAppEntry>) -> Void) {
        // TODO: Fetch real data from shared container / Supabase
        let entry = BabyAppEntry(
            date: Date(),
            lastSleep: "--",
            lastFeeding: "--",
            diaperCount: 0
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct BabyAppEntry: TimelineEntry {
    let date: Date
    let lastSleep: String
    let lastFeeding: String
    let diaperCount: Int
}

// MARK: - Widget View

struct BabyAppWidgetView: View {
    var entry: BabyAppEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.pink)
                Text("Mattia")
                    .font(.caption)
                    .fontWeight(.bold)
            }

            Spacer()

            HStack {
                Image(systemName: "moon.fill")
                    .font(.caption2)
                    .foregroundStyle(.indigo)
                Text(entry.lastSleep)
                    .font(.caption2)
            }

            HStack {
                Image(systemName: "fork.knife")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(entry.lastFeeding)
                    .font(.caption2)
            }

            HStack {
                Image(systemName: "drop.fill")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
                Text("\(entry.diaperCount) pañales")
                    .font(.caption2)
            }
        }
        .padding()
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundStyle(.pink)
                    Text("Mattia")
                        .font(.headline)
                }

                Text("Resumen del día")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    WidgetStat(icon: "moon.fill", value: entry.lastSleep, color: .indigo)
                    WidgetStat(icon: "fork.knife", value: entry.lastFeeding, color: .orange)
                    WidgetStat(icon: "drop.fill", value: "\(entry.diaperCount)", color: .cyan)
                }
            }
        }
        .padding()
    }
}

struct WidgetStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Widget Configuration

struct BabyAppWidget: Widget {
    let kind: String = "BabyAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BabyAppTimelineProvider()) { entry in
            BabyAppWidgetView(entry: entry)
        }
        .configurationDisplayName("Baby App")
        .description("Resumen rápido del cuidado de tu bebé.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct BabyAppWidgetBundle: WidgetBundle {
    var body: some Widget {
        BabyAppWidget()
    }
}
