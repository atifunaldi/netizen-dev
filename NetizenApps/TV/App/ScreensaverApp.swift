import SwiftUI

@main
struct NetizenScreensaverApp: App {
    var body: some Scene {
        WindowGroup { ScreensaverView() }
    }
}

struct ScreensaverView: View {
    @State private var startedAt = Date()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let seconds = timeline.date.timeIntervalSince(startedAt)
            let driftX = sin(seconds / 36) * 90
            let driftY = cos(seconds / 44) * 60
            GeometryReader { geometry in
                ZStack {
                    Color(red: 0.012, green: 0.082, blue: 0.176).ignoresSafeArea()
                    Circle()
                        .fill(Color(red: 1, green: 0.04, blue: 0.22))
                        .frame(width: 310, height: 310)
                        .overlay {
                            Capsule().fill(.white).frame(width: 44, height: 212)
                        }
                        .offset(x: driftX, y: driftY - 80)
                    VStack {
                        Spacer()
                        Text(timeline.date, style: .time)
                            .font(.system(size: 72, weight: .thin, design: .rounded))
                        Text("NETIZEN")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(8)
                        Spacer().frame(height: 30)
                        Text("Powered by Netizen Global Agency")
                            .font(.system(size: 19))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .persistentSystemOverlays(.hidden)
    }
}
