// main_dart_additions_snippet.dart
//
// לא קובץ עצמאי - זה מה שצריך להוסיף בתוך main.dart הקיים שלך.
// ארבעה חלקים: (1) App Check, (2) הגנת צילומי מסך, (3) התראות Push,
// (4) מערכת רכישות. כולם נכנסים מיד אחרי Firebase.initializeApp(),
// לפני runApp().

// ---- ימפורטים להוסיף בראש הקובץ ----
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screenshot_protection.dart'; // הקובץ ששלחתי קודם
import 'push_notification_service.dart';
import 'purchase_service.dart';

// ---- בתוך void main() async { ... }, אחרי Firebase.initializeApp() ----

Future<void> initSecurityAndProtection() async {
  // 1) App Check - מוודא שהבקשות ל-Firebase מגיעות מהאפליקציה האמיתית
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // 2) חוסם צילומי מסך/הקלטה באנדרואיד, ומטשטש את המסך באייפון בזמן
  //    הקלטת מסך/מעבר בין אפליקציות - בלי שום הודעה למשתמש, רק טשטוש שקט
  await ScreenshotProtection.enable();

  // 3) Push Notifications - מבקש הרשאה ושומר את ה-FCM token של המכשיר
  //    ב-Firestore, כדי שאפשר יהיה לשלוח אליו התראות (אוטומטיות/ידניות)
  await PushNotificationService.init();

  // 4) מערכת רכישות - טוען את פרטי המוצרים מהחנות ומתחיל להאזין לרכישות.
  //    ה-callback כאן הוא המקום שבו בפועל "נותנים" לשחקן את מה שקנה
  //    (למשל מוסיפים לו מטבעות, או מסמנים remove_ads=true) - תלוי במבנה
  //    ה-state/provider שלך למטבעות. תעדכן את התוכן בפנים לפי המבנה שלך.
  await PurchaseService.init(
    onPurchaseGranted: (productId) {
      switch (productId) {
        case 'coins_pack_small':
          // TODO: להוסיף למשתמש X מטבעות (למשל 100)
          break;
        case 'coins_pack_medium':
          // TODO: להוסיף למשתמש Y מטבעות (למשל 300)
          break;
        case 'coins_pack_large':
          // TODO: להוסיף למשתמש Z מטבעות (למשל 700)
          break;
        case 'remove_ads':
          // TODO: לשמור דגל removeAds=true (מקומית + ב-players/{deviceId})
          break;
      }
    },
  );
}

// ---- הקריאה בפועל בתוך main() ----
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   await initSecurityAndProtection();  // <-- השורה החדשה
//   runApp(const MyApp());
// }