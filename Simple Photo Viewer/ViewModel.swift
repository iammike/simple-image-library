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
    @Published var selectedAlbumIdentifier: String?
    @Published var hasPhotoLibraryAccess: Bool = false
    @Published var photoLibraryAccessHasBeenChecked: Bool = false
    @Published var isSettingsComplete: Bool = false

    private var fetchOffset = 0
    private let fetchLimit = 50
    private var currentAlbum: PHAssetCollection?
    private var allPhotos: PHFetchResult<PHAsset>
    private var loadedAlbumSettingsData: Data?
    private let decoder = JSONDecoder()
    var videoRequestID: PHImageRequestID?

    init() {
        isSettingsComplete = UserDefaults.standard.bool(forKey: "isSettingsComplete")
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        loadAlbumSettings()
        checkPhotoLibraryAccess()
    }

    func toggleIsSettingsComplete() {
        isSettingsComplete.toggle()
        UserDefaults.standard.set(isSettingsComplete, forKey: "isSettingsComplete")

        if let currentAlbumIdentifier = currentAlbum?.localIdentifier,
           let isCurrentAlbumVisible = albumSettings[currentAlbumIdentifier]?.isVisible,
           !isCurrentAlbumVisible {
            selectFirstVisibleAlbum()
        }
    }

    func selectFirstVisibleAlbum() {
        guard !albums.isEmpty else { return }

        if let firstVisibleAlbum = albums.first(where: { album in
            return albumSettings[album.localIdentifier]?.isVisible ?? false
        }) {
            selectAlbum(firstVisibleAlbum)
        }
    }


    private func loadAlbumSettings() {
        if let data = UserDefaults.standard.data(forKey: "albumSettings") {
            let jsonDecoder = JSONDecoder()
            if let decodedSettings = try? jsonDecoder.decode([String: AlbumSettings].self, from: data) {
                self.albumSettings = decodedSettings
            }
        }
    }

    private func saveAlbumSettings() {
        do {
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(albumSettings)
            UserDefaults.standard.set(data, forKey: "albumSettings")
        } catch {
            print("Error saving album settings: \(error)")
        }
    }

    func checkPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        updateAccessStatus(status)
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
    
    func fetchAlbums() {
        let fetchOptions = PHFetchOptions()

        let allAlbumsFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        let allSmartAlbumsFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)

        let allAlbums = (allAlbumsFetchResult.objects(at: IndexSet(0..<allAlbumsFetchResult.count)) +
                         allSmartAlbumsFetchResult.objects(at: IndexSet(0..<allSmartAlbumsFetchResult.count)))
            .filter(albumContainsImagesAndVideos)

        func latestAssetDate(in album: PHAssetCollection) -> Date? {
            let assetsFetchOptions = PHFetchOptions()
            assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            assetsFetchOptions.fetchLimit = 1
            let assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)
            return assets.firstObject?.creationDate
        }

        let sortedAlbums = allAlbums.sorted {
            latestAssetDate(in: $0) ?? Date.distantPast > latestAssetDate(in: $1) ?? Date.distantPast
        }

        DispatchQueue.main.async {
            self.albums = sortedAlbums

            sortedAlbums.forEach { album in
                if self.albumSettings[album.localIdentifier] == nil {
                    if let data = UserDefaults.standard.data(forKey: "albumSettings") {
                        let jsonDecoder = JSONDecoder()
                        if let decodedSettings = try? jsonDecoder.decode(AlbumSettings.self, from: data) {
                            self.albumSettings[album.localIdentifier] = decodedSettings
                        }
                    } else {
                        let dummyDecoder: Decoder? = nil
                        self.albumSettings[album.localIdentifier] = AlbumSettings(from: dummyDecoder)
                    }
                }
            }

            self.selectFirstVisibleAlbum()
        }
    }


    func toggleAlbumVisibility(_ albumIdentifier: String) {
        if let settings = albumSettings[albumIdentifier] {
            var updatedSettings = settings
            updatedSettings.isVisible.toggle()
            albumSettings[albumIdentifier] = updatedSettings
            objectWillChange.send()
        } else {
            print("Album didn't exist")
        }
        saveAlbumSettings() // will need this in the color toggle too
    }

    private func loadMorePhotosFromAlbum(_ album: PHAssetCollection) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        
        let assets = PHAsset.fetchAssets(in: album, options: options)
        let count = assets.count
        guard fetchOffset < count else {
            return // No more photos to fetch
        }
        
        let upperBound = min(fetchOffset + fetchLimit, count)
        assets.enumerateObjects(at: IndexSet(fetchOffset..<upperBound)) { asset, _, _ in
            DispatchQueue.main.async {
                self.images.append(asset)
            }
        }
        fetchOffset += min(fetchLimit, count - fetchOffset)
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
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (result, _) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    func getVideo(for asset: PHAsset, completion: @escaping (AVPlayerItem?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true

        if let requestID = videoRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, audioMix, info) in
            DispatchQueue.main.async {
                guard let avAsset = avAsset as? AVURLAsset else {
                    completion(nil)
                    return
                }

                let playerItem = AVPlayerItem(url: avAsset.url)
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
    
    func selectAlbum(_ album: PHAssetCollection) {
        selectedAlbumIdentifier = album.localIdentifier
        currentAlbum = album
        fetchOffset = 0
        images = []
        loadMorePhotosFromAlbum(album)
    }
    
    func refreshThumbnails() {
        DispatchQueue.main.async {
            self.fetchOffset = 0
            self.images.removeAll()
            self.loadMorePhotos()
        }
    }
}

struct AlbumSettings: Codable, Equatable {
    var isVisible: Bool
    var color: Color

    enum CodingKeys: String, CodingKey {
        case isVisible
        case color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)

        let colorString = try container.decode(String.self, forKey: .color)
        color = Color(colorString)
    }

    init(from decoder: Decoder? = nil) {
        isVisible = true
        color = Color.clear

        if let decoder = decoder {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                isVisible = try container.decode(Bool.self, forKey: .isVisible)

                let colorString = try container.decode(String.self, forKey: .color)
                color = Color(colorString)
            } catch {
                print("Error decoding AlbumSettings: \(error)")
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isVisible, forKey: .isVisible)

        try container.encode(color.description, forKey: .color)
    }
}
