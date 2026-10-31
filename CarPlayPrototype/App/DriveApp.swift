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
            VStack(spacing: 20) {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 54))
                Text("Araç Bilgi Paneli").font(.largeTitle.bold())
                Text("Bu ilk prototip örnek sıcaklık kullanır. Gerçek hava ve GPS verisi henüz bağlı değildir.")
                    .multilineTextAlignment(.center)
                Button("3°C ile test başlat") {
                    Task { await manager.startPreview() }
                }
                .buttonStyle(.borderedProminent)
                Button("Testi durdur") {
                    Task { await manager.stop() }
                }
                Text(manager.message).font(.footnote)
            }
            .padding()
        }
    }
}
