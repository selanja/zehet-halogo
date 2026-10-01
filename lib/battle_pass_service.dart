// battle_pass_service.dart
//
// 🆕 "באטל פאס" חודשי - צובר נקודות אך ורק מהשלמת משימות (יומיות/שבועיות
// במסך המשימות) והאתגר היומי - בכוונה לא ממשחק חופשי (פתרון שלב/ניצחון
// דו-קרב רגיל), כדי שההתקדמות תרגיש כמו "יעדים ברורים" ולא גרירה סתמית.
// כל כמה נקודות עולים "שלב" (Tier) שנותן פרס. יש שני נתיבים: "חינמי"
// (כולם מקבלים) ו"פרימיום" (רק מי שרכש את "באטל פאס פרימיום" לעונה
// הנוכחית - מוצר IAP, ראה iap_manager.dart) - הפרימיום נותן פרס גדול
// יותר על אותו שלב.
//
// ⚠️ הכל מקומי בלבד (SharedPreferences), בדיוק כמו רוב הכלכלה באפליקציה
// (coins/xp/missions) - אין תלות ברשת כדי לצבור/לתבוע נקודות. המפתחות
// כוללים את מזהה העונה (currentSeasonId) בתוכם, כך שבתחילת חודש חדש
// הכל מתחיל מ-0 אוטומטית בלי שום job/תחזוקה ידנית - פשוט נפתח "דף" חדש.
//
// 🔴 כדי שרכישת הפרימיום תעבוד בחנות בפועל, חובה ליצור מוצר IAP חדש
// בקונסולת החנות עם המזהה המדויק: battle_pass_premium (In-app product,
// לא מתכלה/consumable - נשאר "פעיל" עד סוף העונה) - ראה גם iap_manager.dart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart'; // 🆕 מזהה "אפקטיבי" (uid מקושר או deviceId) - לסנכרון הבאטל פאס בין מכשירים
import 'energy_service.dart';
import 'league_service.dart'; // 🆕 ליגה שבועית - אותן נקודות XP נספרות גם לשבוע הנוכחי
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי תביעת פרס באטל פאס - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון במכשיר אחר

class BattlePassTier {
  final int tier; // 1-based
  final int pointsRequired; // נקודות מצטברות נדרשות כדי לפתוח את השלב הזה
  final int freeCoins;
  final int freeEnergy;
  final int premiumCoins;
  final int premiumEnergy;
  const BattlePassTier({
    required this.tier,
    required this.pointsRequired,
    this.freeCoins = 0,
    this.freeEnergy = 0,
    this.premiumCoins = 0,
    this.premiumEnergy = 0,
  });

  bool get hasFreeReward => freeCoins > 0 || freeEnergy > 0;
  bool get hasPremiumReward => premiumCoins > 0 || premiumEnergy > 0;
}

