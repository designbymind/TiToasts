<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/ti-toasts-hero-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/ti-toasts-hero-light.png">
  <img alt="An example guide of how to properly use the drag-to-dismiss gesture" src="assets/ti-dragtodismisshero-light.png" width="768">
</picture>

# TiToasts

UIKit Liquid Glass stacked notifications for Titanium on iOS 26+. Module ID:
`ti.toasts`, version **0.5.0**, built with Titanium SDK 13.4.1.GA.
No SwiftUI hosting or third-party runtime dependencies.

Inspired by Kavsoft's SToasts sample by Balaji Venkatesh. This module is a UIKit
implementation of the demonstrated design and behavior; the original SwiftUI
source is not bundled.

## Usage

```javascript
const Toasts = require('ti.toasts');
const window = Ti.UI.createWindow({ backgroundColor: '#F2F2F7' });
const stack = Toasts.createView({
    width: Ti.UI.FILL, height: Ti.UI.FILL,
    top: 0, bottom: 0, left: 0, right: 0,
    glassTintOpacity: 0, softBackground: true
});
window.add(stack); // Add after other content, or give it a higher zIndex.
window.addEventListener('open', function () {
    const toast = Toasts.createToast({
        symbol: 'checkmark.circle.fill',
        title: 'Success',
        message: 'Your changes have been saved.',
        tintColor: '#34C759',
        actionSymbol: 'checkmark',
        actionBackgroundColor: '#007AFF',
        actionSymbolColor: '#FFFFFF',
        duration: 5000,
        dismissOnClick: false
    });
    toast.addEventListener('click', function (event) {
        Ti.API.info('Tapped: ' + event.id);
    });
    toast.addEventListener('completed', function (event) {
        Ti.API.info('Removed: ' + event.id + ' (' + event.reason + ')');
    });
    stack.showToast(toast);
    // toast.hide();
    // stack.dismissAll();
});
window.open();
```

## API

`createView(options)` creates a transparent stack overlay. Empty areas pass
through touches. Size the view to fill its parent. It follows its own safe area;
use `bottomOffset` to reserve additional space above a tab bar or composer.

| Stack property | Default | Meaning |
| --- | --- | --- |
| `glassTintOpacity` | `0` | Neutral white/black glass tint, clamped to 0–1; live updates |
| `softBackground` | `true` | Soft material fade beneath the stack |
| `toastWidth` | `310` | Capsule width in points; constrained to parent width minus 40 |
| `position` | `bottom` | `bottom` or `top`; unknown values use `bottom` |
| `bottomOffset` | `0` | Extra safe-area spacing in bottom mode |
| `topOffset` | `0` | Extra safe-area spacing in top mode |
| `entranceDuration` | `450` | Entrance spring duration in milliseconds, clamped to 0–3000; 0 disables it |
| `entranceScale` | `0.9` | Starting entrance scale, clamped to 0.5–1 |
| `entranceBounce` | `0` | Spring overshoot, clamped to 0–1; 0 settles without bounce, 0.5 adds a subtle bounce |

`createToast(options)` creates a **one-shot** event proxy. Register listeners
before passing it to `stack.showToast(toast)`. Calling show again with the same
proxy is ignored; create another toast to show it again. Content is read at show
time; recreate a toast to change its content after showing it.

