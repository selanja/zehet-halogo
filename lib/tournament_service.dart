// tournament_service.dart
//
// 🆕 עוצב מחדש לפי בקשה מפורשת: "אני רוצה שתשים סכום בקופה בהתחלה
// ואני רוצה שתעשה שהם ייקחו כמה ימים, ככה שיהיה יותר עניין שכל יום
// הם יצטרכו להיכנס" - הטורניר ה"יומי" הישן (הרשמה+משחק+איפוס, הכול
// באותו יום) הפך ל"אתגר רב-יומי": אירוע אחד נמשך tournamentEventDays
// ימים (3), נרשמים פעם אחת לכל האירוע, וכל יום באירוע פותח מנה חדשה
// וקטנה של לוגואים (tournamentDailyLogoCount) - הניקוד מצטבר על פני
// כל הימים, והדירוג הסופי (ופיזור הפרסים) נקבע רק בסוף היום האחרון.
// ככה יש סיבה אמיתית לחזור כל יום (לא לאבד נקודות על אותו יום), בלי
// להעניש מי שמפספס יום - הוא פשוט לא מרוויח את הנקודות של אותו יום.
//
// 💰 הקופה כוללת עכשיו גם "זריקת פתיחה" קבועה מה"בית" (tournamentPotSeed)
// בנוסף לדמי הכניסה שנאספו (entrantsSoFar × tournamentEntryFee) - כדי
// שהפרסים יהיו משמעותיים גם באירועים עם מעט משתתפים, לא רק "ויטרינה
// ריקה" בהתחלה. הפרסים עדיין אחוז מהקופה הכוללת (כולל הזריקה), לא סכום
// קבוע - ראו ההסבר ההיסטורי למטה שעדיין נכון: פרס קבוע עלול לעלות על מה
// שנאסף בפועל, פרס יחסי-לקופה מבטיח שלעולם לא משולם יותר ממה שיש.
//
// ⚠️ בכוונה לא מימוש "טורניר בזמן אמת" עם bracket בין שחקנים (כמו הדו-קרב) -
// זה היה דורש תשתית matchmaking חדשה לגמרי ל-N שחקנים. במקום זה, זה
// בעיקרון "אתגר רב-יומי בתשלום עם טבלת דירוג משותפת ופרס", שמשתמש בדיוק
// באותם בלוקי-בניין קיימים (דפוס האפוקה/איפוס-לפי-תאריך, התשלום-רק-כש-
// באמת-מתחילים מהדו-קרב, PlayerSyncService.syncCurrentProgress, דפוס
// ה-leagueKey של LeagueService למניעת אינדקס מורכב ב-Firestore).
//
// ⚠️ כמו הדו-קרב (ראו ההערה המתועדת שם), קביעת התוצאה והענקת הפרס קורות
// בצד הלקוח - מספיק לגרסת ה-MVP הזו (סכומים נמוכים, לא כסף אמיתי), אבל
// אם זה יהפוך למשמעותי כדאי Cloud Function לאימות. כל חישובי ה"אירוע/
// יום" הם דטרמיניסטיים לפי תאריך-לוח מקומי (ללא שרת/cron) - אותו עיקרון
// בדיוק כמו שהיה קודם עם todayId(), רק עם חלון של 3 ימים במקום 1.
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_data.dart';
import 'device_id.dart';
import 'player_sync.dart';
import 'battle_pass_service.dart';
import 'achievements_service.dart';
import 'missions_service.dart';
import 'notification_service.dart';
import 'notification_manager.dart';
import 'iap_manager.dart'; // 🆕 ניצחון (מקום 1) מפעיל מבצע 20% מטבעות בחנות - ראו IapManager.activateTournamentBonus

const int tournamentEntryFee = 50;
// 🆕 תוקן לפי בקשה מפורשת ("תהפוך אותו ליותר לוגואים שיהיה עניין", ואז
// "עוד קצת") - 10 ליום (היה 5, לפני כן 3) × 3 ימים = 30 לוגואים על פני
// האירוע כולו (היה 15, לפני כן 9).
const int tournamentEventDays = 3;
const int tournamentDailyLogoCount = 10;
const int tournamentXpReward = 60;
const int tournamentBattlePassPoints = 30;

