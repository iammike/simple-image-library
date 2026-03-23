import SwiftUI
import UIKit

struct InitialView: View {
    @Binding var isFirstLaunch: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                aboutSection
                guidedAccessCard
                footerNote
                ctaButton
            }
        }
        .background(Color(UIColor.systemBackground))
        .ignoresSafeArea()
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
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .padding(.horizontal, 20)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ABOUT")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("All of your albums are visible by default. On the next screen you can hide individual albums. To change album visibility later, enable Show Album Settings in Settings → LE Viewer.")
                .font(.body)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Set Up Guided Access")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "#FF6B35"))
            Text("Locks the device to this app. Set up once in the Shortcuts app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
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
                    .foregroundColor(.white)
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

    // MARK: - Footer + CTA

    private var footerNote: some View {
        Text("Album visibility can be changed later in Settings → LE Viewer.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 12)
    }

    private var ctaButton: some View {
        Button("Get Started") {
            isFirstLaunch = false
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
}
