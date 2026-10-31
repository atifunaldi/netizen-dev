import SwiftUI

@main
struct NetizenSignageApp: App {
    var body: some Scene {
        WindowGroup { SignageView() }
    }
}

private struct Headline: Decodable, Identifiable {
    struct Rendered: Decodable { let rendered: String }
    struct Media: Decodable {
        struct Details: Decodable {
            struct Size: Decodable { let source_url: URL? }
            let full: Size?
            let large: Size?
        }
        let source_url: URL?
        let media_details: Details?
    }
    struct Embedded: Decodable {
        let wpFeaturedmedia: [Media]?
        enum CodingKeys: String, CodingKey {
            case wpFeaturedmedia = "wp:featuredmedia"
        }
    }
    let id: Int
    let title: Rendered
    let excerpt: Rendered
    let date: String
    let embedded: Embedded?
    enum CodingKeys: String, CodingKey {
        case id, title, excerpt, date
        case embedded = "_embedded"
    }
    var imageURL: URL? {
        guard let media = embedded?.wpFeaturedmedia?.first else { return nil }
        return media.media_details?.large?.source_url ?? media.media_details?.full?.source_url ?? media.source_url
    }
}

private extension String {
    var plainText: String {
        replacingOccurrences(of: "<[^>]*>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#8217;", with: "’")
            .replacingOccurrences(of: "&#8230;", with: "…")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
private final class SignageFeed: ObservableObject {
    @Published var headlines: [Headline] = []
    @Published var status = "Netizenlist haberleri yükleniyor…"

    func refresh() async {
        guard let url = URL(string: "https://netizenlist.com/wp-json/wp/v2/posts?per_page=20&_embed=1") else { return }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let fetched = try JSONDecoder().decode([Headline].self, from: data)
            headlines = fetched
            status = fetched.isEmpty ? "Henüz haber yok." : ""
        } catch {
            status = "Haber akışı şu anda alınamıyor."
        }
    }
}

struct SignageView: View {
    @StateObject private var feed = SignageFeed()
    @State private var selected = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = Int(context.date.timeIntervalSince1970)
            let item = feed.headlines.isEmpty ? nil : feed.headlines[(selected + feed.headlines.count) % feed.headlines.count]
            ZStack {
                Color(red: 0.012, green: 0.082, blue: 0.176).ignoresSafeArea()
                if let url = item?.imageURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(red: 0.012, green: 0.082, blue: 0.176)
                    }
                    .id(url)
                    .ignoresSafeArea()
                    .overlay {
                        LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.25), .black.opacity(0.9)],
                                       startPoint: .top, endPoint: .bottom)
                    }
                }
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        HStack(spacing: 20) {
                            Image("NetizenMark")
                                .resizable()
                                .frame(width: 88, height: 88)
                            VStack(alignment: .leading) {
                                Text("NETIZEN")
                                    .font(.system(size: 42, weight: .heavy))
                                    .tracking(5)
                                Text("DIGITAL SIGNAGE")
                                    .font(.system(size: 18, weight: .medium))
                                    .tracking(4)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(context.date, format: .dateTime.hour().minute())
                                .font(.system(size: 66, weight: .bold, design: .rounded))
                            Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                                .font(.system(size: 22))
                        }
                    }
                    Spacer()
                    if let item {
                        Text("NETIZENLIST")
                            .font(.system(size: 23, weight: .bold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.red)
                        Text(item.title.rendered.plainText)
                            .font(.system(size: 66, weight: .heavy))
                            .lineLimit(3)
                        Text(item.excerpt.rendered.plainText)
                            .font(.system(size: 30))
                            .lineLimit(2)
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        Text(feed.status)
                            .font(.system(size: 32))
                    }
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 5)
                    HStack {
                        Text("NETIZENLIST")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(.red)
                        Text(feed.headlines.prefix(4).map { $0.title.rendered.plainText }.joined(separator: "    •    "))
                            .font(.system(size: 19))
                            .lineLimit(1)
                        Spacer()
                        Text("Powered by Netizen Global Agency")
                            .font(.system(size: 17))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(65)
                .foregroundStyle(.white)
            }
            .onChange(of: elapsed / 15) { _, _ in
                if !feed.headlines.isEmpty { selected = (selected + 1) % feed.headlines.count }
            }
            .onChange(of: elapsed / 300) { _, _ in
                Task { await feed.refresh() }
            }
        }
        .task { await feed.refresh() }
        .persistentSystemOverlays(.hidden)
    }
}
