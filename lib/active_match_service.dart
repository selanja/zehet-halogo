// active_match_service.dart
//
// 🆕 "המערכת צריכה לזהות שהטלפון היה במשחק ולהכניס אותו ישר" - שומר
// מקומית איזה משחק רב-משתתפים (דו-קרב/מרוץ) פעיל כרגע. אם האפליקציה
// נסגרת לגמרי (לא רק ממוזערת) ונפתחת מחדש בזמן שהמשחק עדיין 'playing' -
// main.dart בודק את זה לפני שמראה את מסך הבית, ומחזיר את השחקן ישר
// לתוך המשחק במקום שהוא "ייעלם" מבחינת היריב (ראו גם duel_service.dart
// / _buildWaitingForReconnectOverlay ב-duel_room_screen.dart/logo_race_screen.dart -
// זה בדיוק מה שנותן ליריב סיכוי אמיתי לחזור בתוך חלון הזמן).
//
// נשמר ב-initState של מסך המשחק (ברגע שיש matchId אמיתי), ונמחק ב-dispose
// שלו - בכוונה לא "מנוקה" בשום מקום אחר: אם ה-dispose לא הספיק לרוץ (למשל
// האפליקציה נהרגה על ידי המערכת/המשתמש), המצביע *נשאר* קיים - זה בדיוק
// המצב שאנחנו רוצים לזהות בפתיחה הבאה.
import 'package:shared_preferences/shared_preferences.dart';

enum ActiveMatchType { duel, race }

class ActiveMatchInfo {
  final ActiveMatchType type;
  final String matchId;
  const ActiveMatchInfo({required this.type, required this.matchId});
}

class ActiveMatchService {
  ActiveMatchService._();

  static const _keyType = 'activeMatchType';
  static const _keyId = 'activeMatchId';
  static const _keySavedAt = 'activeMatchSavedAt';

  // 🆕 גיל מקסימלי - שום דו-קרב/מרוץ אמיתי לא נמשך שעתיים. אם המצביע ישן
  // יותר (למשל dispose פשוט לא רץ מסיבה כלשהי בעבר, או שהמשתמש לא פתח
  // את האפליקציה הרבה זמן) - מתעלמים ממנו לגמרי בלי אפילו לבדוק Firestore.
  static const Duration maxAge = Duration(hours: 2);

  static Future<void> save({required ActiveMatchType type, required String matchId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyType, type.name);
    await prefs.setString(_keyId, matchId);
    await prefs.setInt(_keySavedAt, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyType);
    await prefs.remove(_keyId);
    await prefs.remove(_keySavedAt);
  }

  /// לא בודק מול Firestore בכלל - רק קורא את המצביע המקומי (ומנקה אותו
  /// אם עבר את הגיל המקסימלי). הבדיקה שהמשחק עצמו עדיין 'playing' באמת
  /// נעשית בנפרד ב-main.dart (צריך גישה לרשת ולכן לא מתאים לפונקציה הזו).
  static Future<ActiveMatchInfo?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_keyType);
    final id = prefs.getString(_keyId);
    final savedAtMs = prefs.getInt(_keySavedAt);
    if (typeStr == null || id == null || savedAtMs == null) return null;
    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(savedAtMs));
    if (age > maxAge) {
      await clear();
      return null;
    }
    final type = typeStr == 'race' ? ActiveMatchType.race : ActiveMatchType.duel;
    return ActiveMatchInfo(type: type, matchId: id);
  }
}
