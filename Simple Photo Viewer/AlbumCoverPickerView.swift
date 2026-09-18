//
//  AlbumCoverPickerView.swift
//  Simple Photo Viewer
//
//  Lets a caregiver choose which of an album's own photos represents it in the
//  list. The album's newest photo was the original, automatic cover; it kept
//  changing identity every time a photo was added, which is exactly what this
//  screen exists to let a caregiver opt out of.
//

import SwiftUI
import Photos

struct AlbumCoverPickerView: View {
    @ObservedObject var viewModel: ViewModel
    let album: PHAssetCollection

    @Environment(\.dismiss) private var dismiss

    @State private var assets: [PHAsset] = []
    @State private var isLoading = true

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 4)]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if assets.isEmpty {
                    Text("This album has no photos to choose from.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                Button {
                                    choose(asset)
                                } label: {
                                    AlbumCoverView(asset: asset, size: 88)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Use this photo as the album cover")
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Choose Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    // Clears any chosen cover, going back to following the newest photo.
                    Button("Use Newest") { useNewest() }
                }
            }
        }
        .task {
            assets = await viewModel.fetchAssets(in: album)
            isLoading = false
        }
    }

    private func choose(_ asset: PHAsset) {
        viewModel.setAlbumCover(album.localIdentifier, to: asset.localIdentifier)
        dismiss()
    }

    private func useNewest() {
        viewModel.setAlbumCover(album.localIdentifier, to: nil)
        dismiss()
    }
}
