import SwiftUI

@main
struct NetizenNewsApp: App {
    @UIApplicationDelegateAdaptor(NewsAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup { NewsHomeView() }
    }
}

enum Publication: String, CaseIterable, Identifiable {
    case netizen = "Netizenlist"
    case families = "Annelere Fikir Olsun"

    var id: String { rawValue }
    var baseURL: URL {
        switch self {
        case .netizen: return URL(string: "https://netizenlist.com")!
        case .families: return URL(string: "https://annelerefikirolsun.com")!
        }
    }
}

struct WPTitle: Decodable { let rendered: String }
struct WPPost: Decodable, Identifiable {
    struct Media: Decodable { let source_url: URL? }
    struct Embedded: Decodable {
        let media: [Media]?
        enum CodingKeys: String, CodingKey { case media = "wp:featuredmedia" }
    }
    let id: Int
    let date: String
    let link: URL
    let title: WPTitle
    let excerpt: WPTitle
    let content: WPTitle?
    let embedded: Embedded?
    enum CodingKeys: String, CodingKey {
        case id, date, link, title, excerpt, content
        case embedded = "_embedded"
    }
    var imageURL: URL? { embedded?.media?.first?.source_url }
    var readableBody: String {
        let full = content?.rendered.newsFormattedHTML ?? ""
        return full.isEmpty ? excerpt.rendered.newsFormattedHTML : full
    }
}

@MainActor
final class NewsModel: ObservableObject {
    @Published var posts: [WPPost] = []
    @Published var error: String?
    @Published var loading = false

    func load(_ publication: Publication) async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let endpoint = publication.baseURL.appending(path: "wp-json/wp/v2/posts")
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "per_page", value: "20"),
                                     URLQueryItem(name: "orderby", value: "date"),
                                     URLQueryItem(name: "_embed", value: "1")]
            var request = URLRequest(url: components.url!)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            posts = try JSONDecoder().decode([WPPost].self, from: data)
        } catch {
            posts = []
            self.error = "Haberler alınamadı: \(error.localizedDescription)"
        }
    }
}

