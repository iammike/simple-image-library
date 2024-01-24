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
    @Published var selectedAlbumIdentifier: String?
    @Published var hasPhotoLibraryAccess: Bool = false
    @Published var photoLibraryAccessHasBeenChecked: Bool = false
    
    private var fetchOffset = 0
    private let fetchLimit = 50
    private var currentAlbum: PHAssetCollection?
    private var allPhotos: PHFetchResult<PHAsset>
    
    init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        checkPhotoLibraryAccess()
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
            if self.currentAlbum == nil, let firstAlbum = sortedAlbums.first {
                self.selectAlbum(firstAlbum)
            }
        }
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
            // Reset state for photo fetching
            self.fetchOffset = 0
            self.images.removeAll()
            self.loadMorePhotos()
        }
    }
}
