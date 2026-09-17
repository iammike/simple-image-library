import SwiftUI
import UIKit

struct InitialView: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// A phone in landscape has roughly half the height, so the welcome header shrinks
    /// rather than the pages being split differently. Page count must not depend on
    /// orientation: rotating would otherwise change what the current page index means,
    /// moving the reader somewhere else mid-onboarding.
    private var isShort: Bool { verticalSizeClass == .compact }

    private struct Feature: Identifiable {
        /// Stable across body evaluations, unlike a fresh UUID, so rows are not rebuilt.
        var id: String { icon }
        let icon: String
        let title: String
        let description: String
    }

    /// The rows fit one page at regular width and overflow on a phone, so compact width
    /// spreads them across pages. The welcome header costs about a row's worth of
    /// height, so the page carrying it holds one fewer than the rest. Pages still
    /// scroll, which is what catches large Dynamic Type.
    private var featurePages: [[Feature]] {
        guard horizontalSizeClass == .compact else { return [features] }

        let headerPageCount = 2
        let rowsPerPage = 3
        let remainder = Array(features.dropFirst(headerPageCount))

        return [Array(features.prefix(headerPageCount))]
            + stride(from: 0, to: remainder.count, by: rowsPerPage).map { start in
                Array(remainder[start..<min(start + rowsPerPage, remainder.count)])
            }
    }

    private var lastPageIndex: Int { featurePages.count }

    /// Drawn in the layout rather than as the TabView's own overlay, which sat on top
    /// of pages long enough to scroll underneath it.
    private var pageDots: some View {
        HStack(spacing: 9) {
            ForEach(0...lastPageIndex, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(lastPageIndex + 1)")
    }

    /// Dots above a single prominent button, which is what iOS onboarding looks like.
    /// Paging back is a swipe, as it is elsewhere on the platform. The chrome is
    /// tighter on a short screen, where height rather than convention is the problem.
    private var pageControls: some View {
        VStack(spacing: isShort ? 6 : 10) {
            pageDots
            forwardButton
        }
        .padding(.horizontal, 16)
        .padding(.top, isShort ? 6 : 10)
        .padding(.bottom, isShort ? 6 : 12)
    }

    private var forwardButton: some View {
        Button {
            if currentPage == lastPageIndex {
                isFirstLaunch = false
            } else {
                withAnimation { currentPage += 1 }
            }
        } label: {
            // The width belongs on the label: outside the button style it stretches
            // the tap area while the filled pill keeps its intrinsic width.
            Text(currentPage == lastPageIndex ? "Get Started" : "Next")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    /// The button sits below the TabView rather than inside a page. The page indicator
    /// is drawn over the bottom of the TabView, and a button inside the scrolling
    /// content ends up underneath it.
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(featurePages.enumerated()), id: \.offset) { index, page in
                    welcomePage(features: page, showsHeader: index == 0).tag(index)
                }
                setupPage.tag(featurePages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageControls
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        // A large phone in landscape is regular width, where every row fits one page,
        // so the page count can drop while the reader is past the new last page.
        .onChange(of: featurePages.count) { _, _ in
            currentPage = min(currentPage, lastPageIndex)
        }
    }


    /// A page can run past the bottom of a short screen, and a card ending flush with
    /// the screen edge reads as the end of the page. Fading the cut and keeping the
    /// scroll indicator on say there is more.
    private func scrollCue<Content: View>(_ content: Content) -> some View {
        content
            .scrollIndicators(.visible)
            // Indicators are hidden while idle, so flash them on arrival: that is the
            // system's own way of saying a view scrolls.
            .scrollIndicatorsFlash(onAppear: true)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground).opacity(0),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 26)
                .allowsHitTesting(false)
            }
    }

    // MARK: - Page 1: Welcome

    private var features: [Feature] {
        [
            Feature(
                icon: "checkmark.shield.fill",
                title: "Safe & Read-Only",
                description: "Nothing can be deleted, edited, or shared. Your photos and albums are completely protected."
            ),
            Feature(
                icon: "photo.on.rectangle",
                title: "Photos, Videos & Live Photos",
                description: "Browse your entire library in a clean, distraction-free layout with no cluttered menus or extra buttons."
            ),
            Feature(
                icon: "rectangle.stack",
                title: "Album Control",
                description: "Choose exactly which albums are visible. Setup lives inside the app, behind a child-proof gate."
            ),
            Feature(
                icon: "accessibility",
                title: "Accessibility Built In",
                description: "Hear album and photo names read aloud, color-code albums for non-readers, resize album name text, and enlarge the close button to fit every ability."
            ),
            Feature(
                icon: "lock.iphone",
                title: "Guided Access Ready",
                description: "Pair with iOS Guided Access to lock the device to this app, preventing access to anything else."
            ),
        ]
    }

    private func welcomePage(features pageFeatures: [Feature], showsHeader: Bool) -> some View {
        GeometryReader { geometry in
            scrollCue(ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: isShort ? 8 : 32)
                    if showsHeader {
                        header
                    }

                    VStack(spacing: 0) {
                        ForEach(pageFeatures) { feature in
                            featureRow(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description
                            )
                        }
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 32)
                }
                .frame(minHeight: geometry.size.height)
            })
        }
    }

    // MARK: - Page 2: Setup

    private var setupPage: some View {
        GeometryReader { geometry in
            scrollCue(ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)
                    guidedAccessCard
                    accessibilityCard
                    Spacer(minLength: 32)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            })
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: isShort ? 6 : 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: isShort ? 44 : 80, height: isShort ? 44 : 80)
                .shadow(color: Color(hex: "#FF8C42").opacity(0.25), radius: 12, x: 0, y: 6)

            Text("Welcome to LE Viewer")
                .font(isShort ? .headline : .title2)
                .bold()

            Text("A simplified photo viewer for children and people with special needs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, isShort ? 2 : 8)
        .padding(.bottom, isShort ? 12 : 28)
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
        .padding(.vertical, isShort ? 7 : 12)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Setup Lives in the App")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                Text("Press and hold the gear, then answer a quick question to open Setup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "gearshape")
                .font(.caption)
                .foregroundStyle(.tint)
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


}
