// debug_log.dart
// ⚠️ מערכת הדיבאג (יומן אבחון) המקורית הוסרה לגמרי לפי בקשה - היא כתבה
// ל-Firestore כמעט על כל פעולה של המשתמש, וזה יצר עומס/בלגן במסד הנתונים.
// הבאג שהיא נועדה לאתר (הקריסה באייפון) כבר נמצא ותוקן (ראה app_background.dart
// ו-main_menu_screen.dart), אז אין יותר צורך במערכת הזו בכלל.
//
// כל הקוד באפליקציה (iOS ו-Android כאחד - זה קוד Dart משותף) עדיין קורא
// ל-DebugLog.add(...) במקומות רבים. כדי לא לצטרך לגעת בעשרות מקומות
// בקבצים אחרים, ה-class נשאר קיים עם אותה חתימה בדיוק, אבל DebugLog.add()
// עצמה נשארת "no-op" - היא לא עושה שום דבר: לא כותבת לקובץ, לא ל-
// SharedPreferences, ולא ל-Firestore. אפס כתיבות, אפס עומס.
//
// 🆕 DebugLog.reportError(...) - זה *כן* כותב ל-Firestore, אבל בכוונה זה
// method נפרד לגמרי מ-DebugLog.add() הישן: הוא לא נקרא אוטומטית מכל
// הקריאות הישנות שכבר קיימות בקוד (עשרות מקומות) - רק ממקומות ספציפיים
// וחדשים שאני מוסיף בכוונה (שגיאות matchmaking אמיתיות בדו-קרב/מרוץ),
// כדי לאתר את הבאג של "נתקע באייפון" בלי להחזיר את עומס הכתיבה הישן.
// כותב לאותו אוסף debugLogs שכבר פתוח לכתיבה ב-firestore.rules (היה
// בשימוש למטרה הזו בדיוק בעבר) - אין צורך בשינוי כללי הרשאות.
// ⚠️ גם זה זמני לצורך האבחון הנוכחי - כדאי למחוק את זה ואת ה-rule
// המתאים אחרי שהבאג נמצא ותוקן, בדיוק כמו שתוכנן במקור.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'device_id.dart';

class DebugLog {
  /// לא עושה כלום יותר - נשאר כדי שקריאות DebugLog.add(...) הקיימות
  /// בקוד ימשיכו להתקמפל בלי שינוי בכל הקבצים האחרים.
  static void add(String message) {
    // no-op בכוונה
  }

  /// אין יותר יומן לקרוא - תמיד מחזיר רשימה ריקה.
  static Future<List<String>> readAll() async => <String>[];

  /// אין יותר מה לנקות.
  static Future<void> clear() async {}

  /// 🆕 מדווח שגיאה אמיתית ל-Firestore (אוסף debugLogs/{deviceId}, שדה
  /// errors - מערך שמצטבר) - לצורך אבחון בעיות matchmaking/רשת שקורות
  /// רק באייפון. לא זורק שגיאה בעצמו אם הכתיבה נכשלת (עטוף ב-try/catch)
  /// כדי שלעולם לא יגרום לקריסה/תקיעה נוספת בגלל ניסיון הדיווח עצמו.
  static Future<void> reportError(String source, String message) async {
    try {
      final deviceId = await DeviceId.get();
      await FirebaseFirestore.instance.collection('debugLogs').doc(deviceId).set({
        'lastPlatform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
        'lastSource': source,
        'lastMessage': message,
        'lastAt': FieldValue.serverTimestamp(),
        'errors': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()} · ${Platform.isIOS ? 'iOS' : 'Android'} · $source: $message',
        ]),
      }, SetOptions(merge: true));
    } catch (_) {
      // בכוונה שקט - דיווח שנכשל לא אמור לגרום לבעיה נוספת.
    }
  }
}