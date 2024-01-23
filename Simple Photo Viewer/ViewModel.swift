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

    private var fetchOffset = 0
    private let fetchLimit = 100
    private var currentAlbum: PHAssetCollection?
    private var allPhotos: PHFetchResult<PHAsset>

    init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        allPhotos = PHAsset.fetchAssets(with: fetchOptions)
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
        images = []
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
                self.images.append(asset)
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

        let upperBound = min(fetchOffset + fetchLimit, count)
        allPhotos.enumerateObjects(at: IndexSet(fetchOffset..<upperBound)) { asset, _, _ in
            DispatchQueue.main.async {
                self.images.append(asset)
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
        images = []
        loadMorePhotosFromAlbum(album)
    }
}
