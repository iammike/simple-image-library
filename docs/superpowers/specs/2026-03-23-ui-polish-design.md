# UI Polish Design Spec
**Date:** 2026-03-23
**Branch:** dev/michaelcollins/ui-polish (to be created from main)
**Goal:** Improve the visual quality of loading, onboarding, and error screens to pass Apple App Review.

---

## Context

Apple Review feedback flagged the launch page and first-time instructions as visually poor. The app's core functionality (photo browsing, album management, Guided Access support) is intentionally minimal and is not in scope. Only the UI-facing screens that Apple reviewers see first are being improved.

- **Deployment target:** iOS 16.0
- **Device family:** iPad only (TARGETED_DEVICE_FAMILY = 2). iPhone support is a future goal; designs should use adaptive layouts and avoid iPad-specific hard-coded sizes.

Primary users of the improved screens:
- **Parent/caretaker** — sees the first-launch onboarding screen once during setup
- **Child/end user** — sees the loading screen on each launch; may see the access denied screen

---

## Design Direction

**Warm & Friendly** — orange/peach accent color, soft warm backgrounds in light mode, native iOS dark backgrounds in dark mode. Approachable without being childish. Feels like a polished native app.

**Accent color:** `#FF8C42` — set as the universal color in `AccentColor.colorset`. This automatically applies to `Button` fills, `Toggle` tints, and `ProgressView` when no explicit color is set.

**Backgrounds:** Always use adaptive SwiftUI colors (`.systemBackground`, `.secondarySystemBackground`). Never hardcode `Color.white` or hex backgrounds in view code.

**New file required:** `Color+Hex.swift` — a `Color` extension providing `init(hex: String)`. This is needed for the gradient background colors. Example implementation:

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

---

## Screens

### 1. LoadingView

**Current issues:** Informal copy ("please sit tight!"), default `ProgressView` spinner, no visual polish.

**Proposed:**

**Background:** Warm gradient that adapts to dark mode using `@Environment(\.colorScheme)`:
- Light: `LinearGradient` from `Color(hex: "#FFF8F2")` to `Color(hex: "#FFE8D6")`, `startPoint: .top, endPoint: .bottom`
- Dark: `.systemBackground` (solid, no gradient)

**Layout (centered VStack, spacing: 20):**
1. `Image("Logo")` — 80×80, `.scaledToFit()`, with drop shadow: `.shadow(color: Color(hex: "#FF8C42").opacity(0.25), radius: 12, x: 0, y: 6)`
2. `Text("LE Viewer")` — `.title2`, `.bold`, `.primary`
3. Animated loading bar (see below)

Remove the "Loading, please sit tight!" text entirely.

**Animated loading bar:** A `Capsule` filled with `Color(hex: "#FF8C42")`, height 4pt, width 80pt, with a repeating opacity animation:
- Opacity oscillates from 0.5 to 1.0
- Duration: 1.0 second
- `autoreverse: true`, `repeatForever(autoreverses: true)`
- Use `.onAppear` to start the animation with `withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true))`

---

### 2. AccessDeniedView

**Current issues:** Plain `Text()` only, no icon, no action button, no visual hierarchy.

**Proposed (centered VStack, spacing: 16, padding: 40):**

1. `Image(systemName: "photo.fill")` — font size 56pt, foreground `.tint` (picks up accent color). Note: `photo.fill` is available since iOS 13; do not use `photo.on.rectangle.angled` which requires iOS 17.
2. `Text("Photo Access Needed")` — `.title3`, `.semibold`
3. `Text("LE Viewer needs full access to your photo library to show photos.")` — `.body`, `.secondary`, `.multilineTextAlignment(.center)`
4. `Button("Open Settings")` — calls `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`. The URL is guaranteed non-nil by the iOS SDK; no error handling needed. Style as `.buttonStyle(.borderedProminent)` with `.controlSize(.large)`.
5. `Text("Already granted? This screen updates automatically.")` — `.footnote`, `.secondary`, `.multilineTextAlignment(.center)`

Note: The existing timer in `ContentView.setupAccessCheckTimer()` already polls for access changes every 2 seconds and dismisses this view automatically when access is granted. No additional logic needed in `AccessDeniedView`.

---

### 3. InitialView (First-Launch Onboarding)

**Current issues:** Hardcoded `Color.white` (dark mode broken), dense wall of text, plain "Close" button, deprecated `edgesIgnoringSafeArea(.all)`, no visual hierarchy.

