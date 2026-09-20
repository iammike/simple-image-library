//
//  DynamicTypeUITests.swift
//  Simple Photo ViewerUITests
//
//  Album names must respond both to the caregiver's in-app preset and to the system
//  text size, because the two compose: the preset is a `.custom(size:relativeTo:.body)`
//  font. Both are checked by measuring the label's frame, which is the only thing
//  XCUITest can see. It is a coarse check, but it catches a font that stopped scaling,
//  which is the failure that actually happens.
//
//  The system text size is set with the `-UIPreferredContentSizeCategoryName` launch
//  argument. It is a defaults key UIKit reads at launch, so it needs no app change and
//  no Settings-app automation.
//
//  A cold launch at the largest accessibility category costs real time -- UIKit is
//  laying out much bigger text -- and this method makes two such launches back to
//  back. Measured at 14-16s for one launch alone (see #107); 20s left too thin a
//  margin for the second, so this waits longer rather than asserting sooner than a
//  real launch can finish.
//

import XCTest

final class DynamicTypeUITests: ViewerUITestCase {

    private let measuredAlbum = "Fixture Charlie"
    private let launchTimeout: TimeInterval = 40

    private func albumNameHeight(
        extraDefaults: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CGFloat {
        let app = ViewerApp.launch(screen: .viewer, extraDefaults: extraDefaults)
        let label = app.staticTexts[measuredAlbum]
        XCTAssertTrue(label.waitForExistence(timeout: launchTimeout), file: file, line: line)
        let height = label.frame.height
        app.terminate()
        return height
    }

    /// The system text size reaches the album names.
    func testAlbumNamesGrowWithTheSystemTextSize() throws {
        let standard = albumNameHeight(
            extraDefaults: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"]
        )
        let accessibility = albumNameHeight(
            extraDefaults: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL"
            ]
        )

        XCTAssertGreaterThan(
            accessibility, standard * 1.5,
            "Album names did not grow with the system text size "
                + "(\(standard)pt -> \(accessibility)pt)"
        )
    }

    /// The caregiver's preset reaches the album names, independently of the system
    /// setting. The preset is persisted under `albumNameTextSize`, so a launch
    /// argument sets it without walking through Setup.
    func testAlbumNamesGrowWithTheCaregiverPreset() throws {
        let small = albumNameHeight(extraDefaults: ["-albumNameTextSize", "small"])
        let extraLarge = albumNameHeight(extraDefaults: ["-albumNameTextSize", "extraLarge"])

        XCTAssertGreaterThan(
            extraLarge, small * 1.5,
            "The album name preset did not change the label size "
                + "(\(small)pt -> \(extraLarge)pt)"
        )
    }
}
