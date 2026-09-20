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

    // The iPad's second column reads this state directly; iPhone has none, so a tap
    // drives a push. Only an explicit tap: launch-time selection must not skip the list.
    private var isAlbumPresented: Binding<Bool> {
        Binding(
            get: { viewModel.selectedAlbumIdentifier != nil && viewModel.albumSelectionWasExplicit },
            set: {
                if !$0 {
                    viewModel.clearSelectedAlbum()
                }
            }
        )
    }

    var body: some View {
        // The split view's first column is hidden on iPad in portrait, so Setup is full
        // screen rather than living inside the album list.
        if viewModel.isSetupMode {
            SetupView(viewModel: viewModel)
                // A photo open when Setup was entered must not come back when it is left.
                .onAppear { isDetailViewPresented.wrappedValue = false }
        } else if horizontalSizeClass == .compact {
            NavigationStack {
                AlbumView(viewModel: viewModel, showsSelection: false)
                    .navigationDestination(isPresented: isAlbumPresented) {
                        ThumbnailListView(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
                    }
            }
        } else {
            NavigationView {
                AlbumView(viewModel: viewModel, showsSelection: true)
                ThumbnailListView(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
            }
        }

        // Never over Setup: the gear would sit underneath, reachable by VoiceOver.
        if !viewModel.isSetupMode, isDetailViewPresented.wrappedValue, let selectedAsset = selectedAsset.wrappedValue {
            DetailView(viewModel: viewModel, isPresented: isDetailViewPresented, asset: selectedAsset)
        }
    }
}
