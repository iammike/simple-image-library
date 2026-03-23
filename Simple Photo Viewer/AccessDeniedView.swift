import SwiftUI
import UIKit

struct AccessDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Photo Access Needed")
                .font(.title3)
                .fontWeight(.semibold)

            Text("LE Viewer needs full access to your photo library to show photos.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Already granted? This screen updates automatically.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
