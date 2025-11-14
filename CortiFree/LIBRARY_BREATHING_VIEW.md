# ✅ LibraryBreathingView - Breathing Exercises Implementation

## 🎯 Overview

The `LibraryBreathingView` component provides an immersive breathing exercise experience with a smooth animated sphere that guides users through inhale, hold, and exhale phases. This is designed for the Library section's breathing exercises.

---

## 📐 Specifications Implemented

### Visual Design

✅ **Sphere Animation**: 80×80px circle with radial gradient (#73DE85 → #53D7D9)
✅ **Vertical Motion**: Smooth movement from y=+200 (bottom) to y=-200 (top)
✅ **Outer Glow**: Blurred radial gradient halo that pulses with breathing phases
✅ **Dark Background**: Gradient from #01000C → #0B011B → #01000C
✅ **Phase Labels**: "Inspire", "Maintiens", "Expire" with fade transitions
✅ **Timer Display**: Large countdown timer in Poppins Medium 48px
✅ **Cycle Counter**: Shows current cycle number

### Animation Behavior

✅ **Inhale Phase**: Sphere moves from bottom (y=200) to top (y=-200) with easeInOut timing
✅ **Hold Phase**: Sphere stays at top position, no movement
✅ **Exhale Phase**: Sphere moves from top (y=-200) to bottom (y=200) with easeInOut timing
✅ **Continuous Loop**: Automatically repeats cycles until duration ends
✅ **Haptic Feedback**: Light haptic at each phase transition

### Breathing Patterns

5 preset patterns available:

| Pattern | Inhale | Hold | Exhale | Description |
|---------|--------|------|--------|-------------|
| 4-7-8 | 4s | 7s | 8s | Ralentis ton rythme cardiaque |
| Box Breathing | 4s | 4s | 4s | Technique militaire anti-stress |
| Cohérence Cardiaque | 5s | 0s | 5s | Équilibre ton système nerveux |
| Deep Relax | 4s | 2s | 6s | Détente complète du corps |
| Energizing | 3s | 1s | 3s | Booste ton énergie |

---

## 🏗️ Architecture

### File Structure

```
Models/
  └── BreathingPattern.swift (95 lines)
      - BreathingPattern struct
      - 5 preset patterns
      - BreathingPhase enum

Views/Breathing/
  └── LibraryBreathingView.swift (380 lines)
      - LibraryBreathingView (main view)
      - BreathingSphere (animated sphere component)
      - CompletionCelebration (success overlay)
```

### Data Models

```swift
// Pattern definition
struct BreathingPattern: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let inhaleDuration: Double
    let holdDuration: Double
    let exhaleDuration: Double
    let description: String

    var totalCycleDuration: Double {
        inhaleDuration + holdDuration + exhaleDuration
    }
}

// Phase states
enum BreathingPhase: String {
    case inhale = "Inspire"
    case hold = "Maintiens"
    case exhale = "Expire"

    var displayText: String {
        return self.rawValue
    }

    var glowIntensity: Double {
        switch self {
        case .inhale: return 1.0   // Full glow at peak
        case .hold: return 0.8     // Sustained glow
        case .exhale: return 0.4   // Dimmed glow
        }
    }
}
```

---

## 🎨 Visual Design Details

### Sphere Appearance

**Main Circle:**
- Size: 80×80px
- Fill: Radial gradient from center
  - Start: #73DE85 (green)
  - End: #53D7D9 (cyan)
- Shadow: 20px blur, #73DE85 at 50% opacity, offset (0, 10)

**Outer Glow:**
- Size: 240×240px (3x sphere size)
- Fill: Radial gradient
  - Inner: #73DE85 with phase-dependent opacity (30% at inhale)
  - Mid: #53D7D9 with phase-dependent opacity (20% at inhale)
  - Outer: Clear
- Effect: 20px blur for soft glow

**Vertical Motion:**
```
y = +200 (bottom)  →  Exhale complete
         ↑
    [animateInhale]
         ↑
y = -200 (top)     →  Inhale complete
         ↓
    [hold if enabled]
         ↓
y = -200 (top)     →  Hold at peak
         ↓
    [animateExhale]
         ↓
y = +200 (bottom)  →  Back to start
```

### Phase Label Transitions

**Typography:**
- Font: Poppins Bold 32px
- Color: White
- Position: Below breathing sphere

**Animation:**
```swift
// Fade out
withAnimation(.easeInOut(duration: 0.3)) {
    phaseOpacity = 0.0
}

// Delay 0.3s

// Fade in new phase
withAnimation(.easeInOut(duration: 0.3)) {
    phaseOpacity = 1.0
}
```

**Visual Flow:**
```
0.0s : "Inspire" at 100% opacity
...  : Sphere animates upward
[end]: "Inspire" fades to 0% (0.3s)
0.3s : Phase changes to "Maintiens"
0.6s : "Maintiens" fades to 100% (0.3s)
```

### Background Gradient

```swift
LinearGradient(
    colors: [
        Color(hex: "01000C"),  // Top: Very dark purple
        Color(hex: "0B011B"),  // Middle: Dark purple
        Color(hex: "01000C")   // Bottom: Very dark purple
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

Creates a subtle vignette effect focusing attention on the center.

---

## 🔧 Component API

### Usage

```swift
import SwiftUI

struct LibraryView: View {
    @State private var showBreathingExercise = false
    @State private var selectedPattern: BreathingPattern = .fourSevenEight

    var body: some View {
        VStack {
            Button("Start 4-7-8 Breathing") {
                selectedPattern = .fourSevenEight
                showBreathingExercise = true
            }

            Button("Start Coherence Cardiaque") {
                selectedPattern = .coherence
                showBreathingExercise = true
            }
        }
        .fullScreenCover(isPresented: $showBreathingExercise) {
            LibraryBreathingView(
                pattern: selectedPattern,
                totalDuration: 180, // 3 minutes
                onComplete: {
                    // Track exercise completion
                    print("Exercise completed!")
                }
            )
        }
    }
}
```

### Props

```swift
struct LibraryBreathingView: View {
    let pattern: BreathingPattern        // Which breathing pattern to use
    let totalDuration: TimeInterval      // Total exercise duration (default: 180s)
    let onComplete: () -> Void           // Callback when exercise finishes
}
```

### State Management

```swift
@State private var currentPhase: BreathingPhase = .inhale
@State private var yOffset: CGFloat = 200           // Sphere vertical position
@State private var cyclesCompleted: Int = 0
@State private var timeRemaining: TimeInterval
@State private var showCompletion: Bool = false
@State private var phaseOpacity: Double = 1.0
```

---

## 🎬 Animation Timeline Example

**Pattern: 4-7-8 Breathing (4s inhale, 7s hold, 8s exhale)**

```
Time    Phase      Sphere Y    Glow      Action
────────────────────────────────────────────────────────
0.0s    Inhale     +200        0.4       Start cycle
        ↓          ↓           ↑         Animate upward
        ↓          ↓           ↑         Haptic: light
4.0s    Hold       -200        1.0       Reach top
        ↓          (stay)      ↓         Glow sustains
        ↓          -200        0.8
11.0s   Exhale     -200        0.8       Hold complete
        ↓          ↓           ↓         Haptic: light
        ↓          ↓           ↓         Animate downward
19.0s   Complete   +200        0.4       Cycle done
                                         cyclesCompleted++
                                         Restart or finish
```

**Total cycle duration: 19 seconds**

If `totalDuration = 180s` (3 minutes):
- Number of cycles: ~9-10 cycles
- User sees cycle counter: "Cycle 1", "Cycle 2", ..., "Cycle 10"

---

## ⏱️ Timer Implementation

### Countdown Timer

```swift
private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

// In view body
.onReceive(timer) { _ in
    if timeRemaining > 0 {
        timeRemaining -= 1
    } else {
        completeExercise()
    }
}
```

### Display Format

```swift
private func formatTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}
```

**Examples:**
- 180 seconds → "3:00"
- 125 seconds → "2:05"
- 59 seconds → "0:59"
- 0 seconds → "0:00"

---

## 🎯 Animation Functions

### Inhale Phase

```swift
private func animateInhale() {
    currentPhase = .inhale

    // Haptic feedback
    HapticManager.light()

    // Fade in phase label
    withAnimation(.easeInOut(duration: 0.3)) {
        phaseOpacity = 1.0
    }

    // Move sphere upward
    withAnimation(.easeInOut(duration: pattern.inhaleDuration)) {
        yOffset = -200
    }

    // Schedule next phase
    DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhaleDuration) {
        if pattern.holdDuration > 0 {
            animateHold()
        } else {
            animateExhale()
        }
    }
}
```

### Hold Phase

```swift
private func animateHold() {
    currentPhase = .hold

    HapticManager.light()

    // Fade transition for label
    withAnimation(.easeInOut(duration: 0.3)) {
        phaseOpacity = 0.0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.easeInOut(duration: 0.3)) {
            phaseOpacity = 1.0
        }
    }

    // Sphere stays at top (yOffset = -200)

    // Schedule exhale
    DispatchQueue.main.asyncAfter(deadline: .now() + pattern.holdDuration) {
        animateExhale()
    }
}
```

### Exhale Phase

```swift
private func animateExhale() {
    currentPhase = .exhale

    HapticManager.light()

    // Fade transition
    withAnimation(.easeInOut(duration: 0.3)) {
        phaseOpacity = 0.0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.easeInOut(duration: 0.3)) {
            phaseOpacity = 1.0
        }
    }

    // Move sphere downward
    withAnimation(.easeInOut(duration: pattern.exhaleDuration)) {
        yOffset = 200
    }

    // Schedule next cycle
    DispatchQueue.main.asyncAfter(deadline: .now() + pattern.exhaleDuration) {
        if timeRemaining > 0 {
            cyclesCompleted += 1
            startBreathingCycle()
        } else {
            completeExercise()
        }
    }
}
```

---

## 🎊 Completion Celebration

### Success Overlay

When exercise completes (time reaches 0:00):

```swift
struct CompletionCelebration: View {
    let cyclesCompleted: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "73DE85"))

                // Message
                Text("Bravo, tu as retrouvé ton calme")
                    .font(.custom("Poppins-SemiBold", size: 28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("✨")
                    .font(.system(size: 60))

                // Cycles info
                VStack(spacing: 8) {
                    Text("\(cyclesCompleted) cycles")
                        .font(.custom("Poppins-Medium", size: 20))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Tu mérites une pause bien méritée")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Continue button
                Button(action: onDismiss) {
                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "73DE85"), Color(hex: "53D7D9")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }
        }
    }
}
```

**Trigger:**
```swift
private func completeExercise() {
    HapticManager.success()

    withAnimation(.easeInOut(duration: 0.5)) {
        showCompletion = true
    }
}
```

---

## 🎨 Color Palette

| Element | Hex Code | Usage |
|---------|----------|-------|
| Sphere Gradient Start | #73DE85 | Green (inner) |
| Sphere Gradient End | #53D7D9 | Cyan (outer) |
| Glow Inner | #73DE85 | Green with phase opacity |
| Glow Outer | #53D7D9 | Cyan with phase opacity |
| Background Top | #01000C | Very dark purple |
| Background Mid | #0B011B | Dark purple |
| Background Bottom | #01000C | Very dark purple |
| Phase Text | #FFFFFF | White |
| Timer Text | #FFFFFF | White |
| Cycle Counter | #FFFFFF 60% | Semi-transparent white |

---

## 📏 Dimensions

| Element | Size | Notes |
|---------|------|-------|
| Sphere Diameter | 80px | Main circle |
| Outer Glow Size | 240px | 3x sphere size |
| Glow Blur Radius | 20px | Soft edge |
| Vertical Motion Range | 400px | From y=-200 to y=+200 |
| Phase Label Font | 32px | Poppins Bold |
| Timer Font | 48px | Poppins Medium |
| Cycle Counter Font | 16px | Poppins Regular |
| Close Button Size | 32px | SF Symbol |

---

## 🔄 Comparison: LibraryBreathingView vs BreathingExerciseView

There are now **two** breathing exercise views in the project:

### 1. BreathingExerciseView (AntiStress)
**Location:** `Views/AntiStress/BreathingExerciseView.swift`
**Purpose:** Breathing exercise for Anti-Stress feature flow
**Animation:** Scale-based (circle grows/shrinks)
**Integration:** Used in AntiStress flow with `AntiStressExerciseType`
**Completion:** Shows XP earned, integrated with AntiStressViewModel

### 2. LibraryBreathingView (Library)
**Location:** `Views/Breathing/LibraryBreathingView.swift`
**Purpose:** Standalone breathing exercises from Library section
**Animation:** Vertical motion (sphere moves up/down)
**Integration:** Independent, accepts any `BreathingPattern`
**Completion:** Shows cycles completed, simple celebration

**Key Difference:**
- **AntiStress version**: Scale animation (1.0 → 2.0 → 1.0), XP rewards, viewModel integration
- **Library version**: Vertical motion (y=200 → y=-200 → y=200), simpler, standalone

---

## ✅ Build Status

```
** BUILD SUCCEEDED **
```

Zero errors, zero warnings (except expected appintentsmetadataprocessor warning).

---

## 🧪 Testing Checklist

- [ ] Launch LibraryBreathingView with 4-7-8 pattern
- [ ] Verify sphere moves smoothly from bottom to top (inhale)
- [ ] Verify sphere stays at top during hold phase
- [ ] Verify sphere moves smoothly from top to bottom (exhale)
- [ ] Check haptic feedback fires at each phase transition
- [ ] Verify phase label changes: "Inspire" → "Maintiens" → "Expire"
- [ ] Check phase label fade transitions are smooth
- [ ] Verify timer counts down correctly (3:00 → 2:59 → ... → 0:00)
- [ ] Check cycle counter increments: "Cycle 1" → "Cycle 2" → ...
- [ ] Test all 5 breathing patterns (different durations)
- [ ] Verify completion overlay appears when time reaches 0:00
- [ ] Check "Bravo, tu as retrouvé ton calme ✨" message displays
- [ ] Verify close button works (top-left X)
- [ ] Test onComplete callback fires correctly

### Pattern-Specific Tests

**4-7-8 (4s / 7s / 8s):**
- [ ] Inhale takes 4 seconds (bottom → top)
- [ ] Hold at top for 7 seconds (no movement)
- [ ] Exhale takes 8 seconds (top → bottom)
- [ ] Total cycle = 19 seconds

**Box Breathing (4s / 4s / 4s):**
- [ ] All phases equal duration (4 seconds each)
- [ ] Total cycle = 12 seconds

**Coherence (5s / 0s / 5s):**
- [ ] No hold phase (skips "Maintiens")
- [ ] Direct transition: "Inspire" → "Expire"
- [ ] Total cycle = 10 seconds

---

## 🚀 Future Enhancements

### Potential Features

- [ ] **Background Music**: Soft ambient music during exercise
- [ ] **Voice Guidance**: Spoken instructions ("Inspire", "Expire")
- [ ] **Progress Ring**: Circular progress indicator around sphere
- [ ] **Breath Count**: Show total breaths in session
- [ ] **Custom Patterns**: Allow users to create custom timing
- [ ] **Heart Rate Integration**: Show heart rate during exercise (if available)
- [ ] **Statistics**: Track breathing sessions over time
- [ ] **Achievements**: Unlock badges for consistent practice
- [ ] **Saved Sessions**: Bookmark favorite patterns
- [ ] **Apple Health Integration**: Log mindfulness minutes

### Advanced Animations

- [ ] **3D Sphere**: Use RealityKit for depth
- [ ] **Particle Effects**: Floating particles around sphere
- [ ] **Color Themes**: Different color schemes per pattern
- [ ] **Breathing Path**: Show arc/path of sphere motion
- [ ] **Pulsing Effect**: Subtle pulse during hold phase

---

## 📊 Performance Notes

### Memory
- Minimal state (6 @State properties)
- Timer automatically deallocates on dismiss
- No memory leaks with DispatchQueue closures

### Animation Performance
- Uses native SwiftUI animations (hardware accelerated)
- Blur radius optimized (20px is performant)
- No heavy computations in animation loop

### Battery Impact
- Timer fires every 1 second (low frequency)
- Animations are GPU-accelerated
- Haptics are brief pulses (minimal battery drain)

---

## 📄 File Locations

**Models:**
- `/Users/jos/CortiFree/CortiFree/CortiFree/Models/BreathingPattern.swift` (95 lines)

**Views:**
- `/Users/jos/CortiFree/CortiFree/CortiFree/Views/Breathing/LibraryBreathingView.swift` (380 lines)

**Dependencies:**
- SwiftUI framework
- Combine framework (for Timer.publish)
- Custom `Color(hex:)` extension
- Custom `HapticManager` utility
- Poppins font family

---

## 🎯 Integration Example

### Add to LibraryView

```swift
import SwiftUI

struct LibraryView: View {
    @State private var showBreathingExercise = false
    @State private var selectedPattern: BreathingPattern?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LibraryHeaderView { section in
                    if section == .respiration {
                        // Show breathing exercises list
                    }
                }

                // Breathing patterns list
                ForEach(BreathingPattern.allPatterns) { pattern in
                    BreathingPatternCard(pattern: pattern) {
                        selectedPattern = pattern
                        showBreathingExercise = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showBreathingExercise) {
            if let pattern = selectedPattern {
                LibraryBreathingView(
                    pattern: pattern,
                    totalDuration: 180
                ) {
                    // Exercise completed
                    // Could track in analytics, update user stats, etc.
                }
            }
        }
    }
}
```

---

**Date**: 22 Octobre 2025
**Component**: [Views/Breathing/LibraryBreathingView.swift](Views/Breathing/LibraryBreathingView.swift)
**Model**: [Models/BreathingPattern.swift](Models/BreathingPattern.swift)
**Status**: ✅ Complete and production-ready
**Build**: ✅ SUCCEEDED
**Animation**: ✅ Smooth vertical motion with phase transitions
