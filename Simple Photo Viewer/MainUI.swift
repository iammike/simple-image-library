//
//  MainUI.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 5/1/24.
//

import SwiftUI
import Photos

struct MainUI: View {
    @ObservedObject var viewModel: ViewModel
    var selectedAsset: Binding<PHAsset?>
    var isDetailViewPresented: Binding<Bool>

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Selecting an album only sets state on the view model, which the iPad's second
    // column reads. On iPhone there is no second column, so drive a push from the
    // same state and clear it when the user taps Back. Only a tap pushes: the app
    // also selects an album on its own at launch, which must not skip the album list.
    private var isAlbumPresented: Binding<Bool> {
        Binding(
            get: { viewModel.selectedAlbumIdentifier != nil && viewModel.albumSelectionWasExplicit },
            set: {
                if !$0 {
                    viewModel.albumSelectionWasExplicit = false
                    viewModel.selectedAlbumIdentifier = nil
                }
            }
        )
    }

    var body: some View {
        // Setup lives in the album list, which is the first column of the split view
        // and so is hidden behind a toggle on iPad in portrait. Show it full screen
        // instead, which reaches it in any orientation on either device. Normal
        // viewing keeps the split view below.
        if viewModel.isSetupMode {
            NavigationStack {
                AlbumView(viewModel: viewModel)
            }
        } else if horizontalSizeClass == .compact {
            NavigationStack {
                AlbumView(viewModel: viewModel)
                    .navigationDestination(isPresented: isAlbumPresented) {
                        ThumbnailListView(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
                    }
            }
        } else {
            NavigationView {
                AlbumView(viewModel: viewModel)
                ThumbnailListView(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
            }
        }

        if isDetailViewPresented.wrappedValue, let selectedAsset = selectedAsset.wrappedValue {
            DetailView(viewModel: viewModel, isPresented: isDetailViewPresented, asset: selectedAsset)
        }
    }
}