// 🆕 "שיהיה גם לפי זמן ככה שמי שעושה בזמן הכי מהר הניקוד שלו יותר
// גבוה" - כל לוגו נכון שווה tournamentPointsPerCorrect נקודות, ומזמן
// הפתרון הכולל של אותו יום (לא לכל לוגו בנפרד - ראו TournamentEntry.score)
// יורד ניקוד לפי שנייה. ה"ניקוד" האמיתי שמוצג ומדורג לפי הוא השילוב של
// שניהם, לא רק מספר הנכונות עם זמן כ"שובר שוויון" סמוי כמו קודם - פער
// של נקודה אחת (1000) גדול בהרבה מההפרש הריאלי בזמן בין שחקנים, כך
// שרוב הזמן יותר נכונות עדיין מנצח, אבל כל שנייה מהירה יותר תמיד
// מעלה את הניקוד בפועל, לא רק "שוברת שוויון" בשקט.
const int tournamentPointsPerCorrect = 1000;

// 🆕 "זריקת פתיחה" קבועה שה"בית" מוסיף לקופה בתחילת כל אירוע, לפני
// שאף אחד שילם דמי כניסה - לפי בקשה מפורשת ("שתשים סכום בקופה בהתחלה",
// ואז "עוד קצת מטבעות בהתחלה").
const int tournamentPotSeed = 200;

// נתח מהקופה (כולל הזריקה + דמי הכניסה שנאספו) שכל מקום מקבל. הסכום
// הנשאר (30%) הוא "מרווח הבית" - לא משולם לאף אחד, פשוט נשאר מחוץ
// למחזור, בדיוק מה שנותן למשחק רווח קבוע ולא רק "לפעמים".
const double tournamentFirstShare = 0.40;
const double tournamentSecondShare = 0.20;
const double tournamentThirdShare = 0.10;

// 🆕 אם פחות מזה הצטרפו לאירוע מסוים, זה לא ממש "תחרות" (כמעט כל מי
// שמשתתף היה זוכה במקום כלשהו) - במקום לחלק פרס פעוט, כל מי שהצטרף
// מקבל את דמי הכניסה שלו בחזרה במלואם (ראו checkAndClaimPendingPrize).
const int tournamentMinPlayers = 5;

/// אומדן גודל הקופה הנוכחי - לתצוגה בלובי ("הקופה כרגע: X"), לא ערובה
/// סופית (עוד אנשים עשויים להצטרף עד סוף האירוע). כולל את זריקת הפתיחה.
int currentPoolEstimate(int entrantsSoFar) => tournamentPotSeed + entrantsSoFar * tournamentEntryFee;

class TournamentEntry {
  final String deviceId;
  final String name;
  final int correctCount;
  final int totalTimeMs;
  const TournamentEntry({required this.deviceId, required this.name, required this.correctCount, required this.totalTimeMs});

  // 🆕 ניקוד אמיתי (לא רק "נכונות + זמן כשובר שוויון") - ראו ההסבר ליד
  // tournamentPointsPerCorrect. מצטבר אוטומטית על פני כל ימי האירוע כי
  // correctCount/totalTimeMs עצמם כבר מצטברים (ראו submitDayResult).
  int get score => correctCount * tournamentPointsPerCorrect - (totalTimeMs ~/ 1000);

  // דירוג: לפי הניקוד המשולב (נכונות גדולה פי 1000 ממשקל השניות - ראו score).
  int compareTo(TournamentEntry other) => other.score - score;
}

enum TournamentOutcome { prize, refund }

class TournamentPrizeResult {
  final TournamentOutcome outcome;
  final int rank; // רלוונטי רק כש-outcome == prize
  final int coins;
  const TournamentPrizeResult({required this.outcome, this.rank = 0, required this.coins});
}

class TournamentService {
  TournamentService._();

  static final _db = FirebaseFirestore.instance;
  static const _collection = 'tournamentEntries';

