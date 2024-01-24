//
//  ContentView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var selectedAsset: PHAsset?
    @State private var isDetailViewPresented = false
    @State private var isShowingLoader = true
    @State private var loadingStartTime = Date()
    
    private var minLoaderTime = 1.5

    var body: some View {
        Group {
            if viewModel.hasPhotoLibraryAccess && !isShowingLoader {
                ZStack {
                    NavigationView {
                        AlbumView(viewModel: viewModel)
                        ThumbnailListView(viewModel: viewModel, selectedAsset: $selectedAsset, isDetailViewPresented: $isDetailViewPresented)
                    }

                    if isDetailViewPresented, let selectedAsset = selectedAsset {
                        DetailView(viewModel: viewModel, asset: selectedAsset, isPresented: $isDetailViewPresented)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all))
                    }
                }
            } else if viewModel.photoLibraryAccessHasBeenChecked && !isShowingLoader {
                Text("Full Access to the photo library is required. Please enable access in Settings.")
            } else {
                VStack {
                    Text("Loading, please sit tight!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ProgressView()
                        .scaleEffect(1.5, anchor: .center)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .padding()
                }
                .onAppear {
                    loadingStartTime = Date()
                    DispatchQueue.main.asyncAfter(deadline: .now() + minLoaderTime) {
                        if Date().timeIntervalSince(loadingStartTime) >= minLoaderTime {
                            self.isShowingLoader = false
                        }
                    }
                    viewModel.checkPhotoLibraryAccess()
                }
            }
        }
    }
}

