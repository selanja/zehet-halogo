// login_streak_service.dart
//
// 🆕 רצף כניסה יומי - כל יום שהמשתמש פותח את האפליקציה בפעם הראשונה
// באותו יום מקבל בונוס מטבעות (ולפעמים גם אנרגיה), וככל שנכנסים יום
// אחרי יום בלי לפספס - הבונוס גדל, במחזור של 7 ימים (יום 7 = "יאקפוט",
// ואז מתחיל מחזור חדש - אבל מונה הרצף הכולל, להצגה בלבד, ממשיך לעלות
// בלי הגבלה כל עוד לא מפספסים יום שלם). אם מפספסים יום - הרצף מתאפס
// ל-1 (לא נעלם לגמרי - חוזרים ליום 1 של מחזור חדש, לא "נענשים" בלי סוף).
//
// ⚠️ לא קשור בכלל ל"רצף" הקיים באפליקציה (bestRandomStreak - שיא רצף
// תשובות נכונות במצב רנדומלי, מוצג בכרטיס הסטטיסטיקות הראשי) - זה
// פיצ'ר נפרד לגמרי, ובכוונה עם שם ברור אחר ("רצף כניסה יומי") כדי
// שלא יתבלבלו.
//
// שמור מקומית בלבד (SharedPreferences) - כמו רוב הכלכלה באפליקציה
// (coins/xp/missions) - לא קריטי מספיק כדי להצדיק תלות ברשת/Firestore.
import 'package:shared_preferences/shared_preferences.dart';
import 'energy_service.dart';
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי בונוס רצף כניסה - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון במכשיר אחר

class LoginStreakResult {
  final int streakDay; // הרצף הכולל (עולה בלי הגבלה, לתצוגה/גאווה)
  final int dayInCycle; // 1-7 - לאיזה בונוס במחזור השבועי זה מתאים
  final int coins;
  final int energy;
  const LoginStreakResult({required this.streakDay, required this.dayInCycle, required this.coins, required this.energy});
}

class LoginStreakService {
  static const _keyCount = 'loginStreakCount';
  static const _keyLastDate = 'loginStreakLastDate';

  // 🆕 בונוסי המחזור השבועי - יום 7 הוא "יאקפוט" עם גם אנרגיה, כדי לתת
  // סיבה טובה לחזור כל יום ולא לפספס אף יום ברצף.
  static const List<Map<String, int>> _cycleRewards = [
    {'coins': 10, 'energy': 0},
    {'coins': 15, 'energy': 0},
    {'coins': 15, 'energy': 0},
    {'coins': 20, 'energy': 0},
    {'coins': 20, 'energy': 1},
    {'coins': 25, 'energy': 1},
    {'coins': 50, 'energy': 2},
  ];

  static String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// נקרא פעם אחת בכל פתיחה קרה של האפליקציה (ראו main_menu_screen.dart
  /// - _startSplashScreen). מחזיר null אם כבר "נכנסו" היום (או אם כבר
  /// בדקו פעם אחת באותה פתיחה) - כדי שהדיאלוג לא יופיע שוב ושוב.
  static Future<LoginStreakResult?> checkInIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dateKey(now);
    final lastDate = prefs.getString(_keyLastDate);
    if (lastDate == today) return null; // כבר נכנסו היום - אין בונוס נוסף

    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final currentCount = prefs.getInt(_keyCount) ?? 0;
    final newCount = (lastDate == yesterday) ? currentCount + 1 : 1;

    await prefs.setInt(_keyCount, newCount);
    await prefs.setString(_keyLastDate, today);

    final dayInCycle = ((newCount - 1) % 7) + 1;
    final reward = _cycleRewards[dayInCycle - 1];
    final coins = reward['coins']!;
    final energy = reward['energy']!;

    // מעניקים את הבונוס בפועל - אותה שיטה בדיוק כמו שאר הפרסים באפליקציה
    // (ראו missions_service.dart) - קריאה/כתיבה ישירות ל-SharedPreferences.
    final currentCoins = prefs.getInt('coins') ?? 15;
    await prefs.setInt('coins', currentCoins + coins);
    PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה בונוס רצף הכניסה לא מסתנכרן לחשבון Google/Apple מקושר
    if (energy > 0) {
      await EnergyService.addAmount(energy);
    }

    return LoginStreakResult(streakDay: newCount, dayInCycle: dayInCycle, coins: coins, energy: energy);
  }

  /// כמה ימים ברצף כרגע (לתצוגה בלבד, למשל בתג על מסך הבית) - בלי
  /// לגעת/לשנות שום דבר.
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCount) ?? 0;
  }

  /// 🆕 true אם כבר "נכנסו" (ונאסף הבונוס) היום - לתצוגה בלבד (למשל
  /// בדיאלוג "המתנות של היום"), בלי לגעת/לשנות שום דבר.
  static Future<bool> claimedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastDate);
    return lastDate == _dateKey(DateTime.now());
  }

  // 🆕 "המתנות אמור להראות את הרצף של הימים + מה קיבל היום ומה מקבל
  // מחר וכל השבוע" - כדי לצייר את שורת 7 הימים בדיאלוג (ראה
  // main_menu_screen.dart - _showDailyGiftsDialog) צריך גישה לטבלת
  // הפרסים השבועית עצמה (הייתה פרטית) ולדעת "באיזה יום במחזור אנחנו"
  // גם בלי לבצע check-in (סתם להציג, לא לצרוך).

  /// טבלת הפרסים של 7 ימי המחזור (אינדקס 0 = יום 1) - לתצוגה בלבד.
  static List<Map<String, int>> get cycleRewards => _cycleRewards;

  /// יום המחזור הנוכחי (1-7) - מבוסס על הרצף השמור, בלי לגעת/לשנות
  /// שום דבר (לא כמו checkInIfNewDay). אם עוד לא נכנסו אף פעם (רצף 0),
  /// מחזיר 1 (עדיין לא התחיל אף מחזור).
  static Future<int> getCurrentDayInCycle() async {
    final streak = await getCurrentStreak();
    if (streak <= 0) return 1;
    return ((streak - 1) % 7) + 1;
  }
}