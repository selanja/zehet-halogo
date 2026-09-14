// notification_service.dart
//
// 🆕 התראות מקומיות (Local Notifications) - רצות לגמרי במכשיר, בלי
// שרת. משמשות כרגע להתראה "האנרגיה שלך התמלאה!" - מתוזמנת מראש לפי
// כמה זמן נשאר עד לאנרגיה הבאה (ראו energy_service.dart).
//
// ⚠️ הבדל חשוב מהתראות Push אמיתיות (FCM): התראה מקומית שמתוזמנת
// מראש היא הבטחה חד-פעמית של המכשיר "תראה לי את זה בשעה X" - היא
// עובדת גם כשהאפליקציה סגורה לגמרי, בלי תלות באינטרנט. אבל היא לא
// יכולה, למשל, להודיע "נמצא לך יריב!" ברגע אמיתי שזה קורה בזמן
// שהאפליקציה סגורה - לזה צריך שרת (Cloud Function) ששולח דחיפה
// אמיתית ברגע האירוע. זה שלב נפרד וגדול יותר (וגם דורש תוכנית
// Firebase בתשלום - Blaze) - אם תרצה אותו, נבנה אותו בנפרד.
//
// התקנה נדרשת (ראו notifications_setup_instructions.txt):
//   flutter_local_notifications, timezone  ב-pubspec.yaml
//   + כמה שורות הרשאה ב-AndroidManifest.xml וב-Info.plist (iOS)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // מזהי התראות קבועים - כדי שאפשר יהיה לבטל/להחליף התראה ספציפית
  // (לא ליצור עשרות התראות כפולות בכל פעם שהפונקציה נקראת).
  static const int _energyFullNotificationId = 1001;
  // 🆕 התראות "חזרה למשחק" (re-engagement) - כמה נקודות זמן קבועות
  // אחרי הפעם האחרונה שהאפליקציה נפתחה, עם תוכן שונה בכל אחת.
  static const List<int> _comeBackNotificationIds = [1010, 1011, 1012];
  // 🆕 תזכורת יומית אחת ל"יש לך משימות חדשות + אתגר יומי מחכה" - שתי
  // הבשורות האלה מתאפסות באותו רגע בדיוק (חצות), אז מספיקה התראה אחת.
  static const int _dailyResetNotificationId = 1020;

  /// לקרוא פעם אחת בהפעלת האפליקציה (ב-main.dart, לפני runApp או מיד
  /// אחריו). מבקש הרשאת התראות (חובה מ-Android 13+ ו-iOS).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // מבקשים ידנית למטה, כדי לשלוט בתזמון הבקשה
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // בקשת הרשאה בפועל - ב-Android זה שקוף (no-op) בגרסאות ישנות מ-13,
    // וב-iOS זה מציג את הדיאלוג הרגיל של המערכת.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'energy_channel',
    'אנרגיה',
    channelDescription: 'התראה כשהאנרגיה לדו-קרב מתמלאת',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  /// מתזמן התראה מקומית "האנרגיה שלך התמלאה!" בעוד `delay`. אם כבר
  /// מתוזמנת התראה קודמת - היא מוחלפת (לא נערמות כמה התראות).
  static Future<void> scheduleEnergyFullNotification(Duration delay) async {
    if (!_initialized) return; // אם לא אותחל (למשל בקשת ההרשאה נדחתה) - שקט, בלי שגיאה
    await _plugin.cancel(_energyFullNotificationId);
    if (delay <= Duration.zero) return;
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    try {
      await _plugin.zonedSchedule(
        _energyFullNotificationId,
        'האנרגיה שלך מלאה',
        'יריב חדש מחכה - בואו נראה מי מכיר יותר לוגואים ב"זהה את הלוגו!"',
        scheduledDate,
        const NotificationDetails(android: _androidDetails, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // אם התזמון נכשל (למשל הרשאה נדחתה) - לא מפילים את האפליקציה
      // בגלל התראה; זו תוספת נחמדה, לא פיצ'ר קריטי.
    }
  }

  /// מבטל את התראת "אנרגיה מלאה" המתוזמנת (למשל כי האנרגיה כבר מלאה
  /// עכשיו ואין טעם להזכיר את זה שוב בעתיד).
  static Future<void> cancelEnergyFullNotification() async {
    if (!_initialized) return;
    await _plugin.cancel(_energyFullNotificationId);
  }

  static const AndroidNotificationDetails _comeBackAndroidDetails = AndroidNotificationDetails(
    'comeback_channel',
    'תזכורות חזרה למשחק',
    channelDescription: 'תזכורות ידידותיות לחזור לשחק אחרי כמה ימים של חוסר פעילות',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  // 🆕 3 הודעות שונות ב-3 נקודות זמן - יום, 3 ימים ושבוע בלי פעילות.
  // אם השחקן פותח את האפליקציה לפני שאחת מהן מגיעה - היא פשוט לא
  // תישלח (הפונקציה שמבטלת ומתזמנת מחדש נקראת בכל פתיחה, ראו
  // scheduleComeBackReminders למטה).
  static const List<Map<String, dynamic>> _comeBackSchedule = [
    {'days': 1, 'title': 'מתגעגעים אליך', 'body': 'לוגואים חדשים מחכים לך ב"זהה את הלוגו!" - בוא תמשיך בדיוק מאיפה שעצרת'},
    {'days': 3, 'title': 'האנרגיה שלך כבר מלאה', 'body': 'זה הזמן המושלם לדו-קרב קצר ולהרוויח עוד כמה מטבעות'},
    {'days': 7, 'title': 'שבוע שלם בלעדיך', 'body': 'שחקנים אחרים כבר מתקרבים אליך בטבלת השיאים - בוא תחזיר לעצמך את המקום'},
  ];

  /// לקרוא בכל פתיחת אפליקציה (main.dart, אחרי init()) - מבטל תזכורות
  /// "חזרה למשחק" קודמות ומתזמן מחדש 3 חדשות מהרגע הזה. ככה שחקן
  /// שממשיך לשחק כל יום לא מוצף בהתראות (הן כל הזמן "נדחות" קדימה),
  /// ורק שחקן שבאמת נעלם לכמה ימים יקבל אותן.
  static Future<void> scheduleComeBackReminders() async {
    if (!_initialized) return;
    for (final id in _comeBackNotificationIds) {
      await _plugin.cancel(id);
    }
    final now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < _comeBackSchedule.length; i++) {
      final entry = _comeBackSchedule[i];
      final scheduledDate = now.add(Duration(days: entry['days'] as int));
      try {
        await _plugin.zonedSchedule(
          _comeBackNotificationIds[i],
          entry['title'] as String,
          entry['body'] as String,
          scheduledDate,
          const NotificationDetails(android: _comeBackAndroidDetails, iOS: DarwinNotificationDetails()),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // לא קריטי - לא מפילים את האפליקציה בגלל תזכורת שלא הצליחה להתתזמן.
      }
    }
  }

  static const AndroidNotificationDetails _dailyResetAndroidDetails = AndroidNotificationDetails(
    'daily_reset_channel',
    'משימות ואתגר יומי',
    channelDescription: 'תזכורת כשיש משימות יומיות חדשות ואתגר יומי חדש',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  // 🆕 מתזמן תזכורת "משימות חדשות + אתגר יומי מחכה" לשעה 9 בבוקר של
  // ה-*איפוס הבא* (חצות הקרובה = תחילת יום חדש של משימות). קוראים לזה
  // בכל פתיחה של מסך הבית/המשימות - ככה התזכורת תמיד "מצביעה" קדימה
  // לאיפוס הבא, לא לאיפוס שכבר עבר. 9 בבוקר ולא בדיוק בחצות - כדי לא
  // להעיר אף אחד באמצע הלילה עם התראה על משחק לוגואים.
  static Future<void> scheduleDailyResetReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_dailyResetNotificationId);
    final now = tz.TZDateTime.now(tz.local);
    var nextReminder = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!nextReminder.isAfter(now)) {
      nextReminder = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 9);
    }
    try {
      await _plugin.zonedSchedule(
        _dailyResetNotificationId,
        'משימות חדשות מחכות לך',
        'האתגר היומי ומשימות חדשות כבר פתוחות ב"זהה את הלוגו!" - בוא תבדוק מה מחכה לך',
        nextReminder,
        const NotificationDetails(android: _dailyResetAndroidDetails, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // לא קריטי - לא מפילים את האפליקציה בגלל תזכורת שלא הצליחה להתתזמן.
    }
  }
}