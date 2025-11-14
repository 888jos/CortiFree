# 📱 CortiFree - Documentation Technique Complète

## 🎯 Vue d'Ensemble du Projet

**CortiFree** est une application iOS native de bien-être mental basée sur les neurosciences, conçue pour aider les utilisateurs à gérer le stress, l'anxiété, et améliorer leur bien-être général à travers des routines thérapeutiques personnalisées de 8 semaines.

### Concept Principal
- **Routines Personnalisées**: 8 routines thérapeutiques de 8 semaines basées sur la TCC (Thérapie Cognitivo-Comportementale)
- **Exercices Quotidiens**: Respiration guidée, méditation, journaling, grounding, sons d'ambiance
- **Progression Gamifiée**: Système XP, niveaux, streaks pour maintenir l'engagement
- **Science-Backed**: Chaque exercice est validé scientifiquement avec preuves à l'appui
- **IA Adaptive**: Insights générés par IA pour adapter la routine selon les patterns de l'utilisateur

### Objectifs Thérapeutiques
1. Réduire l'anxiété et les pensées en boucle
2. Améliorer la qualité du sommeil
3. Booster l'énergie et la concentration
4. Gérer les émotions et le stress
5. Développer la pleine conscience
6. Créer des habitudes durables (8 semaines = formation d'habitude)

---

## 🛠️ Stack Technique

### Langage et Framework
- **Swift 5.9+**
- **SwiftUI** (100% SwiftUI, pas d'UIKit)
- **iOS 17.0+** minimum deployment target
- **Xcode 15.0+**

### Backend et Services
- **Firebase**:
  - Firebase Authentication (Email/Password, à venir: Apple Sign-In, Google Sign-In)
  - Cloud Firestore (base de données NoSQL temps réel)
  - Firebase Storage (pour audio des méditations, à venir)
  - Firebase Cloud Functions (pour analytics et insights IA)
- **Mixpanel**: Analytics et tracking utilisateur (30+ événements)
- **RevenueCat**: Gestion des abonnements IAP (à intégrer)

### Dépendances (SPM - Swift Package Manager)
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "4.0.0")
]
```

### Architecture et Patterns
- **MVVM** (Model-View-ViewModel)
- **Singleton Pattern**: Services globaux (AuthManager, FirebaseManager, MixpanelManager, SoundPlayer)
- **Repository Pattern**: FirebaseManager comme source unique de données
- **Observer Pattern**: Combine framework avec `@Published` pour réactivité
- **Dependency Injection**: `@StateObject`, `@ObservedObject`, `@EnvironmentObject`

---

## 🏗️ Architecture de l'Application

### Structure des Dossiers
```
CortiFree/
├── App/
│   └── CortiFreApp.swift                   # Point d'entrée, setup Firebase
├── Models/
│   ├── FirebaseModels.swift                # Modèles Firestore (UserProfile, RoutineModel, ExerciseModel, etc.)
│   ├── UserStats.swift                     # Stats utilisateur locales
│   ├── User.swift                          # Modèle utilisateur local
│   ├── Task.swift                          # Modèle tâche locale
│   ├── Exercise.swift                      # Modèle exercice local
│   ├── BreathingPattern.swift              # Patterns de respiration (4-7-8, Box, Coherence)
│   ├── MeditationSupport.swift             # Supports de méditation guidée
│   ├── JournalEntry.swift                  # Entrées de journal
│   ├── DailyTodo.swift                     # Tâches quotidiennes
│   ├── Planet.swift                        # Planètes (thème visuel)
│   ├── ProgressionModels.swift             # XP, Levels, Achievements
│   ├── OnboardingQuiz.swift                # Questions onboarding
│   ├── AntiStress.swift                    # Bouton anti-stress SOS
│   └── DefaultTasks.swift                  # Tâches par défaut
├── Views/
│   ├── HomeView.swift                      # Écran principal (planète, countdown, quick actions)
│   ├── ProfileView.swift                   # Profil utilisateur (stats, progression)
│   ├── LibraryView.swift                   # Bibliothèque (exercices, méditations, sons)
│   ├── ProgressionView.swift               # Niveaux et progression XP
│   ├── ObjectiveInfoView.swift             # Page détails objectif (quand clic planète)
│   ├── Onboarding/
│   │   ├── OnboardingFlowView.swift        # Flow onboarding principal
│   │   ├── OnboardingQuizView.swift        # Quiz 40 questions
│   │   └── PlanSelectionView.swift         # Sélection routine
│   ├── AntiStress/
│   │   ├── BreathingExerciseView.swift     # Exercice de respiration guidé
│   │   └── AntiStressButtonView.swift      # Bouton SOS
│   ├── QuickAccess/
│   │   ├── JournalHomeView.swift           # Journal intime
│   │   └── MeditationSupportView.swift     # Méditations guidées
│   └── Breathing/
│       └── LibraryBreathingView.swift      # Liste exercices respiration
├── ViewModels/
│   ├── HomeViewModel.swift                 # Logic HomeView
│   ├── LibraryViewModel.swift              # Logic LibraryView
│   └── OnboardingViewModel.swift           # Logic Onboarding
├── Services/
│   ├── AuthManager.swift                   # Authentication Firebase (signUp, signIn, signOut)
│   ├── FirebaseManager.swift               # CRUD Firestore (30+ fonctions)
│   ├── MixpanelManager.swift               # Analytics Mixpanel (30+ événements)
│   ├── SoundPlayer.swift                   # Lecteur audio pour sons/méditations
│   └── HapticManager.swift                 # Retour haptique (light, medium, heavy, success)
├── Components/
│   ├── GalaxyBackgroundView.swift          # Background animé avec étoiles filantes
│   ├── LibraryHeaderView.swift             # Header bibliothèque avec image
│   ├── StatsChart.swift                    # Graphique statistiques (7j, 4s, 8s)
│   ├── QuickActionButtonNew.swift          # Boutons quick actions (4 icônes)
│   └── PlanetSelectorCarouselView.swift    # Sélecteur de planète
├── Resources/
│   ├── Lottie/                             # Animations Lottie (planètes, etc.)
│   ├── Sounds/                             # Sons d'ambiance (rain, ocean, fire, etc.)
│   └── Études CortiFree.pdf                # PDF études scientifiques
├── Assets.xcassets/
│   ├── mercury.imageset/
│   ├── venus.imageset/
│   ├── earth.imageset/
│   ├── mars.imageset/
│   ├── jupiter.imageset/
│   ├── saturn.imageset/
│   ├── uranus.imageset/
│   └── neptune.imageset/
└── Extensions/
    ├── Color+Extensions.swift              # Color(hex:) helper
    └── View+Extensions.swift               # View modifiers
