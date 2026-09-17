# App Store listing

`metadata/` holds the text entered in App Store Connect for the current version:
the description, the What's New text, and the notes for App Review. `screenshots/`
holds one folder per required display size.

The screenshots are captured by the `AppStoreScreenshots` UI test on the
`feature/ui-tests` branch, from a fresh install on a simulator with its built-in
sample photos, with the status bar overridden to 9:41. The test runs only with
`SCREENSHOTS=1` in its environment and the album colours come in through
`ALBUM_SETTINGS_HEX`; see the file's header for the exact invocation. Captures
carry an orientation tag, so pass them through `magick -auto-orient -strip`.
