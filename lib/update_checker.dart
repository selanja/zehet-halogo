// update_checker.dart
// חנויות האפליקציות (App Store / Google Play) לא כופות עדכון גרסה
// אוטומטית - משתמש יכול להישאר על גרסה ישנה כרצונו, אלא אם המפתח בעצמו
// בונה בדיקה שחוסמת גרסאות ישנות. זה בדיוק מה שהקובץ הזה עושה, דרך
// Firestore (אותו פרויקט Firebase שכבר משמש לטבלת השיאים ולאיפוס מרחוק).
//
// ================================================================
// איך קובעים גרסה מינימלית מרחוק (חוסמת גרסאות ישנות ממנה):
// ================================================================
// 1. נכנסים למסוף Firebase (console.firebase.google.com) -> הפרויקט
//    -> Firestore Database -> אוסף "meta" -> מסמך "appConfig"
//    (אם המסמך לא קיים - יוצרים אותו).
// 2. מוסיפים/מעדכנים שדה "minVersion" (String, למשל "1.0.4") - כל
//    מכשיר עם גרסה מותקנת נמוכה מזה ייחסם במסך "נדרש עדכון" עד שיעדכן.
// 3. אופציונלי: שדה "updateMessage" (String) - טקסט מותאם אישית שיוצג
//    במסך החסימה. אם לא מוגדר, מוצג טקסט ברירת מחדל.
// 4. אופציונלי: שדות "storeUrlAndroid" ו-"storeUrlIos" (String) - קישור
//    ישיר לדף האפליקציה בחנות. בלי זה כפתור "עדכן עכשיו" לא יעשה כלום.
// 5. השינוי חי מיד לכל המשתמשים בפעם הבאה שהם פותחים את האפליקציה
//    (לא צריך לעדכן קוד או לפרסם גרסה חדשה כדי להפעיל/לכבות את החסימה).
//
// כדי "לשחרר" חסימה בלי לחכות שכולם יעדכנו - פשוט מורידים את minVersion
// בחזרה למספר נמוך (או מוחקים את השדה), וכל המכשירים ייפתחו מיד.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  /// משווה שתי גרסאות בפורמט "1.2.3" - מחזיר true אם current נמוכה מ-minimum
  static bool _isOlder(String current, String minimum) {
    List<int> parse(String v) => v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final c = parse(current);
    final m = parse(minimum);
    final len = c.length > m.length ? c.length : m.length;
    for (int i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv != mv) return cv < mv;
    }
    return false;
  }

  /// בודק מול Firestore אם צריך לחסום את האפליקציה עד לעדכון.
  /// מחזיר null אם הכל בסדר (או שאין אינטרנט/שגיאה - כדי לא לתקוע
  /// משתמש בגלל בעיית רשת זמנית), או מפה עם פרטי החסימה אם צריך לעדכן.
  static Future<Map<String, String>?> checkForRequiredUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final doc = await FirebaseFirestore.instance
          .collection('meta')
          .doc('appConfig')
          .get()
          .timeout(const Duration(seconds: 6));
      final data = doc.data();
      if (data == null) return null;

      final String? minVersion = (data['minVersion'] as String?)?.trim();
      if (minVersion == null || minVersion.isEmpty) return null;

      if (_isOlder(info.version, minVersion)) {
        return {
          'message': (data['updateMessage'] as String?) ??
              'גרסה חדשה של המשחק זמינה! יש לעדכן כדי להמשיך לשחק.',
          'storeUrlAndroid': (data['storeUrlAndroid'] as String?) ?? '',
          'storeUrlIos': (data['storeUrlIos'] as String?) ?? '',
          // 🆕 עיצוב מחדש - "גרסה X · נדרשת Y" בתחתית המסך (מסך 13 · עדכון
          // נדרש במוקאפ) - הגרסה המותקנת בפועל אצל המשתמש מול המינימום
          // הנדרש שהוגדר מרחוק.
          'currentVersion': info.version,
          'minVersion': minVersion,
        };
      }
      return null;
    } catch (e) {
      debugPrint('UPDATE CHECK ERROR: $e');
      return null; // בלי אינטרנט/שגיאה - לא חוסמים את המשתמש
    }
  }
}