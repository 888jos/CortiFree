import SwiftUI

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var page = 0
    @State private var mood: Mood?
    @State private var stress = 3
    @State private var sleep = 3
    @State private var energy = 3
    @State private var note = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let targetDate: Date

    // Keep the daily check-in aligned with CortiFree's existing violet theme.
    // This replaces the isolated turquoise accent previously used here.
    private let accent = Color.appTheme

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.5)
            VStack(spacing: 0) {
                topBar
                progressIndicator

                TabView(selection: $page) {
                    moodSlide.tag(0)
                    recoverySlide.tag(1)
                    reflectionSlide.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: page)

                primaryAction
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private var topBar: some View {
        HStack {
            Button {
                DailyCheckInService.shared.markPrompted()
                dismiss()
            } label: {
                Text("daily_checkin.skip".localized)
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 14)
                    .frame(height: 36)
            }
            .buttonStyle(.glassSecondary)
            .frame(height: 44)
            Spacer()
            Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(.white.opacity(0.62))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= page ? accent : .white.opacity(0.14))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
    }

    private var moodSlide: some View {
        checkInSlide(
            mascotMessage: "daily_checkin.mascot_mood".localized
        ) {
            GlassGroup(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(Mood.allCases, id: \.self) { value in
                    Button {
                        HapticManager.light()
                        mood = value
                    } label: {
                        VStack(spacing: 6) {
                            Text(value.emoji).font(.system(size: 30))
                            Text(value.displayName)
                                .font(.custom("Poppins-Medium", size: 10))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 82)
                        .glassCard(cornerRadius: 16, tint: mood == value ? accent : nil, interactive: true)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(mood == value ? accent : .clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            }
        }
    }

    private var recoverySlide: some View {
        checkInSlide(
            mascotMessage: "daily_checkin.mascot_recovery".localized
        ) {
            VStack(spacing: 22) {
                scaleRow(title: "daily_checkin.stress".localized, icon: "waveform.path.ecg", value: $stress, reversed: true)
                scaleRow(title: "daily_checkin.sleep".localized, icon: "moon.stars", value: $sleep)
                scaleRow(title: "daily_checkin.energy".localized, icon: "bolt", value: $energy)
            }
        }
    }

    private var reflectionSlide: some View {
        checkInSlide(
            mascotMessage: "daily_checkin.mascot_reflection".localized
        ) {
            TextEditor(text: $note)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(height: 170)
                .glassCard(cornerRadius: 18)
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("daily_checkin.reflection_prompt".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.38))
                            .padding(17)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func checkInSlide<Content: View>(
        mascotMessage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                OnboardingMascotDialogueView(message: mascotMessage)
                    .frame(height: 122)
                    .clipped()

                content()
                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(Color(hex: "FF8F7A"))
                }
            }
            .padding(20)
        }
    }

    private func scaleRow(title: String, icon: String, value: Binding<Int>, reversed: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(.white)
            GlassGroup(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        HapticManager.light()
                        value.wrappedValue = score
                    } label: {
                        Text("\(score)")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(value.wrappedValue == score ? Color(hex: "071B22") : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                value.wrappedValue == score ? accent : .clear,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .glassCard(cornerRadius: 12, interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            }
            HStack {
                Text(reversed ? "daily_checkin.high".localized : "daily_checkin.low".localized)
                Spacer()
                Text(reversed ? "daily_checkin.low".localized : "daily_checkin.high".localized)
            }
            .font(.custom("Poppins-Regular", size: 9))
            .foregroundColor(.white.opacity(0.42))
        }
    }

    private var primaryAction: some View {
        Button {
            if page < 2 {
                page += 1
            } else {
                save()
            }
        } label: {
            Group {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(page == 2 ? "daily_checkin.save".localized : "common.continue".localized)
                        .font(.custom("Poppins-SemiBold", size: 14))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.glassPrimary(tint: accent))
        .disabled(isSaving || (page == 0 && mood == nil))
    }

    private func save() {
        guard let mood else { return }
        isSaving = true
        errorMessage = nil
        DailyCheckInService.shared.markPrompted()

        Task {
            do {
                try await DailyCheckInService.shared.save(
                    mood: mood,
                    stress: stress,
                    sleep: sleep,
                    energy: energy,
                    note: note,
                    for: targetDate
                )
                AnalyticsManager.shared.trackDailyCheckInCompleted(
                    mood: mood.rawValue,
                    stress: stress,
                    sleep: sleep,
                    energy: energy,
                    hasNote: !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
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
