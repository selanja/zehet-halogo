// missions_service.dart
//
// מערכת משימות יומיות/שבועיות + אתגר יומי מיוחד.
//
// - משימות יומיות/שבועיות: כל תקופה (יום/שבוע) נבחרות אקראית כמה משימות
//   ממאגר קבוע (חלקן על המשחק הרגיל - פתרון לוגואים/שימוש ברמז, חלקן על
//   דו-קרב - שיחקת/ניצחת), עם התקדמות שמתעדכנת בזמן אמת דרך recordEvent()
//   שנקרא מנקודות המפתח במשחק. כשמתחיל יום/שבוע חדש - מתאפס אוטומטית.
// - אתגר יומי: לוגו אחד מיוחד, נבחר אקראית אבל *דטרמיניסטית* לפי התאריך
//   (כך שכל שחקן שמנסה את "אתגר היום" מקבל את אותו לוגו), עם פרס גדול
//   חד-פעמי ליום.
//
// הכל נשמר מקומית ב-SharedPreferences (בלי צורך בשרת) - בדיוק כמו שאר
// הנתונים במשחק (coins/xp וכו').

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_data.dart';
import 'battle_pass_service.dart'; // 🆕 נקודות "באטל פאס" על תביעת פרסים
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי כל שינוי מטבעות/XP - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון פרסי משימות במכשיר אחר

enum MissionEvent { logoSolved, hintUsed, duelPlayed, duelWon }

class MissionDef {
  final String id;
  final MissionEvent event;
  final int target;
  final int reward;
  final String title;
  // 🆕 משימת "פרימיום" - מוצגת לכולם (ההתקדמות נצברת לכולם, גם למי
  // שאין לו פרימיום - כך שהפרס כבר מחכה ברגע שהוא רוכש), אבל אי אפשר
  // לתבוע אותה (claim) בלי באטל פאס פרימיום פעיל לעונה הנוכחית - ראו
  // BattlePassService.isPremiumUnlocked ו-MissionsService.claim.
  final bool premiumOnly;
  const MissionDef({
    required this.id,
    required this.event,
    required this.target,
    required this.reward,
    required this.title,
    this.premiumOnly = false,
  });
}

class MissionProgress {
  final MissionDef def;
  final int progress;
  final bool claimed;
  const MissionProgress({required this.def, required this.progress, required this.claimed});
  bool get isComplete => progress >= def.target;
}

class DailyChallenge {
  final List<int> levelIds;
  final bool completed;
  // 🆕 true מהרגע שהניסיון היומי היחיד התחיל (גם אם נכשל/לא הושלם) -
  // "פעם אחת ביום" כולל גם ניסיון כושל, לא רק הצלחה.
  final bool attempted;
  const DailyChallenge({required this.levelIds, required this.completed, required this.attempted});
}

class MissionsService {
  MissionsService._();

  // 🆕 מאגר המשימות היומיות - משלב משימות משחק רגיל ומשימות דו-קרב, כדי
  // שהמשימות ימשכו שחקנים לשני חלקי המשחק ולא רק לאחד מהם.
  // 🩹 תוקן: קודם, בפועל, סכומי המשימות היומיות (מוכפלות ב-7 ימים)
  // עלו בסה"כ על סכום המשימות השבועיות לאורך אותו שבוע - כלומר
  // "השבועיות" לא הרגישו יותר משמעותיות מהיומיות כמו שהן אמורות, למרות
  // שכל משימה שבועית בודדת נתנה יותר. עכשיו הפרס היומי הופחת טיפה
  // (המשימות היומיות עדיין "בונוס קטן" יומי) והפרס השבועי הועלה
  // משמעותית, כך שסכום שתי המשימות השבועיות שנבחרות לשבוע גבוה יותר
  // מסכום שלוש המשימות היומיות לאורך אותו השבוע.
  // 🩹 הפרסים חזרו לערכים שהיו לפני הסיבוב הקודם (ראו הערה למעלה ליד
  // _dailyCount) - הצמצום עכשיו הוא בכמות המשימות המוצגות, לא בגובה
  // הפרס של כל אחת.
  static const List<MissionDef> _dailyPool = [
    MissionDef(id: 'd_logos_6', event: MissionEvent.logoSolved, target: 6, reward: 3, title: 'פתור 6 לוגואים'),
    MissionDef(id: 'd_logos_12', event: MissionEvent.logoSolved, target: 12, reward: 4, title: 'פתור 12 לוגואים'),
    MissionDef(id: 'd_hint_1', event: MissionEvent.hintUsed, target: 1, reward: 2, title: 'השתמש ברמז אחד'),
    MissionDef(id: 'd_duel_play_2', event: MissionEvent.duelPlayed, target: 2, reward: 4, title: 'שחק 2 דו-קרבים'),
    MissionDef(id: 'd_duel_win_1', event: MissionEvent.duelWon, target: 1, reward: 4, title: 'נצח דו-קרב אחד'),
  ];

