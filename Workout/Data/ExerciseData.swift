import Foundation

enum ExerciseType: String, CaseIterable {
    case compound = "Compound"
    case unilateral = "Unilateral"
    case accessory = "Accessory/Isolation"
}

enum MediaType {
    case gif
    case none
}

struct ExerciseDefinition: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: ExerciseType
    let category: WorkoutCategory
    let defaultSets: Int
    let defaultReps: String

    var mediaFilename: String {
        name.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "_")
    }

    var mediaType: MediaType {
        if Bundle.main.url(forResource: mediaFilename, withExtension: "gif") != nil {
            return .gif
        }
        return .none
    }

    var mediaURL: URL? {
        Bundle.main.url(forResource: mediaFilename, withExtension: "gif")
    }

    // Custom Hashable conformance (exclude computed properties)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExerciseDefinition, rhs: ExerciseDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExerciseData {
    static let push: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Push Ups", type: .compound, category: .push, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Overhead Press", type: .compound, category: .push, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Bench Press", type: .compound, category: .push, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Lateral Raises", type: .accessory, category: .push, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Front Raises", type: .accessory, category: .push, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Tricep Extension", type: .accessory, category: .push, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "DB Chest Flys", type: .accessory, category: .push, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Tricep Rope Pushdown", type: .accessory, category: .push, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Rear Delt Fly", type: .accessory, category: .push, defaultSets: 3, defaultReps: "10-12"),
    ]

    static let pull: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Lat Pulldown", type: .compound, category: .pull, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Seated Row", type: .compound, category: .pull, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Pull Ups", type: .compound, category: .pull, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Bent Over Row", type: .compound, category: .pull, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Deadlift", type: .compound, category: .pull, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "DB Pullovers", type: .accessory, category: .pull, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Renegade Rows", type: .accessory, category: .pull, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Stiff Arm Pulldown", type: .accessory, category: .pull, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Rope Face Pull", type: .accessory, category: .pull, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "DB Curls", type: .accessory, category: .pull, defaultSets: 3, defaultReps: "10-12"),
    ]

    static let legs: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Squat Variation", type: .compound, category: .legs, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Deadlift", type: .compound, category: .legs, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Hip Thrust", type: .compound, category: .legs, defaultSets: 4, defaultReps: "10"),
        ExerciseDefinition(name: "Lunges", type: .unilateral, category: .legs, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Split Squats", type: .unilateral, category: .legs, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Split Stance RDL", type: .unilateral, category: .legs, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Step Ups", type: .unilateral, category: .legs, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Split Stance Hip Thrust", type: .unilateral, category: .legs, defaultSets: 3, defaultReps: "10-12"),
        ExerciseDefinition(name: "Leg Extension", type: .accessory, category: .legs, defaultSets: 3, defaultReps: "12-15"),
        ExerciseDefinition(name: "Leg Curl", type: .accessory, category: .legs, defaultSets: 3, defaultReps: "12-15"),
        ExerciseDefinition(name: "Cable Kickbacks", type: .accessory, category: .legs, defaultSets: 3, defaultReps: "12-15"),
        ExerciseDefinition(name: "Abductions", type: .accessory, category: .legs, defaultSets: 3, defaultReps: "12-15"),
        ExerciseDefinition(name: "Calf Raises", type: .accessory, category: .legs, defaultSets: 3, defaultReps: "12-15"),
    ]

    static func exercises(for category: WorkoutCategory) -> [ExerciseDefinition] {
        switch category {
        case .push: return push
        case .pull: return pull
        case .legs: return legs
        }
    }

    static func pickGuidance(for type: ExerciseType, category: WorkoutCategory) -> String {
        switch (category, type) {
        case (.push, .compound): return "Pick 2"
        case (.push, .accessory): return "Pick 3"
        case (.pull, .compound): return "Pick 2"
        case (.pull, .accessory): return "Pick 3"
        case (.legs, .compound): return "Pick 1-2"
        case (.legs, .unilateral): return "Pick 1-2"
        case (.legs, .accessory): return "Pick 2"
        default: return ""
        }
    }

    static func repsDisplay(for type: ExerciseType, category: WorkoutCategory) -> String {
        switch (category, type) {
        case (.push, .compound): return "3-4 x 10"
        case (.push, .accessory): return "3 x 10-12"
        case (.pull, .compound): return "3-4 x 10"
        case (.pull, .accessory): return "3 x 10-12"
        case (.legs, .compound): return "4 x 10"
        case (.legs, .unilateral): return "3 x 10-12"
        case (.legs, .accessory): return "3 x 12-15"
        default: return ""
        }
    }
}
