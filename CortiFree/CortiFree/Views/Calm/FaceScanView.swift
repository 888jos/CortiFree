//
//  FaceScanView.swift
//  CortiFree
//
//  Weekly face check: selfie → Milo scans it (sweeping line over the photo) → visible
//  signs, a « rested » score, one tip, and the week-by-week photos of the cycle.
//

import SwiftUI
import PhotosUI

struct FaceScanView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FaceScanStore.shared

    private enum Phase: Equatable {
        case intro
        case scanning(UIImage)
        case result(FaceScanRecord)
    }

    @State private var phase: Phase = .intro
    @State private var showCamera = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showConsent = false
    @AppStorage(FaceScanConsent.storageKey) private var consentStore = ""

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    /// The selfie goes to OpenAI: nothing can be taken or picked before this explicit consent.
    private var consentUID: String { UnifiedFirebaseService.shared.auth.currentUserId ?? "local" }
    private var hasConsent: Bool { MiloConsent.isGranted(in: consentStore, uid: consentUID) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
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
                .padding(.horizontal, 16)
                .padding(.top, 14)

                switch phase {
                case .intro: intro
                case .scanning(let image): scanning(image)
                case .result(let record): result(record)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: phase)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showCamera) {
            SelfieCamera { image in
                showCamera = false
                if let image { start(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            libraryItem = nil
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    start(image)
                } else {
                    errorMessage = t("milo.import.error.unreadable")
                }
            }
        }
        .onAppear { store.reload() }
        .sheet(isPresented: $showConsent) {
            MiloConsentSheet(
                titleKey: "calm.face.consent.title",
                points: [
                    ("server.rack", "calm.face.consent.point.provider"),
                    ("iphone", "calm.face.consent.point.storage"),
                    ("stethoscope", "calm.face.consent.point.wellness"),
                    ("hand.raised.fill", "calm.face.consent.point.optional")
                ],
                acceptKey: "calm.face.consent.continue",
                onAccept: {
                    consentStore = MiloConsent.granting(consentUID, in: consentStore)
                    AnalyticsManager.shared.track(event: "face_check_consent_given")
                    showConsent = false
                },
                onDecline: { showConsent = false }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: Intro

    private var intro: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    weekStrip
                        .padding(.top, 8)
                    Image(systemName: "face.dashed")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(AudioPalette.accent)
                        .padding(.top, 10)
                    Text(String(format: t("calm.face.title"), store.currentSlot + 1))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(t("calm.face.subtitle"))
                        .font(.system(size: 15))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 10) {
                        tipRow("sun.max.fill", "calm.face.tip.light")
                        tipRow("face.smiling", "calm.face.tip.neutral")
                        tipRow("sparkles", "calm.face.tip.nomakeup")
                    }
                    .padding(16)
                    .cfGlass(cornerRadius: 20)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "FFB4A8"))
                            .multilineTextAlignment(.center)
                    }
                    Label(t("calm.face.privacy"), systemImage: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 8) {
                if !hasConsent {
                    primary(t(cameraAvailable ? "calm.face.take" : "calm.face.choose"), icon: cameraAvailable ? "camera.fill" : nil) { showConsent = true }
                } else {
                    if cameraAvailable {
                        primary(t("calm.face.take"), icon: "camera.fill") { showCamera = true }
                    }
                    PhotosPicker(selection: $libraryItem, matching: .images) {
                        Text(t(cameraAvailable ? "calm.face.library" : "calm.face.choose"))
                            .font(.system(size: 15, weight: cameraAvailable ? .medium : .semibold))
                            .foregroundStyle(cameraAvailable ? .white.opacity(0.75) : AudioPalette.backgroundDeep)
                            .frame(maxWidth: .infinity, minHeight: cameraAvailable ? 40 : 52)
                            .background(cameraAvailable ? Color.clear : AudioPalette.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var weekStrip: some View {
        let cycle = store.planPosition.cycle
        return HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { slot in
                let record = store.record(cycle: cycle, slot: slot)
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(record != nil ? AudioPalette.accent : Color.white.opacity(slot == store.currentSlot ? 0.18 : 0.08))
                        if let record, let image = store.image(for: record) {
                            Image(uiImage: image).resizable().scaledToFill().clipShape(Circle())
                        } else {
                            Text(verbatim: "\(slot + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(slot == store.currentSlot ? AudioPalette.accent : .clear, lineWidth: 2))
                    Text(String(format: t("calm.face.day"), FaceScanStore.slotDays[slot]))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AudioPalette.secondaryText)
                }
            }
        }
    }

    private func tipRow(_ icon: String, _ key: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AudioPalette.accent)
                .frame(width: 22)
            Text(t(key))
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primary(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Group {
                if let icon { Label(title, systemImage: icon) } else { Text(title) }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AudioPalette.backgroundDeep)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AudioPalette.accent, in: Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: Scan

    private func start(_ image: UIImage) {
        guard hasConsent else { showConsent = true; return }
        errorMessage = nil
        phase = .scanning(image)
        Task {
            async let minimumShow: Void = { try? await Task.sleep(for: .seconds(4)) }()
            do {
                let result = try await FaceScanAnalyzer.analyze(image)
                await minimumShow
                let record = try store.save(image: image, result: result)
                AnalyticsManager.shared.track(event: "face_check_completed", properties: ["slot": record.slot, "score": result.restedScore])
                HapticManager.success()
                phase = .result(record)
            } catch {
                await minimumShow
                errorMessage = (error as? LocalizedError)?.errorDescription ?? t("calm.face.error.unavailable")
                phase = .intro
            }
        }
    }

    private func scanning(_ image: UIImage) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            TimelineView(.animation) { context in
                let progress = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        LinearGradient(colors: [AudioPalette.accent.opacity(0), AudioPalette.accent.opacity(0.7), AudioPalette.accent.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 60)
                            .offset(y: CGFloat(progress) * (geo.size.height - 60))
                            .blendMode(.screen)
                        // Points that light up as the line passes: eyes, under-eyes, cheeks, jaw.
                        ForEach(Array(Self.scanPoints.enumerated()), id: \.offset) { _, point in
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                                .shadow(color: AudioPalette.accent, radius: 6)
                                .opacity(abs(progress - point.y) < 0.12 ? 1 : 0.25)
                                .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                        }
                    }
                }
            }
            .frame(width: 260, height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(AudioPalette.accent.opacity(0.6), lineWidth: 2))

            Text(t("calm.face.scanning"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(t("calm.face.scanning.sub"))
                .font(.system(size: 14))
                .foregroundStyle(AudioPalette.secondaryText)
            Spacer(minLength: 0)
        }
    }

    private static let scanPoints: [CGPoint] = [
        CGPoint(x: 0.36, y: 0.40), CGPoint(x: 0.64, y: 0.40),
        CGPoint(x: 0.34, y: 0.48), CGPoint(x: 0.66, y: 0.48),
        CGPoint(x: 0.28, y: 0.60), CGPoint(x: 0.72, y: 0.60),
        CGPoint(x: 0.38, y: 0.78), CGPoint(x: 0.5, y: 0.84), CGPoint(x: 0.62, y: 0.78)
    ]

    // MARK: Result

    private func result(_ record: FaceScanRecord) -> some View {
        let previous = store.currentCycleRecords.filter { $0.slot < record.slot }.last
        return VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack(spacing: 16) {
                        if let image = store.image(for: record) {
                            Image(uiImage: image)
                                .resizable().scaledToFill()
                                .frame(width: 96, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(format: t("calm.face.result.week"), record.slot + 1).uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.8)
                                .foregroundStyle(AudioPalette.accent)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(verbatim: "\(record.result.restedScore)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(verbatim: "/100")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AudioPalette.secondaryText)
                            }
                            Text(t("calm.face.result.rested"))
                                .font(.system(size: 13))
                                .foregroundStyle(AudioPalette.secondaryText)
                            if let previous {
                                let delta = record.result.restedScore - previous.result.restedScore
                                Text(String(format: t("calm.face.result.delta"), "\(delta >= 0 ? "+" : "")\(delta)", previous.slot + 1))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(delta >= 0 ? Color(hex: "6FE3B4") : Color(hex: "FFB86B"))
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        sign("calm.face.sign.puffiness", record.result.puffiness)
                        sign("calm.face.sign.dark_circles", record.result.darkCircles)
                        sign("calm.face.sign.jaw", record.result.jawTension)
                        sign("calm.face.sign.skin", record.result.skinDullness)
                    }

                    if !record.result.summary.isEmpty {
                        Text(record.result.summary)
                            .font(.system(size: 16))
                            .lineSpacing(4)
                            .foregroundStyle(.white.opacity(0.95))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .cfGlass(cornerRadius: 20)
                    }
                    if !record.result.tip.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AudioPalette.backgroundDeep)
                                .frame(width: 30, height: 30)
                                .background(AudioPalette.accent, in: Circle())
                            Text(record.result.tip)
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AudioPalette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    if store.currentCycleRecords.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(t("calm.face.progress"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AudioPalette.accent)
                            HStack(spacing: 8) {
                                ForEach(store.currentCycleRecords) { item in
                                    VStack(spacing: 4) {
                                        if let image = store.image(for: item) {
                                            Image(uiImage: image).resizable().scaledToFill()
                                                .frame(width: 58, height: 74)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                        Text(String(format: t("calm.face.day"), FaceScanStore.slotDays[item.slot]))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(AudioPalette.secondaryText)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(t("calm.face.disclaimer"))
                        .font(.system(size: 11))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
            primary(t("calm.common.done")) { dismiss() }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
    }

    private func sign(_ key: String, _ level: FaceScanResult.Level) -> some View {
        HStack {
            Text(t(key))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Spacer(minLength: 4)
            Text(t("calm.face.level.\(level.rawValue)"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(level == .high ? Color(hex: "FFB86B") : level == .medium ? AudioPalette.accent : Color(hex: "6FE3B4"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Front camera selfie (UIImagePickerController keeps it simple and familiar).
struct SelfieCamera: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void
        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onFinish(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onFinish(nil) }
    }
}
