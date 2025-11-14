//
//  DistractionsComponents.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Shared components for distraction tracking screens
//

import SwiftUI

// MARK: - Segment Line

struct SegmentLine: View {
    let isActive: Bool
    let angle: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 2.25)
            .fill(isActive ? Color(hex: "FF2222") : Color.gray.opacity(0.3))
            .frame(width: 4.5, height: 18)
            .shadow(color: isActive ? Color(hex: "FF2222").opacity(0.8) : .clear, radius: 5, x: 0, y: 0)
            .shadow(color: isActive ? Color(hex: "FF2222").opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
            .offset(y: -75)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Custom Slider with Clock Thumb

struct SliderWithClockThumb: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>

    init(value: Binding<Double>, in range: ClosedRange<Double>) {
        self._value = value
        self.range = range
    }

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)

        let thumbSize: CGFloat = 48
        let thumbImage = createClockThumbImage(size: thumbSize)
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setThumbImage(thumbImage, for: .highlighted)

        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)

        return slider
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    private func createClockThumbImage(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            UIColor.white.setFill()
            let ovalPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            ovalPath.fill()

            let iconSize: CGFloat = 24
            let iconRect = CGRect(
                x: (size - iconSize) / 2,
                y: (size - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            if let clockImage = UIImage(systemName: "clock", withConfiguration: UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)) {
                UIColor.black.setFill()
                clockImage.withTintColor(.black, renderingMode: .alwaysOriginal).draw(in: iconRect)
            }
        }
        return image
    }

    class Coordinator: NSObject {
        var value: Binding<Double>

        init(value: Binding<Double>) {
            self.value = value
        }

        @objc func valueChanged(_ sender: UISlider) {
            value.wrappedValue = Double(sender.value)
        }
    }
}
