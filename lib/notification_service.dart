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
  // 🆕 תזכורת "תזכיר לי מחר" - נלחצת ידנית ע"י השחקן במסך האתגר היומי
  // אחרי שסיים/ניצל את הניסיון של היום (ראו daily_challenge_screen.dart).
  static const int _dailyChallengeReminderNotificationId = 1030;
  // 🆕 "הטורניר של אתמול הסתיים" - מתוזמנת 24 שעות אחרי ששיחקו בטורניר
  // היומי, ומבוטלת אם הם כבר ראו את התוצאה באפליקציה לפני שההתראה נורתה
  // (ראו tournament_service.dart). טווח 3000+ חדש ונפרד - ראו ההערה
  // המתועדת ב-notification_manager.dart על התנגשות שכבר קרתה בעבר בין
  // שתי המחלקות האלה כששתיהן השתמשו באותו מספר.
  static const int _tournamentEndedNotificationId = 3001;
  // 🆕 "הטורניר המתוזמן מתחיל" - נרשמת רק אם השחקן לחץ מפורשות "הירשמו
  // מראש" (ראו ScheduledTournamentService.preRegisterForNext), לא
  // אוטומטית כמו רוב שאר התזכורות בקובץ הזה.
  static const int _scheduledTournamentStartNotificationId = 3002;

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
        'יריב חדש מחכה - בואו נראה מי מכיר יותר לוגואים',
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
    {'days': 1, 'title': 'מתגעגעים אליך', 'body': 'לוגואים חדשים מחכים לך - בוא תמשיך בדיוק מאיפה שעצרת'},
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
    'תזכורת יומית',
    channelDescription: 'תזכורת יומית אחת (לא יותר) לחזור לשחק - משימות/אתגר יומי/ליגה/רצף',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  // 🐛 תוקן: "הודעות יריב נמצא" (התראת אתגר-חבר, ראו functions/index.js)
  // קיבלו הגבלת קצב בשרת בנפרד - זה כאן פתרון קשור: תזכורת "חזרה למשחק"
  // אחת ביום, לא יותר, אבל עם כמה נוסחים שונים שמתחלפים כדי שלא תרגיש
  // כמו רובוט שחוזר על אותו משפט כל יום. בוחרים נוסח לפי היום בשנה (לא
  // רנדומלי) - כדי שבתוך יום נתון זה עדיין תמיד אותו נוסח (אם התזמון
  // רץ כמה פעמים באותו יום, לא "יתחלף" סתם), אבל בין יום ליום זה משתנה.
  static const List<Map<String, String>> _dailyVariants = [
    {'title': 'משימות חדשות מחכות לך', 'body': 'האתגר היומי ומשימות חדשות כבר פתוחות - בוא תבדוק מה מחכה לך'},
    {'title': 'הליגה השבועית שלך מתקדמת', 'body': 'שחקנים אחרים כבר משחקים היום - אל תישאר מאחור בדירוג'},
    {'title': 'האתגר היומי מחכה', 'body': 'כמה לוגואים תזהה היום? יש רק הזדמנות אחת ליום'},
    {'title': 'אל תפסיד את הרצף שלך', 'body': 'כניסה קצרה היום שומרת על רצף הימי הכניסה שלך חי'},
    {'title': 'הלוגו פאס שלך מתקדם', 'body': 'עוד כמה נקודות ואתה עולה רמה - משחק אחד קצר מספיק'},
  ];

  // 🆕 מתזמן תזכורת יומית אחת (לא יותר - ראו ההערה למעלה) לשעה 9 בבוקר
  // של ה-*איפוס הבא* (חצות הקרובה = תחילת יום חדש). קוראים לזה בכל
  // פתיחה של מסך הבית/המשימות - ככה התזכורת תמיד "מצביעה" קדימה לאיפוס
  // הבא, לא לאיפוס שכבר עבר. 9 בבוקר ולא בדיוק בחצות - כדי לא להעיר אף
  // אחד באמצע הלילה עם התראה על משחק לוגואים.
  static Future<void> scheduleDailyResetReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_dailyResetNotificationId);
    final now = tz.TZDateTime.now(tz.local);
    var nextReminder = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!nextReminder.isAfter(now)) {
      nextReminder = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 9);
    }
    final dayIndex = nextReminder.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final variant = _dailyVariants[dayIndex % _dailyVariants.length];
    try {
      await _plugin.zonedSchedule(
        _dailyResetNotificationId,
        variant['title']!,
        variant['body']!,
        nextReminder,
        const NotificationDetails(android: _dailyResetAndroidDetails, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // לא קריטי - לא מפילים את האפליקציה בגלל תזכורת שלא הצליחה להתתזמן.
    }
  }

  static const AndroidNotificationDetails _dailyChallengeReminderAndroidDetails = AndroidNotificationDetails(
    'daily_challenge_reminder_channel',
    'תזכורת אתגר יומי',
    channelDescription: 'תזכורת שהשחקן ביקש במפורש - "תזכיר לי מחר" במסך האתגר היומי',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  // 🆕 כפתור "תזכיר לי מחר" במסך האתגר היומי (אחרי שהושלם/נוצל הניסיון
  // של היום) - בניגוד לשאר התזכורות בקובץ הזה, זו לא מתוזמנת אוטומטית
  // אלא רק כשהשחקן מבקש את זה בפירוש, ולכן אין צורך לבטל/להחליף אותה
  // בכל פתיחת מסך - פשוט מתזמנים ב-24 שעות מרגע הלחיצה.
  static Future<void> scheduleDailyChallengeReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_dailyChallengeReminderNotificationId);
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
    try {
      await _plugin.zonedSchedule(
        _dailyChallengeReminderNotificationId,
        'האתגר היומי מחכה',
        'אתגר חדש וללוגו חדש לזהות - בוא תנסה היום',
        scheduledDate,
        const NotificationDetails(android: _dailyChallengeReminderAndroidDetails, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // לא קריטי - לא מפילים את האפליקציה בגלל תזכורת שלא הצליחה להתתזמן.
    }
  }

  static const AndroidNotificationDetails _tournamentEndedAndroidDetails = AndroidNotificationDetails(
    'tournament_ended_channel',
    'הטורניר היומי',
    channelDescription: 'תזכורת שהטורניר היומי שהשתתפת בו הסתיים - בוא לראות איך הלכת',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  // 🆕 נקרא מ-TournamentService.submitDayResult, אבל רק ביום האחרון של
  // האתגר הרב-יומי (ראו day >= tournamentEventDays שם) - מתוזמנת ל-24
  // שעות קדימה (בדיוק כשהתוצאה הסופית של האתגר כבר אמורה להיות זמינה).
  // מבטלת ומחליפה כל תזכורת קודמת מהסוג הזה (אותו דפוס בדיוק כמו
  // scheduleDailyChallengeReminder למעלה).
  static Future<void> scheduleTournamentEndedReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_tournamentEndedNotificationId);
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
    try {
      await _plugin.zonedSchedule(
        _tournamentEndedNotificationId,
        'האתגר הסתיים',
        'בוא לבדוק איך הלכת ולתפוס את הפרס שמחכה לך',
        scheduledDate,
        const NotificationDetails(android: _tournamentEndedAndroidDetails, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // לא קריטי - לא מפילים את האפליקציה בגלל תזכורת שלא הצליחה להתתזמן.
    }
  }

  // 🆕 נקרא מ-TournamentService.checkAndClaimPendingPrize ברגע שהתוצאה
  // כבר הוצגה בפועל בתוך האפליקציה (דרך החלונית) - אין טעם בתזכורת על
  // משהו שהשחקן כבר ראה.
  static Future<void> cancelTournamentEndedReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_tournamentEndedNotificationId);
  }

  static const AndroidNotificationDetails _scheduledTournamentStartAndroidDetails = AndroidNotificationDetails(
    'scheduled_tournament_channel',
    'טורניר מתוזמן',
    channelDescription: 'תזכורת שהטורניר המתוזמן שנרשמתם אליו מתחיל',
    importance: Importance.high,
    priority: Priority.high,
  );

  // 🆕 נקרא כשהשחקן לוחץ "הירשמו מראש וקבלו תזכורת" במסך הטורניר המתוזמן
  // (ScheduledTournamentService.preRegisterForNext) - מתוזמנת בדיוק לרגע
  // startTime (לא כמה דקות לפני - "יקבלו התראות עליו", הכי פשוט ומדויק).
  // startTime יכול להיות עד כ-24 שעות קדימה (אם נרשמים יום לפני).
  static Future<void> scheduleScheduledTournamentStartReminder(DateTime startTime) async {
    if (!_initialized) return;
    await _plugin.cancel(_scheduledTournamentStartNotificationId);
    if (!startTime.isAfter(DateTime.now())) return;
    final scheduledDate = tz.TZDateTime.from(startTime, tz.local);
    try {
      await _plugin.zonedSchedule(
        _scheduledTournamentStartNotificationId,
        'הטורניר המתוזמן מתחיל עכשיו! 🏆',
        'יש לכם שעה שלמה לענות - בואו תתפסו מקום בטבלה',
        scheduledDate,
        const NotificationDetails(android: _scheduledTournamentStartAndroidDetails, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // לא קריטי - לא מפילים את האפליקציה בגלל תזכורת שלא הצליחה להתתזמן.
    }
  }

  // 🆕 נקרא אם השחקן מבטל את ההרשמה-מראש, או אוטומטית אחרי שהוא כבר
  // הצטרף/שיחק בחלון (אין טעם בתזכורת למשהו שכבר קרה).
  static Future<void> cancelScheduledTournamentStartReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_scheduledTournamentStartNotificationId);
  }
}