# Verification — TiToasts 0.5.0

Built using Titanium SDK 13.4.1.GA and Xcode 27.1 Beta, selected per command.
UIKit implementation; minimum iOS 26.0.

## Changes

Per-toast actionSymbol, actionBackgroundColor, and actionSymbolColor options
are captured at show time. Defaults remain checkmark, system red, and white.
Symbols use template rendering to honor their foreground color, with checkmark
fallback for unavailable names. The action continues to dismiss the toast.

AlloyTestApp offers independent controls for each setting. Its ScrollView fills
the window behind the stack; native automatic safe-area insets replace manual
status-bar offsets. Scrollable top/bottom spacers follow the active position and
stack size, allowing covered controls to move clear of the capsules. The overlay
passes touches through empty areas.

## Initial 0.5.0 verification

Device arm64 and simulator arm64/x86_64 builds/packages succeeded. ZIP CRC,
manifest version, and app-local installed binary comparisons passed.
Installed app-locally in AlloyTestApp; earlier versions are retained.

All 34 lifecycle assertions passed on the iPhone 17 Pro simulator, iOS 26.5.0.
On the iPhone 18 Pro simulator, iOS 27.0, verified:

- Trash SF Symbol with a blue button and yellow foreground in bottom mode.
- Independent foreground change to black on a subsequent top-positioned toast.
- Custom actions complete with reason action in both positions.
- Full-height content visible behind glass capsules.
- Vertical scrolling behind a stationary, revealed action.
- Direct coordinate taps on configuration controls pass through the overlay.
- Bottom padding makes the last controls scroll clear of bottom toasts.
- Top padding makes the first content scroll clear of top toasts.

## Packaged Alloy example verification — 2026-11-16

Added the standalone app in example/alloy, adapted from the AlloyTestApp
component with a launcher, generated Alloy hooks, and portable setup/reuse
instructions. Its three component files match the consumer except for the
parent-screen button label (Example instead of Components).

Rebuilt the module with Titanium SDK 13.4.1.GA and Xcode 27.1 Beta. ZIP CRC,
embedded 0.5.0 manifest, device arm64 and simulator arm64/x86_64 metadata passed.
All 17 bundled example files were byte-compared with the repository sources.
XML/JSON parsing, controller JavaScript syntax, and git diff checks passed.
A final packaging pass normalized whitespace in the generated legacy Python
hook; both final native binaries match the runtime-tested package byte for byte.

Copied the Alloy app from the final ZIP into an isolated directory and installed
that same archive's module app-locally there. The extracted app compiled,
launched, and loaded ti.toasts 0.5.0 on the iPhone 18 Pro simulator, iOS 27.0.
Verified custom blue/yellow trash action reveal, completed with reason action,
click events, live top positioning, closing with an active toast, reopening with
fresh defaults, and displaying another toast. The original 34-assertion lifecycle
suite above was not rerun for this example-only packaging update.

Physical-device appearance and gesture acceptance remain unverified.
Archive: ios/dist/ti.toasts-iphone-0.5.0.zip
SHA-256: f2b8204c7e303e01dd739122011f1990f0b9c8a1c7a34c904dd3760167ce7281
