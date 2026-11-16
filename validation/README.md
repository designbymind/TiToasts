# Lifecycle integration checks

`app.js` is a Classic Titanium test entry point. Use it as `Resources/app.js` in
an isolated Titanium app with `ti.toasts` 0.5.0 declared in `tiapp.xml` and its
module ZIP installed in that app's module directory. Set `min-ios-ver` to 26.0.
The runner displays its result and logs each assertion with the prefix
`[TiToasts validation]`.

It checks proxy identity, event identifiers, removal animation completion,
programmatic and timeout dismissal, duplicate show/hide calls, dismiss-all,
view removal, window closure, and duplicate callbacks after timer deadlines.
It also covers top placement, live repositioning during entrance, and leaves
a plain-window top-safe-area preview visible after passing.
Run with Reduced Motion disabled for the animation-duration assertion.

Use the bundled standalone Alloy app in `example/alloy/` (or the AlloyTestApp
demo) for touch interaction and visual comparison, including
partial swipe reveal, action-button dismissal, full swipe, tap-to-dismiss,
light/dark appearance, and live glass tint. Simulator results do not replace
physical-device gesture and rendering acceptance.
