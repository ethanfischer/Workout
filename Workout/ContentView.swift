import SwiftUI

enum AppDestination: Hashable {
    case categorySelection
    case history
    case resumeWorkout(InProgressWorkoutState)
}

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var hasCheckedForSavedWorkout = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
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

                Button {
                    navigationPath.append(AppDestination.categorySelection)
                } label: {
                    Text("START WORKOUT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Button {
                    navigationPath.append(AppDestination.history)
                } label: {
                    Text("History")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .categorySelection:
                    CategorySelectionView(navigationPath: $navigationPath)
                case .history:
                    HistoryView()
                case .resumeWorkout(let state):
                    if let category = WorkoutCategory(rawValue: state.category) {
                        let exercises = reconstructExercises(from: state.exerciseNames, category: category)
                        ActiveWorkoutView(
                            category: category,
                            selectedExercises: exercises,
                            navigationPath: $navigationPath,
                            restoredState: state
                        )
                    }
                }
            }
            .onAppear {
                checkForSavedWorkout()
            }
        }
    }

    private func checkForSavedWorkout() {
        guard !hasCheckedForSavedWorkout else { return }
        hasCheckedForSavedWorkout = true

        if let savedState = WorkoutStateManager.shared.load() {
            navigationPath.append(AppDestination.resumeWorkout(savedState))
        }
    }

    private func reconstructExercises(from names: [String], category: WorkoutCategory) -> [ExerciseDefinition] {
        let allExercises = ExerciseData.exercises(for: category)
        return names.compactMap { name in
            allExercises.first { $0.name == name }
        }
    }
}

#Preview {
    ContentView()
}
