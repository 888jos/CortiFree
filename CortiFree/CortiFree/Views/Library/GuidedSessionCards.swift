//
//  GuidedSessionCards.swift
//  CortiFree
//
//  Reusable cards for guided audio sessions (library, lists).
//

import SwiftUI

// MARK: - Featured (large) card

struct FeaturedSessionCard: View {
    let session: GuidedSession
    var width: CGFloat = 280
    let action: () -> Void
    @ObservedObject private var player = GuidedSessionPlayer.shared

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            ZStack(alignment: .bottomLeading) {
                SessionArtworkView(session: session, cornerRadius: 26)

                LinearGradient(colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                               startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(session.category.title.localized.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(session.localizedTitle)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Label(session.durationLabel, systemImage: "clock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        playBadge
                    }
                }
                .padding(18)
            }
            .frame(width: width, height: width * 1.1)
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: (session.artwork.colors.first ?? .black).opacity(0.35), radius: 16, y: 10)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("\(session.localizedTitle), \(session.durationLabel)")
    }

    private var playBadge: some View {
        let current = player.currentSession?.id == session.id
        return ZStack {
            if current && player.isPlaying {
                EqualizerBars(isAnimating: true, color: AudioPalette.backgroundDeep)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .offset(x: 1)
            }
        }
        .frame(width: 42, height: 42)
        .background(Circle().fill(.white))
    }
}

// MARK: - Grid tile

struct SessionTile: View {
    let session: GuidedSession
    let action: () -> Void
    @ObservedObject private var player = GuidedSessionPlayer.shared

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                SessionArtworkView(session: session, cornerRadius: 18)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .topTrailing) {
                        if GuidedSessionProgressStore.isCompleted(session.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, AudioPalette.accent)
                                .padding(8)
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 6) {
                            if player.currentSession?.id == session.id && player.isPlaying {
                                EqualizerBars(isAnimating: true, color: .white)
                            }
                            Text(session.durationLabel)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .padding(8)
                    }

                Text(session.localizedTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(session.category.title.localized)
                    .font(.system(size: 12))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("\(session.localizedTitle), \(session.durationLabel)")
    }
}

// MARK: - Filter chip

struct LibraryFilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AudioPalette.backgroundDeep : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if isSelected { Capsule().fill(Color.white) }
            }
            .modifier(ChipGlass(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ChipGlass: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        if isSelected {
            content
        } else {
            content.cfGlassCapsule()
        }
    }
}

// MARK: - Section header

struct LibrarySectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .lineLimit(2)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button {
                    HapticManager.light()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AudioPalette.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
