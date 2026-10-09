//
//  BalancedText.swift
//  CortiFree
//
//  Balanced line breaks (the web's `text-wrap: balance`): a text that wraps keeps
//  its number of lines but takes the narrowest width that still allows it, so its
//  lines come out about the same length instead of one long line and a lonely
//  word. It works on the laid-out text, so it is right for every language.
//  Text that fits on one line is left exactly as it is.
//
//  Use it on text that is free to grow vertically (no `lineLimit`): with a line
//  limit, a narrower width would truncate instead of wrapping.
//

import SwiftUI

extension View {
    /// Balances the line breaks of this (multi-line) text.
    /// - Parameter alignment: where the balanced block sits when it is given more
    ///   width than it needs; match the text's `multilineTextAlignment`.
    func balancedLines(alignment: HorizontalAlignment = .center) -> some View {
        BalancedTextLayout(alignment: alignment) { self }
    }
}

struct BalancedTextLayout: Layout {
    var alignment: HorizontalAlignment

    struct Cache {
        var maxWidth: CGFloat = -1
        var size: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        guard let text = subviews.first else { return .zero }
        guard let width = proposal.width, width.isFinite, width > 0 else {
            return text.sizeThatFits(proposal)
        }
        return balancedSize(of: text, maxWidth: width, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        guard let text = subviews.first else { return }
        let size = balancedSize(of: text, maxWidth: bounds.width, cache: &cache)
        let x: CGFloat
        switch alignment {
        case .leading: x = bounds.minX
        case .trailing: x = bounds.maxX - size.width
        default: x = bounds.midX - size.width / 2
        }
        text.place(at: CGPoint(x: x, y: bounds.minY),
                   anchor: .topLeading,
                   proposal: ProposedViewSize(width: size.width, height: size.height))
    }

    private func balancedSize(of text: LayoutSubview, maxWidth: CGFloat, cache: inout Cache) -> CGSize {
        if abs(cache.maxWidth - maxWidth) < 0.5 { return cache.size }

        let full = text.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
        let oneLine = text.sizeThatFits(.unspecified)
        var result = full

        // Wraps: find the narrowest width that keeps the same height (= same lines).
        if oneLine.width > maxWidth + 0.5, oneLine.height > 0, full.height > oneLine.height + 0.5 {
            let lines = max(1, (full.height / oneLine.height).rounded())
            var tooNarrow = max(1, oneLine.width / lines - 1)
            var fits = min(full.width, maxWidth)
            while fits - tooNarrow > 1 {
                let mid = (tooNarrow + fits) / 2
                let height = text.sizeThatFits(ProposedViewSize(width: mid, height: nil)).height
                // Taller = one more line; shorter = the font scaled down. Only the
                // same height means the same lines at full size.
                if abs(height - full.height) < 0.5 {
                    fits = mid
                } else {
                    tooNarrow = mid
                }
            }
            result = CGSize(width: min(maxWidth, fits.rounded(.up)), height: full.height)
        }

        cache = Cache(maxWidth: maxWidth, size: result)
        return result
    }
}
