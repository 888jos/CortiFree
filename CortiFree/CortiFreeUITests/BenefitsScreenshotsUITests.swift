//
//  BenefitsScreenshotsUITests.swift
//  CortiFreeUITests
//
//  Captures the feature-tour screenshots shown after the pre-paywall, once per app language.
//  Run on an iPhone simulator where onboarding is done (the app opens on Home):
//
//    TEST_RUNNER_SHOTS_DIR=/path/to/out xcodebuild test -scheme CortiFree \
//      -destination 'platform=iOS Simulator,name=iPhone 15' \
//      -only-testing:CortiFreeUITests/BenefitsScreenshotsUITests
//
//  Files: <SHOTS_DIR>/<page>_<lang>.png (page = home, plan, library, breathing, meditation = player).
//  TEST_RUNNER_PAGES=meditation,plan and TEST_RUNNER_LANGS=fr,ja limit the capture.
//  Taps use screen coordinates: the tab bar labels change with the language.
//

import XCTest

final class BenefitsScreenshotsUITests: XCTestCase {

    private let languages = ["en", "fr", "de", "es", "ja", "ko"]

    // Normalized positions on an iPhone 15 (393 × 852 pt).
    private enum Spot {
        static let tabHome = CGVector(dx: 0.153, dy: 0.920)
        static let tabPlan = CGVector(dx: 0.326, dy: 0.920)
        static let tabLibrary = CGVector(dx: 0.672, dy: 0.920)
        static let breathingTile = CGVector(dx: 0.150, dy: 0.755)
        static let meditationTile = CGVector(dx: 0.384, dy: 0.755)
        static let firstMeditation = CGVector(dx: 0.267, dy: 0.405)
        static let firstExercisePlay = CGVector(dx: 0.860, dy: 0.455)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureBenefitsScreenshots() throws {
        let env = ProcessInfo.processInfo.environment
        let outDir = env["SHOTS_DIR"] ?? NSTemporaryDirectory()
        let pages = Set((env["PAGES"] ?? "home,plan,library,meditation,breathing").split(separator: ",").map(String.init))
        try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

        let langs = env["LANGS"].map { $0.split(separator: ",").map(String.init) } ?? languages
        for lang in langs {
            let app = XCUIApplication()
            // Argument domain: overrides the in-app language for this launch only.
            app.launchArguments = ["-selectedLanguage", lang, "-AppleLanguages", "(\(lang))"]
            app.launch()
            pause(4)

            func tap(_ spot: CGVector, wait: TimeInterval = 2.5) {
                app.coordinate(withNormalizedOffset: spot).tap()
                pause(wait)
            }
            func shot(_ page: String) throws {
                let data = XCUIScreen.main.screenshot().pngRepresentation
                try data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent("\(page)_\(lang).png"))
            }

            if pages.contains("home") { tap(Spot.tabHome); try shot("home") }
            if pages.contains("plan") { tap(Spot.tabPlan); try shot("plan") }
            if pages.contains("library") { tap(Spot.tabLibrary); try shot("library") }
            if pages.contains("breathing") {
                tap(Spot.tabHome)
                tap(Spot.breathingTile)
                tap(Spot.firstExercisePlay, wait: 6)
                try shot("breathing")
                app.terminate()
                app.launch()
                pause(4)
            }
            // Last: the full-screen player keeps playing (mini player) once opened.
            if pages.contains("meditation") {
                tap(Spot.tabHome)
                tap(Spot.meditationTile, wait: 3)
                tap(Spot.firstMeditation, wait: 15) // the session may still be preparing
                try shot("meditation")
            }

            app.terminate()
        }
    }

    private func pause(_ seconds: TimeInterval) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }
}
