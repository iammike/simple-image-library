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
    @State private var accessCheckTimer: Timer? = nil
    
    private let minLoaderTime = 1.5
    private let accessCheckInterval = 2.0
    
    var body: some View {
        Group {
            if viewModel.hasPhotoLibraryAccess {
                // Access granted: keep the loading screen up until albums are ready,
                // then show the main content. Never fall back to the denied screen here.
                if viewModel.albumsLoaded && !isShowingLoader {
                    MainContentView(viewModel: viewModel, selectedAsset: $selectedAsset, isDetailViewPresented: $isDetailViewPresented)
                } else {
                    LoadingView()
                        .onAppear {
                            setupLoadingTimer()
                        }
                }
            } else if viewModel.photoLibraryAccessHasBeenChecked && !isShowingLoader {
                AccessDeniedView()
                    .onAppear {
                        setupAccessCheckTimer()
                    }
                    .onDisappear {
                        accessCheckTimer?.invalidate()
                        accessCheckTimer = nil
                    }
            } else {
                LoadingView()
                    .onAppear {
                        setupLoadingTimer()
                    }
            }
        }
    }
    
    private func setupLoadingTimer() {
    #if targetEnvironment(simulator)
        self.isShowingLoader = false
    #else
        loadingStartTime = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + minLoaderTime) {
            if Date().timeIntervalSince(loadingStartTime) >= minLoaderTime {
                self.isShowingLoader = false
            }
        }
    #endif
    }
    
    private func setupAccessCheckTimer() {
        accessCheckTimer?.invalidate() // Invalidate any existing timer
        accessCheckTimer = Timer.scheduledTimer(withTimeInterval: accessCheckInterval, repeats: true) { _ in
            viewModel.checkPhotoLibraryAccess()

            if viewModel.hasPhotoLibraryAccess {
                // Access just granted: stop polling and drop the loader gate so the
                // loading screen (then main content once albums load) takes over.
                self.accessCheckTimer?.invalidate()
                self.accessCheckTimer = nil
                self.isShowingLoader = false
            }
        }
    }

}
