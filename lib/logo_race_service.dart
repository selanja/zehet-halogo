// logo_race_service.dart
//
// "מרוץ לוגואים" - 1 על 1, matchmaking בדיוק כמו דו-קרב (duel_service.dart),
// אבל שונה לגמרי במנגנון עצמו:
//
//  - בוחרים רמת הימור (20/50/100/200 מטבעות) - בדיוק כמו בדו-קרב, וכמות
//    הלוגואים במרוץ תלויה ברמה (ראו stakeQuestionCounts למטה - ככל
//    שההימור גבוה יותר, יש יותר לוגואים, בדיוק כמו stakeQuestionCounts
//    ב-duel_service.dart).
//  - כל לוגו מוצג כשהוא כמעט לגמרי מכוסה במסך שחור, שנחשף בהדרגה
//    *מהמרכז כלפי חוץ* (עיגול שגדל, לא וילון שנסוג הצידה) על פני
//    revealDurationSeconds שניות - אם אף אחד לא ניחש עד אז, הלוגו נחשף
//    לגמרי והסיבוב מסתיים בלי ניקוד לאף אחד.
//  - יש "צ'אט" חי בין שני השחקנים - כל ניחוש *שלם* שכל שחקן מקליד
//    (באמצעות אותו מנגנון תאי-אות+מקלדת הקיים בכל שאר המשחק, לא הקלדה
//    חופשית - ראו logo_race_screen.dart) מתפרסם לשני הצדדים כמו הודעה,
//    נכון או לא נכון. מי שמקליד ראשון את השם הנכון מזכה את עצמו בנקודה
//    על הסיבוב, ועוברים יחד ללוגו הבא.
//  - בסיום כל הסיבובים - מנצח מי שצבר יותר נקודות (תיקו אפשרי). המנצח
//    לוקח את כל קופת ההימור (פי 2), ומקבל 50 XP קבועים - בדיוק כמו ניצחון
//    בדו-קרב (_winXpReward ב-duel_room_screen.dart). בתיקו כל אחד מקבל
//    בחזרה את ההימור שלו (בלי רווח/הפסד); בהפסד - ההימור פשוט אבד.
//
// עולה 2 אנרגיה (EnergyService.duelCost) - בדיוק כמו דו-קרב. מוחזרת אם
// לא נמצא יריב (searchTimeout) או אם החיפוש בוטל.
//
// מבנה הנתונים ב-Firestore:
//
// logoRaceQueue/{deviceId}
//   username, createdAt, matchId (null עד שנמצא יריב), stake
//
// logoRaces/{raceId}
//   player1Id, player1Name, player2Id, player2Name
//   status         - 'countdown' | 'playing' | 'finished'
//   logoIds        - מזהי לוגו (זהים לשני השחקנים, מתוך gameLevels) - הכמות תלויה ב-stake
//   stake          - רמת ההימור שנבחרה (20/50/100/200)
//   totalStages    - כמות הלוגואים במרוץ הזה (נשמר על המסמך, לא רק מחושב
//                    מ-stake בכל מקום - עקבי גם אם המיפוי ישתנה בעתיד)
//   currentStage   - 0..totalStages-1 - הלוגו שנחשף כרגע
//   stageStartAt   - Server Timestamp - מתי החשיפה של השלב הנוכחי התחילה
//   stageWinner    - {"0": deviceId|'none', "1": ...} - מי ניחש נכון ראשון בכל שלב
//   scores         - {deviceId: מספר סיבובים שניצח}
//   messages       - [{senderId, text, stage, atMs}] - כל הודעות הצ'אט, כולל ניחושים שגויים
//   winnerId       - מתמלא כש-status הופך ל-'finished' (null = תיקו)
//   createdAt      - Server Timestamp
//
// ⚠️ כמו בדו-קרב, בדיקת "מי ניחש נכון" מתבצעת ב-Transaction בצד הלקוח -
// מספיק ל-MVP, עקבי עם רמת האבטחה הקיימת של שאר המשחק.
//
// ⚠️ שאילתת findMatch מסננת גם לפי 'stake' (בדיוק כמו duelQueue) - זה
// אומר ש-Firestore ידרוש אינדקס מורכב על logoRaceQueue (matchId+stake+
// createdAt+__name__), בנוסף לאינדקס הקודם (matchId+createdAt) שכבר
// נוצר. אם תיתקל שוב ב-FAILED_PRECONDITION בלוג - זה בדיוק זה, ויהיה שם
// קישור ישיר ליצירת האינדקס.

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'duel_service.dart' show DuelService; // 🆕 שימוש חוזר ב-pickRandomLogoIds הקיים
import 'energy_service.dart';

