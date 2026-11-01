import SwiftUI
import Combine

@main
struct DriveApp: App {
    var body: some Scene {
        WindowGroup { DriveContentView() }
    }
}

struct DriveContentView: View {
    private let navy = Color(red: 3/255, green: 21/255, blue: 45/255)
    private let panel = Color(red: 7/255, green: 29/255, blue: 56/255)
    private let accent = Color(red: 1, green: 48/255, blue: 74/255)
    private let border = Color(red: 23/255, green: 69/255, blue: 104/255)
    @StateObject private var manager = DriveActivityManager()
    @StateObject private var weather = WeatherLocation()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
                Text("NETIZEN  •  DRIVE")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white)
                Text("Araç Bilgi Paneli")
                    .font(.largeTitle.bold())
                Text("Netizen Drive 1.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Konum izniyle güncel hava sıcaklığını alabilir ve Live Activity başlatabilirsiniz. Live Activity, desteklenen CarPlay ekranlarında da görüntülenebilir.")
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
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(panel, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                Text(weather.status).font(.footnote).foregroundStyle(.secondary)
                if let updated = weather.lastUpdated {
                    Text("Son hava durumu: \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Button("Hava durumunu yenile") { weather.request() }
                    .disabled(weather.isLoading)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(navy)
            .foregroundStyle(.white)
            .navigationTitle("Netizen Drive")
            .toolbarBackground(navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onReceive(weather.$lastUpdated.compactMap { $0 }) { _ in
            guard let temperature = weather.temperature else { return }
            Task {
                await manager.updateIfActive(temperature: temperature, location: weather.placeName)
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }
}
