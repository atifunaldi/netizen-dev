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
    let categories: [Int]?
    let embedded: Embedded?
    enum CodingKeys: String, CodingKey {
        case id, title, excerpt, date, categories
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
    @State private var lastRotation = Date.now
    @State private var lastRefresh = Date.distantPast

    private let navy = Color(red: 0.012, green: 0.082, blue: 0.176)
    private let red = Color(red: 1, green: 0.188, blue: 0.29)
    private let categories: [(String, Int?)] = [
        ("TÜMÜ", nil), ("TREND", nil), ("TEKNOLOJİ", nil),
        ("KÜLTÜR", nil), ("SANAT", nil), ("AİLE", nil), ("BEYEFENDİ", nil)
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let item = feed.headlines.isEmpty ? nil : feed.headlines[selected % feed.headlines.count]
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 5) {
                            (Text("Netizen").foregroundColor(.white) + Text("list").foregroundColor(red))
                                .font(.system(size: 61, weight: .heavy))
                            Text("İNTERNET VATANDAŞLARININ BULUŞMA NOKTASI")
                                .font(.system(size: 17, weight: .medium))
                                .tracking(3)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                        Text(context.date, format: .dateTime.day().month(.wide).year().weekday(.wide))
                            .font(.system(size: 19, weight: .medium))
                        Rectangle().fill(.white.opacity(0.55)).frame(width: 2, height: 55)
                        Text(context.date, format: .dateTime.hour().minute())
                            .font(.system(size: 55, weight: .bold, design: .rounded))
                    }
                    .frame(height: 120)

                    if let item {
                        HStack(alignment: .top, spacing: 44) {
                            AsyncImage(url: item.imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                navy.overlay { ProgressView().tint(.white) }
                            }
                            .frame(width: geometry.size.width * 0.49, height: geometry.size.height - 235)
                            .clipped()

                            VStack(alignment: .leading, spacing: 21) {
                                Text(item.title.rendered.plainText)
                                    .font(.system(size: 48, weight: .heavy))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(4)
                                Text(item.date.prefix(10))
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(item.excerpt.rendered.plainText)
                                    .font(.system(size: 27))
                                    .lineSpacing(8)
                                    .foregroundStyle(.white.opacity(0.88))
                                    .lineLimit(11)
                                Spacer(minLength: 0)
                                Text("Okumaya devam →")
                                    .font(.system(size: 22, weight: .semibold))
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(red).frame(height: 3).offset(y: 7)
                                    }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                        .id(item.id)
                        .transition(.opacity)
                        .frame(maxHeight: .infinity)
                    } else {
                        Spacer()
                        Text(feed.status).font(.system(size: 36))
                        Spacer()
                    }

                    Rectangle().fill(red).frame(height: 4).padding(.top, 12)
                    HStack(spacing: 30) {
                        ForEach(categories.indices, id: \.self) { index in
                            Text(categories[index].0)
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 13)
                                .background(categories[index].0 == "TÜMÜ" ? red : .clear)
                        }
                        Spacer()
                        Text(String(format: "%02d / %02d", feed.headlines.isEmpty ? 0 : selected + 1, feed.headlines.count))
                            .font(.system(size: 19, weight: .bold, design: .monospaced))
                        Text("‹  ›").font(.system(size: 32, weight: .bold))
                    }
                    .frame(height: 83)
                }
                .padding(.horizontal, 55)
                .padding(.top, 20)
                .padding(.bottom, 22)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(navy)
                .animation(.easeInOut(duration: 1.2), value: selected)
            }
            .onChange(of: context.date) { _, now in
                if now.timeIntervalSince(lastRotation) >= 15 {
                    lastRotation = now
                    if !feed.headlines.isEmpty { selected = (selected + 1) % feed.headlines.count }
                }
                if now.timeIntervalSince(lastRefresh) >= 300 {
                    lastRefresh = now
                    Task { await feed.refresh() }
                }
            }
        }
        .task { await feed.refresh() }
        .persistentSystemOverlays(.hidden)
    }
}
