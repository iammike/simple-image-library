//
//  ViewModel.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/23/24.
//

import SwiftUI
import Photos

class ViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var images: [PHAsset] = []
    @Published var albums: [PHAssetCollection] = []
    @Published var selectedAlbumIdentifier: String?
    @Published var hasPhotoLibraryAccess: Bool = false
    @Published var photoLibraryAccessHasBeenChecked: Bool = false
    @Published var uniqueAssets: [UniqueAsset] = []

    private var fetchOffset = 0
    private let fetchLimit = 100
    private var currentAlbum: PHAssetCollection?
    private var allPhotos: PHFetchResult<PHAsset>

    override init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        allPhotos = PHAsset.fetchAssets(with: fetchOptions)

        super.init()
        PHPhotoLibrary.shared().register(self)
        checkPhotoLibraryAccess()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    private func checkForNewPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let latestPhotos = PHAsset.fetchAssets(with: fetchOptions)
        DispatchQueue.main.async {
            let newPhotos = latestPhotos.objects(at: IndexSet(0..<latestPhotos.count))
            let newUniqueAssets = newPhotos.map { UniqueAsset(asset: $0) }

            // Avoid adding duplicates
            for newAsset in newUniqueAssets {
                if !self.uniqueAssets.contains(where: { $0.asset.localIdentifier == newAsset.asset.localIdentifier }) {
                    self.uniqueAssets.append(newAsset)
                }
            }
        }
    }
    
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let currentAlbum = currentAlbum,
           let _ = changeInstance.changeDetails(for: currentAlbum) {
            DispatchQueue.main.async {
                self.selectAlbum(currentAlbum)
            }
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
                // Full access granted
                self.hasPhotoLibraryAccess = true
                self.fetchAlbums()
                self.setupPhotoAccessGranted()
                print("Authorized access found")

            case .limited, .denied, .restricted, .notDetermined:
                // Limited access or no access
                self.hasPhotoLibraryAccess = false
                self.clearCachedData()

            @unknown default:
                // Handle future cases
                self.hasPhotoLibraryAccess = false
                self.clearCachedData()
            }
            self.photoLibraryAccessHasBeenChecked = true
        }
    }

    private func clearCachedData() {
        self.albums.removeAll()
        self.images.removeAll()
        self.uniqueAssets.removeAll()
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
    
    private func setupPhotoAccessGranted() {
        fetchAlbums()
        loadAllPhotos()
    }

    func fetchAlbums() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]

        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options)

        let allAlbums = [userAlbums, smartAlbums].flatMap { $0.objects(at: IndexSet(0..<$0.count)) }

        albums = allAlbums.filter { album in
            let assetCount = PHAsset.fetchAssets(in: album, options: nil).count
            return assetCount > 0
        }
    }
    
    func loadAllPhotos() {
        selectedAlbumIdentifier = nil
        currentAlbum = nil
        fetchOffset = 0
        uniqueAssets = []
        loadMorePhotos()
    }

    func loadInitialPhotos() {
        images = []
        fetchOffset = 0
        fetchPhotos()
    }
    
    private func loadMorePhotosFromAlbum(_ album: PHAssetCollection) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        let count = assets.count
        guard fetchOffset < count else {
            return // No more photos to fetch
        }
        
        let upperBound = min(fetchOffset + fetchLimit, count)
        assets.enumerateObjects(at: IndexSet(fetchOffset..<upperBound)) { asset, _, _ in
            DispatchQueue.main.async {
                self.uniqueAssets.append(UniqueAsset(asset: asset))
            }
        }
        
        fetchOffset += fetchLimit
    }

    func loadMorePhotos() {
        if let currentAlbum = currentAlbum {
            loadMorePhotosFromAlbum(currentAlbum)
        } else {
            loadMorePhotosFromAll()
        }
    }
    
    private func loadMorePhotosFromAll() {
        let count = allPhotos.count
        guard fetchOffset < count else {
            return // No more photos to fetch
        }

        let upperBound = min(fetchOffset + fetchLimit, allPhotos.count)
        allPhotos.enumerateObjects(at: IndexSet(fetchOffset..<upperBound)) { asset, _, _ in
            DispatchQueue.main.async {
                self.uniqueAssets.append(UniqueAsset(asset: asset))
            }
        }

        fetchOffset += fetchLimit
    }

    private func fetchPhotos() {
        guard let album = currentAlbum else {
            fetchFromAllPhotos()
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)

        let upperBound = min(fetchOffset + fetchLimit, assets.count)
        assets.enumerateObjects(at: IndexSet(fetchOffset..<upperBound)) { asset, _, _ in
            DispatchQueue.main.async {
                self.images.append(asset)
            }
        }
    }

    private func fetchFromAllPhotos() {
        let upperBound = min(fetchOffset + fetchLimit, allPhotos.count)
        allPhotos.enumerateObjects(at: IndexSet(fetchOffset..<upperBound)) { asset, _, _ in
            DispatchQueue.main.async {
                self.images.append(asset)
            }
        }
    }

    func selectAlbum(_ album: PHAssetCollection) {
        selectedAlbumIdentifier = album.localIdentifier
        currentAlbum = album
        fetchOffset = 0
        uniqueAssets = []
        loadMorePhotosFromAlbum(album)
    }
}