class BattlePassService {
  // 🩹 הבאטל פאס גדל משמעותית לפי בקשת המשתמש: 15 שלבים -> 24 שלבים,
  // עם עקומת דרישות תלולה יותר (כל שלב דורש יותר נקודות מהקודם, ההפרש
  // עצמו גדל בהדרגה) שמתאימה לעונה הארוכה יותר (45 יום, ראו
  // seasonLengthDays למטה). מטבעות הפרימיום ביחס לנתיב החינמי נשארו
  // מוגדלים (בערך פי 2.5-3, לפי הבקשה המפורשת הקודמת), אבל 🩹 כל
  // הכמויות (חינם+פרימיום) הופחתו בכ-20-25% בסיבוב הזה - לפי בקשה
  // נוספת: "אם הוספנו עוד שלבים אז תוריד טיפה את הכמות של המטבעות",
  // כי 24 שלבים בכמויות של 15-השלבים הישנות היו נותנים סה"כ יותר מדי
  // מטבעות לאורך העונה. השלב האחרון (24) נשאר "פרס עונה" גדול במיוחד.
  static const List<BattlePassTier> tiers = [
    BattlePassTier(tier: 1, pointsRequired: 0, freeCoins: 10, premiumCoins: 25),
    BattlePassTier(tier: 2, pointsRequired: 70, freeCoins: 15, premiumCoins: 35),
    BattlePassTier(tier: 3, pointsRequired: 150, freeCoins: 10, premiumCoins: 30, premiumEnergy: 1),
    BattlePassTier(tier: 4, pointsRequired: 240, freeCoins: 15, premiumCoins: 45),
    BattlePassTier(tier: 5, pointsRequired: 340, freeEnergy: 1, premiumCoins: 35, premiumEnergy: 2),
    BattlePassTier(tier: 6, pointsRequired: 450, freeCoins: 20, premiumCoins: 50),
    BattlePassTier(tier: 7, pointsRequired: 570, freeCoins: 15, premiumCoins: 45, premiumEnergy: 1),
    BattlePassTier(tier: 8, pointsRequired: 700, freeCoins: 25, premiumCoins: 65),
    BattlePassTier(tier: 9, pointsRequired: 840, freeEnergy: 1, premiumCoins: 50, premiumEnergy: 2),
    BattlePassTier(tier: 10, pointsRequired: 990, freeCoins: 30, premiumCoins: 80),
    BattlePassTier(tier: 11, pointsRequired: 1150, freeCoins: 25, premiumCoins: 65, premiumEnergy: 1),
    BattlePassTier(tier: 12, pointsRequired: 1320, freeCoins: 40, premiumCoins: 100),
    BattlePassTier(tier: 13, pointsRequired: 1500, freeEnergy: 2, premiumCoins: 70, premiumEnergy: 2),
    BattlePassTier(tier: 14, pointsRequired: 1690, freeCoins: 45, premiumCoins: 115),
    BattlePassTier(tier: 15, pointsRequired: 1890, freeCoins: 30, premiumCoins: 80, premiumEnergy: 1),
    BattlePassTier(tier: 16, pointsRequired: 2100, freeCoins: 55, premiumCoins: 130),
    BattlePassTier(tier: 17, pointsRequired: 2320, freeEnergy: 2, premiumCoins: 85, premiumEnergy: 3),
    BattlePassTier(tier: 18, pointsRequired: 2550, freeCoins: 60, premiumCoins: 150),
    BattlePassTier(tier: 19, pointsRequired: 2790, freeCoins: 40, premiumCoins: 100, premiumEnergy: 1),
    BattlePassTier(tier: 20, pointsRequired: 3040, freeCoins: 70, premiumCoins: 175),
    BattlePassTier(tier: 21, pointsRequired: 3300, freeEnergy: 3, premiumCoins: 115, premiumEnergy: 3),
    BattlePassTier(tier: 22, pointsRequired: 3570, freeCoins: 75, premiumCoins: 195),
    BattlePassTier(tier: 23, pointsRequired: 3850, freeCoins: 55, premiumCoins: 135, premiumEnergy: 2),
    BattlePassTier(tier: 24, pointsRequired: 4140, freeCoins: 120, freeEnergy: 3, premiumCoins: 280, premiumEnergy: 8),
    // 🆕 עוד 6 שלבים (25-30) - העונה עכשיו ארוכה יותר, וגם ניצחון בדו-קרב
    // שווה הרבה פחות נקודות מכפי שהיה (ראו duel_room_screen.dart -
    // _winBattlePassPoints, ירד מ-50 ל-10) - כך שלסיים את כל הבאטל פאס
    // דורש שילוב של הרבה משחק לאורך זמן, לא רק כמה דו-קרבים מהירים ביום.
    // ממשיכים בדיוק את אותה עקומה (ההפרש בין שלבים ממשיך לגדול ב-10
    // בכל שלב), ושלב 30 הוא עכשיו "פרס העונה" הגדול (במקום שלב 24).
    BattlePassTier(tier: 25, pointsRequired: 4440, freeCoins: 80, premiumCoins: 210),
    BattlePassTier(tier: 26, pointsRequired: 4750, freeEnergy: 3, premiumCoins: 150, premiumEnergy: 3),
    BattlePassTier(tier: 27, pointsRequired: 5070, freeCoins: 90, premiumCoins: 230),
    BattlePassTier(tier: 28, pointsRequired: 5400, freeEnergy: 4, premiumCoins: 165, premiumEnergy: 4),
    BattlePassTier(tier: 29, pointsRequired: 5740, freeCoins: 100, premiumCoins: 250),
    BattlePassTier(tier: 30, pointsRequired: 6090, freeCoins: 150, freeEnergy: 5, premiumCoins: 350, premiumEnergy: 10),
  ];

