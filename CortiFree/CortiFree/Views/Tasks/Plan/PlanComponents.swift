//
//  PlanComponents.swift
//  CortiFree
//
//  Building blocks of the Plan tab: Liquid Glass surfaces (iOS 26, material fallback),
//  header, progress, item cards, short-version toggle, completion card.
//

import SwiftUI

// MARK: - Palette

/// Single colour system for the Plan tab: one brand accent (shared with the Library
/// and the player), neutral surfaces, and a "done" green used for completion only.
enum PlanPalette {
    static let accent = AudioPalette.accent
    static let accentDeep = Color(hex: "7B5CFF")
    static let deep = Color(hex: "0A0515")
    static let plum = Color(hex: "1A0A2E")
    static let done = Color(hex: "8FE3C3")
    static let secondaryText = Color.white.opacity(0.62)
    static let tertiaryText = Color.white.opacity(0.42)
    static let thumbnail = Color.white.opacity(0.08)
    static var itemGradient: [Color] { [accentDeep, accent] }
}

// MARK: - Glass

extension View {
    /// Liquid Glass surface on iOS 26, ultra-thin material on earlier systems.
    @ViewBuilder
    func planGlass(cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0.opacity(0.18)) } ?? Glass.regular
            self.glassEffect(interactive ? base.interactive() : base, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(.ultraThinMaterial)
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(tint.opacity(0.10))
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(LinearGradient(colors: [.white.opacity(0.20), .white.opacity(0.04)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    func planGlassCapsule(tint: Color? = nil, interactive: Bool = true) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = tint.map { Glass.regular.tint($0) } ?? Glass.regular
            self.glassEffect(interactive ? base.interactive() : base, in: .capsule)
        } else {
            self
                .background { ZStack { Capsule().fill(.ultraThinMaterial); if let tint { Capsule().fill(tint) } } }
                .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        }
    }

    @ViewBuilder
    func planGlassButtonStyle(prominent: Bool, tint: Color = PlanPalette.accent) -> some View {
        if #available(iOS 26, *) {
            if prominent { self.buttonStyle(.glassProminent).tint(tint) } else { self.buttonStyle(.glass) }
        } else {
            self.buttonStyle(PlanFallbackButtonStyle(prominent: prominent, tint: tint))
        }
    }
}

