import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var body: some View {
        VStack {
            if workouts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("No workouts yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Complete a workout to see it here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: HistoryDetailView(workout: workout)) {
                                HistoryCard(workout: workout)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("History")
    }
}

struct HistoryCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)

            HStack {
                Text("\(workout.category.rawValue) Day")
                Text("•")
                Text("\(workout.exercises.count) exercises")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("\(workout.durationSeconds / 60) min")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: [Workout.self, CompletedExercise.self, ExerciseSet.self])
}