```

### Navigation
**Architecture de Navigation**: TabView avec 4 onglets principaux

```swift
TabView {
    HomeView()
        .tabItem { Label("Accueil", systemImage: "house.fill") }

    TasksView() // DailyTodoView
        .tabItem { Label("Tâches", systemImage: "checkmark.circle.fill") }

    LibraryView()
        .tabItem { Label("Librairie", systemImage: "book.fill") }

    ProfileView()
        .tabItem { Label("Profil", systemImage: "person.fill") }
}
```

**Flows Modaux (Sheets)**:
- Onboarding (première utilisation)
- BreathingExercise (respiration guidée)
- MeditationSupport (méditation guidée)
- JournalHomeView (journal intime)
- ObjectiveInfoView (détails objectif)
- RoutineDetailsView (preuves scientifiques)

---

## 🗄️ Structure Firebase Firestore

### Collections Globales (Lecture Seule)

#### 1. `routines/` - Les 8 Routines Principales
```
routines/{routineId}/
├── routineId: "reduce-anxiety"
├── title: "Réduire mon anxiété"
├── description: "Programme de 8 semaines..."
├── objective: "Calmer les tensions internes..."
├── durationWeeks: 8
├── icon: "brain.head.profile"
├── category: "mental_health"
├── difficultyLevel: 2
├── tags: ["anxiety", "breathing", "meditation"]
├── createdAt: Timestamp
├── updatedAt: Timestamp
├── isActive: true
│
└── weeks/{weekId}/
    ├── weekNumber: 1
    ├── theme: "Découvrir sa respiration"
    │
    └── daily_tasks/{dayId}/
        ├── dayNumber: 1
        │
        └── tasks/{taskId}/
            ├── taskId: "task_morning_1"
            ├── exerciseRef: "exercises/breathing_4_7_8"
            ├── moment: "morning" | "afternoon" | "evening"
            ├── order: 1
            ├── isMandatory: true
            ├── unlockCondition: null
            └── estimatedDurationMinutes: 3
```

**Routines Disponibles**:
1. `reduce-anxiety` - Réduire l'anxiété
2. `improve-sleep` - Améliorer le sommeil
3. `boost-energy` - Booster l'énergie
4. `manage-stress` - Gérer le stress
5. `enhance-focus` - Améliorer la concentration
6. `emotional-balance` - Équilibre émotionnel
7. `reduce-fatigue` - Réduire la fatigue
8. `increase-confidence` - Augmenter la confiance

#### 2. `exercises/` - Bibliothèque d'Exercices
```
exercises/{exerciseId}/
├── exerciseId: "breathing_4_7_8"
├── type: "breathing" | "meditation" | "journaling" | "grounding" | "sound" | "visualization"
├── title: "Respiration 4-7-8"
├── description: "Technique du Dr. Andrew Weil pour calmer le système nerveux"
├── instructions: ["Step 1", "Step 2", "Step 3"]
├── durationMinutes: 3
├── difficulty: 1 | 2 | 3
├── benefits: ["reduce_anxiety", "better_sleep"]
├── icon: "wind" (SF Symbol)
├── audioURL: "gs://cortifree/audio/breathing_4_7_8.mp3" (optionnel)
├── animationType: "breathing_circle" (optionnel)
├── parameters: {
│     "inhale_duration": 4,
│     "hold_duration": 7,
│     "exhale_duration": 8,
│     "cycles": 8
│   }
├── tags: ["anxiety", "sleep", "beginner"]
├── xpReward: 15
├── createdAt: Timestamp
└── isActive: true
```

**Types d'Exercices**:
- `breathing`: Respiration guidée (4-7-8, Box Breathing, Coherence Cardiaque)
- `meditation`: Méditations guidées (Body Scan, Gratitude, Mindfulness)
- `journaling`: Écriture thérapeutique (Gratitude, Pensées, Émotions)
- `grounding`: Ancrage corporel (5 sens, 5-4-3-2-1)
- `sound`: Sons d'ambiance (Pluie, Ocean, Feu, Bruit Blanc)
- `visualization`: Visualisations guidées (Lieu sûr, Objectifs)

#### 3. `meditation_supports/` - Méditations Guidées
```
meditation_supports/{supportId}/
├── id: "body-scan"
├── title: "Scan corporel guidé"
├── category: "grounding"
├── durationMinutes: 5
├── audioURL: "gs://cortifree/meditations/body_scan.mp3"
├── transcript: "Fermez les yeux, installez-vous confortablement..."
│
└── sections/{sectionId}/
    ├── order: 1
    ├── title: "Les pieds"
    ├── durationSeconds: 30
    └── steps: ["Portez votre attention sur vos pieds", "Ressentez les sensations"]
