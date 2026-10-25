// achievements_service.dart
//
// 🆕 מדליות והישגים - נותנים לשחקן חדש יעדים ותחושת התקדמות שלא תלויה
// ב-XP הכללי (שאצל שחקנים ותיקים גבוה מאוד). ההתקדמות נשמרת מקומית
// ב-SharedPreferences (מונים שמגדילים ממקומות שונים במשחק), והפרסים - מטבעות.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_id.dart';
import 'league_service.dart';
import 'player_sync.dart';

class AchievementDef {
  final String id;
  final String title;
  final String desc;
  final String counter; // duelWins | raceWins | logosSolved | bestStreak | daysPlayed | leagueTier
  final int goal;
  final int rewardCoins;
  final String medal; // אימוג'י המדליה
  const AchievementDef(this.id, this.title, this.desc, this.counter, this.goal, this.rewardCoins, this.medal);
}

class AchievementsService {
  AchievementsService._();

  static const List<AchievementDef> all = [
    AchievementDef('duel_1', 'ניצחון ראשון', 'נצחו בדו-קרב אחד', 'duelWins', 1, 20, '⚔️'),
    AchievementDef('duel_10', 'לוחם', 'נצחו ב-10 דו-קרבים', 'duelWins', 10, 60, '🛡️'),
    AchievementDef('duel_50', 'אלוף הזירה', 'נצחו ב-50 דו-קרבים', 'duelWins', 50, 200, '👑'),
    AchievementDef('race_1', 'מהיר על ההדק', 'נצחו במירוץ אחד', 'raceWins', 1, 20, '🏁'),
    AchievementDef('race_10', 'רץ מקצועי', 'נצחו ב-10 מירוצים', 'raceWins', 10, 60, '⚡'),
    AchievementDef('logos_25', 'מתחילים', 'פתרו 25 לוגואים', 'logosSolved', 25, 25, '🔍'),
    AchievementDef('logos_100', 'עין חדה', 'פתרו 100 לוגואים', 'logosSolved', 100, 60, '👁️'),
    AchievementDef('logos_300', 'מומחה מותגים', 'פתרו 300 לוגואים', 'logosSolved', 300, 150, '🧠'),
    AchievementDef('logos_600', 'אגדת הלוגואים', 'פתרו 600 לוגואים', 'logosSolved', 600, 300, '🏆'),
    AchievementDef('streak_5', 'על גלגל', 'רצף של 5 תשובות נכונות ברצף', 'bestStreak', 5, 30, '🔥'),
    AchievementDef('streak_15', 'בלתי עצור', 'רצף של 15 תשובות נכונות', 'bestStreak', 15, 100, '🚀'),
    AchievementDef('days_3', 'חוזרים', 'שחקו ב-3 ימים שונים', 'daysPlayed', 3, 30, '📅'),
    AchievementDef('days_7', 'קבועים', 'שחקו ב-7 ימים שונים', 'daysPlayed', 7, 80, '🗓️'),
    AchievementDef('days_30', 'נאמנים', 'שחקו ב-30 ימים שונים', 'daysPlayed', 30, 250, '💎'),
    AchievementDef('league_gold', 'ליגת הזהב', 'הגיעו לליגת זהב', 'leagueTier', 2, 150, '🥇'),
    AchievementDef('tafzoret_1', 'צייד תפזורת', 'סיימו עולם אחד בתפזורת', 'tafzoretWorldsCompleted', 1, 30, '🧩'),
    AchievementDef('tafzoret_5', 'מאסטר תפזורת', 'סיימו 5 עולמות בתפזורת', 'tafzoretWorldsCompleted', 5, 100, '🗂️'),
    AchievementDef('tafzoret_15', 'אלוף התפזורת', 'סיימו 15 עולמות בתפזורת', 'tafzoretWorldsCompleted', 15, 300, '🏅'),
    AchievementDef('tournament_1', 'אלוף היום', 'סיימו במקום הראשון בטורניר יומי', 'tournamentWins', 1, 50, '🏆'),
    AchievementDef('tournament_5', 'אלוף סדרתי', 'סיימו במקום הראשון ב-5 טורנירים יומיים', 'tournamentWins', 5, 150, '👑'),
  ];

  static const String _claimedKey = 'achClaimed';

  static String _counterKey(String c) => 'ach_$c';

