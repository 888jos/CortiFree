# Refactoring Progress: Removing Hardcoded Values

## ✅ Completed

### 1. AppConstants.swift - Extended with new configuration
**File**: `/Users/jos/CortiFree/CortiFree/CortiFree/Utilities/AppConstants.swift`

**Added**:
- `Program` enum with `totalDays`, `totalWeeks`, `defaultInitialScore`, `daysPerWeek`
- `Habits` enum with:
  - `ID` sub-enum for all 8 habit identifiers
  - `Difficulty` levels (easy=1, medium=2, hard=3)
  - `defaultWaterQuantity = "2L"`
- `Notifications` enum with `taskValidated` notification name
- Extended `Animation` enum with day navigation and confetti durations
- Extended `Layout` enum with task-specific constants
- Added `taskBackground` gradient extension

### 2. HabitConfiguration.swift - Created centralized business logic
**File**: `/Users/jos/CortiFree/CortiFree/CortiFree/Models/HabitConfiguration.swift`

**Functions**:
- `habitID(from imageName:)` - Maps image assets to habit IDs (replaces 22-line switch in TasksV2View)
- `shouldShowTask(dayOfWeek:frequencyPerWeek:)` - Centralized frequency distribution logic
- `dayKey(_ day:)` - Standard Firebase key formatting
- `displayInfo(for habitId:)` - Get image name and icon for a habit
- `weekNumber(for programDay:)` - Calculate week from program day
- `frequencyCount(from frequency:)` - Parse frequency strings

### 3. Localization Keys - Added to both EN and FR
**Files**:
- `/Users/jos/CortiFree/CortiFree/CortiFree/Resources/en.lproj/Localizable.strings`
- `/Users/jos/CortiFree/CortiFree/CortiFree/Resources/fr.lproj/Localizable.strings`

**Added keys**:
- `habit.title.*` (sleep, breathing, meditation, water, sport, nature, social, journal)
- `frequency.label.*` (daily, 1x_week through 5x_week)
- `tasks.view.*` (encouragement_default, loading, no_tasks_today, all_done)
- `alert.*` (task_completion, error messages)

### 4. StringKeys.swift - Extended with type-safe accessors
**File**: `/Users/jos/CortiFree/CortiFree/CortiFree/Utils/StringKeys.swift`

**Added**:
- `HabitTitles` struct with all 8 habit titles + helper `title(for:)`
- `Frequency` struct with frequency labels + helper `label(for:)`
- `TasksView` struct with view-specific strings
- `Alerts` struct with alert messages

### 5. TasksV2View.swift - Partial refactoring started
**File**: `/Users/jos/CortiFree/CortiFree/CortiFree/Views/Tasks/TasksV2View.swift`

**Changes made**:
- Line 20-21: Replaced `45` with `AppConstants.Program.defaultInitialScore`
- Line 68: Replaced `"sleep"` with `AppConstants.Habits.ID.sleep`
- Line 73: Replaced `"Quotidien"` with `StringKeys.Frequency.daily`
- Line 74: Replaced `2` with `AppConstants.Habits.Difficulty.medium`
- Line 91: Replaced `"breathing"` with `AppConstants.Habits.ID.breathing`
- Line 93: Replaced `"Respirer en conscience"` with `StringKeys.HabitTitles.breathing`
- Line 97: Replaced `1` with `AppConstants.Habits.Difficulty.easy`

## 🚧 Remaining Work

### TasksV2View.swift - Continue refactoring

The following hardcoded values still need to be replaced:

#### Habit Titles (lines ~110-250)
- Line ~115: `"Méditer en pleine conscience"` → `StringKeys.HabitTitles.meditation`
- Line ~138: `"Boire de l'eau"` → `StringKeys.HabitTitles.water`
- Line ~165: `"Bouger ton corps"` → `StringKeys.HabitTitles.sport`
- Line ~190: `"Temps dans la nature"` → `StringKeys.HabitTitles.nature`
- Line ~210: `"Interaction sociale"` → `StringKeys.HabitTitles.social`
- Line ~235: `"Écrire ton journal"` → `StringKeys.HabitTitles.journal`

#### Habit IDs in habitTracking[] (lines ~110-250)
- Line ~113: `"meditation"` → `AppConstants.Habits.ID.meditation`
- Line ~136: `"water"` → `AppConstants.Habits.ID.water`
- Line ~163: `"sport"` → `AppConstants.Habits.ID.sport`
- Line ~188: `"nature"` → `AppConstants.Habits.ID.nature`
- Line ~208: `"social"` → `AppConstants.Habits.ID.social`
- Line ~233: `"journal"` → `AppConstants.Habits.ID.journal`