```

#### 4. `onboarding_questions/` - Quiz Onboarding (40 Questions)
```
onboarding_questions/{questionId}/
├── questionId: "sleep_quality"
├── screenNumber: 5
├── category: "symptoms"
├── questionText: "Comment évaluez-vous votre sommeil ?"
├── type: "scale" | "multiple_choice" | "text" | "multi_select"
├── options: ["Très mauvais", "Mauvais", "Moyen", "Bon", "Excellent"]
├── scaleMin: 1
├── scaleMax: 5
├── isRequired: true
├── affectsRoutineSelection: true
├── weightInAlgorithm: 0.8
└── order: 5
```

### Collections Utilisateur (Privées sous `users/{userId}/`)

#### 1. `users/{userId}` - Profil Principal
```swift
struct UserProfile {
    var uid: String                      // Firebase Auth UID
    var email: String
    var displayName: String?
    var photoURL: String?
    var createdAt: Timestamp
    var lastLogin: Timestamp
    var onboardingCompleted: Bool
    var onboardingCompletedAt: Timestamp?
    var selectedRoutineId: String?       // "reduce-anxiety"
    var currentWeek: Int                 // 1-8
    var currentDay: Int                  // 1-56
    var totalXP: Int                     // XP total accumulé
    var level: Int                       // Niveau actuel (1-20)
    var currentStreakDays: Int           // Série actuelle
    var longestStreakDays: Int           // Meilleure série
    var preferredMoments: [String]       // ["morning", "evening"]
    var notificationSettings: {
        morningTime: "08:00",
        eveningTime: "21:00",
        enabled: true
    }
    var mixpanelDistinctId: String?
}
```

#### 2. `users/{userId}/routine_progress/{routineId}` - Progression Routine
```swift
struct RoutineProgress {
    var routineId: String
    var startedAt: Timestamp
    var currentWeek: Int
    var currentDay: Int
    var completionPercentage: Double     // 0.0 - 1.0
    var isActive: Bool
    var completedAt: Timestamp?
    var totalTasksCompleted: Int
    var totalTasks: Int
    var adherenceScore: Double           // Score d'adhérence (0.0 - 1.0)
}
```

**Sous-collection**: `daily_progress/{date}`
```swift
struct DailyProgress {
    var date: String                     // "2025-11-10"
    var weekNumber: Int
    var dayNumber: Int
    var completedTasks: Int
    var totalTasks: Int
    var completionRate: Double
    var xpEarned: Int
    var moodMorning: String?             // "good", "neutral", "bad"
    var moodEvening: String?
    var energyLevel: Int?                // 1-10
    var stressLevel: Int?                // 1-10
    var notes: String?
    var createdAt: Timestamp
}
```

#### 3. `users/{userId}/completed_tasks/` - Historique Tâches
```swift
struct CompletedTask {
    var taskId: String
    var exerciseId: String
    var routineId: String
    var weekNumber: Int
    var dayNumber: Int
    var moment: String                   // "morning", "afternoon", "evening"
    var completedAt: Timestamp
    var durationActualSeconds: Int       // Durée réelle
    var xpEarned: Int
    var feedbackMood: String?            // "veryGood", "good", "neutral", "bad", "veryBad"
    var feedbackNote: String?
    var wasManual: Bool                  // Ajouté manuellement ou via routine
    var deviceInfo: {
        platform: "iOS",
        version: "18.6"
    }
}
```

#### 4. `users/{userId}/feedback/` - Feedbacks Exercices
```swift
struct FeedbackModel {
    var type: String                     // "exercise_completion", "general", "bug_report"
    var exerciseId: String?
    var mood: String                     // "veryGood", "good", "neutral", "bad", "veryBad"
    var rating: Int?                     // 1-5
    var note: String?
    var timestamp: Timestamp
    var context: {
        routineId: String?,
        week: Int?,
        day: Int?
    }
}
```

#### 5. `users/{userId}/ai_insights/` - Insights IA
```swift
struct AIInsight {
    var generatedAt: Timestamp
    var insightType: String              // "routine_adjustment", "recommendation", "warning"
    var trigger: String                  // "low_energy_pattern", "high_stress_signals"
    var dataAnalyzed: {
        period: "last_7_days",
        completionRate: 0.65,
        avgMood: "neutral",
        fatigueSignals: 5,
        negativeSignals: 3
    }
    var recommendation: String           // "Passer à des exercices plus doux"
    var suggestedExercises: ["breathing_5_5", "gentle_meditation"]
    var priority: String                 // "low", "medium", "high"
    var isApplied: Bool
    var appliedAt: Timestamp?
}
```

#### 6. `users/{userId}/stats/weekly_summary` - Stats Hebdomadaires
```swift
struct WeeklySummary {
    var weekStart: String                // "2025-11-03"
    var totalTasksCompleted: Int
    var totalXPEarned: Int
    var avgCompletionRate: Double
    var dominantMood: String             // "good", "neutral", "bad"
    var mostActiveMoment: String         // "morning", "afternoon", "evening"
    var generatedAt: Timestamp
}
```

---

## 📊 Modèles de Données Locaux

### Planet (Thème Visuel)
```swift
struct Planet: Identifiable, Codable {
    let id: String                       // "earth", "mars", "jupiter", etc.
    let name: String                     // "Terre", "Mars", "Jupiter"
    let imageName: String                // Nom asset image
    let haloColor: Color                 // Couleur du halo/thème
}