  static const List<MissionDef> _weeklyPool = [
    MissionDef(id: 'w_logos_40', event: MissionEvent.logoSolved, target: 40, reward: 20, title: 'פתור 40 לוגואים השבוע'),
    MissionDef(id: 'w_logos_80', event: MissionEvent.logoSolved, target: 80, reward: 35, title: 'פתור 80 לוגואים השבוע'),
    MissionDef(id: 'w_duel_play_8', event: MissionEvent.duelPlayed, target: 8, reward: 25, title: 'שחק 8 דו-קרבים השבוע'),
    MissionDef(id: 'w_duel_win_5', event: MissionEvent.duelWon, target: 5, reward: 28, title: 'נצח 5 דו-קרבים השבוע'),
  ];

  // 🆕 משימות "פרימיום" - לפי בקשה מפורשת: משימות נוספות שמוצגות לכולם
  // במסך המשימות, אבל חסומות (אי אפשר לתבוע) למי שאין לו באטל פאס
  // פרימיום. בניגוד למאגרים למעלה - אלה לא נבחרות אקראית, הן קבועות
  // ותמיד פעילות בנוסף למשימות הרגילות (יום/שבוע), כדי שיהיה תמיד
  // ברור מה בדיוק "המשימות הבלעדיות לפרימיום" של התקופה. ההתקדמות שלהן
  // נצברת לכולם (כולל מי שאין לו פרימיום) - כך שאם מישהו רוכש פרימיום
  // באמצע היום/שבוע, הפרס כבר מחכה לו מוכן לאיסוף.
  // 🩹 הועלו מ-1 ל-2 משימות פרימיום לכל תקופה (יומי/שבועי) לפי בקשה
  // מפורשת, ומוצגות עכשיו ראשונות ברשימה (ראו המיון ב-_getMissions).
  static const List<MissionDef> _dailyPremiumMissions = [
    MissionDef(id: 'd_premium_logos_20', event: MissionEvent.logoSolved, target: 20, reward: 10, title: 'פתור 20 לוגואים', premiumOnly: true),
    MissionDef(id: 'd_premium_duel_win_2', event: MissionEvent.duelWon, target: 2, reward: 12, title: 'נצח 2 דו-קרבים', premiumOnly: true),
  ];

  static const List<MissionDef> _weeklyPremiumMissions = [
    MissionDef(id: 'w_premium_duel_win_10', event: MissionEvent.duelWon, target: 10, reward: 45, title: 'נצח 10 דו-קרבים השבוע', premiumOnly: true),
    MissionDef(id: 'w_premium_logos_150', event: MissionEvent.logoSolved, target: 150, reward: 60, title: 'פתור 150 לוגואים השבוע', premiumOnly: true),
  ];

  // 🩹 תוקן לפי בקשה מפורשת: 2 משימות יומיות רגילות + 2 שבועיות רגילות
  // (בנוסף ל-2 יומיות פרימיום + 2 שבועיות פרימיום שמוצגות ראשונות
  // למעלה - ראו _dailyPremiumMissions/_weeklyPremiumMissions למטה).
  static const int _dailyCount = 2;
  static const int _weeklyCount = 2;

