// screenshot_guard_service.dart
//
// 🆕 "שומר צילומי מסך" - רלוונטי רק ב-iOS. מטפל בשני דברים שונים
// לגמרי מבחינת מה שבאמת אפשר לעשות בפועל באייפון:
//
// 1. זיהוי צילום מסך *אחרי* שהוא כבר קרה - אין שום דרך למנוע את
//    הצילום עצמו באייפון (מדיניות מפורשת ומכוונת של אפל, לא מגבלה
//    טכנית שאפשר לעקוף) - אז כל מה שאפשר זה להראות למשתמש הודעת
//    אזהרה אחרי המעשה (ראו onScreenshotTaken למטה, מחובר ב-main.dart).
//
// 2. זיהוי הקלטת מסך *בזמן אמת* (UIScreen.isCaptured) - את זה כן
//    אפשר לתפוס תוך כדי: כל עוד יש הקלטה פעילה, מציגים את מסך הטשטוש
//    (אותו אחד שכבר קיים למעבר לרקע ב-main.dart) - כך שההקלטה בפועל
//    "תתעד" מסך מטושטש, לא את תוכן המשחק.
//
// ⚠️ דורש שינוי native ב-iOS (AppDelegate.swift) - לא Flutter טהור,
// ולכן לא יכולתי לשלוח קובץ מוכן (לא ידוע לי המבנה המדויק של הקובץ
// אצלך). ראו את קובץ ההוראות ios_screenshot_detection_instructions.txt
// ששלחתי בנפרד להוספה המדויקת. בלי זה, השירות הזה פשוט לא יקבל אף
// קריאה מה-native side (לא יקרוס, פשוט לא יעשה כלום בשקט).
//
// באנדרואיד לא רלוונטי בכלל - שם כבר יש פתרון חזק בהרבה (FLAG_SECURE,
// ראו android_flag_secure_instructions.txt) שחוסם את הצילום מלכתחילה
// ולא רק מזהה אותו אחרי המעשה.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// true כל עוד יש הקלטת מסך פעילה כרגע - ValueNotifier גלובלי כדי
/// ש-AppLifecycleManager (ב-main.dart) יוכל "לדרוש" טשטוש גם מהמקור
/// הזה, בנוסף למעבר לרקע הרגיל, בלי שני הצדדים צריכים לדעת אחד על השני.
final ValueNotifier<bool> isScreenRecordingNow = ValueNotifier<bool>(false);

class ScreenshotGuardService {
  ScreenshotGuardService._();

  static const _channel = MethodChannel('screenshot_guard');
  static bool _initialized = false;

  /// callback אופציונלי שרץ כל פעם שזוהה צילום מסך (אחרי המעשה) -
  /// לדוגמה הצגת הודעת אזהרה. לא חובה להגדיר - אם לא מוגדר, פשוט
  /// נרשם ל-debug log ותו לא. ראו main.dart לחיבור בפועל.
  static VoidCallback? onScreenshotTaken;

  /// 🆕 callback נוסף - רץ רק מהצילום *השני* ואילך (לא מהראשון), לפי
  /// בקשה מפורשת: "בפעם הראשונה התראה, בפעם השנייה מעביר שלב בלי אופציה
  /// לחזור". מחובר ב-logo_level_screen.dart (המסך היחיד שבו "שלב" רלוונטי) -
  /// אם אף מסך לא מאזין כרגע (למשל השחקן בתפריט), פשוט לא קורה כלום.
  static VoidCallback? onRepeatedScreenshot;

  static const _keyScreenshotCount = 'screenshotWarningCount';

  /// לקרוא פעם אחת ב-main.dart. לא עושה כלום באנדרואיד (מחזיר מיד).
  static void init() {
    if (_initialized || !Platform.isIOS) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'screenshotTaken':
          debugPrint('ScreenshotGuard: זוהה צילום מסך');
          onScreenshotTaken?.call();
          final prefs = await SharedPreferences.getInstance();
          final count = (prefs.getInt(_keyScreenshotCount) ?? 0) + 1;
          await prefs.setInt(_keyScreenshotCount, count);
          if (count >= 2) onRepeatedScreenshot?.call();
          break;
        case 'recordingChanged':
          isScreenRecordingNow.value = (call.arguments as bool?) ?? false;
          break;
        default:
          break;
      }
    });
  }
}