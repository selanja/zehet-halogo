// duel_service.dart
//
// שירות דו-קרב (Duel) בזמן אמת - אחראי על:
//  1. Matchmaking אקראי - שחקן נכנס לתור, המערכת מתאימה אותו אוטומטית
//     לשחקן אחר שממתין. אם אין אף אחד תוך פרק זמן סביר - מחזירים סטטוס
//     "אין כרגע שחקנים מחוברים" כדי שהמסך יציג הודעה מתאימה במקום להיתקע
//     במסך "מחפש יריב..." לנצח.
//  2. שליחת/קבלת תשובות בזמן אמת דרך מסמך משחק משותף ב-Firestore.
//
// ⚠️ הערת אבטחה: בגרסה הזו בדיקת "מי ענה נכון ראשון" מתבצעת ב-Transaction
// בצד הלקוח (לא ב-Cloud Function). זה מספיק לגרסת MVP/בדיקות, אבל שחקן
// עם ידע טכני יכול תיאורטית "לרמות". לפני שיש תגמול אמיתי (מטבעות בתשלום
// וכו') כדאי להעביר את בדיקת הנכונות ל-Cloud Function כדי שהתשובה הנכונה
// לא תהיה חשופה בכלל בצד הלקוח.
//
// מבנה הנתונים ב-Firestore:
//
// duelQueue/{deviceId}
//   username        - שם השחקן שממתין
//   createdAt        - Server Timestamp - מתי נכנס לתור
//   matchId          - null כל עוד לא נמצא יריב; מתמלא ע"י השחקן שמצא אותו
//
// duels/{matchId}
//   player1Id, player1Name
//   player2Id, player2Name
//   player1Progress, player2Progress  - כמה לוגואים כל שחקן כבר פתר נכון
//                                       (0-10) - **כל אחד מתקדם על הקצב
//                                       שלו, לא משותף!** ראה הערה למטה.
//   status                          - 'countdown' | 'playing' | 'finished'
//   logoIds                         - 10 מזהי חידה מתוך gameLevels (זהים לשני השחקנים, בסדר קבוע)
//   createdAt                       - Server Timestamp
//   winnerId                        - מתמלא כשה-status הופך ל-finished (מי שהגיע ל-10 ראשון)
//
// 🆕 עיצוב עדכני (לא "מרוץ" יותר): שני השחקנים מקבלים בדיוק אותם
// לוגואים, אבל כל אחד עונה על שלו בקצב שלו - אם שחקן א' עונה נכון, זה
// מקדם רק אותו (player1Progress/player2Progress), לא את שחקן ב'. לכל
// לוגו יש 30 שניות (ראו duel_room_screen.dart) - אם הזמן נגמר בלי
// תשובה נכונה, עוברים ללוגו הבא בלי שזה נספר. כל שחקן רואה בזמן אמת
// כמה תשובות נכונות (player1Correct/player2Correct) יש ליריב. המשחק
// מסתיים רק אחרי ששני השחקנים עברו את כל הלוגואים שלהם, וה מנצח נקבע
// לפי מי שצבר יותר תשובות נכונות - לא לפי מי שסיים ראשון. הכל נקבע
// אטומית ב-Transaction (advanceLogo) כדי שסיום כמעט-בו-זמני לא ייצור
// מצב שבו שני הלקוחות "חושבים" שהם ניצחו.

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bot_config.dart';
import 'level_data.dart'; // 🆕 levelsCounts/worldDifficulty - ראו worldsForStake למטה
import 'package:flutter/foundation.dart' show debugPrint; // 🆕 הדפסת שגיאת אינדקס חסר לטבלת עונת הדו-קרבים

/// תוצאה אפשרית מ-DuelService.findMatch
enum DuelSearchStatus {
  matched,        // נמצא יריב, יש matchId
  noPlayersFound, // אף אחד לא נמצא בזמן הסביר - "אין כרגע שחקנים מחוברים"
  cancelled,      // המשתמש ביטל את החיפוש בעצמו
  error,
}

class DuelSearchResult {
  final DuelSearchStatus status;
  final String? matchId;
  final String? errorMessage;
  const DuelSearchResult(this.status, {this.matchId, this.errorMessage});
}

class DuelMatch {
  final String matchId;
  final String player1Id, player1Name;
  final String player2Id, player2Name;
  final int player1Progress, player2Progress;
  // 🆕 כמות התשובות הנכונות בפועל של כל שחקן - שונה מ-Progress (שהוא
  // כמה לוגואים כבר "עברו", גם אם נכשלו בזמן). המנצח נקבע לפי Correct,
  // לא לפי Progress/מהירות - ראו DuelService.advanceLogo.
  final int player1Correct, player2Correct;
  final String status; // countdown | playing | finished
  final List<int> logoIds;
  final String? winnerId;
  final int stake; // דמי הכניסה שכל שחקן שילם (לפי הרמה שנבחרה בלובי)
  // 🆕 כמות הלוגואים במשחק הזה - תלויה ברמת ההימור (15=5, 50=7, 200=10),
  // ראו DuelService.stakeQuestionCounts. נשמרת על המשחק עצמו (לא רק
  // מחושבת מהימור בכל מקום) כדי שהתנהגות המשחק תישאר עקבית גם אם
  // בעתיד נשנה את המיפוי הימור->כמות.
  final int totalQuestions;
  // 🆕 זמן ההתחלה האמיתי של המשחק (שרת) - לחישוב "כמה זמן זה לקח"
  // מדויק במסך התוצאה, זהה משני הצדדים (לא מבוסס שעון מכשיר מקומי).
  final DateTime? questionStartAt;
  // 🆕 "פעימת חיים" (heartbeat) - כל שחקן כותב לשדה שלו כל כמה שניות
  // כל עוד הוא בפועל במסך הדו-קרב (ראו DuelRoomScreen). זה מה שמאפשר
  // לצד השני לזהות ניתוק אמיתי (לא רק יציאה מבוקרת/PopScope) - למשל
  // אין אינטרנט, או שהאפליקציה נהרגה ע"י המערכת בלי ש-dispose() הספיק
  // לרוץ - ולהכריז על עצמו כמנצח אחרי כמה שניות בלי לחכות לנצח.
  final DateTime? player1LastSeen, player2LastSeen;

  // 🆕 "שחק שוב מול אותו יריב" - ראו DuelService.requestRematch. שני
  // השדות האלה יושבים על מסמך המשחק *הישן* (שכבר הסתיים): מי מהשחקנים
  // כבר ביקש רימאץ' (מזהי מכשירים), ואם שניהם ביקשו - המזהה של הדו-קרב
  // החדש שנוצר אוטומטית. שני הצדדים עדיין מאזינים למסמך הישן הזה גם
  // אחרי שהוא finished (ראו duel_room_screen.dart), אז ברגע ש-rematchMatchId
  // מתמלא - שניהם עוברים ישירות לדו-קרב החדש בלי שום צורך בקוד/הזמנה.
  final List<String> rematchRequestedBy;
  final String? rematchMatchId;
  // 🆕 "סדרת דו-קרב (הטוב מ-3)" - ראו DuelService.findMatch(wantsSeries).
  // seriesWins ממופה לפי deviceId->מספר סיבובים שנוצחו *בסדרה הזו* (לא
  // כולל את הסיבוב הנוכחי בזמן שהוא עדיין playing). seriesRound הוא
  // מספר הסיבוב הנוכחי (1,2,3).
  final bool seriesMode;
  final Map<String, int> seriesWins;
  final int seriesRound;

  DuelMatch({
    required this.matchId,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    required this.player1Progress,
    required this.player2Progress,
    required this.player1Correct,
    required this.player2Correct,
    required this.status,
    required this.logoIds,
    required this.winnerId,
    required this.stake,
    required this.totalQuestions,
    required this.questionStartAt,
    this.player1LastSeen,
    this.player2LastSeen,
    this.rematchRequestedBy = const [],
    this.rematchMatchId,
    this.seriesMode = false,
    this.seriesWins = const {},
    this.seriesRound = 1,
  });

  factory DuelMatch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DuelMatch(
      matchId: doc.id,
      player1Id: d['player1Id'] ?? '',
      player1Name: d['player1Name'] ?? 'שחקן 1',
      player2Id: d['player2Id'] ?? '',
      player2Name: d['player2Name'] ?? 'שחקן 2',
      player1Progress: d['player1Progress'] ?? 0,
      player2Progress: d['player2Progress'] ?? 0,
      player1Correct: d['player1Correct'] ?? 0,
      player2Correct: d['player2Correct'] ?? 0,
      status: d['status'] ?? 'countdown',
      logoIds: List<int>.from(d['logoIds'] ?? const []),
      winnerId: d['winnerId'] as String?,
      stake: d['stake'] ?? DuelService.stakeOptions.first,
      totalQuestions: d['totalQuestions'] ?? DuelService.questionsForStake(d['stake'] ?? DuelService.stakeOptions.first),
      questionStartAt: (d['questionStartAt'] as Timestamp?)?.toDate(),
      player1LastSeen: (d['lastSeenP1'] as Timestamp?)?.toDate(),
      player2LastSeen: (d['lastSeenP2'] as Timestamp?)?.toDate(),
      rematchRequestedBy: List<String>.from(d['rematchRequestedBy'] ?? const []),
      rematchMatchId: d['rematchMatchId'] as String?,
      seriesMode: d['seriesMode'] == true,
      seriesWins: Map<String, int>.from((d['seriesWins'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)) ?? const {}),
      seriesRound: (d['seriesRound'] as num?)?.toInt() ?? 1,
    );
  }

  /// המזהה של "היריב שלי", בהינתן מי אני
  String opponentIdFor(String myDeviceId) =>
      myDeviceId == player1Id ? player2Id : player1Id;

  int myProgressFor(String myDeviceId) =>
      myDeviceId == player1Id ? player1Progress : player2Progress;

  int opponentProgressFor(String myDeviceId) =>
      myDeviceId == player1Id ? player2Progress : player1Progress;

  int myCorrectFor(String myDeviceId) =>
      myDeviceId == player1Id ? player1Correct : player2Correct;

  int opponentCorrectFor(String myDeviceId) =>
      myDeviceId == player1Id ? player2Correct : player1Correct;

  /// מתי היריב שלי (לפי מי אני) נראה לאחרונה - null אם עדיין לא כתב
  /// אף heartbeat (למשל השחקן השני עוד לא הגיע למסך בכלל).
  DateTime? opponentLastSeenFor(String myDeviceId) =>
      myDeviceId == player1Id ? player2LastSeen : player1LastSeen;

  int seriesWinsFor(String deviceId) => seriesWins[deviceId] ?? 0;
  /// האם הסדרה כבר הוכרעה (מישהו הגיע ל-2 ניצחונות מתוך 3).
  bool get seriesDecided => seriesMode && seriesWins.values.any((w) => w >= 2);
}

