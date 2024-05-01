//
//  InitialView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 5/1/24.
//

import SwiftUI

struct InitialView: View {
    @Binding var isFirstLaunch: Bool

    var body: some View {
        VStack {
            Spacer()
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            welcomeText
            generalInfoText
            instructionsText
            closeButton
            Spacer()
        }
        .padding()
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }

    private var instructionsText: some View {
        Text("""
        1. Open Shortcuts.app
        2. Tap Automation
        3. Tap + Button
        4. Tap "App"
        5. Tap "Choose" and select LE Viewer
        6. Leave "Is Opened" selected, select "Run Immediately" and tap Done
        7. Tap "New Blank Automation"
        8. Tap "Add Action"
        9. Search for "Guided Access"
        10. Select "Start Guided Access"
        11. Tap Done
        """)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 20)
    }

    private var welcomeText: some View {
        Text("Welcome to LE Viewer!")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.bottom, 20)
    }

    private var generalInfoText: some View {
        Text("""
        This app is intended for children or users with special needs who benefit from a more "protected" media library experience. By default, all albums are displayed. On the next screen you will be able to hide individual albums. Following that process, the ability to hide or unhide can only be reinvoked by toggling the "Show album view settings" in Settings.app for this application.\n
        It is recommended you use this app with Guided Access:
        """)
        .padding(.bottom, 20)
    }

    private var closeButton: some View {
        Button("Close") {
            isFirstLaunch = false
        }
    }
}

