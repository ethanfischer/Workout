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
                        Text(exercise.name)
                            .font(.headline)

                        ForEach(exercise.sets.sorted { $0.setNumber < $1.setNumber }) { set in
                            HStack {
                                Text("Set \(set.setNumber):")
                                    .foregroundColor(.secondary)
                                Text("\(Int(set.weight)) lbs x \(set.reps)")
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
