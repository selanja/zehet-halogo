// energy_service.dart
//
// מערכת "אנרגיה" לדו-קרב - קיימת אך ורק כדי שדו-קרב לא יהפוך לדרך
// היחידה לשחק (המטרה שאתה ביקשת: "כדי שלא ישחקו רק אונליין"). לא נוגעת
// במשחק הרגיל/אתגר רנדומלי בכלל - שם, ולא במטבעות הרגילים.
//
//   מקסימום: 8 אנרגיות
//   כל דו-קרב עולה: 2 אנרגיות
//   מתמלא: אנרגיה אחת כל 5 דקות - **מבוסס זמן אמיתי**, כלומר גם אם
//   האפליקציה סגורה, כשחוזרים אליה מחשבים לפי כמה זמן עבר בפועל (לא
//   רק כשהאפליקציה פתוחה) - בדיוק כמו שביקשת.
//   אם אין אנרגיה בכלל: אפשר לצפות בפרסומת ולקבל +2 אנרגיה (משחק אחד).
//
// ⚠️ הערת אבטחה (כמו בכל שאר הכלכלה באפליקציה - מטבעות/XP): זה מחושב
// ונשמר בצד הלקוח (SharedPreferences), אין אימות מול שרת. שחקן עם ידע
// טכני יכול תיאורטית לקדם את שעון המכשיר כדי "לזייף" זמן שעבר ולקבל
// אנרגיה בחינם. זה עקבי עם רמת האבטחה הקיימת של כל שאר המשחק (מטבעות
// כבר נשמרים ומחושבים בצד הלקוח באותה צורה) - לא משהו חדש שנפתח כאן.

import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'notification_manager.dart'; // 🆕 מתג "האנרגיה התמלאה" בטאב ההתראות (ראו _syncFullEnergyNotification)

class EnergyService {
  EnergyService._();

  static const int maxEnergy = 8;
  static const int duelCost = 2;
  static const int regenMinutes = 5;
  static const int adRewardAmount = 2;

  static const _keyEnergy = 'duelEnergy';
  static const _keyLastUpdate = 'duelEnergyLastUpdateMs';
  // 🆕 קירור בין פרסומות-לאנרגיה (בקשה מפורשת: "שהפרסומת תהיה פעם ב-2
  // דקות") - בעבר לא היה שום קירור מבוסס-זמן, רק תלות בזמינות הפרסומת
  // עצמה מה-SDK (AdsManager.isRewardedReady). עכשיו יש גם קירור אמיתי -
  // אחרי כל פרסומת שהתקבל עליה תגמול, אי אפשר לצפות בעוד אחת עד שעברו
  // adEnergyCooldownMinutes דקות, גם אם ה-SDK "מוכן" עם פרסומת נוספת.
  static const _keyLastAdMs = 'duelEnergyLastAdMs';
  static const int adEnergyCooldownMinutes = 2;

  /// קורא את האנרגיה הנוכחית, אחרי שמחשב ומזכה אוטומטית כל אנרגיה
  /// שהצטברה מאז הפעם האחרונה (לפי זמן אמיתי שעבר, גם אם האפליקציה
  /// הייתה סגורה כל הזמן הזה).
  static Future<int> getCurrentEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    int energy = prefs.getInt(_keyEnergy) ?? maxEnergy;
    final lastUpdateMs = prefs.getInt(_keyLastUpdate);

    if (lastUpdateMs == null) {
      // פעם ראשונה - מתחילים עם אנרגיה מלאה ושומרים חותמת זמן נוכחית
      await prefs.setInt(_keyEnergy, energy);
      await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
      return energy;
    }

