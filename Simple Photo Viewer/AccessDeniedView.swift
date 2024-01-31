//
//  AccessDeniedView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/24/24.
//

import SwiftUI

struct AccessDeniedView: View {
    var body: some View {
        Text("Full Access to the photo library is required.\nIf you just granted it, please wait a moment for the application to load your data.\nOtherwise, please enable access in iOS Settings.")
            .multilineTextAlignment(.center)
            .lineSpacing(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
