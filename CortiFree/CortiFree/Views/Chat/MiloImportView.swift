//
//  MiloImportView.swift
//  CortiFree
//
//  « Bring your story to Milo »: pick what to share (ask your own AI about you,
//  paste a conversation, or import a PDF such as an Apple Health export), watch
//  Milo read it, then keep or drop what Milo learned.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct MiloImportView: View {
    /// A document shared from another app, analysed right away.
    var initialDocument: MiloImportDocument?
    let isQuotaReached: Bool
    /// One assistant call was spent (counts toward the daily quota).
    let onAnalyzed: () -> Void
    /// The user kept the insight and wants to talk about it.
    let onFinish: (MiloInsight) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var store = MiloStore.shared

    private enum Phase: Equatable {
        case choose
        case reading(MiloImportDocument)
        case result(MiloInsight)
    }

    @State private var phase: Phase = .choose
    @State private var errorMessage: String?
    @State private var showFilePicker = false
    @State private var copiedPrompt = false
    @State private var analysisTask: Task<Void, Never>?
    @State private var screenshot: PhotosPickerItem?

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85)
                .ignoresSafeArea()

            switch phase {
            case .choose:
                chooser
                    .transition(.opacity)
            case .reading(let document):
                MiloReadingView(document: document)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .result(let insight):
                result(insight)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: phase)
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: MiloImportReader.fileTypes) { result in
            switch result {
            case .success(let url):
                do { start(try MiloImportReader.read(url)) } catch { errorMessage = error.localizedDescription }
            case .failure:
                errorMessage = t("milo.import.error.unreadable")
            }
        }
        .onAppear {
            if let initialDocument, phase == .choose { start(initialDocument) }
        }
        .onChange(of: screenshot) { _, item in
            guard let item else { return }
            screenshot = nil
            Task { @MainActor in
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    errorMessage = t("milo.import.error.unreadable")
                    return
                }
                do { start(try MiloImportReader.image(data)) } catch { errorMessage = error.localizedDescription }
            }
        }
        .onDisappear { analysisTask?.cancel() }
    }

    // MARK: - Choose

    private var chooser: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                closeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image("cortifree_assistant_avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        Text(t("milo.import.title"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(t("milo.import.subtitle"))
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 4)

                    askCard
                    pasteCard
                    fileCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "FFB4A8"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if isQuotaReached {
                        Text(t("assistant.quota.reached"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AudioPalette.secondaryText)
                    }

                    Label(t("milo.import.privacy"), systemImage: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .cfGlassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t("common.close"))
    }

    /// The viral one: ask ChatGPT / Claude what they know about you, paste the answer.
    private var askCard: some View {
        optionCard(icon: "sparkles", titleKey: "milo.import.ask.title", noteKey: "milo.import.ask.note", highlighted: true) {
            VStack(alignment: .leading, spacing: 10) {
                stepLabel(1, t("milo.import.ask.step1"))
                HStack(spacing: 8) {
                    ForEach(MiloImportCenter.AskApp.allCases) { app in
                        Button {
                            HapticManager.light()
                            if let url = MiloImportCenter.askURL(app) { openURL(url) }
                        } label: {
                            Text(app.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AudioPalette.backgroundDeep)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(AudioPalette.accent, in: Capsule())
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                    Button {
                        UIPasteboard.general.string = MiloImportCenter.askPrompt()
                        HapticManager.light()
                        copiedPrompt = true
                    } label: {
                        Image(systemName: copiedPrompt ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t("milo.import.ask.copy"))
                }
                stepLabel(2, t("milo.import.ask.step2"))
                pasteButton
            }
        }
    }

    private var pasteCard: some View {
        optionCard(icon: "bubble.left.and.text.bubble.right.fill", titleKey: "milo.import.paste.title", noteKey: "milo.import.paste.note") {
            pasteButton
        }
    }

    private var fileCard: some View {
        optionCard(icon: "doc.richtext.fill", titleKey: "milo.import.file.title", noteKey: "milo.import.file.note") {
            HStack(spacing: 8) {
                PhotosPicker(selection: $screenshot, matching: .screenshots) {
                    Label(t("milo.import.file.screenshot"), systemImage: "photo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressableCardStyle())

                Button {
                    HapticManager.light()
                    errorMessage = nil
                    showFilePicker = true
                } label: {
                    Label(t("milo.import.file.button"), systemImage: "doc")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressableCardStyle())
            }
            .disabled(isQuotaReached)
        }
    }

    /// System paste button: reads the clipboard without the « Allow Paste » prompt.
    private var pasteButton: some View {
        PasteButton(payloadType: String.self) { strings in
            let text = strings.joined(separator: "\n")
            Task { @MainActor in
                do { start(try MiloImportReader.pasted(text)) } catch { errorMessage = error.localizedDescription }
            }
        }
        .labelStyle(.titleAndIcon)
        .buttonBorderShape(.capsule)
        .tint(Color.white.opacity(0.18))
        .disabled(isQuotaReached)
    }

    private func stepLabel(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: "\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AudioPalette.backgroundDeep)
                .frame(width: 20, height: 20)
                .background(AudioPalette.accent.opacity(0.85), in: Circle())
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func optionCard<Content: View>(icon: String, titleKey: String, noteKey: String, highlighted: Bool = false,
                                           @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                    .frame(width: 36, height: 36)
                    .background(AudioPalette.accent.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(t(titleKey))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(t(noteKey))
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cfGlass(cornerRadius: 22)
        .overlay {
            if highlighted {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AudioPalette.accent.opacity(0.45), lineWidth: 1)
            }
        }
    }

    // MARK: - Analysis

    private func start(_ document: MiloImportDocument) {
        guard !isQuotaReached else { errorMessage = t("assistant.quota.reached"); return }
        errorMessage = nil
        phase = .reading(document)
        analysisTask = Task {
            // The reading animation always plays in full, even when the reply is instant.
            async let minimumShow: Void = { try? await Task.sleep(for: .seconds(5.5)) }()
            do {
                let insight = try await MiloImportAnalyzer.analyze(document)
                await minimumShow
                guard !Task.isCancelled else { return }
                onAnalyzed()
                HapticManager.success()
                phase = .result(insight)
            } catch {
                await minimumShow
                guard !Task.isCancelled else { return }
                if case DeepSeekChatError.quotaExceeded = error { onAnalyzed() }
                errorMessage = (error as? LocalizedError)?.errorDescription ?? t("assistant.error.unavailable")
                phase = .choose
            }
        }
    }

    // MARK: - Result

    private func result(_ insight: MiloInsight) -> some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image("cortifree_assistant_avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t("milo.import.result.eyebrow").uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.8)
                                .foregroundStyle(AudioPalette.accent)
                            Text(t("milo.import.result.title"))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 28)

                    Text(insight.summary)
                        .font(.system(size: 17))
                        .lineSpacing(5)
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cfGlass(cornerRadius: 22)

                    if !insight.themes.isEmpty {
                        MiloChipFlow(items: insight.themes)
                    }

                    if !insight.firstStep.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AudioPalette.backgroundDeep)
                                .frame(width: 32, height: 32)
                                .background(AudioPalette.accent, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t("milo.import.result.first_step"))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AudioPalette.accent)
                                Text(insight.firstStep)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AudioPalette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    Text(t("milo.import.result.disclaimer"))
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
            }

            VStack(spacing: 8) {
                Button {
                    HapticManager.light()
                    store.insight = insight
                    onFinish(insight)
                    dismiss()
                } label: {
                    Text(t("milo.import.result.keep"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AudioPalette.backgroundDeep)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AudioPalette.accent, in: Capsule())
                }
                .buttonStyle(PressableCardStyle())

                Button(t("milo.import.result.discard")) { dismiss() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(minHeight: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Reading animation

/// Milo « reads » the document: glowing orbit around the avatar, the page scanned line by
/// line, and the topics found in the document popping in one after another.
private struct MiloReadingView: View {
    let document: MiloImportDocument

    @State private var topics: [MiloImportTopics.Topic] = []
    @State private var visibleTopics = 0
    @State private var stepIndex = 0
    @State private var appeared = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    private var steps: [String] {
        let first = document.source == .healthPDF ? "milo.import.reading.step.health" : "milo.import.reading.step.read"
        return [first, "milo.import.reading.step.notice", "milo.import.reading.step.connect"].map(t)
    }

    /// A few real lines of the document, blurred, scrolling behind the scanner.
    private var previewLines: [String] {
        document.text.components(separatedBy: .newlines)
            .filter { $0.count > 12 }
            .prefix(14)
            .map { String($0.prefix(60)) }
    }

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 20)

            orbit
                .frame(width: 190, height: 190)

            VStack(spacing: 8) {
                Text(t("milo.import.reading.title"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(steps[stepIndex])
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .contentTransition(.opacity)
                    .id(stepIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .multilineTextAlignment(.center)

            page
                .frame(height: 150)
                .padding(.horizontal, 32)

            MiloChipFlow(items: topics.prefix(visibleTopics).map(\.title), icons: topics.prefix(visibleTopics).map(\.icon), centered: true)
                .padding(.horizontal, 24)
                .frame(minHeight: 80, alignment: .top)

            Spacer(minLength: 20)
        }
        .onAppear(perform: run)
        .accessibilityElement(children: .combine)
    }

    private var orbit: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [AudioPalette.accent.opacity(0.45), .clear], center: .center, startRadius: 10, endRadius: 95))
                    .scaleEffect(1 + 0.08 * sin(time * 2.2))

                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(AngularGradient(colors: [AudioPalette.accent.opacity(0), AudioPalette.accent, .white],
                                            center: .center), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 168, height: 168)
                    .rotationEffect(.radians(time * 2.4))

                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.radians(-time * 1.6))

                ForEach(0..<6, id: \.self) { index in
                    let angle = time * 0.9 + Double(index) * .pi / 3
                    Circle()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 4, height: 4)
                        .offset(x: cos(angle) * 84, y: sin(angle) * 84)
                        .opacity(0.4 + 0.6 * max(0, sin(time * 3 + Double(index))))
                }

                Image("cortifree_assistant_avatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .offset(y: 3 * sin(time * 1.8))
            }
        }
    }

    private var page: some View {
        TimelineView(.animation) { context in
            let progress = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(previewLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.55))
                                .lineLimit(1)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .blur(radius: 2.2)
                    .offset(y: -CGFloat(progress) * 40)

                    LinearGradient(colors: [AudioPalette.accent.opacity(0), AudioPalette.accent.opacity(0.55), AudioPalette.accent.opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 34)
                        .offset(y: CGFloat(progress) * (geo.size.height - 34))
                        .blendMode(.screen)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.14)))
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .accessibilityHidden(true)
    }

    private func run() {
        topics = MiloImportTopics.detect(in: document.text)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        for index in 1...2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.8) {
                withAnimation(.easeOut(duration: 0.35)) { stepIndex = index }
            }
        }
        for index in topics.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(index) * 0.75) {
                HapticManager.light()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { visibleTopics = index + 1 }
            }
        }
    }
}

/// Wrapping row of capsules (themes, topics).
struct MiloChipFlow: View {
    let items: [String]
    var icons: [String] = []
    var centered = false

    var body: some View {
        MiloFlowLayout(spacing: 8, centered: centered) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 6) {
                    if let icon = icons[safe: index] {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AudioPalette.accent)
                    }
                    Text(item)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.10), in: Capsule())
                .overlay(Capsule().strokeBorder(AudioPalette.accent.opacity(0.35)))
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
    }
}

private struct MiloFlowLayout: Layout {
    var spacing: CGFloat
    var centered: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = centered ? bounds.minX + (bounds.width - row.width) / 2 : bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let current = rows.count - 1
            rows[current].width += rows[current].indices.isEmpty ? size.width : size.width + spacing
            rows[current].height = max(rows[current].height, size.height)
            rows[current].indices.append(index)
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}
