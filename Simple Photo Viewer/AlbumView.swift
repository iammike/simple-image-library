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
    /// The highlight says which album fills the second column, so it means nothing
    /// where there is no second column. The split view's sidebar reports a compact
    /// size class of its own, so only the layout's owner can tell.
    let showsSelection: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showingGate = false
    @State private var gatePassed = false

    /// A phone's landscape navigation bar is about 32pt, which a 30pt ring plus its
    /// stroke overflows.
    private var ringDiameter: CGFloat {
        verticalSizeClass == .compact ? 22 : 30
    }

    /// Matches the bar so the item is never laid out taller than what contains it.
    private var barHeight: CGFloat {
        verticalSizeClass == .compact ? 32 : 44
    }
    @State private var holdProgress: CGFloat = 0

    var body: some View {
        List {
            Text("Albums")
                .font(.title)
                .fontWeight(.bold)

            if viewModel.albumsLoaded && !viewModel.hasVisibleAlbums {
                NoVisibleAlbumsView()
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                let isVisible = viewModel.isVisible(album)
                // Setup has its own screen, so this list shows only visible albums.
                if isVisible {
                    AlbumRowView(
                        viewModel: viewModel,
                        album: album,
                        isSelected: showsSelection && viewModel.selectedAlbumIdentifier == album.localIdentifier,
                        isVisible: isVisible,
                        toggleVisibility: {
                            viewModel.toggleAlbumVisibility(album.localIdentifier)
                        },
                        selectAlbum: {
                            viewModel.openAlbum(album)
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
                            .trim(from: 0, to: holdProgress)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: ringDiameter, height: ringDiameter)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: holdProgress == 0 ? 0.2 : 3), value: holdProgress)
                        // Tinted rather than the default black, which is the highest
                        // contrast thing on a light screen and drew more attention
                        // than the one control a child is not meant to use should.
                        Image(systemName: "gearshape")
                            .foregroundStyle(.tint)
                    }
                    // At rest the ring draws nothing, so an explicit shape is needed for
                    // a usable target. Width stays the ring's, or the glyph sits inside
                    // the bar's trailing margin.
                    .frame(width: ringDiameter, height: barHeight)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 3, maximumDistance: 50) {
                        holdProgress = 0
                        showingGate = true
                    } onPressingChanged: { pressing in
                        holdProgress = pressing ? 1 : 0
                    }
                    // VoiceOver cannot perform a long press, so it gets a direct action.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Open Setup")
                    .accessibilityHint("Press and hold to open Setup")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        holdProgress = 0
                        showingGate = true
                    }
                }
            }
        }
        // Entering setup replaces this navigation stack with Setup's. Doing that while
        // the sheet is still dismissing leaves iOS 16 drawing the old bar and placing
        // the new one below it, so Done cannot be hit. Wait for the dismissal.
        .sheet(isPresented: $showingGate, onDismiss: {
            if gatePassed {
                gatePassed = false
                viewModel.enterSetup()
            }
        }) {
            ParentalGateView { gatePassed = true }
        }
    }
}
