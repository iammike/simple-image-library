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
                Text("Once saved, view settings can be modified again by enabling 'Show album view settings' in this app's section within the iOS Settings application.")
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
        .refreshable {
            viewModel.refreshAlbums()
        }
    }
}
