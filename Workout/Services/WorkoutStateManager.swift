import Foundation

class WorkoutStateManager {
    static let shared = WorkoutStateManager()
    private let key = "inProgressWorkout"

    private init() {}

    func save(_ state: InProgressWorkoutState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> InProgressWorkoutState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(InProgressWorkoutState.self, from: data)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
