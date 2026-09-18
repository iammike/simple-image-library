//
//  AlbumColor.swift
//  Simple Photo Viewer
//
//  A fixed palette of high-contrast colors a parent can assign to albums so
//  non-readers can recognize albums by color.
//

import Foundation

enum AlbumColorPalette {
    /// Fixed set of distinct, high-contrast colors (hex strings).
    ///
    /// Orange is deliberately not in this set: the app tints itself `#FF8C42`, and
    /// the palette's original orange (`#FB8C00`, see `legacyOrange` below) was close
    /// enough to it that an album colored orange read as app chrome rather than as
    /// that album's own mark -- the one thing the recognition palette must not do.
    static let colors: [String] = [
        "#E53935", // red
        "#00897B", // teal
        "#FDD835", // yellow
        "#43A047", // green
        "#1E88E5", // blue
        "#8E24AA"  // purple
    ]

    /// The palette's original second color, replaced for colliding with the app's
    /// own accent. Kept only so a value already stored in `AlbumSettings` can be
    /// recognized and migrated; never offered by `next(after:)`.
    static let legacyOrange = "#FB8C00"

    /// What a stored `legacyOrange` value becomes. Migrating to the palette's own
    /// teal, rather than dropping the color, keeps it a two-step cycle (album had a
    /// color -> still has a color) instead of silently uncoloring the album.
    static let replacementForLegacyOrange = "#00897B"

    /// Cycles a color selection: none -> first -> ... -> last -> none.
    /// An unknown/legacy value is treated as "none", so it advances to the first color.
    static func next(after current: String?) -> String? {
        guard let current = current, let index = colors.firstIndex(of: current) else {
            return colors.first
        }
        let nextIndex = index + 1
        return nextIndex < colors.count ? colors[nextIndex] : nil
    }
}
