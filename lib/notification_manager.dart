// notification_manager.dart
// התראות מקומיות (Local Notifications) - נשלחות ישירות מהמכשיר עצמו,
// בלי שרת/פוש חיצוני. כרגע משמש רק לתזכורת אחת: "בונוס 15 המטבעות
// תמורת פרסומת זמין שוב" - 3 שעות אחרי שנלקח (אותו Cooldown בדיוק
// כמו ב-shop_screen.dart).
//
// ⚠️ התקנה חד-פעמית נדרשת (לא קורית אוטומטית):
// 1. pubspec.yaml: הוספתי כבר flutter_local_notifications + timezone.
//    צריך להריץ פעם אחת: flutter pub get
// 2. אנדרואיד (android/app/src/main/AndroidManifest.xml) - לוודא שיש
//    את ההרשאות הבאות בתוך <manifest>:
//      <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//      <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//    🆕 בכוונה בלי SCHEDULE_EXACT_ALARM - ראו הסבר למטה.
// 3. iOS - אין צורך בשינוי ידני נוסף, הבקשה מוצגת אוטומטית ב-init().
//
// 🆕 תוקן: הוסרה ההסתמכות על AndroidScheduleMode.exactAllowWhileIdle
// (שדרשה הרשאת SCHEDULE_EXACT_ALARM) ועברנו ל-inexactAllowWhileIdle.
// ההרשאה הזו מיועדת בפועל לאפליקציות שעון מעורר/יומן, וגוגל פליי דורש
// עליה טופס הצהרה ייעודי בזמן פרסום - ואין קטגוריה מתאימה למשחק כמו
// שלנו. תזכורת "המטבעות שלך מחכות" לא חייבת להיות מדויקת לשנייה - היא
// יכולה להגיע כמה דקות אחרי 3 השעות בלי שום בעיה, אז אין שום צורך
// אמיתי בהרשאה הזו. חשוב: צריך גם למחוק ידנית את השורה
// <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
// מ-AndroidManifest.xml אם היא כבר שם - אחרת גוגל פליי עדיין ידרוש
// את ההצהרה גם אם הקוד לא באמת צריך אותה.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // 🩹 תוקן לפי דחיית Apple (Guideline 4.5.4): "The button in the app
  // settings was pre-set to enable notifications... does not request
  // and obtain the user's consent before sending push notifications" -
  // המתג "התראות" במסך ההגדרות הופיע כבר דלוק (true) עבור כל משתמש
  // חדש, בלי שהוא אי-פעם ביקש את זה בפועל - בדיוק מה שאפל פסלה. עכשיו
  // ברירת המחדל היא false: המתג מתחיל כבוי, ומופעל רק אם המשתמש עצמו
  // לוחץ עליו במפורש בהגדרות.
  static bool notificationsEnabled = false;

  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    } catch (_) {}
  }

  /// הפעלה/כיבוי של התראות (מהתפריט הגדרות) + שמירה. כיבוי מבטל מיד
  /// גם תזכורת שכבר מתוזמנת, כדי שלא תישלח אחרי שהמשתמש כיבה.
  ///
  /// 🩹 תוקן לפי דחייה חוזרת של Apple (Guideline 4.5.4) על אותה בעיה,
  /// למרות שברירת המחדל של המתג כבר הייתה false: הבעיה האמיתית הייתה
  /// שחלון ההרשאה המערכתי (iOS/Android) נפתח אוטומטית לכל משתמש חדש
  /// כבר ב-init() באתחול האפליקציה - לפני שהוא בכלל נגע במתג. זו לא
  /// "הסכמה לפני שליחה" בעיני אפל. עכשיו הבקשה למערכת מתבצעת רק כאן,
  /// בתגובה ישירה ללחיצת המשתמש על המתג בהגדרות.
  static Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', value);
    } catch (_) {}
    if (value) {
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint('NOTIFICATIONS PERMISSION REQUEST ERROR: $e');
      }
    } else {
      await cancelFreeCoinsReminder();
    }
  }

  /// מזהה קבוע להתראת בונוס המטבעות - כל תזמון חדש מבטל את הקודם,
  /// כדי שלא יצטברו כמה התראות כפולות אם המשתמש צופה בכמה פרסומות ברצף.
  // 🐛 תוקן: היה 1001 - בדיוק אותו מזהה כמו _energyFullNotificationId
  // ב-notification_service.dart (מחלקה נפרדת לגמרי, אבל flutter_local_notifications
  // מנהל את כל המזהים גלובלית בצד ה-native, לא לפי מופע Dart). שתי
  // ההתראות התחרו על אותו slot - איזו שתוזמנה אחרונה ביטלה בשקט את
  // השנייה, כך ששחקן שגם השלים אנרגיה וגם צפה בפרסומת למטבעות יכול
  // היה לפספס אחת מהתזכורות לגמרי בלי שום שגיאה. הועבר לטווח נפרד (2xxx).
  static const int _coinsBonusNotificationId = 2001;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await loadSettings();
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _plugin.initialize(settings);

      // 🩹 בכוונה בלי בקשת הרשאה כאן - ראו הסבר מעל setNotificationsEnabled().
      // הבקשה למערכת (אנדרואיד 13+ / iOS) מתבצעת אך ורק כשהמשתמש בעצמו
      // מפעיל את המתג "התראות" בהגדרות, לא אוטומטית לכל משתמש חדש כאן.
    } catch (e) {
      debugPrint('NOTIFICATIONS INIT ERROR: $e');
    }
  }

  /// מתזמן תזכורת בעוד [delay] (ברירת מחדל 3 שעות - תואם לזמן ה-Cooldown
  /// של הבונוס בחנות) שהבונוס זמין שוב. אם כבר יש תזכורת מתוזמנת - היא
  /// מבוטלת ומוחלפת בחדשה, כדי שתמיד תהיה בדיוק אחת פעילה.
  static Future<void> scheduleFreeCoinsReminder({Duration delay = const Duration(hours: 3)}) async {
    if (!notificationsEnabled) return;
    try {
      await _plugin.cancel(_coinsBonusNotificationId);
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
      await _plugin.zonedSchedule(
        _coinsBonusNotificationId,
        'המטבעות שלך מחכות',
        '15 מטבעות חינם זמינים עכשיו - בוא תיקח אותן',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'coins_bonus_channel',
            'תזכורות מטבעות',
            channelDescription: 'תזכורת כשבונוס המטבעות תמורת פרסומת זמין שוב',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('SCHEDULE NOTIFICATION ERROR: $e');
    }
  }

  /// מבטל את תזכורת בונוס המטבעות אם קיימת (למשל אם רוצים להימנע ממנה
  /// כשיש למשתמש מנוי ללא-פרסומות, או בכל מקרה אחר)
  static Future<void> cancelFreeCoinsReminder() async {
    try {
      await _plugin.cancel(_coinsBonusNotificationId);
    } catch (_) {}
  }
}