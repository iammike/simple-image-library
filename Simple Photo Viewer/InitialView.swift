import SwiftUI
import UIKit

struct InitialView: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            setupPage.tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)
                    header

                    VStack(spacing: 0) {
                        featureRow(
                            icon: "checkmark.shield.fill",
                            title: "Safe & Read-Only",
                            description: "Nothing can be deleted, edited, or shared. Your photos and albums are completely protected."
                        )
                        featureRow(
                            icon: "photo.on.rectangle",
                            title: "Photos, Videos & Live Photos",
                            description: "Browse your entire library in a clean, distraction-free layout — no cluttered menus or extra buttons."
                        )
                        featureRow(
                            icon: "rectangle.stack",
                            title: "Album Control",
                            description: "Choose exactly which albums are visible. All settings are managed in the Settings app — never inside LE Viewer."
                        )
                        featureRow(
                            icon: "accessibility",
                            title: "Accessibility Built In",
                            description: "Hear album and photo names read aloud, color-code albums for non-readers, and enlarge the close button to fit every ability."
                        )
                        featureRow(
                            icon: "lock.iphone",
                            title: "Guided Access Ready",
                            description: "Pair with iOS Guided Access to lock the device to this app, preventing access to anything else."
                        )
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 32)
                    nextButton
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    // MARK: - Page 2: Setup

    private var setupPage: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)
                    guidedAccessCard
                    accessibilityCard
                    Spacer(minLength: 32)
                    ctaButton
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(color: Color(hex: "#FF8C42").opacity(0.25), radius: 12, x: 0, y: 6)

            Text("Welcome to LE Viewer")
                .font(.title2)
                .bold()

            Text("A simplified photo viewer for children and people with special needs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .padding(.horizontal, 24)
    }

    // MARK: - Feature Rows

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36, alignment: .top)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
    }

    // MARK: - Guided Access Card

    private var guidedAccessCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECOMMENDED SETUP")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                cardHeader
                Divider()
                ForEach(Array(steps.enumerated()), id: \.offset) { index, stepText in
                    stepRow(number: index + 1, text: stepText)
                    if index < steps.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }

    private var cardHeader: some View {
        Button {
            if let url = URL(string: "shortcuts://") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Up Guided Access")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Text("Tap to open the Shortcuts app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    // MARK: - Accessibility Card

    private var accessibilityCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACCESSIBILITY")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                accessibilityCardHeader
                Divider()
                accessibilityOptionRow(icon: "speaker.wave.2.fill", text: "Read names aloud on tap")
                Divider()
                accessibilityOptionRow(icon: "xmark.circle.fill", text: "Large media close button")
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }

    private var accessibilityCardHeader: some View {
        Button {
            openAppSettings()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility Options")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Text("Tap to open Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    private func accessibilityOptionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(text)
                .font(.callout)
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func stepRow(number: Int, text: Text) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FF8C42"))
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
            }
            text.font(.callout)
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    // MARK: - Steps

    private var steps: [Text] {
        [
            Text("Open ") + Text("Shortcuts").fontWeight(.semibold) + Text(", tap ") + Text("Automation").fontWeight(.semibold),
            Text("Tap ") + Text("+").fontWeight(.semibold) + Text(", then tap ") + Text("App").fontWeight(.semibold),
            Text("Tap ") + Text("Choose").fontWeight(.semibold) + Text(" and select ") + Text("LE Viewer").fontWeight(.semibold),
            Text("Leave ") + Text("Is Opened").fontWeight(.semibold) + Text(" selected, tap ") + Text("Run Immediately").fontWeight(.semibold) + Text(", then ") + Text("Next").fontWeight(.semibold),
            Text("Tap ") + Text("New Blank Automation").fontWeight(.semibold),
            Text("Tap ") + Text("Add Action").fontWeight(.semibold) + Text(", search ") + Text("Guided Access").fontWeight(.semibold),
            Text("Select ") + Text("Start Guided Access").fontWeight(.semibold) + Text(", tap ") + Text("Done").fontWeight(.semibold),
        ]
    }

    // MARK: - Buttons

    private var nextButton: some View {
        Button("Next") {
            withAnimation {
                currentPage = 1
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 72)
    }

    private var ctaButton: some View {
        Button("Get Started") {
            isFirstLaunch = false
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 72)
    }
}
