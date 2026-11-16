# Verification — TiToasts 0.4.0 — November 13, 2026

Built with Titanium SDK 13.4.1.GA and Xcode 27.1 Beta, selected per command.
Deployment target remains iOS 26.0; UIKit only.

## Positioning

- position defaults to bottom; top follows the hosting view's top safe area.
- topOffset adds spacing for top mode; bottomOffset retains its existing meaning.
- Top mirrors the stack, entrance direction, and soft background gradient.
- Live position changes finish an active entrance, close exposed actions, and
  relocate existing proxies without emitting completed or restarting timers.
- AlloyTestApp includes a Bottom/Top navigation-bar toggle.

## Verification

Device arm64 and simulator arm64/x86_64 packages compiled successfully.
ZIP CRC, embedded version, and app-local binary comparisons passed.
Installed app-locally in AlloyTestApp; earlier versions are preserved.
No global module registry changes or publication.

All 34 lifecycle assertions passed on iPhone 17 Pro simulator, iOS 26.5.0.
Checks include timeout during a top entrance, changing position during a bottom
entrance without completing the toast, and normal dismissal after repositioning.

Device Hub visual checks confirmed:
- Top toast below the status-bar safe area in a plain window on iOS 26.5.
- Top toast below the navigation-bar safe area in AlloyTestApp on iOS 27.0.
- A visible bottom toast relocates to the top without recreation/completion.

Physical-device positioning and gesture acceptance remain unverified.
Archive: ios/dist/ti.toasts-iphone-0.4.0.zip
SHA-256: befafd8f875c0d70ca32a2b5cac56e4ddb2a1a83bbfe26ee0684c5bc44237a01
