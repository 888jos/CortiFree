//
//  DailyTodosView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue simple de to-dos libre
//

import SwiftUI

struct DailyTodosView: View {
    @StateObject private var viewModel = DailyTodoViewModel()
    @State private var newTodoText = ""
    @FocusState private var isInputFocused: Bool
    @State private var timeUntilMidnight = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header avec stats
            headerSection

            // Message d'erreur
            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { viewModel.errorMessage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }

            // Liste des to-dos
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(viewModel.todos) { todo in
                        TodoRow(
                            todo: todo,
                            onToggle: {
                                Task {
                                    await viewModel.toggleCompletion(todo)
                                }
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteTodo(todo)
                                }
                            }
                        )
                    }

                    if viewModel.todos.isEmpty && viewModel.errorMessage == nil {
                        emptyStateView
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }

            // Input pour nouveau to-do
            newTodoInput
        }
        .task {
            await viewModel.loadTodos()
            updateTimeUntilMidnight()
        }
        .onReceive(timer) { _ in
            updateTimeUntilMidnight()
            checkForMidnightReset()
        }
    }

    // Calculer le temps jusqu'à minuit
    private func updateTimeUntilMidnight() {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)

        let components = calendar.dateComponents([.hour, .minute, .second], from: now, to: midnight)

        if let hours = components.hour, let minutes = components.minute, let seconds = components.second {
            timeUntilMidnight = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }

    // Vérifier si on doit réinitialiser (à minuit)
    private func checkForMidnightReset() {
        Task {
            await viewModel.checkAndResetDailyTodos()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Ma To-Do List")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)

            // Timer jusqu'à minuit
            HStack(spacing: 6) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                Text("Suppression dans \(timeUntilMidnight)")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )

            // Progress bar
            if !viewModel.todos.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progression")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Text("\(viewModel.completedCount)/\(viewModel.todos.count)")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(Color.appTheme)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appTheme, Color.appThemeSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.completionRate, height: 8)
                                .animation(.spring(response: 0.5), value: viewModel.completionRate)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))

            Text("Ta liste est vide")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white.opacity(0.5))

            Text("Ajoute des tâches ci-dessous")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var newTodoInput: some View {
        HStack(spacing: 12) {
            TextField("Nouvelle tâche...", text: $newTodoText, onCommit: addTodo)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "1A1B3A").opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isInputFocused ? Color.appTheme : Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .focused($isInputFocused)

            Button(action: addTodo) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 24))
                    .foregroundColor(newTodoText.isEmpty ? Color.white.opacity(0.3) : Color.appTheme)
            }
            .disabled(newTodoText.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color(hex: "1A1B3A").opacity(0.6))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func addTodo() {
        guard !newTodoText.isEmpty else { return }

        Task {
            await viewModel.createTodo(title: newTodoText)
            newTodoText = ""
            isInputFocused = false
        }
    }
}

// MARK: - Todo Row Component

struct TodoRow: View {
    let todo: DailyTodo
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                HapticManager.light()
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.appTheme, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if todo.isCompleted {
                        Circle()
                            .fill(Color.appTheme)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.custom("Poppins-Bold", size: 14))
                            .foregroundColor(.white)
                    }
                }
            }

            // Title
            Text(todo.title)
                .font(.custom("Poppins-Medium", size: 15))
                .foregroundColor(todo.isCompleted ? .white.opacity(0.5) : .white)
                .strikethrough(todo.isCompleted, color: .white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Delete button
            Button(action: { showDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "FF6B9D"))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1B3A").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .confirmationDialog("Supprimer cette tâche ?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
            Button("Annuler", role: .cancel) {}
        }
    }
}

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)
        DailyTodosView()
    }
}
