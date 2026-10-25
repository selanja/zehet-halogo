// scheduled_tournament_service.dart
//
// 🆕 "טורניר מתוזמן" - פורמט טורניר שני, בנוסף (לא במקום!) לטורניר היומי
// הרגיל (tournament_service.dart) - לפי בקשה מפורשת: "טורנירים שמתחילים
// בשעה ספציפית ויש להם שעה לענות... 20/30 לוגואים". ההבדלים מהטורניר
// היומי:
//  - לא "משחקים מתי שרוצים לפני שהיום מסתיים" - יש חלון זמן קבוע אחד
//    ביום (ברירת מחדל: 20:00-21:00 שעון מקומי, ראו scheduledTournamentStartHour/
//    scheduledTournamentWindowMinutes) - אפשר להצטרף ולשחק רק בתוכו.
//  - אפשר להצטרף תוך כדי (גם לא בדיוק ב-20:00) כל עוד החלון עוד פתוח -
//    "הצטרפות" ו"משחק" הן בפועל אותה פעולה אחת (ראו join()+hasJoinedToday).
//  - "הרשמה מראש" (preRegisterForNext למטה) - לפי בקשה מפורשת, זו הרשמה
//    אמיתית: משלמים את דמי הכניסה *מיד* (עד יום שלם לפני שהחלון בפועל
//    נפתח), והמקום שלכם "שמור" - ברגע שהחלון נפתח אין צורך לשלם שוב,
//    פשוט לוחצים "שחקו" (ראו hasJoinedToday בצד ה-UI). בנוסף מתוזמנת
//    התראה מקומית בדיוק לרגע שהחלון נפתח. מי שלא נרשם-מראש עדיין יכול
//    להצטרף תוך כדי כרגיל (משלם באותו רגע, דרך join()).
//  - 25 לוגואים (בטווח 20-30 שביקשו) ודמי כניסה גבוהים יותר (100, כפול
//    מהיומי) - פורמט "יותר רציני", בהתאמה.
// שאר הארכיטקטורה (קופה=נרשמים×דמי כניסה, פרס=אחוז מהקופה 40/20/10%,
// <5 נרשמים=החזר מלא, הענקת תוצאה/פרס בצד הלקוח) זהה בכוונה לחלוטין
// לטורניר היומי - ראו ההערה המלאה שם להסברים (אותו טרייד-אוף MVP, אותה
// סיבה לפרס-יחסי-לא-קבוע). אוסף Firestore נפרד (scheduledTournamentEntries)
// ומפתחות SharedPreferences נפרדים (קידומת "scheduled") כדי לא להתנגש עם
// הטורניר היומי - שני הפורמטים רצים לגמרי במקביל, בלי תלות אחד בשני.
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_data.dart';
import 'device_id.dart';
import 'player_sync.dart';
import 'notification_service.dart'; // 🆕 הרשמה-מראש -> תזכורת מקומית, ראו preRegisterForNext
import 'notification_manager.dart'; // 🆕 מתזמנים תזכורת רק אם השחקן בכלל הדליק התראות בהגדרות
import 'battle_pass_service.dart';
import 'achievements_service.dart';
import 'missions_service.dart';
// 🆕 export (לא רק import) - כך ש-scheduled_tournament_screen.dart יוכל
// להשתמש ב-TournamentEntry/TournamentPrizeResult/tournamentFirstShare
// וכו' רק מ-import אחד (הקובץ הזה), בלי לייבא גם את tournament_service.dart
// בעצמו בכל קובץ שמשתמש בטורניר המתוזמן.
export 'tournament_service.dart' show TournamentEntry, TournamentOutcome, TournamentPrizeResult, tournamentFirstShare, tournamentSecondShare, tournamentThirdShare;
import 'tournament_service.dart' show TournamentEntry, TournamentOutcome, TournamentPrizeResult, tournamentFirstShare, tournamentSecondShare, tournamentThirdShare;
import 'iap_manager.dart'; // 🆕 ניצחון מפעיל את אותו מבצע 20% מטבעות כמו בטורניר היומי

const int scheduledTournamentEntryFee = 100;
const int scheduledTournamentLogoCount = 25;
const int scheduledTournamentStartHour = 20; // 20:00 שעון מקומי
const int scheduledTournamentWindowMinutes = 60;
const int scheduledTournamentMinPlayers = 5;
const int scheduledTournamentXpReward = 90;
const int scheduledTournamentBattlePassPoints = 45;

