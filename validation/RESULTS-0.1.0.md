# Verification — November 12, 2026

Module: `ti.toasts` 0.1.0. Titanium SDK: 13.4.1.GA.
Toolchain: `/Applications/Xcode-27.1-Beta.app`, selected per command.
Native implementation: Swift and UIKit, minimum iOS 26.0, no SwiftUI hosting.

## Package

- Device archive: arm64.
- Simulator archive: arm64 and x86_64.
- Mach-O minimum OS: 26.0.
- ZIP CRC/integrity passed; embedded manifest matches source.
- Device and simulator binaries installed app-locally in AlloyTestApp match ZIP bytes.
- Global module registry was not modified.

Archive: `ios/dist/ti.toasts-iphone-0.1.0.zip`

SHA-256: `b3f3d25faf6f4144497b96913addd7ff5d445f53c6d0f4cc74ff10e769009578`

## Runtime

An isolated Classic Titanium app on the iPhone 17 Pro simulator, iOS 26.5.0,
passed all 21 assertions in `validation/app.js`. The final system log recorded
`PASS · 21 lifecycle assertions` at 13:53:56 Pacific time. Checks include proxy
identity, event identifiers, removal animation ordering, duplicate show/hide
calls, programmatic dismissal, expiration during insertion, dismiss-all,
overlay removal, window closure, and no duplicate completion after timer deadlines.

AlloyTestApp built and loaded the module on the iPhone 18 Pro simulator,
iOS 27.0. Interactions verified through Device Hub:

- Per-toast click event; optional tap dismissal emits click before completed.
- Partial left swipe reveals the red checkmark action.
- Checkmark emits completed with reason action.
- Full left swipe emits completed with reason swipe.
- Three-card stacking and rearrangement after removing the newest card.
- Light/dark appearance and live glass tint changes.
- Empty overlay passes touches to demo controls.
- Closing and reopening the demo resets its state.

Physical-device rendering, tactile gesture feel, and VoiceOver spoken interaction
have not been validated. The custom UIKit gradient, blur transitions, soft
background, and swipe mechanics are approximations of the SwiftUI reference.
