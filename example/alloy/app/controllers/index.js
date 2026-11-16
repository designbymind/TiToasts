var demo = null;

/** Open one demo controller; its close callback releases the owned reference. */
function openDemo() {
    if (demo) return;
    demo = Alloy.createController('toasts/index', {
        onClose: function () {
            demo = null;
        }
    });
}

$.index.open();
