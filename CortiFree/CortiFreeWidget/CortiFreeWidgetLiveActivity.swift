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
    private let pink = Color(red: 0.95, green: 0.31, blue: 0.71)
    private let purple = Color(red: 0.72, green: 0.58, blue: 0.96)
    private let background = Color(red: 0.043, green: 0.004, blue: 0.106)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CortiFreeWidgetAttributes.self) { context in
            HStack(spacing: context.state.phase == .limitedOffer ? 18 : 14) {
                leadingVisual(
                    context.state,
                    size: context.state.phase == .limitedOffer ? 66 : 46
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(context.state.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(context.state.phase == .limitedOffer ? 2 : 1)
                    Text(context.state.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                    if context.state.phase == .onboardingProgress {
                        ProgressView(value: context.state.progress)
                            .tint(pink)
                    } else {
                        HStack(spacing: 10) {
                            countdown(until: context.state.offerEndsAt)
                                .font(.caption.bold())
                                .monospacedDigit()
                                .foregroundStyle(pink)

                            if let ctaTitle = context.state.ctaTitle,
                               let url = liveActivityURL(context.state) {
                                Link(destination: url) {
                                    Text(ctaTitle)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 14)
                                        .frame(height: 36)
                                        .background(
                                            LinearGradient(
                                                colors: [pink, purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            in: Capsule()
                                        )
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 8)
                if context.state.phase == .onboardingProgress {
                    trailingValue(context.state)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, context.state.phase == .limitedOffer ? 20 : 14)
            .frame(minHeight: context.state.phase == .limitedOffer ? 118 : nil)
            .activityBackgroundTint(background)
            .activitySystemActionForegroundColor(pink)
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
                                .tint(pink)
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
                                            colors: [pink, purple],
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
            .keylineTint(pink)
        }
    }

    @ViewBuilder
    private func leadingVisual(_ state: CortiFreeWidgetAttributes.ContentState, size: CGFloat) -> some View {
        if state.phase == .limitedOffer {
            Image("LiveGift")
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
                .foregroundStyle(pink)
        } else {
            Text("\(state.progressPercentage)%")
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(pink)
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