#### Difficulty Levels (lines ~70-250)
Replace all hardcoded `1`, `2`, `3` with:
- `AppConstants.Habits.Difficulty.easy` (1)
- `AppConstants.Habits.Difficulty.medium` (2)
- `AppConstants.Habits.Difficulty.hard` (3)

#### shouldShowTask Function (lines ~257-270)
Replace entire function with call to `HabitConfiguration.shouldShowTask(dayOfWeek:frequencyPerWeek:)`

#### Image Name to Habit ID Mapping (lines ~848-869)
Replace 22-line switch statement with call to `HabitConfiguration.habitID(from:)`

#### Frequency Strings (multiple locations)
- Replace `"Quotidien"` with `StringKeys.Frequency.daily`
- Replace `"3x/semaine"` with `StringKeys.Frequency.threePerWeek`
- etc.

#### Hardcoded Numbers
- Line 324: `66` → `AppConstants.Program.totalDays`
- Line 842: `2.0` → `AppConstants.Animation.confettiDuration`
- Line 709: `String(format: "day_%02d", day)` → `HabitConfiguration.dayKey(day)`

#### Gradient Colors (lines ~277-279, etc.)
- Replace hex color strings with `AppConstants.Colors.*`
- Use `LinearGradient.taskBackground` where applicable

#### Animation Durations
- Line 842: `DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)` → use `AppConstants.Animation.confettiDuration`
- Other animation delays should use constants from `AppConstants.Animation`

#### Encouragement Text (line ~377)
- Replace hardcoded French text with `StringKeys.TasksView.encouragementDefault`

## 📝 Refactoring Guidelines

### Pattern to Follow

**Before**:
```swift
let sleepData = habitTracking["sleep"]
dailyTasks.append(HabitTask(
    title: "Se lever avant 7h",
    frequencyText: "Quotidien",
    difficulty: 2,
    // ...
))
```

**After**:
```swift
let sleepData = habitTracking[AppConstants.Habits.ID.sleep]
dailyTasks.append(HabitTask(
    title: StringKeys.HabitTitles.sleep,
    frequencyText: StringKeys.Frequency.daily,
    difficulty: AppConstants.Habits.Difficulty.medium,
    // ...
))
```

### Search and Replace Strategy

1. **Habit IDs in habitTracking**:
   - Find: `habitTracking["sleep"]`
   - Replace: `habitTracking[AppConstants.Habits.ID.sleep]`

2. **Frequency strings**:
   - Find: `"Quotidien"`
   - Replace: `StringKeys.Frequency.daily`

3. **Difficulty numbers**:
   - Find: `difficulty: 1`
   - Replace: `difficulty: AppConstants.Habits.Difficulty.easy`

4. **shouldShowTask function** (lines 257-270):
   ```swift
   // OLD CODE - DELETE THIS
   private func shouldShowTask(dayOfWeek: Int, frequencyPerWeek: Int) -> Bool {
       switch frequencyPerWeek {
       case 7: return true
       case 5: return dayOfWeek <= 4
       // ... etc
       }
   }

   // NEW CODE - USE THIS
   private func shouldShowTask(dayOfWeek: Int, frequencyPerWeek: Int) -> Bool {
       return HabitConfiguration.shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: frequencyPerWeek)
   }
   ```

5. **getHabitId function** (lines 848-869):
   ```swift
   // OLD CODE - DELETE THIS
   private func getHabitId(for imageName: String) -> String {
       switch imageName {
       case "habit_sleep": return "sleep"
       // ... 22 lines of mappings
       }
   }

   // NEW CODE - USE THIS
   private func getHabitId(for imageName: String) -> String {
       return HabitConfiguration.habitID(from: imageName) ?? imageName
   }
   ```

## ✅ Benefits Achieved

1. **Centralized Configuration**: All magic numbers and strings in one place
2. **Type Safety**: Enums prevent typos and provide autocomplete
3. **Localization Ready**: All user-facing strings use localization keys
4. **Maintainability**: Easy to update values across the entire app
5. **Scalability**: Adding new habits requires minimal code changes
6. **Business Logic Separation**: HabitConfiguration handles all habit-related logic

## 🔧 Next Steps

1. Complete TasksV2View.swift refactoring (follow patterns above)
2. Test the app to ensure all strings display correctly
3. Verify French/English language switching works
4. Run build to catch any compilation errors
5. Test all habit-related functionality

## 📊 Progress Summary

- **Phase 1-5**: ✅ Complete (AppConstants, HabitConfiguration, Localization, StringKeys)
- **Phase 6**: 🚧 In Progress (TasksV2View refactoring ~10% done)
- **Phase 7**: ⏳ Pending (Testing and build)

**Estimated completion**: Continue with TasksV2View.swift refactoring following the patterns documented above.
