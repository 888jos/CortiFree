//
//  ShareViewController.swift
//  CortiFreeShare
//
//  « Share › CortiFree »: receives a conversation link (ChatGPT, Claude, Grok, Gemini…),
//  copied text, a PDF (Apple Health export) or a screenshot, hands it to the app through
//  MiloShareInbox and opens CortiFree, where Milo reads it.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        model.onCancel = { [weak self] in
            self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
        }
        model.onSent = { [weak self] in
            guard let self else { return }
            let opened = self.openContainingApp(MiloShareInbox.openURL)
            if opened {
                self.extensionContext?.completeRequest(returningItems: nil)
            } else {
                self.model.state = .sentManualOpen
            }
        }
        model.onDone = { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }

        let host = UIHostingController(rootView: ShareCardView(model: model))
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)

        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        Task { await model.load(providers) }
    }

    /// Extensions can't call UIApplication.shared: find the application in the responder
    /// chain and call open(_:options:completionHandler:) through the runtime.
    private func openContainingApp(_ url: URL) -> Bool {
        let selector = NSSelectorFromString("openURL:options:completionHandler:")
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication, application.responds(to: selector) {
                typealias OpenFunction = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, AnyObject?) -> Void
                let function = unsafeBitCast(application.method(for: selector), to: OpenFunction.self)
                function(application, selector, url as NSURL, NSDictionary(), nil)
                return true
            }
            responder = current.next
        }
        return false
    }
}

// MARK: - Model

@MainActor
final class ShareModel: ObservableObject {
    enum State: Equatable {
        case loading
        case ready(ShareSummary)
        case unsupported
        case failed
        case sentManualOpen
    }

    @Published var state: State = .loading
    var onCancel: () -> Void = {}
    var onSent: () -> Void = {}
    var onDone: () -> Void = {}

    private var pending: (item: MiloShareInbox.Item, data: Data?)?

    func load(_ providers: [NSItemProvider]) async {
        if let (item, data, summary) = await Self.extract(from: providers) {
            pending = (item, data)
            state = .ready(summary)
        } else {
            state = .unsupported
        }
    }

    func send(_ mode: MiloShareInbox.Item.Mode = .story) {
        guard var item = pending?.item else { return }
        item.mode = mode
        do {
            try MiloShareInbox.save(item, fileData: pending?.data)
            onSent()
        } catch {
            state = .failed
        }
    }

    // MARK: Extraction

