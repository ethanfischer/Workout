//
//  WorkoutWidgetLiveActivity.swift
//  WorkoutWidget
//
//  Created by Work on 1/16/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var currentExercise: String
        var nextExercise: String?
        var currentSet: Int
        var totalSets: Int
    }

    var workoutCategory: String
}

struct WorkoutWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.pink)
                    Text("REST")
                        .font(.headline)
                        .foregroundColor(.pink)
                    Spacer()
                    Text(context.state.endTime, style: .timer)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Current: \(context.state.currentExercise)")
                            .font(.subheadline)
                        if let next = context.state.nextExercise {
                            Text("Next: \(next)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.8))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.pink)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.currentExercise)
                            .font(.headline)
                        if let next = context.state.nextExercise {
                            Text("Next: \(next)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.pink)
            } compactTrailing: {
                Text(context.state.endTime, style: .timer)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                    .frame(minWidth: 36)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.pink)
            }
        }
    }
}

#Preview("Live Activity", as: .content, using: WorkoutActivityAttributes(workoutCategory: "Push")) {
    WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(45),
        currentExercise: "Bench Press",
        nextExercise: "Shoulder Press",
        currentSet: 2,
        totalSets: 4
    )
}
