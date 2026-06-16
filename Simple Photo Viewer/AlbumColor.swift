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
    static let colors: [String] = [
        "#E53935", // red
        "#FB8C00", // orange
        "#FDD835", // yellow
        "#43A047", // green
        "#1E88E5", // blue
        "#8E24AA"  // purple
    ]

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
