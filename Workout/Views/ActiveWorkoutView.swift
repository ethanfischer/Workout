import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let category: WorkoutCategory
    let selectedExercises: [ExerciseDefinition]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var isResting = false
    @State private var restTimeRemaining = 60
    @State private var completedSets: [[ExerciseSet]] = []
    @State private var workoutStartTime = Date()
    @State private var showingComplete = false
    @State private var timer: Timer?

    @Query private var workouts: [Workout]

    private var currentExercise: ExerciseDefinition? {
        guard currentExerciseIndex < selectedExercises.count else { return nil }
        return selectedExercises[currentExerciseIndex]
    }

    private var totalSets: Int {
        currentExercise?.defaultSets ?? 3
    }

    var body: some View {
        VStack {
            if showingComplete {
                WorkoutCompleteView(
                    category: category,
                    completedSets: completedSets,
                    exercises: selectedExercises,
                    duration: Int(Date().timeIntervalSince(workoutStartTime))
                )
            } else if isResting {
                restView
            } else {
                exerciseView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(currentExerciseIndex + 1) of \(selectedExercises.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            initializeExercise()
        }
    }

    private var exerciseView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text(currentExercise?.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Set \(currentSetIndex + 1) of \(totalSets)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let lastData = getLastSetData() {
                VStack(spacing: 4) {
                    Text("LAST TIME")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(lastData.weight)) lbs x \(lastData.reps)")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 40)
            }

            if currentSetIndex > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<currentSetIndex, id: \.self) { i in
                        if i < completedSets[currentExerciseIndex].count {
                            let set = completedSets[currentExerciseIndex][i]
                            HStack {
                                Text("Set \(i + 1): \(Int(set.weight)) lbs x \(set.reps)")
                                    .font(.caption)
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("WEIGHT")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 20) {
                    Button {
                        if weight >= 5 { weight -= 5 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.pink)
                    }

                    Text("\(Int(weight)) lbs")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 100)

                    Button {
                        weight += 5
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.pink)
                    }
                }
            }

            VStack(spacing: 8) {
                Text("REPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 20) {
                    Button {
                        if reps > 0 { reps -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.pink)
                    }

                    Text("\(reps)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 100)

                    Button {
                        reps += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.pink)
                    }
                }
            }

            Spacer()

            Button {
                completeSet()
            } label: {
                Text("COMPLETE SET")
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
    }

    private var restView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("REST")
                .font(.title)
                .fontWeight(.bold)

            Text(formatTime(restTimeRemaining))
                .font(.system(size: 72, weight: .bold, design: .monospaced))

            if let nextExercise = getNextExerciseName() {
                Text("Next: \(nextExercise)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                skipRest()
            } label: {
                Text("SKIP REST")
                    .font(.headline)
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func initializeExercise() {
        if completedSets.isEmpty {
            completedSets = Array(repeating: [], count: selectedExercises.count)
        }

        if let lastData = getLastSetData() {
            weight = lastData.weight
            reps = lastData.reps
        } else {
            weight = 0
            reps = 0
        }
    }

    private func getLastSetData() -> (weight: Double, reps: Int)? {
        guard let exerciseName = currentExercise?.name else { return nil }

        let sorted = workouts.sorted { $0.date > $1.date }
        for workout in sorted {
            if let exercise = workout.exercises.first(where: { $0.name == exerciseName }) {
                let sortedSets = exercise.sets.sorted { $0.setNumber < $1.setNumber }
                if currentSetIndex < sortedSets.count {
                    let set = sortedSets[currentSetIndex]
                    return (set.weight, set.reps)
                } else if let lastSet = sortedSets.last {
                    return (lastSet.weight, lastSet.reps)
                }
            }
        }
        return nil
    }

    private func completeSet() {
        let set = ExerciseSet(setNumber: currentSetIndex + 1, weight: weight, reps: reps)
        completedSets[currentExerciseIndex].append(set)

        if currentSetIndex + 1 >= totalSets {
            if currentExerciseIndex + 1 >= selectedExercises.count {
                saveWorkout()
                showingComplete = true
            } else {
                startRest()
            }
        } else {
            currentSetIndex += 1
            startRest()
        }
    }

    private func startRest() {
        isResting = true
        restTimeRemaining = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                endRest()
            }
        }
    }

    private func skipRest() {
        timer?.invalidate()
        endRest()
    }

    private func endRest() {
        timer?.invalidate()
        isResting = false

        if currentSetIndex + 1 >= totalSets {
            currentExerciseIndex += 1
            currentSetIndex = 0
            initializeExercise()
        } else {
            if let lastData = getLastSetData() {
                weight = lastData.weight
                reps = lastData.reps
            }
        }
    }

    private func getNextExerciseName() -> String? {
        if currentSetIndex + 1 >= totalSets {
            if currentExerciseIndex + 1 < selectedExercises.count {
                return selectedExercises[currentExerciseIndex + 1].name
            }
            return nil
        } else {
            return "\(currentExercise?.name ?? "") - Set \(currentSetIndex + 2)"
        }
    }

    private func saveWorkout() {
        let workout = Workout(category: category)
        workout.durationSeconds = Int(Date().timeIntervalSince(workoutStartTime))

        for (index, exercise) in selectedExercises.enumerated() {
            let completed = CompletedExercise(name: exercise.name, order: index)
            completed.sets = completedSets[index]
            workout.exercises.append(completed)
        }

        modelContext.insert(workout)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(
            category: .push,
            selectedExercises: [
                ExerciseDefinition(name: "Bench Press", type: .compound, category: .push, defaultSets: 3, defaultReps: "10")
            ]
        )
    }
    .modelContainer(for: [Workout.self, CompletedExercise.self, ExerciseSet.self])
}