class DuelService {
  // הבנאי הציבורי הרגיל (לא הופך את המחלקה ל-static utility class) -
  // כי findMatch/cancelSearch הם מתודות instance (משתמשות ב-_queueSub/
  // _timeoutTimer שצריכים "לחיות" לאורך זמן החיפוש של מופע ספציפי).
  // שאר המתודות (submitCorrectAnswer, watchMatch וכו') הן static כי הן
  // חסרות state ואין סיבה ליצור instance בשבילן.
  DuelService();

  static final _db = FirebaseFirestore.instance;
  static const _queueCollection = 'duelQueue';
  static const _duelsCollection = 'duels';

  // תור אחרי כמה שניות המתנה בלי יריב מוותרים ומחזירים noPlayersFound
  static const Duration searchTimeout = Duration(seconds: 25);
  // רשומת תור נחשבת "תקועה"/ישנה מדי אחרי כך - שחקן שסגר את האפליקציה
  // תוך כדי חיפוש לא ישאיר "רפאים" שחוסמים matchmaking לאחרים
  static const Duration staleQueueEntry = Duration(seconds: 30);

  static const int questionsPerDuel = 10;

  // 🆕 כלכלת הדו-קרב: בלובי בוחרים אחת מכמה "רמות הימור" - כל שחקן
  // משלם את הסכום שנבחר כדמי כניסה, המנצח לוקח את כל הקופה (פי 2 -
  // כלומר רווח נטו = הסכום, הפסד נטו = הסכום). matchmaking מתאים רק
  // בין שחקנים שבחרו באותה רמה בדיוק (אי אפשר "לפגוש" שחקן ברמה אחרת).
  // 🆕 5 = "דו-קרב בזק" - הרמה הכי זולה והכי מהירה (גם פחות לוגואים
  // וגם פחות זמן ללוגו - ראו stakeLogoTimeoutSeconds למטה), בשביל מי
  // שרוצה סיבוב קצר ומהיר בלי להתחייב להימור/משך של דו-קרב מלא.
  // 🆕 נוספו שתי רמות הימור לפי בקשה מפורשת ("עוד אופציות של כסף") -
  // 100 (בין 50 ל-200) ו-500 (הימור "היי-רולר" מעל 200, למי שרוצה סיכון
  // וקופה גדולה יותר).
  static const List<int> stakeOptions = [5, 15, 50, 100, 200, 500];
  static const int entryFeeCoins = 15; // ברירת מחדל/רמה ראשונה - נשאר לתאימות לאחור
  // 🆕 כל רמת הימור משחקת על כמות שונה של לוגואים - ככה ההימור הזול
  // הוא גם "משחק מהיר" (5 לוגואים) וההימור היקר הוא משחק מלא ומשמעותי
  // יותר (10 לוגואים). המנצח תמיד לוקח את כל הקופה (פי 2 מההימור).
  static const Map<int, int> stakeQuestionCounts = {5: 5, 15: 5, 50: 7, 100: 8, 200: 10, 500: 12};
  static int questionsForStake(int stake) => stakeQuestionCounts[stake] ?? questionsPerDuel;

  // 🩹 תוקן לפי בקשה מפורשת: 30 שניות לכל לוגו הרגיש מוגזם (עד 6 דקות
  // המתנה אפשרית בהימור של 12 לוגואים אם היריב מנצל כל שנייה) - גם מול
  // בוט וגם מול שחקן אמיתי. "בזק" (5) נשאר ללא שינוי - כבר מהיר מספיק.
  // הימורים קלים-בינוניים (15/50/100, רמת קושי 1-3 לפי stakeDifficulty)
  // ירדו ל-20 שניות כדי שהסיבוב ירגיש קצבי יותר. הימורים "קשים" (200/500,
  // רמת קושי 4-5) נשארו על 30 שניות - לוגואים נדירים/קשים יותר דורשים
  // יותר זמן מחשבה אמיתי, לא רק הרגל.
  static const Map<int, int> stakeLogoTimeoutSeconds = {5: 15, 15: 20, 50: 20, 100: 20, 200: 30, 500: 30};
  static int logoTimeoutForStake(int stake) => stakeLogoTimeoutSeconds[stake] ?? 30;

  // 🐛 תוקן: היה מאגר עולמות קבוע (רשימה כתובה ביד) לכל רמת הימור - בדיוק
  // סוג הבאג שכבר תפס אותנו פעמיים עם רמות חדשות (level_data.dart מול
  // logo_level_screen.dart): כל עולם חדש שנוסף חייב "לזכור" גם לעדכן את
  // הרשימה הזו בנפרד, וקל לשכוח. עכשיו זה מחושב אוטומטית מרמת הקושי
  // המספרית של כל עולם (worldDifficulty ב-level_data.dart, 1-5) - לכל
  // רמת הימור יש רמת קושי מקסימלית משלה (stakeDifficulty למטה), והמאגר
  // הוא *כל* העולמות עד רמת הקושי הזו כולל (מצטבר - לפי בקשה מפורשת:
  // "עולים ברמה, הרמות הקודמות עדיין שם"). עולם חדש שנוסף ל-levelsCounts
  // עם רמת קושי משויכת נכנס אוטומטית למאגר הנכון, בלי לגעת כאן בכלל.
  static const Map<int, int> stakeDifficulty = {5: 1, 15: 1, 50: 2, 100: 3, 200: 4, 500: 5};
  static int difficultyForStake(int stake) => stakeDifficulty[stake] ?? 1;

  static List<int> worldsForStake(int stake) {
    final maxDifficulty = difficultyForStake(stake);
    final worlds = levelsCounts.keys.where((w) => worldDifficulty(w) <= maxDifficulty).toList();
    worlds.sort();
    return worlds;
  }
  // 🐛 "כשמשחקים על 15 מטבעות, כל רמז עולה יותר מכל הניצחון של המשחק" -
  // בעקבות בקשה מפורשת המחיר עצמו *לא* משתנה לפי הימור (מחיר זול מדי
  // היה מאפשר לכל אחד "לעשות מה שהוא רוצה") - במקום זה רמזים חסומים
  // כליל בהימורים הזולים (5/15/50) וזמינים רק מ-100 מטבעות ומעלה, ראו
  // hintsAllowedForStake למטה.
  static const int letterHintCost = 20;
  static const int wordHintCost = 60;
  static int letterHintCostForStake(int stake) => letterHintCost;
  static int wordHintCostForStake(int stake) => wordHintCost;
  static bool hintsAllowedForStake(int stake) => stake >= 100;

  // 🆕 קנס על יציאה באמצע דו-קרב/מרוץ פעיל - המטבעות/האנרגיה כבר "אבודים"
  // ממילא (נגבו כשהמשחק התחיל), והיריב תמיד מוכרז מנצח ומקבל את הקופה
  // (forfeitMatch/LogoRaceService המקביל) בלי קשר לכלום למטה - זה נשאר
  // אותו דבר. מה שכן משתנה כאן זה רק אם היציאה *גם* נספרת כ"אזהרה"
  // לצורך חסימה עתידית:
  //  - יציאה מבוקרת (כפתור X) בלוגו הראשון/השני (progress<2) - אזהרה.
  //  - יציאה מבוקרת מהלוגו השלישי ואילך - "פרישה" - בלי הצטברות אזהרות
  //    בכלל (לפי בקשה מפורשת: זה עונש נפרד, המפסיד כבר "משלם" בזה
  //    שהיריב מנצח - לא צריך גם להעניש עם אזהרה).
  //  - ניתוק מוחלט (האפליקציה נסגרה/קרסה, ראו opponentDisconnectTimeoutSeconds
  //    למטה) - תמיד אזהרה, לא משנה על איזה לוגו - כי אין שום "יציאה
  //    מבוקרת" שאפשר להעריך לפיה, ומבחינת היריב זו התנהגות זהה לנטישה.
  // משותף לדו-קרב ולמרוץ (logo_race_screen.dart קורא לפונקציות האלה
  // ישירות דרך duel_service.dart - "מוניטין" אחד לשני המצבים, לא שני
  // מונים נפרדים - עוזב-חוזר בדו-קרב לא אמור "להתחיל מחדש" במרוץ).
  static const _penaltiesCollection = 'duelPenalties';
  static const int forfeitBanHours = 3;
  // 🆕 כמה אזהרות (שלא פגו) מובילות לחסימה - הועלה מ-2 ל-4 לפי בקשה
  // מפורשת, יחד עם ההבחנה למעלה בין "אזהרה" ל"פרישה" (שלא נספרת).
  static const int forfeitBanThreshold = 4;
  // 🆕 אזהרה שלא "התחדשה" (אזהרה נוספת) במשך כל כך הרבה ימים - נחשבת
  // פגה, והמונה מתאפס בפעם הבאה שנדרשת אזהרה חדשה. כך שחקן עם עבר רחוק
  // לא נשאר "אזהרה אחת מחסימה" לצמיתות.
  static const int warningsResetDays = 3;

