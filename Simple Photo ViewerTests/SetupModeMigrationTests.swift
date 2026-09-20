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

    // MARK: - What a real migration also does

    /// A caregiver who had already left setup in 1.5 has used the app normally
    /// before; they should not be told to "start" it again.
    func testFalseLegacyValueMarksSetupAlreadyCompleted() {
        defaults.set(false, forKey: "showAlbumViewSettings")
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertEqual(defaults.bool(forKey: "hasCompletedSetup"), true)
    }

    /// A caregiver who was mid-setup when they upgraded has not necessarily used the
    /// app before; a single legacy bit cannot tell "brand new" from "returning to
    /// setup", so the conservative case is left alone rather than guessed at.
    func testTrueLegacyValueDoesNotMarkSetupCompleted() {
        defaults.set(true, forKey: "showAlbumViewSettings")
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertNil(defaults.object(forKey: "hasCompletedSetup"))
    }

    /// A real migration always flags the one-time notice that Setup moved, whichever
    /// way the legacy value pointed.
    func testMigrationFlagsTheMovedNoticeRegardlessOfLegacyValue() {
        defaults.set(true, forKey: "showAlbumViewSettings")
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertTrue(defaults.bool(forKey: "showsMovedFromSettingsNotice"))
    }

    /// A fresh install has no legacy key, so it must never see the "moved" notice --
    /// there is nothing that moved for a caregiver who never had 1.5.
    func testFreshInstallNeverFlagsTheMovedNotice() {
        ViewModel.migrateSetupModeKey(in: defaults)
        XCTAssertNil(defaults.object(forKey: "showsMovedFromSettingsNotice"))
    }
}
