import UIKit
import Flutter
import ObjectiveC.runtime

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    installDebugFocusWorkaround()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func installDebugFocusWorkaround() {
#if DEBUG
    guard let flutterViewClass: AnyClass = NSClassFromString("FlutterView") else {
      return
    }
    let selector = NSSelectorFromString("focusItemsInRect:")
    guard let method = class_getInstanceMethod(flutterViewClass, selector) else {
      return
    }

    typealias FocusItemsBlock = @convention(block) (AnyObject, CGRect) -> NSArray
    let block: FocusItemsBlock = { _, _ in
      // Hot-restart'ta iOS UIFocus ile FlutterView çakışmasını önler.
      return []
    }
    let implementation = imp_implementationWithBlock(block)
    method_setImplementation(method, implementation)
#endif
  }
}
