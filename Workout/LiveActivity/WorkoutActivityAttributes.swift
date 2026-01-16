import ActivityKit
import Foundation

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
