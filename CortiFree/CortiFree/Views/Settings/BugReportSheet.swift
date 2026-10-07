//
//  BugReportSheet.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Extracted from SettingsView for better modularity
//

import SwiftUI

struct BugReportSheet: View {
    @Binding var bugReportText: String
    @Binding var bugReportScreenshot: UIImage?
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @State private var showImagePicker: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundView

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        descriptionSection
                        screenshotSection
                        Spacer(minLength: 20)
                        submitButton
                    }
                    .padding(24)
                }
            }
            .navigationTitle(LanguageManager.shared.localizedString(for: "settings.bug_report.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LanguageManager.shared.localizedString(for: "settings.bug_report.cancel")) {
                        onCancel()
                    }
                    .foregroundColor(Color(hex: "B794F6"))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $bugReportScreenshot)
            }
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [Color(hex: "1F0140"), Color(hex: "01000C")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString(for: "settings.bug_report.description_label"))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            TextEditor(text: $bugReportText)
                .frame(minHeight: 150)
                .padding(12)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .glassCard(cornerRadius: 18)
        }
    }

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString(for: "settings.bug_report.screenshot_label"))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            if let screenshot = bugReportScreenshot {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: screenshot)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(action: {
                        bugReportScreenshot = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color(hex: "B794F6")))
                    }
                    .padding(8)
                }
            } else {
                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20))
                        Text(LanguageManager.shared.localizedString(for: "settings.bug_report.choose_image"))
                            .font(.custom("Poppins-Medium", size: 14))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glassSecondary(tint: Color(hex: "B794F6"), cornerRadius: 18))
            }
        }
    }

    private var submitButton: some View {
        Button(action: {
            onSubmit()
        }) {
            Text(LanguageManager.shared.localizedString(for: "settings.bug_report.submit"))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glassPrimary(tint: Color(hex: "7C3AED")))
        .disabled(bugReportText.isEmpty)
    }
}

#Preview {
    BugReportSheet(
        bugReportText: .constant(""),
        bugReportScreenshot: .constant(nil),
        onSubmit: {},
        onCancel: {}
    )
}
