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
    @State private var showingGate = false
    @State private var holdProgress = false

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
        .toolbar {
            if !viewModel.isSetupMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ZStack {
                        Circle()
                            .trim(from: 0, to: holdProgress ? 1 : 0)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 3), value: holdProgress)
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Open Setup (press and hold)")
                    }
                    .onLongPressGesture(minimumDuration: 3, maximumDistance: 50) {
                        holdProgress = false
                        showingGate = true
                    } onPressingChanged: { pressing in
                        holdProgress = pressing
                    }
                }
            }
        }
        .sheet(isPresented: $showingGate) {
            ParentalGateView { viewModel.enterSetup() }
        }
    }
}
