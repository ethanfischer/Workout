import SwiftUI

struct WorkoutCompleteView: View {
    let category: WorkoutCategory
    let completedSets: [[ExerciseSet]]
    let exercises: [ExerciseDefinition]
    let duration: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("WORKOUT COMPLETE")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 4) {
                Text("\(category.rawValue) Day")
                    .font(.headline)
                Text("\(exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)

                            if index < completedSets.count {
                                ForEach(completedSets[index].sorted { $0.setNumber < $1.setNumber }) { set in
                                    Text("Set \(set.setNumber): \(Int(set.weight)) lbs x \(set.reps)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()

            NavigationLink(destination: ContentView()) {
                Text("DONE")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        return "\(mins) min"
    }
}

#Preview {
    WorkoutCompleteView(
        category: .push,
        completedSets: [
            [ExerciseSet(setNumber: 1, weight: 10, reps: 12)]
        ],
        exercises: [
            ExerciseDefinition(name: "Bench Press", type: .compound, category: .push, defaultSets: 3, defaultReps: "10")
        ],
        duration: 1800
    )
}