struct PlanFallbackButtonStyle: ButtonStyle {
    let prominent: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background {
                if prominent {
                    Capsule().fill(LinearGradient(colors: [tint, tint.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay(Capsule().strokeBorder(.white.opacity(prominent ? 0.25 : 0.14), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PlanGlassGroup<Content: View>: View {
    var spacing: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

// MARK: - Background

struct PlanBackground: View {
    let goal: PlanGoal?

    var body: some View {
        ZStack {
            LinearGradient(colors: [PlanPalette.deep, PlanPalette.plum, PlanPalette.deep],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [PlanPalette.accent.opacity(0.24), .clear],
                           center: .init(x: 0.85, y: 0.02), startRadius: 10, endRadius: 420)
            RadialGradient(colors: [PlanPalette.accentDeep.opacity(0.18), .clear],
                           center: .init(x: 0.05, y: 0.35), startRadius: 10, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Icon button

struct PlanIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .planGlassCapsule()
        .accessibilityLabel(label)
    }
}

// MARK: - Progress

struct PlanProgressCard: View {
    let plan: PersonalPlan
    let displayedDay: Int
    let todayIndex: Int
    let completedDays: Set<Int>
    let onSelectDay: (Int) -> Void

    private var week: Int { (displayedDay - 1) / 7 + 1 }
    private var progress: Double { min(1, Double(min(todayIndex, PersonalPlan.length)) / Double(PersonalPlan.length)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "plan.header.day_of".localized, min(displayedDay, PersonalPlan.length)))
                    .font(.faroBold(28))
                    .foregroundStyle(.white)
                Spacer()
                if plan.cycle > 1 {
                    Text(String(format: "plan.cycle".localized, plan.cycle) + " · " + plan.cycleTheme.localizedTitle)
                        .font(Font.Poppins.custom(.medium, size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .planGlassCapsule(interactive: false)
                }
            }

            // 4 week segments
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { w in
                    GeometryReader { geo in
                        let fill = segmentFill(week: w)
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.10))
                            Capsule()
                                .fill(LinearGradient(colors: PlanPalette.itemGradient, startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * fill)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(String(format: "plan.header.day_of".localized, min(todayIndex, PersonalPlan.length)))
            .accessibilityValue("\(Int((progress * 100).rounded()))%")

            // Week strip
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let isFuture = day > todayIndex
                    Button {
                        guard !isFuture else { return }
                        HapticManager.light()
                        onSelectDay(day)
                    } label: {
                        VStack(spacing: 5) {
                            Text("\(day)")
                                .font(Font.Poppins.custom(day == displayedDay ? .semiBold : .regular, size: 13))
                                .foregroundStyle(isFuture ? .white.opacity(0.3) : .white)
                                .frame(width: 34, height: 34)
                                .background {
                                    if day == displayedDay {
                                        Circle().fill(PlanPalette.accent.opacity(0.35))
                                    }
                                }
                                .overlay {
                                    if day == todayIndex { Circle().strokeBorder(PlanPalette.accent, lineWidth: 1.5) }
                                }
                            Circle()
                                .fill(completedDays.contains(day) ? PlanPalette.done : .clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isFuture)
                    .accessibilityLabel(String(format: "plan.day_title".localized, day))
                }
            }
        }
        .padding(18)
        .planGlass(cornerRadius: 26)
    }

    private var weekDays: [Int] {
        let start = (week - 1) * 7 + 1
        return Array(start...min(start + 6, PersonalPlan.length))
    }

    private func segmentFill(week w: Int) -> CGFloat {
        let today = min(todayIndex, PersonalPlan.length)
        let start = (w - 1) * 7
        return CGFloat(max(0, min(7, today - start))) / 7
    }
}

// MARK: - Short version toggle

struct PlanShortToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn.animation(.spring(response: 0.35, dampingFraction: 0.85))) {
            HStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PlanPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(PlanPalette.accent.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("plan.short.title".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(.white)
                    Text("plan.short.subtitle".localized)
                        .font(Font.Poppins.custom(.regular, size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .tint(PlanPalette.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .planGlass(cornerRadius: 20)
    }
}

// MARK: - Thumbnail

/// Same square illustration for every item kind (clipped, never bleeding out of the card).
struct PlanThumbnail: View {
    let display: PlanItemDisplay
    var size: CGFloat = 60
    var cornerRadius: CGFloat = 16
    var showsPlay = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(PlanPalette.thumbnail)
            if let imageName = display.imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: display.symbol)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(PlanPalette.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            if showsPlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.black.opacity(0.45)))
                    .padding(5)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Day slot header

struct PlanSlotHeader: View {
    let slot: PlanDaySlot

    var body: some View {
        Label(slot.localizedTitle, systemImage: slot.symbol)
            .font(Font.Poppins.custom(.semiBold, size: 13))
            .foregroundStyle(PlanPalette.secondaryText)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.top, 6)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Next step

/// Highlights the first item left to do today, with a direct start button.
struct PlanNextStepCard: View {
    let item: PlanItem
    let display: PlanItemDisplay
    let onStart: () -> Void

    var body: some View {
        Button {
            HapticManager.medium()
            onStart()
        } label: {
            HStack(spacing: 16) {
                PlanThumbnail(display: display, size: 84, cornerRadius: 20)
                VStack(alignment: .leading, spacing: 6) {
                    Text("plan.next.title".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 11))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(PlanPalette.accent)
                    Text(display.title)
                        .font(.faroSemiBold(20))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Label(item.kind == .habit ? "plan.action.open".localized : "plan.next.start".localized,
                              systemImage: item.kind == .habit ? "arrow.right" : "play.fill")
                            .font(Font.Poppins.custom(.semiBold, size: 13))
                            .foregroundStyle(PlanPalette.deep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(PlanPalette.accent))
                        if let duration = display.durationLabel {
                            Text(duration)
                                .font(Font.Poppins.custom(.medium, size: 13))
                                .foregroundStyle(PlanPalette.secondaryText)
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 26, tint: PlanPalette.accent, interactive: true)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Item card

struct PlanItemCard: View {
    let item: PlanItem
    let display: PlanItemDisplay
    let status: TasksV2View.TaskStatus
    let isShort: Bool
    let isEditable: Bool
    let onOpen: () -> Void
    let onToggleDone: () -> Void
    let onSkip: () -> Void
    /// Edit mode: replace / remove controls instead of the completion circle.
    var isEditing = false
    var onSwap: (() -> Void)?
    var onRemove: (() -> Void)?

    @State private var donePop = false
    @State private var ringPulse = false
    @State private var ringVisible = false

    private var isDone: Bool { status == .done }
    private var canEdit: Bool { !isDone && (onSwap != nil || onRemove != nil) }
    private var isSkipped: Bool { status == .skipped }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: {
                HapticManager.light()
                onOpen()
            }) {
                HStack(spacing: 14) {
                    PlanThumbnail(display: display, showsPlay: item.kind == .audio || item.kind == .evening)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(display.kindLabel)
                                .font(Font.Poppins.custom(.medium, size: 12))
                                .foregroundStyle(PlanPalette.tertiaryText)
                            if let duration = display.durationLabel {
                                Text("·").foregroundStyle(PlanPalette.tertiaryText)
                                Text(duration)
                                    .font(Font.Poppins.custom(.medium, size: 12))
                                    .foregroundStyle(PlanPalette.tertiaryText)
                            }
                            if isShort && (item.shortRefID != nil || item.shortMinutes != nil) {
                                Text("plan.short.badge".localized)
                                    .font(Font.Poppins.custom(.medium, size: 10))
                                    .foregroundStyle(PlanPalette.accent)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(PlanPalette.accent.opacity(0.15)))
                            }
                        }
                        Text(display.title)
                            .font(Font.Poppins.custom(.semiBold, size: 16))
                            .foregroundStyle(.white.opacity(isDone ? 0.55 : 1))
                            .strikethrough(isDone, color: .white.opacity(0.4))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if !display.subtitle.isEmpty {
                            Text(display.subtitle)
                                .font(Font.Poppins.custom(.regular, size: 12))
                                .foregroundStyle(PlanPalette.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(openHint)

            if isEditing && canEdit {
                HStack(spacing: 6) {
                    if let onSwap {
                        editButton("arrow.triangle.2.circlepath", label: "plan.edit.swap".localized, action: onSwap)
                    }
                    if let onRemove {
                        editButton("minus", label: "plan.edit.remove".localized, action: onRemove)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    guard isEditable else { HapticManager.error(); return }
                    onToggleDone()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(isDone ? PlanPalette.done : .white.opacity(0.3), lineWidth: 2)
                            .background(Circle().fill(isDone ? PlanPalette.done : .clear))
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(PlanPalette.deep)
                                .transition(.scale(scale: 0.2).combined(with: .opacity))
                        } else if isSkipped {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .frame(width: 28, height: 28)
                    // Micro celebration: the checkbox pops and sends a ring out when validated.
                    .scaleEffect(donePop ? 1.18 : 1)
                    .overlay(
                        Circle()
                            .stroke(PlanPalette.done, lineWidth: 2)
                            .scaleEffect(ringPulse ? 2.1 : 1)
                            .opacity(ringPulse ? 0 : (ringVisible ? 0.9 : 0))
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .opacity(isEditable ? 1 : 0.5)
                .accessibilityLabel((isDone ? "plan.action.undo" : "plan.action.mark_done").localized)
            }
        }
        .padding(12)
        .planGlass(cornerRadius: 22, interactive: true)
        .opacity(isSkipped ? 0.5 : 1)
        .onChange(of: isDone) { _, done in
            guard done else { return }
            ringPulse = false
            ringVisible = true
            withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { donePop = true }
            withAnimation(.easeOut(duration: 0.6)) { ringPulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { donePop = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                ringVisible = false
                ringPulse = false
            }
        }
        .contextMenu {
            if isEditable {
                Button { onToggleDone() } label: {
                    Label((isDone ? "plan.action.undo" : "plan.action.mark_done").localized,
                          systemImage: isDone ? "arrow.uturn.backward" : "checkmark.circle")
                }
                if !isDone && !isSkipped {
                    Button { onSkip() } label: {
                        Label("plan.action.skip".localized, systemImage: "forward.end")
                    }
                }
                if !isDone, let onSwap {
                    Button { onSwap() } label: {
                        Label("plan.edit.swap".localized, systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                if !isDone, let onRemove {
                    Button(role: .destructive) { onRemove() } label: {
                        Label("plan.edit.remove".localized, systemImage: "minus.circle")
                    }
                }
            }
        }
    }

    private func editButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(.white.opacity(0.12)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var openHint: String {
        switch item.kind {
        case .breathing: return "plan.action.start".localized
        case .audio, .evening: return "plan.action.play".localized
        case .habit: return "plan.action.open".localized
        }
    }
}

// MARK: - Finished cycle

struct PlanFinishedCard: View {
    let plan: PersonalPlan
    let onContinue: () -> Void
    let onChangeGoal: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "laurel.leading.laurel.trailing")
                .font(.system(size: 40))
                .foregroundStyle(PlanPalette.accent)
            Text("plan.finished.title".localized)
                .font(.faroBold(24))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("plan.finished.subtitle".localized)
                .font(Font.Poppins.custom(.regular, size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button {
                HapticManager.medium()
                onContinue()
            } label: {
                Text(String(format: "plan.finished.same".localized, plan.goal.localizedName))
                    .font(Font.Poppins.custom(.semiBold, size: 15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .planGlassButtonStyle(prominent: true)
            Button {
                HapticManager.light()
                onChangeGoal()
            } label: {
                Text("plan.finished.new".localized)
                    .font(Font.Poppins.custom(.medium, size: 15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .planGlassButtonStyle(prominent: false)
        }
        .padding(22)
        .planGlass(cornerRadius: 28, tint: PlanPalette.accent)
    }
}

// MARK: - Follow-up cycle banner

/// Light banner at the top of a follow-up cycle (started on its own on day 29): the user
/// already has today's tasks and can still pick another goal.
struct PlanCycleBanner: View {
    let plan: PersonalPlan
    let onChangeGoal: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: plan.cycleTheme.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(LinearGradient(colors: PlanPalette.itemGradient, startPoint: .topLeading, endPoint: .bottomTrailing)))
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "plan.cycle_banner.title".localized, plan.cycle, plan.cycleTheme.localizedTitle))
                    .font(Font.Poppins.custom(.semiBold, size: 14))
                    .foregroundStyle(.white)
                Button {
                    HapticManager.light()
                    onChangeGoal()
                } label: {
                    Text("plan.cycle_banner.change_goal".localized)
                        .font(Font.Poppins.custom(.medium, size: 13))
                        .foregroundStyle(PlanPalette.accent)
                        .underline()
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("plan.close".localized)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .planGlass(cornerRadius: 20, tint: PlanPalette.accent)
    }
}