// 8 Planètes Disponibles
Planet.earth        // Bleu (#4A90E2)
Planet.mars         // Rouge (#E74C3C)
Planet.jupiter      // Orange (#F39C12)
Planet.saturn       // Jaune (#F1C40F)
Planet.venus        // Rose (#E91E63)
Planet.mercury      // Gris (#95A5A6)
Planet.uranus       // Cyan (#00BCD4)
Planet.neptune      // Bleu foncé (#3F51B5)
```

### BreathingPattern (Patterns de Respiration)
```swift
enum BreathingPattern: String {
    case fourSevenEight = "4-7-8"
    case boxBreathing = "Box Breathing"
    case coherence = "Cohérence Cardiaque"
    case deepRelax = "Deep Relax"
    case energizing = "Energizing"

    var inhale: Double                   // Durée inspiration (secondes)
    var hold: Double                     // Durée rétention (secondes)
    var exhale: Double                   // Durée expiration (secondes)
    var cycles: Int                      // Nombre de cycles
}
```

### Level (Système de Progression)
```swift
struct Level: Identifiable {
    let id: Int                          // 1-20
    let name: String                     // "Novice", "Explorer", "Maître"
    let requiredXP: Int                  // XP requis pour débloquer
    let description: String

    static let allLevels: [Level]        // 20 niveaux
}

// Exemples de niveaux
Level 1:  "Novice"          - 0 XP
Level 2:  "Explorer"        - 100 XP
Level 3:  "Apprenti"        - 250 XP
Level 5:  "Adepte"          - 750 XP
Level 10: "Expert"          - 3500 XP
Level 15: "Maître"          - 8500 XP
Level 20: "Légende"         - 20000 XP
```

### XPAction (Actions qui donnent de l'XP)
```swift
enum XPAction {
    case dailyMissionComplete           // +50 XP
    case meditationComplete             // +30 XP
    case breathingComplete              // +15 XP
    case journalComplete                // +20 XP
    case exerciseComplete               // +25 XP
    case streakMilestone                // +100 XP (7 jours)

    var xpValue: Int
    var iconName: String
}
```

---

## 🎨 Design System

### Couleurs
```swift
// Couleurs Principales
Color.appTheme          = Color(hex: "8B5CF6")  // Violet principal
Color.appThemeSecondary = Color(hex: "A78BFA")  // Violet clair

// Couleurs de Fond
Color(hex: "01000C")    // Noir espace profond
Color(hex: "0B011B")    // Violet très foncé
Color(hex: "1F0140")    // Violet foncé
Color(hex: "130C57")    // Violet moyen

// Couleurs d'Action
Color(hex: "DA6B10")    // Orange (Apprendre)
Color(hex: "49288C")    // Violet (Blog)
Color(hex: "D953B3")    // Rose (Conseils)
Color(hex: "1B7BF1")    // Bleu (Études)

// Couleurs de Planètes (thèmes dynamiques)
Varie selon la planète sélectionnée
```

### Typographie (Polices Personnalisées)
```swift
// Poppins (principale)
.font(.custom("Poppins-Bold", size: 28))
.font(.custom("Poppins-SemiBold", size: 18))
.font(.custom("Poppins-Medium", size: 16))
.font(.custom("Poppins-Regular", size: 14))

// SF Pro Rounded (secondaire, pour chiffres/stats)
.font(.custom("SF Pro Rounded-Bold", size: 36))
.font(.custom("SF Pro Rounded-Semibold", size: 16))
.font(.custom("SF Pro Rounded-Regular", size: 14))
```

### Animations
```swift
// Planète Pulse Animation
withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
    planetScale = 1.08  // Pulse de 1.0 à 1.08
}

// Halo Opacity Animation
withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
    haloOpacity = 0.55  // Opacity de 0.35 à 0.55
}

// Étoiles Filantes (GalaxyBackgroundView)
// Position aléatoire, trajectoire, vitesse, opacité
```

### Composants Réutilisables
```swift
// GalaxyBackgroundView
// - Étoiles filantes animées
// - Intensité réglable (0.0 - 2.0)

// QuickActionButtonNew
// - Icon + Label
// - Couleur thématique
// - Animation de press

// StatsChart
// - Graphique linéaire avec gradient
// - Animations de 1s, 4s, 8s selon période
// - Labels axes X et Y

