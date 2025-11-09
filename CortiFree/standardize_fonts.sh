#!/bin/bash

# Script pour standardiser toutes les polices dans l'application CortiFree
# Remplace .font(.system(...)) par les polices Poppins et SF Pro Rounded appropriées

echo "🔄 Début de la standardisation des polices..."

# Liste des fichiers à traiter
files=(
    "./Views/AntiStress/AntiStressSituationView.swift"
    "./Views/AntiStress/BreathingExerciseView.swift"
    "./Views/AntiStress/GenericExerciseView.swift"
    "./Views/AntiStress/GroundingExerciseView.swift"
    "./Views/Auth/AuthView.swift"
    "./Views/Auth/LoginView.swift"
    "./Views/Auth/ResetPasswordView.swift"
    "./Views/Auth/SignUpView.swift"
    "./Views/Breathing/LibraryBreathingView.swift"
    "./Views/DailyTodos/DailyTodosView.swift"
    "./Views/Journal/JournalView.swift"
    "./Views/LevelDetailsView.swift"
    "./Views/Library/BreathingExerciseDetailView.swift"
    "./Views/Meditation/GuidedMeditationSessionView.swift"
    "./Views/Meditation/MeditationSupportView.swift"
    "./Views/Onboarding/AuthenticationView.swift"
    "./Views/Onboarding/ConsequencesFlowView.swift"
    "./Views/Onboarding/DiagnosticResultView.swift"
    "./Views/Onboarding/OnboardingQuizView.swift"
    "./Views/Onboarding/RecoveryBenefitsFlowView.swift"
    "./Views/Onboarding/SymptomsSelectionView.swift"
    "./Views/PlanetSelectorCarouselView.swift"
    "./Views/QuickAccess/BreathingListView.swift"
    "./Views/QuickAccess/JournalHomeView.swift"
    "./Views/QuickAccess/MeditationListView.swift"
    "./Views/QuickAccess/SoundsListView.swift"
    "./Views/Settings/PlanetSettingsView.swift"
    "./Views/Tasks/AddTaskView.swift"
    "./Views/Tasks/TaskDetailView.swift"
    "./ContentView.swift"
)

# Fonction pour remplacer les polices
replace_fonts() {
    local file=$1
    echo "📝 Traitement de $file..."

    # SF Pro Rounded pour les chiffres/scores
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.bold, design: \.rounded))/.font(.custom("SF Pro Rounded-Bold", size: \1))/g' "$file"
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.semibold, design: \.rounded))/.font(.custom("SF Pro Rounded-Semibold", size: \1))/g' "$file"
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.medium, design: \.rounded))/.font(.custom("SF Pro Rounded-Medium", size: \1))/g' "$file"
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.regular, design: \.rounded))/.font(.custom("SF Pro Rounded-Regular", size: \1))/g' "$file"

    # Poppins pour le texte
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.bold))/.font(.custom("Poppins-Bold", size: \1))/g' "$file"
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.semibold))/.font(.custom("Poppins-SemiBold", size: \1))/g' "$file"
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.medium))/.font(.custom("Poppins-Medium", size: \1))/g' "$file"
    sed -i '' 's/\.font(\.system(size: \([0-9]*\), weight: \.regular))/.font(.custom("Poppins-Regular", size: \1))/g' "$file"

    echo "✅ $file traité"
}

# Traiter tous les fichiers
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        replace_fonts "$file"
    else
        echo "⚠️  Fichier non trouvé: $file"
    fi
done

echo ""
echo "✨ Standardisation terminée!"
echo "📊 Total de fichiers traités: ${#files[@]}"
echo ""
echo "⚠️  ATTENTION: Vérifiez que les icônes SF Symbols conservent bien .font(.system(size:))"
echo "   Les emojis et icônes ne doivent PAS être changés!"
