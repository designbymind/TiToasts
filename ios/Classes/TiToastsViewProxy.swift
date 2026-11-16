// Copyright (c) 2026 DesignByMind LLC.
import TitaniumKit
import UIKit

@objc(TiToastsViewProxy)
class TiToastsViewProxy: TiViewProxy {
  override func newView() -> TiUIView! { TiToastsView(frame: .zero) }

  @objc(showToast:)
  func showToast(_ arguments: [Any]?) {
    guard let toast = arguments?.first as? TiToastsToastProxy else {
      NSLog("[TiToasts] show expects a toast created with createToast().")
      return
    }
    TiThreadPerformOnMainThread({
      (self.view as? TiToastsView)?.show(toast)
    }, false)
  }

  @objc(dismissAll:)
  func dismissAll(_ arguments: [Any]?) {
    TiThreadPerformOnMainThread({
      guard self.viewAttached() else { return }
      (self.view as? TiToastsView)?.dismissAll(reason: "programmatic", animated: true)
    }, false)
  }

  override func windowDidClose() {
    TiThreadPerformOnMainThread({
      if self.viewAttached() {
        (self.view as? TiToastsView)?.dismissAll(reason: "windowClosed", animated: false)
      }
    }, true)
    super.windowDidClose()
  }
}

private enum ToastPosition: String {
  case bottom, top
}

private final class ToastEntry {
  let proxy: TiToastsToastProxy
  let card: ToastCard
  var timer: DispatchWorkItem?
  var removalReason: String?
  init(proxy: TiToastsToastProxy, card: ToastCard) {
    self.proxy = proxy
    self.card = card
  }
  deinit { timer?.cancel() }
}

@objc(TiToastsView)
class TiToastsView: TiUIView {
  private var entries: [ToastEntry] = [] // Oldest first; includes animating removals.
  private var glassTintOpacity: CGFloat = 0
  private var bottomOffset: CGFloat = 0
  private var topOffset: CGFloat = 0
  private var toastPosition: ToastPosition = .bottom
  private var toastWidth: CGFloat = 310
  private var disposing = false
  private var entranceDuration: TimeInterval = 0.45
  private var entranceScale: CGFloat = 0.9
  private var entranceBounce: CGFloat = 0
  private let edgeBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let edgeMask = CAGradientLayer()

  override func initializeState() {
    super.initializeState()
    backgroundColor = .clear
    clipsToBounds = false
    edgeBlur.isUserInteractionEnabled = false
    edgeBlur.alpha = 0
    edgeMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
    edgeMask.locations = [0, 1]
    edgeBlur.layer.mask = edgeMask
    addSubview(edgeBlur)
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    return hit === self ? nil : hit
  }

  override func touchedContentView(with event: UIEvent!) -> Bool { true }

  @objc(setGlassTintOpacity_:)
  func setGlassTintOpacity_(_ value: Any?) {
    glassTintOpacity = min(1, max(0, CGFloat(TiUtils.doubleValue(value, def: 0))))
    entries.forEach { $0.card.setGlassTintOpacity(glassTintOpacity) }
  }

  @objc(setPosition_:)
  func setPosition_(_ value: Any?) {
    let position = ToastPosition(rawValue: TiUtils.stringValue(value)?.lowercased() ?? "") ?? .bottom
    guard position != toastPosition else { return }
    toastPosition = position
    for entry in entries {
      entry.card.stopEntrance(at: .end)
      entry.card.closeAction(animated: false)
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    edgeMask.colors = position == .top
      ? [UIColor.black.cgColor, UIColor.clear.cgColor]
      : [UIColor.clear.cgColor, UIColor.black.cgColor]
    CATransaction.commit()
    setNeedsLayout()
  }

  @objc(setTopOffset_:)
  func setTopOffset_(_ value: Any?) {
    let offset = TiUtils.doubleValue(value, def: 0)
    topOffset = offset.isFinite ? max(0, CGFloat(offset)) : 0
    setNeedsLayout()
  }

  @objc(setBottomOffset_:)
  func setBottomOffset_(_ value: Any?) {
    bottomOffset = max(0, CGFloat(TiUtils.doubleValue(value, def: 0)))
    setNeedsLayout()
  }

  @objc(setToastWidth_:)
  func setToastWidth_(_ value: Any?) {
    toastWidth = max(180, CGFloat(TiUtils.doubleValue(value, def: 310)))
    setNeedsLayout()
  }

  @objc(setSoftBackground_:)
  func setSoftBackground_(_ value: Any?) {
    edgeBlur.isHidden = !TiUtils.boolValue(value, def: true)
  }

  @objc(setEntranceDuration_:)
  func setEntranceDuration_(_ value: Any?) {
    let milliseconds = TiUtils.doubleValue(value, def: 450)
    entranceDuration = milliseconds.isFinite ? min(3000, max(0, milliseconds)) / 1000 : 0.45
  }

  @objc(setEntranceScale_:)
  func setEntranceScale_(_ value: Any?) {
    let scale = TiUtils.doubleValue(value, def: 0.9)
    entranceScale = scale.isFinite ? CGFloat(min(1, max(0.5, scale))) : 0.9
  }

  @objc(setEntranceBounce_:)
  func setEntranceBounce_(_ value: Any?) {
    let bounce = TiUtils.doubleValue(value, def: 0)
    entranceBounce = bounce.isFinite ? CGFloat(min(1, max(0, bounce))) : 0
  }

  override func frameSizeChanged(_ frame: CGRect, bounds: CGRect) {
    super.frameSizeChanged(frame, bounds: bounds)
    setNeedsLayout()
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layoutStack()
  }

  /// Removing the overlay also completes its toasts and cancels pending timers.
  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil, !entries.isEmpty { dismissAll(reason: "detached", animated: false) }
  }

