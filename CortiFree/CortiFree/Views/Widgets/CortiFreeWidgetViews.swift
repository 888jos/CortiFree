//
//  CortiFreeWidgetViews.swift
//  CortiFree
//
//  Vues des 6 widgets (Milo, Respire, Cortisol, Humeur, Message de Milo, Streak).
//  Fichier membre des deux targets : le widget les affiche, et la galerie des Réglages
//  les réutilise comme aperçus (avec `interactive: false`).
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Catalogue

enum CortiFreeWidgetKind: String, CaseIterable, Identifiable {
    case milo, breathe, cortisol, mood, message, streak

    var id: String { rawValue }
    var kind: String { "CortiFree.\(rawValue)" }
    var displayName: String { WidgetL10n.string("widget.v.\(rawValue).name") }
    var summary: String { WidgetL10n.string("widget.v.\(rawValue).desc") }

    var families: [WidgetFamily] {
        switch self {
        case .milo: return [.systemSmall, .systemMedium]
        case .breathe: return [.systemSmall, .systemMedium]
        case .cortisol: return [.systemSmall, .systemMedium, .accessoryCircular]
        case .mood: return [.systemMedium, .systemLarge]
        case .message: return [.systemMedium, .accessoryRectangular]
        case .streak: return [.systemSmall, .accessoryCircular, .accessoryInline]
        }
    }

    var deepLink: URL? {
        switch self {
        case .milo, .message: return URL(string: "cortifree://milo")
        case .mood, .cortisol: return URL(string: "cortifree://progress")
        case .breathe: return URL(string: "cortifree://home")
        case .streak: return URL(string: "cortifree://tasks")
        }
    }
}

// MARK: - Design

enum CFW {
    static let purple = Color(red: 0.718, green: 0.580, blue: 0.965)   // #B794F6
    static let purple2 = Color(red: 0.529, green: 0.263, blue: 0.918)  // #8744EB
    static let green = Color(red: 0.35, green: 0.82, blue: 0.45)
    static let orange = Color(red: 1.0, green: 0.60, blue: 0.10)
    static let red = Color(red: 0.94, green: 0.30, blue: 0.33)
    static let muted = Color.white.opacity(0.55)
    static let faint = Color.white.opacity(0.12)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }

    static func tierColor(_ tier: Int) -> Color {
        [green, Color(red: 0.55, green: 0.80, blue: 1.0), orange, red][min(max(tier, 0), 3)]
    }

    static func progressColor(_ value: Double) -> Color {
        switch value {
        case ..<0.01: return faint
        case ..<0.5: return orange.opacity(0.85)
        case ..<0.99: return purple
        default: return green
        }
    }
}

/// Fond galaxie commun (même ambiance que le widget tâches).
struct CFWidgetBackground: View {
    private static let stars: [(x: Double, y: Double, r: Double, a: Double)] = {
        var result: [(Double, Double, Double, Double)] = []
        var rng: UInt64 = 0x51EE_7A11
        func next() -> Double {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            return Double(rng >> 33) / Double(UInt32.max)
        }
        for _ in 0..<40 { result.append((next(), next(), next() * 1.5 + 0.4, next() * 0.5 + 0.2)) }
        return result
    }()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.122, green: 0.004, blue: 0.251),
                                    Color(red: 0.043, green: 0.004, blue: 0.106),
                                    Color(red: 0.004, green: 0, blue: 0.047)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [CFW.purple2.opacity(0.35), .clear],
                           center: UnitPoint(x: 0.8, y: 0.15), startRadius: 0, endRadius: 220)
            Canvas { ctx, size in
                for star in Self.stars {
                    let rect = CGRect(x: star.x * size.width, y: star.y * size.height, width: star.r, height: star.r)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(star.a)))
                }
            }
        }
    }
}

/// Bouton d'intent dans le widget, simple contenu dans la galerie de l'app.
private struct IntentButton<Intent: AppIntent, Label: View>: View {
    let intent: Intent
    let interactive: Bool
    @ViewBuilder let label: () -> Label

    var body: some View {
        if interactive {
            Button(intent: intent, label: label).buttonStyle(.plain)
        } else {
            label()
        }
    }
}

private struct MiloAvatar: View {
    let state: MiloState
    let size: CGFloat