  /// כמה חידות יש סה"כ - מגיע מבחוץ (gameLevels.length בקובץ logo_level_screen)
  /// כדי לא ליצור תלות מעגלית בין הקבצים.
  static List<int> pickRandomLogoIds(List<int> allLevelIds, {int count = questionsPerDuel}) {
    final pool = List<int>.from(allLevelIds)..shuffle(Random());
    return pool.take(count).toList();
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;
  Timer? _timeoutTimer;
  // 🆕 ראו ה"סריקה חוזרת" בתוך findMatch למטה - מנסה שוב כל כמה שניות
  // לתפוס יריב בזמן שממתינים בתור, כדי לתקן את באג ה"קיפאון" כששני
  // שחקנים מתחילים לחפש כמעט באותו רגע.
  Timer? _rescanTimer;

  // 🆕 ניקוי הזדמנותי של מסמכי דו-קרב ישנים ב-Firestore (duels/{matchId})
  // - בלי זה הם נשארים שם לנצח, גם אחרי שהמשחק הסתיים מזמן. אין כרגע
  // Cloud Function מתוזמנת בפועל (זו דורשת פריסה ידנית - ראו
  // cloud_functions_notifications_snippet.js -> cleanupOldDuels), אז
  // בינתיים מריצים ניקוי קליל מצד הלקוח: בכל פעם שמישהו נכנס לחפש
  // יריב, יש סיכוי קטן (1 מתוך 10) שהמכשיר שלו ימחק עד 50 דו-קרבים
  // ישנים שהסתיימו. זה לא מושלם (תלוי שיהיו מספיק חיפושים כדי שזה
  // ירוץ), אבל עדיף על כלום ולא דורש שום פריסה בצד שלך.
  // ⚠️ בפעם הראשונה שזה ירוץ, Firestore עשוי לדרוש אינדקס מורכב
  // (status + createdAt) - זה עטוף ב-try/catch כך שזה לא יפיל כלום,
  // אבל הניקוי לא יעבוד עד שתיצור את האינדקס (Firestore Console בדרך
  // כלל נותן קישור ישיר ליצירתו בלוג השגיאה של הפרויקט).
  static const int oldDuelCleanupDays = 3;
  static Future<void> _maybeCleanupOldDuels() async {
    if (Random().nextInt(10) != 0) return;
    await cleanupOldDuelsNow();
  }

  /// 🆕 אותה מחיקה בדיוק, אבל *בלי* ההגרלה (1 מתוך 10) - לקריאה ישירה
  /// פעם אחת בכל הפעלת אפליקציה (ראה main.dart), כדי שהניקוי לא יהיה
  /// תלוי רק בכך שיהיו מספיק חיפושי דו-קרב כדי "להתגלגל" ולרוץ.
  static Future<void> cleanupOldDuelsNow() async {
    try {
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: oldDuelCleanupDays)));
      final oldSnap = await _db
          .collection(_duelsCollection)
          .where('status', isEqualTo: 'finished')
          .where('createdAt', isLessThan: cutoff)
          .limit(50)
          .get();
      if (oldSnap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in oldSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // ניקוי הזדמנותי בלבד - לא חלק קריטי מהמשחק, לא מפילים כלום בגללו.
    }
  }

  /// מחפש/יוצר דו-קרב אקראי. מחזיר Future שמסתיים כשנמצא יריב, כשעבר הזמן
  /// המוקצב, או אם בוטל ידנית (ע"י קריאה ל-cancelSearch על אותו instance).
  static Map<String, dynamic> _seriesFieldsFor(bool wantsSeries) =>
      wantsSeries ? {'seriesMode': true, 'seriesWins': <String, dynamic>{}, 'seriesRound': 1} : {};

  Future<DuelSearchResult> findMatch({
    required String deviceId,
    required String username,
    required List<int> allLevelIds,
    required int stake,
    // 🆕 "סדרת דו-קרב" - מחפש רק יריבים שגם הם ביקשו סדרה (לא מתערבב
    // עם חיפוש דו-קרב בודד רגיל), ראו _seriesFieldsFor למטה.
    bool wantsSeries = false,
  }) async {
    // 🆕 לא חוסם את החיפוש עצמו - רץ ברקע (ראו _maybeCleanupOldDuels למעלה)
    _maybeCleanupOldDuels();
    final completer = Completer<DuelSearchResult>();
    bool finished = false;
    void finish(DuelSearchResult r) {
      if (finished) return;
      finished = true;
      _queueSub?.cancel();
      _timeoutTimer?.cancel();
      _rescanTimer?.cancel();
      completer.complete(r);
    }

    try {
      // שלב 1: מנסים למצוא מישהו שכבר ממתין (רשומה "טרייה" בלבד, לא רפאים)
      // 🆕 מסננים גם לפי 'stake' - כדי שרק שחקנים שבחרו באותה רמת הימור
      // בדיוק ייפגשו (מי ששם 15 לא אמור להתמודד מול מי ששם 200).
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(staleQueueEntry));
      final waitingSnap = await _db
          .collection(_queueCollection)
          .where('matchId', isNull: true)
          .where('stake', isEqualTo: stake)
          .where('createdAt', isGreaterThan: cutoff)
          .orderBy('createdAt')
          .limit(5)
          .get();

      final candidate = waitingSnap.docs.where((d) => d.id != deviceId && (d.data()['wantsSeries'] == true) == wantsSeries).firstOrNull;

      if (candidate != null) {
        // שלב 2: ניסיון "לתפוס" את היריב הזה ב-Transaction, כדי שאם שני
        // שחקנים ינסו לתפוס אותו יריב באותו רגע - רק אחד יצליח
        final matchId = await _db.runTransaction<String?>((tx) async {
          final oppRef = _db.collection(_queueCollection).doc(candidate.id);
          final oppSnap = await tx.get(oppRef);
          if (!oppSnap.exists || oppSnap.data()?['matchId'] != null) {
            return null; // מישהו אחר כבר תפס אותו קודם
          }

          final totalQuestions = questionsForStake(stake);
          final logoIds = pickRandomLogoIds(allLevelIds, count: totalQuestions);
          final matchRef = _db.collection(_duelsCollection).doc();
          tx.set(matchRef, {
            'player1Id': candidate.id,
            'player1Name': oppSnap.data()?['username'] ?? 'שחקן',
            'player2Id': deviceId,
            'player2Name': username,
            'player1Progress': 0,
            'player2Progress': 0,
            'player1Correct': 0,
            'player2Correct': 0,
            'status': 'countdown',
            'logoIds': logoIds,
            'createdAt': FieldValue.serverTimestamp(),
            'winnerId': null,
            'stake': stake,
            'totalQuestions': totalQuestions,
            ..._seriesFieldsFor(wantsSeries),
          });
          tx.update(oppRef, {'matchId': matchRef.id});
          return matchRef.id;
        });

        if (matchId != null) {
          finish(DuelSearchResult(DuelSearchStatus.matched, matchId: matchId));
          return completer.future;
        }
        // אם ה-Transaction נכשל (מישהו אחר תפס קודם) - ממשיכים לשלב 3
        // ונכנסים לתור בעצמנו, בדיוק כמו אם לא היה אף מועמד מלכתחילה.
      }

      // שלב 3: אין מועמד זמין - נכנסים לתור בעצמנו וממתינים שמישהו יתפוס אותנו
      final myQueueRef = _db.collection(_queueCollection).doc(deviceId);
      await myQueueRef.set({
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'matchId': null,
        'stake': stake,
        'wantsSeries': wantsSeries,
      });

      _queueSub = myQueueRef.snapshots().listen((snap) {
        final matchId = snap.data()?['matchId'] as String?;
        if (matchId != null) {
          myQueueRef.delete(); // מנקים את רשומת התור - כבר לא צריכים אותה
          finish(DuelSearchResult(DuelSearchStatus.matched, matchId: matchId));
        }
      }, onError: (e) {
        finish(DuelSearchResult(DuelSearchStatus.error, errorMessage: e.toString()));
      });

      // 🩹 באג שתוקן ("לפעמים matchmaking בכלל לא מוצא יריב"): אם שני
      // שחקנים לוחצים "חפש" כמעט באותו רגע, יכול לקרות ששלב 1 למעלה
      // מפספס אצל *שניהם* - כל אחד שולח את שאילתת ה-waitingSnap שלו לפני
      // שהשני הספיק לכתוב את רשומת התור שלו, כך ששניהם מגיעים לכאן
      // (שלב 3) ופשוט "יושבים" בתור ומחכים ל-matchId שאף אחד לא הולך
      // לכתוב - כי הקוד הקודם רק *האזין* פסיבית (queueSub למעלה) בלי
      // לנסות לחפש שוב, ואז שניהם נופלים ל-noPlayersFound אחרי searchTimeout.
      // התיקון: בזמן שאנחנו בתור, סורקים מחדש כל כמה שניות (לא רק
      // מסתמכים על queueSub) ומנסים לתפוס יריב שממתין - הפעם ב-Transaction
      // שקוראת/כותבת גם את המסמך *שלנו* וגם את של המועמד יחד (לא רק את
      // שלו, כמו בניסיון הראשוני למעלה), כדי שגם אם שני הצדדים מנסים
      // "לתפוס" זה את זה כמעט בו-זמנית - Firestore יבטיח ששני המסמכים
      // נכתבים אטומית ורק ניסיון אחד מצליח (השני נופל בשקט ומנסה שוב).
      _rescanTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (finished) return;
        try {
          final rescanCutoff = Timestamp.fromDate(DateTime.now().subtract(staleQueueEntry));
          final rescanSnap = await _db
              .collection(_queueCollection)
              .where('matchId', isNull: true)
              .where('stake', isEqualTo: stake)
              .where('createdAt', isGreaterThan: rescanCutoff)
              .orderBy('createdAt')
              .limit(5)
              .get();
          if (finished) return;
          final rescanCandidate = rescanSnap.docs.where((d) => d.id != deviceId && (d.data()['wantsSeries'] == true) == wantsSeries).firstOrNull;
          if (rescanCandidate == null) return;

          final rescanMatchId = await _db.runTransaction<String?>((tx) async {
            final myRef = _db.collection(_queueCollection).doc(deviceId);
            final oppRef = _db.collection(_queueCollection).doc(rescanCandidate.id);
            final mySnap = await tx.get(myRef);
            final oppSnap = await tx.get(oppRef);
            // בודקים גם את שלנו וגם את של המועמד - יכול להיות ששניהם
            // כבר נתפסו (על ידי queueSub הפסיבי, או ניסיון סריקה מקביל).
            if (!mySnap.exists || mySnap.data()?['matchId'] != null) return null;
            if (!oppSnap.exists || oppSnap.data()?['matchId'] != null) return null;

            final totalQuestions = questionsForStake(stake);
            final logoIds = pickRandomLogoIds(allLevelIds, count: totalQuestions);
            final matchRef = _db.collection(_duelsCollection).doc();
            tx.set(matchRef, {
              'player1Id': rescanCandidate.id,
              'player1Name': oppSnap.data()?['username'] ?? 'שחקן',
              'player2Id': deviceId,
              'player2Name': username,
              'player1Progress': 0,
              'player2Progress': 0,
              'player1Correct': 0,
              'player2Correct': 0,
              'status': 'countdown',
              'logoIds': logoIds,
              'createdAt': FieldValue.serverTimestamp(),
              'winnerId': null,
              'stake': stake,
              'totalQuestions': totalQuestions,
              ..._seriesFieldsFor(wantsSeries),
            });
            tx.update(oppRef, {'matchId': matchRef.id});
            tx.update(myRef, {'matchId': matchRef.id});
            return matchRef.id;
          });

          if (rescanMatchId != null) {
            myQueueRef.delete().catchError((_) {});
            finish(DuelSearchResult(DuelSearchStatus.matched, matchId: rescanMatchId));
          }
        } catch (_) {
          // סריקה חוזרת בלבד - לא קריטית, ננסה שוב בפעם הבאה (או ש-
          // queueSub/searchTimeout יטפלו בזה בסוף).
        }
      });

      _timeoutTimer = Timer(searchTimeout, () async {
        if (finished) return;
        // 🆕 אף יריב אמיתי לא נמצא - במקום "אין שחקנים" מכניסים יריב-בוט
        // (ראו createBotMatchIfStillWaiting), כדי שאף אחד לא יישאר בלי משחק.
        // 🆕 "סדרת דו-קרב" נבדקת מול מתג בוטים נפרד ('superdual') - לפי
        // בקשה מפורשת, כדי שאפשר יהיה להדליק/לכבות בוטים לכל מוד בנפרד
        // דרך Firebase (ראו bot_config.dart).
        if (botFallbackEnabled && await BotConfig.enabledFor(wantsSeries ? 'superdual' : 'duel') && !finished) {
          try {
            final botMatchId = await _createBotMatchIfStillWaiting(
              deviceId: deviceId,
              username: username,
              allLevelIds: allLevelIds,
              stake: stake,
              wantsSeries: wantsSeries,
            );
            if (botMatchId != null) {
              finish(DuelSearchResult(DuelSearchStatus.matched, matchId: botMatchId));
              return;
            }
          } catch (_) {
            // נופלים לתוצאה הרגילה למטה
          }
        }
        await myQueueRef.delete().catchError((_) {});
        finish(const DuelSearchResult(DuelSearchStatus.noPlayersFound));
      });
    } catch (e) {
      finish(DuelSearchResult(DuelSearchStatus.error, errorMessage: e.toString()));
    }

    return completer.future;
  }

  // ============================================================
  // 🆕 יריב-בוט - כשלא נמצא שחקן אמיתי אחרי searchTimeout.
  // המשחק נוצר כרגיל ב-Firestore (השחקן האמיתי הוא player1, הבוט player2
  // עם מזהה שמתחיל ב-botIdPrefix), והלקוח של השחקן האמיתי "מנגן" בשם
  // הבוט (ראו _BotDriver ב-duel_room_screen.dart). אין סטטיסטיקות
  // ניצחונות/עונה/ראש-בראש/רימאץ' מול בוט.
  // ============================================================
  static const bool botFallbackEnabled = true;
  static const String botIdPrefix = 'bot_';
  static bool isBotId(String id) => id.startsWith(botIdPrefix);

  static List<String> get botNames => _botNames;
  static const List<String> _botNames = [
    'דניאל', 'נועה', 'איתי', 'מיכל', 'עומר', 'שיר', 'יונתן', 'תמר', 'אורי', 'ליאור',
    'רוני', 'גיל', 'הדר', 'עידו', 'מאיה', 'אלון', 'ענת', 'רן', 'נוי', 'תום',
    'yuval_k', 'dan123', 'noa_l', 'omer.b', 'Tal', 'Amit', 'Shir', 'Guy', 'Roy', 'Lior',
  ];

  /// יוצר משחק מול בוט, אבל רק אם רשומת התור שלי עדיין לא נתפסה ע"י שחקן
  /// אמיתי (Transaction) - אם כן נתפסה, מחזיר את המשחק האמיתי במקום.
  Future<String?> _createBotMatchIfStillWaiting({
    required String deviceId,
    required String username,
    required List<int> allLevelIds,
    required int stake,
    bool wantsSeries = false,
  }) async {
    final rnd = Random();
    final botId = '$botIdPrefix${rnd.nextInt(900000) + 100000}';
    var botName = _botNames[rnd.nextInt(_botNames.length)];
    if (botName == username) botName = _botNames[(_botNames.indexOf(botName) + 1) % _botNames.length];
    final myRef = _db.collection(_queueCollection).doc(deviceId);
    return _db.runTransaction<String?>((tx) async {
      final mySnap = await tx.get(myRef);
      final existing = mySnap.data()?['matchId'] as String?;
      if (existing != null) return existing; // נתפסתי ע"י שחקן אמיתי ברגע האחרון
      final totalQuestions = questionsForStake(stake);
      final matchRef = _db.collection(_duelsCollection).doc();
      tx.set(matchRef, {
        'player1Id': deviceId,
        'player1Name': username,
        'player2Id': botId,
        'player2Name': botName,
        'player1Progress': 0,
        'player2Progress': 0,
        'player1Correct': 0,
        'player2Correct': 0,
        'status': 'countdown',
        'logoIds': pickRandomLogoIds(allLevelIds, count: totalQuestions),
        'createdAt': FieldValue.serverTimestamp(),
        'winnerId': null,
        'stake': stake,
        'totalQuestions': totalQuestions,
        'vsBot': true,
        ..._seriesFieldsFor(wantsSeries),
      });
      if (mySnap.exists) tx.delete(myRef);
      return matchRef.id;
    });
  }

  /// ביטול חיפוש יזום ע"י המשתמש (למשל לחיצה על "ביטול" במסך ההמתנה)
  Future<void> cancelSearch(String deviceId) async {
    _queueSub?.cancel();
    _timeoutTimer?.cancel();
    _rescanTimer?.cancel(); // 🆕 עוצרים גם את הסריקה החוזרת התקופתית
    await _db.collection(_queueCollection).doc(deviceId).delete().catchError((_) {});
  }

  /// מאזין חי למצב הדו-קרב - ניקוד, שאלה נוכחית, מנצח וכו'
  static Stream<DuelMatch> watchMatch(String matchId) {
    return _db
        .collection(_duelsCollection)
        .doc(matchId)
        .snapshots()
        .where((s) => s.exists)
        .map((s) => DuelMatch.fromDoc(s));
  }

  /// 🆕 מדווח שעברתי (אני, isPlayer1/2) ללוגו הבא - newProgress הוא כמה
  /// לוגואים כבר "עברו" אצלי (בין אם ענית נכון ובין אם נגמר הזמן - 30
  /// שניות לכל לוגו, ראו duel_room_screen.dart), ו-gotItRight אומר אם
  /// הלוגו הזה נספר כתשובה נכונה. המשחק מסתיים באחד משני מצבים:
  ///  (א) 🆕 ניצחון מיידי - אם ענית נכון על *כל* הלוגואים שלך (הגעת
  ///      לניקוד המושלם האפשרי - כמות שווה ל-totalQuestions) - אתה מוכרז
  ///      מנצח *מיד*, בלי לחכות שהיריב יסיים גם הוא (אין לו סיכוי להשוות
  ///      תוצאה גבוהה יותר ממילא ברגע שהגעת למקסימום).
  ///  (ב) שני השחקנים סיימו את כל הלוגואים שלהם (בלי ניצחון מיידי של אף
  ///      אחד) - או-אז המנצח נקבע לפי מי שצבר יותר תשובות נכונות
  ///      (Correct), לא לפי מי שסיים מהר יותר. רק אם יש שוויון מוחלט -
  ///      ההכרעה היא מי שסיים שני (הראשון "המתין" בזה שהשני עוד לא הגיע).
  /// הכל ב-Transaction כדי שסיום כמעט-בו-זמני של שני הצדדים לא ייצור
  /// מצב שבו שני הלקוחות "חושבים" שהם ניצחו.
  static Future<void> advanceLogo({
    required String matchId,
    required bool isPlayer1,
    required int newProgress,
    required bool gotItRight,
  }) async {
    final matchRef = _db.collection(_duelsCollection).doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(matchRef);
      final d = snap.data();
      if (d == null) return;
      if (d['status'] == 'finished') return; // המשחק כבר הוכרע - אין מה לעדכן

      final progressField = isPlayer1 ? 'player1Progress' : 'player2Progress';
      final currentProgress = (d[progressField] ?? 0) as int;
      if (newProgress <= currentProgress) return; // עדכון כפול/מיושן - מתעלמים

      final correctField = isPlayer1 ? 'player1Correct' : 'player2Correct';
      final currentCorrect = (d[correctField] ?? 0) as int;
      final myNewCorrect = gotItRight ? currentCorrect + 1 : currentCorrect;

      // 🆕 כמות הלוגואים לניצחון תלויה במשחק הספציפי הזה (לפי ההימור
      // שנבחר) - לא בקבוע גלובלי קבוע.
      final totalQuestions = (d['totalQuestions'] ?? questionsForStake(d['stake'] ?? stakeOptions.first)) as int;
      final update = <String, dynamic>{
        progressField: newProgress,
        if (gotItRight) correctField: myNewCorrect,
      };

      final myId = isPlayer1 ? d['player1Id'] : d['player2Id'];
      final otherId = isPlayer1 ? d['player2Id'] : d['player1Id'];

      // 🆕 (א) ניצחון מיידי - עניתי נכון על כל הלוגואים שלי (ניקוד מושלם).
      // אין צורך לחכות ליריב - אין לו סיכוי להשיג תוצאה גבוהה יותר.
      if (myNewCorrect >= totalQuestions) {
        update['status'] = 'finished';
        update['winnerId'] = myId;
        if (d['seriesMode'] == true) update['seriesWins.$myId'] = FieldValue.increment(1);
        tx.update(matchRef, update);
        return;
      }

      final otherProgressField = isPlayer1 ? 'player2Progress' : 'player1Progress';
      final otherProgress = (d[otherProgressField] ?? 0) as int;

      if (newProgress >= totalQuestions && otherProgress >= totalQuestions) {
        // שני השחקנים סיימו את כל הלוגואים שלהם - מכריעים עכשיו.
        final otherCorrectField = isPlayer1 ? 'player2Correct' : 'player1Correct';
        final otherCorrect = (d[otherCorrectField] ?? 0) as int;
        update['status'] = 'finished';
        if (myNewCorrect > otherCorrect) {
          update['winnerId'] = myId;
        } else if (otherCorrect > myNewCorrect) {
          update['winnerId'] = otherId;
        } else {
          // שוויון מוחלט בכמות הנכונות - אני זה שהגיע לכאן שני (השני כבר
          // סיים את כל הלוגואים שלו קודם) ולכן הוא "היה ראשון" ומנצח.
          update['winnerId'] = otherId;
        }
        if (d['seriesMode'] == true) update['seriesWins.${update['winnerId']}'] = FieldValue.increment(1);
      }
      tx.update(matchRef, update);
    });
  }

  /// מעביר את המשחק מ-'countdown' ל-'playing' ומתחיל את הטיימר של השאלה
  /// הראשונה. בטוח לקרוא משני הלקוחות במקביל (למשל אם שני השחקנים סיימו
  /// את הספירה לאחור המקומית שלהם כמעט יחד) - התנאי status=='countdown'
  /// ב-Transaction מבטיח שרק הקריאה הראשונה בפועל תשפיע, השנייה "תיפול"
  /// בשקט כי הסטטוס כבר לא countdown.
  static Future<void> startMatchIfNeeded(String matchId) async {
    final matchRef = _db.collection(_duelsCollection).doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(matchRef);
      final d = snap.data();
      if (d == null || d['status'] != 'countdown') return;
      tx.update(matchRef, {
        'status': 'playing',
        'questionStartAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // 🆕 כל כמה שניות נחשב "עדיין בחיים" - ראו player1LastSeen/player2LastSeen
  // ב-DuelMatch ו-_maybeForfeitDisconnectedOpponent ב-duel_room_screen.dart.
  static const int heartbeatIntervalSeconds = 4;
  // 🩹 היה 20 שניות (הועלה בעבר מ-10, כדי לתת שולי טעות להפרעות קצרות
  // ולגיטימיות - התראת מערכת, מסך הרשאה, מעבר קצר לאפליקציה אחרת). לפי
  // בקשה מפורשת חזר ל-15: עכשיו יש גם מסך "ממתין לחיבור מחדש" בזמן
  // ההמתנה (ראו _buildWaitingForReconnectOverlay ב-duel_room_screen.dart)
  // וגם תמיכה ב"חזרה למשחק" אם היריב אכן חוזר תוך כדי (ראו
  // active_match_service.dart) - כך שגם אם 15 שניות "תפס" הפרעה קצרה
  // בטעות, זה לא הרס סופי: אם השחקן חוזר, הוא יוכנס ישר בחזרה כל עוד
  // המשחק עדיין 'playing' (לא נגמר עדיין ברגע שהוא חזר).
  static const int opponentDisconnectTimeoutSeconds = 15;

  /// כתיבת "פעימת חיים" - נקרא כל כמה שניות מ-DuelRoomScreen כל עוד
  /// השחקן בפועל במסך. כתיבה קלה (לא Transaction) לשדה נפרד משדות
  /// ההתקדמות - כך שלא מתחרה עם advanceLogo. לא קריטי אם נכשל (בדיוק
  /// המצב שאנחנו רוצים לזהות אצל היריב) - עטוף ב-try/catch שקט.
  static Future<void> updateHeartbeat(String matchId, {required bool isPlayer1}) async {
    try {
      await _db.collection(_duelsCollection).doc(matchId).update({
        isPlayer1 ? 'lastSeenP1' : 'lastSeenP2': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // בדיוק המצב שאנחנו מנסים לזהות (אין אינטרנט וכו') - שקט, בלי לזרוק.
    }
  }

  /// שחקן עוזב את הדו-קרב באמצע (סוגר את המסך/האפליקציה) - היריב מוכרז מנצח
  //
  // 🩹 באג חמור שתוקן: הפונקציה הזו נהגה לעבוד עם get() רגיל ואז update()
  // רגיל (בלי Transaction) - כלומר קריאה וכתיבה *לא אטומיות*. duel_room_screen.dart
  // קורא לה משני כיוונים שיכולים לקרות כמעט בו-זמנית: (א) שחקן עוזב בעצמו
  // (leavingDeviceId=אני), וגם (ב) _maybeForfeitDisconnectedOpponent מכריז
  // *את עצמו* מנצח כשהיריב שותק יותר מדי (leavingDeviceId=היריב). אם שני
  // הצדדים חוו יחד הפרעת רשת רגעית (Wi-Fi/אמולטור) והחמיצו את פעימות
  // החיים ההדדיות שלהם - שני הלקוחות יכולים לקרוא ל-forfeitMatch כמעט
  // באותו רגע, כל אחד "חושב" שהוא זה שהיריב שלו התנתק. בלי Transaction,
  // שני ה-get() הראשוניים יכולים לקרוא את אותו status='playing' (לפני
  // שהעדכון הראשון בכלל הגיע לשרת), ואז שני ה-update() רצים - וכל מכשיר
  // שרואה את ה-update *שלו* עצמו (הכתיבה המקומית "אופטימית" של Firestore,
  // לפני אישור השרת) קובע מיד אצלו winnerId=עצמו ומציג "ניצחת!" - וזה
  // בדיוק מה שגרם לשני הצדדים לראות "ניצחת!" יחד באותו דו-קרב (הבאג
  // שדווח ב-1.9.2026). עכשיו הכל בתוך Transaction אחד, בדיוק כמו
  // advanceLogo/startMatchIfNeeded/requestRematch למעלה: הבדיקה
  // status=='finished' נעשית *בתוך* ה-Transaction על הנתונים העדכניים
  // ביותר בשרת, כך שרק הקריאה שמגיעה ראשונה בפועל (מבחינת השרת, לא
  // מבחינת מי שהתחיל להריץ קודם מקומית) מצליחה לקבוע מנצח - הקריאה
  // השנייה "נופלת" בשקט (status כבר finished) ולא דורסת שום דבר.
  // 🐛 תוקן: עכשיו מחזיר bool - true רק אם הקריאה הזו *בפועל* קבעה מנצח
  // (המשחק עוד לא היה finished כשהיא רצתה בשרת), false אם זו הייתה
  // no-op כי מישהו כבר הכריע קודם. חשוב במיוחד ב-_maybeForfeitDisconnectedOpponent
  // (duel_room_screen.dart): אם שני הצדדים חושבים בו-זמנית שהשני התנתק
  // (למשל הפרעת רשת רגעית משותפת), רק קריאה אחת מהן באמת "מנצחת" בשרת -
  // בלי הערך המוחזר הזה, הצד שהקריאה שלו נפלה (כי הוא בעצם *הפסיד*)
  // עדיין היה ממשיך ולהעניש בטעות את המנצח האמיתי דרך applyForfeitPenalty.
  static Future<bool> forfeitMatch(String matchId, String leavingDeviceId) async {
    final matchRef = _db.collection(_duelsCollection).doc(matchId);
    bool applied = false;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(matchRef);
      final d = snap.data();
      if (d == null || d['status'] == 'finished') return;
      final opponentId = d['player1Id'] == leavingDeviceId ? d['player2Id'] : d['player1Id'];
      final update = <String, dynamic>{'status': 'finished', 'winnerId': opponentId};
      // 🆕 "סדרת דו-קרב" - עזיבה/ניתוק מסיימים את *כל הסדרה* מיד (לא רק
      // את הסיבוב), כי מי שעזב לא חוזר לסיבוב הבא ממילא - בלי זה הצד
      // השני היה נשאר תקוע לנצח ב"הסיבוב הבא מתחיל תוך רגע" (רק צד אחד
      // עדיין קיים כדי לבקש רימאץ' - bothRequested לעולם לא היה מתקיים).
      if (d['seriesMode'] == true) {
        final currentWins = ((d['seriesWins'] as Map<String, dynamic>?)?[opponentId] as num?)?.toInt() ?? 0;
        update['seriesWins.$opponentId'] = currentWins + 1 < 2 ? 2 : currentWins + 1;
      }
      tx.update(matchRef, update);
      applied = true;
    });
    return applied;
  }

  /// קורא את מצב האזהרות/חסימה הנוכחי של שחקן (לפי מכשיר) - בלי לשנות
  /// כלום. משמש גם לפני יציאה (כדי להציג הודעה מדויקת) וגם בלובי (כדי
  /// לחסום כניסה לחיפוש כשיש חסימה פעילה).
  static Future<Map<String, dynamic>> getForfeitStatus(String deviceId) async {
    final snap = await _db.collection(_penaltiesCollection).doc(deviceId).get();
    final d = snap.data();
    if (d == null) return {'warnings': 0, 'banUntilMs': null};
    return {'warnings': _effectiveWarnings(d), 'banUntilMs': d['banUntil'] as int?};
  }

  static bool isBanned(Map<String, dynamic> status) {
    final banUntilMs = status['banUntilMs'] as int?;
    if (banUntilMs == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(banUntilMs).isAfter(DateTime.now());
  }

  // 🆕 אזהרות "פגות" (ראו warningsResetDays למעלה) - אם עברו יותר מדי
  // ימים מאז האזהרה האחרונה בלי אזהרה חדשה, מתייחסים למונה כאילו הוא 0.
  static int _effectiveWarnings(Map<String, dynamic> d) {
    final lastWarningAtMs = d['lastWarningAt'] as int?;
    if (lastWarningAtMs == null) return (d['warnings'] ?? 0) as int; // מסמך ישן מלפני התוספת הזו - מתייחסים כרגיל
    final expired = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastWarningAtMs)) > const Duration(days: warningsResetDays);
    return expired ? 0 : ((d['warnings'] ?? 0) as int);
  }

  /// רושם "עזיבה באמצע דו-קרב/מרוץ" עבור מכשיר מסוים. `countsAsWarning`
  /// קובע אם זה בכלל מצטבר למונה האזהרות (ראו ההסבר המלא ליד
  /// forfeitBanThreshold למעלה) - אם false, זו no-op שרק מחזירה את המצב
  /// הנוכחי בלי לגעת בו (פרישה מאוחרת - לא נספרת).
  static Future<Map<String, dynamic>> applyForfeitPenalty(String deviceId, {required bool countsAsWarning}) async {
    if (!countsAsWarning) return getForfeitStatus(deviceId);
    final ref = _db.collection(_penaltiesCollection).doc(deviceId);
    // 🩹 לא Transaction בכוונה - ראו הסבר היסטורי: רק המכשיר עצמו (או
    // היריב שמכריז על ניתוקו) כותב למסמך העונשין הזה, אין תרחיש אמיתי
    // של כתיבה כפולה בו-זמנית שדורשת אטומיות.
    final snap = await ref.get();
    final d = snap.data();
    final priorWarnings = d == null ? 0 : _effectiveWarnings(d);
    final warnings = priorWarnings + 1;
    final update = <String, dynamic>{'warnings': warnings, 'lastWarningAt': DateTime.now().millisecondsSinceEpoch};
    int? banUntilMs;
    if (warnings >= forfeitBanThreshold) {
      banUntilMs = DateTime.now().add(const Duration(hours: forfeitBanHours)).millisecondsSinceEpoch;
      update['banUntil'] = banUntilMs;
    }
    await ref.set(update, SetOptions(merge: true));
    return {'warnings': warnings, 'banUntilMs': banUntilMs};
  }

  /// 🆕 מנקה את החסימה/האזהרות של המכשיר *הנוכחי בלבד* (אף פעם לא של
  /// מכשיר אחר - deviceId תמיד מגיע מ-DeviceId.get() של המכשיר שקורא לזה).
  /// כלי עזר כדי שלא תצטרך גישה ל-Firebase Console כדי לנקות חסימה
  /// לעצמך בזמן בדיקות.
  static Future<void> clearMyForfeitPenalty(String deviceId) async {
    try {
      await _db.collection(_penaltiesCollection).doc(deviceId).delete();
    } catch (_) {}
  }

  // ================================================================
  // 🆕 "נמצא יריב" - סטטיסטיקות אמיתיות למסך שלפני תחילת הדו-קרב
  // (מסך העיצוב "Opponent Found"): ניצחונות כלליים ומאזן ראש-בראש בין
  // שני השחקנים הספציפיים האלה. שני אלה לא היו קיימים קודם באפליקציה -
  // נשמרים במסמכים ייעודיים שמתעדכנים פעם אחת בלבד לכל דו-קרב (ולא פעמיים,
  // פעם מכל מכשיר) בעזרת Transaction ודגל 'statsRecorded' על מסמך המשחק.
  // ================================================================
  static const _statsCollection = 'duelStats'; // duelStats/{deviceId} -> {wins}
  static const _h2hCollection = 'duelH2H'; // duelH2H/{pairKey} -> {idA, winsA, winsB}

  // ================================================================
  // 🆕 "עונת דו-קרבים" - טבלת שיאים חודשית נפרדת מהניצחונות הכוללים
  // (duelStats, שנשמרים לתמיד). כל מסמך מפתחו לפי חודש+שנה+מכשיר, כך
  // שבתחילת כל חודש הטבלה מתאפסת אוטומטית בלי שום job/תחזוקה ידנית -
  // פשוט נפתח מסמך חדש. duelSeasonStats/{seasonId}_{deviceId} ->
  // {seasonId, deviceId, name, wins} - name מתעדכן בכל ניצחון כדי שהטבלה
  // תמיד תציג את השם העדכני ביותר של השחקן, גם אם הוא שינה אותו.
  // ================================================================
  static const _seasonStatsCollection = 'duelSeasonStats';

  /// מזהה העונה הנוכחית - "2026-08" למשל. עונה חדשה = חודש קלנדרי חדש.
  static String currentSeasonId([DateTime? now]) {
    final n = now ?? DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  /// שם עונה ידידותי להצגה בטבלת השיאים ("אוגוסט 2026").
  static String seasonDisplayName([DateTime? now]) {
    const hebrewMonths = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    final n = now ?? DateTime.now();
    return '${hebrewMonths[n.month - 1]} ${n.year}';
  }

  static String _pairKey(String a, String b) => (a.compareTo(b) <= 0) ? '${a}_$b' : '${b}_$a';

  /// נקרא פעם אחת מכל מכשיר בסיום דו-קרב (ראה duel_room_screen.dart) -
  /// אבל בזכות ה-Transaction ודגל 'statsRecorded' על מסמך המשחק, גם אם
  /// שני המכשירים קוראים לזה כמעט יחד, הספירה תתעדכן פעם אחת בלבד.
  static Future<void> recordMatchResultOnce({
    required String matchId,
    required String player1Id,
    required String player2Id,
    required String? winnerId,
    String? winnerName,
  }) async {
    final matchRef = _db.collection(_duelsCollection).doc(matchId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(matchRef);
        final d = snap.data();
        if (d == null || d['statsRecorded'] == true) return;
        tx.update(matchRef, {'statsRecorded': true});

        if (winnerId != null) {
          final winnerRef = _db.collection(_statsCollection).doc(winnerId);
          tx.set(winnerRef, {'wins': FieldValue.increment(1)}, SetOptions(merge: true));

          // 🆕 טבלת השיאים העונתית (מתאפסת כל חודש - ראו currentSeasonId).
          final seasonId = currentSeasonId();
          final seasonRef = _db.collection(_seasonStatsCollection).doc('${seasonId}_$winnerId');
          tx.set(seasonRef, {
            'seasonId': seasonId,
            'deviceId': winnerId,
            'name': winnerName ?? '',
            'wins': FieldValue.increment(1),
          }, SetOptions(merge: true));
        }

        final a = player1Id, b = player2Id;
        final pairKey = _pairKey(a, b);
        final isAFirst = a.compareTo(b) <= 0;
        final h2hRef = _db.collection(_h2hCollection).doc(pairKey);
        final winsAIncrement = winnerId == null ? 0 : (winnerId == (isAFirst ? a : b) ? 1 : 0);
        final winsBIncrement = winnerId == null ? 0 : (winnerId == (isAFirst ? b : a) ? 1 : 0);
        tx.set(h2hRef, {
          'idA': isAFirst ? a : b,
          'winsA': FieldValue.increment(winsAIncrement),
          'winsB': FieldValue.increment(winsBIncrement),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      // 🆕 סטטיסטיקה "נחמד שיהיה" ולא קריטית - כשל כאן לא אמור למנוע
      // מהשחקן לראות את מסך התוצאה הרגיל.
    }
  }

  static Future<int> getWins(String deviceId) async {
    try {
      final snap = await _db.collection(_statsCollection).doc(deviceId).get();
      return (snap.data()?['wins'] ?? 0) as int;
    } catch (_) {
      return 0;
    }
  }

  /// מחזיר {mine, theirs} - כמה ניצחונות יש לי מול היריב הספציפי הזה
  /// (ולהיפך), מתוך כל הדו-קרבים שנערכו ביניהם עד כה.
  static Future<Map<String, int>> getHeadToHead(String myId, String opponentId) async {
    try {
      final pairKey = _pairKey(myId, opponentId);
      final snap = await _db.collection(_h2hCollection).doc(pairKey).get();
      final d = snap.data();
      if (d == null) return {'mine': 0, 'theirs': 0};
      final idA = d['idA'] as String?;
      final winsA = (d['winsA'] ?? 0) as int;
      final winsB = (d['winsB'] ?? 0) as int;
      final mine = idA == myId ? winsA : winsB;
      final theirs = idA == myId ? winsB : winsA;
      return {'mine': mine, 'theirs': theirs};
    } catch (_) {
      return {'mine': 0, 'theirs': 0};
    }
  }

  /// שולף את X המובילים בעונת הדו-קרבים הנוכחית (החודש הזה), ממוין לפי
  /// ניצחונות בסדר יורד. כל שורה: {deviceId, name, wins}. לא קריטי -
  /// כשל בשליפה מחזיר רשימה ריקה במקום לזרוק חריגה.
  //
  // 🩹 "טבלת עונת הדו-קרבים לא עובדת, היא לא מזהה ניצחונות" - כמעט
  // בוודאות זה NOT א-באג בקוד: השאילתה כאן משלבת where('seasonId',...)
  // + orderBy('wins',...) על שני שדות שונים - Firestore דורש לזה אינדקס
  // מורכב (composite index) שנוצר ידנית בקונסולה. בלי האינדקס, השאילתה
  // נכשלת עם FAILED_PRECONDITION - וקודם זה נבלע בשקט ע"י ה-catch, אז
  // הטבלה פשוט הייתה ריקה תמיד בלי שום שגיאה נראית לעין. עכשיו השגיאה
  // המלאה (כולל קישור ישיר ליצירת האינדקס!) נדפסת ל-debugPrint - תריץ
  // `flutter run`, תיכנס לטבלת העונה, ותחפש בלוג שורה שמתחילה
  // ב-"BATTLE PASS SEASON LEADERBOARD ERROR" - יהיה שם קישור שאפשר
  // ללחוץ עליו ישירות כדי שפיירבייס ייצור את האינדקס אוטומטית (לוקח
  // בערך דקה להיבנות בצד השרת).
  static Future<List<Map<String, dynamic>>> getSeasonLeaderboard({int limit = 20}) async {
    try {
      final seasonId = currentSeasonId();
      final snap = await _db
          .collection(_seasonStatsCollection)
          .where('seasonId', isEqualTo: seasonId)
          .orderBy('wins', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return {
          'deviceId': d['deviceId'] ?? '',
          'name': (d['name'] ?? '').toString().isEmpty ? 'שחקן' : d['name'],
          'wins': (d['wins'] ?? 0) as int,
        };
      }).toList();
    } catch (e) {
      debugPrint('SEASON LEADERBOARD ERROR (getSeasonLeaderboard - כנראה חסר אינדקס מורכב ב-Firestore): $e');
      return [];
    }
  }

  /// המקום והניצחונות של שחקן ספציפי בעונה הנוכחית - לכרטיס "המקום שלי"
  /// מעל/מתחת לטבלה (לא רק ל-20 המובילים, גם אם השחקן לא נמצא ביניהם).
  /// 🩹 אותה סיבה בדיוק כמו למעלה - השאילתה השנייה כאן (seasonId + wins
  /// גדול-מ) גם דורשת אינדקס מורכב נפרד. גם כאן השגיאה המלאה (עם הקישור
  /// ליצירת האינדקס) עכשיו נדפסת במקום להיבלע בשקט.
  static Future<Map<String, dynamic>?> getMySeasonRank(String deviceId) async {
    try {
      final seasonId = currentSeasonId();
      final mySnap = await _db.collection(_seasonStatsCollection).doc('${seasonId}_$deviceId').get();
      final myWins = (mySnap.data()?['wins'] ?? 0) as int;
      if (myWins == 0) return {'rank': null, 'wins': 0};
      // סופרים כמה שחקנים עם יותר ניצחונות ממני בעונה הזו - המקום שלי = זה+1.
      final higherSnap = await _db
          .collection(_seasonStatsCollection)
          .where('seasonId', isEqualTo: seasonId)
          .where('wins', isGreaterThan: myWins)
          .count()
          .get();
      final higherCount = higherSnap.count ?? 0;
      return {'rank': higherCount + 1, 'wins': myWins};
    } catch (e) {
      debugPrint('SEASON LEADERBOARD ERROR (getMySeasonRank - כנראה חסר אינדקס מורכב ב-Firestore): $e');
      return null;
    }
  }

  /// מבטל דו-קרב *לפני* שהתחיל בפועל (עדיין ב-status 'countdown', אף
  /// אחד לא ענה על אף שאלה) - מסמן "תיקו" (בלי מנצח) כדי שהיריב לא יישאר
  /// תקוע מחכה, אבל *בלי* להעביר קופה - כי דמי הכניסה (stake) עדיין לא
  /// נגבו בפועל בשלב הזה (הם נגבים רק כשנכנסים ל-DuelRoomScreen). ה-
  /// Transaction עם התנאי status=='countdown' מונע מצב שבו לוחצים "ביטול"
  /// בדיוק ברגע שהיריב כבר התחיל את הדו-קרב בפועל.
  static Future<void> cancelBeforeStart(String matchId) async {
    final matchRef = _db.collection(_duelsCollection).doc(matchId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(matchRef);
        final d = snap.data();
        if (d == null || d['status'] != 'countdown') return;
        tx.update(matchRef, {'status': 'finished', 'winnerId': null});
      });
    } catch (_) {}
  }

  // ================================================================
  // 🆕 "שחק שוב מול אותו יריב" (Rematch) - במקום לחזור ללובי ולחפש יריב
  // אקראי חדש, שני השחקנים שכבר סיימו דו-קרב יחד יכולים ללחוץ "שחק
  // שוב" ישירות ממסך התוצאה. שניהם עדיין מאזינים למסמך המשחק *הישן*
  // (שכבר finished) - אז אין צורך בשום קוד/הזמנה: ברגע ששני מזהי
  // המכשירים נמצאים ב-rematchRequestedBy, איזה מהצדדים שמגיע לזה
  // *שני* (בכל סדר - לא בהכרח player1 דווקא, כדי שאם הצד שהיה "אמור"
  // ליצור כבר עזב את המסך, השני עדיין יכול ליצור בעצמו) יוצר דו-קרב
  // חדש בין אותם שני שחקנים בדיוק, באותה רמת הימור, וכותב את המזהה
  // שלו בחזרה על המסמך הישן - שני הצדדים מזהים את זה (rematchMatchId)
  // ועוברים אליו ישירות. הבדיקה rematchMatchId != null מונעת כפילות
  // גם אם שני הלקוחות מגיעים לכאן כמעט בו-זמנית.
  // ================================================================
  static Future<void> requestRematch({
    required String oldMatchId,
    required String myDeviceId,
    required List<int> allLevelIds,
  }) async {
    final oldRef = _db.collection(_duelsCollection).doc(oldMatchId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(oldRef);
        final d = snap.data();
        if (d == null) return;
        if (d['rematchMatchId'] != null) return; // כבר נוצר - אין מה לעשות שוב

        final existing = List<String>.from(d['rematchRequestedBy'] ?? const []);
        if (!existing.contains(myDeviceId)) existing.add(myDeviceId);

        final player1Id = d['player1Id'] as String? ?? '';
        final player2Id = d['player2Id'] as String? ?? '';
        final bothRequested = existing.contains(player1Id) && existing.contains(player2Id);

        if (!bothRequested) {
          tx.update(oldRef, {'rematchRequestedBy': existing});
          return;
        }

        // שני הצדדים ביקשו - מי שהגיע לכאן שני (וגילה ש-bothRequested
        // כבר true) הוא זה שיוצר את הדו-קרב החדש בפועל. זה לא בהכרח
        // תמיד אותו שחקן (player1) - בכוונה, כדי שאם השחקן שהיה אמור
        // ליצור כבר עזב את המסך, השני עדיין יכול ליצור בעצמו. הבדיקה
        // rematchMatchId != null למעלה מונעת כפילות גם אם שני הלקוחות
        // מגיעים לכאן כמעט בו-זמנית.
        final stake = (d['stake'] ?? stakeOptions.first) as int;
        final totalQuestions = questionsForStake(stake);
        final logoIds = pickRandomLogoIds(allLevelIds, count: totalQuestions);
        final newRef = _db.collection(_duelsCollection).doc();
        // 🆕 "סדרת דו-קרב" - אם המשחק הישן היה חלק מסדרה, ממשיכים אותה (אותו
        // seriesWins שנצבר, סיבוב הבא) - לא רק רימאץ' חד-פעמי רגיל.
        final oldSeriesMode = d['seriesMode'] == true;
        tx.set(newRef, {
          'player1Id': player1Id,
          'player1Name': d['player1Name'],
          'player2Id': player2Id,
          'player2Name': d['player2Name'],
          'player1Progress': 0,
          'player2Progress': 0,
          'player1Correct': 0,
          'player2Correct': 0,
          'status': 'countdown',
          'logoIds': logoIds,
          'createdAt': FieldValue.serverTimestamp(),
          'winnerId': null,
          'stake': stake,
          'totalQuestions': totalQuestions,
          if (oldSeriesMode) 'seriesMode': true,
          if (oldSeriesMode) 'seriesWins': Map<String, dynamic>.from(d['seriesWins'] ?? const {}),
          if (oldSeriesMode) 'seriesRound': ((d['seriesRound'] as num?)?.toInt() ?? 1) + 1,
        });
        tx.update(oldRef, {'rematchRequestedBy': existing, 'rematchMatchId': newRef.id});
      });
    } catch (_) {
      // לא קריטי - אם זה נכשל, הכפתור פשוט נשאר במצב "ממתין" והשחקן
      // תמיד יכול לחזור ללובי הרגיל ולחפש יריב חדש במקום.
    }
  }

  /// 🆕 המשך "סדרת דו-קרב" מול בוט - כמו requestRematch, אבל בלי הריקוד
  /// של "שני הצדדים צריכים לבקש": מול בוט יש רק לקוח אמיתי אחד (הבוט
  /// כולו מדומה אצלו), אז הוא יוצר את הסיבוב הבא ישירות בקריאה אחת.
  /// מחזיר את מזהה הדו-קרב החדש (או הקיים, אם כבר נוצר קודם - אידמפוטנטי).
  static Future<String?> createNextSeriesRoundVsBot({
    required String oldMatchId,
    required List<int> allLevelIds,
  }) async {
    final oldRef = _db.collection(_duelsCollection).doc(oldMatchId);
    try {
      return await _db.runTransaction<String?>((tx) async {
        final snap = await tx.get(oldRef);
        final d = snap.data();
        if (d == null) return null;
        if (d['rematchMatchId'] != null) return d['rematchMatchId'] as String?; // כבר נוצר - לא כפול

        final stake = (d['stake'] ?? stakeOptions.first) as int;
        final totalQuestions = questionsForStake(stake);
        final logoIds = pickRandomLogoIds(allLevelIds, count: totalQuestions);
        final newRef = _db.collection(_duelsCollection).doc();
        tx.set(newRef, {
          'player1Id': d['player1Id'],
          'player1Name': d['player1Name'],
          'player2Id': d['player2Id'],
          'player2Name': d['player2Name'],
          'player1Progress': 0,
          'player2Progress': 0,
          'player1Correct': 0,
          'player2Correct': 0,
          'status': 'countdown',
          'logoIds': logoIds,
          'createdAt': FieldValue.serverTimestamp(),
          'winnerId': null,
          'stake': stake,
          'totalQuestions': totalQuestions,
          'vsBot': true,
          'seriesMode': true,
          'seriesWins': Map<String, dynamic>.from(d['seriesWins'] ?? const {}),
          'seriesRound': ((d['seriesRound'] as num?)?.toInt() ?? 1) + 1,
        });
        tx.update(oldRef, {'rematchMatchId': newRef.id});
        return newRef.id;
      });
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // 🆕 "אתגר חבר" - במקום matchmaking אקראי, שחקן יכול ליצור קוד הזמנה
  // בן 6 תווים ולשלוח אותו לחבר (וואטסאפ וכו') - החבר מקליד את הקוד
  // ומתחיל דו-קרב ישירות מולו, בלי לעבור דרך התור האקראי בכלל.
  //
  // duelInvites/{code}
  //   creatorId, creatorName  - מי יצר את ההזמנה
  //   stake                   - רמת ההימור שנבחרה בעת היצירה
  //   status                  - 'waiting' | 'matched' | 'cancelled'
  //   matchId                 - מתמלא כשמישהו מצטרף בפועל
  //   createdAt               - Server Timestamp - לחישוב תפוגה
  // ================================================================
  static const _invitesCollection = 'duelInvites';
  static const Duration inviteExpiry = Duration(minutes: 1);
  static const int inviteCodeLength = 6;
  // בכוונה בלי 0/O ו-1/I - קלות להתבלבל ביניהן כשמקלידים קוד שקיבלו בטקסט.
  static const String _inviteCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _generateInviteCode() {
    final rnd = Random();
    return List.generate(inviteCodeLength, (_) => _inviteCodeChars[rnd.nextInt(_inviteCodeChars.length)]).join();
  }

  /// יוצר קוד הזמנה חדש וכותב אותו ל-Firestore. מנסה כמה פעמים במקרה
  /// הנדיר של התנגשות בקוד קיים. זורק חריגה אם כל הניסיונות נכשלו.
  static Future<String> createInvite({
    required String deviceId,
    required String username,
    required int stake,
  }) async {
    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateInviteCode();
      final ref = _db.collection(_invitesCollection).doc(code);
      try {
        // 🩹 תוקן: בעבר זה עבר דרך runTransaction כדי לבדוק+לכתוב אטומית -
        // אבל Transaction.get() על מסמך שעדיין *לא קיים* (וזה המקרה כאן
        // כמעט תמיד, כי בודקים קוד רנדומלי חדש) חושף תקלה ידועה בתוסף
        // cloud_firestore עצמו: "Bad state: Future already completed",
        // שקורסת מחוץ ל-try/catch כי היא קורית בצד הפלאגין הנטיבי (לא
        // בקוד שלנו) - בדיוק מה שקרה בפועל. מרחב הקודים ענק (33^6 ~ 1.3
        // מיליארד צירופים אפשריים), כך שהסיכוי ששני מכשירים יגרילו בדיוק
        // אותו קוד באותו רגע אפסי בקנה המידה של האפליקציה הזו - אז בדיקה
        // וכתיבה רגילות (לא אטומיות, אבל בטוחות בפועל בהסתברות הזו)
        // מונעות את התקלה בלי לוותר על שום דבר משמעותי.
        final existing = await ref.get();
        if (existing.exists) continue; // התנגשות אסטרונומית נדירה - ננסה קוד אחר
        await ref.set({
          'creatorId': deviceId,
          'creatorName': username,
          'stake': stake,
          'status': 'waiting',
          'matchId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return code;
      } catch (_) {
        // ננסה שוב עם קוד חדש
      }
    }
    throw Exception('לא הצלחנו ליצור קוד הזמנה - נסה שוב');
  }

  /// מאזין חי למצב ההזמנה - היוצר משתמש בזה כדי לדעת מתי מישהו הצטרף
  /// (status הופך ל-'matched' ו-matchId מתמלא).
  static Stream<Map<String, dynamic>?> watchInvite(String code) {
    return _db.collection(_invitesCollection).doc(code).snapshots().map((s) => s.data());
  }

  /// ביטול הזמנה (למשל אם היוצר מוותר לפני שמישהו הצטרף)
  static Future<void> cancelInvite(String code) async {
    try {
      await _db.collection(_invitesCollection).doc(code).delete();
    } catch (_) {}
  }

  /// 🆕 דחיית הזמנה ישירה מחבר (ראו friends_screen.dart/main.dart -
  /// הדיאלוג הקופץ "X הזמין אותך לדו-קרב"). לא מוחקים את המסמך מיד -
  /// רק מסמנים status:'declined', כדי שהיוצר (שמאזין ל-watchInvite)
  /// יקבל עדכון חי ויידע להציג "החבר דחה את ההזמנה" במקום לחכות
  /// לתפוגת הקוד אחרי 15 דקות. היוצר בעצמו מנקה את המסמך בפועל אחרי
  /// שהוא רואה את הדחייה (ראו _listenToMyInvite).
  static Future<void> declineInvite(String code) async {
    try {
      await _db.collection(_invitesCollection).doc(code).update({'status': 'declined'});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getInvite(String code) async {
    try {
      final snap = await _db.collection(_invitesCollection).doc(code.trim().toUpperCase()).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// מצטרפים לדו-קרב לפי קוד הזמנה. אטומי (Transaction) - כך ששני
  /// אנשים לא יכולים "לתפוס" את אותו קוד בו-זמנית, ובודק גם תפוגה
  /// (inviteExpiry) וגם שלא מדובר בקוד של עצמך.
  static Future<JoinInviteResult> joinInvite({
    required String code,
    required String deviceId,
    required String username,
    required List<int> allLevelIds,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != inviteCodeLength) {
      return const JoinInviteResult(JoinInviteStatus.notFound);
    }
    final ref = _db.collection(_invitesCollection).doc(cleanCode);
    // 🩹 בדיקה רגילה (לא בתוך Transaction) קודם - תופסת מיד את המקרה
    // הנפוץ ביותר (קוד שגוי/לא קיים - הקלדה שגויה) בלי לגעת ב-
    // runTransaction בכלל. חשוב כי Transaction.get() על מסמך שלא קיים
    // חושף תקלה ידועה בתוסף cloud_firestore ("Bad state: Future already
    // completed" - ראו הערה מפורטת ליד createInvite). זו לא בדיקה
    // אטומית (תיאורטית ההזמנה יכולה להימחק בול בין הבדיקה הזו ל-
    // Transaction למטה), אבל היא מסננת את המקרה הנפוץ באמת בלי לסכן קריסה.
    final preCheck = await ref.get();
    if (!preCheck.exists) return const JoinInviteResult(JoinInviteStatus.notFound);
    try {
      return await _db.runTransaction<JoinInviteResult>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return const JoinInviteResult(JoinInviteStatus.notFound);
        final d = snap.data()!;
        if (d['creatorId'] == deviceId) return const JoinInviteResult(JoinInviteStatus.ownCode);
        if (d['status'] != 'waiting') return const JoinInviteResult(JoinInviteStatus.alreadyUsed);

        final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && DateTime.now().difference(createdAt) > inviteExpiry) {
          return const JoinInviteResult(JoinInviteStatus.expired);
        }

        final stake = (d['stake'] ?? stakeOptions.first) as int;
        final totalQuestions = questionsForStake(stake);
        final logoIds = pickRandomLogoIds(allLevelIds, count: totalQuestions);
        final matchRef = _db.collection(_duelsCollection).doc();
        tx.set(matchRef, {
          'player1Id': d['creatorId'],
          'player1Name': d['creatorName'],
          'player2Id': deviceId,
          'player2Name': username,
          'player1Progress': 0,
          'player2Progress': 0,
          'player1Correct': 0,
          'player2Correct': 0,
          'status': 'countdown',
          'logoIds': logoIds,
          'createdAt': FieldValue.serverTimestamp(),
          'winnerId': null,
          'stake': stake,
          'totalQuestions': totalQuestions,
        });
        tx.update(ref, {'status': 'matched', 'matchId': matchRef.id});
        return JoinInviteResult(JoinInviteStatus.matched, matchId: matchRef.id);
      });
    } catch (e) {
      return JoinInviteResult(JoinInviteStatus.error, errorMessage: e.toString());
    }
  }
}

/// תוצאה אפשרית מ-DuelService.joinInvite
enum JoinInviteStatus {
  matched,      // הצטרפות הצליחה, יש matchId
  notFound,     // אין קוד כזה (או שהוקלד לא נכון)
  expired,      // הקוד קיים אבל עברו יותר מ-inviteExpiry דקות
  ownCode,      // ניסית להצטרף לקוד שאתה עצמך יצרת
  alreadyUsed,  // מישהו אחר כבר הצטרף/ההזמנה בוטלה
  error,
}

class JoinInviteResult {
  final JoinInviteStatus status;
  final String? matchId;
  final String? errorMessage;
  const JoinInviteResult(this.status, {this.matchId, this.errorMessage});
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}