  func show(_ toast: TiToastsToastProxy) {
    guard !disposing, !toast.wasShown else { return }
    toast.wasShown = true
    toast.stack = self
    proxy.remember(toast)
    let card = ToastCard(toast: toast, opacity: glassTintOpacity)
    let entry = ToastEntry(proxy: toast, card: card)
    card.onClick = { [weak toast] in
      guard let toast, !toast.didComplete else { return }
      toast.fireEvent("click", with: toast.payload())
      if TiUtils.boolValue(toast.value(forKey: "dismissOnClick"), def: false) {
        toast.stack?.dismiss(toast, reason: "click", animated: true)
      }
    }
    card.onDismiss = { [weak self, weak toast] reason in
      if let toast { self?.dismiss(toast, reason: reason, animated: true) }
    }
    card.onSwipeBegan = { [weak self, weak card] in
      self?.entries.forEach { if $0.card !== card { $0.card.closeAction(animated: true) } }
    }
    let previous = entries.map { ($0.card, $0.card.center, $0.card.transform) }
    entries.append(entry)
    addSubview(card)
    layoutStack()
    for (view, center, transform) in previous {
      view.center = center
      view.transform = transform
    }
    // Stack geometry and entrance motion have separate owners. Relayouts and
    // new arrivals cannot overwrite an entrance that is still settling.
    card.prepareEntrance(scale: entranceScale, duration: entranceDuration, fromTop: toastPosition == .top)
    animate { self.layoutStack() }
    card.startEntrance(duration: entranceDuration, bounce: entranceBounce)
    let duration = TiUtils.doubleValue(toast.value(forKey: "duration"), def: 0)
    if duration.isFinite, duration > 0 {
      let timer = DispatchWorkItem { [weak self, weak toast] in
        if let toast { self?.dismiss(toast, reason: "timeout", animated: true) }
      }
      entry.timer = timer
      DispatchQueue.main.asyncAfter(deadline: .now() + duration / 1000, execute: timer)
    }
    UIAccessibility.post(notification: .announcement, argument: card.accessibilityLabel)
  }

  func dismiss(_ toast: TiToastsToastProxy, reason: String, animated: Bool) {
    guard let entry = entries.first(where: { $0.proxy === toast }), entry.removalReason == nil else { return }
    entry.removalReason = reason
    entry.timer?.cancel()
    entry.timer = nil
    entry.card.isUserInteractionEnabled = false
    entry.card.stopEntrance()
    let changes = {
      if !UIAccessibility.isReduceMotionEnabled {
        entry.card.center.x = -entry.card.bounds.width
        entry.card.transitionBlur.effect = UIBlurEffect(style: .regular)
      }
      entry.card.alpha = 0
      self.layoutStack()
    }
    if animated {
      animate(changes) { [weak self] in self?.finish(entry) }
    } else {
      finish(entry)
      layoutStack()
    }
  }

  func dismissAll(reason: String, animated: Bool) {
    disposing = !animated
    for entry in entries {
      if !animated {
        // Includes an in-flight removal. Its first dismissal reason wins.
        entry.removalReason = entry.removalReason ?? reason
        finish(entry)
      } else { dismiss(entry.proxy, reason: reason, animated: true) }
    }
    layoutStack()
    disposing = false
  }