    var body: some View {
        Image("cortifree_assistant_avatar")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .saturation(state == .tired || state == .sleeping ? 0.45 : 1)
            .rotationEffect(.degrees(state == .sleeping ? -12 : state == .stressed ? 6 : 0))
            .overlay(alignment: .topTrailing) {
                Image(systemName: state.overlaySymbol)
                    .font(.system(size: size * 0.24, weight: .bold))
                    .foregroundStyle(state == .stressed ? CFW.red : state == .proud ? .yellow : .white)
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .offset(x: size * 0.06, y: -size * 0.06)
            }
    }
}

// MARK: - 1. Milo compagnon

struct MiloWidgetView: View {
    let insights: WidgetInsights
    let family: WidgetFamily

    private var state: MiloState { insights.miloState }
    private var status: String { WidgetL10n.string("widget.milo.status.\(state.rawValue)") }

    var body: some View {
        if family == .systemSmall {
            VStack(spacing: 6) {
                MiloAvatar(state: state, size: 74)
                Text(status)
                    .font(CFW.font(12, .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 14) {
                MiloAvatar(state: state, size: 96)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Milo")
                        .font(CFW.font(11, .bold))
                        .foregroundStyle(CFW.purple)
                        .kerning(1.2)
                    Text(status)
                        .font(CFW.font(16, .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(WidgetL10n.string(insights.miloQuoteKey))
                        .font(CFW.font(12))
                        .foregroundStyle(CFW.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    ProgressBar(value: insights.todayProgress)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(CFW.faint)
                Capsule()
                    .fill(LinearGradient(colors: [CFW.purple, CFW.purple2], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(4, geo.size.width * value))
            }
        }
        .frame(height: 4)
    }
}

// MARK: - 2. Respire en 1 tap

struct BreatheWidgetView: View {
    let insights: WidgetInsights
    let family: WidgetFamily
    let breathStart: Date?
    var interactive = true

    private enum Phase: Int { case inhale, holdFull, exhale, holdEmpty }

    private var elapsed: TimeInterval? {
        guard let breathStart else { return nil }
        let value = insights.date.timeIntervalSince(breathStart)
        return (0..<WidgetInsightsStore.breathSessionSeconds).contains(value) ? value : nil
    }

    private var phase: Phase? {
        guard let elapsed else { return nil }
        return Phase(rawValue: Int(elapsed / WidgetInsightsStore.breathPhaseSeconds) % 4)
    }

    private var phaseLabel: String {
        switch phase {
        case .inhale: return WidgetL10n.string("widget.breathe.inhale")
        case .holdFull, .holdEmpty: return WidgetL10n.string("widget.breathe.hold")
        case .exhale: return WidgetL10n.string("widget.breathe.exhale")
        case nil: return WidgetL10n.string("widget.breathe.title")
        }
    }

    /// Taille cible de la phase en cours (WidgetKit anime le passage d'une entrée à l'autre).
    private var circleScale: CGFloat {
        switch phase {
        case .inhale, .holdFull: return 1
        case .exhale, .holdEmpty, nil: return 0.62
        }
    }

    var body: some View {
        let compact = family == .systemSmall
        let circle = compact ? 92.0 : 104.0
        HStack(spacing: 16) {
            IntentButton(intent: StartBreathingIntent(), interactive: interactive && phase == nil) {
                ZStack {
                    Circle().fill(CFW.purple.opacity(0.12))
                    Circle()
                        .fill(RadialGradient(colors: [CFW.purple, CFW.purple2.opacity(0.7)],
                                             center: .center, startRadius: 0, endRadius: circle / 2))
                        .scaleEffect(circleScale)
                        .shadow(color: CFW.purple.opacity(0.6), radius: 12)
                        .animation(.easeInOut(duration: 2), value: circleScale)
                    VStack(spacing: 2) {
                        Text(phaseLabel)
                            .font(CFW.font(compact ? 14 : 15, .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.opacity)
                        if phase == nil {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        } else if let breathStart {
                            Text(timerInterval: breathStart...breathStart.addingTimeInterval(WidgetInsightsStore.breathSessionSeconds),
                                 countsDown: true)
                                .font(CFW.font(11, .medium).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .frame(width: 44)
                        }
                    }
                }
                .frame(width: circle, height: circle)
            }
            .frame(maxWidth: compact ? .infinity : nil)

            if !compact {
                VStack(alignment: .leading, spacing: 6) {
                    Text(WidgetL10n.string("widget.breathe.title"))
                        .font(CFW.font(11, .bold))
                        .foregroundStyle(CFW.purple)
                        .kerning(1.2)
                    Text(WidgetL10n.string(phase == nil ? "widget.breathe.cta" : "widget.breathe.follow"))
                        .font(CFW.font(16, .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(WidgetL10n.format("widget.breathe.today", insights.breathsToday))
                        .font(CFW.font(12))
                        .foregroundStyle(CFW.muted)
                    if phase != nil {
                        IntentButton(intent: StopBreathingIntent(), interactive: interactive) {
                            Text(WidgetL10n.string("widget.breathe.stop"))
                                .font(CFW.font(12, .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(CFW.faint))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 4. Jauge de cortisol

struct CortisolWidgetView: View {
    let insights: WidgetInsights
    let family: WidgetFamily

    private var level: Int { insights.cortisolLevel }
    private var tier: Int { insights.cortisolTier }
    private var tint: Color { CFW.tierColor(tier) }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(level), in: 0...100) {
                Text("CORT")
            } currentValueLabel: {
                Text("\(level)")
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                header
                Spacer(minLength: 0)
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(level)").font(CFW.font(44, .heavy)).foregroundStyle(.white)
                    Text("%").font(CFW.font(20, .bold)).foregroundStyle(CFW.muted)
                }
                Text(WidgetL10n.string("widget.cortisol.tier.\(tier)"))
                    .font(CFW.font(13, .bold))
                    .foregroundStyle(tint)
                battery
            }
        default:
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    header
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text("\(level)").font(CFW.font(48, .heavy)).foregroundStyle(.white)
                        Text("%").font(CFW.font(22, .bold)).foregroundStyle(CFW.muted)
                    }
                    battery
                }
                .frame(width: 130)
                VStack(alignment: .leading, spacing: 6) {
                    Text(WidgetL10n.string("widget.cortisol.tier.\(tier)"))
                        .font(CFW.font(16, .bold))
                        .foregroundStyle(tint)
                    Text(WidgetL10n.string("widget.cortisol.hint.\(tier)"))
                        .font(CFW.font(12))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text(WidgetL10n.string("widget.cortisol.disclaimer"))
                        .font(CFW.font(9))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg").font(.system(size: 11, weight: .bold))
            Text(WidgetL10n.string("widget.cortisol.title").uppercased())
                .font(CFW.font(11, .bold))
                .kerning(1.2)
        }
        .foregroundStyle(CFW.purple)
    }

    /// Jauge façon batterie, 10 segments.
    private var battery: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int((Double(level) / 10).rounded(.up)) ? tint : CFW.faint)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - 5. Humeur en 1 tap

struct MoodWidgetView: View {
    let insights: WidgetInsights
    let family: WidgetFamily
    var interactive = true

    private var languageCode: String {
        WidgetDataStore.sharedDefaults?.string(forKey: WidgetInsightsStore.languageKey)
            ?? UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.current.identifier
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 12 : 8) {
            Text(WidgetL10n.string("widget.mood.title"))
                .font(CFW.font(14, .bold))
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                ForEach(WidgetMood.allCases, id: \.self) { mood in
                    IntentButton(intent: LogMoodIntent(mood: mood), interactive: interactive) {
                        let selected = insights.todayMood == mood
                        Text(mood.emoji)
                            .font(.system(size: family == .systemLarge ? 26 : 22))
                            .frame(maxWidth: .infinity, minHeight: family == .systemLarge ? 42 : 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selected ? CFW.color(mood.hex).opacity(0.45) : Color.white.opacity(0.07))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected ? CFW.color(mood.hex) : .clear, lineWidth: 1.5)
                            )
                    }
                }
            }

            if family == .systemLarge {
                monthGrid
            } else {
                lastDays
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func cell(_ date: Date, size: CGFloat) -> some View {
        let mood = insights.moods[WidgetInsightsStore.dayKey(date)]
        let isToday = Calendar.current.isDate(date, inSameDayAs: insights.date)
        return RoundedRectangle(cornerRadius: size * 0.28)
            .fill(mood.map { CFW.color($0.hex) } ?? CFW.faint)
            .overlay(RoundedRectangle(cornerRadius: size * 0.28).stroke(.white.opacity(isToday ? 0.9 : 0), lineWidth: 1.5))
            .frame(height: size)
    }

    private var lastDays: some View {
        let cal = Calendar.current
        let days = (0..<14).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: insights.date) }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                ForEach(days, id: \.self) { cell($0, size: 12) }
            }
            Text(WidgetL10n.string("widget.mood.recent"))
                .font(CFW.font(10))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var monthGrid: some View {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .month, for: insights.date)
        let start = interval?.start ?? insights.date
        let count = cal.range(of: .day, in: .month, for: insights.date)?.count ?? 30
        let leading = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
        let days: [Date?] = Array(repeating: nil, count: leading)
            + (0..<count).map { cal.date(byAdding: .day, value: $0, to: start) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateFormat = "LLLL yyyy"

        return VStack(alignment: .leading, spacing: 8) {
            Text(formatter.string(from: insights.date).capitalized)
                .font(CFW.font(12, .semibold))
                .foregroundStyle(CFW.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        cell(day, size: 28)
                    } else {
                        Color.clear.frame(height: 28)
                    }
                }
            }
        }
    }
}

// MARK: - 6. Le mot de Milo

struct MiloMessageWidgetView: View {
    let insights: WidgetInsights
    let family: WidgetFamily

    private var quote: String { WidgetL10n.string(insights.miloQuoteKey) }

    var body: some View {
        if family == .accessoryRectangular {
            VStack(alignment: .leading, spacing: 1) {
                Text("Milo").font(CFW.font(12, .bold)).widgetAccentable()
                Text(quote)
                    .font(CFW.font(12))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image("cortifree_assistant_avatar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                    Text(WidgetL10n.string("widget.message.title").uppercased())
                        .font(CFW.font(11, .bold))
                        .foregroundStyle(CFW.purple)
                        .kerning(1.2)
                    Spacer()
                    Image(systemName: "quote.closing")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(CFW.purple.opacity(0.5))
                }
                Spacer(minLength: 0)
                Text(quote)
                    .font(CFW.font(19, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - 7. Streak

struct StreakWidgetView: View {
    let insights: WidgetInsights
    let family: WidgetFamily

    private var streak: Int { insights.streak }

    private var flameColors: [Color] {
        switch streak {
        case 100...: return [Color(red: 0.4, green: 0.8, blue: 1), CFW.purple2]
        case 30...: return [CFW.purple, CFW.purple2]
        case 7...: return [.yellow, CFW.red]
        default: return [.yellow, CFW.orange]
        }
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(WidgetL10n.format(streak == 1 ? "widget.streak.inline.one" : "widget.streak.inline", streak), systemImage: "flame.fill")
        case .accessoryCircular:
            let previous = WidgetInsights.milestones.last { $0 <= streak } ?? 0
            let next = insights.nextMilestone
            Gauge(value: Double(streak - previous), in: 0...Double(max(1, next - previous))) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text("\(streak)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        default:
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: flameColors, startPoint: .top, endPoint: .bottom))
                    .shadow(color: flameColors.last!.opacity(0.6), radius: 10)
                Text("\(streak)")
                    .font(CFW.font(36, .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(WidgetL10n.string(streak == 0 ? "widget.streak.zero" : streak == 1 ? "widget.streak.days.one" : "widget.streak.days"))
                    .font(CFW.font(12, .semibold))
                    .foregroundStyle(CFW.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if streak > 0 {
                    Text(WidgetL10n.format("widget.streak.next", insights.nextMilestone))
                        .font(CFW.font(10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Routage par type (widget + galerie)

struct CortiFreeKindView: View {
    let kind: CortiFreeWidgetKind
    let insights: WidgetInsights
    let family: WidgetFamily
    var breathStart: Date?
    var interactive = true

    var body: some View {
        switch kind {
        case .milo: MiloWidgetView(insights: insights, family: family)
        case .breathe: BreatheWidgetView(insights: insights, family: family, breathStart: breathStart, interactive: interactive)
        case .cortisol: CortisolWidgetView(insights: insights, family: family)
        case .mood: MoodWidgetView(insights: insights, family: family, interactive: interactive)
        case .message: MiloMessageWidgetView(insights: insights, family: family)
        case .streak: StreakWidgetView(insights: insights, family: family)
        }
    }
}

extension WidgetFamily {
    var isAccessory: Bool {
        self == .accessoryCircular || self == .accessoryRectangular || self == .accessoryInline
    }

    /// Taille de référence (iPhone 6,1") pour les aperçus de la galerie.
    var previewSize: CGSize {
        switch self {
        case .systemSmall: return CGSize(width: 158, height: 158)
        case .systemMedium: return CGSize(width: 338, height: 158)
        case .systemLarge: return CGSize(width: 338, height: 354)
        case .accessoryCircular: return CGSize(width: 72, height: 72)
        case .accessoryRectangular: return CGSize(width: 172, height: 76)
        case .accessoryInline: return CGSize(width: 240, height: 26)
        default: return CGSize(width: 158, height: 158)
        }
    }
}