  // 🆕 נקודת עוגן קבועה (לא תלויה בתאריך ההתקנה) - כדי שכל המכשירים
  // יחשבו בדיוק את אותם גבולות אירוע (אותו "יום 1/2/3" לכל שחקן ביחס
  // לאותו תאריך לוח אמיתי), בדיוק כמו שהיה קודם עם todayId() (שגם הוא
  // הניח שכל השחקנים פחות או יותר על אותו תאריך לוח - אותה הנחה, רק
  // עכשיו עם חלון 3 ימים).
  static final DateTime _epoch = DateTime(2024, 1, 1);

  static int _daysSinceEpoch(DateTime d) => DateTime(d.year, d.month, d.day).difference(_epoch).inDays;

  /// אינדקס האירוע הנוכחי (0,1,2,...) - מתקדם אוטומטית כל tournamentEventDays ימים.
  static int currentEventIndex([DateTime? now]) => _daysSinceEpoch(now ?? DateTime.now()) ~/ tournamentEventDays;

  static String eventId([int? index]) => 'evt${index ?? currentEventIndex()}';

  /// יום 1..tournamentEventDays בתוך האירוע הנוכחי.
  static int dayInEvent([DateTime? now]) => (_daysSinceEpoch(now ?? DateTime.now()) % tournamentEventDays) + 1;

  /// רגע סיום האירוע הנוכחי (חצות מקומית, תחילת האירוע הבא) - לתצוגת
  /// "נותרו X" בלובי/בבאנר הבית.
  static DateTime eventEndTime([DateTime? now]) {
    final nextEventStartDay = (currentEventIndex(now) + 1) * tournamentEventDays;
    return _epoch.add(Duration(days: nextEventStartDay));
  }

  /// הלוגואים הקבועים של יום מסוים בתוך אירוע מסוים - אותם לוגואים
  /// בדיוק לכל שחקן, נבחרים דטרמיניסטית לפי (eventId, day) (אותו רעיון
  /// כמו MissionsService.getDailyChallenge).
  static List<int> levelIdsForEventDay(String eventId, int day) {
    final ids = gameLevels.keys.toList()..sort();
    final rnd = Random('$eventId-day$day'.hashCode);
    final shuffled = List<int>.from(ids)..shuffle(rnd);
    return shuffled.take(tournamentDailyLogoCount).toList();
  }

