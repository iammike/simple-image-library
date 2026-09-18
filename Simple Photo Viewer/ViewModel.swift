//
//  ViewModel.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/23/24.
//

import SwiftUI
import Photos

class ViewModel: ObservableObject {
    @Published var images: [PHAsset] = []
    @Published var albums: [PHAssetCollection] = []
    @Published var albumSettings: [String: AlbumSettings] = [:]
    /// True when stored settings exist but could not be decoded. Visibility then fails
    /// closed: an album without an entry is hidden, not shown, until an adult acts in
    /// Setup. The alternative, showing everything an adult had hidden, is the one
    /// failure this app must not have.
    private(set) var albumSettingsFailedToDecode = false
    @Published var selectedAlbumIdentifier: String?
    /// Most recent asset in each album, keyed by album identifier, used as a cover.
    @Published var albumCoverAssets: [String: PHAsset] = [:]
    /// True when the current selection came from a tap rather than from the automatic
    /// selection made at launch or after a refresh.
    @Published var albumSelectionWasExplicit = false
    @Published var hasPhotoLibraryAccess: Bool = false
    @Published var photoLibraryAccessHasBeenChecked: Bool = false
    @Published var albumsLoaded: Bool = false
    /// True once the open album's fetch has come back with nothing to show. `images`
    /// is also empty while the first page is still loading, which must not read as empty.
    @Published var currentAlbumIsEmpty = false
    @Published var isSetupMode: Bool = true
    @Published var prefetchedImage: UIImage?
    @Published var livePhoto: PHLivePhoto?

    private var fetchOffset = 0
    private let fetchLimit = 250
    private var currentAlbum: PHAssetCollection?
    /// Guards against a second fetch starting while one for the same album and offset
    /// is still in flight -- the grid retriggers 'load more' on every layout pass
    /// near the last row, not just once.
    private var isLoadingMorePhotos = false
    private let decoder = JSONDecoder()
    var videoRequestID: PHImageRequestID?

