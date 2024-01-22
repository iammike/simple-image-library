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
    @State private var isDetailViewPresented = false
    
    private let allPhotos: PHFetchResult<PHAsset>
    
    init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allMedia = NSPredicate(format: "(mediaType == %d)", PHAssetMediaType.image.rawValue)
        fetchOptions.predicate = allMedia
        allPhotos = PHAsset.fetchAssets(with: fetchOptions)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(images, id: \.self) { asset in
                            ThumbnailView(asset: asset)
                                .onTapGesture {
                                    self.selectedAsset = asset
                                    self.isDetailViewPresented = true
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
                
                if isDetailViewPresented {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(0)
                    
                    DetailView(asset: selectedAsset!, isPresented: $isDetailViewPresented)
                        .padding()
                        .shadow(radius: 10)
                        .zIndex(1) // Ensure it's on top of the dim background
                }
            }
            .navigationTitle("Simple Photo Viewer")
            .onAppear(perform: loadInitialPhotos)
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
        if offset < allPhotos.count {
            let upperBound = min(offset + limit, allPhotos.count)
            allPhotos.enumerateObjects(at: IndexSet(integersIn: offset..<upperBound), options: []) { (asset, _, _) in
                DispatchQueue.main.async {
                    self.images.append(asset)
                }
            }
        }
    }
    
}