| Toast property | Default | Meaning |
| --- | --- | --- |
| `title` | empty | Single-line primary text |
| `message` | empty | Single-line secondary text (the sample's description) |
| `symbol` | `checkmark.circle.fill` | SF Symbol name |
| `tintColor` | system green | Icon color and subtle vertical color wash |
| `duration` | `0` | Milliseconds until auto-dismiss; 0 disables it |
| `dismissOnClick` | `false` | Remove after firing `click` when tapped |
| `actionSymbol` | `checkmark` | Action SF Symbol name; unavailable/invalid symbols fall back to checkmark |
| `actionBackgroundColor` | system red | Action button background color |
| `actionSymbolColor` | white | Action symbol foreground color; symbols render as a single-color template |

Action appearance is captured when a toast is shown, independently of its
leading icon and `tintColor`. Changing the action icon or colors keeps the
existing dismissal behavior and `completed` reason (`action` or `swipe`).

Set `stack.position = 'top'` to anchor below the hosting view's top safe area.
In a navigation window, this respects the navigation bar's safe area as well.
Top mode mirrors the stack, background fade, and entrance direction. Add spacing
with `stack.topOffset = 8`. Bottom mode is the default and keeps `bottomOffset`.
Use a view that fills its parent and let the module apply its safe-area insets.
Changing position live relocates visible toasts without completing or recreating
them, finishes pending entrances, and closes any exposed swipe action.

Entrance settings apply to newly shown toasts. The toast rises and scales into
place with a decelerating spring; its entrance transform is independent of the
stack layout. For a slight bounce, set `stack.entranceBounce = 0.5`. Reduced
Motion bypasses entrance movement, scaling, bounce, and blur.

Methods: `stack.showToast(toast)`, `stack.dismissAll()`, `toast.hide()`.
The newest toast is in front, with up to two compressed cards visible behind it.
Additional toasts stay in the stack and appear as newer ones are removed. The
demo limits its stack to three to match the original example.

## Events and interaction

Events fire on each **toast**, rather than the stack:

- `click`: tap on the closed toast body. Payload: `id`, `toast`, and Titanium's
  standard event fields. Tapping a body whose swipe action is open closes that
  action first. Action-button taps and swipes do not fire `click`.
- `completed`: fires **once**, after the capsule is removed and the remaining
  stack has finished rearranging. Payload: `id`, `toast`, `reason`.

Completion reasons: `programmatic`, `timeout`, `swipe`, `action`, `click`,
`windowClosed`, or `detached`. Titanium may deliver its window-close lifecycle
hook when removing a view, so removing the overlay can report `windowClosed`. If removal is already underway, its original
reason wins. Closing the window or detaching the stack immediately removes all
remaining capsules and cancels timers. A toast never shown emits neither event.

The checkmark stays hidden for the first 48 points of a left swipe, then scales
and fades in with at least 12 points of separation from the glass capsule.
The gap is maintained while dragging and settling, including with Reduced Motion.
Swipe left to reveal the circular checkmark button; tap it to dismiss. A full left
swipe dismisses directly. Reverse the swipe or tap the body to close the action.
VoiceOver exposes a Dismiss action. Reduced Motion disables movement and blur
transitions. Labels use semantic colors and fonts; capsule geometry remains
65 points tall like the original, with single-line truncation.

The UIKit gradient, transition blur, soft background, and gesture implementation
approximate the SwiftUI rendering shown in the reference recordings. Native
Liquid Glass adapts to light/dark mode; physical-device comparison remains part
of visual acceptance.

## Alloy

```xml
<View id="stack" module="ti.toasts" width="Ti.UI.FILL" height="Ti.UI.FILL" />
```

Use `$.stack.showToast(toast)` from the controller. A standalone Alloy example,
adapted from AlloyTestApp's `toasts/index` component, is bundled in
`example/alloy/` in both the repository and the module ZIP. It includes three
sample messages, automatic dismissal, tap behavior, live glass tint, action
symbol/color controls, appearance controls, and an event log. Copy the example
out of the installed module directory and extract the module ZIP into its root
for an app-local installation, then run `ti build -p ios --target simulator`.
See the bundled `example/alloy/README.md` for setup and component reuse.
The stack overlays the full-height ScrollView. Automatic safe-area insets and
scrollable spacers at the active stack edge let the first/last controls scroll
clear of the capsules while content can still move behind the glass. Empty areas
of the stack pass touches through to the ScrollView.

## Build

```sh
ti build -p ios --build-only --project-dir ./ios --sdk 13.4.1.GA
```

The module archive is written to `ios/dist/ti.toasts-iphone-0.5.0.zip`.
