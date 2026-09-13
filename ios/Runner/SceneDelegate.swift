import Flutter
import UIKit

// 🆕 מסך "פרטיות" native - מוסתר תוכן המשחק לפני שהמערכת מצלמת את
// התמונה הממוזערת ל"חלוניות" (App Switcher). היה כבר טשטוש מקביל בצד
// Flutter (AppLifecycleManager ב-main.dart, מגיב ל-didChangeAppLifecycleState),
// אבל זה אסינכרוני מדי - התמונה הממוזערת נלכדת לפעמים *לפני* שהפריים
// המטושטש הספיק להצטייר, ולכן עדיין נראה תוכן אמיתי בחלוניות.
// sceneWillResignActive נקרא סינכרונית *לפני* הלכידה, אז הוספת שכבה
// ישירות ל-UIWindow כאן מבטיחה שהיא באמת תיתפס בתמונה הממוזערת.
class SceneDelegate: FlutterSceneDelegate {

  private var privacyOverlay: UIView?

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    showPrivacyOverlay()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    hidePrivacyOverlay()
  }

  private func showPrivacyOverlay() {
    guard privacyOverlay == nil, let window = self.window else { return }

    let overlay = UIView(frame: window.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    // צבע המותג (#201040) - אותו סגול כמו רקע האייקון/adaptive icon.
    overlay.backgroundColor = UIColor(red: 32.0 / 255.0, green: 16.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)

    let logo = UIImageView(image: UIImage(named: "PrivacyLogo"))
    logo.contentMode = .scaleAspectFit
    logo.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(logo)
    NSLayoutConstraint.activate([
      logo.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      logo.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      logo.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.5),
      logo.heightAnchor.constraint(equalTo: logo.widthAnchor),
    ])

    window.addSubview(overlay)
    privacyOverlay = overlay
  }

  private func hidePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
