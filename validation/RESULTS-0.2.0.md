# Verification — TiToasts 0.2.0 — November 12, 2026

Built with Titanium SDK 13.4.1.GA and Xcode 27.1 Beta, selected per command.
Deployment target remains iOS 26.0. UIKit implementation; no SwiftUI hosting.

## Changes

- Entrance rises from below and scales from 0.9 to 1 using a critically damped
  450 ms spring by default, with blur/opacity settling alongside it.
- Optional entranceBounce (0–1) lowers spring damping for a small overshoot.
  Entrance duration and starting scale are also configurable.
- Entrance motion has its own container, independent of stack geometry.
  Removal freezes an interrupted entrance before dismissing the toast.
- Swipe reveal scales and fades the entire 52-point circle and checkmark
  uniformly. Further swipe travel expands the action into a pill.
- AlloyTestApp pins 0.2.0 and includes a Slight entrance bounce switch.

## Validation

Device arm64 and simulator arm64/x86_64 archives compiled and packaged.
ZIP CRC, embedded version, and installed device/simulator binary comparisons passed.
The new version is installed app-locally in AlloyTestApp; 0.1.0 is preserved.
No global module registry changes or publication.

All 27 lifecycle assertions passed on iPhone 17 Pro simulator, iOS 26.5.0.
The expanded runner tests timeout interruption of a bouncing entrance and
programmatic dismissal with entrance animation disabled, in addition to the
prior completion timing, proxy identity, duplicate-call, and teardown checks.

On iPhone 18 Pro simulator, iOS 27.0, verified default entrance, optional bounce,
circular reveal, closing an open action, checkmark completion, body click,
and swipe-through dismissal. The new entrance and circular reveal were recorded
through Device Hub and inspected frame by frame against the user's references.
Physical-device animation/gesture acceptance remains unverified.

Archive: ios/dist/ti.toasts-iphone-0.2.0.zip
SHA-256: 5d5f7222d14782184c0700d58d2ec239b8f61c49b0ee5f97e09aa2ae364dc77b

Earlier verification is retained in RESULTS-0.1.0.md.
