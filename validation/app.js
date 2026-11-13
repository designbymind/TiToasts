// Run as the Resources/app.js of a Classic Titanium app with ti.toasts 0.4.0.
// Checks the JS/native bridge, completion ordering, one-shot behavior and teardown.
var Toasts = require('ti.toasts');
var window = Ti.UI.createWindow({ backgroundColor: '#F2F2F7' });
var result = Ti.UI.createLabel({ top: 200, left: 20, right: 20, height: Ti.UI.SIZE, color: '#000000' });
var stack = Toasts.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL });
var tracked = [];
var checks = 0;
window.add(result);
window.add(stack);
function delay(ms) { return new Promise(function (resolve) { setTimeout(resolve, ms); }); }
function assert(condition, message) {
  if (!condition) throw new Error(message);
  checks++;
  Ti.API.info('[TiToasts validation] PASS ' + message);
}
function toast(duration) {
  var proxy = Toasts.createToast({ title: 'Validation', message: 'Testing lifecycle', duration: duration || 0 });
  var item = { proxy: proxy, count: 0, reason: null, finishedAt: 0 };
  item.done = new Promise(function (resolve, reject) {
    var watchdog = setTimeout(function () { reject(new Error('Missing completed event')); }, 5000);
    proxy.addEventListener('completed', function (event) {
      item.count++;
      item.reason = event.reason;
      item.finishedAt = Date.now();
      assert(event.toast === proxy, 'completed retains toast proxy identity');
      assert(typeof event.id === 'string' && event.id.length > 0, 'completed includes identifier');
      clearTimeout(watchdog);
      resolve(item);
    });
  });
  tracked.push(item);
  return item;
}
async function run() {
  try {
    var a = toast();
    stack.showToast(a.proxy);
    stack.showToast(a.proxy); // Duplicate show must not enqueue twice.
    await delay(100);
    var removalStarted = Date.now();
    a.proxy.hide();
    a.proxy.hide();
    await a.done;
    assert(a.reason === 'programmatic', 'hide reports programmatic');
    assert(a.finishedAt - removalStarted >= 250, 'completed waits for removal animation');
    stack.showToast(a.proxy); // Completed proxies cannot be shown again.
    a.proxy.hide();

    var b = toast(100);
    stack.showToast(b.proxy);
    await b.done;
    assert(b.reason === 'timeout', 'duration reports timeout during entrance animation');

    stack.entranceDuration = 900;
    stack.entranceBounce = 1;
    stack.entranceScale = 0.85;
    var bouncing = toast(100);
    stack.showToast(bouncing.proxy);
    await bouncing.done;
    assert(bouncing.reason === 'timeout', 'timeout interrupts a bouncing entrance');

    stack.entranceDuration = 0;
    var immediate = toast();
    stack.showToast(immediate.proxy);
    await delay(50);
    immediate.proxy.hide();
    await immediate.done;
    assert(immediate.reason === 'programmatic', 'disabled entrance preserves dismissal lifecycle');
    stack.entranceDuration = 450;
    stack.entranceBounce = 0;
    stack.entranceScale = 0.9;

    stack.position = 'top';
    stack.topOffset = 8;
    var topToast = toast(100);
    stack.showToast(topToast.proxy);
    await topToast.done;
    assert(topToast.reason === 'timeout', 'top entrance preserves timeout completion');

    stack.position = 'bottom';
    var moved = toast(1500);
    stack.showToast(moved.proxy);
    await delay(100);
    stack.position = 'top'; // Also interrupts a bottom entrance in progress.
    stack.topOffset = 12;
    await delay(100);
    assert(moved.count === 0, 'position change keeps the toast active');
    moved.proxy.hide();
    await moved.done;
    assert(moved.reason === 'programmatic', 'repositioned toast completes normally');

    var group = [toast(1500), toast(), toast()];
    group.forEach(function (entry) { stack.showToast(entry.proxy); });
    await delay(100);
    stack.dismissAll();
    await Promise.all(group.map(function (entry) { return entry.done; }));
    assert(group.every(function (entry) { return entry.reason === 'programmatic'; }), 'dismissAll completes every toast');

    var detached = toast(1000);
    stack.showToast(detached.proxy);
    await delay(100);
    window.remove(stack);
    await detached.done;
    assert(['windowClosed', 'detached'].indexOf(detached.reason) >= 0, 'removing overlay completes toasts: ' + detached.reason);
    window.add(stack);

    var child = Ti.UI.createWindow({ backgroundColor: '#FFFFFF' });
    var childStack = Toasts.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL });
    child.add(childStack);
    await new Promise(function (resolve) { child.addEventListener('open', resolve); child.open(); });
    var closed = toast(1000);
    childStack.showToast(closed.proxy);
    await delay(100);
    child.close();
    await closed.done;
    assert(['windowClosed', 'detached'].indexOf(closed.reason) >= 0, 'closing window completes toasts');
    await delay(1600); // Previously scheduled timers must not complete a second time.
    assert(tracked.every(function (entry) { return entry.count === 1; }), 'all completions fire exactly once after timer deadlines');
    result.text = 'PASS · ' + checks + ' lifecycle assertions\niOS ' + Ti.Platform.version;
    Ti.API.info('[TiToasts validation] ' + result.text);
    // Leave a plain-window safe-area preview visible after the assertions.
    stack.position = 'top';
    stack.topOffset = 0;
    stack.showToast(Toasts.createToast({ title: 'Top safe area', message: 'iOS ' + Ti.Platform.version }));
  } catch (error) {
    result.text = 'FAIL · ' + error.message;
    Ti.API.error('[TiToasts validation] ' + error.message + '\n' + error.stack);
  }
}
window.addEventListener('open', run);
window.open();
