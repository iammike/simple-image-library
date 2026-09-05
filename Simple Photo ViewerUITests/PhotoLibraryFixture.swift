//
//  PhotoLibraryFixture.swift
//  Simple Photo ViewerUITests
//
//  Seeds the simulator's photo library with named user albums.
//
//  Why here: `xcrun simctl addmedia` can only drop files into the library, where they
//  surface under the "Recents" smart album; it cannot create a named user album. The
//  app under test only reads the library and must not grow album-creation code. But
//  the XCUITest *runner* is a separate application with its own bundle identifier,
//  its own Photos authorization and its own Photos entitlement, and it shares the
//  simulator's single system photo library with the app. So the runner builds the
//  fixture and the app sees it.
//
//  The seed is idempotent by album title: an album that already holds the expected
//  number of assets is left alone, so a warm device re-runs in well under a second.
//

import Photos
import UIKit
import XCTest

enum PhotoLibraryFixture {

    struct AlbumSpec {
        let name: String
        let assetCount: Int
        let color: UIColor
    }

    /// Distinct names so a test can name the album it hides, and distinct colors so a
    /// failure screenshot says which album's photos are on screen.
    static let specs: [AlbumSpec] = [
        AlbumSpec(name: "Fixture Alpha", assetCount: 3, color: .systemRed),
        AlbumSpec(name: "Fixture Bravo", assetCount: 2, color: .systemGreen),
        AlbumSpec(name: "Fixture Charlie", assetCount: 4, color: .systemBlue)
    ]

    /// Added by `seedExtraAlbum()` only, to exercise pull-to-refresh discovering an
    /// album that did not exist when the app launched.
    static let lateAlbum = AlbumSpec(name: "Fixture Delta", assetCount: 2, color: .systemPurple)

    // MARK: - Authorization

    /// Brings the runner process to `.authorized`, tapping the system alert if it appears.
    /// Runs the main run loop while waiting so the out-of-process alert can be driven.
    static func ensureAuthorized(timeout: TimeInterval = 30) throws {
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized { return }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }

        // The alert can take a moment to appear, and a stale alert left by an earlier
        // run can be dismissed before this one shows, so keep looking for the whole
        // window rather than tapping once.
        let deadline = Date().addingTimeInterval(timeout)
        while PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized,
              Date() < deadline {
            SystemAlerts.allowFullPhotoAccess(timeout: 1)
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.25))
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized else {
            throw FixtureError.notAuthorized(status)
        }
    }

    // MARK: - Seeding

    /// Creates any of `specs` that the library does not already hold.
    static func seed() throws {
        try ensureAuthorized()
        for spec in specs { try ensureAlbum(spec) }
    }

    /// Creates the album that pull-to-refresh is expected to discover.
    static func seedLateAlbum() throws {
        try ensureAuthorized()
        try ensureAlbum(lateAlbum)
    }

    /// Removes the late album so a re-run starts from the same place. Its assets stay
    /// behind in Recents, which no test counts.
    ///
    /// iOS puts up "Allow ... to delete the album ...?" for this, even though the
    /// runner created the album itself. `performChangesAndWait` on the test's main
    /// thread deadlocks against that alert — it blocks the only thread that could tap
    /// it — so the change is made asynchronously while the alert is being answered.
    static func removeLateAlbum() throws {
        try ensureAuthorized()
        guard let existing = fetchAlbum(named: lateAlbum.name) else { return }
        try performChangeAnsweringSystemAlert {
            PHAssetCollectionChangeRequest.deleteAssetCollections([existing] as NSArray)
        }
    }

    private static func performChangeAnsweringSystemAlert(
        timeout: TimeInterval = 30,
        _ changes: @escaping () -> Void
    ) throws {
        var finished = false
        var failure: Error?
        PHPhotoLibrary.shared().performChanges(changes) { _, error in
            DispatchQueue.main.async {
                failure = error
                finished = true
            }
        }

        let deadline = Date().addingTimeInterval(timeout)
        while !finished, Date() < deadline {
            SystemAlerts.confirmPhotoLibraryChange(timeout: 0.5)
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.25))
        }

        if let failure { throw failure }
        guard finished else { throw FixtureError.changeTimedOut }
    }

    private static func ensureAlbum(_ spec: AlbumSpec) throws {
        if let existing = fetchAlbum(named: spec.name),
           PHAsset.fetchAssets(in: existing, options: nil).count == spec.assetCount {
            return
        }

        let images = (0..<spec.assetCount).map { index in
            swatch(color: spec.color, index: index)
        }

        try PHPhotoLibrary.shared().performChangesAndWait {
            let albumRequest = PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(withTitle: spec.name)
            let placeholders = images.compactMap { image in
                PHAssetChangeRequest.creationRequestForAsset(from: image)
                    .placeholderForCreatedAsset
            }
            albumRequest.addAssets(placeholders as NSArray)
        }
    }

    // MARK: - Queries the tests assert against

    static func fetchAlbum(named name: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", name)
        return PHAssetCollection
            .fetchAssetCollections(with: .album, subtype: .any, options: options)
            .firstObject
    }

    static func assetCount(inAlbumNamed name: String) -> Int {
        guard let album = fetchAlbum(named: name) else { return 0 }
        return PHAsset.fetchAssets(in: album, options: nil).count
    }

    // MARK: - Images

    /// A flat swatch with a large index numeral: distinguishable in a failure
    /// screenshot without shipping any binary fixture into the repository. Sizes and
    /// creation dates are staggered so album ordering is stable between runs.
    private static func swatch(color: UIColor, index: Int) -> UIImage {
        let size = CGSize(width: 240, height: 240)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "\(index + 1)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 120),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2
                ),
                withAttributes: attributes
            )
        }
    }

    enum FixtureError: Error, CustomStringConvertible {
        case notAuthorized(PHAuthorizationStatus)
        case changeTimedOut

        var description: String {
            switch self {
            case .notAuthorized(let status):
                return "The UI test runner did not reach .authorized for Photos "
                    + "(status \(status.rawValue)). The permission alert was not "
                    + "dismissed, or the runner's Info.plist is missing "
                    + "NSPhotoLibraryUsageDescription."
            case .changeTimedOut:
                return "A photo-library change never completed. A system alert is "
                    + "probably still on screen with a button this fixture does not "
                    + "know the label of."
            }
        }
    }
}
