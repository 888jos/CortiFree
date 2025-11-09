//
//  DiagnosticResultView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Diagnostic result screen with histogram
//

import SwiftUI

struct DiagnosticResultView: View {
    let cortisolDifference: Int // e.g., 38 for +38%
    let onContinue: () -> Void

    @State private var showBars: Bool = false
    @State private var showPercentages: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0A0B1E")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Title with checkmark
                    HStack(spacing: 12) {
                        // Checkmark circle (same as quiz)
                        ZStack {
                            Circle()
                                .fill(Color(hex: "3FB63D"))
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.custom("Poppins-Bold", size: 14))
                                .foregroundColor(.white)
                        }

                        Text("Analyse terminée")
                            .font(.custom("SF Pro Rounded-Heavy", size: 32))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 36)

                    // Announcement text
                    Text("Nous avons des nouvelles à t'annoncer…")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 36)

                    // Main result text
                    Text("Tes réponses indiquent clairement un taux de cortisol trop élevé*")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(Color(hex: "FF4D50"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 20)
                        .padding(.horizontal, 36)

                    // Histogram
                    histogramView
                        .padding(.top, 40)

                    // Stats comparison
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color(hex: "FF4D50"))
                                .frame(width: 10, height: 10)

                            Text("Ton niveau actuel")
                                .font(.custom("Poppins-Medium", size: 13))
                                .foregroundColor(.white)

                            Spacer()

                            Text("+\(cortisolDifference)%")
                                .font(.custom("Poppins-Bold", size: 13))
                                .foregroundColor(Color(hex: "FF4D50"))
                        }

                        HStack {
                            Circle()
                                .fill(Color(hex: "3FB63D"))
                                .frame(width: 10, height: 10)

                            Text("Niveau recommandé")
                                .font(.custom("Poppins-Medium", size: 13))
                                .foregroundColor(.white)

                            Spacer()

                            Text("Normal")
                                .font(.custom("Poppins-Bold", size: 13))
                                .foregroundColor(Color(hex: "3FB63D"))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.horizontal, 36)
                    .padding(.top, 24)

                    Spacer()
                        .frame(height: 40)

                    // CTA Button
                    Button(action: {
                        HapticManager.light()
                        onContinue()
                    }) {
                        Text("Vérifie tes symptômes")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "4169E1"))
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .padding(.horizontal, 34)

                    // Disclaimer
                    Text("* Ce résultat est donné à titre indicatif uniquement et ne constitue pas un diagnostic médical.")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(Color(hex: "D9D9D9").opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Animate bars
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showBars = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
                showPercentages = true
            }
        }
    }

    // MARK: - Histogram View

    private var histogramView: some View {
        HStack(alignment: .bottom, spacing: 40) {
            // Bar 1 - User (Toi) - Rouge
            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "FF4D50"))
                            .frame(width: 40, height: showBars ? 210 : 0)
                    }

                    // Percentage inside bar
                    if showPercentages {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Text("\(100 + cortisolDifference)%")
                                .font(.custom("Poppins-Bold", size: 13))
                                .foregroundColor(.white)
                                .padding(.bottom, 210 - 25)
                        }
                    }
                }
                .frame(height: 210)

                Text("Ton score")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.white)
            }

            // Bar 2 - Average (Moyenne) - Verte
            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "3FB63D"))
                            .frame(width: 40, height: showBars ? 120 : 0)
                    }

                    // Percentage inside bar
                    if showPercentages {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Text("100%")
                                .font(.custom("Poppins-Bold", size: 13))
                                .foregroundColor(.white)
                                .padding(.bottom, 120 - 25)
                        }
                    }
                }
                .frame(height: 210)

                Text("Moyenne")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DiagnosticResultView(cortisolDifference: 38, onContinue: {})
}