  private func finish(_ entry: ToastEntry) {
    guard entries.contains(where: { $0 === entry }) else { return }
    entry.timer?.cancel()
    entry.card.stopEntrance()
    entry.card.layer.removeAllAnimations()
    entry.card.onClick = nil
    entry.card.onDismiss = nil
    entry.card.onSwipeBegan = nil
    entry.card.removeFromSuperview()
    entries.removeAll { $0 === entry }
    entry.proxy.completed(reason: entry.removalReason ?? "programmatic")
    proxy.forget(entry.proxy)
  }

  private func layoutStack() {
    let visible = entries.filter { $0.removalReason == nil }
    let stackHeight = min(CGFloat(max(0, visible.count - 1)) * 12.5, 25)
    let width = min(toastWidth, max(0, bounds.width - 40))
    let isTop = toastPosition == .top
    let y = isTop
      ? bounds.minY + safeAreaInsets.top + topOffset + stackHeight
      : bounds.maxY - safeAreaInsets.bottom - bottomOffset - 65 - stackHeight
    for (depth, entry) in visible.reversed().enumerated() {
      let layer = CGFloat(min(depth, 2))
      entry.card.bounds = CGRect(x: 0, y: 0, width: width, height: 65)
      let scale = 1 - layer * 0.05
      // Top stacks mirror the bottom stack: older layers peek toward the
      // chosen edge, while every layer remains inside its safe area.
      let centerY = isTop ? y + 32.5 * scale - layer * 10 : y + 65 - 32.5 * scale + layer * 10
      entry.card.center = CGPoint(x: bounds.midX, y: centerY)
      entry.card.transform = CGAffineTransform(scaleX: scale, y: scale)
      entry.card.layer.zPosition = CGFloat(visible.count - depth)
      entry.card.isHidden = depth > 2
      entry.card.isUserInteractionEnabled = depth == 0
      entry.card.accessibilityElementsHidden = depth != 0
    }
    if isTop {
      edgeBlur.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width,
        height: 90 + safeAreaInsets.top + topOffset)
    } else {
      edgeBlur.frame = CGRect(x: bounds.minX, y: bounds.maxY - safeAreaInsets.bottom - bottomOffset - 90,
        width: bounds.width, height: 90 + safeAreaInsets.bottom + bottomOffset)
    }
    edgeMask.frame = edgeBlur.bounds
    edgeBlur.alpha = visible.isEmpty ? 0 : 1
  }

  private func animate(_ changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
    UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.3,
      delay: 0, options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction],
      animations: changes, completion: { _ in completion?() })
  }
}

private final class ToastBody: UIView {
  var onActivate: (() -> Void)?
  override func accessibilityActivate() -> Bool {
    onActivate?()
    return true
  }
}

/// UIKit capsule with native glass and a custom iOS 26-compatible swipe action.
private final class ToastCard: UIView, UIGestureRecognizerDelegate {
  let transitionBlur = UIVisualEffectView(effect: nil)
  var onClick: (() -> Void)?
  var onDismiss: ((String) -> Void)?
  var onSwipeBegan: (() -> Void)?
  private let motion = UIView()
  private var entranceAnimator: UIViewPropertyAnimator?
  private let capsule = ToastBody()
  private let glass = UIVisualEffectView()
  private let gradient = CAGradientLayer()
  private let symbol = UIImageView()
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let action = UIButton(type: .system)
  private let actionRevealDistance: CGFloat = 72
  private let actionRevealStart: CGFloat = 48
  private let actionMinimumGap: CGFloat = 12
  private var opacity: CGFloat
  private var offset: CGFloat = 0
  private var initialOffset: CGFloat = 0
  private var recognitionTranslation: CGFloat = 0
  private var offsetBeforePan: CGFloat = 0
  private var tint: UIColor
  private var pan: UIPanGestureRecognizer!

