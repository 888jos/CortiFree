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
            .navigationTitle(NSLocalizedString("settings.bug_report.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("settings.bug_report.cancel", comment: "")) {
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
            Text(NSLocalizedString("settings.bug_report.description_label", comment: ""))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            TextEditor(text: $bugReportText)
                .frame(minHeight: 150)
                .padding(12)
                .background(Color(hex: "B794F6").opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "B794F6").opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("settings.bug_report.screenshot_label", comment: ""))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            if let screenshot = bugReportScreenshot {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: screenshot)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)

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
                        Text(NSLocalizedString("settings.bug_report.choose_image", comment: ""))
                            .font(.custom("Poppins-Medium", size: 14))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "B794F6").opacity(0.2))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "B794F6").opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var submitButton: some View {
        Button(action: {
            onSubmit()
        }) {
            Text(NSLocalizedString("settings.bug_report.submit", comment: ""))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(buttonBackground)
                .cornerRadius(12)
                .shadow(
                    color: bugReportText.isEmpty ? .clear : Color(hex: "7C3AED").opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        }
        .disabled(bugReportText.isEmpty)
    }

    private var buttonBackground: some ShapeStyle {
        if bugReportText.isEmpty {
            return AnyShapeStyle(Color.gray.opacity(0.5))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(hex: "7C3AED"), Color(hex: "5B21B6")],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
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
