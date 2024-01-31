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
            if viewModel.showAlbumViewSettings {
                Text("After saving, view settings can only be be accessed by toggling \"Show album view settings\" in iOS's Settings.app entry for this application.")
                Button(action: {
                    viewModel.toggleIsSettingsComplete()
                }) {
                    Text("Save View Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            Text("Albums")
                .font(.title)
                .fontWeight(.bold)

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                let isVisible = viewModel.albumSettings[album.localIdentifier]?.isVisible ?? true
                if viewModel.showAlbumViewSettings || isVisible {
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
        }
    }
}