  // 🆕 אתגר היום - 6 לוגואים רנדומליים (אותם 6 לכולם, נבחרים לפי
  // התאריך) תוך 45 שניות בסך הכל. פרס חד-פעמי ליום: מטבעות + XP.
  static const int dailyChallengeLogoCount = 6;
  static const int dailyChallengeSeconds = 45;
  static const int dailyChallengeCoinReward = 15;
  // 🩹 הופחת לפי בקשה מפורשת (יחד עם העלאת פרסי המשימות היומיות למעלה) -
  // מ-50 ל-30. זה גם ה-XP וגם כמות נקודות-הבאטל-פאס שהאתגר היומי נותן
  // (ראו MissionsService.completeDailyChallenge).
  static const int dailyChallengeXpReward = 30;

  static String _todayId(DateTime now) => '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // מזהה שבוע פשוט (לא בהכרח שבוע ISO רשמי, אבל עקבי לאורך השנה ומספיק
  // בשביל "איפוס פעם בשבוע").
  static String _weekId(DateTime now) {
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    final week = (dayOfYear / 7).floor();
    return '${now.year}-w$week';
  }

  static List<MissionDef> _pickMissions(List<MissionDef> pool, int count, String seedKey) {
    final rnd = Random(seedKey.hashCode);
    final shuffled = List<MissionDef>.from(pool)..shuffle(rnd);
    return shuffled.take(count).toList();
  }

  static MissionDef? _findDef(String id, {required bool weekly}) {
    final pool = weekly ? _weeklyPool : _dailyPool;
    for (final m in pool) {
      if (m.id == id) return m;
    }
    // 🆕 גם משימות הפרימיום הקבועות (ראו הערה למעלה) - לא חלק ממאגר
    // הבחירה האקראית, אבל צריכות להיפתר גם הן לפי המזהה שלהן.
    final premiumDefs = weekly ? _weeklyPremiumMissions : _dailyPremiumMissions;
    for (final p in premiumDefs) {
      if (p.id == id) return p;
    }
    return null;
  }

