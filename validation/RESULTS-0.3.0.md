# Verification — TiToasts 0.3.0 — November 13, 2026

Built with Titanium SDK 13.4.1.GA and Xcode 27.1 Beta, selected per command.
iOS deployment target remains 26.0.

The action reveal starts after 48 points of swipe travel (previously 18).
A position constraint maintains a minimum 12-point layout gap between the
scaled action and glass capsule, including hidden endpoints used by UIKit's
settle animations. This also covers the full-size Reduced Motion button.
The fully open reveal distance remains 72 points.

Device arm64 and simulator arm64/x86_64 archives compiled successfully.
ZIP CRC, embedded version and installed binary comparisons passed.
Installed app-locally in AlloyTestApp; previous versions are preserved.
No global module registry changes or publication.

All 27 lifecycle assertions passed on the iPhone 17 Pro simulator, iOS 26.5.0.
AlloyTestApp built and loaded 0.3.0 on the iPhone 18 Pro simulator, iOS 27.0.
Checked opening, closing, action dismissal and completed-event delivery.
A Device Hub recording of opening and closing was inspected frame by frame:
the visible button stays separated from the glass throughout both transitions.
The supplied physical-device reference was reviewed; the updated binary has
not yet been physically device-tested.

Archive: ios/dist/ti.toasts-iphone-0.3.0.zip
SHA-256: a4b9b643e92f5fe28b02a633fc62e88d885fcf92c6495ec5ae3dd2afc3b5cbf4
