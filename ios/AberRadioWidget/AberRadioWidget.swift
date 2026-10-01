import WidgetKit
import SwiftUI

private let liveURL = URL(string: "https://api.aberradio.com/api/2/radiocom/transmissions/now?format=json&timezone=Europe%2FLondon")!
private let appURL = URL(string: "aberradio://listen-live")!

private struct LiveProgramme: Decodable {
    let name: String?
    let description: String?
}

private struct LiveEntry: TimelineEntry {
    let date: Date
    let programmeName: String
    let presenter: String
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LiveEntry {
        LiveEntry(date: Date(), programmeName: "Aber Radio", presenter: "Live from Abergavenny")
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveEntry>) -> Void) {
        URLSession.shared.dataTask(with: liveURL) { data, _, _ in
            let live = data.flatMap { try? JSONDecoder().decode(LiveProgramme.self, from: $0) }
            let entry = LiveEntry(
                date: Date(),
                programmeName: live?.name?.nonEmpty ?? "Aber Radio Live",
                presenter: live?.description?.plainText.nonEmpty ?? "Live from Abergavenny"
            )
            completion(Timeline(
                entries: [entry],
                policy: .after(Date().addingTimeInterval(15 * 60))
            ))
        }.resume()
    }
}

private struct AberRadioWordmark: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("ABER").foregroundStyle(Color(red: 0, green: 0.33, blue: 0.24))
            Text("RADIO").foregroundStyle(Color(red: 1, green: 0.70, blue: 0))
        }
        .font(.system(size: 16, weight: .black, design: .rounded))
        .lineLimit(1)
    }
}

private struct WidgetContent: View {
    @Environment(\.widgetFamily) private var family
    let entry: LiveEntry

    @ViewBuilder
    var body: some View {
        let content = Group {
            if family == .systemMedium {
                medium
            } else {
                small
            }
        }
        .widgetURL(appURL)

        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                Color(red: 0.055, green: 0.055, blue: 0.055)
            }
        } else {
            content.background(Color(red: 0.055, green: 0.055, blue: 0.055))
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 7) {
            AberRadioWordmark()
            Spacer(minLength: 2)
            Label("LIVE", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption2.bold())
                .foregroundStyle(Color(red: 0.25, green: 0.76, blue: 0.25))
            Text(entry.programmeName)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
            Text("Tap to listen")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(2)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                AberRadioWordmark()
                Label("NOW ON AIR", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption2.bold())
                    .foregroundStyle(Color(red: 0.25, green: 0.76, blue: 0.25))
                Text(entry.programmeName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(entry.presenter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(systemName: "play.fill")
                .font(.title2.bold())
                .foregroundStyle(.black)
                .frame(width: 52, height: 52)
                .background(Color(red: 1, green: 0.70, blue: 0), in: Circle())
                .accessibilityLabel("Listen live")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(2)
    }
}

private extension String {
    var plainText: String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

@main
struct AberRadioWidget: Widget {
    let kind = "AberRadioNowPlaying"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetContent(entry: entry)
        }
        .configurationDisplayName("Aber Radio Live")
        .description("See what is on air and tap to listen live.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