/// שלב הטורניר המתוזמן של היום, ביחס לעכשיו:
///  - upcoming: עוד לא התחיל היום (לפני scheduledTournamentStartHour).
///  - active: בתוך חלון המשחק (אפשר להצטרף/לשחק).
///  - closed: החלון של היום כבר נסגר (עד שמתחיל שוב מחר).
enum ScheduledTournamentPhase { upcoming, active, closed }

int currentScheduledPoolEstimate(int entrantsSoFar) => entrantsSoFar * scheduledTournamentEntryFee;

class ScheduledTournamentService {
  ScheduledTournamentService._();

  static final _db = FirebaseFirestore.instance;
  static const _collection = 'scheduledTournamentEntries';

  static String _dateId(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String todayId() => _dateId(DateTime.now());

  static DateTime _windowStart(DateTime day) => DateTime(day.year, day.month, day.day, scheduledTournamentStartHour);
  static DateTime _windowEnd(DateTime day) => _windowStart(day).add(const Duration(minutes: scheduledTournamentWindowMinutes));

  static ScheduledTournamentPhase get currentPhase {
    final now = DateTime.now();
    final start = _windowStart(now);
    final end = _windowEnd(now);
    if (now.isBefore(start)) return ScheduledTournamentPhase.upcoming;
    if (now.isBefore(end)) return ScheduledTournamentPhase.active;
    return ScheduledTournamentPhase.closed;
  }

  /// מועד תחילת החלון *הבא* - היום אם עוד לא התחיל (upcoming), אחרת
  /// (active/closed) מחר ב-scheduledTournamentStartHour. זה גם המועד
  /// שמתוזמנת אליו התראת ה"הרשמה מראש" (ראו preRegisterForNext למטה) -
  /// כך שמי שנרשם מראש בזמן שהחלון של היום עדיין פתוח (active) מקבל
  /// תזכורת לחלון של *מחר*, לא להיום שכבר באמצע/נגמר.
  static DateTime get nextStartTime {
    final now = DateTime.now();
    if (currentPhase == ScheduledTournamentPhase.upcoming) return _windowStart(now);
    return _windowStart(now.add(const Duration(days: 1)));
  }

  /// זמן שנותר עד nextStartTime - "מתחיל בעוד" (upcoming) או "חוזר מחר
  /// בעוד" (closed). 0 ב-active (באמצע החלון, אין "הבא" רלוונטי כרגע).
  static Duration get timeUntilNextStart {
    if (currentPhase == ScheduledTournamentPhase.active) return Duration.zero;
    final diff = nextStartTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// זמן שנותר עד סגירת החלון (רלוונטי רק ב-active - 0 אחרת).
  static Duration get timeLeftInWindow {
    if (currentPhase != ScheduledTournamentPhase.active) return Duration.zero;
    final now = DateTime.now();
    final diff = _windowEnd(now).difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// מועד החלון האחרון שכבר *נסגר* בפועל - "היום" אם אנחנו אחרי הסגירה
  /// של היום (closed), אחרת "אתמול" (upcoming/active - החלון של היום
  /// עוד לא הסתיים, אז התוצאה האחרונה הזמינה היא עדיין של אתמול).
  static String get lastClosedPeriodId {
    final now = DateTime.now();
    if (currentPhase == ScheduledTournamentPhase.closed) return todayId();
    return _dateId(now.subtract(const Duration(days: 1)));
  }

  /// הלוגואים הקבועים של היום - כמו בטורניר היומי, אבל עם מלח שונה
  /// ב-Random כדי שלא ייצא באותו סט לוגואים בדיוק (לא קריטי אם כן, רק
  /// ניקיון).
  static List<int> levelIdsForPeriod(String periodId) {
    final ids = gameLevels.keys.toList()..sort();
    final rnd = Random('scheduled-$periodId'.hashCode);
    final shuffled = List<int>.from(ids)..shuffle(rnd);
    return shuffled.take(scheduledTournamentLogoCount).toList();
  }

  static Future<bool> hasJoinedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('scheduledTournamentJoinedPeriod') == todayId();
  }

  static Future<Map<String, dynamic>?> _todayResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scheduledTournamentResult_${todayId()}');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasPlayedToday() async => (await _todayResult()) != null;

  static const _preRegisteredKey = 'scheduledTournamentPreRegistered';

  /// true אם כבר נרשמו-מראש *לחלון הבא* הספציפי (nextStartTime) - לא
  /// "בכלל אי-פעם". אם nextStartTime התקדם (למשל אתמול נרשמו להיום,
  /// והיום כבר הגיע ועבר) הערך הישן פשוט לא תואם יותר ומחזיר false,
  /// בלי צורך לנקות אותו באופן יזום.
  static Future<bool> hasPreRegisteredForNext() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preRegisteredKey) == _dateId(nextStartTime);
  }

