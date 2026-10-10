//
//  CortiFreeWidgetLiveActivity.swift
//  CortiFreeWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

struct CortiFreeWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            case onboardingProgress
            case limitedOffer
        }

        var phase: Phase
        var currentStep: Int
        var totalSteps: Int
        var title: String
        var subtitle: String
        var offerEndsAt: Date?
        var imageName: String
        var deepLinkPath: String
        var ctaTitle: String?
    }

    var name: String
}

struct CortiFreeWidgetLiveActivity: Widget {
    private let accent = Color(red: 0.718, green: 0.580, blue: 0.965) // #B794F6
    private let accentDeep = Color(red: 0.529, green: 0.263, blue: 0.918) // #8744EB
    private let background = Color(red: 0.043, green: 0.004, blue: 0.106)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CortiFreeWidgetAttributes.self) { context in
            Group {
                if context.state.phase == .limitedOffer {
                    offerLockScreen(context.state)
                } else {
                    progressLockScreen(context.state)
                }
            }
            .activityBackgroundTint(background)
            .activitySystemActionForegroundColor(accent)
            .widgetURL(liveActivityURL(context.state))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    leadingVisual(context.state, size: context.state.phase == .limitedOffer ? 38 : 30)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    trailingValue(context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if context.state.phase == .onboardingProgress {
                            ProgressView(value: context.state.progress)
                                .tint(accent)
                        } else if let ctaTitle = context.state.ctaTitle,
                                  let url = liveActivityURL(context.state) {
                            Link(destination: url) {
                                Label(ctaTitle, systemImage: "arrow.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(
                                        LinearGradient(
                                            colors: [accentDeep, accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                }
            } compactLeading: {
                leadingVisual(context.state, size: 20)
            } compactTrailing: {
                if context.state.phase == .limitedOffer {
                    countdown(until: context.state.offerEndsAt)
                        .font(.caption2.bold())
                        .monospacedDigit()
                } else {
                    Text("\(Int((context.state.progress * 100).rounded()))%")
                        .font(.caption2.bold())
                        .monospacedDigit()
                }
            } minimal: {
                leadingVisual(context.state, size: 18)
            }
            .widgetURL(liveActivityURL(context.state))
            .keylineTint(accent)
        }
    }

    /// Gift offer: Milo and the full headline on top (two lines, never cut), then the countdown
    /// and the button on their own row so long languages (German, Spanish) still fit.
    private func offerLockScreen(_ state: CortiFreeWidgetAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                leadingVisual(state, size: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(state.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Label {
                    countdown(until: state.offerEndsAt)
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "timer")
                }
                .font(.subheadline.bold())
                .foregroundStyle(accent)
                Spacer(minLength: 8)
                if let ctaTitle = state.ctaTitle, let url = liveActivityURL(state) {
                    Link(destination: url) {
                        Text(ctaTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            // Full width for the button text: the countdown gives way, never the CTA.
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 18)
                            .frame(height: 34)
                            .background(
                                LinearGradient(colors: [accentDeep, accent], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func progressLockScreen(_ state: CortiFreeWidgetAttributes.ContentState) -> some View {
        HStack(spacing: 14) {
            leadingVisual(state, size: 46)
            VStack(alignment: .leading, spacing: 6) {
                Text(state.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
                ProgressView(value: state.progress)
                    .tint(accent)
            }
            Spacer(minLength: 8)
            trailingValue(state)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func leadingVisual(_ state: CortiFreeWidgetAttributes.ContentState, size: CGFloat) -> some View {
        if state.phase == .limitedOffer {
            Image(state.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(state.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        }
    }

    private func liveActivityURL(_ state: CortiFreeWidgetAttributes.ContentState) -> URL? {
        URL(string: "cortifree://\(state.deepLinkPath)")
    }

    @ViewBuilder
    private func trailingValue(_ state: CortiFreeWidgetAttributes.ContentState) -> some View {
        if state.phase == .limitedOffer {
            countdown(until: state.offerEndsAt)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(accent)
        } else {
            Text("\(state.progressPercentage)%")
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(accent)
        }
    }

    @ViewBuilder
    private func countdown(until endDate: Date?) -> some View {
        if let endDate, endDate > Date() {
            Text(timerInterval: Date()...endDate, countsDown: true)
        } else {
            Text("00:00")
        }
    }
}

extension CortiFreeWidgetAttributes.ContentState {
    var progress: Double {
        guard totalSteps > 1 else { return 1 }
        return min(max(Double(currentStep - 1) / Double(totalSteps - 1), 0), 1)
    }

    var progressPercentage: Int {
        Int((progress * 100).rounded())
    }

    var remainingSteps: Int {
        max(totalSteps - currentStep, 0)
    }
}
