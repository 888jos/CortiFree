//
//  MiloDecodeView.swift
//  CortiFree
//
//  « Decode this message »: pick the screenshot (or paste the text) that is making the
//  user overthink, watch Milo read it, then get the likely meaning, a calming sentence,
//  a calm reply to copy and a short breathing reset.
//

import SwiftUI
import PhotosUI

struct MiloDecodeView: View {
    /// A screenshot or text shared through « Share › CortiFree », decoded right away.
    var initialDocument: MiloImportDocument?
    let isQuotaReached: Bool
    let onAnalyzed: () -> Void
    let onBreathe: () -> Void
    let onTalk: (MiloDecodeResult) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Phase: Equatable {
        case choose
        case reading(MiloImportDocument)
        case result(MiloDecodeResult)
    }

    @State private var phase: Phase = .choose
    @State private var errorMessage: String?
    @State private var screenshot: PhotosPickerItem?
    @State private var copied = false
    @State private var task: Task<Void, Never>?

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85)
                .ignoresSafeArea()

            switch phase {
            case .choose:
                chooser.transition(.opacity)
            case .reading(let document):
                MiloReadingView(
                    document: document,
                    titleKey: "milo.decode.reading.title",
                    stepKeys: ["milo.decode.reading.step1", "milo.decode.reading.step2", "milo.decode.reading.step3"]
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .result(let result):
                resultView(result).transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: phase)
        .preferredColorScheme(.dark)
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
                do { start(try MiloImportReader.chatImage(data)) } catch { errorMessage = error.localizedDescription }
            }
        }
        .onDisappear { task?.cancel() }
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

            Spacer(minLength: 0)

            VStack(spacing: 14) {
                Image("cortifree_assistant_avatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                Text(t("milo.decode.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(t("milo.decode.subtitle"))
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                PhotosPicker(selection: $screenshot, matching: .screenshots) {
                    Label(t("milo.decode.screenshot"), systemImage: "photo.on.rectangle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AudioPalette.backgroundDeep)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AudioPalette.accent, in: Capsule())
                }
                .buttonStyle(PressableCardStyle())

                PasteButton(payloadType: String.self) { strings in
                    let text = strings.joined(separator: "\n")
                    Task { @MainActor in
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.count >= 2 else { errorMessage = t("milo.import.error.empty"); return }
                        start(MiloImportDocument(text: trimmed, source: .document, fileName: nil))
                    }
                }
                .labelStyle(.titleAndIcon)
                .buttonBorderShape(.capsule)
                .tint(Color.white.opacity(0.18))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "FFB4A8"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Label(t("milo.decode.privacy"), systemImage: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .disabled(isQuotaReached)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .cfGlassCircle(interactive: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t("common.close"))
    }

    // MARK: - Decode

    private func start(_ document: MiloImportDocument) {
        guard !isQuotaReached else { errorMessage = t("assistant.quota.reached"); return }
        errorMessage = nil
        phase = .reading(document)
        task = Task {
            async let minimumShow: Void = { try? await Task.sleep(for: .seconds(4)) }()
            do {
                let result = try await MiloDecodeAnalyzer.decode(document)
                await minimumShow
                guard !Task.isCancelled else { return }
                onAnalyzed()
                HapticManager.success()
                phase = .result(result)
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

    private func resultView(_ result: MiloDecodeResult) -> some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image("cortifree_assistant_avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t("milo.decode.result.eyebrow").uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.8)
                                .foregroundStyle(AudioPalette.accent)
                            Text(t("milo.decode.result.title"))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 28)

                    if !result.tone.isEmpty {
                        Label(result.tone, systemImage: "waveform")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AudioPalette.accent.opacity(0.22), in: Capsule())
                            .overlay(Capsule().strokeBorder(AudioPalette.accent.opacity(0.5)))
                    }

                    Text(result.meaning)
                        .font(.system(size: 17))
                        .lineSpacing(5)
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cfGlass(cornerRadius: 22)

                    if !result.reassurance.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AudioPalette.backgroundDeep)
                                .frame(width: 30, height: 30)
                                .background(AudioPalette.accent, in: Circle())
                            Text(result.reassurance)
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AudioPalette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    if !result.reply.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(t("milo.decode.result.reply"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AudioPalette.accent)
                            Text(result.reply)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(hex: "3478F6"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Button {
                                UIPasteboard.general.string = result.reply
                                HapticManager.light()
                                copied = true
                            } label: {
                                Label(t(copied ? "milo.decode.result.copied" : "milo.decode.result.copy"),
                                      systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.12), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(16)
                        .cfGlass(cornerRadius: 22)
                    }

                    Text(t("milo.decode.result.disclaimer"))
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
            }

            VStack(spacing: 8) {
                Button {
                    HapticManager.light()
                    dismiss()
                    onBreathe()
                } label: {
                    Label(t("milo.decode.result.breathe"), systemImage: "wind")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AudioPalette.backgroundDeep)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AudioPalette.accent, in: Capsule())
                }
                .buttonStyle(PressableCardStyle())

                Button(t("milo.decode.result.talk")) {
                    onTalk(result)
                    dismiss()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .frame(minHeight: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}