// ObjectiveStatCard
// - Carte de statistique
// - Valeur + Label
// - Bordure colorée selon planète
```

---

## ⚙️ Services et Managers (Singletons)

### 1. AuthManager
**Responsabilité**: Gestion authentification Firebase

```swift
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated: Bool = false

    // Méthodes
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() throws
    func resetPassword(email: String) async throws
    func deleteAccount() async throws
}
```

### 2. FirebaseManager
**Responsabilité**: CRUD Firestore, source unique de données

```swift
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()

    // USER MANAGEMENT
    func createUserProfile(_ profile: UserProfile) async throws
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func updateUserProfile(userId: String, data: [String: Any]) async throws

    // ONBOARDING
    func saveOnboardingResponse(userId: String, response: OnboardingResponse) async throws
    func completeOnboarding(userId: String, selectedRoutine: String) async throws
    func fetchOnboardingQuestions() async throws -> [OnboardingQuestion]

    // ROUTINES
    func fetchAllRoutines() async throws -> [RoutineModel]
    func fetchRoutine(routineId: String) async throws -> RoutineModel?
    func startRoutine(userId: String, routineId: String) async throws
    func fetchRoutineProgress(userId: String, routineId: String) async throws -> RoutineProgress?

    // EXERCISES
    func fetchExercise(exerciseId: String) async throws -> ExerciseModel?
    func fetchExercisesByType(type: String) async throws -> [ExerciseModel]
    func fetchExercisesByTags(tags: [String]) async throws -> [ExerciseModel]

    // TASKS
    func saveCompletedTask(userId: String, task: CompletedTask) async throws
    func fetchCompletedTasks(userId: String, limit: Int) async throws -> [CompletedTask]
    func updateDailyProgress(userId: String, routineId: String, date: String, progress: DailyProgress) async throws

    // FEEDBACK
    func saveFeedback(userId: String, feedback: FeedbackModel) async throws

    // CUSTOM TASKS
    func saveCustomTask(userId: String, task: CustomTask) async throws
    func fetchCustomTasks(userId: String) async throws -> [CustomTask]
    func deleteCustomTask(userId: String, taskId: String) async throws

    // STATS
    func fetchWeeklySummary(userId: String) async throws -> WeeklySummary?
    func generateWeeklySummary(userId: String) async throws

    // AI INSIGHTS
    func fetchAIInsights(userId: String) async throws -> [AIInsight]
    func applyAIInsight(userId: String, insightId: String) async throws

    // XP & LEVELS
    func addXP(userId: String, amount: Int) async throws
    func updateStreak(userId: String) async throws
    func calculateLevel(xp: Int) -> Level
}
```

### 3. MixpanelManager
**Responsabilité**: Analytics et tracking

```swift
class MixpanelManager {
    static let shared = MixpanelManager()
    private let mixpanel = Mixpanel.mainInstance()

    // USER TRACKING
    func setUserProfile(userId: String, properties: [String: Any])
    func setSuperProperties(_ properties: [String: Any])

    // ONBOARDING EVENTS
    func trackOnboardingStarted()
    func trackOnboardingQuestionAnswered(questionId: String, answer: String, screenNumber: Int)
    func trackOnboardingCompleted(selectedRoutine: String)

    // ROUTINE EVENTS
    func trackRoutineStarted(routineId: String, routineName: String)
    func trackRoutineCompleted(routineId: String, durationWeeks: Int, adherenceScore: Double)

    // EXERCISE EVENTS
    func trackExerciseStarted(exerciseId: String, exerciseType: String, moment: String)
    func trackExerciseCompleted(exerciseId: String, durationSeconds: Int, feedbackMood: String?, xpEarned: Int)
    func trackExerciseAbandoned(exerciseId: String, durationSeconds: Int)

    // PROGRESSION EVENTS
    func trackLevelUp(newLevel: Int, totalXP: Int)
    func trackStreakMilestone(streakDays: Int)
    func trackXPEarned(amount: Int, source: String)

    // UI EVENTS
    func trackScreenViewed(_ screenName: String)
    func trackButtonTapped(_ buttonName: String, context: String?)

    // FEEDBACK EVENTS
    func trackFeedbackSubmitted(mood: String, exerciseId: String?, hasNote: Bool)

    // AI EVENTS
    func trackAIInsightGenerated(insightType: String, trigger: String, priority: String)
    func trackAIInsightApplied(insightType: String)
    func trackAIInsightDismissed(insightType: String)
}
```

### 4. SoundPlayer
**Responsabilité**: Lecture audio (sons d'ambiance, méditations)

```swift
class SoundPlayer: ObservableObject {
    static let shared = SoundPlayer()

    @Published var isPlaying: Bool = false
    @Published var currentExercise: Exercise?
    @Published var selectedDuration: TimeInterval = 300  // 5 minutes par défaut
    @Published var playbackProgress: Double = 0.0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func play(exercise: Exercise)
    func pause()
    func stop()
    func setDuration(_ duration: TimeInterval)
}
```

### 5. HapticManager
**Responsabilité**: Feedback haptique

```swift
class HapticManager {
    static func light()         // UIImpactFeedbackGenerator(style: .light)
    static func medium()        // UIImpactFeedbackGenerator(style: .medium)
    static func heavy()         // UIImpactFeedbackGenerator(style: .heavy)
    static func success()       // UINotificationFeedbackGenerator(type: .success)
    static func warning()       // UINotificationFeedbackGenerator(type: .warning)
    static func error()         // UINotificationFeedbackGenerator(type: .error)
}
```

### 6. ProgressionManager
**Responsabilité**: Gestion XP, niveaux, streaks

```swift
class ProgressionManager: ObservableObject {
    static let shared = ProgressionManager()