enum RaceSearchStatus { matched, noPlayersFound, cancelled, error }

class RaceSearchResult {
  final RaceSearchStatus status;
  final String? raceId;
  final String? errorMessage;
  const RaceSearchResult(this.status, {this.raceId, this.errorMessage});
}

class RaceChatMessage {
  final String senderId;
  final String text;
  final int stage;
  final int atMs;
  const RaceChatMessage({required this.senderId, required this.text, required this.stage, required this.atMs});

  factory RaceChatMessage.fromMap(Map<String, dynamic> m) => RaceChatMessage(
        senderId: m['senderId'] ?? '',
        text: m['text'] ?? '',
        stage: (m['stage'] ?? 0) as int,
        atMs: (m['atMs'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {'senderId': senderId, 'text': text, 'stage': stage, 'atMs': atMs};
}

class LogoRaceMatch {
  final String raceId;
  final String player1Id, player1Name;
  final String player2Id, player2Name;
  final String status;
  final List<int> logoIds;
  final int stake;
  final int totalStages;
  final int currentStage;
  final DateTime? stageStartAt;
  final Map<String, String> stageWinner; // stageIndex (String) -> deviceId | 'none'
  final Map<String, int> scores;
  final List<RaceChatMessage> messages;
  final String? winnerId;

  const LogoRaceMatch({
    required this.raceId,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    required this.status,
    required this.logoIds,
    required this.stake,
    required this.totalStages,
    required this.currentStage,
    required this.stageStartAt,
    required this.stageWinner,
    required this.scores,
    required this.messages,
    required this.winnerId,
  });

  factory LogoRaceMatch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawWinner = (d['stageWinner'] as Map<String, dynamic>?) ?? const {};
    final stake = (d['stake'] ?? LogoRaceService.stakeOptions.first) as int;
    return LogoRaceMatch(
      raceId: doc.id,
      player1Id: d['player1Id'] ?? '',
      player1Name: d['player1Name'] ?? 'שחקן 1',
      player2Id: d['player2Id'] ?? '',
      player2Name: d['player2Name'] ?? 'שחקן 2',
      status: d['status'] ?? 'countdown',
      logoIds: List<int>.from(d['logoIds'] ?? const []),
      stake: stake,
      totalStages: (d['totalStages'] ?? LogoRaceService.stagesForStake(stake)) as int,
      currentStage: (d['currentStage'] ?? 0) as int,
      stageStartAt: (d['stageStartAt'] as Timestamp?)?.toDate(),
      stageWinner: rawWinner.map((k, v) => MapEntry(k, v.toString())),
      scores: Map<String, int>.from(d['scores'] ?? const {}),
      messages: (d['messages'] as List<dynamic>? ?? const [])
          .map((m) => RaceChatMessage.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      winnerId: d['winnerId'] as String?,
    );
  }

  String opponentIdFor(String myId) => myId == player1Id ? player2Id : player1Id;
  String opponentNameFor(String myId) => myId == player1Id ? player2Name : player1Name;
  String nameFor(String deviceId) => deviceId == player1Id ? player1Name : (deviceId == player2Id ? player2Name : deviceId);
  int scoreFor(String deviceId) => scores[deviceId] ?? 0;
  List<RaceChatMessage> messagesForStage(int stage) => messages.where((m) => m.stage == stage).toList();
}

class LogoRaceService {
  // בנאי ציבורי רגיל (לא static utility class) - findMatch/cancelSearch
  // הן מתודות instance שמשתמשות ב-_queueSub/_timeoutTimer, בדיוק כמו
  // DuelService. שאר המתודות static כי הן חסרות state.
  LogoRaceService();

  static final _db = FirebaseFirestore.instance;
  static const _queueCollection = 'logoRaceQueue';
  static const _racesCollection = 'logoRaces';

  // 🆕 רמות הימור - בדיוק כמו דו-קרב, matchmaking מתאים רק בין שחקנים
  // שבחרו באותה רמה בדיוק. ⚠️ שונות במפורש מ-DuelService.stakeOptions
  // ([5,15,50,200]) - זו בקשה מפורשת לרמות 20/50/100/200 במרוץ.
  static const List<int> stakeOptions = [20, 50, 100, 200];

  // 🆕 כל רמת הימור משחקת על כמות שונה של לוגואים - ההימור הזול הוא גם
  // "משחק קצר" וההימור היקר הוא מרוץ ארוך ומשמעותי יותר. גם מענה לבקשה
  // "צריך יותר לוגואים" - כל הרמות עכשיו עם יותר לוגואים מה-5 הקבועים
  // שהיו קודם.
  static const Map<int, int> stakeQuestionCounts = {20: 6, 50: 8, 100: 10, 200: 12};
  static int stagesForStake(int stake) => stakeQuestionCounts[stake] ?? 6;

  // ⚠️ נשאר כברירת מחדל/תאימות לאחור בלבד (למשל לפני שנבחרה רמת הימור) -
  // בפועל כל מרוץ ספציפי משתמש ב-match.totalStages, לא בקבוע הזה.
  static const int stagesCount = 6;

  static const int revealDurationSeconds = 25;
  static const int countdownSeconds = 3;
  static const Duration searchTimeout = Duration(seconds: 25);
  static const Duration staleQueueEntry = Duration(seconds: 30);

  // 🆕 כלכלה: בדיוק כמו דו-קרב - המנצח לוקח את כל הקופה (פי 2 מההימור),
  // בתיקו כל אחד מקבל את ההימור שלו בחזרה, בהפסד ההימור פשוט אבד. XP
  // בסיסי כמו הבקשה המפורשת: ניצחון = 50 XP, תיקו/הפסד = 0 (בדיוק כמו
  // ש-_winXpReward ב-duel_room_screen.dart ניתן רק על ניצחון).
  static const int winXpReward = 50;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;
  Timer? _timeoutTimer;
  // 🆕 ראו ה"סריקה חוזרת" בתוך findMatch למטה - זהה לתיקון ב-DuelService.
  Timer? _rescanTimer;

  /// 🆕 ניקוי הזדמנותי של מרוצים ישנים - אותו רעיון בדיוק כמו
  /// _maybeCleanupOldDuels ב-duel_service.dart (1 מתוך 10 סיכוי).
  static const int oldRaceCleanupDays = 3;
  static Future<void> _maybeCleanupOldRaces() async {
    if (Random().nextInt(10) != 0) return;
    await cleanupOldRacesNow();
  }

  /// 🆕 אותה מחיקה בדיוק, בלי ההגרלה - לקריאה ישירה פעם אחת בכל הפעלת
  /// אפליקציה (ראה main.dart), כדי שהניקוי לא יהיה תלוי רק בזה שיהיו
  /// מספיק חיפושי מרוץ כדי "להתגלגל" ולרוץ בפועל.
  static Future<void> cleanupOldRacesNow() async {
    try {
      final snap = await _db.collection(_racesCollection).where('status', isEqualTo: 'finished').limit(50).get();
      final cutoff = DateTime.now().subtract(const Duration(days: oldRaceCleanupDays));
      final batch = _db.batch();
      var any = false;
      for (final doc in snap.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.isBefore(cutoff)) {
          batch.delete(doc.reference);
          any = true;
        }
      }
      if (any) await batch.commit();
    } catch (_) {}
  }

  /// מחפש/יוצר מרוץ 1 על 1 ברמת ההימור שנבחרה. גובה 2 אנרגיה מיד, ומחזיר
  /// אותה אם לא נמצא יריב (searchTimeout) או אם החיפוש בוטל - בדיוק כמו
  /// DuelService.findMatch. דמי ההימור עצמם (במטבעות) נגבים רק כשבאמת
  /// נמצא יריב (ראו logo_race_screen.dart, בדיוק כמו _payEntryFeeIfNeeded
  /// בדו-קרב) - כדי שאם החיפוש נכשל, לא ניקח מטבעות על כלום.
  Future<RaceSearchResult> findMatch({
    required String deviceId,
    required String username,
    required List<int> allLevelIds,
    required int stake,
  }) async {
    final paid = await EnergyService.spendForDuel();
    if (!paid) return const RaceSearchResult(RaceSearchStatus.error, errorMessage: 'אין מספיק אנרגיה');

    _maybeCleanupOldRaces();
    final completer = Completer<RaceSearchResult>();
    bool finished = false;
    void finish(RaceSearchResult r) {
      if (finished) return;
      finished = true;
      _queueSub?.cancel();
      _timeoutTimer?.cancel();
      _rescanTimer?.cancel();
      if (r.status != RaceSearchStatus.matched) {
        EnergyService.refundSearchEnergy();
      }
      completer.complete(r);
    }

    try {
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(staleQueueEntry));
      final waitingSnap = await _db
          .collection(_queueCollection)
          .where('matchId', isNull: true)
          .where('stake', isEqualTo: stake)
          .where('createdAt', isGreaterThan: cutoff)
          .orderBy('createdAt')
          .limit(5)
          .get();

      final candidate = waitingSnap.docs.where((d) => d.id != deviceId).firstOrNull;

      if (candidate != null) {
        final raceId = await _db.runTransaction<String?>((tx) async {
          final oppRef = _db.collection(_queueCollection).doc(candidate.id);
          final oppSnap = await tx.get(oppRef);
          if (!oppSnap.exists || oppSnap.data()?['matchId'] != null) return null;

          final totalStages = stagesForStake(stake);
          final logoIds = DuelService.pickRandomLogoIds(allLevelIds, count: totalStages);
          final raceRef = _db.collection(_racesCollection).doc();
          tx.set(raceRef, {
            'player1Id': candidate.id,
            'player1Name': oppSnap.data()?['username'] ?? 'שחקן',
            'player2Id': deviceId,
            'player2Name': username,
            'status': 'countdown',
            'logoIds': logoIds,
            'stake': stake,
            'totalStages': totalStages,
            'currentStage': 0,
            'stageStartAt': null,
            'stageWinner': {},
            'scores': {},
            'messages': [],
            'winnerId': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tx.update(oppRef, {'matchId': raceRef.id});
          return raceRef.id;
        });

        if (raceId != null) {
          finish(RaceSearchResult(RaceSearchStatus.matched, raceId: raceId));
          return completer.future;
        }
      }

      final myQueueRef = _db.collection(_queueCollection).doc(deviceId);
      await myQueueRef.set({
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'matchId': null,
        'stake': stake,
      });

      _queueSub = myQueueRef.snapshots().listen((snap) {
        final raceId = snap.data()?['matchId'] as String?;
        if (raceId != null) {
          myQueueRef.delete();
          finish(RaceSearchResult(RaceSearchStatus.matched, raceId: raceId));
        }
      }, onError: (e) {
        finish(RaceSearchResult(RaceSearchStatus.error, errorMessage: e.toString()));
      });

      // 🩹 באג שתוקן (זהה לתיקון ב-DuelService.findMatch): אם שני שחקנים
      // לוחצים "חפש" כמעט באותו רגע, שניהם יכולים לפספס זה את זה בסריקה
      // הראשונית למעלה (השאילתה של כל אחד רצה לפני שהשני הספיק לכתוב את
      // רשומת התור שלו) - ואז שניהם רק *מחכים* פסיבית (queueSub) בלי
      // שאף אחד ינסה לחפש שוב, עד שפג הזמן ושניהם מקבלים noPlayersFound.
      // התיקון: כל כמה שניות בזמן שאנחנו בתור, סורקים מחדש ומנסים לתפוס
      // יריב שממתין - הפעם ב-Transaction שקוראת/כותבת גם את המסמך שלנו
      // וגם את של המועמד יחד, כדי שגם ניסיון תפיסה הדדי כמעט-בו-זמני
      // ייפתר אטומית (רק צד אחד מצליח).
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
          final rescanCandidate = rescanSnap.docs.where((d) => d.id != deviceId).firstOrNull;
          if (rescanCandidate == null) return;

          final rescanRaceId = await _db.runTransaction<String?>((tx) async {
            final myRef = _db.collection(_queueCollection).doc(deviceId);
            final oppRef = _db.collection(_queueCollection).doc(rescanCandidate.id);
            final mySnap = await tx.get(myRef);
            final oppSnap = await tx.get(oppRef);
            if (!mySnap.exists || mySnap.data()?['matchId'] != null) return null;
            if (!oppSnap.exists || oppSnap.data()?['matchId'] != null) return null;

            final totalStages = stagesForStake(stake);
            final logoIds = DuelService.pickRandomLogoIds(allLevelIds, count: totalStages);
            final raceRef = _db.collection(_racesCollection).doc();
            tx.set(raceRef, {
              'player1Id': rescanCandidate.id,
              'player1Name': oppSnap.data()?['username'] ?? 'שחקן',
              'player2Id': deviceId,
              'player2Name': username,
              'status': 'countdown',
              'logoIds': logoIds,
              'stake': stake,
              'totalStages': totalStages,
              'currentStage': 0,
              'stageStartAt': null,
              'stageWinner': {},
              'scores': {},
              'messages': [],
              'winnerId': null,
              'createdAt': FieldValue.serverTimestamp(),
            });
            tx.update(oppRef, {'matchId': raceRef.id});
            tx.update(myRef, {'matchId': raceRef.id});
            return raceRef.id;
          });

          if (rescanRaceId != null) {
            myQueueRef.delete().catchError((_) {});
            finish(RaceSearchResult(RaceSearchStatus.matched, raceId: rescanRaceId));
          }
        } catch (_) {
          // סריקה חוזרת בלבד - לא קריטית, ננסה שוב בפעם הבאה.
        }
      });

      _timeoutTimer = Timer(searchTimeout, () async {
        await myQueueRef.delete().catchError((_) {});
        finish(const RaceSearchResult(RaceSearchStatus.noPlayersFound));
      });
    } catch (e) {
      finish(RaceSearchResult(RaceSearchStatus.error, errorMessage: e.toString()));
    }

    return completer.future;
  }

