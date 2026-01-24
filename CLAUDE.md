# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -project Workout.xcodeproj -scheme Workout -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run on simulator
xcrun simctl boot "iPhone 16"
xcrun simctl install booted build/Debug-iphonesimulator/Workout.app
xcrun simctl launch booted com.workout.TiffinWorkout
```

The project has no test suite currently. Open `Workout.xcodeproj` in Xcode for the standard development workflow.

## Architecture

**iOS SwiftUI app** with SwiftData persistence, targeting iOS 17+. Uses Push/Pull/Legs workout categorization.

### Project Structure

```
Workout/                    # Main app target
├── WorkoutApp.swift        # Entry point with SwiftData modelContainer
├── ContentView.swift       # Home screen with NavigationStack routing
├── Models/WorkoutModels.swift   # SwiftData models
├── Data/ExerciseData.swift      # Static exercise catalog
├── Views/                  # All view components
└── LiveActivity/           # Dynamic Island attributes

WorkoutWidget/              # Widget extension for lock screen + Dynamic Island
```

### Data Model

Three SwiftData `@Model` classes with cascade delete relationships:
- `Workout` → has many `CompletedExercise` → has many `ExerciseSet`
- `WorkoutCategory` enum: `.push`, `.pull`, `.legs`

Static exercise definitions in `ExerciseData.swift` provide the exercise picker catalog. Exercise GIFs are loaded from the bundle using filename conventions (e.g., "bench_press.gif").

### Navigation Pattern

Uses `NavigationStack` with `NavigationPath` and `AppDestination` enum for type-safe routing:
```
Home → CategorySelection → ExerciseSelection → ActiveWorkout → WorkoutComplete → History
```

Views pass `$navigationPath` binding down to allow programmatic navigation (e.g., "Exit Workout" returns to history).

### Key Features

- **Pre-population**: ActiveWorkoutView queries history to pre-fill weight/reps from last workout
- **Rest timer**: 60-second countdown between sets with audio cue (beep.wav)
- **Pause functionality**: Workout can be paused, stopping elapsed timer
- **Live Activity**: Dynamic Island shows rest countdown and current exercise via ActivityKit

### Widget Extension

`WorkoutWidget/` contains:
- Lock screen widget (`WorkoutWidget.swift`)
- Live Activity for Dynamic Island (`WorkoutWidgetLiveActivity.swift`)
- Shared attributes in `Workout/LiveActivity/WorkoutActivityAttributes.swift`

## Exercise GIFs

GIFs are downloaded from **ExerciseDB via RapidAPI** using Python scripts in the repo root.

```bash
# Download all exercise GIFs
python3 download_all_gifs.py
```

The scripts:
- `download_all_gifs.py` - Downloads GIFs for all exercises to `Workout/Resources/ExerciseMedia/`
- `download_exercise_gifs.py` - Downloads GIFs for specific missing exercises to `exercise_gifs/`

GIF filenames must match the `mediaFilename` computed property in `ExerciseDefinition` (lowercase, underscores for spaces). The API searches by exercise name and downloads 360p resolution GIFs.