  /// מגדיל מונה (duelWins/raceWins/logosSolved).
  static Future<void> inc(String counter, [int by = 1]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_counterKey(counter), (prefs.getInt(_counterKey(counter)) ?? 0) + by);
      syncMedalsToCloud(); // fire-and-forget - ראו ההסבר למטה
    } catch (_) {}
  }

  // ================================================================
  // 🆕 "כשאנשים רואים את ה-XP הגבוה בטבלה הם מוותרים" - הטבלה הארצית
  // (leaderboard_screen.dart) מציגה עכשיו גם דירוג לפי מדליות (0-15,
  // מספר הוגן וקרוב לכולם) כברירת מחדל, במקום XP גולמי. כדי שזה יהיה
  // דירוג *ארצי* אמיתי (לא רק מקומי אצלי) צריך לסנכרן את הספירה לענן -
  // לאותו מסמך leaderboard/{deviceId} הפתוח שכבר קיים (כמו league_service.dart).
  // מוגבל בקצב כדי לא להציף כתיבות בכל פתרון לוגו בודד.
  static final _db = FirebaseFirestore.instance;
  static const Duration _cloudSyncEvery = Duration(seconds: 60);
  static DateTime? _lastCloudSync;

  static Future<void> syncMedalsToCloud({bool force = false}) async {
    try {
      final now = DateTime.now();
      if (!force && _lastCloudSync != null && now.difference(_lastCloudSync!) < _cloudSyncEvery) return;
      _lastCloudSync = now;
      final prefs = await SharedPreferences.getInstance();
      final name = (prefs.getString('username') ?? '').trim();
      if (name.isEmpty) return;
      final count = await earnedCount();
      final id = await DeviceId.get();
      await _db.collection('leaderboard').doc(id).set({'name': name, 'medals': count}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// רושם שהיום שיחקו (לימי משחק שונים) - בטוח לקרוא כמה פעמים ביום.
  static Future<void> recordActiveDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = DateTime.now();
      final today = '${n.year}-${n.month}-${n.day}';
      final days = prefs.getStringList('ach_days') ?? <String>[];
      if (!days.contains(today)) {
        days.add(today);
        await prefs.setStringList('ach_days', days.length > 400 ? days.sublist(days.length - 400) : days);
      }
      syncMedalsToCloud();
    } catch (_) {}
  }

  static Future<int> progress(String counter) async {
    final prefs = await SharedPreferences.getInstance();
    switch (counter) {
      case 'bestStreak':
        return prefs.getInt('bestRandomStreak') ?? 0;
      case 'daysPlayed':
        return (prefs.getStringList('ach_days') ?? const []).length;
      case 'leagueTier':
        return LeagueService.getTier();
      default:
        return prefs.getInt(_counterKey(counter)) ?? 0;
    }
  }

  static Future<Set<String>> claimed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_claimedKey) ?? const []).toSet();
  }

  /// כמה הישגים הושגו ועוד לא נתבעו (לנקודה על הכפתור).
  /// כמה הישגים כבר הושגו בפועל (בין אם נתבעו או לא) - מוצג בכרטיס הפרופיל
  /// בתפריט הראשי במקום XP, כדי ששחקן חדש יראה יעד קרוב ("2/15") ולא ספירה
  /// שמדגישה כמה הוא מפגר אחרי ותיקים.
  static Future<int> earnedCount() async {
    var n = 0;
    for (final a in all) {
      if (await progress(a.counter) >= a.goal) n++;
    }
    return n;
  }

  static Future<int> unclaimedCount() async {
    final c = await claimed();
    var n = 0;
    for (final a in all) {
      if (!c.contains(a.id) && await progress(a.counter) >= a.goal) n++;
    }
    return n;
  }

  /// תובע פרס הישג. מחזיר את כמות המטבעות, או null אם אי אפשר.
  static Future<int?> claim(AchievementDef a) async {
    final prefs = await SharedPreferences.getInstance();
    final c = (prefs.getStringList(_claimedKey) ?? <String>[]).toList();
    if (c.contains(a.id)) return null;
    if (await progress(a.counter) < a.goal) return null;
    c.add(a.id);
    await prefs.setStringList(_claimedKey, c);
    await prefs.setInt('coins', (prefs.getInt('coins') ?? 15) + a.rewardCoins);
    PlayerSyncService.syncCurrentProgress();
    return a.rewardCoins;
  }
}
