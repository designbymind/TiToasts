// Copyright (c) 2026 DesignByMind LLC.
import TitaniumKit
import UIKit

/// A one-shot toast. The stack retains the proxy through its removal completion.
@objc(TiToastsToastProxy)
class TiToastsToastProxy: TiProxy {
  let identifier = UUID().uuidString
  weak var stack: TiToastsView?
  var wasShown = false
  var didComplete = false

  @objc(hide:)
  func hide(_ arguments: [Any]?) {
    TiThreadPerformOnMainThread({ [weak self] in
      guard let self else { return }
      self.stack?.dismiss(self, reason: "programmatic", animated: true)
    }, false)
  }

  func payload(reason: String? = nil) -> [String: Any] {
    var result: [String: Any] = ["id": identifier, "toast": self]
    if let reason { result["reason"] = reason }
    return result
  }

  func completed(reason: String) {
    guard !didComplete else { return }
    didComplete = true
    stack = nil
    fireEvent("completed", with: payload(reason: reason))
  }
}
