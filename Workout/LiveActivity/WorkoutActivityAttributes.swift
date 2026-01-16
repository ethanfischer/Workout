import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var currentExercise: String
        var nextExercise: String?
        var currentSet: Int
        var totalSets: Int
    }

    var workoutCategory: String
}
