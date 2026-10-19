import SwiftUI

/// Daily check-in drawer (half screen): the recap of one day, today from 21:00, yesterday
/// before that (DailyCheckInService.pendingDay). One plain question per step, no mascot
/// dialogue; one tap answers and moves on.
/// Stress 1 = very calm … 5 = very stressed; sleep and energy 1 = bad … 5 = great.
struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var step = 0
    @State private var mood: Mood?
    @State private var stress: Int?
    @State private var sleep: Int?
    @State private var energy: Int?
    @State private var note = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var goingBack = false
    @State private var saved = false

    let targetDate: Date

    private let accent = Color.appTheme
    private let stepCount = 5

    private var isToday: Bool { Calendar.current.isDateInToday(targetDate) }
    /// « today » / « yesterday », for the questions and analytics.
    private var dayKind: String { isToday ? "today" : "yesterday" }
    private static let stepNames = ["mood", "stress", "sleep", "energy", "note"]

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.5)
            VStack(alignment: .leading, spacing: 0) {
                topBar
                progressIndicator
                    .padding(.top, 10)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(question)
                            .font(.poppinsSemiBold(20))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        content
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.poppinsRegular(12))
                                .foregroundColor(Color(hex: "FF8F7A"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingBack ? .leading : .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .interactiveDismissDisabled(isSaving)
        .onAppear {
            AnalyticsManager.shared.track(event: "daily_checkin_shown", properties: ["day": dayKind])
        }
        .onDisappear {
            // Swiped down or « Not now » before saving: Home keeps a card until it is done.
            guard !saved else { return }
            DailyCheckInService.shared.markPrompted(for: targetDate)
            AnalyticsManager.shared.track(event: "daily_checkin_skipped", properties: [
                "day": dayKind, "step": Self.stepNames[step], "step_index": step + 1
            ])
        }
    }

    // MARK: Header

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.light()
                goingBack = true
                step -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
            }
            .opacity(step > 0 ? 1 : 0)
            .disabled(step == 0)

            Spacer()
            Text((isToday ? "daily_checkin.day.today" : "daily_checkin.day.yesterday").localized)
                .font(.poppinsMedium(12))
                .foregroundColor(.white.opacity(0.6))
            Spacer()

            Button {
                dismiss()
            } label: {
                Text("daily_checkin.skip".localized)
                    .font(.poppinsMedium(12))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? accent : .white.opacity(0.14))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Steps

    private var question: String {
        "daily_checkin.q.\(Self.stepNames[step]).\(dayKind)".localized
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: moodGrid
        case 1: options("stress", emojis: ["😌", "🙂", "😐", "😣", "😫"], selection: stress) { stress = $0 }
        case 2: options("sleep", emojis: ["😩", "😕", "😐", "🙂", "😴"], selection: sleep) { sleep = $0 }
        case 3: options("energy", emojis: ["🪫", "😮‍💨", "😐", "💪", "⚡️"], selection: energy) { energy = $0 }
        default: noteStep
        }
    }

    private var moodGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(Mood.allCases, id: \.self) { value in
                Button {
                    mood = value
                    next()
                } label: {
                    VStack(spacing: 6) {
                        Text(value.emoji).font(.system(size: 32))
                        Text(value.displayName)
                            .font(.poppinsMedium(12))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .glassCard(cornerRadius: 18, tint: mood == value ? accent : nil, interactive: true)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(mood == value ? accent : .clear, lineWidth: 1.5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Five plain answers, 1…5, top to bottom.
    private func options(_ key: String, emojis: [String], selection: Int?, choose: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 8) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    choose(value)
                    next()
                } label: {
                    HStack(spacing: 12) {
                        Text(emojis[value - 1]).font(.system(size: 22))
                        Text("daily_checkin.\(key).\(value)".localized)
                            .font(.poppinsMedium(16))
                            .foregroundColor(.white)
                        Spacer()
                        if selection == value {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .glassCard(cornerRadius: 23, tint: selection == value ? accent : nil, interactive: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var noteStep: some View {
        VStack(spacing: 16) {
            TextEditor(text: $note)
                .font(.poppinsRegular(15))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(height: 120)
                .glassCard(cornerRadius: 18)
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("daily_checkin.note_placeholder".localized)
                            .font(.poppinsRegular(15))
                            .foregroundColor(.white.opacity(0.38))
                            .padding(17)
                            .allowsHitTesting(false)
                    }
                }

            Button(action: save) {
                Group {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("daily_checkin.save".localized)
                            .font(.poppinsSemiBold(15))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.glassPrimary(tint: accent))
            .disabled(isSaving)
        }
    }

    // MARK: Actions

    private func next() {
        HapticManager.light()
        goingBack = false
        // A short beat so the tapped answer shows as selected.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            if step < stepCount - 1 { step += 1 }
        }
    }

    private func save() {
        guard let mood, let stress, let sleep, let energy else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await DailyCheckInService.shared.save(
                    mood: mood, stress: stress, sleep: sleep, energy: energy, note: note, for: targetDate
                )
                AnalyticsManager.shared.trackDailyCheckInCompleted(
                    mood: mood.rawValue, stress: stress, sleep: sleep, energy: energy,
                    hasNote: !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    day: dayKind
                )
                saved = true
                HapticManager.success()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
                HapticManager.error()
            }
        }
    }
}
