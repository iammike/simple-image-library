# LE Viewer

A photo viewer with almost nothing to press. It is for children and for people with
special needs who want to look at their own photos without the rest of the Photos app
in the way: no editing, no sharing, no deleting, and no way to reach anything the
adult has hidden.

The app was built for someone's son who needed exactly that, and for two toddlers who
turned out to need it too.

## What the viewer sees

- A list of albums, each with its cover photo and, if the caregiver has assigned one,
  a colour ring a non-reader can recognise.
- A grid of photos. Tap one to see it full screen; swipe to move through the album,
  pinch to zoom, tap the close button to come back. Videos and Live Photos play.
- Nothing else. Setup is behind a press-and-hold on the gear plus a simple arithmetic
  question, which a child does not get through.

Run it under **Guided Access** and the viewer cannot leave the app either.

## What the caregiver sets up

Press and hold the gear for three seconds and answer the question to reach Setup:

- **Hide albums.** A hidden album is gone from the viewer entirely, not merely
  collapsed. This is the one control over what the viewer can reach, and it is the
  part of the app tested hardest.
- **Colour albums.** Each album can carry one of six colours as a recognition cue.
- **Album name size.** Four presets, which also scale with the system text size.
- **Read names aloud.** Speak an album's name when it is tapped, and a photo's date
  when it opens.
- **Large close button** for anyone who finds the standard one hard to hit.

## Requirements

iOS 17 or later, iPhone and iPad. Photo library access is required and the app asks
for it on first launch; it reads photos and never writes to the library.

## Development

Open `Simple Photo Viewer.xcodeproj` in Xcode and run the `Simple Photo Viewer`
scheme. There are no dependencies.

Unit tests live in `Simple Photo ViewerTests` and cover album visibility, the
settings migration from 1.5, the parental gate, colours, and read-aloud text. A UI
test suite that drives the app on a simulator with a seeded photo library is on the
`feature/ui-tests` branch.

Things worth knowing before changing the code:

- `ViewModel.isVisible` is the single decision about whether the viewer can see an
  album. Every path that shows albums or photos goes through it; a new path that does
  not is a bug, because it is how hidden albums leak.
- iPad keeps the split view it has always had. iPhone pushes. The two are branched
  on the horizontal size class in `MainUI`, and the iPad side is meant to stay as it
  is: the app's users do not like change.
- The 1.5 release kept its settings in the iOS Settings app and its setup flag under a
  different key. `ViewModel.migrateSetupModeKey` carries a configured device across
  the upgrade, and the upgrade path is part of the release checklist.

Simulator tips: `xcrun simctl addmedia` seeds photos, and launch arguments such as
`-isSetupMode YES -isFirstLaunch NO` override the persisted defaults for one launch,
which is the reliable way to start the app in a known state.
