import Foundation

struct InProgressWorkoutState: Codable, Hashable {
    let category: String
    let exerciseNames: [String]
    var currentExerciseIndex: Int
    var currentSetIndex: Int
    var weight: Double
    var reps: Int
    var completedSets: [[SerializableSet]]
    var elapsedTime: Int
    var lastSaveTime: Date
    var isPaused: Bool
    var isResting: Bool
    var restTimeRemaining: Int
    var pausedRestTimeRemaining: Int?

    struct SerializableSet: Codable, Hashable {
        let setNumber: Int
        let weight: Double
        let reps: Int
    }
}
