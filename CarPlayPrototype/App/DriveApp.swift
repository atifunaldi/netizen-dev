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

    private let navy = Color(red: 3.0 / 255, green: 21.0 / 255, blue: 45.0 / 255)
    private let panel = Color(red: 7.0 / 255, green: 29.0 / 255, blue: 56.0 / 255)
    private let red = Color(red: 1, green: 48.0 / 255, blue: 74.0 / 255)

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                (Text("NETIZEN ").foregroundColor(.white) + Text("DRIVE").foregroundColor(red))
                    .font(.system(size: 30, weight: .black))
                Spacer()
                Image(systemName: "car.side.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(red)
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 20) {
                Label("ARAÇ BİLGİ PANELİ", systemImage: "steeringwheel")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.75))
                Text(weather.placeName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Rectangle().fill(red).frame(height: 3)
                HStack(alignment: .firstTextBaseline) {
                    Text(weather.temperature.map { "\($0)°C" } ?? "—°C")
                        .font(.system(size: 66, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("DIŞ SICAKLIK")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(weather.status)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panel, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.65), lineWidth: 1))

            if !weather.isTracking {
                Button {
                    weather.startDriving()
                } label: {
                    Label("Sürüşü başlat", systemImage: "location.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .background(red, in: Capsule())
            } else {
                Button {
                    weather.stopDriving()
                    Task { await manager.stop() }
                } label: {
                    Label("Sürüşü bitir", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .background(panel, in: Capsule())
                .overlay(Capsule().stroke(red, lineWidth: 1))
            }

            if weather.isTracking && weather.temperature == nil {
                Text("Konum alındıktan sonra sıcaklık ve yol bilgisi otomatik güncellenecek.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
            Text("Powered by Netizen Global Agency")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .overlay(alignment: .top) { red.frame(height: 2) }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(navy.ignoresSafeArea())
        .foregroundStyle(.white)
        .onAppear {
            weather.requestPermissionOnLaunch()
        }
        .onChange(of: weather.updateSequence) { _, _ in
            guard weather.isTracking && weather.temperature != nil else { return }
            Task { await manager.startOrUpdate(temperature: weather.temperature, roadName: weather.placeName) }
        }
    }
}
