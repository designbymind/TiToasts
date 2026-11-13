var Toasts = require('ti.toasts');
var window = Ti.UI.createWindow({ backgroundColor: '#F2F2F7' });
var add = Ti.UI.createButton({ title: 'Add Toast', top: 120, height: 50 });
var stack = Toasts.createView({ top: 0, bottom: 0, left: 0, right: 0, glassTintOpacity: 0, entranceBounce: 0.5 });
window.add(add);
window.add(stack);
var positionButton = Ti.UI.createButton({ title: 'Position: Bottom', top: 180, height: 44 });
window.add(positionButton);
var position = 'bottom';
positionButton.addEventListener('click', function () {
    position = position === 'bottom' ? 'top' : 'bottom';
    stack.position = position;
    positionButton.title = 'Position: ' + (position === 'top' ? 'Top' : 'Bottom');
});
add.addEventListener('click', function () {
    var toast = Toasts.createToast({
        title: 'Success', message: 'Your changes have been saved.',
        symbol: 'checkmark.circle.fill', tintColor: '#34C759', duration: 5000
    });
    toast.addEventListener('click', function (event) { Ti.API.info('click ' + event.id); });
    toast.addEventListener('completed', function (event) { Ti.API.info('completed ' + event.reason); });
    stack.showToast(toast);
});
window.open();
