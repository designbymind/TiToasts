# TiToasts Alloy example

A standalone iOS 26+ app adapted from AlloyTestApp's `toasts/index` component.
It uses standard Alloy XML/TSS and requires no PurgeTSS, shared app helpers,
additional native modules, or npm dependencies.

## Run

Install the Titanium and Alloy CLIs and Titanium SDK 13.4.1.GA or a compatible
newer SDK, with an Xcode version supporting your simulator. The app pins the
tested SDK and `ti.toasts` 0.5.0 in `tiapp.xml`.

1. Copy this entire `alloy` directory to a writable folder outside the installed
   module directory.
2. Extract `ti.toasts-iphone-0.5.0.zip` into the copied app's root. Its embedded
   `modules/iphone/ti.toasts/0.5.0/` tree provides an app-local installation.
3. From the copied app's root, run:

   ```sh
   ti build -p ios --target simulator
   ```

Tap **Open Toast Demo**. Use **Example** to close it, then open it again to
exercise cleanup and a fresh controller. If a different compatible SDK is
installed, select it with `--sdk` or update `tiapp.xml`.

## Explore

- Cycle the action's SF Symbol, background, and foreground independently;
  settings apply to newly created toasts.
- Add up to three toasts, toggle five-second automatic dismissal, or dismiss
  on tap. Watch each toast's `click` and `completed` events in the event log.
- Swipe left to reveal the configured action, tap it to dismiss, or swipe fully.
- Use the navigation button to switch live between bottom and top positioning.
- Adjust glass tint, enable a slight entrance bounce, and compare light/dark mode.
- Scroll behind the capsules. Top/bottom spacers add enough scroll range to move
  covered controls clear; the overlay passes touches through its empty areas.

## Reuse the component

Copy the three `app/{controllers,views,styles}/toasts/index.*` files into your
Alloy app, declare/install the module, and call:

```javascript
var demo = Alloy.createController('toasts/index', {
    onClose: function () {
        demo = null;
    }
});
```

The controller opens its own NavigationWindow. On close it removes owned toast
listeners, restores the prior app appearance override, and destroys its Alloy
bindings before calling `onClose`.

The placeholder `DefaultIcon.png` comes from Titanium's standard app template;
its license is included in `TITANIUM-TEMPLATE-LICENSE`.
