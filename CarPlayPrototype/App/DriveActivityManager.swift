import ActivityKit
import Foundation

@MainActor
final class DriveActivityManager: ObservableObject {
    @Published var message = "Hazır"
    private var current: Activity<DriveActivityAttributes>?

    func startOrUpdate(temperature: Int?, roadName: String?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Live Activities ayarlardan etkinleştirilmeli."
            return
        }
        if Activity<DriveActivityAttributes>.activities.isEmpty {
            do {
                let state = DriveActivityAttributes.ContentState(
                    temperatureCelsius: temperature.map(Double.init),
                    locationName: roadName,
                    observedAt: .now
                )
                current = try Activity.request(
                    attributes: DriveActivityAttributes(title: "Araç Bilgi Paneli"),
                    content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60)),
                    pushType: nil
                )
                message = "Live Activity başlatıldı."
            } catch {
                message = "Başlatılamadı: \(error.localizedDescription)"
            }
        } else {
            await updateDrivingInfo(temperature: temperature, roadName: roadName)
        }
    }

    func updateDrivingInfo(temperature: Int?, roadName: String?) async {
        let state = DriveActivityAttributes.ContentState(
            temperatureCelsius: temperature.map(Double.init),
            locationName: roadName,
            observedAt: .now
        )
        for activity in Activity<DriveActivityAttributes>.activities {
            await activity.update(
                ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60))
            )
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