    /// Files first (PDF, screenshot), then a link, then plain text.
    private static func extract(from providers: [NSItemProvider]) async -> (MiloShareInbox.Item, Data?, ShareSummary)? {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            if let data = await loadData(provider, type: .pdf) {
                let suggested = provider.suggestedName ?? "document"
                let name = suggested.lowercased().hasSuffix(".pdf") ? suggested : suggested + ".pdf"
                return (item(.file, fileName: safeName(name)), data, ShareSummary(kind: .pdf, title: name, detail: nil))
            }
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let data = await loadData(provider, type: .image) {
                return (item(.file, fileName: "screenshot.png"), data, ShareSummary(kind: .image, title: nil, detail: nil))
            }
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = await loadURL(provider), let scheme = url.scheme?.lowercased() {
                if scheme == "http" || scheme == "https" {
                    return (item(.link, link: url.absoluteString), nil,
                            ShareSummary(kind: .link, title: ShareSummary.provider(for: url), detail: url.host))
                }
                if url.isFileURL, let data = try? Data(contentsOf: url) {
                    let name = safeName(url.lastPathComponent)
                    return (item(.file, fileName: name), data, ShareSummary(kind: .pdf, title: url.lastPathComponent, detail: nil))
                }
            }
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            guard let text = await loadText(provider)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { continue }
            // « Share » in some AI apps sends the conversation link as text.
            if text.count < 300, let url = firstLink(in: text) {
                return (item(.link, link: url.absoluteString), nil,
                        ShareSummary(kind: .link, title: ShareSummary.provider(for: url), detail: url.host))
            }
            let words = text.split(whereSeparator: \.isWhitespace).count
            return (item(.text, text: String(text.prefix(60_000))), nil,
                    ShareSummary(kind: .text, title: nil, detail: "\(words)"))
        }
        return nil
    }

    private static func item(_ kind: MiloShareInbox.Item.Kind, text: String? = nil, link: String? = nil, fileName: String? = nil) -> MiloShareInbox.Item {
        MiloShareInbox.Item(id: UUID(), kind: kind, text: text, link: link, fileName: fileName, date: Date())
    }

    private static func safeName(_ name: String) -> String {
        let cleaned = name.replacingOccurrences(of: "/", with: "-")
        return cleaned.isEmpty ? "document" : cleaned
    }

    private static func firstLink(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        return detector?.firstMatch(in: text, range: range)?.url
    }

    private static func loadData(_ provider: NSItemProvider, type: UTType) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    private static func loadURL(_ provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                if let url = item as? URL { continuation.resume(returning: url) }
                else if let data = item as? Data { continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil)) }
                else if let string = item as? String { continuation.resume(returning: URL(string: string)) }
                else { continuation.resume(returning: nil) }
            }
        }
    }

    private static func loadText(_ provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, _ in
                if let string = item as? String { continuation.resume(returning: string) }
                else if let data = item as? Data { continuation.resume(returning: String(data: data, encoding: .utf8)) }
                else if let string = (item as? NSAttributedString)?.string { continuation.resume(returning: string) }
                else { continuation.resume(returning: nil) }
            }
        }
    }
}

struct ShareSummary: Equatable {
    enum Kind { case link, text, pdf, image }
    let kind: Kind
    let title: String?
    let detail: String?

    static func provider(for url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if host.contains("chatgpt.com") || host.contains("openai.com") { return "ChatGPT" }
        if host.contains("claude.ai") { return "Claude" }
        if host.contains("grok.com") || host.hasSuffix("x.com") { return "Grok" }
        if host.contains("gemini") || host == "g.co" { return "Gemini" }
        if host.contains("perplexity") { return "Perplexity" }
        if host.contains("copilot") { return "Copilot" }
        if host.contains("mistral") { return "Le Chat" }
        if host.contains("deepseek") { return "DeepSeek" }
        return nil
    }
}

// MARK: - View

private struct ShareCardView: View {
    @ObservedObject var model: ShareModel

    private let accent = Color(red: 0.72, green: 0.58, blue: 0.96)
    private let deep = Color(red: 0.18, green: 0.11, blue: 0.31)

