import CoreLocation
import Foundation

@MainActor
final class WeatherLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var temperature: Int?
    @Published var placeName = "Konum bekleniyor"
    @Published var status = "Konum izni verilmedi."
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .restricted, .denied:
            status = "Konum erişimi kapalı. Ayarlar'dan izin verebilirsiniz."
        @unknown default:
            status = "Konum izni belirlenemedi."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "Konum alınamadı: \(error.localizedDescription)"
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        placeName = String(format: "%.3f, %.3f", location.coordinate.latitude, location.coordinate.longitude)
        status = "Hava durumu alınıyor…"
        Task { await fetchWeather(at: location.coordinate) }
    }

    private struct WeatherResponse: Decodable {
        struct Current: Decodable { let temperature_2m: Double }
        let current: Current
    }

    private func fetchWeather(at coordinate: CLLocationCoordinate2D) async {
        var parts = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        parts.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        do {
            let (data, response) = try await URLSession.shared.data(from: parts.url!)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            temperature = Int(try JSONDecoder().decode(WeatherResponse.self, from: data).current.temperature_2m.rounded())
            status = "Güncel sıcaklık alındı."
        } catch {
            status = "Hava durumu alınamadı: \(error.localizedDescription)"
        }
    }
}