  // 🆕 טוען את מצב התקופה הנוכחית (יום/שבוע) מה-SharedPreferences; אם
  // התקופה השתנתה מאז הפעם האחרונה (יום/שבוע חדש) - בוחר סט משימות חדש
  // ומאפס התקדמות אוטומטית.
  static Future<Map<String, dynamic>> _loadPeriod(SharedPreferences prefs, {required bool weekly}) async {
    final now = DateTime.now();
    final periodId = weekly ? _weekId(now) : _todayId(now);
    final storeKey = weekly ? 'missions_weekly' : 'missions_daily';
    final raw = prefs.getString(storeKey);

    Map<String, dynamic>? data;
    if (raw != null) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        data = null;
      }
    }

    bool needsSave = false;

    // 🩹 אותה הגנה כמו באתגר היומי - אם 'missions' לא תקין (נתונים ישנים
    // מגרסה קודמת) בונים סט משימות חדש במקום לקרוס בהמשך.
    if (data == null || data['periodId'] != periodId || data['missions'] is! Map) {
      final pool = weekly ? _weeklyPool : _dailyPool;
      final count = weekly ? _weeklyCount : _dailyCount;
      final chosen = _pickMissions(pool, count, '$periodId-${weekly ? 'w' : 'd'}');
      // 🆕 משימות הפרימיום הקבועות של התקופה מתווספות תמיד, בנוסף
      // למשימות הרגילות שנבחרו אקראית - ראו הערה מפורטת ליד
      // _dailyPremiumMissions/_weeklyPremiumMissions.
      final premiumDefs = weekly ? _weeklyPremiumMissions : _dailyPremiumMissions;
      data = {
        'periodId': periodId,
        'missions': {
          for (final m in chosen) m.id: {'progress': 0, 'claimed': false},
          for (final p in premiumDefs) p.id: {'progress': 0, 'claimed': false},
        },
      };
      needsSave = true;
    } else {
      // 🩹 תוקן: שחקנים שכבר היה להם סט משימות שמור מלפני שהתווספו/עודכנו
      // משימות הפרימיום הקבועות - לא היו רואים אותן בכלל עד תחילת
      // התקופה הבאה (כי periodId לא השתנה אז הענף למעלה לא רץ מחדש).
      // כאן מוסיפים כל משימת-פרימיום שחסרה מהמסמך הקיים, בלי לגעת
      // בהתקדמות/משימות אחרות ששמורות כבר.
      final missions = data['missions'] as Map<String, dynamic>;
      final premiumDefs = weekly ? _weeklyPremiumMissions : _dailyPremiumMissions;
      for (final p in premiumDefs) {
        if (!missions.containsKey(p.id)) {
          missions[p.id] = {'progress': 0, 'claimed': false};
          needsSave = true;
        }
      }
    }
    if (needsSave) {
      await prefs.setString(storeKey, jsonEncode(data));
    }
    return data;
  }

  static Future<void> _savePeriod(SharedPreferences prefs, {required bool weekly, required Map<String, dynamic> data}) async {
    await prefs.setString(weekly ? 'missions_weekly' : 'missions_daily', jsonEncode(data));
  }

  static Future<List<MissionProgress>> getDailyMissions() => _getMissions(weekly: false);
  static Future<List<MissionProgress>> getWeeklyMissions() => _getMissions(weekly: true);

  static Future<List<MissionProgress>> _getMissions({required bool weekly}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _loadPeriod(prefs, weekly: weekly);
    final missions = data['missions'] as Map<String, dynamic>;
    final result = <MissionProgress>[];
    missions.forEach((id, v) {
      final def = _findDef(id, weekly: weekly);
      if (def == null) return;
      final m = v as Map<String, dynamic>;
      result.add(MissionProgress(def: def, progress: (m['progress'] ?? 0) as int, claimed: (m['claimed'] ?? false) as bool));
    });
    // 🩹 תוקן: משימות הפרימיום (אם יש) עכשיו מוצגות **ראשונות** ברשימה,
    // הכי למעלה - לפי בקשה מפורשת ("שיהיה הכי למעלה") - כדי שיהיה מיד
    // ברור שיש בונוס בלעדי לפרימיום, במקום להסתתר בסוף הרשימה.
    result.sort((a, b) {
      if (a.def.premiumOnly != b.def.premiumOnly) return a.def.premiumOnly ? -1 : 1;
      return a.def.target.compareTo(b.def.target);
    });
    return result;
  }

  // 🆕 נקודת הכניסה שנקראת מהמשחק/מהדו-קרב בזמן אמת (fire-and-forget) -
  // מתקדמת רק את המשימות (יומי+שבועי) שמתאימות לאירוע הזה, ולא נוגעת
  // במשימות שכבר הושלמו/נאספו.
  static Future<void> recordEvent(MissionEvent event, {int amount = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    for (final weekly in [false, true]) {
      final data = await _loadPeriod(prefs, weekly: weekly);
      final missions = data['missions'] as Map<String, dynamic>;
      bool changed = false;
      missions.forEach((id, v) {
        final def = _findDef(id, weekly: weekly);
        if (def == null || def.event != event) return;
        final m = v as Map<String, dynamic>;
        final claimed = (m['claimed'] ?? false) as bool;
        if (claimed) return;
        final current = (m['progress'] ?? 0) as int;
        if (current >= def.target) return;
        m['progress'] = (current + amount).clamp(0, def.target);
        changed = true;
      });
      if (changed) await _savePeriod(prefs, weekly: weekly, data: data);
    }
  }

  // מעניק את פרס המשימה (רק אם היא הושלמה ועוד לא נאספה) ומחזיר כמה
  // מטבעות ניתנו - null אם אי אפשר לאסוף (עוד לא הושלמה / כבר נאספה /
  // 🆕 או שזו משימת-פרימיום (premiumOnly) והשחקן עדיין לא רכש באטל פאס
  // פרימיום לעונה הנוכחית - ההתקדמות ממשיכה להישמר, רק התביעה חסומה).
  static Future<int?> claim(String missionId, {required bool weekly}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _loadPeriod(prefs, weekly: weekly);
    final missions = data['missions'] as Map<String, dynamic>;
    final m = missions[missionId] as Map<String, dynamic>?;
    if (m == null) return null;
    final def = _findDef(missionId, weekly: weekly);
    if (def == null) return null;
    if (def.premiumOnly && !await BattlePassService.isPremiumUnlocked()) return null;
    final claimed = (m['claimed'] ?? false) as bool;
    final progress = (m['progress'] ?? 0) as int;
    if (claimed || progress < def.target) return null;
    m['claimed'] = true;
    await _savePeriod(prefs, weekly: weekly, data: data);
    final coins = prefs.getInt('coins') ?? 15;
    await prefs.setInt('coins', coins + def.reward);
    PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה הקישור ל-Google/Apple לא מציג את המטבעות המעודכנים במכשיר אחר
    BattlePassService.addPoints(def.reward); // 🆕 נקודות "באטל פאס" על איסוף פרס משימה
    return def.reward;
  }

  // 🆕 מחליף משימה ספציפית (רק אם היא עדיין לא נאספה) במשימה אחרת
  // רנדומלית מאותו מאגר שלא כבר פעילה, ומאפס לה התקדמות מ-0. משמש
  // לכפתור "פרסומת = החלף משימה" במסך המשימות - הפרסומת עצמה כבר
  // נצפתה לפני שקוראים לזה; הפונקציה הזו רק מבצעת את ההחלפה בפועל.
  // מחזיר את המשימה החדשה, או null אם אי אפשר להחליף (המשימה כבר
  // נאספה, או שאין עוד משימה שונה זמינה במאגר).
  static Future<MissionDef?> rerollMission(String missionId, {required bool weekly}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _loadPeriod(prefs, weekly: weekly);
    final missions = data['missions'] as Map<String, dynamic>;
    final current = missions[missionId] as Map<String, dynamic>?;
    if (current == null) return null;
    final currentDef = _findDef(missionId, weekly: weekly);
    if (currentDef == null || currentDef.premiumOnly) return null; // 🆕 אי אפשר להחליף את משימת הפרימיום הקבועה - היא לא חלק מהמאגר האקראי
    final claimed = (current['claimed'] ?? false) as bool;
    if (claimed) return null; // אי אפשר להחליף משימה שכבר נאספה

    final pool = weekly ? _weeklyPool : _dailyPool;
    final activeIds = missions.keys.toSet();
    final candidates = pool.where((m) => m.id != missionId && !activeIds.contains(m.id)).toList();
    if (candidates.isEmpty) return null; // אין עוד משימה שונה במאגר להחליף אליה

    final newDef = candidates[Random().nextInt(candidates.length)];
    missions.remove(missionId);
    missions[newDef.id] = {'progress': 0, 'claimed': false};
    await _savePeriod(prefs, weekly: weekly, data: data);
    return newDef;
  }

  // כמה פרסי משימות ממתינים לאיסוף כרגע - לתג "חדש" בתפריט הראשי, כדי
  // שהשחקן ידע שיש לו משהו לאסוף בלי לפתוח את המסך. אתגר היום לא נכלל
  // כאן כי הפרס שלו ניתן מיידית עם הסיום, בלי שלב איסוף נפרד.
  // 🆕 משימת-פרימיום שהושלמה לא נספרת כאן אם אין פרימיום פעיל - היא
  // בפועל חסומה מתביעה, אז תג "יש לך משהו לאסוף" יטעה בלי הבדיקה הזו.
  static Future<int> unclaimedCount() async {
    final daily = await getDailyMissions();
    final weekly = await getWeeklyMissions();
    final premium = await BattlePassService.isPremiumUnlocked();
    return [...daily, ...weekly].where((m) => m.isComplete && !m.claimed && (!m.def.premiumOnly || premium)).length;
  }

  // 🆕 אתגר יומי - לוגו אחד "מיוחד", נבחר אקראית אבל דטרמיניסטית לפי
  // התאריך (Random עם seed מבוסס תאריך) כך שכולם מקבלים את אותו הלוגו
  // באותו היום, עם פרס גדול חד-פעמי.
  static Future<DailyChallenge> getDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final periodId = _todayId(DateTime.now());
    final raw = prefs.getString('daily_challenge');
    Map<String, dynamic>? data;
    if (raw != null) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        data = null;
      }
    }
    // 🩹 תיקון: מכשירים עם נתונים ישנים מגרסה קודמת (לפני שהיה קיים
    // 'levelIds' בפורמט הזה, תחת אותו מפתח SharedPreferences) עלולים
    // להגיע לכאן עם periodId תואם אך בלי שדה levelIds תקין - מה שגרם
    // לקריסה "type 'Null' is not a subtype of type 'List<dynamic>'".
    // לכן בודקים גם שה-levelIds קיים ומהסוג הנכון, ולא רק את ה-periodId.
    final bool needsRegenerate = data == null || data['periodId'] != periodId || data['levelIds'] is! List;
    if (needsRegenerate) {
      final ids = gameLevels.keys.toList()..sort();
      final rnd = Random(periodId.hashCode);
      final shuffled = List<int>.from(ids)..shuffle(rnd);
      final levelIds = shuffled.take(dailyChallengeLogoCount).toList();
      data = {'periodId': periodId, 'levelIds': levelIds, 'completed': false, 'attempted': false};
      await prefs.setString('daily_challenge', jsonEncode(data));
    }
    List<int> rawIds;
    try {
      rawIds = (data['levelIds'] as List).whereType<num>().map((e) => e.toInt()).toList();
    } catch (_) {
      rawIds = <int>[];
    }
    return DailyChallenge(levelIds: rawIds, completed: (data['completed'] ?? false) as bool, attempted: (data['attempted'] ?? false) as bool);
  }

  // 🆕 נקרא מ-DailyChallengeScreen ברגע שהניסיון היומי היחיד *מתחיל*
  // (לפני שהטיימר רץ) - כדי ש"פעם אחת ביום" יחול גם אם השחקן נכשל
  // (לא רק על הצלחה), וגם אם יצא מהמסך באמצע הריצה.
  static Future<void> markDailyChallengeAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    final periodId = _todayId(DateTime.now());
    final raw = prefs.getString('daily_challenge');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['periodId'] != periodId) return;
      data['attempted'] = true;
      await prefs.setString('daily_challenge', jsonEncode(data));
    } catch (_) {}
  }

  // 🆕 נקרא מ-DailyChallengeScreen ברגע שהשחקן פתר את כל 6 הלוגואים
  // בתוך הזמן - מזכה מטבעות + XP באופן חד-פעמי ומיידי (אין שלב "איסוף"
  // נפרד, כי זה כבר הישג חד-פעמי בזמן אמת). מחזיר false אם כבר הושלם
  // היום (הגנה מפני זיכוי כפול).
  static Future<bool> completeDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final periodId = _todayId(DateTime.now());
    final raw = prefs.getString('daily_challenge');
    Map<String, dynamic>? data;
    if (raw != null) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        data = null;
      }
    }
    if (data == null || data['periodId'] != periodId) return false; // לא אמור לקרות - נטען לפני המשחק
    if (data['completed'] == true) return false;
    data['completed'] = true;
    data['attempted'] = true;
    await prefs.setString('daily_challenge', jsonEncode(data));
    final coins = prefs.getInt('coins') ?? 15;
    await prefs.setInt('coins', coins + dailyChallengeCoinReward);
    final xp = prefs.getInt('xp') ?? 0;
    await prefs.setInt('xp', xp + dailyChallengeXpReward);
    PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה הקישור ל-Google/Apple לא מציג את פרס האתגר היומי במכשיר אחר
    BattlePassService.addPoints(dailyChallengeXpReward); // 🆕 נקודות "באטל פאס" על השלמת אתגר יומי
    return true;
  }
}