  // 🆕 אורך העונה עכשיו קבוע ל-45 יום (במקום "מתחילת החודש הקלנדרי ועד
  // סופו" הישן) - לפי בקשה מפורשת "שיהיה יותר ימים לעשות אותו". השיטה
  // הישנה הייתה בעייתית גם מעבר לזה שהיא קצרה מדי: מי שהתחיל לשחק
  // ב-28 לחודש קיבל בפועל רק 2-3 ימים להשלים באטל פאס שלם, בעוד מי
  // שהתחיל ב-1 לחודש קיבל חודש מלא - לא הוגן ולא עקבי בין שחקנים.
  // _seasonEpoch הוא עוגן קבוע וזהה לכל השחקנים (לא תלוי מתי כל שחקן
  // התקין את המשחק) - כך שכל השחקנים עוברים לעונה חדשה באותו רגע
  // בדיוק, וגם "הבאטל פאס מתחלף והכוכבים מתאפסים" קורה אוטומטית בכל
  // מעבר עונה, כי כל מפתחות ה-SharedPreferences (נקודות/תביעות/פרימיום)
  // כוללים את מזהה העונה (currentSeasonId) בתוכם - עונה חדשה = "דף new"
  // ריק לגמרי, בלי שום job/תחזוקה ידנית.
  static const int seasonLengthDays = 45;
  // 🆕 אופס לקראת העלאת המשחק לחנויות ("בוא נאפס את הבאטל פאס") - העוגן
  // הישן (1.1.2025) היה מתאריך הפיתוח, כך שבפועל היינו כבר "באמצע" עונה
  // כלשהי ביום ההשקה בלי שום סיבה טובה. העוגן החדש הוא תאריך ההשקה בפועל
  // (19.9.2026, "עוד יומיים" מהיום שזה נכתב - 17.9.2026) - כל שחקן שיתקין
  // את האפליקציה מרגע ההשקה יתחיל בדיוק ב"עונה 1, יום 1", עם 45 ימים
  // מלאים קדימה. ⚠️ אם תאריך ההשקה בפועל ישתנה שוב - תעדכן את התאריך כאן
  // לתאריך האמיתי לפני שמעלים בפועל.
  static final DateTime _seasonEpoch = DateTime(2026, 9, 19);

  static int _seasonIndex([DateTime? now]) {
    final n = now ?? DateTime.now();
    final daysSinceEpoch = n.difference(_seasonEpoch).inDays;
    return daysSinceEpoch < 0 ? 0 : daysSinceEpoch ~/ seasonLengthDays;
  }

  /// תאריך תחילת העונה הנוכחית (לחישוב "כמה ימים נותרו").
  static DateTime seasonStartDate([DateTime? now]) => _seasonEpoch.add(Duration(days: _seasonIndex(now) * seasonLengthDays));

  /// כמה ימים נותרו עד שהעונה הנוכחית מסתיימת ועונה חדשה מתחילה (ואז
  // הנקודות/התביעות מתאפסות אוטומטית - ראו ההסבר למעלה).
  static int daysLeftInSeason([DateTime? now]) {
    final n = now ?? DateTime.now();
    final end = seasonStartDate(n).add(const Duration(days: seasonLengthDays));
    return end.difference(n).inDays;
  }

  /// מספר העונה הרץ (1, 2, 3...) - לתווית "עונה N" במסך.
  static int currentSeasonNumber([DateTime? now]) => _seasonIndex(now) + 1;

  static String currentSeasonId([DateTime? now]) => 'S${_seasonIndex(now)}';

