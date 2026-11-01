import ActivityKit
import Foundation

@MainActor
final class DriveActivityManager: ObservableObject {
    @Published var message = "Hazır"

    func startPreview(temperature: Int = 3, location: String = "Örnek konum") async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Live Activities ayarlardan etkinleştirilmeli."
            return
        }
        let state = DriveActivityAttributes.ContentState(
            temperatureCelsius: Double(temperature), locationName: location, observedAt: .now
        )
        do {
            // Reuse the existing activity instead of creating duplicate dashboard cards.
            if let existing = Activity<DriveActivityAttributes>.activities.first {
                await existing.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60)))
                message = "Live Activity güncellendi."
            } else {
                let attributes = DriveActivityAttributes(title: "Araç Bilgi Paneli")
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60)),
                    pushType: nil
                )
                message = "Live Activity başlatıldı."
            }
        } catch {
            message = "Başlatılamadı: \(error.localizedDescription)"
        }
    }


    func updateIfActive(temperature: Int, location: String) async {
        guard !Activity<DriveActivityAttributes>.activities.isEmpty else { return }
        let state = DriveActivityAttributes.ContentState(
            temperatureCelsius: Double(temperature),
            locationName: location,
            observedAt: .now
        )
        for activity in Activity<DriveActivityAttributes>.activities {
            await activity.update(
                ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60))
            )
        }
        message = "Güncel hava durumu Live Activity'ye aktarıldı."
    }

    func stop() async {
        for activity in Activity<DriveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        message = "Durduruldu."
    }
}