  init(toast: TiToastsToastProxy, opacity: CGFloat) {
    self.opacity = opacity
    tint = TiUtils.colorValue(toast.value(forKey: "tintColor"))?.color ?? .systemGreen
    super.init(frame: .zero)
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.06
    layer.shadowRadius = 5
    layer.shadowOffset = CGSize(width: 0, height: 10)
    action.backgroundColor = TiUtils.colorValue(toast.value(forKey: "actionBackgroundColor"))?.color ?? .systemRed
    action.tintColor = TiUtils.colorValue(toast.value(forKey: "actionSymbolColor"))?.color ?? .white
    let actionSymbol = TiUtils.stringValue(toast.value(forKey: "actionSymbol")) ?? "checkmark"
    let actionImage = UIImage(systemName: actionSymbol) ?? UIImage(systemName: "checkmark")
    action.setImage(actionImage?.withRenderingMode(.alwaysTemplate), for: .normal)
    action.accessibilityLabel = "Dismiss notification"
    action.addTarget(self, action: #selector(completeAction), for: .touchUpInside)
    action.alpha = 0
    addSubview(motion)
    motion.addSubview(capsule)
    motion.addSubview(action)
    capsule.layer.addSublayer(gradient)
    capsule.addSubview(glass)
    capsule.clipsToBounds = true
    glass.isUserInteractionEnabled = false
    symbol.image = UIImage(systemName: TiUtils.stringValue(toast.value(forKey: "symbol")) ?? "checkmark.circle.fill")
    symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title1)
    symbol.tintColor = tint
    symbol.contentMode = .scaleAspectFit
    symbol.isUserInteractionEnabled = false
    titleLabel.text = TiUtils.stringValue(toast.value(forKey: "title")) ?? ""
    titleLabel.font = .preferredFont(forTextStyle: .callout)
    titleLabel.textColor = .label
    messageLabel.text = TiUtils.stringValue(toast.value(forKey: "message")) ?? ""
    messageLabel.font = .preferredFont(forTextStyle: .caption2)
    messageLabel.textColor = .secondaryLabel
    for label in [titleLabel, messageLabel] {
      label.numberOfLines = 1
      label.lineBreakMode = .byTruncatingTail
      label.adjustsFontForContentSizeCategory = true
      capsule.addSubview(label)
    }
    capsule.addSubview(symbol)
    transitionBlur.isUserInteractionEnabled = false
    capsule.addSubview(transitionBlur)
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    capsule.addGestureRecognizer(tap)
    pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    pan.delegate = self
    addGestureRecognizer(pan)
    tap.require(toFail: pan)
    capsule.onActivate = { [weak self] in self?.tapped() }
    capsule.isAccessibilityElement = true
    capsule.accessibilityTraits = .button
    capsule.accessibilityLabel = [titleLabel.text, messageLabel.text].compactMap { $0 }.joined(separator: ". ")
    capsule.accessibilityHint = "Double tap to activate. Use the Dismiss action to remove."
    capsule.accessibilityCustomActions = [UIAccessibilityCustomAction(name: "Dismiss", target: self, selector: #selector(accessibilityDismiss))]
    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ToastCard, _: UITraitCollection) in
      view.updateGlass()
    }
    updateGlass()
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override var accessibilityLabel: String? {
    get { capsule.accessibilityLabel }
    set { capsule.accessibilityLabel = newValue }
  }

  func setGlassTintOpacity(_ value: CGFloat) { opacity = value; updateGlass() }

  private func updateGlass() {
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .regular)
      effect.tintColor = (traitCollection.userInterfaceStyle == .dark ? UIColor.black : .white).withAlphaComponent(opacity)
      glass.effect = effect
    }
    gradient.colors = [tint.withAlphaComponent(0.15).cgColor, tint.withAlphaComponent(0.1).cgColor, UIColor.clear.cgColor]
    gradient.locations = [0, 0.5, 1]
  }

  /// Entrance uses its own container so the stack's depth scale stays intact.
  func prepareEntrance(scale: CGFloat, duration: TimeInterval, fromTop: Bool) {
    layoutIfNeeded()
    guard duration > 0, !UIAccessibility.isReduceMotionEnabled else { return }
    motion.transform = CGAffineTransform(translationX: 0, y: fromTop ? -100 : 100).scaledBy(x: scale, y: scale)
    motion.alpha = 0
    transitionBlur.effect = UIBlurEffect(style: .regular)
  }

  func startEntrance(duration: TimeInterval, bounce: CGFloat) {
    guard duration > 0, !UIAccessibility.isReduceMotionEnabled else { return }
    // Critical damping gives a fast arrival with a slow, non-overshooting tail.
    // Reducing damping adds a small overshoot when bounce is requested.
    let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1 - bounce * 0.3)
    entranceAnimator = animator
    animator.addAnimations { [weak self] in
      self?.motion.transform = .identity
      self?.motion.alpha = 1
      self?.transitionBlur.effect = nil
    }
    animator.startAnimation()
  }

  /// Freeze an interrupted entrance before dismissal; never snap to its endpoint.
  func stopEntrance(at position: UIViewAnimatingPosition = .current) {
    if let animator = entranceAnimator, animator.state == .active {
      animator.stopAnimation(false)
      animator.finishAnimation(at: position)
    }
    entranceAnimator = nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    motion.bounds = bounds
    motion.center = CGPoint(x: bounds.midX, y: bounds.midY)
    layoutSwipe()
  }

  private func layoutSwipe() {
    capsule.frame = bounds.offsetBy(dx: offset, dy: 0)
    capsule.layer.cornerRadius = bounds.height / 2
    glass.frame = capsule.bounds
    glass.layer.cornerRadius = bounds.height / 2
    glass.clipsToBounds = true
    gradient.frame = capsule.bounds
    transitionBlur.frame = capsule.bounds
    let iconWidth: CGFloat = 30
    symbol.frame = CGRect(x: 20, y: (bounds.height - 34) / 2, width: iconWidth, height: 34)
    let x: CGFloat = 20 + iconWidth + 15
    let textWidth = max(0, bounds.width - x - 20)
    let titleHeight = min(26, titleLabel.font.lineHeight)
    let messageHeight = min(19, messageLabel.font.lineHeight)
    let total = titleHeight + messageHeight + 4
    titleLabel.frame = CGRect(x: x, y: (bounds.height - total) / 2, width: textWidth, height: titleHeight)
    messageLabel.frame = CGRect(x: x, y: titleLabel.frame.maxY + 4, width: textWidth, height: messageHeight)
    // Reveal a complete circle with uniform scale (including its checkmark).
    // Its width only grows beyond the settled reveal, during a full swipe.
    let distance = max(0, -offset)
    let progress = min(1, max(0, (distance - actionRevealStart) / (actionRevealDistance - actionRevealStart)))
    let eased = progress * progress * (3 - 2 * progress)
    let diameter: CGFloat = 52
    let actionWidth = max(diameter, distance - (actionRevealDistance - diameter))
    action.bounds = CGRect(x: 0, y: 0, width: actionWidth, height: diameter)
    action.layer.cornerRadius = diameter / 2
    let scale = UIAccessibility.isReduceMotionEnabled ? 1 : max(0.001, eased)
    let restingCenter = bounds.width - 8 - actionWidth / 2
    // Keep even the invisible starting position clear of the capsule. UIKit
    // interpolates this position during settle animations, so fading in or
    // closing cannot carry the circle through the glass edge.
    let separatedCenter = capsule.frame.maxX + actionMinimumGap + actionWidth * scale / 2
    action.center = CGPoint(x: max(restingCenter, separatedCenter), y: bounds.midY)
    action.transform = CGAffineTransform(scaleX: scale, y: scale)
    action.alpha = eased
    action.isUserInteractionEnabled = progress >= 0.8
    action.accessibilityElementsHidden = progress < 0.8
  }

  func closeAction(animated: Bool) { settle(to: 0, animated: animated) }
  private func settle(to value: CGFloat, animated: Bool = true) {
    offset = value
    UIView.animate(withDuration: animated && !UIAccessibility.isReduceMotionEnabled ? 0.3 : 0,
      delay: 0, options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction]) {
      self.layoutSwipe()
    }
  }

  @objc private func tapped() {
    if offset < -1 { closeAction(animated: true) } else { onClick?() }
  }
  @objc private func completeAction() { onDismiss?("action") }
  @objc private func accessibilityDismiss() -> Bool { onDismiss?("action"); return true }

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = recognizer.velocity(in: self)
    let horizontal = abs(velocity.x) > abs(velocity.y) && (velocity.x < 0 || offset < 0)
    // UIPan resets its translation when it recognizes. Preserve the movement
    // that crossed its threshold, including very fast begin/end-only swipes.
    if horizontal { recognitionTranslation = recognizer.translation(in: self).x }
    return horizontal
  }

  @objc private func panned(_ recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
      offsetBeforePan = offset
      initialOffset = offset + recognitionTranslation
      offset = min(0, max(-bounds.width, initialOffset))
      onSwipeBegan?()
      layoutSwipe()
    case .changed:
      offset = min(0, max(-bounds.width, initialOffset + recognizer.translation(in: self).x))
      layoutSwipe()
    case .ended:
      offset = min(0, max(-bounds.width, initialOffset + recognizer.translation(in: self).x))
      let velocity = recognizer.velocity(in: self).x
      if -offset > bounds.width * 0.65 || (velocity < -850 && -offset > bounds.width * 0.45) {
        onDismiss?("swipe")
      } else {
        settle(to: -offset > 38 && velocity < 250 ? -actionRevealDistance : 0)
      }
    case .cancelled, .failed: settle(to: offsetBeforePan)
    default: break
    }
  }
}
