import Foundation

/// Immutable data for the first on-device prototype. No network or location permission is needed.
struct DriveSnapshot: Codable, Equatable {
    let temperatureCelsius: Double?
    let locationName: String?
    let roadName: String?
    let speedLimitKmh: Int?
    let observedAt: Date

    var frostRisk: Bool { temperatureCelsius.map { $0 < 4 } ?? false }
    var temperatureLabel: String {
        guard let temperatureCelsius else { return "—" }
        return String(format: "%.0f°C", temperatureCelsius)
    }

    static let preview = DriveSnapshot(
        temperatureCelsius: 3,
        locationName: "Konum örneği",
        roadName: nil,
        speedLimitKmh: nil,
        observedAt: .now
    )
}
