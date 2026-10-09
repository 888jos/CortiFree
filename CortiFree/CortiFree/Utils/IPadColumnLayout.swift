//
//  IPadColumnLayout.swift
//  CortiFree
//
//  iPad only: the app keeps its iPhone layout, centred in a readable column,
//  while full-bleed backgrounds (`.ignoresSafeArea()`) still cover the whole
//  screen. Done by widening the horizontal safe area of every full-screen
//  SwiftUI hosting controller (the window root and every fullScreenCover), so
//  no screen has to opt in. Nothing here runs on iPhone.
//

import SwiftUI
import UIKit

enum IPadColumnLayout {
    static let isPad = UIDevice.current.userInterfaceIdiom == .pad

    /// Width of the centred content column on iPad.
    static let columnWidth: CGFloat = 620

    /// Width available to content: the screen on iPhone, the column on iPad.
    static var contentWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return isPad ? min(screenWidth, columnWidth) : screenWidth
    }

    /// Call once at launch. No-op on iPhone.
    static func install() {
        guard isPad, !installed else { return }
        installed = true
        // Before layout, so SwiftUI's very first pass already sees the column: a
        // width change landing just after a screen appears gets caught by its
        // `repeatForever` animations and the whole layout keeps swinging.
        swizzle(#selector(UIViewController.viewWillLayoutSubviews),
                with: #selector(UIViewController.cf_iPadColumn_viewWillLayoutSubviews))
        // After layout too, in case a hosting controller skips `super` above.
        swizzle(#selector(UIViewController.viewDidLayoutSubviews),
                with: #selector(UIViewController.cf_iPadColumn_viewDidLayoutSubviews))
    }

    private static func swizzle(_ original: Selector, with replacement: Selector) {
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, original),
              let replacementMethod = class_getInstanceMethod(UIViewController.self, replacement) else { return }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }

    private static var installed = false
}

extension View {
    /// iPad: let this view (a banner, a backdrop) run past the content column to
    /// the screen edges. Returns the view untouched on iPhone.
    @ViewBuilder
    func iPadFullBleed() -> some View {
        if IPadColumnLayout.isPad {
            ignoresSafeArea(edges: .horizontal)
        } else {
            self
        }
    }

    /// iPad: present this sheet as a tall page instead of the small centred
    /// form sheet (for content that needs room, like the Milo chat).
    /// Returns the view untouched on iPhone.
    @ViewBuilder
    func iPadPageSheet() -> some View {
        if IPadColumnLayout.isPad {
            presentationSizing(.page)
        } else {
            self
        }
    }
}

extension UIViewController {
    @objc fileprivate func cf_iPadColumn_viewWillLayoutSubviews() {
        cf_iPadColumn_applyColumnInsets()
        cf_iPadColumn_viewWillLayoutSubviews() // original implementation (swizzled)
    }

    @objc fileprivate func cf_iPadColumn_viewDidLayoutSubviews() {
        cf_iPadColumn_viewDidLayoutSubviews() // original implementation (swizzled)
        cf_iPadColumn_applyColumnInsets()
    }

    private func cf_iPadColumn_applyColumnInsets() {
        guard isFullScreenSwiftUIScreen else { return }
        let width = view.window?.bounds.width ?? view.bounds.width
        guard width > 0 else { return }

        // Extra side inset = what is left of the screen around the column, minus
        // any inset the system already gives (e.g. none on iPad, kept for safety).
        let systemInsets = view.safeAreaInsets.left - additionalSafeAreaInsets.left
        let inset = max(0, (width - IPadColumnLayout.columnWidth) / 2 - max(0, systemInsets))
        let rounded = inset.rounded()
        guard abs(additionalSafeAreaInsets.left - rounded) > 0.5
                || abs(additionalSafeAreaInsets.right - rounded) > 0.5 else { return }
        additionalSafeAreaInsets.left = rounded
        additionalSafeAreaInsets.right = rounded
    }

    /// The window root, or a full-screen modal, hosting SwiftUI content.
    /// Form sheets, popovers, alerts and third-party UIKit screens are left alone.
    private var isFullScreenSwiftUIScreen: Bool {
        guard parent == nil,
              String(describing: type(of: self)).contains("HostingController") else { return false }
        if view.window?.rootViewController === self { return true }
        guard presentingViewController != nil else { return false }
        return modalPresentationStyle == .fullScreen || modalPresentationStyle == .overFullScreen
    }
}
