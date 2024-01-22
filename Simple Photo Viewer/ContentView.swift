//
//  ContentView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var images: [PHAsset] = []
    @State private var fetchOffset = 0
    @State private var fetchLimit = 100
    @State private var selectedAsset: PHAsset?
    @State private var showDetailView = false

    private let allPhotos: PHFetchResult<PHAsset>

    init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let allMedia = NSPredicate(format: "(mediaType == %d) OR (mediaType == %d)",
                                   PHAssetMediaType.image.rawValue,
                                   PHAssetMediaType.video.rawValue)
        fetchOptions.predicate = allMedia

        allPhotos = PHAsset.fetchAssets(with: fetchOptions)
    }


    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(images, id: \.self) { asset in
                        ThumbnailView(asset: asset)
                            .onTapGesture {
                                self.selectedAsset = asset
                                self.showDetailView = true
                            }
                            .onAppear {
                                if images.last == asset {
                                    loadMorePhotos()
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Library")
            .onAppear(perform: loadInitialPhotos)
            .sheet(isPresented: $showDetailView, content: {
                if let asset = selectedAsset {
                    DetailView(asset: asset)
                }
            })
        }
    }

    private func loadInitialPhotos() {
        fetchPhotos(offset: fetchOffset, limit: fetchLimit)
    }

    private func loadMorePhotos() {
        fetchOffset += fetchLimit
        fetchPhotos(offset: fetchOffset, limit: fetchLimit)
    }

    private func fetchPhotos(offset: Int, limit: Int) {
        allPhotos.enumerateObjects(at: IndexSet(integersIn: offset..<(offset + limit)), options: []) { (asset, _, _) in
            DispatchQueue.main.async {
                self.images.append(asset)
            }
        }
    }
}