    /// Where settings persist. Tests pass their own suite so they never touch the
    /// configuration of the app installed on the same simulator.
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ViewModel.migrateSetupModeKey(in: defaults)
        if defaults.object(forKey: "isSetupMode") != nil {
            isSetupMode = defaults.bool(forKey: "isSetupMode")
        } else {
            isSetupMode = true
        }
        loadAlbumSettings()
        checkPhotoLibraryAccess()
    }

    func toggleIsSettingsComplete() {
        isSetupMode.toggle()
        defaults.set(isSetupMode, forKey: "isSetupMode")
        // Tapping a name in setup also selects it; clearing keeps Done from pushing a grid.
        albumSelectionWasExplicit = false

        // The loaded album must still be one the viewer may see.
        if !isSetupMode {
            let currentAlbumIsVisible = currentAlbum.map(isVisible) ?? false
            if !currentAlbumIsVisible {
                selectFirstVisibleAlbum()
            }
        }
    }

    /// Default settings for albums not seen before. Both the initial fetch and the
    /// refresh must seed through here, or an album gets no entry and cannot be hidden.
    func seedMissingAlbumSettings(for albums: [PHAssetCollection]) {
        for album in albums where albumSettings[album.localIdentifier] == nil {
            albumSettings[album.localIdentifier] = AlbumSettings(isVisible: !albumSettingsFailedToDecode)
        }
    }

    /// An album with no stored settings counts as visible, unless the stored settings
    /// could not be read. Every visibility check goes through here so the default
    /// cannot diverge between call sites.
    func isVisible(_ album: PHAssetCollection) -> Bool {
        isVisibleAlbum(identifiedBy: album.localIdentifier)
    }

    /// Keyed by identifier so the rule can be exercised without a Photos object.
    func isVisibleAlbum(identifiedBy identifier: String) -> Bool {
        albumSettings[identifier]?.isVisible ?? !albumSettingsFailedToDecode
    }

    /// False once an adult has hidden every album.
    var hasVisibleAlbums: Bool {
        albums.contains(where: isVisible)
    }

    /// Drops the current album and the photos loaded from it.
    func clearSelectedAlbum() {
        selectedAlbumIdentifier = nil
        albumSelectionWasExplicit = false
        currentAlbum = nil
        fetchOffset = 0
        images = []
        currentAlbumIsEmpty = false
        // Any fetch still in flight for the album just left is now stale; do not let
        // it block a fetch for whatever album is selected next.
        isLoadingMorePhotos = false
    }

    /// Opens Setup after the parental gate succeeds.
    func enterSetup() {
        isSetupMode = true
        defaults.set(true, forKey: "isSetupMode")
    }

    /// One-time migration: rename the legacy `showAlbumViewSettings` key to `isSetupMode`.
    /// Only ever runs for a device that actually had the legacy key -- never for a
    /// fresh install -- so the two things it sets alongside the rename are safe to
    /// tie to "this device is a 1.5 upgrade", not just "this is a first launch".
    static func migrateSetupModeKey(in defaults: UserDefaults) {
        let legacyKey = "showAlbumViewSettings"
        let newKey = "isSetupMode"
        guard defaults.object(forKey: newKey) == nil,
              defaults.object(forKey: legacyKey) != nil else { return }
        let legacyValue = defaults.bool(forKey: legacyKey)
        defaults.set(legacyValue, forKey: newKey)
        defaults.removeObject(forKey: legacyKey)

        // A caregiver who had already left setup in 1.5 has, by definition, used the
        // app normally before; the first-run copy in Setup ("Start Using LE Viewer")
        // would be telling them to start something they already have.
        if !legacyValue {
            defaults.set(true, forKey: "hasCompletedSetup")
        }
        // Setup moving out of the iOS Settings app is invisible until they go
        // looking for it there and find nothing. Tell them once, the first time they
        // open Setup on this device.
        defaults.set(true, forKey: "showsMovedFromSettingsNotice")
    }

    func selectFirstVisibleAlbum() {
        // Albums can all vanish from Photos; clearing keeps stale photos off screen.
        guard !albums.isEmpty else {
            clearSelectedAlbum()
            return
        }

        if let firstVisibleAlbum = albums.first(where: { album in
            return isVisible(album)
        }) {
            selectAlbum(firstVisibleAlbum, explicit: false)
        } else {
            // Hiding albums gates what the viewer sees, so photos must not survive it.
            clearSelectedAlbum()
        }
    }

    /// Where an undecodable settings blob is kept. The next save overwrites the live
    /// key, so one bad read would otherwise be made permanent; this copy is never
    /// overwritten once written.
    static let unreadableAlbumSettingsKey = "albumSettings.unreadable"

    private func loadAlbumSettings() {
        guard let data = defaults.data(forKey: "albumSettings") else { return }
        do {
            var decoded = try JSONDecoder().decode([String: AlbumSettings].self, from: data)
            if migrateLegacyOrange(in: &decoded) {
                albumSettings = decoded
                saveAlbumSettings()
            } else {
                albumSettings = decoded
            }
        } catch {
            albumSettingsFailedToDecode = true
            if defaults.data(forKey: ViewModel.unreadableAlbumSettingsKey) == nil {
                defaults.set(data, forKey: ViewModel.unreadableAlbumSettingsKey)
            }
            print("Album settings could not be decoded; hiding every album until Setup is used: \(error)")
        }
    }

    /// An album already colored with the palette's retired orange (see
    /// `AlbumColorPalette.legacyOrange`) is remapped to what replaced it, so the ring
    /// goes back to meaning only that album instead of reading as app chrome.
    /// Returns whether anything changed, so the caller knows to persist the result.
    private func migrateLegacyOrange(in settings: inout [String: AlbumSettings]) -> Bool {
        var didMigrate = false
        for (identifier, setting) in settings where setting.colorHex == AlbumColorPalette.legacyOrange {
            settings[identifier] = AlbumSettings(
                isVisible: setting.isVisible,
                colorHex: AlbumColorPalette.replacementForLegacyOrange
            )
            didMigrate = true
        }
        return didMigrate
    }

    private func saveAlbumSettings() {
        do {
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(albumSettings)
            defaults.set(data, forKey: "albumSettings")
        } catch {
            print("Error saving album settings: \(error)")
        }
    }

    func checkPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                self.updateAccessStatus(newStatus)
            }
        } else {
            updateAccessStatus(status)
        }
    }

    private func updateAccessStatus(_ status: PHAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .authorized:
                self.hasPhotoLibraryAccess = true
                self.fetchAlbums()

            case .limited, .denied, .restricted, .notDetermined:
                self.hasPhotoLibraryAccess = false
                self.clearCachedData()

            @unknown default:
                self.hasPhotoLibraryAccess = false
                self.clearCachedData()
            }
            self.photoLibraryAccessHasBeenChecked = true
        }
    }

    private func clearCachedData() {
        self.albums.removeAll()
        self.images.removeAll()
    }

    private func processPhotoLibraryAccess(status: PHAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .authorized:
                self.hasPhotoLibraryAccess = true
            default:
                self.hasPhotoLibraryAccess = false
            }
        }
    }

    /// Every album holding media, newest first, with each album's newest asset, which
    /// also serves as its cover. Fetch once per album here, never in the sort comparator.
    private func fetchAlbumsWithCovers() -> (albums: [PHAssetCollection], covers: [String: PHAsset]) {
        let fetchOptions = PHFetchOptions()

        let allAlbumsFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        let allSmartAlbumsFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)

        let allAlbums = (allAlbumsFetchResult.objects(at: IndexSet(0..<allAlbumsFetchResult.count)) +
                         allSmartAlbumsFetchResult.objects(at: IndexSet(0..<allSmartAlbumsFetchResult.count)))
            .filter(albumContainsImagesAndVideos)

        var covers: [String: PHAsset] = [:]
        for album in allAlbums {
            let assetsFetchOptions = PHFetchOptions()
            assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            assetsFetchOptions.fetchLimit = 1
            if let asset = PHAsset.fetchAssets(in: album, options: assetsFetchOptions).firstObject {
                covers[album.localIdentifier] = asset
            }
        }

        let sortedAlbums = allAlbums.sorted {
            (covers[$0.localIdentifier]?.creationDate ?? Date.distantPast)
                > (covers[$1.localIdentifier]?.creationDate ?? Date.distantPast)
        }

        return (sortedAlbums, covers)
    }

    func fetchAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            let (sortedAlbums, covers) = self.fetchAlbumsWithCovers()

            DispatchQueue.main.async {
                self.albums = sortedAlbums
                self.albumCoverAssets = covers

                self.seedMissingAlbumSettings(for: sortedAlbums)

                self.selectFirstVisibleAlbum()
                self.albumsLoaded = true
            }
        }
    }

    func toggleAlbumVisibility(_ albumIdentifier: String) {
        // A missing entry means visible, so hiding must create one rather than bail.
        var updatedSettings = albumSettings[albumIdentifier] ?? AlbumSettings()
        updatedSettings.isVisible.toggle()
        albumSettings[albumIdentifier] = updatedSettings
        objectWillChange.send()
        saveAlbumSettings()
    }

    /// Cycles the album's assigned color (none -> palette colors -> none) and persists it.
    func setAlbumColor(_ albumIdentifier: String) {
        if var settings = albumSettings[albumIdentifier] {
            settings.colorHex = AlbumColorPalette.next(after: settings.colorHex)
            albumSettings[albumIdentifier] = settings
            objectWillChange.send()
        } else {
            print("Album didn't exist")
        }
        saveAlbumSettings()
    }

    /// Fetches and enumerates off the main thread -- this runs synchronously from a
    /// tap on iPhone (album row -> push) -- and applies the whole page in one mutation
    /// rather than one dispatch per asset, which used to mean up to 250 separate
    /// published changes, each triggering a re-render of every row observing this
    /// object.
    private func loadMorePhotosFromAlbum(_ album: PHAssetCollection) {
        guard !isLoadingMorePhotos else { return }
        isLoadingMorePhotos = true

        let albumIdentifier = album.localIdentifier
        let offset = fetchOffset
        let limit = fetchLimit

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)

            let assets = PHAsset.fetchAssets(in: album, options: options)
            let count = assets.count

            var newAssets: [PHAsset] = []
            if offset < count {
                let upperBound = min(offset + limit, count)
                newAssets.reserveCapacity(upperBound - offset)
                assets.enumerateObjects(at: IndexSet(offset..<upperBound)) { asset, _, _ in
                    newAssets.append(asset)
                }
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingMorePhotos = false

                // The selected album (or a fresh load of the same one) may have moved
                // on while this was in flight; a stale page must not be applied.
                guard self.currentAlbum?.localIdentifier == albumIdentifier,
                      self.fetchOffset == offset else { return }

                // Only a fresh load decides emptiness: a paging fetch under thumbnails
                // that are still on screen must not put an empty note above them.
                if offset == 0 {
                    self.currentAlbumIsEmpty = count == 0
                }
                guard !newAssets.isEmpty else { return }
                self.images.append(contentsOf: newAssets)
                self.fetchOffset += newAssets.count
            }
        }
    }

    func loadMorePhotos() {
        if let currentAlbum = currentAlbum {
            loadMorePhotosFromAlbum(currentAlbum)
        }
    }

    func getImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (result, _) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    func getLivePhoto(for asset: PHAsset, completion: @escaping (PHLivePhoto?) -> Void) {
        let manager = PHImageManager.default()
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        manager.requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { livePhoto, _ in
            DispatchQueue.main.async {
                completion(livePhoto)
            }
        }
    }

    func prefetchImageForNextIndex(currentIndex: Int) {
        let nextIndex = currentIndex + 1
        guard images.indices.contains(nextIndex) else { return }

        let nextAsset = images[nextIndex]
        getImage(for: nextAsset) { [weak self] downloadedImage in
            DispatchQueue.main.async {
                self?.prefetchedImage = downloadedImage
            }
        }
    }

    func getVideo(for asset: PHAsset, completion: @escaping (AVPlayerItem?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true

        if let requestID = videoRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            videoRequestID = nil
        }

        videoRequestID = PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, audioMix, info) in
            DispatchQueue.main.async {
                guard let avAsset = avAsset as? AVURLAsset else {
                    self.videoRequestID = nil
                    completion(nil)
                    return
                }

                let playerItem = AVPlayerItem(url: avAsset.url)
                self.videoRequestID = nil
                completion(playerItem)
            }
        }
    }

    func cancelVideoLoading() {
        if let requestID = videoRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            videoRequestID = nil
        }
    }

    private func albumContainsImagesAndVideos(_ album: PHAssetCollection) -> Bool {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        let assetCount = PHAsset.fetchAssets(in: album, options: fetchOptions).count
        return assetCount > 0
    }

    /// A tap on an album row. The album may already be selected from launch, so the
    /// tap is recorded either way; the iPhone push depends on it.
    func openAlbum(_ album: PHAssetCollection) {
        if selectedAlbumIdentifier == album.localIdentifier {
            albumSelectionWasExplicit = true
        } else {
            selectAlbum(album, explicit: true)
        }
    }

    /// - Parameter explicit: true for a user tap. Automatic selection fills the iPad's
    ///   second column but must not push a grid on iPhone.
    func selectAlbum(_ album: PHAssetCollection, explicit: Bool = true) {
        albumSelectionWasExplicit = explicit
        selectedAlbumIdentifier = album.localIdentifier
        currentAlbum = album
        fetchOffset = 0
        images = []
        currentAlbumIsEmpty = false
        // The previous album's fetch, if still in flight, must not block this one.
        isLoadingMorePhotos = false
        loadMorePhotosFromAlbum(album)
    }

    func refreshThumbnails() {
        DispatchQueue.main.async {
            self.fetchOffset = 0
            self.images.removeAll()
            self.loadMorePhotos()
        }
    }

    func refreshAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            let (sortedAlbums, covers) = self.fetchAlbumsWithCovers()

            DispatchQueue.main.async {
                let currentAlbumIdentifier = self.selectedAlbumIdentifier
                self.albums = sortedAlbums
                self.albumCoverAssets = covers

                self.seedMissingAlbumSettings(for: sortedAlbums)

                if let currentAlbumIdentifier = currentAlbumIdentifier,
                   self.albums.contains(where: { $0.localIdentifier == currentAlbumIdentifier }) {
                    self.selectedAlbumIdentifier = currentAlbumIdentifier
                } else {
                    self.selectFirstVisibleAlbum()
                }
                self.albumsLoaded = true
            }
        }
    }
}

/// A struct representing the settings for an album, including its visibility and optional color.
struct AlbumSettings: Codable {
    /// Indicates whether the album is visible.
    var isVisible: Bool

    /// Optional color (hex string) assigned to the album, or `nil` for no color.
    var colorHex: String?

    /// Coding keys for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case isVisible
        case colorHex
    }

    /// Initializes a new instance of `AlbumSettings`.
    /// - Parameters:
    ///   - isVisible: Whether the album is visible. Defaults to `true`.
    ///   - colorHex: Optional assigned color as a hex string. Defaults to `nil`.
    init(isVisible: Bool = true, colorHex: String? = nil) {
        self.isVisible = isVisible
        self.colorHex = colorHex
    }

    /// Initializes a new instance of `AlbumSettings` from a decoder.
    /// Tolerates data persisted by earlier versions that lacks newer keys.
    /// - Parameter decoder: The decoder to read data from, or `nil` for defaults.
    init(from decoder: Decoder?) {
        isVisible = true
        colorHex = nil

        if let decoder = decoder {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
                colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
            } catch {
                print("Error decoding AlbumSettings: \(error)")
            }
        }
    }

    /// Encodes this instance into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encodeIfPresent(colorHex, forKey: .colorHex)
    }
}
