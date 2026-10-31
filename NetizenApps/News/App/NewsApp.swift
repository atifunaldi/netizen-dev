import SwiftUI

@main
struct NetizenNewsApp: App {
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
    let id: Int
    let date: String
    let link: URL
    let title: WPTitle
    let excerpt: WPTitle
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
                                     URLQueryItem(name: "orderby", value: "date")]
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.title.rendered.plainHTML)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(post.excerpt.rendered.plainHTML)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
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
            .navigationTitle("Netizen")
            .task(id: publication) { await model.load(publication) }
        }
        .tint(Color(red: 1, green: 0.04, blue: 0.22))
    }
}
