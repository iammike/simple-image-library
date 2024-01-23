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
            Button(action: {
                viewModel.loadAllPhotos()
            }) {
                Text("All Photos")
            }
            .listRowBackground(viewModel.selectedAlbumIdentifier == nil ? Color.blue.opacity(0.3) : Color.clear)

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                HStack {
                    Text(album.localizedTitle ?? "Unknown Album")
                    Spacer()
                }
                .contentShape(Rectangle()) // Make the whole row tappable
                .onTapGesture {
                    viewModel.selectAlbum(album)
                }
                .listRowBackground(viewModel.selectedAlbumIdentifier == album.localIdentifier ? Color.blue.opacity(0.3) : Color.clear)
            }
        }
    }
}

