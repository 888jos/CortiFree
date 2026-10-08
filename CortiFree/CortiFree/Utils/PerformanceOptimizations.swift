//
//  PerformanceOptimizations.swift
//  CortiFree
//
//  Optimisations globales pour améliorer les performances sur iPhone
//

import SwiftUI

class PerformanceManager {
    static let shared = PerformanceManager()

    private init() {}

    // MARK: - App Launch Optimizations

    func configureForOptimalPerformance() {
        // 1. Reduce animation complexity
        configureAnimations()

        // 2. Configure image caching
        configureImageCaching()

        // 3. Optimize memory usage
        configureMemoryManagement()
    }

    private func configureAnimations() {
        // Reduce animation duration globally
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: 0) {
            UIView.setAnimationDuration(0.2) // Faster animations
        }
    }

    private func configureImageCaching() {
        // Increase URL cache size
        let memoryCapacity = 50 * 1024 * 1024 // 50MB
        let diskCapacity = 200 * 1024 * 1024 // 200MB
        let urlCache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "CortiFreeImageCache"
        )
        URLCache.shared = urlCache
    }

    private func configureMemoryManagement() {
        // Register for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        // Clear caches when memory is low
        URLCache.shared.removeAllCachedResponses()
        print("⚠️ Memory warning - cleared caches")
    }
}

// MARK: - Optimized View Modifiers

extension View {
    /// Use lazy loading for heavy views
    func lazyLoad() -> some View {
        self.drawingGroup() // Rasterize complex views
            .compositingGroup() // Flatten view hierarchy
    }

    /// Optimize for scrolling performance
    func optimizedForScrolling() -> some View {
        self
            .drawingGroup()
            .clipped()
    }

    /// Reduce animation complexity
    func lightAnimation() -> some View {
        self.animation(.easeInOut(duration: AppConstants.Animation.standardDuration))
    }
}

// MARK: - Optimized Galaxy Background

struct LightweightGalaxyBackground: View {
    var body: some View {
        // Simple gradient instead of complex animation
        LinearGradient(
            colors: [
                Color(hex: "0A0515"),
                Color(hex: "1a0a2e"),
                Color(hex: "0A0515")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Performance Tips

/*
 TIPS FOR BETTER PERFORMANCE:

 1. Replace heavy backgrounds:
    - Instead of: GalaxyBackgroundView(intensity: 1.0)
    - Use: LightweightGalaxyBackground()

 2. Optimize navigation:
    - Use .lazy modifier on heavy views
    - Preload next view before navigation

 3. Reduce Firebase calls:
    - Batch writes when possible
    - Use local cache first
    - Implement pagination for large datasets

 4. Image optimization:
    - Use smaller image sizes
    - Implement lazy loading for images
    - Cache processed images

 5. Animation optimization:
    - Use .lightAnimation() instead of complex animations
    - Disable animations on older devices
    - Reduce particle effects

 6. Memory management:
    - Release unused resources
    - Clear caches periodically
    - Use weak references where appropriate
 */