  // שם-טעם לעונה - חודש+שנה של תחילתה (למשל "ספטמבר 2026") - נשאר רק
  // ככותרת "יפה" מתחת לתווית "עונה N", לא כמזהה בפועל (זה currentSeasonId).
  static String seasonDisplayName([DateTime? now]) {
    const hebrewMonths = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];
    final start = seasonStartDate(now);
    return '${hebrewMonths[start.month - 1]} ${start.year}';
  }

  static String get _pointsKey => 'battlePassPoints_${currentSeasonId()}';
  static String get _premiumKey => 'battlePassPremium_${currentSeasonId()}';
  static String get _claimedFreeKey => 'battlePassClaimedFree_${currentSeasonId()}';
  static String get _claimedPremiumKey => 'battlePassClaimedPremium_${currentSeasonId()}';

  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  /// מוסיף נקודות לעונה הנוכחית - נקרא מכל מקום שמעניק "הישג" במשחק
  /// (פתרון שלב, ניצחון דו-קרב, משימה, אתגר יומי). לא חוסם/מחזיר כלום -
  /// כשל שקט אם משום מה SharedPreferences לא זמין, לא קריטי מספיק כדי
  /// להפריע לזרימת המשחק הרגילה.
  static Future<void> addPoints(int amount) async {
    if (amount <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_pointsKey) ?? 0;
      await prefs.setInt(_pointsKey, current + amount);
      syncToCloud(); // 🆕 fire-and-forget - ראו ההסבר המלא ליד syncToCloud למטה
      LeagueService.addPoints(amount); // 🆕 ליגה שבועית
    } catch (_) {}
  }

  static Future<bool> isPremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// נקרא מ-IapManager אחרי רכישה מאושרת של battle_pass_premium.
  static Future<void> markPremiumPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    syncToCloud();
  }

  static Future<Set<int>> getClaimedFreeTiers() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_claimedFreeKey) ?? const []).map(int.parse).toSet();
  }

  static Future<Set<int>> getClaimedPremiumTiers() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_claimedPremiumKey) ?? const []).map(int.parse).toSet();
  }

  /// השלב הגבוה ביותר שכבר "נפתח" (יש מספיק נקודות אליו) - 0 אם עוד
  /// לא הגיעו אפילו לשלב 1 (לא אמור לקרות בפועל כי שלב 1 דורש 0 נקודות).
  static int currentTierFor(int points) {
    int tier = 0;
    for (final t in tiers) {
      if (points >= t.pointsRequired) tier = t.tier;
    }
    return tier;
  }

  /// תובע פרס משלב מסוים (נתיב חינמי או פרימיום). מחזיר {coins, energy}
  /// שהוענקו בפועל, או null אם אי אפשר (השלב עדיין נעול, כבר נתבע,
  /// או שזה נתיב פרימיום בלי רכישה פעילה לעונה הזו).
  static Future<Map<String, int>?> claimTier(int tier, {required bool premium}) async {
    BattlePassTier? def;
    for (final t in tiers) {
      if (t.tier == tier) def = t;
    }
    if (def == null) return null;

    final points = await getPoints();
    if (points < def.pointsRequired) return null; // עדיין נעול

    final prefs = await SharedPreferences.getInstance();
    final coins = premium ? def.premiumCoins : def.freeCoins;
    final energy = premium ? def.premiumEnergy : def.freeEnergy;
    if (coins <= 0 && energy <= 0) return null; // אין פרס בנתיב הזה בשלב הזה

    if (premium) {
      if (!await isPremiumUnlocked()) return null;
      final claimed = await getClaimedPremiumTiers();
      if (claimed.contains(tier)) return null;
      claimed.add(tier);
      await prefs.setStringList(_claimedPremiumKey, claimed.map((e) => e.toString()).toList());
    } else {
      final claimed = await getClaimedFreeTiers();
      if (claimed.contains(tier)) return null;
      claimed.add(tier);
      await prefs.setStringList(_claimedFreeKey, claimed.map((e) => e.toString()).toList());
    }

    if (coins > 0) {
      final c = prefs.getInt('coins') ?? 15;
      await prefs.setInt('coins', c + coins);
      PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה פרס הבאטל פאס לא מסתנכרן לחשבון Google/Apple מקושר
    }
    if (energy > 0) {
      await EnergyService.addAmount(energy);
    }
    syncToCloud();
    return {'coins': coins, 'energy': energy};
  }

  /// כמה פרסים ממתינים לאיסוף כרגע (לתג-מספר על כרטיס הבאטל פאס
  /// בתפריט הראשי) - סופר גם נתיב פרימיום רק אם הוא פעיל לעונה הזו.
  static Future<int> pendingClaimsCount() async {
    final points = await getPoints();
    final unlockedTier = currentTierFor(points);
    final claimedFree = await getClaimedFreeTiers();
    final claimedPremium = await getClaimedPremiumTiers();
    final premiumUnlocked = await isPremiumUnlocked();
    int count = 0;
    for (final t in tiers) {
      if (t.tier > unlockedTier) break;
      if (t.hasFreeReward && !claimedFree.contains(t.tier)) count++;
      if (premiumUnlocked && t.hasPremiumReward && !claimedPremium.contains(t.tier)) count++;
    }
    return count;
  }

  // ========================================================================
  // 🆕 סנכרון בין מכשירים - עד עכשיו הכול היה מקומי בלבד (SharedPreferences),
  // בניגוד למטבעות/XP/אנרגיה שכבר מסתנכרנים לענן. המשמעות: מי שקנה
  // פרימיום וקישר חשבון Google/Apple, ואז החליף מכשיר או התקין מחדש -
  // היה מאבד את סטטוס הפרימיום וההתקדמות של העונה הנוכחית לגמרי, למרות
  // ששילם כסף אמיתי. נשמר תחת players/{effectiveId}.battlePass - אותו
  // מסמך בדיוק שבו כבר נשמרים מטבעות/XP (ראה player_sync.dart), לא אוסף
  // נפרד. כולל את מזהה העונה כדי שנתונים מעונה ישנה לעולם לא "יזלגו"
  // לעונה חדשה בטעות.
  // ========================================================================
  static CollectionReference<Map<String, dynamic>> get _players => FirebaseFirestore.instance.collection('players');

  /// שולח את מצב הבאטל פאס של העונה הנוכחית לענן. fire-and-forget בכוונה
  /// (לא מחכים לו בקוד הקורא) - לא חוסם את זרימת המשחק, וכשל שקט אם אין
  /// אינטרנט כרגע (יסתנכרן בפעם הבאה שנקרא לזה, בכל שינוי משמעותי הבא).
  static Future<void> syncToCloud() async {
    try {
      final effectiveId = await AccountService.effectiveId();
      final points = await getPoints();
      final premium = await isPremiumUnlocked();
      final claimedFree = await getClaimedFreeTiers();
      final claimedPremium = await getClaimedPremiumTiers();
      await _players.doc(effectiveId).set({
        'battlePass': {
          'season': currentSeasonId(),
          'points': points,
          'premium': premium,
          'claimedFree': claimedFree.toList(),
          'claimedPremium': claimedPremium.toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// טוען מהענן אם יש שם נתונים *לעונה הנוכחית* (נתונים מעונה אחרת -
  /// למשל אם המכשיר "נעלם" לזמן רב - פשוט מתעלמים מהם, בדיוק כמו
  /// שהעונה הישנה ממילא הייתה מתאפסת גם במכשיר שבו נשמרו). ראה שני
  /// מקומות הקריאה ב-account_service.dart (קישור חשבון/פתרון התנגשות):
  /// `force=false` (ברירת מחדל) - לא דורס התקדמות מקומית קיימת לעונה
  /// הזו אם כבר יש כזו (למשל שיחקו קצת כאורח לפני הקישור). `force=true` -
  /// המשתמש בחר במפורש "התחבר עם ההתקדמות השמורה" בדיאלוג התנגשות
  /// (ראה account_conflict_dialog.dart), כך שכן דורסים כל מה שהיה מקומי.
  static Future<void> pullFromCloudIfNeeded({bool force = false}) async {
    try {
      final effectiveId = await AccountService.effectiveId();
      final doc = await _players.doc(effectiveId).get().timeout(const Duration(seconds: 15));
      final bp = doc.data()?['battlePass'] as Map<String, dynamic>?;
      if (bp == null || bp['season'] != currentSeasonId()) return;

      final prefs = await SharedPreferences.getInstance();
      if (!force && (prefs.containsKey(_pointsKey) || prefs.containsKey(_premiumKey))) return;

      await prefs.setInt(_pointsKey, (bp['points'] as num?)?.toInt() ?? 0);
      await prefs.setBool(_premiumKey, bp['premium'] == true);
      final claimedFree = (bp['claimedFree'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
      final claimedPremium = (bp['claimedPremium'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
      await prefs.setStringList(_claimedFreeKey, claimedFree);
      await prefs.setStringList(_claimedPremiumKey, claimedPremium);
    } catch (_) {}
  }
}