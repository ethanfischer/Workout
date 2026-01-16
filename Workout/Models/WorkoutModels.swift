import Foundation
import SwiftData

enum WorkoutCategory: String, Codable, CaseIterable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
}

@Model
class Workout {
    var id: UUID
    var date: Date
    var category: WorkoutCategory
    var durationSeconds: Int
    @Relationship(deleteRule: .cascade) var exercises: [CompletedExercise]

    init(category: WorkoutCategory, exercises: [CompletedExercise] = []) {
        self.id = UUID()
        self.date = Date()
        self.category = category
        self.durationSeconds = 0
        self.exercises = exercises
    }
}

@Model
class CompletedExercise {
    var id: UUID
    var name: String
    var order: Int
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]

    init(name: String, order: Int, sets: [ExerciseSet] = []) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.sets = sets
    }
}

@Model
class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int

    init(setNumber: Int, weight: Double, reps: Int) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
    }
}
