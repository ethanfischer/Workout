import SwiftUI

struct HistoryDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 4) {
                    Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(workout.category.rawValue) Day")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(workout.durationSeconds / 60) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(exercise.name)
                                .font(.headline)
                            if let rating = exercise.difficultyRating {
                                Text(difficultyEmoji(for: rating))
                            }
                        }

                        ForEach(exercise.sets.sorted { $0.setNumber < $1.setNumber }) { set in
                            HStack {
                                Text("Set \(set.setNumber):")
                                    .foregroundColor(.secondary)
                                Text("\(formatWeight(set.weight, exerciseName: exercise.name)) x \(set.reps)")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isBandedExercise(_ name: String) -> Bool {
        name.lowercased().contains("banded") || name.lowercased().contains("resistance band")
    }

    private func formatWeight(_ weight: Double, exerciseName: String) -> String {
        if isBandedExercise(exerciseName) {
            return ResistanceLevel.from(rawValue: weight).displayName
        } else {
            return "\(Int(weight)) lbs"
        }
    }

    private func difficultyEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😫"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return ""
        }
    }
}

#Preview {
    let workout = Workout(category: .push)
    workout.durationSeconds = 1800
    let exercise = CompletedExercise(name: "Bench Press", order: 0)
    exercise.sets = [
        ExerciseSet(setNumber: 1, weight: 10, reps: 12),
        ExerciseSet(setNumber: 2, weight: 15, reps: 10)
    ]
    workout.exercises = [exercise]

    return NavigationStack {
        HistoryDetailView(workout: workout)
    }
}
