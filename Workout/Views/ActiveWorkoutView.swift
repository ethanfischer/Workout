import SwiftUI
import SwiftData
import AudioToolbox
import ActivityKit
import UserNotifications

struct ActiveWorkoutView: View {
    let category: WorkoutCategory
    let selectedExercises: [ExerciseDefinition]
    @Binding var navigationPath: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var isResting = false
    @State private var restTimeRemaining = 60
    @State private var completedSets: [[ExerciseSet]] = []
    @State private var showingComplete = false
    @State private var timer: Timer?
    @State private var liveActivity: Activity<WorkoutActivityAttributes>?
    @State private var restEndTime: Date?
    @State private var showingEndConfirmation = false
    @State private var isPaused = false
    @State private var elapsedTime: Int = 0
    @State private var workoutTimer: Timer?
    @State private var pausedRestTimeRemaining: Int?

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
                    duration: elapsedTime,
                    navigationPath: $navigationPath
                )
            } else if isPaused {
                pausedView
            } else if isResting {
                restView
            } else {
                exerciseView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !isPaused && !showingComplete {
                    Button {
                        togglePause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text(formatTime(elapsedTime))
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(isPaused ? .secondary : .primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(currentExerciseIndex + 1) of \(selectedExercises.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .alert("End Workout?", isPresented: $showingEndConfirmation) {
            Button("Save & Exit", role: nil) {
                savePartialWorkout()
                endLiveActivity()
                cancelRestNotification()
                timer?.invalidate()
                workoutTimer?.invalidate()
                navigateToHistory()
            }
            Button("Discard", role: .destructive) {
                endLiveActivity()
                cancelRestNotification()
                timer?.invalidate()
                workoutTimer?.invalidate()
                navigateToHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to save your progress so far?")
        }
        .onAppear {
            initializeExercise()
            requestNotificationPermission()
            startWorkoutTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkRestStatus()
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private var exerciseView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let exercise = currentExercise {
                ExerciseMediaView(exercise: exercise, size: 200)
            }

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
                    Text("\(formatWeight(lastData.weight)) x \(lastData.reps)")
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
                                Text("Set \(i + 1): \(formatWeight(set.weight)) x \(set.reps)")
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
                Text(currentExercise?.isBanded == true ? "RESISTANCE" : "WEIGHT")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 20) {
                    Button {
                        if currentExercise?.isBanded == true {
                            let currentLevel = ResistanceLevel.from(rawValue: weight)
                            if let currentIndex = ResistanceLevel.allCases.firstIndex(of: currentLevel), currentIndex > 0 {
                                weight = ResistanceLevel.allCases[currentIndex - 1].rawValue
                            }
                        } else {
                            if weight >= 5 { weight -= 5 }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.pink)
                    }

                    if currentExercise?.isBanded == true {
                        Text(ResistanceLevel.from(rawValue: weight).displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 120)
                    } else {
                        Text("\(Int(weight)) lbs")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 100)
                    }

                    Button {
                        if currentExercise?.isBanded == true {
                            let currentLevel = ResistanceLevel.from(rawValue: weight)
                            if let currentIndex = ResistanceLevel.allCases.firstIndex(of: currentLevel), currentIndex < ResistanceLevel.allCases.count - 1 {
                                weight = ResistanceLevel.allCases[currentIndex + 1].rawValue
                            }
                        } else {
                            weight += 5
                        }
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

    private var pausedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("PAUSED")
                .font(.title)
                .fontWeight(.bold)

            Text(formatTime(elapsedTime))
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 16) {
                Button {
                    togglePause()
                } label: {
                    Text("RESUME")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }

                Button {
                    showingEndConfirmation = true
                } label: {
                    Text("End Workout")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
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
            weight = currentExercise?.isBanded == true ? ResistanceLevel.medium.rawValue : 0
            reps = currentExercise?.defaultRepsInt ?? 10
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
            // Last set of this exercise
            if currentExerciseIndex + 1 >= selectedExercises.count {
                // Last exercise - workout complete
                saveWorkout()
                showingComplete = true
            } else {
                // More exercises - rest then move to next exercise
                startRest()
            }
        } else {
            // More sets - rest then move to next set
            startRest()
        }
    }

    private func startRest() {
        isResting = true
        restTimeRemaining = 60
        restEndTime = Date().addingTimeInterval(60)
        startLiveActivity()
        scheduleRestNotification()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
                // Countdown beeps for last 3 seconds
                if restTimeRemaining <= 3 && restTimeRemaining > 0 {
                    playCountdownBeep()
                }
            } else {
                playTimerEndSound()
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
        restEndTime = nil
        endLiveActivity()
        cancelRestNotification()

        if currentSetIndex + 1 >= totalSets {
            // Move to next exercise
            currentExerciseIndex += 1
            currentSetIndex = 0
            initializeExercise()
        } else {
            // Move to next set
            currentSetIndex += 1
            if let lastData = getLastSetData() {
                weight = lastData.weight
                reps = lastData.reps
            }
        }
    }

    // MARK: - Workout Timer

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused {
                elapsedTime += 1
            }
        }
    }

    private func togglePause() {
        isPaused.toggle()

        if isPaused {
            // Pausing - save rest timer state if resting
            if isResting {
                pausedRestTimeRemaining = restTimeRemaining
                timer?.invalidate()
                endLiveActivity()
                cancelRestNotification()
            }
        } else {
            // Resuming - restart rest timer if we were resting
            if isResting, let remaining = pausedRestTimeRemaining {
                restTimeRemaining = remaining
                restEndTime = Date().addingTimeInterval(TimeInterval(remaining))
                startLiveActivity()
                scheduleRestNotification()
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if restTimeRemaining > 0 {
                        restTimeRemaining -= 1
                        if restTimeRemaining <= 3 && restTimeRemaining > 0 {
                            playCountdownBeep()
                        }
                    } else {
                        playTimerEndSound()
                        endRest()
                    }
                }
                pausedRestTimeRemaining = nil
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
        workoutTimer?.invalidate()
        let workout = Workout(category: category)
        workout.durationSeconds = elapsedTime

        for (index, exercise) in selectedExercises.enumerated() {
            let completed = CompletedExercise(name: exercise.name, order: index)
            completed.sets = completedSets[index]
            workout.exercises.append(completed)
        }

        modelContext.insert(workout)
    }

    private func savePartialWorkout() {
        workoutTimer?.invalidate()
        // Only save if there's at least one completed set
        let hasCompletedSets = completedSets.contains { !$0.isEmpty }
        guard hasCompletedSets else { return }

        let workout = Workout(category: category)
        workout.durationSeconds = elapsedTime

        // Only save exercises that have at least one completed set
        for (index, exercise) in selectedExercises.enumerated() {
            guard index < completedSets.count && !completedSets[index].isEmpty else { continue }
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

    private func formatWeight(_ weight: Double) -> String {
        if currentExercise?.isBanded == true {
            return ResistanceLevel.from(rawValue: weight).displayName
        } else {
            return "\(Int(weight)) lbs"
        }
    }

    private func navigateToHistory() {
        // Clear the navigation stack and navigate to history
        navigationPath.removeLast(navigationPath.count)
        navigationPath.append(AppDestination.history)
    }

    private func playCountdownBeep() {
        // Single beep for countdown
        AudioServicesPlaySystemSound(1057)
    }

    private func playTimerEndSound() {
        // Play triple ding sound
        let dingSound: SystemSoundID = 1057
        AudioServicesPlaySystemSound(dingSound)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(dingSound)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AudioServicesPlaySystemSound(dingSound)
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else { return }

        let attributes = WorkoutActivityAttributes(workoutCategory: category.rawValue)
        let endTime = Date().addingTimeInterval(TimeInterval(restTimeRemaining))
        let state = WorkoutActivityAttributes.ContentState(
            endTime: endTime,
            currentExercise: currentExercise?.name ?? "",
            nextExercise: getNextExerciseName(),
            currentSet: currentSetIndex + 1,
            totalSets: totalSets
        )

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }

    private func updateLiveActivity() {
        // No longer needed - the system handles the countdown automatically
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }

        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }

    // MARK: - Notifications

    private func scheduleRestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelRestNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    private func checkRestStatus() {
        guard isResting, let endTime = restEndTime else { return }

        if Date() >= endTime {
            // Rest period ended while app was backgrounded
            playTimerEndSound()
            endRest()
        } else {
            // Update remaining time
            restTimeRemaining = max(0, Int(endTime.timeIntervalSinceNow))
        }
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(
            category: .push,
            selectedExercises: [
                ExerciseDefinition(name: "Bench Press", type: .compound, category: .push, defaultSets: 3, defaultReps: "10")
            ],
            navigationPath: .constant(NavigationPath())
        )
    }
    .modelContainer(for: [Workout.self, CompletedExercise.self, ExerciseSet.self])
}
