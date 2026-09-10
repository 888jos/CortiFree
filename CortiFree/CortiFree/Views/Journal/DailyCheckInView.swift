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

    private let accent = Color(hex: "66D9C8")

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
                    .foregroundColor(.white.opacity(0.62))
                    .frame(height: 44)
            }
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
            eyebrow: "daily_checkin.eyebrow".localized,
            title: "daily_checkin.mood_title".localized,
            subtitle: "daily_checkin.mood_subtitle".localized,
            mascotMessage: "daily_checkin.mascot_mood".localized
        ) {
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
                        .background(
                            mood == value ? accent.opacity(0.22) : Color(hex: "17182E").opacity(0.86),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(mood == value ? accent : .white.opacity(0.08), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recoverySlide: some View {
        checkInSlide(
            eyebrow: "daily_checkin.eyebrow".localized,
            title: "daily_checkin.recovery_title".localized,
            subtitle: "daily_checkin.recovery_subtitle".localized,
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
            eyebrow: "daily_checkin.journal_eyebrow".localized,
            title: "daily_checkin.reflection_title".localized,
            subtitle: "daily_checkin.reflection_subtitle".localized,
            mascotMessage: "daily_checkin.mascot_reflection".localized
        ) {
            TextEditor(text: $note)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(height: 170)
                .background(Color(hex: "17182E").opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
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
        eyebrow: String,
        title: String,
        subtitle: String,
        mascotMessage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingMascotDialogueView(message: mascotMessage)
                    .frame(height: 122)
                    .clipped()

                VStack(alignment: .leading, spacing: 7) {
                    Text(eyebrow.uppercased())
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundColor(accent)
                    Text(title)
                        .font(.custom("Poppins-Bold", size: 25))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
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
                                value.wrappedValue == score ? accent : .white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
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
                    ProgressView().tint(Color(hex: "071B22"))
                } else {
                    Text(page == 2 ? "daily_checkin.save".localized : "common.continue".localized)
                        .font(.custom("Poppins-SemiBold", size: 14))
                }
            }
            .foregroundColor(Color(hex: "071B22"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(accent, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isSaving || (page == 0 && mood == nil))
        .opacity(page == 0 && mood == nil ? 0.45 : 1)
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
                MixpanelManager.shared.trackDailyCheckInCompleted(
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
