// boost_service.dart
//
// 🆕 בוסטים זמניים הנרכשים במטבעות בחנות (ראו shop_screen.dart) - "חצי
// שעה של רמזים מתנה" או "חצי שעה כפול נקודות", לפי בקשה מפורשת. בוסט
// אחד פעיל בכל רגע נתון (קנייה בזמן שכבר יש בוסט פעיל חסומה - ראו
// shop_screen.dart._buyBoost). המצב (סוג + זמן תפוגה) נשמר מקומית
// ב-SharedPreferences בלבד, לא מסונכרן בין מכשירים - זה מכוון: בוסט
// זמני כזה הגיוני שיהיה "ליחידת המשחק הנוכחית", לא עובר עם ההתקדמות.
import 'package:shared_preferences/shared_preferences.dart';

enum BoostType { freeHints, doublePoints }

class BoostService {
  BoostService._();

  // 🩹 קוצר מ-30 ל-15 דקות לפי בקשה מפורשת.
  static const Duration duration = Duration(minutes: 15);
  // 🩹 הועלה מ-100 ל-150 לפי בקשה מפורשת ("נראלי נמוך מידי") - גם אחרי
  // שרמזים-חינם הוגבל ל-boostHintsMaxPerPuzzle לחידה (ראו logo_level_screen.dart),
  // על פני חלון הבוסט (שעכשיו 15 דקות) אפשר לפתור כמה חידות, וזה עדיין
  // שווה יותר מ-150 אם קונים את אותם רמזים בנפרד (20/60 מטבעות לרמז).
  static const int priceCoins = 150;

  // 🆕 "טעימה" חינמית חד-פעמית - לפי בקשה מפורשת: קצרה בהרבה מהבוסט
  // האמיתי (3 דקות לעומת 15), כדי שמשתמש ירגיש בדיוק מה הוא מקבל ואז
  // ירצה להמשיך בתשלום (priceCoins) כשהיא נגמרת - "טעימה חינם" לפני
  // מכירה, לא תחליף לרכישה.
  static const Duration trialDuration = Duration(minutes: 3);

  static const _keyType = 'activeBoostType'; // 'hints' | 'double'
  static const _keyExpiresAt = 'activeBoostExpiresAt';
  static const _keyTrialGranted = 'boostFreeTrialGranted';

  /// הבוסט הפעיל כרגע, או null אם אין כזה/פג תוקף (ואז גם מנקה את המצב
  /// השמור כדי שבדיקות הבאות לא יצטרכו לחשב מחדש כל פעם).
  static Future<BoostType?> getActive() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_keyType);
    final expiresAt = prefs.getInt(_keyExpiresAt);
    if (typeStr == null || expiresAt == null) return null;
    if (DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      await prefs.remove(_keyType);
      await prefs.remove(_keyExpiresAt);
      return null;
    }
    return typeStr == 'hints' ? BoostType.freeHints : BoostType.doublePoints;
  }

  /// כמה זמן נשאר לבוסט הפעיל (Duration.zero אם אין בוסט פעיל).
  static Future<Duration> getRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_keyExpiresAt);
    if (expiresAt == null) return Duration.zero;
    final ms = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return ms > 0 ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// מפעיל בוסט חדש ל-[duration] (ברירת המחדל - משך הבוסט הרגיל). הקורא
  /// אחראי לוודא קודם שאין בוסט פעיל ושהמטבעות כבר נוכו בפועל (ראו
  /// shop_screen.dart._buyBoost) - הפונקציה הזו רק קובעת את מצב הבוסט עצמו.
  static Future<void> activate(BoostType type, {Duration? customDuration}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyType, type == BoostType.freeHints ? 'hints' : 'double');
    await prefs.setInt(_keyExpiresAt, DateTime.now().add(customDuration ?? duration).millisecondsSinceEpoch);
  }

  /// מעניק בוסט ניסיון חינמי חד-פעמי (רמזים חינם, [trialDuration] בלבד) -
  /// פעם אחת בלבד לכל שחקן, לעולם לא שוב (גם אם לא היה בוסט פעיל כרגע).
  /// נקרא מ-shop_screen.dart כשהחנות נפתחת בפעם הראשונה. מחזיר true אם
  /// הוענק כרגע (כדי שהמסך הקורא יידע להציג הודעה), false אם כבר נוצל
  /// בעבר או שיש בוסט אחר פעיל כרגע (לא דורסים בוסט שכבר שולם עליו).
  static Future<bool> grantFreeTrialIfEligible() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyTrialGranted) ?? false) return false;
    await prefs.setBool(_keyTrialGranted, true); // חד-פעמי - מסומן תמיד, גם אם לא הופעל כרגע בפועל
    if (await getActive() != null) return false;
    await activate(BoostType.freeHints, customDuration: trialDuration);
    return true;
  }

  /// "MM:SS" לתצוגה (ראו shopBoostActiveLabel).
  static String formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
