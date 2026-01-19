# Workout App Design

## Overview

A basic iOS workout app built with SwiftUI. Users select a workout category (Push/Pull/Legs), pick exercises from a table, then step through sets one at a time with weight/rep tracking. History is saved and used to pre-populate targets for future workouts.

## Screens

### 1. Home
- App title "TIFFIN WORKOUT"
- Large "START WORKOUT" button
- Smaller "History" link below

### 2. Category Selection
- Three large buttons: Push, Pull, Legs
- Back navigation

### 3. Exercise Selection (Table View)
Grouped by exercise type with pick guidance:

**Push (shoulders + chest + triceps):**
| Type | Pick | Exercises | Reps |
|------|------|-----------|------|
| Compound | 2 | Push ups, Overhead press, Bench press | 3-4 x 10 |
| Accessory/Isolation | 3 | Lateral raises, Front raises, Tricep extension, DB chest flys, Tricep rope pushdown, Rear delt fly | 3 x 10-12 |

**Pull (back + biceps):**
| Type | Pick | Exercises | Reps |
|------|------|-----------|------|
| Compound | 2 | Lat pulldown, Seated row, Pull ups, Bent over row, Deadlift | 3-4 x 10 |
| Accessory/Isolation | 3 | DB pullovers, Renegade rows, Stiff arm pulldown, Rope face pull, DB curls | 3 x 10-12 |

**Legs (lower body):**
| Type | Pick | Exercises | Reps |
|------|------|-----------|------|
| Compound | 1-2 | Squat variation, Deadlift, Hip thrust | 4 x 10 |
| Unilateral | 1-2 | Lunges, Split squats, Split stance RDL, Step ups, Split stance hip thrust | 3 x 10-12 |
| Accessory/Isolation | 2 | Leg extension, Leg curl, Cable kickbacks, Abductions, Calf raises | 3 x 12-15 |

- Checkbox selection per exercise
- "START (n)" button shows count of selected

### 4. Active Workout (Set by Set)
- Exercise name + "Set X of Y"
- "LAST TIME" box showing previous weight x reps (from history)
- Weight input with +/- buttons (pre-populated from history)
- Reps input with +/- buttons (pre-populated from history)
- "COMPLETE SET" button
- Shows completed sets for current exercise
- Progress indicator "1 of 5" (exercise count)
- "End" button to abort

**No history case:** Empty fields, user enters from scratch

### 5. Rest Timer
- Large countdown display (1 minute)
- "Next: [exercise name]" preview
- "SKIP REST" button
- Triggers after each set

### 6. Workout Complete Summary
- Category name
- Exercise count
- Total duration
- List of all exercises with their sets
- "DONE" button returns to home

### 7. History
**List view:**
- Cards showing: Date, Category, Exercise count, Duration
- Sorted by most recent

**Detail view (tap a workout):**
- Date, Category, Duration header
- Each exercise with all sets (weight x reps)

## Data Model

```swift
struct Workout {
    let id: UUID
    let date: Date
    let category: WorkoutCategory  // push, pull, legs
    let duration: TimeInterval
    let exercises: [CompletedExercise]
}

struct CompletedExercise {
    let name: String
    let sets: [ExerciseSet]
}

struct ExerciseSet {
    let weight: Double
    let reps: Int
}

enum WorkoutCategory {
    case push, pull, legs
}
```

## App Flow

```
HOME → CATEGORY → EXERCISE SELECT → WORKOUT (set by set)
  │                                      ↓
  │                                 REST TIMER (1 min)
  │                                      ↓
  │                                 COMPLETE SUMMARY
  │                                      ↓
  └──── HISTORY ◄────────────────── (saves workout)
           ↓
       DETAIL VIEW
```

## Implementation Notes

- Use SwiftData for persistence
- Store workout history locally on device
- Query history to get most recent data per exercise for pre-population
- Timer uses SwiftUI's `Timer.publish`
- Navigation via NavigationStack
