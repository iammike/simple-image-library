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
    @AppStorage("readAloudOnTap") private var readAloudOnTap = false
    @AppStorage("visionImpairedCloseButton") private var visionImpairedCloseButton = false
    @AppStorage("albumNameTextSize") private var albumNameTextSizeRaw = AlbumNameTextSize.defaultValue.rawValue

    var body: some View {
        List {
            if viewModel.isSetupMode {
                Section(header: Text("Setup")) {
                    Toggle("Read names aloud on tap", isOn: $readAloudOnTap)
                    Toggle("Large media close button", isOn: $visionImpairedCloseButton)
                    Picker("Album name text size", selection: $albumNameTextSizeRaw) {
                        ForEach(AlbumNameTextSize.allCases) { size in
                            Text(size.label).tag(size.rawValue)
                        }
                    }
                }

                Text("Tap Done when finished. To return to Setup later, press and hold the gear, then answer the quick question.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button(action: {
                    viewModel.toggleIsSettingsComplete()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            Text("Albums")
                .font(.title)
                .fontWeight(.bold)

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                let isVisible = viewModel.albumSettings[album.localIdentifier]?.isVisible ?? true
                if viewModel.isSetupMode || isVisible {
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
