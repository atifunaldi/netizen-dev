import ActivityKit
import SwiftUI
import WidgetKit

struct DriveLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DriveActivityAttributes.self) { context in
            HStack(spacing: 16) {
                Image(systemName: context.state.frostRisk ? "snowflake" : "thermometer.medium")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(context.state.frostRisk ? Color(red: 1, green: 0.19, blue: 0.29) : .white)
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.temperatureLabel).font(.system(size: 38, weight: .bold, design: .rounded)).minimumScaleFactor(0.7).lineLimit(1)
                    if context.state.frostRisk {
                        Text("Donma riski").font(.system(size: 16, weight: .semibold))
                    } else {
                        Text(context.state.locationName ?? "Konum bilinmiyor").font(.system(size: 15, weight: .medium)).lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(Color(red: 3/255, green: 21/255, blue: 45/255))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.temperatureLabel).font(.title2.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.frostRisk ? "Donma riski" : (context.state.locationName ?? "Konum bilinmiyor"))
                }
            } compactLeading: {
                Image(systemName: context.state.frostRisk ? "snowflake" : "thermometer.medium")
            } compactTrailing: {
                Text(context.state.temperatureLabel).font(.system(size: 13, weight: .bold))
            } minimal: {
                Image(systemName: "thermometer.medium")
            }
        }
    }
}

@main
struct DriveWidgetBundle: WidgetBundle {
    var body: some Widget { DriveLiveActivityWidget() }
}
