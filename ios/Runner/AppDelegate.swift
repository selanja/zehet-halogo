import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // 🆕 ערוץ ה-MethodChannel של screenshot_guard_service.dart (בצד Dart) -
  // סטטי כדי שהאזנת ה-NotificationCenter למטה (שנרשמת פעם אחת ב-
  // didFinishLaunchingWithOptions, לפני שהמנוע/הערוץ בהכרח קיימים) תוכל
  // להשתמש בו ברגע שהוא כן נוצר (ב-didInitializeImplicitFlutterEngine).
  static var screenshotChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 🆕 חובה כדי שהתראות מקומיות (flutter_local_notifications) יעבדו
    // כמו שצריך ב-iOS - בלי זה, למשל, לא יתקבלו קריאות callback כשהמשתמש
    // לוחץ על ההתראה בזמן שהאפליקציה פתוחה ברקע.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    // 🆕 זיהוי צילום מסך (אחרי המעשה - אין דרך לחסום אותו ב-iOS) והקלטת
    // מסך (בזמן אמת) - ראו screenshot_guard_service.dart בצד Dart להסבר
    // המלא. שני האירועים מדווחים דרך אותו MethodChannel.
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