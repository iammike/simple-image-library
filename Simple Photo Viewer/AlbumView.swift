//
//  AlbumView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/23/24.
//

import SwiftUI
import Photos

struct AlbumView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        List {
            if !viewModel.isSettingsComplete {
                Button(action: {
                    viewModel.toggleIsSettingsComplete()
                }) {
                    Text("Complete Album View Settings")
                        .font(.headline)
                        .padding()
                }
            }

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                let isVisible = viewModel.albumSettings[album.localIdentifier]?.isVisible ?? true
                if !viewModel.isSettingsComplete || isVisible {
                    AlbumRowView(
                        viewModel: viewModel,
                        album: album,
                        isSelected: viewModel.selectedAlbumIdentifier == album.localIdentifier,
                        isVisible: isVisible,
//                        albumColor: viewModel.albumSettings[album.localIdentifier]?.color ?? Color.clear,
                        toggleVisibility: {
                            viewModel.toggleAlbumVisibility(album.localIdentifier)
                        },
                        selectAlbum: {
                            if viewModel.selectedAlbumIdentifier != album.localIdentifier {
                                viewModel.selectAlbum(album)
                            }
                        }
                    )
                }
            }

            if viewModel.isSettingsComplete {
                Button(action: {
                    viewModel.toggleIsSettingsComplete()
                }) {
                    Text("Toggle isSettingsComplete")
                        .font(.headline)
                        .padding()
                }
            }
        }
    }
}
