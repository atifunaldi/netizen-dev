import ActivityKit
import Foundation

@MainActor
final class DriveActivityManager: ObservableObject {
    @Published var message = "Hazır"
    private var current: Activity<DriveActivityAttributes>?

    func startPreview(temperature: Int = 3, location: String = "Örnek konum") async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Live Activities ayarlardan etkinleştirilmeli."
            return
        }
        do {
            let attributes = DriveActivityAttributes(title: "Araç Bilgi Paneli")
            let state = DriveActivityAttributes.ContentState(
                temperatureCelsius: temperature, locationName: location, observedAt: .now
            )
            current = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60)),
                pushType: nil
            )
            message = "Live Activity başlatıldı."
        } catch {
            message = "Başlatılamadı: \(error.localizedDescription)"
        }
    }

    func stop() async {
        for activity in Activity<DriveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        current = nil
        message = "Durduruldu."
    }
}
