#!/bin/bash
set -e

cd /Users/work/Repos/TiffinWorkout/Workout

echo "=== Building Workout App ==="

# Task 2: Exercise Data
echo "Creating Exercise Data..."
mkdir -p Workout/Data
cat > Workout/Data/ExerciseData.swift << 'EOF'
import Foundation

enum ExerciseType: String, CaseIterable {
    case compound = "Compound"
    case unilateral = "Unilateral"
    case accessory = "Accessory/Isolation"
}

struct ExerciseDefinition: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: ExerciseType
    let category: WorkoutCategory
    let defaultSets: Int
    let defaultReps: String
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
EOF
git add Workout/Data/
git commit -m "feat: add hardcoded exercise data for Push/Pull/Legs"
echo "✓ Task 2 complete"

# Task 3: App Setup with SwiftData
echo "Configuring SwiftData..."
cat > Workout/WorkoutApp.swift << 'EOF'
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
EOF
git add Workout/WorkoutApp.swift
git commit -m "feat: configure SwiftData model container"
echo "✓ Task 3 complete"

# Task 4: Home Screen
echo "Creating Home Screen..."
cat > Workout/ContentView.swift << 'EOF'
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Text("TIFFIN")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("WORKOUT")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: CategorySelectionView()) {
                    Text("START WORKOUT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                NavigationLink(destination: HistoryView()) {
                    Text("History")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
EOF
git add Workout/ContentView.swift
git commit -m "feat: implement home screen with navigation"
echo "✓ Task 4 complete"

# Task 5: Category Selection Screen
echo "Creating Category Selection..."
mkdir -p Workout/Views
cat > Workout/Views/CategorySelectionView.swift << 'EOF'
import SwiftUI

struct CategorySelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("SELECT CATEGORY")
                .font(.headline)
                .padding(.top, 40)

            Spacer()

            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                NavigationLink(destination: ExerciseSelectionView(category: category)) {
                    Text(category.rawValue.uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
}
EOF
git add Workout/Views/
git commit -m "feat: add category selection screen"
echo "✓ Task 5 complete"

# Task 6: Exercise Selection Screen
echo "Creating Exercise Selection..."
cat > Workout/Views/ExerciseSelectionView.swift << 'EOF'
import SwiftUI

struct ExerciseSelectionView: View {
    let category: WorkoutCategory
    @State private var selectedExercises: Set<ExerciseDefinition> = []

    private var exercisesByType: [(type: ExerciseType, exercises: [ExerciseDefinition])] {
        let exercises = ExerciseData.exercises(for: category)
        let types = category == .legs
            ? [ExerciseType.compound, .unilateral, .accessory]
            : [ExerciseType.compound, .accessory]

        return types.compactMap { type in
            let filtered = exercises.filter { $0.type == type }
            return filtered.isEmpty ? nil : (type, filtered)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("WORKOUT BUILDER")
                    .font(.headline)
                Text(categorySubtitle)
                    .font(.subheadline)
                    .foregroundColor(.pink)
            }
            .padding(.vertical, 16)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(exercisesByType, id: \.type) { group in
                        ExerciseTypeSection(
                            type: group.type,
                            category: category,
                            exercises: group.exercises,
                            selectedExercises: $selectedExercises
                        )
                    }
                }
                .padding(.horizontal)
            }

            NavigationLink(destination: ActiveWorkoutView(
                category: category,
                selectedExercises: Array(selectedExercises)
            )) {
                Text("START WORKOUT (\(selectedExercises.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedExercises.isEmpty ? Color.gray : Color.pink)
                    .cornerRadius(12)
            }
            .disabled(selectedExercises.isEmpty)
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var categorySubtitle: String {
        switch category {
        case .push: return "Upper body day - Push (shoulders + chest + triceps)"
        case .pull: return "Upper body day - Pull (back + biceps)"
        case .legs: return "Lower body day"
        }
    }
}

struct ExerciseTypeSection: View {
    let type: ExerciseType
    let category: WorkoutCategory
    let exercises: [ExerciseDefinition]
    @Binding var selectedExercises: Set<ExerciseDefinition>

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TYPE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 100, alignment: .leading)
                Text("EXERCISE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("REPS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.pink)
            .foregroundColor(.white)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(ExerciseData.pickGuidance(for: type, category: category))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(exercises) { exercise in
                        Button {
                            toggleSelection(exercise)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: selectedExercises.contains(exercise) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedExercises.contains(exercise) ? .pink : .gray)
                                Text(exercise.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(ExerciseData.repsDisplay(for: type, category: category))
                    .font(.caption)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private func toggleSelection(_ exercise: ExerciseDefinition) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseSelectionView(category: .push)
    }
}
EOF
git add Workout/Views/ExerciseSelectionView.swift
git commit -m "feat: add exercise selection with table layout"
echo "✓ Task 6 complete"

# Task 7: Active Workout View
echo "Creating Active Workout View..."
cat > Workout/Views/ActiveWorkoutView.swift << 'EOF'
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
EOF
git add Workout/Views/ActiveWorkoutView.swift
git commit -m "feat: add active workout view with set tracking and rest timer"
echo "✓ Task 7 complete"

# Task 8: Workout Complete View
echo "Creating Workout Complete View..."
cat > Workout/Views/WorkoutCompleteView.swift << 'EOF'
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
EOF
git add Workout/Views/WorkoutCompleteView.swift
git commit -m "feat: add workout complete summary view"
echo "✓ Task 8 complete"

# Task 9: History View
echo "Creating History View..."
cat > Workout/Views/HistoryView.swift << 'EOF'
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
EOF
git add Workout/Views/HistoryView.swift
git commit -m "feat: add history list view"
echo "✓ Task 9 complete"

# Task 10: History Detail View
echo "Creating History Detail View..."
cat > Workout/Views/HistoryDetailView.swift << 'EOF'
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
EOF
git add Workout/Views/HistoryDetailView.swift
git commit -m "feat: add history detail view"
echo "✓ Task 10 complete"

# Final commit for build script
git add -A
git commit -m "feat: complete workout app implementation" --allow-empty

echo ""
echo "=== All tasks complete! ==="
echo ""
echo "Building project..."
xcodebuild -project Workout.xcodeproj -scheme Workout -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20

echo ""
echo "Done! Open Workout.xcodeproj in Xcode to run the app."
