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
                Text("Netizen Drive 1.3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Sürüş sırasında bulunduğunuz yol ve dış hava sıcaklığı gösterilir.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button {
                    weather.startDriving()
                } label: {
                    Label("Sürüşü başlat", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Text(weather.temperature.map { "\($0)°C" } ?? "—°C")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(weather.placeName).font(.title3.bold())
                Text(weather.status).font(.footnote).foregroundStyle(.secondary)
                Button {
                    Task { await manager.startOrUpdate(temperature: weather.temperature, roadName: weather.placeName) }
                } label: {
                    Label("Live Activity başlat", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    weather.stopDriving(); Task { await manager.stop() }
                } label: {
                    Label("Sürüşü bitir", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                Text(manager.message)
                    .font(.footnote)
                    .accessibilityLabel("Sürüş durumu: \(manager.message)")
                Spacer(minLength: 12)
                Text("Powered by Netizen Global Agency")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Netizen Drive")
        }
        .onChange(of: weather.updateSequence) { _, _ in
            Task { await manager.startOrUpdate(temperature: weather.temperature, roadName: weather.placeName) }
        }
        .tint(Color(red: 1, green: 0.04, blue: 0.22))
    }
}