    var body: some View {
        ZStack {
            // The share sheet is full height: paint all of it, not a floating card on white.
            LinearGradient(colors: [Color(red: 0.12, green: 0.07, blue: 0.24), Color(red: 0.05, green: 0.03, blue: 0.12)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button(action: model.onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.1), in: Circle())
                    }
                    .accessibilityLabel(ShareText.cancel)
                }

                Spacer(minLength: 0)

                Image("MiloAvatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)

                content

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView().tint(.white).padding(.vertical, 30)
        case .ready(let summary):
            VStack(spacing: 8) {
                Text(ShareText.title(for: summary))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(summary.kind == .image || summary.kind == .text ? ShareText.choiceSubtitle : ShareText.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            chip(for: summary)
            if summary.kind == .image || summary.kind == .text {
                // A screenshot or a text is often the message someone is overthinking.
                primaryButton(ShareText.decode) { model.send(.decode) }
                secondaryButton(ShareText.knowMe) { model.send(.story) }
            } else {
                primaryButton(ShareText.send) { model.send(.story) }
            }
            Text(ShareText.privacy)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        case .failed:
            Text(ShareText.failed)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            primaryButton(ShareText.close, action: model.onCancel)
        case .unsupported:
            Text(ShareText.unsupported)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            primaryButton(ShareText.close, action: model.onCancel)
        case .sentManualOpen:
            Text(ShareText.sentTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(ShareText.sentSubtitle)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            primaryButton(ShareText.close, action: model.onDone)
        }
    }

    private func chip(for summary: ShareSummary) -> some View {
        let (icon, text): (String, String) = {
            switch summary.kind {
            case .link: return ("link", summary.detail ?? "")
            case .text: return ("text.bubble", ShareText.words(summary.detail ?? "0"))
            case .pdf: return ("doc.richtext", summary.title ?? "PDF")
            case .image: return ("photo", ShareText.screenshot)
            }
        }()
        return Label(text, systemImage: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1), in: Capsule())
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(deep)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Copy (the extension has no Localizable.strings of its own)

private enum ShareText {
    private static var lang: String {
        let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        return ["fr", "es", "de", "ja", "ko"].contains(code) ? String(code) : "en"
    }

    private static func pick(_ values: [String: String]) -> String { values[lang] ?? values["en"]! }

    static func title(for summary: ShareSummary) -> String {
        if summary.kind == .image || summary.kind == .text {
            return pick(["en": "What should Milo do?", "fr": "Que doit faire Milo ?", "es": "¿Qué hace Milo?",
                         "de": "Was soll Milo tun?", "ja": "Miloに何をしてもらう？", "ko": "Milo가 무엇을 할까요?"])
        }
        if let provider = summary.title, summary.kind == .link {
            return pick(["en": "Let Milo read your \(provider) chat", "fr": "Milo lit ta discussion \(provider)",
                         "es": "Milo lee tu chat de \(provider)", "de": "Milo liest deinen \(provider)-Chat",
                         "ja": "Miloが\(provider)の会話を読みます", "ko": "Milo가 \(provider) 대화를 읽어요"])
        }
        return pick(["en": "Let Milo read it", "fr": "Milo va le lire", "es": "Deja que Milo lo lea",
                     "de": "Lass Milo es lesen", "ja": "Miloに読んでもらう", "ko": "Milo에게 읽게 하기"])
    }

    static var subtitle: String {
        pick(["en": "Milo gets to know you and builds your next step.",
              "fr": "Milo apprend à te connaître et te propose ta prochaine étape.",
              "es": "Milo te conoce mejor y te propone tu siguiente paso.",
              "de": "Milo lernt dich kennen und schlägt dir den nächsten Schritt vor.",
              "ja": "Miloがあなたを理解し、次の一歩を提案します。",
              "ko": "Milo가 당신을 알아가고 다음 단계를 제안해요."])
    }

    static var choiceSubtitle: String {
        pick(["en": "A message on your mind? Milo tells you what it most likely means. Or let Milo get to know you.",
              "fr": "Un message te fait cogiter ? Milo te dit ce qu'il veut sûrement dire. Ou laisse Milo apprendre à te connaître.",
              "es": "¿Un mensaje te da vueltas? Milo te dice lo que probablemente significa. O deja que Milo te conozca.",
              "de": "Eine Nachricht geht dir nicht aus dem Kopf? Milo sagt dir, was sie wahrscheinlich bedeutet. Oder lass Milo dich kennenlernen.",
              "ja": "気になるメッセージ？Miloがおそらくの意味を教えます。またはMiloにあなたを知ってもらいましょう。",
              "ko": "신경 쓰이는 메시지가 있나요? Milo가 그 뜻을 알려 줘요. 아니면 Milo가 당신을 알게 해 주세요."])
    }

    static var decode: String {
        pick(["en": "Decode this message", "fr": "Décoder ce message", "es": "Descifrar este mensaje",
              "de": "Diese Nachricht deuten", "ja": "このメッセージを読み解く", "ko": "이 메시지 해석하기"])
    }

    static var knowMe: String {
        pick(["en": "Help Milo get to know me", "fr": "Aider Milo à me connaître", "es": "Que Milo me conozca",
              "de": "Milo soll mich kennenlernen", "ja": "Miloに自分を知ってもらう", "ko": "Milo가 나를 알게 하기"])
    }

    static var send: String {
        pick(["en": "Send to Milo", "fr": "Envoyer à Milo", "es": "Enviar a Milo",
              "de": "An Milo senden", "ja": "Miloに送る", "ko": "Milo에게 보내기"])
    }

    static var privacy: String {
        pick(["en": "Milo reads it once and only keeps a short summary you can delete.",
              "fr": "Milo le lit une fois et ne garde qu'un court résumé, supprimable.",
              "es": "Milo lo lee una vez y solo guarda un breve resumen que puedes borrar.",
              "de": "Milo liest es einmal und behält nur eine kurze, löschbare Zusammenfassung.",
              "ja": "Miloは一度だけ読み、削除できる短い要約だけを残します。",
              "ko": "Milo는 한 번만 읽고 삭제 가능한 짧은 요약만 남겨요."])
    }

    static var unsupported: String {
        pick(["en": "Milo can read a conversation link, text, a PDF or a screenshot.",
              "fr": "Milo peut lire un lien de conversation, du texte, un PDF ou une capture d'écran.",
              "es": "Milo puede leer un enlace de conversación, texto, un PDF o una captura.",
              "de": "Milo kann einen Chat-Link, Text, ein PDF oder einen Screenshot lesen.",
              "ja": "Miloは会話のリンク、テキスト、PDF、スクリーンショットを読めます。",
              "ko": "Milo는 대화 링크, 텍스트, PDF, 스크린샷을 읽을 수 있어요."])
    }

    static var failed: String {
        pick(["en": "CortiFree couldn't receive it. Copy the conversation and paste it into Milo instead.",
              "fr": "CortiFree n'a pas pu le recevoir. Copie la conversation et colle-la dans Milo.",
              "es": "CortiFree no pudo recibirlo. Copia la conversación y pégala en Milo.",
              "de": "CortiFree konnte es nicht empfangen. Kopiere das Gespräch und füge es bei Milo ein.",
              "ja": "CortiFreeで受け取れませんでした。会話をコピーしてMiloに貼り付けてください。",
              "ko": "CortiFree가 받지 못했어요. 대화를 복사해 Milo에 붙여 넣어 주세요."])
    }

    static var sentTitle: String {
        pick(["en": "Sent to Milo", "fr": "Envoyé à Milo", "es": "Enviado a Milo",
              "de": "An Milo gesendet", "ja": "Miloに送りました", "ko": "Milo에게 보냈어요"])
    }

    static var sentSubtitle: String {
        pick(["en": "Open CortiFree: Milo is waiting with your analysis.",
              "fr": "Ouvre CortiFree : Milo t'attend avec ton analyse.",
              "es": "Abre CortiFree: Milo te espera con tu análisis.",
              "de": "Öffne CortiFree: Milo wartet mit deiner Analyse.",
              "ja": "CortiFreeを開いてください。Miloが分析を用意しています。",
              "ko": "CortiFree를 열어 주세요. Milo가 분석을 준비했어요."])
    }

    static var close: String {
        pick(["en": "Close", "fr": "Fermer", "es": "Cerrar", "de": "Schließen", "ja": "閉じる", "ko": "닫기"])
    }

    static var cancel: String {
        pick(["en": "Cancel", "fr": "Annuler", "es": "Cancelar", "de": "Abbrechen", "ja": "キャンセル", "ko": "취소"])
    }

    static var screenshot: String {
        pick(["en": "Screenshot", "fr": "Capture d'écran", "es": "Captura", "de": "Screenshot", "ja": "スクリーンショット", "ko": "스크린샷"])
    }

    static func words(_ count: String) -> String {
        pick(["en": "\(count) words", "fr": "\(count) mots", "es": "\(count) palabras",
              "de": "\(count) Wörter", "ja": "\(count)語", "ko": "\(count)단어"])
    }
}
