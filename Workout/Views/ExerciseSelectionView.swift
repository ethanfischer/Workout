import SwiftUI

struct ExerciseSelectionView: View {
    let category: WorkoutCategory
    @Binding var navigationPath: NavigationPath
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

    private var sortedSelectedExercises: [ExerciseDefinition] {
        let allExercises = ExerciseData.exercises(for: category)
        return allExercises.filter { selectedExercises.contains($0) }
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
                selectedExercises: sortedSelectedExercises,
                navigationPath: $navigationPath,
                restoredState: nil
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
                                ExerciseMediaView(exercise: exercise, size: 36)
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
        ExerciseSelectionView(category: .push, navigationPath: .constant(NavigationPath()))
    }
}