  /// "הירשמו מראש וקבלו תזכורת" - לפי בקשה מפורשת, זה *כן* כולל תשלום
  /// מיידי של דמי הכניסה (בדיוק כמו join() למטה, רק מראש - עד יום שלם
  /// לפני שהחלון בפועל נפתח), לא רק תזכורת. ברגע שהחלון נפתח אין צורך
  /// לשלם שוב - ראו hasJoinedToday בצד ה-UI. בהצלחה חוזר null, ובכישלון
  /// (אין מספיק מטבעות) חוזר מספר המטבעות החסרים - אותו חוזה בדיוק כמו join().
  static Future<int?> preRegisterForNext() async {
    final prefs = await SharedPreferences.getInstance();
    final targetPeriod = _dateId(nextStartTime);
    final alreadyPaid = prefs.getString('scheduledTournamentJoinedPeriod') == targetPeriod;
    if (!alreadyPaid) {
      final coins = prefs.getInt('coins') ?? 15;
      if (coins < scheduledTournamentEntryFee) return scheduledTournamentEntryFee - coins;
      await prefs.setInt('coins', coins - scheduledTournamentEntryFee);
      await prefs.setString('scheduledTournamentJoinedPeriod', targetPeriod);
      PlayerSyncService.syncCurrentProgress();
    }
    await prefs.setString(_preRegisteredKey, targetPeriod);
    // 🆕 קטגוריית "עדכוני טורניר" בטאב ההתראות - ראו notification_manager.dart.
    if (NotificationManager.notificationsEnabled && NotificationManager.tournamentNotificationsEnabled) {
      await NotificationService.scheduleScheduledTournamentStartReminder(nextStartTime);
    }
    return null;
  }

