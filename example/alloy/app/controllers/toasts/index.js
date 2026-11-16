var args = arguments[0] || {};
var Toasts = require('ti.toasts');
$.usage.text = "const toast = Toasts.createToast({...});\ntoast.addEventListener('click', onClick);\ntoast.addEventListener('completed', onDone);\nstack.showToast(toast);";
var active = [];
var sequence = 0;
var log = [];
var disposed = false;
var closing = false;
var appearance = 0;
var toastPosition = 'bottom';
var actionSymbolIndex = 0;
var actionBackgroundIndex = 0;
var actionSymbolColorIndex = 0;
var actionSymbols = ['checkmark', 'xmark', 'trash', 'arrow.uturn.backward', 'heart.fill'];
var actionBackgrounds = [
	{ name: 'Red', color: '#FF3B30' }, { name: 'Blue', color: '#007AFF' },
	{ name: 'Purple', color: '#AF52DE' }, { name: 'Green', color: '#34C759' }
];
var actionSymbolColors = [
	{ name: 'White', color: '#FFFFFF' }, { name: 'Yellow', color: '#FFD60A' },
	{ name: 'Black', color: '#000000' }, { name: 'Cyan', color: '#64D2FF' }
];
var originalAppearance = Ti.UI.overrideUserInterfaceStyle;
var examples = [
	{ symbol: 'exclamationmark.triangle.fill', title: 'Connection Failed', message: 'Something went wrong. Please try again!', tintColor: '#FF3B30' },
	{ symbol: 'arrowshape.bounce.right.fill', title: 'Pending Action', message: 'Your file has still pending changes.', tintColor: '#FFCC00' },
	{ symbol: 'checkmark.circle.fill', title: 'Success', message: 'Your changes have been saved.', tintColor: '#34C759' }
];

/** Add scroll range, rather than shrinking the viewport behind the overlay. */
function updateScrollPadding() {
	if (disposed) return;
	var clearance = active.length ? 65 + Math.min(Math.max(active.length - 1, 0) * 12.5, 25) + 16 : 0;
	$.topSpacer.height = toastPosition === 'top' ? clearance : 0;
	$.bottomSpacer.height = toastPosition === 'bottom' ? clearance : 0;
}
function changeActionSymbol() {
	actionSymbolIndex = (actionSymbolIndex + 1) % actionSymbols.length;
	$.actionSymbolButton.title = 'Action symbol: ' + actionSymbols[actionSymbolIndex];
}
function changeActionBackground() {
	actionBackgroundIndex = (actionBackgroundIndex + 1) % actionBackgrounds.length;
	$.actionBackgroundButton.title = 'Action background: ' + actionBackgrounds[actionBackgroundIndex].name;
}
function changeActionSymbolColor() {
	actionSymbolColorIndex = (actionSymbolColorIndex + 1) % actionSymbolColors.length;
	$.actionSymbolColorButton.title = 'Action symbol color: ' + actionSymbolColors[actionSymbolColorIndex].name;
}

/** Record events while retaining only the most recent lines. */
function record(text) {
	Ti.API.info('[TiToasts] ' + text);
	if (disposed) return;
	log.unshift(text);
	log = log.slice(0, 7);
	$.events.text = log.join('\n');
}
function clicked(event) {
	record('click · ' + event.id.slice(0, 8));
}
function completed(event) {
	record('completed · ' + event.reason + ' · ' + event.id.slice(0, 8));
	var toast = event.toast;
	active = active.filter(function (item) {
		return item !== toast;
	});
	updateScrollPadding();
	toast.removeEventListener('click', clicked);
	toast.removeEventListener('completed', completed);
}
function addToast() {
	if (disposed || closing || active.length >= 3) return;
	var options = Object.assign({}, examples[sequence++ % examples.length], {
		duration: $.automatic.value ? 5000 : 0,
		dismissOnClick: $.dismissOnClick.value,
		actionSymbol: actionSymbols[actionSymbolIndex],
		actionBackgroundColor: actionBackgrounds[actionBackgroundIndex].color,
		actionSymbolColor: actionSymbolColors[actionSymbolColorIndex].color
	});
	var toast = Toasts.createToast(options);
	toast.addEventListener('click', clicked);
	toast.addEventListener('completed', completed);
	active.push(toast);
	updateScrollPadding();
	$.stack.showToast(toast);
}
function togglePosition() {
	toastPosition = toastPosition === 'bottom' ? 'top' : 'bottom';
	$.stack.position = toastPosition;
	$.positionButton.title = toastPosition === 'top' ? 'Top' : 'Bottom';
	updateScrollPadding();
	record('position · ' + toastPosition);
}
function changeBounce(event) {
	$.stack.entranceBounce = event.value ? 0.5 : 0;
}
function dismissAll() {
	$.stack.dismissAll();
}
function changeTint(event) {
	$.stack.glassTintOpacity = event.value;
	$.tintLabel.text = 'GLASS TINT OPACITY · ' + event.value.toFixed(2);
}
function cycleAppearance(event) {
	appearance = (appearance + 1) % 3;
	Ti.UI.overrideUserInterfaceStyle = [Ti.UI.USER_INTERFACE_STYLE_UNSPECIFIED, Ti.UI.USER_INTERFACE_STYLE_LIGHT, Ti.UI.USER_INTERFACE_STYLE_DARK][appearance];
	event.source.title = 'Appearance: ' + ['System', 'Light', 'Dark'][appearance];
	applyAppearance();
}
function applyAppearance() {
	var dark = appearance === 2 || (appearance === 0 && Ti.UI.userInterfaceStyle === Ti.UI.USER_INTERFACE_STYLE_DARK);
	$.scroll.backgroundColor = dark ? '#000000' : '#F2F2F7';
	$.navigation.backgroundColor = $.scroll.backgroundColor;
	$.window.titleAttributes = { color: dark ? '#FFFFFF' : '#000000' };
	$.getView('scroll').children.forEach(function (view) {
		if (view.backgroundColor) view.backgroundColor = dark ? '#1C1C1E' : '#FFFFFF';
		if (view.children)
			view.children.forEach(function (child) {
				if (child.apiName === 'Ti.UI.Label') child.color = dark ? '#FFFFFF' : '#000000';
			});
	});
	$.usage.color = dark ? '#FFFFFF' : '#000000';
}
function onOpened() {
	applyAppearance();
	updateScrollPadding();
}
function closeProject() {
	if (closing || disposed) return;
	closing = true;
	$.navigation.close();
}
function onProjectClosed(event) {
	if (event.source !== $.navigation || disposed) return;
	disposed = true;
	active.forEach(function (toast) {
		toast.removeEventListener('click', clicked);
		toast.removeEventListener('completed', completed);
	});
	active = [];
	Ti.UI.overrideUserInterfaceStyle = originalAppearance;
	$.destroy();
	if (args.onClose) args.onClose();
}
$.navigation.open();
