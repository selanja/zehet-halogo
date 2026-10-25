// tafzoret_service.dart
//
// לוגיקת ההתקדמות של מצב "תפזורת" - עצמאית לגמרי מהמשחק הראשי (כל
// מפתחות ה-SharedPreferences כאן עם קידומת tafzoret, ראו tafzoret_data.dart).
//
// כל עולם: 30 לוגואים קבועים (tafzoretWorlds[world]). שחקן שפותר לפחות
// tafzoretPassThreshold (25) מתוך 30 פותח את העולם הבא. סיום מלא (30/30)
// מזכה בפרס חד-פעמי (מטבעות + XP + נקודות Logo Pass). אפשר גם לדלג על
// עולם בלי לסיים אותו בתשלום (ראו IapManager.unlockTafzoretWorldId) -
// אותו רעיון בדיוק כמו פתיחת רמה בתשלום במשחק הראשי, רק עם מפתחות נפרדים.
import 'package:shared_preferences/shared_preferences.dart';
import 'tafzoret_data.dart';
import 'battle_pass_service.dart';
import 'achievements_service.dart';
import 'missions_service.dart';
import 'player_sync.dart';

/// פרס חד-פעמי על סיום מלא (30/30) של עולם תפזורת.
const int tafzoretWorldCoinsReward = 40;
const int tafzoretWorldXpReward = 400;
const int tafzoretWorldBattlePassPoints = 250;

class TafzoretService {
  TafzoretService._();

  static String _solvedKey(int world) => 'tafzoretSolved_$world';
  static const String _unlockedWorldKey = 'tafzoretUnlockedWorld';
  static const String _completedWorldsKey = 'tafzoretCompletedWorlds';

  /// העולם הגבוה ביותר שפתוח כרגע (1 = רק עולם 1 פתוח, ברירת המחדל).
  static Future<int> unlockedWorld() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedWorldKey) ?? 1;
  }

  static Future<bool> isWorldUnlocked(int world) async {
    if (world <= 1) return true;
    final unlocked = await unlockedWorld();
    return world <= unlocked;
  }

  /// מזהי הלוגואים (TafzoretLogo.id) שכבר נפתרו נכון בעולם הזה.
  static Future<Set<String>> solvedIdsForWorld(int world) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_solvedKey(world)) ?? const []).toSet();
  }

  static Future<bool> isWorldFullyCompleted(int world) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList(_completedWorldsKey) ?? const [];
    return done.contains(world.toString());
  }

  /// רושם פתרון נכון של לוגו אחד. מחזיר (passedThisTime, justFullyCompleted)
  /// כדי שהמסך ידע אם צריך להראות פופאפ "העולם נפתח!" / "העולם הושלם!".
  static Future<({bool justUnlockedNext, bool justFullyCompleted})> markSolved(
    int world,
    String logoId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final solved = (prefs.getStringList(_solvedKey(world)) ?? const []).toSet();
    final wasAlreadySolved = solved.contains(logoId);
    solved.add(logoId);
    await prefs.setStringList(_solvedKey(world), solved.toList());

    bool justUnlockedNext = false;
    bool justFullyCompleted = false;

    if (!wasAlreadySolved) {
      final total = tafzoretWorlds[world]?.length ?? tafzoretLogosPerWorld;
      // פותח את העולם הבא ברגע שחוצים את הסף, לא רק כשמגיעים בדיוק אליו -
      // כך גם שחקן שכבר עבר את הסף לפני ה-markSolved האחרון (למשל חזר
      // לפתור לוגו שפספס) עדיין פותח את הבא כראוי.
      if (solved.length >= tafzoretPassThreshold) {
        final currentUnlocked = prefs.getInt(_unlockedWorldKey) ?? 1;
        if (world + 1 > currentUnlocked && world < tafzoretWorldCount) {
          await prefs.setInt(_unlockedWorldKey, world + 1);
          justUnlockedNext = true;
        }
      }

      if (solved.length >= total) {
        final done = prefs.getStringList(_completedWorldsKey) ?? const [];
        if (!done.contains(world.toString())) {
          final newDone = [...done, world.toString()];
          await prefs.setStringList(_completedWorldsKey, newDone);
          justFullyCompleted = true;
          await _grantWorldCompletionReward();
          await AchievementsService.inc('tafzoretWorldsCompleted');
          MissionsService.recordEvent(MissionEvent.tafzoretWorldCompleted);
        }
      }
    }

    return (justUnlockedNext: justUnlockedNext, justFullyCompleted: justFullyCompleted);
  }

  static Future<void> _grantWorldCompletionReward() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('coins') ?? 15;
    final xp = prefs.getInt('xp') ?? 0;
    await prefs.setInt('coins', coins + tafzoretWorldCoinsReward);
    await prefs.setInt('xp', xp + tafzoretWorldXpReward);
    BattlePassService.addPoints(tafzoretWorldBattlePassPoints);
    PlayerSyncService.syncCurrentProgress();
  }

  // ---- דילוג בתשלום (ראו IapManager.unlockTafzoretWorldId) ----

  /// רושם איזה עולם המשתמש מבקש לפתוח, לפני שמתחילים את הרכישה.
  static Future<void> setPendingUnlock(int world) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pendingTafzoretUnlockWorld', world);
  }

  /// נקרא מ-IapManager אחרי רכישה מוצלחת - פותח את העולם המבוקש אם הוא
  /// מעבר למה שכבר פתוח (אותה לוגיקה בדיוק כמו פתיחת רמה בתשלום הרגילה).
  static Future<void> grantPendingUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    final world = prefs.getInt('pendingTafzoretUnlockWorld') ?? 0;
    if (world > 0) {
      final current = prefs.getInt(_unlockedWorldKey) ?? 1;
      if (world > current) {
        await prefs.setInt(_unlockedWorldKey, world);
      }
      await prefs.remove('pendingTafzoretUnlockWorld');
    } else {
      final credits = prefs.getInt('tafzoretUnlockCredits') ?? 0;
      await prefs.setInt('tafzoretUnlockCredits', credits + 1);
    }
  }
}