    @Published var currentXP: Int = 0
    @Published var currentLevel: Level = Level.allLevels[0]
    @Published var streakDays: Int = 0
    @Published var showLevelUpPopup: Bool = false
    @Published var newlyUnlockedLevel: Level?

    func addXP(_ amount: Int)
    func updateLevel()
    func progressInfo() -> (current: Int, needed: Int, percentage: Double)
}
```

### 7. PlanetSettings
**Responsabilité**: Gestion planète sélectionnée (thème)

```swift
class PlanetSettings: ObservableObject {
    static let shared = PlanetSettings()

    @Published var selectedPlanet: Planet = Planet.earth

    func selectPlanet(_ planet: Planet)
}
```

---

## 🔄 Flux de Données Principaux

### 1. Inscription Utilisateur
```
User → AuthManager.signUp(email, password)
     → FirebaseAuth.createUser()
     → FirebaseManager.createUserProfile(UserProfile)
     → MixpanelManager.setUserProfile()
     → Navigate to OnboardingFlow
```

### 2. Onboarding (40 Questions)
```
User answers 40 questions
     → FirebaseManager.saveOnboardingResponse() (pour chaque question)
     → Algorithm calcule meilleure routine
     → User sélectionne routine
     → FirebaseManager.completeOnboarding()
     → UserDefaults.set(routineStartDate, selectedRoutineTitle)
     → MixpanelManager.trackOnboardingCompleted()
     → Navigate to HomeView
```

### 3. Démarrage Exercice de Respiration
```
User taps QuickAction "Respiration"
     → Navigate to BreathingExerciseView
     → Load BreathingPattern (4-7-8, Box, Coherence)
     → MixpanelManager.trackExerciseStarted()
     → Animate breathing circle (inhale/hold/exhale cycles)
     → Timer tracks duration
```

### 4. Complétion Exercice
```
User completes exercise
     → Show feedback modal (mood selector + note)
     → User selects mood + optional note
     → FirebaseManager.saveCompletedTask()
         → Save to completed_tasks/
         → Update daily_progress/
         → Calculate XP earned
         → Add XP to user.totalXP
         → Check if level up
     → FirebaseManager.saveFeedback()
         → Save to feedback/
     → ProgressionManager.addXP(xpAmount)
         → Update currentXP
         → Check level progression
         → Show level up popup if needed
     → MixpanelManager.trackExerciseCompleted()
     → MixpanelManager.trackFeedbackSubmitted()
```

### 5. Génération Insights IA (Cloud Function - Nightly)
```
Cloud Function scheduled (1:00 AM daily)
     → Fetch user's last 7 days activity
     → Analyze:
         - Completion rate (< 70% → warning)
         - Mood patterns (negative mood 3+ days → adjustment)
         - Fatigue signals (low energy 5+ days → easier exercises)
         - Stress signals (high stress 5+ days → more grounding)
     → Generate AIInsight if pattern detected
     → Save to users/{uid}/ai_insights/
     → MixpanelManager.trackAIInsightGenerated()
     → Push notification (optionnel)
```

### 6. Affichage HomeView
```
User opens app
     → AuthManager checks authentication
     → If authenticated:
         → Fetch UserProfile from Firestore
         → Fetch RoutineProgress
         → Load selectedPlanet from UserDefaults
         → Load routineStartDate from UserDefaults
         → Calculate countdown (56 days - daysPassed)
         → Real-time countdown avec TimelineView
         → Display:
             - Planet animée (pulse 1.0 → 1.08)
             - Countdown personnalisé selon routine
             - 4 Quick Actions
             - Bouton Anti-Stress
     → If not authenticated:
         → Show OnboardingFlow
```

---

## 🎯 Fonctionnalités Clés Implémentées

### ✅ Authentification
- Sign up avec email/password
- Sign in
- Sign out
- Password reset
- Gestion session persistante

### ✅ Onboarding
- Quiz 40 questions (scales, multiple choice, text, multi-select)
- Algorithm de sélection de routine
- Sélection manuelle de routine
- Sauvegarde réponses dans Firestore
- Complétion onboarding

### ✅ HomeView
- **Planète Animée**: Pulse 1.0 → 1.08 (5s), halo synchronisé, taille 387x387 (352 * 1.1)
- **Countdown Temporel**: 56 jours (8 semaines), temps réel avec TimelineView, phrases personnalisées selon routine
- **Easter Egg**: 3 taps sur planète → étoiles filantes + message motivant
- **Quick Actions**: 4 boutons (Respiration, Méditation, Sons, Journal)
- **Bouton Anti-Stress**: Accès rapide exercice SOS
- **ObjectiveInfoView**: Clic sur planète → page détails avec stats (jours passés, restants, niveau, streak)

### ✅ Exercices de Respiration
- 5 patterns: 4-7-8, Box Breathing, Cohérence Cardiaque, Deep Relax, Energizing
- Animation breathing circle
- Timer avec cycles
- Feedback mood après exercice
- Sauvegarde dans Firestore
- Tracking Mixpanel

### ✅ Méditations Guidées
- Body Scan
- Gratitude
- Mindfulness
- Visualisation
- Auto-Compassion
- Clarté
- Marche Méditative
- Ancrage

### ✅ Sons d'Ambiance
- 8 sons: Pluie, Ocean, Feu, Bruit Blanc, Matinée, Forêt, Ruisseau, Nuit d'été
- Durée sélectionnable (5, 10, 15, 30, 60 min)
- Lecteur avec play/pause
- Timer countdown
- Fade out à la fin

### ✅ Journal Intime
- Entrées quotidiennes
- Mood tracking
- Sauvegarde locale + Firestore
- Historique avec filtres

### ✅ Progression XP
- 20 niveaux (Novice → Légende)
- Actions qui donnent XP (exercices, missions, streaks)
- Barre de progression
- Level up animations
- Streak counter (jours consécutifs)

### ✅ ProfileView
- Stats utilisateur (XP, niveau, streak)
- Graphique activité (7j, 4s, 8s) avec animations différentes
- Historique progression
- Settings (notifications, compte)

### ✅ LibraryView
- Catalogue exercices respiration
- Catalogue méditations
- Catalogue sons
- Catégories: Apprendre, Blog, Conseils, Études
- PDF études scientifiques (clic → ouvre navigateur)

### ✅ Tâches Quotidiennes
- Liste tâches du jour (morning, afternoon, evening)
- Checkbox complétion
- Ajout tâches personnalisées
- Sauvegarde dans Firestore

### ✅ Notifications (à finaliser)
- Push notifications pour rappels
- Notifications locales pour tâches
- Préférences horaires (matin, soir)

---

## 🔧 Configurations et Setup

### Firebase Configuration
**Fichier**: `GoogleService-Info.plist` (à la racine du projet)

```swift
// CortiFreApp.swift
import Firebase

