//
//  AddTaskView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Modal for adding custom tasks (simplified flow) - Updated with 9 categories
//

import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: CustomTaskCategory? = nil
    @State private var selectedActivity: String? = nil
    @State private var durationInMinutes: Int? = nil
    @State private var showDurationPicker = false
    @State private var showSuccessToast = false
    @State private var selectedTime = Date()
    @State private var showTimePicker = false

    // Task suggestions per category - UPDATED FOR 9 CATEGORIES
    let taskSuggestions: [CustomTaskCategory: [String]] = [
        .breathing: [
            "Respiration carrée (4-4-4-4)",
            "Cohérence cardiaque 5 min",
            "Respiration profonde 3 minutes",
            "Technique 4-7-8"
        ],
        .movement: [
            "Faire une promenade",
            "S'étirer 10 minutes",
            "Faire quelques squats légers",
            "Marcher dans la nature"
        ],
        .nutrition: [
            "Boire un verre d'eau",
            "Manger un fruit frais",
            "Préparer une tisane apaisante",
            "Éviter la caféine après 14h"
        ],
        .mental: [
            "Méditer 5 minutes",
            "Faire un scan corporel",
            "Visualiser un souvenir calme",
            "Écouter une méditation guidée"
        ],
        .environment: [
            "Aérer la pièce 5 minutes",
            "Ranger son espace de travail",
            "Allumer une bougie",
            "Créer un coin cosy"
        ],
        .creativity: [
            "Dessiner ou colorier",
            "Écrire dans un journal",
            "Écouter de la musique relaxante",
            "Faire une activité manuelle"
        ],
        .digital: [
            "Éteindre les écrans 1h avant le coucher",
            "Faire une pause sans écran",
            "Activer le mode Ne pas déranger",
            "Ranger son téléphone"
        ],
        .sleep: [
            "Lire avant de dormir",
            "Préparer la chambre (température, obscurité)",
            "Écrire dans un journal de gratitude",
            "Faire une routine du soir"
        ],
        .sensory: [
            "Écouter des sons de la nature",
            "Sentir une huile essentielle",
            "Toucher une texture apaisante",
            "Observer la nature par la fenêtre"
        ]
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"),
                    Color(hex: "0B011B"),
                    Color(hex: "01000C")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Form content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Section 1 - Category Grid (3x3)
                        categoryGridSection

                        // Section 2 - Activity Suggestions (only if category selected)
                        if selectedCategory != nil {
                            activitySuggestionsSection
                        }

                        // Section 3 - Time (required)
                        if selectedActivity != nil {
                            timeSection
                        }

                        // Section 4 - Duration (optional)
                        if selectedActivity != nil {
                            durationSection
                        }

                        // Section 5 - Add button
                        if selectedActivity != nil {
                            addButton
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }

            // Success toast
            if showSuccessToast {
                VStack {
                    Spacer()
                    successToast
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text("Nouvelle Tâche")
                .font(.custom("Poppins-SemiBold", size: 22))
                .foregroundColor(.white)

            Spacer()

            // Invisible spacer for centering
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Category Grid Section (3x3 for 9 categories)

    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catégorie")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.white)

            // 3x3 Grid for 9 categories
            VStack(spacing: 12) {
                // Row 1: Respiration, Mouvement, Nutrition
                HStack(spacing: 12) {
                    CategoryCard(
                        category: .breathing,
                        isSelected: selectedCategory == .breathing
                    ) {
                        selectCategory(.breathing)
                    }

                    CategoryCard(
                        category: .movement,
                        isSelected: selectedCategory == .movement
                    ) {
                        selectCategory(.movement)
                    }

                    CategoryCard(
                        category: .nutrition,
                        isSelected: selectedCategory == .nutrition
                    ) {
                        selectCategory(.nutrition)
                    }
                }

                // Row 2: Mental, Environnement, Créativité
                HStack(spacing: 12) {
                    CategoryCard(
                        category: .mental,
                        isSelected: selectedCategory == .mental
                    ) {
                        selectCategory(.mental)
                    }

                    CategoryCard(
                        category: .environment,
                        isSelected: selectedCategory == .environment
                    ) {
                        selectCategory(.environment)
                    }

                    CategoryCard(
                        category: .creativity,
                        isSelected: selectedCategory == .creativity
                    ) {
                        selectCategory(.creativity)
                    }
                }

                // Row 3: Digital, Sommeil, Sensoriel
                HStack(spacing: 12) {
                    CategoryCard(
                        category: .digital,
                        isSelected: selectedCategory == .digital
                    ) {
                        selectCategory(.digital)
                    }

                    CategoryCard(
                        category: .sleep,
                        isSelected: selectedCategory == .sleep
                    ) {
                        selectCategory(.sleep)
                    }

                    CategoryCard(
                        category: .sensory,
                        isSelected: selectedCategory == .sensory
                    ) {
                        selectCategory(.sensory)
                    }
                }
            }
        }
    }

    // MARK: - Activity Suggestions Section

    private var activitySuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activité suggérée")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.white)

            if let category = selectedCategory,
               let suggestions = taskSuggestions[category] {
                VStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        ActivitySuggestionButton(
                            activity: suggestion,
                            isSelected: selectedActivity == suggestion
                        ) {
                            HapticManager.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedActivity = suggestion
                            }
                        }
                    }
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Time Section (Required)

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Heure recommandée")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)

                Text("*")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(Color(hex: "FF4444"))
            }

            Button(action: {
                HapticManager.light()
                showTimePicker.toggle()
            }) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color.appThemeSecondary)

                    Text(timeString(from: selectedTime))
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2A2B5A"))
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Time picker
            if showTimePicker {
                DatePicker(
                    "Heure",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2A2B5A").opacity(0.5))
                )
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Durée (facultative)")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                // Duration display/button
                Button(action: {
                    HapticManager.light()
                    showDurationPicker.toggle()
                }) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color.appTheme)

                        if let duration = durationInMinutes {
                            Text("\(duration) min")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white)
                        } else {
                            Text("Ajouter une durée")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "2A2B5A"))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Clear button
                if durationInMinutes != nil {
                    Button(action: {
                        HapticManager.light()
                        withAnimation {
                            durationInMinutes = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            // Duration picker
            if showDurationPicker {
                Picker("Durée", selection: Binding(
                    get: { durationInMinutes ?? 10 },
                    set: { durationInMinutes = $0 }
                )) {
                    ForEach([5, 10, 15, 20, 25, 30, 45, 60], id: \.self) { duration in
                        Text("\(duration) min").tag(duration)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2A2B5A").opacity(0.5))
                )
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: addTask) {
            Text("Ajouter la tâche")
                .font(.custom("Poppins-Medium", size: 17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [
                            Color.appTheme,
                            Color.appThemeSecondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(
                    color: Color.appTheme.opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .disabled(selectedCategory == nil || selectedActivity == nil)
        .opacity((selectedCategory == nil || selectedActivity == nil) ? 0.5 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Success Toast

    private var successToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.appTheme)

            Text("Tâche ajoutée pour aujourd'hui ✅")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "2A2B5A"))
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func selectCategory(_ category: CustomTaskCategory) {
        HapticManager.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedCategory = category
            selectedActivity = nil // Reset activity when category changes
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func sfSymbolForCategory(_ category: CustomTaskCategory) -> String {
        return category.icon
    }

    private func addTask() {
        guard let category = selectedCategory,
              let activity = selectedActivity else { return }

        HapticManager.success()

        let newTask = TaskItem(
            title: activity,
            category: .morning, // Default category for custom tasks
            completed: false,
            taskFrequency: .once, // Always "today only"
            customCategory: category,
            durationInMinutes: durationInMinutes,
            isCustomTask: true,
            sfSymbol: sfSymbolForCategory(category),
            recommendedTime: timeString(from: selectedTime)
        )

        viewModel.addCustomTask(newTask)

        // Show success toast
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSuccessToast = true
        }

        // Hide toast and dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSuccessToast = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// MARK: - Category Card (Uses ICONS instead of emojis)

struct CategoryCard: View {
    let category: CustomTaskCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // USE ICON instead of emoji
                Image(systemName: category.icon)
                    .font(.custom("Poppins-Medium", size: 24))
                    .foregroundColor(.white)

                Text(category.displayName)
                    .font(.custom("Poppins-Medium", size: 11))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Color.appTheme,
                                Color.appThemeSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(hex: "2A2B5A")
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color.appTheme.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Suggestion Button

struct ActivitySuggestionButton: View {
    let activity: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.appTheme : .white.opacity(0.3))

                Text(activity)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2A2B5A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.appTheme : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    AddTaskView(viewModel: TasksViewModel())
}
