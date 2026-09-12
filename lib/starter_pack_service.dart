// starter_pack_service.dart
//
// 🆕 "מארז פתיחה" (Starter Pack) - הצעת רכישה חד-פעמית ומוגבלת בזמן
// למשתמשים חדשים, אחרי שהם כבר התנסו טיפה במשחק (לא מיד בפתיחה
// הראשונה - זה מרגיש פחות אגרסיבי וממיר יותר טוב).
//
// ⚠️ לפי בקשה מפורשת: המארז לא צריך להיות תמיד אותו דבר. לכן בכל
// פעם שמשתמש הופך זכאי להצעה, נבחר רנדומלית אחד מ-7 מארזים שונים
// בשני מחירים (starter_pack_a..g ב-iap_manager.dart - תוכן שונה),
// והבחירה הזו נשמרת קבועה למשתמש הזה (לא מתחלפת בכל פעם שהחלון נפתח).
//
// לוגיקת הזכאות:
//   1. maxLevel >= _triggerAfterLevel (המשתמש כבר סיים לפחות 2 רמות -
//      לא מציגים למשתמש שעדיין לא הבין את המשחק בכלל).
//   2. עדיין לא נרכש (IapManager._grant שומר 'starterPackPurchased'=true).
//   3. יש חלון זמן מוגבל (offerWindowHours = 3 שעות בלבד) מהרגע
//      שההצעה "נפתחה" לראשונה למשתמש הזה - אחרי שהחלון נגמר, ההצעה
//      נעלמת לתמיד (לא מוצגת שוב) כדי לשמור על תחושת "הזדמנות אמיתית"
//      ולעודד רכישה מהירה.
//   4. המשתמש יכול ללחוץ "אולי מאוחר יותר" - זה סוגר את הדיאלוג הנוכחי
//      בלי לבטל את ההצעה (היא תופיע שוב בפעם הבאה שנכנסים למסך הבית,
//      כל עוד החלון עדיין לא נגמר).
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show Random;
import 'iap_manager.dart';

class StarterPackService {
  StarterPackService._();

  /// כמה רמות המשתמש צריך לסיים לפני שההצעה בכלל יכולה להופיע.
  static const int _triggerAfterLevel = 2;

  /// כמה שעות ההצעה נשארת פעילה מהרגע שהיא "נפתחה" בפעם הראשונה.
  static const int offerWindowHours = 3;

  /// בודק אם יש להציג את ההצעה כרגע. מחזיר את מזהה המוצר (starter_pack_a/b/c)
  /// אם כן, או null אם לא (כבר נרכש/עוד לא זכאי/החלון נגמר).
  static Future<String?> variantToShow({required int maxLevel}) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('starterPackPurchased') ?? false) return null;
    if (prefs.getBool('starterPackExpired') ?? false) return null;
    if (maxLevel < _triggerAfterLevel) return null;

    // בוחר (פעם אחת בלבד) איזה מארז מוצג למשתמש הזה, ומתי החלון נפתח.
    String? variant = prefs.getString('starterPackVariant');
    int? firstShownMs = prefs.getInt('starterPackFirstShownAt');

    if (variant == null || firstShownMs == null) {
      final options = IapManager.starterPackIds;
      variant = options[Random().nextInt(options.length)];
      firstShownMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString('starterPackVariant', variant);
      await prefs.setInt('starterPackFirstShownAt', firstShownMs);
    }

    final firstShown = DateTime.fromMillisecondsSinceEpoch(firstShownMs);
    final elapsed = DateTime.now().difference(firstShown);
    if (elapsed.inHours >= offerWindowHours) {
      // החלון נגמר בלי רכישה - מסמנים כ"פג תוקף" כדי שלא תוצג שוב אף פעם.
      await prefs.setBool('starterPackExpired', true);
      return null;
    }

    return variant;
  }

  /// כמה זמן נשאר להצעה (לתצוגת ספירה לאחור בדיאלוג/בחנות). null אם אין הצעה פעילה.
  static Future<Duration?> remaining() async {
    final prefs = await SharedPreferences.getInstance();
    final firstShownMs = prefs.getInt('starterPackFirstShownAt');
    if (firstShownMs == null) return null;
    final firstShown = DateTime.fromMillisecondsSinceEpoch(firstShownMs);
    final deadline = firstShown.add(const Duration(hours: offerWindowHours));
    final left = deadline.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// 🆕 בודק אם יש כרגע הצעת מארז פתיחה *פעילה וממתינה* (כבר הוצגה,
  /// עדיין לא נרכשה, עדיין בתוך חלון 3 השעות) - בלי לבחור וריאנט חדש
  /// אם עוד לא הוצגה בכלל. משמש את shop_screen.dart להצגת הבאנר הזהוב
  /// למעלה, כדי שהמשתמש יוכל למצוא את ההצעה גם אם סגר את הדיאלוג.
  static Future<String?> activePendingOffer() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('starterPackPurchased') ?? false) return null;
    if (prefs.getBool('starterPackExpired') ?? false) return null;
    final variant = prefs.getString('starterPackVariant');
    final firstShownMs = prefs.getInt('starterPackFirstShownAt');
    if (variant == null || firstShownMs == null) return null;
    final firstShown = DateTime.fromMillisecondsSinceEpoch(firstShownMs);
    final elapsed = DateTime.now().difference(firstShown);
    if (elapsed.inHours >= offerWindowHours) {
      await prefs.setBool('starterPackExpired', true);
      return null;
    }
    return variant;
  }
}