  Future<void> cancelSearch(String deviceId) async {
    _queueSub?.cancel();
    _timeoutTimer?.cancel();
    _rescanTimer?.cancel(); // 🆕 עוצרים גם את הסריקה החוזרת התקופתית
    await EnergyService.refundSearchEnergy();
    await _db.collection(_queueCollection).doc(deviceId).delete().catchError((_) {});
  }

  static Stream<LogoRaceMatch> watchRace(String raceId) {
    return _db
        .collection(_racesCollection)
        .doc(raceId)
        .snapshots()
        .where((s) => s.exists)
        .map((s) => LogoRaceMatch.fromDoc(s));
  }

  /// מעביר מ-'countdown' ל-'playing' ומתחיל את חשיפת הלוגו הראשון -
  /// בטוח לקרוא משני הלקוחות במקביל (התנאי status=='countdown' ב-Transaction).
  static Future<void> startRaceIfNeeded(String raceId) async {
    final ref = _db.collection(_racesCollection).doc(raceId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final d = snap.data();
        if (d == null || d['status'] != 'countdown') return;
        tx.update(ref, {'status': 'playing', 'currentStage': 0, 'stageStartAt': FieldValue.serverTimestamp()});
      });
    } catch (_) {}
  }

  /// שולח הודעת "צ'אט" (ניחוש שלם - הורכב מתאי-אות+מקלדת במסך, לא הקלדה
  /// חופשית - ראו logo_race_screen.dart) - נשמרת תמיד לתיעוד/הצגה לשני
  /// הצדדים. אם הטקסט תואם את התשובה הנכונה *וזה הניחוש הנכון הראשון
  /// לשלב הזה* - מזכה נקודה ומתקדם לשלב הבא (או מסיים את המרוץ אם זה
  /// היה השלב האחרון), הכל באותו Transaction כדי שלא ייווצר מצב לא עקבי
  /// אם שני השחקנים "כמעט" ניחשו נכון באותו רגע.
  static Future<void> sendGuess({
    required String raceId,
    required int stage,
    required String deviceId,
    required String text,
    required String correctAnswer,
  }) async {
    final ref = _db.collection(_racesCollection).doc(raceId);
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final isCorrect = _normalize(trimmed) == _normalize(correctAnswer);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final d = snap.data();
        if (d == null || d['status'] != 'playing') return;
        if ((d['currentStage'] ?? 0) != stage) return; // כבר עברנו הלאה

        final messages = List<Map<String, dynamic>>.from(
            (d['messages'] as List<dynamic>? ?? const []).map((m) => Map<String, dynamic>.from(m as Map)));
        messages.add({'senderId': deviceId, 'text': trimmed, 'stage': stage, 'atMs': DateTime.now().millisecondsSinceEpoch});
        final update = <String, dynamic>{'messages': messages};

        final stageWinner = Map<String, dynamic>.from(d['stageWinner'] ?? const {});
        final stageKey = stage.toString();
        if (isCorrect && stageWinner[stageKey] == null) {
          stageWinner[stageKey] = deviceId;
          update['stageWinner'] = stageWinner;

          final scores = Map<String, int>.from(d['scores'] ?? const {});
          scores[deviceId] = (scores[deviceId] ?? 0) + 1;
          update['scores'] = scores;

          final totalStages = (d['totalStages'] ?? stagesForStake(d['stake'] ?? stakeOptions.first)) as int;
          _applyStageAdvance(update, stage: stage, totalStages: totalStages, scores: scores, player1Id: d['player1Id'], player2Id: d['player2Id']);
        }

        tx.update(ref, update);
      });
    } catch (_) {}
  }

  /// נקרא ע"י לקוח כלשהו כשזמן החשיפה לשלב נגמר בלי שאף אחד ניחש נכון -
  /// מסמן 'none' כמנצח השלב ומתקדם הלאה, בלי לזכות אף אחד בנקודה.
  static Future<void> forceAdvanceOnTimeout({required String raceId, required int stage}) async {
    final ref = _db.collection(_racesCollection).doc(raceId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final d = snap.data();
        if (d == null || d['status'] != 'playing') return;
        if ((d['currentStage'] ?? 0) != stage) return;

        final stageWinner = Map<String, dynamic>.from(d['stageWinner'] ?? const {});
        final stageKey = stage.toString();
        if (stageWinner[stageKey] != null) return; // מישהו כבר ניחש נכון - ה-Transaction ההוא כבר קידם

        stageWinner[stageKey] = 'none';
        final update = <String, dynamic>{'stageWinner': stageWinner};
        final scores = Map<String, int>.from(d['scores'] ?? const {});
        final totalStages = (d['totalStages'] ?? stagesForStake(d['stake'] ?? stakeOptions.first)) as int;
        _applyStageAdvance(update, stage: stage, totalStages: totalStages, scores: scores, player1Id: d['player1Id'], player2Id: d['player2Id']);
        tx.update(ref, update);
      });
    } catch (_) {}
  }

  static void _applyStageAdvance(
    Map<String, dynamic> update, {
    required int stage,
    required int totalStages,
    required Map<String, int> scores,
    required String player1Id,
    required String player2Id,
  }) {
    final nextStage = stage + 1;
    if (nextStage >= totalStages) {
      update['status'] = 'finished';
      final s1 = scores[player1Id] ?? 0;
      final s2 = scores[player2Id] ?? 0;
      update['winnerId'] = s1 == s2 ? null : (s1 > s2 ? player1Id : player2Id);
    } else {
      update['currentStage'] = nextStage;
      update['stageStartAt'] = FieldValue.serverTimestamp();
    }
  }

  /// שחקן עוזב באמצע - היריב מוכרז מנצח (בדיוק כמו forfeitMatch בדו-קרב).
  //
  // 🩹 באג חמור שתוקן (זהה לזה שהיה ב-DuelService.forfeitMatch): הפונקציה
  // הזו נהגה לעבוד עם get()+update() רגילים בלי Transaction - קריאה
  // וכתיבה לא אטומיות. אם שני הצדדים חוו יחד הפרעת רשת רגעית ופספסו
  // פעימות חיים הדדיות, שניהם יכולים לקרוא ל-forfeitRace כמעט בו-זמנית
  // (כל אחד חושב שהיריב שלו התנתק) - בלי Transaction שני ה-update()
  // יכולים "לדרוס" זה את זה כך ששני הלקוחות רואים אצלם winnerId=עצמם
  // ומציגים ניצחון גם למי שבפועל הפסיד. עכשיו הכל בתוך Transaction אחד -
  // הבדיקה status=='finished' נעשית על הנתונים העדכניים ביותר בשרת, כך
  // שרק קריאה אחת בפועל מצליחה לקבוע מנצח.
  static Future<void> forfeitRace(String raceId, String leavingDeviceId) async {
    final ref = _db.collection(_racesCollection).doc(raceId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final d = snap.data();
        if (d == null || d['status'] == 'finished') return;
        final opponentId = d['player1Id'] == leavingDeviceId ? d['player2Id'] : d['player1Id'];
        tx.update(ref, {'status': 'finished', 'winnerId': opponentId});
      });
    } catch (_) {}
  }

  static String _normalize(String s) => s.trim().replaceAll(' ', '').toLowerCase();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}