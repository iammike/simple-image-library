//
//  SetupView.swift
//  Simple Photo Viewer
//
//  The caregiver-facing configuration screen, reached from the gear behind the
//  parental gate. Presented full screen: it used to live in the album list, which
//  is the first column of the split view and so is hidden on iPad in portrait.
//

import SwiftUI
import Photos

struct SetupView: View {
    @ObservedObject var viewModel: ViewModel

    @AppStorage("readAloudOnTap") private var readAloudOnTap = false
    @AppStorage("visionImpairedCloseButton") private var visionImpairedCloseButton = false
    @AppStorage("albumNameTextSize") private var albumNameTextSizeRaw = AlbumNameTextSize.defaultValue.rawValue

    /// A settings form stretched across an iPad reads as unfinished, so the content
    /// keeps a readable measure and the grouped background fills the rest.
    private let maximumContentWidth: CGFloat = 700

    var body: some View {
        NavigationStack {
            Form {
                displaySection
                albumsSection
            }
            .frame(maxWidth: maximumContentWidth)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.toggleIsSettingsComplete()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var displaySection: some View {
        Section {
            Toggle("Read names aloud on tap", isOn: $readAloudOnTap)
            Toggle("Large media close button", isOn: $visionImpairedCloseButton)
            Picker("Album name text size", selection: $albumNameTextSizeRaw) {
                ForEach(AlbumNameTextSize.allCases) { size in
                    Text(size.label).tag(size.rawValue)
                }
            }
        } header: {
            Text("Display")
        } footer: {
            Text("Album names scale with this setting and with the system text size.")
        }
    }

    private var albumsSection: some View {
        Section {
            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                AlbumRowView(
                    viewModel: viewModel,
                    album: album,
                    isSelected: viewModel.selectedAlbumIdentifier == album.localIdentifier,
                    isVisible: viewModel.albumSettings[album.localIdentifier]?.isVisible ?? true,
                    toggleVisibility: {
                        viewModel.toggleAlbumVisibility(album.localIdentifier)
                    },
                    selectAlbum: {
                        viewModel.openAlbum(album)
                    }
                )
            }
        } header: {
            Text("Albums")
        } footer: {
            Text("Tap the circle to give an album a color that non-readers can recognize. Tap the eye to hide an album from the viewer.")
        }
    }
}
