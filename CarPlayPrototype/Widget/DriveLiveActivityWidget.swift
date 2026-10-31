import ActivityKit
import SwiftUI
import WidgetKit

struct DriveLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DriveActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: context.state.frostRisk ? "snowflake" : "thermometer.medium")
                    .foregroundStyle(context.state.frostRisk ? .orange : .primary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.temperatureLabel).font(.title2.bold())
                    if context.state.frostRisk {
                        Text("Donma riski").font(.caption.bold())
                    } else {
                        Text(context.state.locationName ?? "Konum bilinmiyor").font(.caption)
                    }
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color(.secondarySystemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.temperatureLabel).font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.frostRisk ? "Donma riski" : (context.state.locationName ?? "Konum bilinmiyor"))
                }
            } compactLeading: {
                Image(systemName: context.state.frostRisk ? "snowflake" : "thermometer.medium")
            } compactTrailing: {
                Text(context.state.temperatureLabel)
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
