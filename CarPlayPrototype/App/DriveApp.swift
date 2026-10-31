import SwiftUI

@main
struct DriveApp: App {
    var body: some Scene {
        WindowGroup { DriveContentView() }
    }
}

struct DriveContentView: View {
    @StateObject private var manager = DriveActivityManager()

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
                Text("Bu sürüm Live Activity önizlemesidir. Gerçek hava, GPS ve CarPlay verileri henüz bağlı değildir.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button {
                    Task { await manager.startPreview() }
                } label: {
                    Label("3°C ile testi başlat", systemImage: "play.fill")
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
