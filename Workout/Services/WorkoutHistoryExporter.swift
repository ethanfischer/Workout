import Foundation
import SwiftData

struct WorkoutHistoryExport: Codable {
    var version: Int
    var exportedAt: Date
    var workouts: [WorkoutDTO]
}

struct WorkoutDTO: Codable {
    var id: UUID
    var date: Date
    var category: String
    var durationSeconds: Int
    var exercises: [CompletedExerciseDTO]
}

struct CompletedExerciseDTO: Codable {
    var id: UUID
    var name: String
    var order: Int
    var difficultyRating: Int?
    var sets: [ExerciseSetDTO]
}

struct ExerciseSetDTO: Codable {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
}

enum WorkoutImportError: LocalizedError {
    case unsupportedVersion(Int)
    case unknownCategory(String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v): return "Unsupported export version: \(v)"
        case .unknownCategory(let c): return "Unknown workout category: \(c)"
        case .decodeFailed(let msg): return "Could not read file: \(msg)"
        }
    }
}

struct WorkoutImportResult {
    var imported: Int
    var skippedDuplicates: Int
}

enum WorkoutHistoryExporter {
    static let currentVersion = 1

    static func encode(workouts: [Workout]) throws -> Data {
        let dtos = workouts.map { workout in
            WorkoutDTO(
                id: workout.id,
                date: workout.date,
                category: workout.category.rawValue,
                durationSeconds: workout.durationSeconds,
                exercises: workout.exercises
                    .sorted { $0.order < $1.order }
                    .map { exercise in
                        CompletedExerciseDTO(
                            id: exercise.id,
                            name: exercise.name,
                            order: exercise.order,
                            difficultyRating: exercise.difficultyRating,
                            sets: exercise.sets
                                .sorted { $0.setNumber < $1.setNumber }
                                .map { set in
                                    ExerciseSetDTO(
                                        id: set.id,
                                        setNumber: set.setNumber,
                                        weight: set.weight,
                                        reps: set.reps
                                    )
                                }
                        )
                    }
            )
        }

        let payload = WorkoutHistoryExport(
            version: currentVersion,
            exportedAt: Date(),
            workouts: dtos
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    @MainActor
    static func importData(_ data: Data, into context: ModelContext) throws -> WorkoutImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload: WorkoutHistoryExport
        do {
            payload = try decoder.decode(WorkoutHistoryExport.self, from: data)
        } catch {
            throw WorkoutImportError.decodeFailed(error.localizedDescription)
        }

        guard payload.version <= currentVersion else {
            throw WorkoutImportError.unsupportedVersion(payload.version)
        }

        let existing = try context.fetch(FetchDescriptor<Workout>())
        var existingIDs = Set(existing.map { $0.id })

        var imported = 0
        var skipped = 0

        for dto in payload.workouts {
            if existingIDs.contains(dto.id) {
                skipped += 1
                continue
            }

            guard let category = WorkoutCategory(rawValue: dto.category) else {
                throw WorkoutImportError.unknownCategory(dto.category)
            }

            let workout = Workout(category: category)
            workout.id = dto.id
            workout.date = dto.date
            workout.durationSeconds = dto.durationSeconds
            workout.exercises = dto.exercises.map { exDTO in
                let exercise = CompletedExercise(
                    name: exDTO.name,
                    order: exDTO.order,
                    difficultyRating: exDTO.difficultyRating
                )
                exercise.id = exDTO.id
                exercise.sets = exDTO.sets.map { setDTO in
                    let set = ExerciseSet(
                        setNumber: setDTO.setNumber,
                        weight: setDTO.weight,
                        reps: setDTO.reps
                    )
                    set.id = setDTO.id
                    return set
                }
                return exercise
            }

            context.insert(workout)
            existingIDs.insert(dto.id)
            imported += 1
        }

        try context.save()
        return WorkoutImportResult(imported: imported, skippedDuplicates: skipped)
    }
}
