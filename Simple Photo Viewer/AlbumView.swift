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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding()
                    .background(viewModel.selectedAlbumIdentifier == nil ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(10)
            }

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                HStack {
                    Text(album.localizedTitle ?? "Unknown Album")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectAlbum(album)
                }
                .padding()
                .background(viewModel.selectedAlbumIdentifier == album.localIdentifier ? Color.blue.opacity(0.3) : Color.clear)
                .cornerRadius(10)
            }
        }
    }
}