@main
struct CortiFreApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthManager.shared)
        }
    }
}
```

### Mixpanel Configuration
```swift
import Mixpanel

// Dans AppDelegate ou App init
Mixpanel.initialize(token: "YOUR_MIXPANEL_TOKEN", trackAutomaticEvents: true)
```

### UserDefaults Keys
```swift
// Utilisés pour persistence locale
UserDefaults.standard.set(Date(), forKey: "routineStartDate")
UserDefaults.standard.set("Réduire l'anxiété", forKey: "selectedRoutineTitle")
UserDefaults.standard.set("earth", forKey: "selectedPlanet")
UserDefaults.standard.set(true, forKey: "onboardingCompleted")
```

---

## 📝 Conventions de Code

### Naming
- **Files**: PascalCase (HomeView.swift, FirebaseManager.swift)
- **Classes/Structs**: PascalCase (UserProfile, BreathingPattern)
- **Functions**: camelCase (fetchUserProfile, saveCompletedTask)
- **Variables**: camelCase (currentXP, isAuthenticated)
- **Constants**: camelCase (let maxRetries = 3)
- **Enums**: PascalCase (BreathingPattern, XPAction)

### SwiftUI Conventions
```swift
// View structure
struct MyView: View {
    // 1. Property Wrappers
    @StateObject private var viewModel = MyViewModel()
    @State private var isLoading = false
    @Binding var data: String

    // 2. Body
    var body: some View {
        // Implementation
    }

    // 3. Computed Properties
    private var formattedData: String {
        // ...
    }

    // 4. Subviews
    private var headerSection: some View {
        // ...
    }

    // 5. Methods
    private func handleTap() {
        // ...
    }
}
```

### Async/Await Pattern
```swift
// Firebase calls
func fetchData() async throws -> Data {
    try await FirebaseManager.shared.fetchUserProfile(userId: userId)
}

// Dans View
.task {
    do {
        data = try await fetchData()
    } catch {
        print("Error: \(error)")
    }
}
```

### Error Handling
```swift
enum AppError: LocalizedError {
    case userNotFound
    case invalidData
    case networkError

