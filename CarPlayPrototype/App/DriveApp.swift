import SwiftUI

@main
struct DriveApp: App {
    var body: some Scene {
        WindowGroup { DriveContentView() }
    }
}

struct DriveContentView: View {
    @StateObject private var manager = DriveActivityManager()
    @StateObject private var weather = WeatherLocation()

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color(red: 1, green: 0.04, blue: 0.22))
                    .accessibilityHidden(true)
                Text("Araç Bilgi Paneli")
                    .font(.largeTitle.bold())
                Text("Netizen Drive 1.1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Konum izniyle güncel hava sıcaklığını alabilir ve Live Activity başlatabilirsiniz. CarPlay bağlantısı henüz etkin değildir.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button {
                    weather.request()
                } label: {
                    Label("Konum ve hava durumunu al", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Text(weather.temperature.map { "\($0)°C" } ?? "—°C")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(weather.status).font(.footnote).foregroundStyle(.secondary)
                Button {
                    Task { await manager.startPreview(temperature: weather.temperature ?? 3, location: weather.temperature == nil ? "Örnek konum" : weather.placeName) }
                } label: {
                    Label(weather.temperature == nil ? "3°C örnek testi başlat" : "Güncel sıcaklıkla başlat", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    Task { await manager.stop() }
                } label: {
                    Label("Testi durdur", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                Text(manager.message)
                    .font(.footnote)
                    .accessibilityLabel("Test durumu: \(manager.message)")
                Spacer(minLength: 12)
                Text("Powered by Netizen Global Agency")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Netizen Drive")
        }
        .tint(Color(red: 1, green: 0.04, blue: 0.22))
    }
}
