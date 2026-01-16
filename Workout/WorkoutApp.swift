import SwiftUI
import SwiftData

@main
struct WorkoutApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Workout.self, CompletedExercise.self, ExerciseSet.self])
    }
}