  static Future<bool> hasJoinedEvent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tournamentJoinedEvent') == eventId();
  }

  /// האם כבר שיחקו את המנה של *היום* (יום X הספציפי בתוך האירוע הנוכחי) -
  /// לא "כל האירוע", רק היום הנוכחי. יום חדש באירוע = אפשר לשחק שוב.
  static Future<bool> hasPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('tournamentLastDayPlayed_${eventId()}') == dayInEvent();
  }

  /// נרשם לכל האירוע (לא רק ליום בודד): בודק/מנכה דמי כניסה פעם אחת
  /// ומסמן "הצטרף". בהצלחה חוזר null, ובכישלון (אין מספיק מטבעות) חוזר
  /// מספר המטבעות החסרים.
  static Future<int?> join() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('coins') ?? 15;
    if (coins < tournamentEntryFee) return tournamentEntryFee - coins;
    await prefs.setInt('coins', coins - tournamentEntryFee);
    await prefs.setString('tournamentJoinedEvent', eventId());
    final username = prefs.getString('username') ?? 'שחקן';
    final deviceId = await DeviceId.get();
    // 🆕 יוצרים מיד מסמך 0/0 בהרשמה - כך שהשחקן נספר ב"משתתפים"
    // (ומשפיע על גודל הקופה המוצג) גם לפני ששיחק את היום הראשון בפועל.
    try {
      await _db.collection(_collection).doc('${eventId()}_$deviceId').set({
        'eventId': eventId(),
        'deviceId': deviceId,
        'name': username,
        'correctCount': 0,
        'totalTimeMs': 0,
        'lastDayPlayed': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // אופליין/שגיאת רשת - ההרשמה המקומית (דמי הכניסה כבר ירדו) בכל
      // מקרה תקפה; המסמך ב-Firestore ייווצר בפועל ב-submitDayResult
      // הראשון (שולח set מלא, לא תלוי שהמסמך הזה הצליח).
    }
    PlayerSyncService.syncCurrentProgress();
    return null;
  }

  /// נקרא בתום המנה היומית בתוך האירוע (אחרי הלוגו האחרון של אותו יום) -
  /// מצטבר על גבי התוצאה שכבר הייתה לאירוע הזה (לא מחליף אותה), שולח
  /// את הסכום המצטבר החדש לטבלת הדירוג המשותפת, ומעניק XP+נקודות-לוגו-
  /// פאס על ההשתתפות (ללא תלות במיקום - הפרס על מיקום ניתן בנפרד, רק
  /// בסוף האירוע - ראו checkAndClaimPendingPrize).
  static Future<void> submitDayResult({required int correctCount, required int totalTimeMs}) async {
    final prefs = await SharedPreferences.getInstance();
    final evId = eventId();
    final day = dayInEvent();
    final username = prefs.getString('username') ?? 'שחקן';
    final deviceId = await DeviceId.get();

    // מצטבר מקומית (סובל אופליין) - תמיד שולחים ל-Firestore את הסכום
    // המצטבר המקומי המלא (לא FieldValue.increment), כך שגם אם יום
    // קודם לא הצליח להישלח בזמן, היום הנוכחי "מתקן" את הסכום הכולל.
    final localKey = 'tournamentCumulative_$evId';
    final prevRaw = prefs.getString(localKey);
    int prevCorrect = 0, prevTimeMs = 0;
    if (prevRaw != null) {
      try {
        final prev = jsonDecode(prevRaw) as Map<String, dynamic>;
        prevCorrect = (prev['correctCount'] as num?)?.toInt() ?? 0;
        prevTimeMs = (prev['totalTimeMs'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    final newCorrect = prevCorrect + correctCount;
    final newTimeMs = prevTimeMs + totalTimeMs;
    await prefs.setString(localKey, jsonEncode({'correctCount': newCorrect, 'totalTimeMs': newTimeMs}));
    await prefs.setInt('tournamentLastDayPlayed_$evId', day);

    try {
      await _db.collection(_collection).doc('${evId}_$deviceId').set({
        'eventId': evId,
        'deviceId': deviceId,
        'name': username,
        'correctCount': newCorrect,
        'totalTimeMs': newTimeMs,
        'lastDayPlayed': day,
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // אופליין/שגיאת רשת - הסכום המצטבר המקומי כבר נשמר, ננסה שוב
      // לדווח בפעם הבאה שתישלח תוצאה (ראו ההערה למעלה).
    }

    final xp = prefs.getInt('xp') ?? 0;
    await prefs.setInt('xp', xp + tournamentXpReward);
    BattlePassService.addPoints(tournamentBattlePassPoints);
    MissionsService.recordEvent(MissionEvent.tournamentPlayed);
    PlayerSyncService.syncCurrentProgress();

    // 🆕 תזכורת לטלפון בדיוק כשהאירוע כולו מסתיים (לא כל יום בנפרד) -
    // רק אם זה היום האחרון של האירוע, ורק אם השחקן הפעיל התראות
    // ולא כיבה ספציפית את קטגוריית "עדכוני טורניר" בטאב ההתראות.
    if (day >= tournamentEventDays) {
      if (NotificationManager.notificationsEnabled && NotificationManager.tournamentNotificationsEnabled) {
        NotificationService.scheduleTournamentEndedReminder();
      }
    }
  }

  /// טבלת הדירוג המצטברת של אירוע מסוים, ממוינת בצד הלקוח (לא orderBy
  /// ב-Firestore, כדי לא להזדקק לאינדקס מורכב - אותו דפוס בדיוק כמו LeagueService).
  static Future<List<TournamentEntry>> fetchLeaderboard(String eventId) async {
    try {
      final snap = await _db.collection(_collection).where('eventId', isEqualTo: eventId).limit(500).get();
      final entries = snap.docs.map((d) {
        final data = d.data();
        return TournamentEntry(
          deviceId: (data['deviceId'] ?? '') as String,
          name: (data['name'] ?? 'שחקן') as String,
          correctCount: ((data['correctCount'] ?? 0) as num).toInt(),
          totalTimeMs: ((data['totalTimeMs'] ?? 0) as num).toInt(),
        );
      }).toList();
      entries.sort((a, b) => a.compareTo(b));
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// נקרא כשנפתח מסך הטורניר - אם האירוע שהצטרפו אליו האחרון כבר הסתיים
  /// (האירוע הנוכחי התקדם הלאה) ועדיין לא נתבע פרס/החזר ממנו, מעניק
  /// אותו ומחזיר את הפרטים כדי להציג חלונית "זכית!".
  static Future<TournamentPrizeResult?> checkAndClaimPendingPrize() async {
    final prefs = await SharedPreferences.getInstance();
    final joinedEvent = prefs.getString('tournamentJoinedEvent');
    if (joinedEvent == null) return null; // לא הצטרפו לשום אירוע
    if (joinedEvent == eventId()) return null; // האירוע שהצטרפו אליו עדיין פעיל - אין מה לתבוע עדיין
    if (prefs.getBool('tournamentPrizeClaimed_$joinedEvent') == true) return null;

    final entries = await fetchLeaderboard(joinedEvent);
    if (entries.isEmpty) {
      // אין מה לתבוע (או שעדיין לא הגיע מידע) - לא מסמנים כנתבע כדי שננסה שוב בפעם הבאה.
      return null;
    }
    final deviceId = await DeviceId.get();
    final rank = entries.indexWhere((e) => e.deviceId == deviceId);
    await prefs.setBool('tournamentPrizeClaimed_$joinedEvent', true);
    // 🆕 האירוע נסגר (פרס/החזר כבר טופל או שאין מה לתבוע) - מנקים כדי
    // ש-hasJoinedEvent() יחזיר false עבור האירוע החדש הנוכחי, ויאפשר
    // הרשמה נקייה לאירוע הבא.
    await prefs.remove('tournamentJoinedEvent');
    if (rank < 0) return null; // לא השתתפו באירוע הקודם בפועל - אין מה לתבוע

    // 🆕 האפליקציה כבר פתוחה והגענו לכאן - התזכורת לטלפון כבר מילאה את
    // תפקידה (אם בכלל נורתה) או שלא תצטרך להינות יותר, כך או כך.
    NotificationService.cancelTournamentEndedReminder();

    // 🆕 מעט מדי משתתפים = לא ממש תחרות - כולם (לא רק המקומות הראשונים)
    // מקבלים את דמי הכניסה שלהם בחזרה, בלי קשר למיקום.
    if (entries.length < tournamentMinPlayers) {
      final coins = prefs.getInt('coins') ?? 15;
      await prefs.setInt('coins', coins + tournamentEntryFee);
      PlayerSyncService.syncCurrentProgress();
      return TournamentPrizeResult(outcome: TournamentOutcome.refund, coins: tournamentEntryFee);
    }

    if (rank > 2) return null;

    // הקופה בפועל = זריקת הפתיחה + (מספר הנרשמים שסיימו ונכנסו לטבלה
    // כפול דמי הכניסה). הפרס הוא אחוז ממנה - אף פעם לא משולם יותר ממה
    // שנאסף (ראו הערת הקובץ).
    final pool = currentPoolEstimate(entries.length);
    final share = [tournamentFirstShare, tournamentSecondShare, tournamentThirdShare][rank];
    final prize = (pool * share).round();
    if (prize <= 0) return null;
    final coins = prefs.getInt('coins') ?? 15;
    await prefs.setInt('coins', coins + prize);
    if (rank == 0) {
      await AchievementsService.inc('tournamentWins');
      MissionsService.recordEvent(MissionEvent.tournamentWon);
      // 🆕 "ניצחון בטורניר נותן 20% הנחה על כמה חבילות ספציפיות" - לפי
      // בקשה מפורשת. ראו ההערה המלאה ליד IapManager.tournamentBonusEligibleIds
      // להסבר למה זה בפועל "אותו מחיר, 25% יותר מטבעות" ולא שינוי מחיר
      // אמיתי (לא אפשרי מקוד הלקוח למוצרי IAP אמיתיים).
      await IapManager.activateTournamentBonus();
    }
    PlayerSyncService.syncCurrentProgress();
    return TournamentPrizeResult(outcome: TournamentOutcome.prize, rank: rank + 1, coins: prize);
  }
}
