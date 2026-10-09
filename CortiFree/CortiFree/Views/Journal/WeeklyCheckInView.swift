//
//  WeeklyCheckInView.swift
//  CortiFree
//
//  Weekly check-in drawer: the week's moods, this week's face check (saved with the progress
//  photos), this week's pulse and a talk with Milo about the week.
//

import SwiftUI

struct WeeklyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var faceStore = FaceScanStore.shared
    @ObservedObject private var pulseStore = WeeklyPulseStore.shared
    @State private var showFaceScan = false
    @State private var showPulse = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    private var week: Int { faceStore.currentSlot + 1 }
    private var faceRecord: FaceScanRecord? {
        faceStore.record(cycle: faceStore.planPosition.cycle, slot: faceStore.currentSlot)
    }
    private var pulseRecord: WeeklyPulseRecord? {
        pulseStore.record(cycle: faceStore.planPosition.cycle, slot: faceStore.currentSlot)
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.5)
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        moodStrip
                        faceStep
                        pulseStep
                        miloStep
                    }
                    .padding(20)
                    .padding(.top, 8)
                }
                Button {
                    WeeklyCheckInService.shared.markPrompted()
                    dismiss()
                } label: {
                    Text(t(faceRecord == nil || pulseRecord == nil ? "daily_checkin.skip" : "calm.common.done"))
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.glassSecondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            faceStore.reload()
            WeeklyCheckInService.shared.markPrompted()
            AnalyticsManager.shared.track(event: "weekly_checkin_shown", properties: ["week": week])
        }
        .fullScreenCover(isPresented: $showFaceScan) { FaceScanView() }
        .fullScreenCover(isPresented: $showPulse) { PulseCheckView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("weekly_checkin.eyebrow").uppercased())
                .font(.custom("Poppins-SemiBold", size: 11))
                .tracking(0.8)
                .foregroundColor(Color.appThemeSecondary)
            Text(String(format: t("weekly_checkin.title"), week))
                .font(.custom("Poppins-SemiBold", size: 24))
                .foregroundColor(.white)
            Text(t("weekly_checkin.subtitle"))
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Moods of the last 7 days

    private var moodStrip: some View {
        let moods = WidgetInsightsStore.load().moods
        let today = Calendar.current.startOfDay(for: Date())
        let days = (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
        return VStack(alignment: .leading, spacing: 10) {
            Text(t("weekly_checkin.moods"))
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(.white)
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 6) {
                        Text(moods[WidgetInsightsStore.dayKey(day)]?.emoji ?? "·")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(height: 28)
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.custom("Poppins-Medium", size: 10))
                            .foregroundColor(.white.opacity(Calendar.current.isDateInToday(day) ? 0.9 : 0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    // MARK: Steps

    private var faceStep: some View {
        Button {
            HapticManager.light()
            showFaceScan = true
        } label: {
            HStack(spacing: 14) {
                if let faceRecord, let image = faceStore.image(for: faceRecord) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    stepIcon("face.dashed")
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: t(faceRecord == nil ? "calm.face.card.due" : "calm.face.card.done"), week))
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                    Text(faceRecord.map { String(format: t("calm.face.card.last"), $0.result.restedScore) }
                         ?? t("weekly_checkin.face.subtitle"))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.62))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: faceRecord == nil ? "chevron.right" : "checkmark.circle.fill")
                    .font(.system(size: faceRecord == nil ? 13 : 20, weight: .bold))
                    .foregroundColor(faceRecord == nil ? Color.appThemeSecondary : Color(hex: "6FE3B4"))
            }
            .padding(14)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassCard(cornerRadius: 18, tint: faceRecord == nil ? Color.appTheme : nil, interactive: true)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var pulseStep: some View {
        let done = pulseRecord != nil
        return Button {
            HapticManager.light()
            showPulse = true
        } label: {
            HStack(spacing: 14) {
                stepIcon("heart.fill")
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: t(done ? "weekly_checkin.pulse.done" : "weekly_checkin.pulse.due"), week))
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                    Text(pulseRecord.map { String(format: t("weekly_checkin.pulse.last"), $0.bpm) }
                         ?? t("weekly_checkin.pulse.subtitle"))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.62))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: done ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: done ? 20 : 13, weight: .bold))
                    .foregroundColor(done ? Color(hex: "6FE3B4") : Color.appThemeSecondary)
            }
            .padding(14)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassCard(cornerRadius: 18, tint: done ? nil : Color.appTheme, interactive: true)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var miloStep: some View {
        Button {
            HapticManager.light()
            let position = faceStore.planPosition
            WeeklyCheckInService.shared.markPrompted()
            MiloWeeklyCheckIn.shared.start(planDay: position.day, cycle: position.cycle, source: "weekly_checkin")
            dismiss()
        } label: {
            HStack(spacing: 14) {
                stepIcon("bubble.left.and.text.bubble.right.fill")
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("weekly_checkin.milo.title"))
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                    Text(t("weekly_checkin.milo.subtitle"))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.62))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appThemeSecondary)
            }
            .padding(14)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassCard(cornerRadius: 18, interactive: true)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func stepIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(colors: [Color.appTheme, Color.appThemeSecondary],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
    }
}
