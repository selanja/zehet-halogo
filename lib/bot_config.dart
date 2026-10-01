// bot_config.dart
//
// מתג הפעלה/כיבוי מרחוק ליריבי-הבוט (דו-קרב, סדרת דו-קרב, ומירוץ), בלי
// עדכון לאפליקציה. נקרא מהמסמך meta/appConfig (אותו מסמך של minVersion -
// קריאה פתוחה, כתיבה רק ידנית דרך Firebase Console: Firestore Database ->
// meta -> appConfig -> Add field). שדות רלוונטים לבוטים (כולם אופציונליים):
//
//   botsEnabled         - boolean, false = כיבוי מלא של כל הבוטים (ברירת מחדל: true)
//   botsDuelEnabled     - boolean, false = בלי בוט בדו-קרב רגיל בלבד
//   botsSuperdualEnabled - boolean, false = בלי בוט בסדרת דו-קרב בלבד
//   botsRaceEnabled     - boolean, false = בלי בוט במירוץ בלבד
//   fakeOnlineBoostMin/fakeOnlineBoostMax - number (int), טווח "שחקנים
//                       מחוברים" מדומים להוסיף לתצוגת "X משחקים עכשיו"
//                       בתפריט הראשי - מוגרל מספר עצמאי לכל מוד (דו-קרב/
//                       סדרת דו-קרב/מירוץ - שלושתם נפרדים לגמרי, ראו
//                       presence_service.dart) בכל דקה בערך, כך שהוא גם
//                       נמוך יותר וגם "חי" (משתנה עם הזמן) במקום מספר
//                       קבוע. 0/0 = כבוי.
//
// אם המסמך לא נקרא (אין אינטרנט/שגיאה) - הבוט לא נכנס (בטוח יותר).
import 'package:cloud_firestore/cloud_firestore.dart';

class BotConfig {
  BotConfig._();

  /// [mode] = 'duel' | 'superdual' | 'race'
  static Future<bool> enabledFor(String mode) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('meta')
          .doc('appConfig')
          .get()
          .timeout(const Duration(seconds: 4));
      final data = doc.data();
      if (data == null) return true; // אין הגדרות בכלל - ברירת מחדל: פעיל
      if (data['botsEnabled'] == false) return false;
      if (mode == 'duel' && data['botsDuelEnabled'] == false) return false;
      if (mode == 'superdual' && data['botsSuperdualEnabled'] == false) return false;
      if (mode == 'race' && data['botsRaceEnabled'] == false) return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
