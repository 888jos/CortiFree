import SwiftUI

/// One-time disclosure shown before the first message is sent to the AI provider.
/// Also used, with its own points, before the first weekly face check (selfie → OpenAI).
struct MiloConsentSheet: View {
    var titleKey = "assistant.consent.title"
    var points: [(icon: String, key: String)] = [
        ("server.rack", "assistant.consent.point.provider"),
        ("list.bullet.rectangle", "assistant.consent.point.plan"),
        ("mic.fill", "assistant.consent.point.voice"),
        ("heart.text.square", "assistant.consent.point.health"),
        ("stethoscope", "assistant.consent.point.diagnosis"),
        ("hand.raised.fill", "assistant.consent.point.revoke")
    ]
    var acceptKey = "assistant.consent.accept"
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Image("cortifree_assistant_avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 28)

                        Text(LanguageManager.shared.localizedString(for: titleKey))
                            .font(.custom("Poppins-SemiBold", size: 22))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        ForEach(points, id: \.key) { point(icon: $0.icon, key: $0.key) }

                        Button {
                            LegalDocumentsHelper.openPrivacyPolicy()
                        } label: {
                            Text(LanguageManager.shared.localizedString(for: "assistant.consent.privacy"))
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundStyle(Color.appTheme)
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }

                VStack(spacing: 10) {
                    Button(action: onAccept) {
                        Text(LanguageManager.shared.localizedString(for: acceptKey))
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.appTheme, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDecline) {
                        Text(LanguageManager.shared.localizedString(for: "assistant.consent.decline"))
                            .font(.custom("Poppins-Medium", size: 15))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func point(icon: String, key: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.appTheme)
                .frame(width: 26)
            Text(LanguageManager.shared.localizedString(for: key))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
