# 1.5 — Accessibility Release Design

Date: 2026-06-16
Branch: `feature/accessibility-1.5`

## Goal

Ship a minimal, accessibility-themed 1.5 that adds genuine new functionality (to strengthen the App Store Guideline 4.2 argument) while serving the app's stated audience: children and people with special needs. Includes one low-risk bug fix and a new unit test target.

## Scope

In scope:
1. Tap-to-hear / read-aloud (#89)
2. Album color coding (#57)
3. Accessibility labels + Dynamic Type pass
4. Bug #59 — show loading screen after photo access is granted
5. Unit test target + initial unit tests (#80)

Out of scope: slideshow (#86), memory game (#87), favorites (#88), UI tests (#81), any change to the DetailView swipe/video gesture code (fragile area).

## Feature 1 — Tap-to-hear / read-aloud (#89)

- New `SpeechManager`: a thin wrapper around `AVSpeechSynthesizer` exposed as a shared singleton with a single `speak(_ text: String)` method and a `stop()`. Reads the `readAloudOnTap` preference and the system VoiceOver state itself, so callers just call `speak`.
- New Settings.bundle toggle: Title "Read names aloud on tap", Key `readAloudOnTap`, default `false`. Same `PSToggleSwitchSpecifier` pattern as existing toggles.
- Behavior when enabled:
  - Album list: tapping an album row speaks `album.localizedTitle` (in addition to selecting it).
  - Detail view: when a photo is opened (DetailView `onAppear` for the initially selected asset) it speaks a friendly date string derived from `PHAsset.creationDate` (e.g. "March 5, 2024") via a shared `DateFormatter` (`.long` date style). Assets with no creation date speak nothing. Deliberately not hooked into the swipe path, to stay out of the fragile gesture/video code.
- Suppression: `SpeechManager.speak` is a no-op when `readAloudOnTap` is off OR when `UIAccessibility.isVoiceOverRunning` is true (avoid double-speaking over VoiceOver).

## Feature 2 — Album color coding (#57)

- Extend `AlbumSettings` with `var colorHex: String?` (default `nil`). Update `CodingKeys`, both initializers, and `encode(to:)`. Decoding must tolerate older persisted JSON that lacks the key (use `decodeIfPresent`).
- Palette: a fixed set of ~6 high-contrast preset colors plus "none", defined in one place (e.g. `AlbumColor` enum or a static array of hex strings). A fixed palette keeps colors distinct and child-friendly and avoids a full color picker.
- Setup mode (`showAlbumViewSettings == true`): each `AlbumRowView` shows the current color swatch; tapping it cycles through palette + none. Persists via existing `saveAlbumSettings()` (add a `setAlbumColor` method on the ViewModel mirroring `toggleAlbumVisibility`).
- Normal mode: a leading colored dot before the album title when a color is assigned, so non-readers recognize albums by color.

## Feature 3 — Accessibility labels + Dynamic Type

- Add `.accessibilityLabel` to icon-only controls:
  - DetailView close button (`xmark`) → "Close".
  - AlbumRowView visibility toggle (`eye`) → "Show album" / "Hide album" reflecting state.
  - Album color swatch button → "Album color".
  - ThumbnailView cells → a label indicating photo vs video.
- Dynamic Type: confirm text uses semantic fonts (already largely true) and nothing critical clips at larger sizes; apply small fixes only where needed. No layout rewrites.

## Bug #59 — loading after access granted

- In `ContentView`, when access flips to granted via the re-check timer, ensure `LoadingView` is shown until `viewModel.albumsLoaded` is true, instead of any blank or stale AccessDenied flash. Fix is confined to ContentView's view conditions / timer handling. Does not touch ViewModel access logic beyond what is needed.

## Unit test target + tests (#80)

- Add a `Simple Photo ViewerTests` unit test target (XCTest) to the Xcode project and a shared scheme test action.
- Initial tests (logic only, no UI):
  - `AlbumSettings` round-trip encode/decode, including backward-compatible decode of JSON without `colorHex`, and default values.
  - Album color palette: cycling logic (none → first → ... → last → none).
  - `SpeechManager` gating: `speak` is a no-op when the toggle is off (verify via an injectable synthesizer/seam, or by testing the pure "should speak" decision function). Prefer extracting a pure function `shouldSpeak(enabled:voiceOverRunning:)` so it is testable without AVSpeechSynthesizer.
  - Read-aloud date formatting helper produces expected strings for a known date and `nil` for no date.
- Run via `xcodebuild test` against an iOS simulator destination.

## Versioning

- Bump `MARKETING_VERSION` to `1.5`, reset `CURRENT_PROJECT_VERSION` to `1`, in both build configs. Done at the end, after features land.

## Verification

- `xcodebuild build` and `xcodebuild test` succeed on a simulator.
- Manual sim check: read-aloud toggle on/off; album color assign in setup mode and dot in normal mode; VoiceOver labels read sensibly; loading screen after granting access.
