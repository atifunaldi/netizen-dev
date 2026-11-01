import CoreLocation
import Foundation

@MainActor
final class WeatherLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var temperature: Int?
    @Published var placeName = "Konum bekleniyor"
    @Published var status = "Konum izni verilmedi."
    @Published var updateSequence = 0
    @Published var isTracking = false
    private let geocoder = CLGeocoder()
    private var lastWeatherTime = Date.distantPast
    private var lastWeatherLocation: CLLocation?
    private var lastRoadLocation: CLLocation?
    private var lastRoadTime = Date.distantPast
    private var isGeocoding = false
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 35
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startDriving() {
        isTracking = true
        request()
    }

    func stopDriving() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        status = "Sürüş durduruldu."
    }

    func request() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
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
        guard isTracking, let location = locations.last,
              location.horizontalAccuracy >= 0, location.horizontalAccuracy < 120,
              abs(location.timestamp.timeIntervalSinceNow) < 30 else { return }

        let roadDistance = lastRoadLocation.map { location.distance(from: $0) } ?? .infinity
        if !isGeocoding && roadDistance > 35 && Date().timeIntervalSince(lastRoadTime) > 8 {
            lastRoadLocation = location
            lastRoadTime = .now
            isGeocoding = true
            Task {
                defer { isGeocoding = false }
                do {
                    let marks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "tr_TR"))
                    guard isTracking else { return }
                    if let road = marks.first?.thoroughfare, !road.isEmpty, road != placeName {
                        placeName = road
                        updateSequence += 1
                    }
                } catch {
                    status = "Yol adı geçici olarak alınamadı."
                }
            }
        }

        let weatherDistance = lastWeatherLocation.map { location.distance(from: $0) } ?? .infinity
        if Date().timeIntervalSince(lastWeatherTime) > 600 || weatherDistance > 10000 {
            lastWeatherTime = .now
            lastWeatherLocation = location
            Task { await fetchWeather(at: location.coordinate) }
        }
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
            guard isTracking else { return }
            status = "Güncel sıcaklık alındı."
            updateSequence += 1
        } catch {
            status = "Hava durumu alınamadı: \(error.localizedDescription)"
        }
    }
}