**Proposed layout:**

Wrap the entire content in a `ScrollView` containing a `VStack(alignment: .leading, spacing: 0)`. This ensures it doesn't clip on smaller iPads or future iPhone support.

Replace `.background(Color.white).edgesIgnoringSafeArea(.all)` with `.background(Color(.systemBackground)).ignoresSafeArea()`.

User may dismiss ("Get Started") at any point without having read all the steps — no read-gating needed. The button is always active.

**Section 1 — Header (centered, padding: top 32, bottom 24):**

```
VStack(spacing: 12) {
    Image("Logo") — 80×80, .scaledToFit(), same drop shadow as LoadingView
    Text("Welcome to LE Viewer") — .title2, .bold
    Text("A simplified photo viewer for children and people with special needs.")
        — .subheadline, .secondary, .multilineTextAlignment(.center), max width 300pt
}
.frame(maxWidth: .infinity)
.padding(.top, 32)
.padding(.bottom, 24)
.padding(.horizontal, 20)
```

**Section 2 — About (padding: horizontal 20, bottom 8):**

Section label: `Text("ABOUT")` — `.caption`, `.secondary`, uppercase (match iOS Settings section header style), padding bottom 6.

Body copy:
> "All of your albums are visible by default. On the next screen you can hide individual albums. To change album visibility later, enable Show Album Settings in Settings → LE Viewer."

Style: `.body`, no card background, standard `.primary` text. Padding: `.horizontal(20)`.

**Section 3 — Guided Access card (padding: horizontal 16, bottom 16):**

Section label: `Text("RECOMMENDED SETUP")` — `.caption`, `.secondary`, uppercase, padding horizontal 20, bottom 6.

Card: `VStack(spacing: 0)` with `.background(Color(.secondarySystemBackground))`, `.cornerRadius(12)`, `.padding(.horizontal, 16)`.

Inside the card:

- **Card header row** (`.padding(.vertical, 12).padding(.horizontal, 16)`, `Divider()` below):
  - `Text("Set Up Guided Access")` — `.subheadline`, `.semibold`, foreground `Color(hex: "#FF6B35")`
  - `Text("Locks the device to this app. Set up once in the Shortcuts app.")` — `.caption`, `.secondary`

- **Step rows** — 7 rows, each:
  - `HStack(spacing: 12)` with `Divider()` between each row (not after the last)
  - Number badge: `ZStack { Circle().fill(Color(hex: "#FF8C42")).frame(width: 24, height: 24); Text("\(stepNumber)").font(.caption).bold().foregroundColor(.white) }` where `stepNumber` is the `Int` loop index + 1
  - Step text: `.callout`, key UI element names wrapped in `Text` with `.fontWeight(.semibold)` (use attributed strings or concatenated `Text` views)

  Steps (corrected for iOS 18):
  1. Open **Shortcuts**, tap **Automation**
  2. Tap **+**, then tap **App**
  3. Tap **Choose** and select **LE Viewer**
  4. Leave **Is Opened** selected, tap **Run Immediately**, then **Next**
  5. Tap **New Blank Automation**
  6. Tap **Add Action**, search **Guided Access**
  7. Select **Start Guided Access**, tap **Done**

  Use `Divider()` (not a manual `Rectangle`) between rows for native behavior.

**Section 4 — Footer note:**

`Text("Album visibility can be changed later in Settings → LE Viewer.")`
— `.footnote`, `.secondary`, `.multilineTextAlignment(.center)`, `.padding(.horizontal, 20)`, `.padding(.top, 12)`

**Section 5 — CTA Button:**

`Button("Get Started") { isFirstLaunch = false }`
— `.buttonStyle(.borderedProminent)`, `.controlSize(.large)`, `.frame(maxWidth: .infinity)`, `.padding(.horizontal, 16)`, `.padding(.top, 16)`, `.padding(.bottom, 32)`

---

## New File

**`Color+Hex.swift`** — add to the `Simple Photo Viewer` target. Contains only the `Color(hex:)` initializer defined above. No other changes.

---

## Other Changes

- **`AccentColor.colorset`** — set universal color to `#FF8C42` (RGB: 255/140/66)
- **`.gitignore`** — add `.superpowers/` entry

---

## Out of Scope

- `MainUI`, `ThumbnailListView`, `DetailView`, `AlbumView` — no changes to core browsing experience
- App icon
- LaunchScreen storyboard — app uses in-app `LoadingView`; keep as-is