    if (energy < maxEnergy) {
      final elapsedMinutes = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastUpdateMs)).inMinutes;
      final regenerated = elapsedMinutes ~/ regenMinutes;
      if (regenerated > 0) {
        final newEnergy = (energy + regenerated).clamp(0, maxEnergy);
        // מקדמים את חותמת הזמן רק לפי כמות הדקות שבאמת "נוצלה" לאנרגיה
        // (לא מאפסים לגמרי) - כדי לא לאבד שניות עודפות מעל ל-5 הדקות
        // האחרונות שטרם הבשילו לאנרגיה נוספת.
        final consumedMs = regenerated * regenMinutes * 60 * 1000;
        await prefs.setInt(_keyLastUpdate, lastUpdateMs + consumedMs);
        await prefs.setInt(_keyEnergy, newEnergy);
        energy = newEnergy;
      }
    } else {
      // כבר מלא - אין טעם "לצבור" זמן, מרעננים את חותמת הזמן להווה
      await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
    }

    return energy;
  }

  // 🆕 מאפס לגמרי ל-0 - נקרא פעם אחת בדיוק כשמשתמש חדש לגמרי נרשם (ראו
  // main_menu_screen.dart, _saveWelcomeName) לפי בקשה מפורשת: "לפני
  // שהם מקבלים את המתנה לא יהיה להם מטבעות וזה" - כדי שמתנת סיום
  // ההדרכה (onboarding_gift_popup.dart) באמת תהיה המקור הראשון לאנרגיה
  // שלהם, במקום שהם כבר יתחילו עם אנרגיה מלאה (ברירת המחדל הרגילה)
  // ומתנת הסיום תרגיש מיותרת/כפולה.
  static Future<void> resetToZero() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEnergy, 0);
    await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
  }

  /// כמה זמן נשאר עד לאנרגיה הבאה (null אם כבר מלא) - לתצוגה כמו
  /// "עוד 03:24 לאנרגיה הבאה" במסך הלובי.
  static Future<Duration?> timeUntilNextEnergy() async {
    final energy = await getCurrentEnergy(); // מוודא שהחישוב/חותמת הזמן מעודכנים
    if (energy >= maxEnergy) return null;
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateMs = prefs.getInt(_keyLastUpdate)!;
    final nextTick = DateTime.fromMillisecondsSinceEpoch(lastUpdateMs).add(const Duration(minutes: regenMinutes));
    final remaining = nextTick.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// מנסה "לשלם" 2 אנרגיות עבור ניסיון דו-קרב (בתחילת החיפוש - גם אם
  /// בסוף לא נמצא יריב, ראה refundSearchEnergy למטה). מחזיר false אם
  /// אין מספיק אנרגיה.
  static Future<bool> spendForDuel() async {
    final energy = await getCurrentEnergy();
    if (energy < duelCost) return false;
    final prefs = await SharedPreferences.getInstance();
    final newEnergy = energy - duelCost;
    await prefs.setInt(_keyEnergy, newEnergy);
    await _syncFullEnergyNotification(newEnergy);
    return true;
  }

  /// מחזיר את 2 האנרגיות אם החיפוש נכשל (אין יריב זמין/בוטל/שגיאה) -
  /// הוגן: לא "לוקחים" אנרגיה על ניסיון שאפילו לא הפך למשחק אמיתי.
  /// 🐛 תיקון: התקרה כאן הייתה maxEnergy (8) - למי שקנה אנרגיה בכסף
  /// אמיתי ויש לו יותר מ-8 בפועל, החזר כזה היה "גוזם" לו את העודף חזרה
  /// ל-8 בטעות. עכשיו התקרה זהה לזו של רכישה (energyPurchaseCap).
  static Future<void> refundSearchEnergy() async {
    final energy = await getCurrentEnergy();
    final prefs = await SharedPreferences.getInstance();
    final newEnergy = (energy + duelCost).clamp(0, energyPurchaseCap);
    await prefs.setInt(_keyEnergy, newEnergy);
    await _syncFullEnergyNotification(newEnergy);
  }

  /// 🐛 תוקן (אותו באג בדיוק כמו ב-refundSearchEnergy למעלה, שתוקן שם
  /// אבל נשכח כאן): התקרה הייתה maxEnergy קבוע - למי שיש יותר מ-8
  /// אנרגיה בפועל (רכישה/פרס גדול), כל זיכוי נוסף (אפילו +1 מבונוס
  /// יומי) היה "גוזם" אותו בחזרה ל-8, הורס עודף ששולם עליו בכסף אמיתי.
  /// עכשיו התקרה היא maxEnergy כרגיל - חוץ ממצב שבו כבר יש יותר מזה
  /// (עודף מרכישה), ואז שומרים על העודף הקיים כתקרה במקום להרוס אותו.
  static int _capFor(int currentEnergy) => currentEnergy > maxEnergy ? energyPurchaseCap : maxEnergy;

  /// 🆕 זיכוי אנרגיה בכמות כלשהי (למשל בונוס יומי) - כללי יותר מ-
  /// addFromAd (שתמיד מזכה בדיוק adRewardAmount).
  static Future<void> addAmount(int amount) async {
    final energy = await getCurrentEnergy();
    final prefs = await SharedPreferences.getInstance();
    final newEnergy = (energy + amount).clamp(0, _capFor(energy));
    await prefs.setInt(_keyEnergy, newEnergy);
    await _syncFullEnergyNotification(newEnergy);
  }

  /// זיכוי אנרגיה תמורת צפייה בפרסומת (+2, מספיק לדו-קרב אחד). קוראים
  /// לזה רק אחרי שה-SDK בפועל זיכה בתגמול - כאן גם נרשמת חותמת הזמן
  /// לצורך הקירור (ראו canWatchAdForEnergy/timeUntilNextAdEnergy למטה).
  static Future<void> addFromAd() async {
    final energy = await getCurrentEnergy();
    final prefs = await SharedPreferences.getInstance();
    final newEnergy = (energy + adRewardAmount).clamp(0, _capFor(energy));
    await prefs.setInt(_keyEnergy, newEnergy);
    await prefs.setInt(_keyLastAdMs, DateTime.now().millisecondsSinceEpoch);
    await _syncFullEnergyNotification(newEnergy);
  }

  /// 🆕 האם עבר מספיק זמן (adEnergyCooldownMinutes) מהפרסומת הקודמת
  /// שקיבלה תגמול - יש לבדוק את זה *לפני* להציג/לפתוח פרסומת נוספת.
  static Future<bool> canWatchAdForEnergy() async {
    final remaining = await timeUntilNextAdEnergy();
    return remaining == null || remaining <= Duration.zero;
  }

  /// כמה זמן נשאר עד שאפשר לצפות בפרסומת נוספת תמורת אנרגיה - null אם
  /// אפשר כבר עכשיו (או שעדיין לא נצפתה שום פרסומת מעולם).
  static Future<Duration?> timeUntilNextAdEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAdMs = prefs.getInt(_keyLastAdMs);
    if (lastAdMs == null) return null;
    final nextAllowed = DateTime.fromMillisecondsSinceEpoch(lastAdMs).add(const Duration(minutes: adEnergyCooldownMinutes));
    final remaining = nextAllowed.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// 🆕 זיכוי אנרגיה תמורת רכישה אמיתית (חנות - ראה IapManager). **בכוונה
  /// לא מוגבל ל-maxEnergy** כמו addAmount/addFromAd הרגילים - אם מגבילים
  /// לתקרה של 8, חבילות של 15/30 אנרגיה כמעט תמיד "יתבזבזו" (רוב הכמות
  /// שנקנתה בכסף אמיתי פשוט תיעלם ברגע הרכישה אם כבר יש קצת אנרגיה) -
  /// זה לא הוגן כלפי מי שמשלם. יש תקרה גבוהה מאוד (energyPurchaseCap)
  /// רק כדי למנוע מספר לא סביר/באג, לא כדי להגביל שימוש רגיל.
  static const int energyPurchaseCap = 999;
  static Future<void> addFromPurchase(int amount) async {
    final energy = await getCurrentEnergy();
    final prefs = await SharedPreferences.getInstance();
    final newEnergy = (energy + amount).clamp(0, energyPurchaseCap);
    await prefs.setInt(_keyEnergy, newEnergy);
    await _syncFullEnergyNotification(newEnergy);
  }

  // 🆕 אחרי כל שינוי באנרגיה - מתזמנים מחדש (או מבטלים, אם כבר מלא)
  // התראה מקומית "האנרגיה שלך התמלאה!" לרגע שבו היא תגיע ל-8/8.
  // 🐛 תוקן: "לוחצים על הימור בדו-קרב, האנרגיה יורדת אבל שום דבר לא
  // קורה - לא מגיע למסך 'מחפש יריב' בכלל" - קרה למשתמש אחר (מכשיר שונה).
  // שורש הבעיה: spendForDuel() קורא לפונקציה הזו כצעד האחרון שלו, ו-
  // NotificationService.cancelEnergyFullNotification() (ו-_plugin.cancel
  // בתוך scheduleEnergyFullNotification, לפני ה-try הפנימי שלה) לא היו
  // עטופים ב-try/catch - אם הקריאה הזו נכשלת (למשל הרשאת התראות לא
  // ניתנה במכשיר הזה), החריגה עפה למעלה ועוצרת את כל שרשרת ה-await
  // *אחרי* שהאנרגיה כבר נוכתה בפועל אבל *לפני* ש-_startSearch() בכלל
  // נקרא - בדיוק התסמינים שתוארו. התראה על אנרגיה מלאה היא תוספת נחמדה,
  // לא פיצ'ר קריטי - כישלון בה לעולם לא אמור לעצור פעולת משחק אמיתית.
  static Future<void> _syncFullEnergyNotification(int energy) async {
    try {
      if (energy >= maxEnergy) {
        await NotificationService.cancelEnergyFullNotification();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateMs = prefs.getInt(_keyLastUpdate) ?? DateTime.now().millisecondsSinceEpoch;
      final energiesNeeded = maxEnergy - energy;
      final fullAt = DateTime.fromMillisecondsSinceEpoch(lastUpdateMs).add(Duration(minutes: regenMinutes * energiesNeeded));
      // 🆕 מגודר לפי מתג "האנרגיה התמלאה" בטאב ההתראות - ראו notification_manager.dart.
      if (NotificationManager.notificationsEnabled && NotificationManager.energyNotificationsEnabled) {
        await NotificationService.scheduleEnergyFullNotification(fullAt.difference(DateTime.now()));
      } else {
        await NotificationService.cancelEnergyFullNotification();
      }
    } catch (_) {
      // שקט בכוונה - ראו ההסבר למעלה.
    }
  }
}