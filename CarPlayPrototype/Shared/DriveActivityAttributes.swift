import ActivityKit
import Foundation

struct DriveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var temperatureCelsius: Double?
        var locationName: String?
        var observedAt: Date

        var frostRisk: Bool { temperatureCelsius.map { $0 < 4 } ?? false }
        var temperatureLabel: String {
            guard let temperatureCelsius else { return "—" }
            return String(format: "%.0f°C", temperatureCelsius)
        }
    }

    var title: String
}
