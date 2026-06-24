//
//  SetupModeMigrationTests.swift
//  Simple Photo ViewerTests
//

import XCTest
@testable import Simple_Photo_Viewer

final class SetupModeMigrationTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "SetupModeMigrationTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func testMigratesLegacyFalseValue() {
        defaults.set(false, forKey: "showAlbumViewSettings")
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertEqual(defaults.object(forKey: "isSetupMode") as? Bool, false)
        XCTAssertNil(defaults.object(forKey: "showAlbumViewSettings"))
    }

    func testMigratesLegacyTrueValue() {
        defaults.set(true, forKey: "showAlbumViewSettings")
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertEqual(defaults.object(forKey: "isSetupMode") as? Bool, true)
        XCTAssertNil(defaults.object(forKey: "showAlbumViewSettings"))
    }

    func testNoLegacyKeyLeavesNewKeyUnset() {
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertNil(defaults.object(forKey: "isSetupMode"))
    }

    func testDoesNotOverwriteExistingNewKey() {
        defaults.set(false, forKey: "isSetupMode")
        defaults.set(true, forKey: "showAlbumViewSettings")
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertEqual(defaults.object(forKey: "isSetupMode") as? Bool, false)
    }
}
