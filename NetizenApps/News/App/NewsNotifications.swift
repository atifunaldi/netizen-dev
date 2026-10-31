import Foundation
import UIKit
import UserNotifications

enum NewsNotificationSettings {
    static let netizen = "notifications.netizenlist"
    static let families = "notifications.families"
    static func enabled(_ publication: Publication) -> Bool {
        UserDefaults.standard.object(forKey: key(publication)) as? Bool ?? true
    }
    static func key(_ publication: Publication) -> String {
        publication == .netizen ? netizen : families
    }
}

@MainActor
final class NewsNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NewsNotificationManager()
    @Published var deviceToken: String?
    @Published var status = "Bildirimler etkinleştirilmedi."
    @Published var selectedArticleURL: URL?
    private override init() { super.init() }

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        do {
            let allowed = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if allowed {
                UIApplication.shared.registerForRemoteNotifications()
                status = "Bildirim izni verildi. Sunucu bağlantısı bekleniyor."
            } else {
                status = "Bildirim izni verilmedi."
            }
        } catch {
            status = "Bildirim izni alınamadı: \(error.localizedDescription)"
        }
    }

    func registered(_ token: Data) {
        deviceToken = token.map { String(format: "%02x", $0) }.joined()
        status = "Apple bildirim kaydı hazır. Sunucu bağlantısı bekleniyor."
        // The token must be sent only to a secured, verified notification backend.
        // Never log, commit, or send it to an untrusted public endpoint.
    }

    func registrationFailed(_ error: Error) {
        status = "Apple bildirim kaydı başarısız: \(error.localizedDescription)"
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           didReceive response: UNNotificationResponse,
                                           withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        let urlString = info["article_url"] as? String
        let publication = info["publication"] as? String
        Task { @MainActor in
            let shouldOpen = (publication == "netizenlist" && NewsNotificationSettings.enabled(.netizen)) ||
                             (publication == "families" && NewsNotificationSettings.enabled(.families))
            if shouldOpen, let urlString, let url = URL(string: urlString),
               url.scheme == "https",
               ["netizenlist.com", "annelerefikirolsun.com"].contains(url.host?.lowercased() ?? "") {
                selectedArticleURL = url
            }
            completionHandler()
        }
    }
}

final class NewsAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in NewsNotificationManager.shared.registered(deviceToken) }
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in NewsNotificationManager.shared.registrationFailed(error) }
    }
}