extension String {
    var newsFormattedHTML: String {
        var html = self
        html = html.replacingOccurrences(of: "(?is)<(script|style|figure|figcaption)[^>]*>.*?</\\1>", with: "", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?i)<li\\b[^>]*>", with: "\n• ", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?i)</li\\s*>", with: "\n", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?i)</(p|div|h[1-6]|ul|ol|blockquote)\\s*>", with: "\n\n", options: .regularExpression)
        html = html.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&quot;": "\"", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " ", "&hellip;": "…", "&#8230;": "…", "&#8217;": "’", "&#8220;": "“", "&#8221;": "”", "&ndash;": "–", "&mdash;": "—"]
        for (entity, replacement) in entities {
            html = html.replacingOccurrences(of: entity, with: replacement)
        }
        html = html.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
        html = html.replacingOccurrences(of: " *\n *", with: "\n", options: .regularExpression)
        html = html.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return html.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var plainHTML: String {
        let withoutTags = replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return withoutTags
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#8217;", with: "’")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct NewsHomeView: View {
    @State private var publication: Publication = .netizen
    @StateObject private var model = NewsModel()
    @StateObject private var notifications = NewsNotificationManager.shared
    @State private var showSettings = false
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var votes: [String: Bool] = [:]
    @State private var animating = false
    @AppStorage(NewsNotificationSettings.netizen) private var notifyNetizen = true
    @AppStorage(NewsNotificationSettings.families) private var notifyFamilies = true

    private let navy = Color(red: 3 / 255, green: 21 / 255, blue: 45 / 255)
    private let panel = Color(red: 7 / 255, green: 29 / 255, blue: 56 / 255)
    private let red = Color(red: 1, green: 48 / 255, blue: 74 / 255)
    private let green = Color(red: 0.15, green: 0.88, blue: 0.26)

    private var visiblePosts: [WPPost] {
        Array(model.posts.dropFirst(currentIndex).prefix(2))
    }

    private func voteKey(_ post: WPPost) -> String {
        "\(publication.id):\(post.id)"
    }

    private func restoreVotes() {
        votes = (UserDefaults.standard.dictionary(forKey: "netizen.news.votes.v1") as? [String: Bool]) ?? [:]
    }

    private func castVote(liked: Bool) {
        guard !animating, currentIndex < model.posts.count else { return }
        animating = true
        let post = model.posts[currentIndex]
        votes[voteKey(post)] = liked
        UserDefaults.standard.set(votes, forKey: "netizen.news.votes.v1")
        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = CGSize(width: liked ? 850 : -850, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
            currentIndex += 1
            dragOffset = .zero
            animating = false
        }
    }

    private func resetDeck() {
        currentIndex = 0
        dragOffset = .zero
        animating = false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    (Text("NETIZEN MEDIA ").foregroundColor(.white) + Text("NEWS").foregroundColor(red))
                        .font(.system(size: 29, weight: .black))
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Button { showSettings = true } label: {
                        Image(systemName: "bell")
                            .font(.title3.bold())
                            .foregroundStyle(red)
                            .frame(width: 42, height: 42)
                            .background(panel, in: Circle())
                    }
                    .accessibilityLabel("Bildirim ayarları")
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 22)

                HStack(spacing: 0) {
                    ForEach(Publication.allCases) { source in
                        Button { publication = source; resetDeck() } label: {
                            Text(source.rawValue)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(publication == source ? red : Color.clear, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .overlay(Capsule().stroke(.white.opacity(0.8), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                if model.loading { ProgressView().tint(.white).padding() }
                if let error = model.error {
                    Text(error).foregroundStyle(.white).padding()
                }

                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ZStack {
                            if visiblePosts.count > 1 {
                                NewsStoryCard(post: visiblePosts[1], panel: panel, red: red)
                                    .padding(.horizontal, 4)
                                    .scaleEffect(0.97)
                                    .offset(y: 10)
                                    .allowsHitTesting(false)
                            }
                            if let post = visiblePosts.first {
                                NewsStoryCard(post: post, panel: panel, red: red)
                                    .offset(dragOffset)
                                    .rotationEffect(.degrees(Double(dragOffset.width / 32)))
                                    .gesture(
                                        DragGesture(minimumDistance: 15)
                                            .onChanged { value in
                                                guard !animating else { return }
                                                dragOffset = value.translation
                                            }
                                            .onEnded { value in
                                                if value.translation.width > 100 {
                                                    castVote(liked: true)
                                                } else if value.translation.width < -100 {
                                                    castVote(liked: false)
                                                } else {
                                                    withAnimation(.spring()) { dragOffset = .zero }
                                                }
                                            }
                                    )
                                    .accessibilityHint("Sağa kaydır: beğen. Sola kaydır: beğenme.")
                            } else if !model.loading && model.error == nil {
                                VStack(spacing: 14) {
                                    Text("Haberler tamamlandı").font(.title2.bold())
                                    Text("Beğenilen: \(votes.filter { $0.key.hasPrefix(publication.id + ":") && $0.value }.count)   Beğenilmeyen: \(votes.filter { $0.key.hasPrefix(publication.id + ":") && !$0.value }.count)")
                                        .font(.subheadline)
                                    Button("Yeniden gözden geçir") { resetDeck() }
                                        .tint(red)
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        HStack(spacing: 72) {
                            Image(systemName: "hand.thumbsdown")
                                .foregroundStyle(red)
                                .accessibilityLabel("Beğenmedim; sola kaydır")
                            Image(systemName: "hand.thumbsup")
                                .foregroundStyle(green)
                                .accessibilityLabel("Beğendim; sağa kaydır")
                        }
                        .font(.system(size: 27, weight: .medium))
                        .padding(.top, 22)
                        .padding(.bottom, 30)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }

                Text("Powered by Netizen Global Agency")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { red.frame(height: 2) }
            }
            .background(navy.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    Form {
                        Section("Yayın bildirimleri") {
                            Toggle("Netizenlist", isOn: $notifyNetizen)
                            Toggle("Annelere Fikir Olsun", isOn: $notifyFamilies)
                            Button("Bildirim izni iste") {
                                Task { await notifications.requestAuthorization() }
                            }
                            Text(notifications.status).font(.footnote)
                        }
                        Section {
                            Text("Bildirimlerin uygulama kapalıyken ulaşması için güvenli APNs gönderim sunucusu henüz kurulmalıdır.")
                                .font(.footnote)
                        }
                    }
                    .navigationTitle("Bildirimler")
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button("Bitti") { showSettings = false }
                    } }
                }
            }
            .onChange(of: notifications.selectedArticleURL) { _, url in
                guard let url else { return }
                UIApplication.shared.open(url)
                notifications.selectedArticleURL = nil
            }
            .task(id: publication) {
                restoreVotes()
                resetDeck()
                await model.load(publication)
            }
        }
        .tint(red)
    }
}

private struct NewsStoryCard: View {
    let post: WPPost
    let panel: Color
    let red: Color

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: post.imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.white.opacity(0.08))
                        .overlay { Image(systemName: "newspaper").foregroundStyle(.white.opacity(0.4)) }
                }
                .frame(height: min(geometry.size.height * 0.30, 230))
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 14) {
                    Text(post.title.rendered.plainHTML)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)
                        .padding(.leading, 12)
                        .overlay(alignment: .leading) { red.frame(width: 4) }

                    ScrollView {
                        Text(post.readableBody)
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.hidden)

                    Link(destination: post.link) {
                        Text("Haberin tamamını oku")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .underline()
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(panel)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white, lineWidth: 1.5))
        }
    }
}