  /// מבטלים הרשמה-מראש - אם עוד לא שיחקו בפועל בתקופה הזו, מחזירים את
  /// דמי הכניסה ששולמו ב-preRegisterForNext (לא הוגן "לכלוא" מטבעות של
  /// מישהו שהתחרט לפני שהחלון בכלל נפתח).
  static Future<void> cancelPreRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final targetPeriod = _dateId(nextStartTime);
    if (prefs.getString('scheduledTournamentJoinedPeriod') == targetPeriod) {
      final alreadyPlayed = prefs.getString('scheduledTournamentResult_$targetPeriod') != null;
      if (!alreadyPlayed) {
        final coins = prefs.getInt('coins') ?? 15;
        await prefs.setInt('coins', coins + scheduledTournamentEntryFee);
        await prefs.remove('scheduledTournamentJoinedPeriod');
        PlayerSyncService.syncCurrentProgress();
      }
    }
    await prefs.remove(_preRegisteredKey);
    await NotificationService.cancelScheduledTournamentStartReminder();
  }

  /// נרשם+משתתף (אותה פעולה - ראו הערת הקובץ) - בודק/מנכה דמי כניסה
  /// ומסמן "נרשם". קורא לזה מיד לפני הניווט למסך המשחק, רק אם currentPhase
  /// == active (המסך עצמו אחראי לבדוק את זה לפני שהוא בכלל מציג כפתור).
  /// בהצלחה חוזר null, ובכישלון (אין מספיק מטבעות) חוזר מספר המטבעות החסרים.
  /// 🩹 בטוח גם כנגד תשלום כפול - אם כבר שולם היום דרך preRegisterForNext,
  /// לא גובים שוב (ה-UI גם ככה לא אמור לקרוא לזה במקרה הזה, אבל ליתר ביטחון).
  static Future<int?> join() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('scheduledTournamentJoinedPeriod') == todayId()) {
      await NotificationService.cancelScheduledTournamentStartReminder();
      return null;
    }
    final coins = prefs.getInt('coins') ?? 15;
    if (coins < scheduledTournamentEntryFee) return scheduledTournamentEntryFee - coins;
    await prefs.setInt('coins', coins - scheduledTournamentEntryFee);
    await prefs.setString('scheduledTournamentJoinedPeriod', todayId());
    // 🆕 כבר בפנים - אין יותר טעם בתזכורת "הטורניר מתחיל", ראו
    // preRegisterForNext למעלה.
    await NotificationService.cancelScheduledTournamentStartReminder();
    PlayerSyncService.syncCurrentProgress();
    return null;
  }

  static Future<void> submitResult({required int correctCount, required int totalTimeMs}) async {
    final prefs = await SharedPreferences.getInstance();
    final periodId = todayId();
    final username = prefs.getString('username') ?? 'שחקן';
    final deviceId = await DeviceId.get();

    await prefs.setString('scheduledTournamentResult_$periodId', jsonEncode({'correctCount': correctCount, 'totalTimeMs': totalTimeMs}));

    try {
      await _db.collection(_collection).doc('${periodId}_$deviceId').set({
        'periodId': periodId,
        'deviceId': deviceId,
        'name': username,
        'correctCount': correctCount,
        'totalTimeMs': totalTimeMs,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // אופליין/שגיאת רשת - התוצאה המקומית כבר נשמרה, ננסה שוב לדרג בפעם הבאה שתיפתח הטבלה.
    }

    final xp = prefs.getInt('xp') ?? 0;
    await prefs.setInt('xp', xp + scheduledTournamentXpReward);
    BattlePassService.addPoints(scheduledTournamentBattlePassPoints);
    MissionsService.recordEvent(MissionEvent.tournamentPlayed);
    PlayerSyncService.syncCurrentProgress();
  }

  static Future<List<TournamentEntry>> fetchLeaderboard(String periodId) async {
    try {
      final snap = await _db.collection(_collection).where('periodId', isEqualTo: periodId).limit(500).get();
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

  /// נקרא כשנפתח המסך (וגם ב-main_menu_screen.dart בכניסה הכללית) - אם
  /// יש פרס ממתין מהחלון האחרון שכבר נסגר (lastClosedPeriodId) שעדיין
  /// לא נתבע, מעניק אותו ומחזיר את הפרטים כדי להציג חלונית "זכית!".
  static Future<TournamentPrizeResult?> checkAndClaimPendingPrize() async {
    final prefs = await SharedPreferences.getInstance();
    final periodId = lastClosedPeriodId;
    if (prefs.getBool('scheduledTournamentPrizeClaimed_$periodId') == true) return null;

    final entries = await fetchLeaderboard(periodId);
    if (entries.isEmpty) return null;
    final deviceId = await DeviceId.get();
    final rank = entries.indexWhere((e) => e.deviceId == deviceId);
    await prefs.setBool('scheduledTournamentPrizeClaimed_$periodId', true);
    if (rank < 0) return null;

    if (entries.length < scheduledTournamentMinPlayers) {
      final coins = prefs.getInt('coins') ?? 15;
      await prefs.setInt('coins', coins + scheduledTournamentEntryFee);
      PlayerSyncService.syncCurrentProgress();
      return TournamentPrizeResult(outcome: TournamentOutcome.refund, coins: scheduledTournamentEntryFee);
    }

    if (rank > 2) return null;

    final pool = currentScheduledPoolEstimate(entries.length);
    final share = [tournamentFirstShare, tournamentSecondShare, tournamentThirdShare][rank];
    final prize = (pool * share).round();
    if (prize <= 0) return null;
    final coins = prefs.getInt('coins') ?? 15;
    await prefs.setInt('coins', coins + prize);
    if (rank == 0) {
      await AchievementsService.inc('tournamentWins');
      MissionsService.recordEvent(MissionEvent.tournamentWon);
      await IapManager.activateTournamentBonus();
    }
    PlayerSyncService.syncCurrentProgress();
    return TournamentPrizeResult(outcome: TournamentOutcome.prize, rank: rank + 1, coins: prize);
  }
}
