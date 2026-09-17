//
//  AlbumNameTextSize.swift
//  Simple Photo Viewer
//
//  Caregiver-selectable preset sizes for album-name labels in the album list.
//  The raw value is what gets persisted in UserDefaults.
//

import SwiftUI

enum AlbumNameTextSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    /// Human-facing label shown in the Setup picker.
    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    /// Concrete point size for the album-name label. `.medium` matches the
    /// app's previous default body size so existing users see no change.
    var pointSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 24
        case .extraLarge: return 32
        }
    }

    /// Body-relative so the preset and Dynamic Type compose. An empty font name
    /// falls back to the system font, which is what makes the scaling work.
    var font: Font {
        .custom("", size: pointSize, relativeTo: .body)
    }

    /// Default for fresh installs and unrecognized stored values.
    static var defaultValue: AlbumNameTextSize { .medium }
}
