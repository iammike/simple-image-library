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
    /// False until the caregiver has left Setup once. The first visit is part of first
    /// run and needs a clear way out; later visits are a return to a settings screen.
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    /// True for exactly one Setup visit on a device upgraded from 1.5, where this
    /// screen did not exist and configuration lived in the iOS Settings app instead.
    /// Set only by migrating a real legacy key, never on a fresh install.
    @AppStorage("showsMovedFromSettingsNotice") private var showsMovedFromSettingsNotice = false
    /// Drives the alert itself, kept apart from the stored flag above: binding
    /// `.alert(isPresented:)` straight to a value that is already true on this
    /// view's very first render does not reliably present it (see `onAppear` below).
    @State private var isMovedNoticePresented = false

    /// A settings form stretched across an iPad reads as unfinished, so the content
    /// keeps a readable measure and the grouped background fills the rest.
    private let maximumContentWidth: CGFloat = 700

    var body: some View {
        NavigationStack {
            Form {
                displaySection
                albumsSection
                if !hasCompletedSetup {
                    firstRunSection
                }
            }
            .frame(maxWidth: maximumContentWidth)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: finishSetup)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                guard showsMovedFromSettingsNotice else { return }
                // Presenting synchronously from onAppear, the first time this view
                // is inserted, can lose the race with the containing view still
                // being installed and never actually present. Posting to the next
                // run loop turn is the standard fix.
                DispatchQueue.main.async {
                    isMovedNoticePresented = true
                }
            }
            .alert("Setup Has Moved", isPresented: $isMovedNoticePresented) {
                Button("Got It") { showsMovedFromSettingsNotice = false }
            } message: {
                Text("Setup now lives here in the app instead of the iOS Settings app. Come back any time: press and hold the gear, then answer the question.")
            }
        }
    }

    /// Shown only on the first visit. "Done" is a poor label before anything has been
    /// done, and this is the one moment to say how Setup is reached again.
    private var firstRunSection: some View {
        Section {
            Button(action: finishSetup) {
                Text("Start Using LE Viewer")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } footer: {
            Text("You can come back to Setup at any time: press and hold the gear, then answer the question.")
        }
    }

    private func finishSetup() {
        hasCompletedSetup = true
        viewModel.toggleIsSettingsComplete()
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
            Text("The album names under Albums below change as you pick a size, so you can see the result. They also scale with the system text size.")
        }
    }

    private var albumsSection: some View {
        Section {
            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                AlbumRowView(
                    viewModel: viewModel,
                    album: album,
                    isSelected: false,
                    isVisible: viewModel.isVisible(album),
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
