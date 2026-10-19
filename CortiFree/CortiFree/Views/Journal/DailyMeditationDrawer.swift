//
//  DailyMeditationDrawer.swift
//  CortiFree
//
//  First app open of each day, during the first week: that day's session of the 7-day
//  « First steps » course (see DailyMeditationService), in a drawer.
//

import SwiftUI

struct DailyMeditationDrawer: View {
    let day: Int
    /// The session started: the drawer chain stops there (no weekly drawer over the player).
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared

    private var session: GuidedSession? { DailyMeditationService.shared.session(forDay: day) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.5)

            if let session {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(String(format: "daily_meditation.eyebrow".localized, day + 1, DailyMeditationService.length).uppercased())
                            .font(.poppinsSemiBold(12))
                            .tracking(0.8)
                            .foregroundColor(Color(hex: "D4B4FF"))
                        Spacer()
                        Button {
                            AnalyticsManager.shared.track(event: "daily_meditation_dismissed", properties: ["day": day + 1])
                            dismiss()
                        } label: {
                            Text("daily_checkin.skip".localized)
                                .font(.poppinsMedium(12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Text("daily_meditation.title".localized)
                        .font(.poppinsBold(24))
                        .foregroundColor(.white)

                    progress

                    HStack(spacing: 14) {
                        LibraryImage(name: session.artwork.imageName ?? session.category.libraryImage)
                            .frame(width: 92, height: 92)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.localizedTitle)
                                .font(.poppinsSemiBold(17))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(session.localizedSubtitle)
                                .font(.poppinsRegular(13))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                            Label(session.durationLabel, systemImage: "clock")
                                .font(.poppinsMedium(12))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 22)

                    Spacer(minLength: 0)

                    Button {
                        HapticManager.medium()
                        AnalyticsManager.shared.track(event: "daily_meditation_started", properties: ["day": day + 1, "session_id": session.id])
                        onStart()
                        dismiss()
                        // Let the drawer close before the full player opens.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            GuidedSessionPlayer.shared.play(session, presentFullPlayer: true)
                        }
                    } label: {
                        Label("daily_meditation.start".localized, systemImage: "play.fill")
                            .font(.poppinsSemiBold(16))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.glassPrimary)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            AnalyticsManager.shared.track(event: "daily_meditation_viewed", properties: ["day": day + 1])
        }
    }

    /// Seven dots: done, today, to come.
    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(0..<DailyMeditationService.length, id: \.self) { index in
                let done = DailyMeditationService.shared.session(forDay: index)
                    .map { GuidedSessionProgressStore.isCompleted($0.id) } ?? false
                Capsule()
                    .fill(index == day ? Color(hex: "D4B4FF") : done ? Color(hex: "B794F6").opacity(0.7) : Color.white.opacity(0.15))
                    .frame(height: 6)
            }
        }
    }
}

extension View {
    /// The look shared by the drawers that open at the first app open of the day.
    /// Half screen; `expandable` lets it be pulled up to full screen.
    func dailyDrawerPresentation(expandable: Bool = false) -> some View {
        presentationDetents(expandable ? [.medium, .large] : [.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
    }
}