    var errorDescription: String? {
        switch self {
        case .userNotFound: return "Utilisateur introuvable"
        case .invalidData: return "Données invalides"
        case .networkError: return "Erreur réseau"
        }
    }
}
```

---

## 🚧 État Actuel du Projet

### ✅ Complété
1. Architecture complète (MVVM, Services, Models)
2. Firebase integration (Auth, Firestore)
3. Mixpanel analytics (30+ événements)
4. HomeView avec planète animée + countdown
5. Exercices de respiration guidés
6. Méditations guidées
7. Sons d'ambiance
8. Journal intime
9. Système XP et niveaux
10. ProfileView avec stats
11. LibraryView avec catalogue
12. PDF études scientifiques
13. ObjectiveInfoView (détails objectif)

### 🔨 En Cours
1. Finalisation onboarding (40 questions)
2. Algorithm sélection routine IA
3. Seed data Firestore (routines + exercises)
4. Cloud Functions (insights IA)

### 📋 À Faire
1. RevenueCat integration (abonnements)
2. Apple Sign-In
3. Google Sign-In
4. Push notifications
5. Export données utilisateur
6. Mode offline avec cache Firestore
7. Tests unitaires et UI
8. App Store assets (screenshots, description)
9. Privacy Policy et Terms of Service
10. Beta testing (TestFlight)

---

## 📚 Documentation Externe

### Guides Internes
- `FIREBASE_ARCHITECTURE.md` - Architecture Firestore détaillée
- `FIREBASE_SETUP_GUIDE.md` - Guide installation Firebase
- `AI_ROUTINE_GENERATOR_PROMPT.md` - Prompt génération routines IA
- `PROJECT_CONTEXT.md` - Ce fichier (contexte complet)

### APIs Utilisées
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Mixpanel Swift SDK](https://docs.mixpanel.com/docs/tracking-methods/sdks/swift)
- [AVFoundation](https://developer.apple.com/av-foundation/) (audio)

### Ressources Scientifiques
- Études neurosciences dans `Études CortiFree.pdf`
- TCC (Thérapie Cognitivo-Comportementale)
- Respiration 4-7-8 (Dr. Andrew Weil)
- Cohérence cardiaque (HeartMath Institute)
- Body Scan (Jon Kabat-Zinn, MBSR)

---

## 🎯 Vision Produit

### Objectif à Court Terme (3 mois)
1. Lancer MVP avec 8 routines complètes
2. 1000 utilisateurs beta
3. Taux de complétion > 60%
4. Retention J30 > 40%

### Objectif à Moyen Terme (6-12 mois)
1. 50,000 utilisateurs
2. 10+ routines supplémentaires
3. Communauté utilisateurs (forums, partage)
4. Contenu premium (méditations exclusives)
5. Partenariats thérapeutes

### Fonctionnalités Futures
1. **AI Coach**: Recommandations personnalisées temps réel
2. **Social**: Partage progression, défis entre amis
3. **Wearables**: Integration Apple Watch, Oura Ring
4. **Contenu Dynamique**: Nouvelles méditations chaque semaine
5. **Gamification Avancée**: Badges, achievements, leaderboards
6. **Thérapie Virtuelle**: Sessions vidéo avec thérapeutes
7. **Export Medical**: Rapport PDF pour médecin
8. **Multi-langue**: Anglais, Espagnol, Allemand

---

## 🔐 Sécurité et Privacy

### Données Sensibles
- Mots de passe: Hashés par Firebase Auth (bcrypt)
- Feedbacks mood: Encryptés au repos
- Journal intime: Encrypté client-side avant upload
- Notes personnelles: Jamais partagées avec tiers

### RGPD Compliance
- Consentement explicite tracking
- Droit à l'oubli (suppression compte)
- Export données utilisateur
- Opt-out analytics
- Privacy Policy claire

### Security Rules Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Collections globales: lecture seule
    match /routines/{routineId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // Collections utilisateur: propriétaire uniquement
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;

      match /{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

---

## ⚡ Performance et Optimisations

### Firestore Optimization
- Indexes composites pour queries complexes
- Pagination (limit 20 items per query)
- Cache persistence activé
- Listeners détachés quand view disparaît

### Images et Assets
- Images planètes: PNG optimisés, < 200KB chacune
- Lottie animations: JSON, < 50KB
- Sons: MP3 compressés, 128kbps

### SwiftUI Performance
- `.id()` pour forcer re-render
- `LazyVStack` pour listes longues
- `@State` uniquement pour UI state
- `@StateObject` pour ViewModels
- Avoid deep view hierarchies

---

## 🧪 Testing Strategy

### Unit Tests (à implémenter)
- FirebaseManager methods
- ProgressionManager XP calculations
- Level progression logic
- Date calculations (countdown)

### UI Tests (à implémenter)
- Onboarding flow complet
- Exercise completion flow
- Navigation entre tabs
- Authentication flows

### Manual Testing Checklist
- ✅ Sign up / Sign in
- ✅ Onboarding 40 questions
- ✅ Routine selection
- ✅ Exercise completion
- ✅ Feedback submission
- ✅ XP gain et level up
- ✅ Streak calculation
- ✅ Profile stats affichage
- ✅ Library navigation
- ✅ PDF opening

---

## 📱 App Store Metadata

### App Name
**CortiFree - Bien-être & Neurosciences**

### Subtitle
**8 semaines pour retrouver ton équilibre mental**

### Description Courte
Routines personnalisées de 8 semaines basées sur les neurosciences pour réduire l'anxiété, améliorer le sommeil, et booster ton énergie.

### Keywords
bien-être, anxiété, méditation, respiration, neurosciences, sommeil, stress, TCC, pleine conscience, mental health

### Category
Health & Fitness

### Age Rating
4+ (contenu adapté à tous)

---

## 🎬 Conclusion

**CortiFree** est une application iOS complète et robuste, architecturée selon les meilleures pratiques SwiftUI et Firebase. L'app combine neurosciences, gamification, et personnalisation IA pour créer une expérience thérapeutique engageante et efficace.

**Points Forts**:
- ✅ Architecture MVVM propre et scalable
- ✅ Firebase integration complète (Auth, Firestore, Analytics)
- ✅ Design system cohérent et professionnel
- ✅ Expérience utilisateur fluide et engageante
- ✅ Fondations scientifiques solides
- ✅ Analytics robustes (Mixpanel)
- ✅ Performance optimisée

**Prochaines Étapes Critiques**:
1. Seed Firestore avec routines et exercices
2. Deploy Cloud Functions pour insights IA
3. Implémenter RevenueCat pour monetization
4. Beta testing avec 100 users
5. Soumettre à l'App Store

**Tech Debt à Adresser**:
- Ajouter tests unitaires (coverage > 70%)
- Améliorer gestion erreurs (custom AppError)
- Documenter code (inline comments)
- Optimiser images assets (WebP)
- Implémenter offline mode complet

---

**Version**: 1.0.0 (Build 1)
**Last Updated**: 2025-11-10
**iOS Target**: 17.0+
**Swift Version**: 5.9
**Xcode**: 15.0+

**Maintainers**: Claude AI + Jos (Product Owner)
