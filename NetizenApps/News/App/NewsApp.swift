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
    let embedded: Embedded?
    enum CodingKeys: String, CodingKey {
        case id, date, link, title, excerpt
        case embedded = "_embedded"
    }
    var imageURL: URL? { embedded?.media?.first?.source_url }
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
    @AppStorage(NewsNotificationSettings.netizen) private var notifyNetizen = true
    @AppStorage(NewsNotificationSettings.families) private var notifyFamilies = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Yayın", selection: $publication) {
                    ForEach(Publication.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                if model.loading { ProgressView().padding() }
                if let error = model.error { Text(error).foregroundStyle(.red).padding() }
                List(model.posts) { post in
                    Link(destination: post.link) {
                        HStack(alignment: .top, spacing: 14) {
                            if let imageURL = post.imageURL {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Color.secondary.opacity(0.1))
                                }
                                .frame(width: 100, height: 85)
                                .clipped()
                                .cornerRadius(8)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                            Text(post.title.rendered.plainHTML)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(post.excerpt.rendered.plainHTML)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .refreshable { await model.load(publication) }
                Text("Powered by Netizen Global Agency")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .navigationTitle("Netizen News")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "bell")
                    }
                    .accessibilityLabel("Bildirim ayarları")
                }
            }
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
            .task(id: publication) { await model.load(publication) }
        }
        .tint(Color(red: 1, green: 0.04, blue: 0.22))
    }
}
