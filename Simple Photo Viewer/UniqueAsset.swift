//
//  UniqueAsset.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/23/24.
//

import Foundation
import Photos

struct UniqueAsset {
    let id: UUID = UUID()  // Unique identifier
    let asset: PHAsset
}
