import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  static var screenshotChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    // 🐛 תוקן: firebase_messaging אמור לקרוא ל-registerForRemoteNotifications()
    // באופן אוטומטי אחרי requestPermission() מה-Dart - אבל בפרויקט הזה
    // ה-plugins (כולל firebase_messaging עצמו) נרשמים מאוחר יותר, בתוך
    // didInitializeImplicitFlutterEngine, ולא כאן כמו בפרויקט Flutter רגיל.
    // זה בדיוק התזמון שגרם ל-APNs token "אף פעם לא להגיע" (נבדק בפועל -
    // pushDebug הראה "APNs token NEVER arrived after 30s"). קוראים לזה
    // ישירות כאן, בקוד נייטיבי טהור שלא תלוי בתזמון ה-plugins בכלל - אפשר
    // לקרוא לזה גם לפני שהמשתמש אישר הרשאה (Apple תומכת בזה רשמית).
    application.registerForRemoteNotifications()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRecordingChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    AppDelegate.screenshotChannel = FlutterMethodChannel(
      name: "screenshot_guard",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }

  @objc private func handleScreenshotTaken() {
    AppDelegate.screenshotChannel?.invokeMethod("screenshotTaken", arguments: nil)
  }

  @objc private func handleRecordingChanged() {
    AppDelegate.screenshotChannel?.invokeMethod("recordingChanged", arguments: UIScreen.main.isCaptured)
  }
}