// duel_room_screen.dart
//
// חדר הדו-קרב עצמו - כל שחקן מקבל את אותם לוגואים (logoIds, זהים
// לשני הצדדים), אבל **כל אחד רץ על שלו בקצב שלו** - אם אני עונה נכון
// על לוגו, זה מתקדם רק אותי ללוגו הבא, לא את היריב. לכל לוגו יש 30
// שניות: אם עונים נכון בזמן - נספר כתשובה נכונה; אם לא - עוברים
// ללוגו הבא בלי שזה נספר (כדי שדו-קרב לא יתקע לנצח על לוגו שאף אחד לא
// מזהה). 🆕 זה **לא מרוץ**: המשחק לא מסתיים כשמישהו מסיים ראשון - הוא
// מסתיים רק אחרי ששני השחקנים עברו את כל הלוגואים שלהם, וה מנצח נקבע
// לפי מי שצבר יותר תשובות נכונות בסה"כ, גם אם השני "סיים" מהר יותר.
// רואים בזמן אמת פס התקדמות של היריב (כמה לוגואים הוא כבר פתר נכון) -
// זה מה שנותן את התחושה "אונליין", בלי שהתשובות שלו נחשפות.
//
// עיצוב הקלט זהה למצב המשחק הרגיל (logo_level_screen.dart) - כולל
// אפשרות רמז/פתרון מילה תמורת מטבעות, כדי שהמסך ירגיש כמו חלק טבעי
// מהמשחק ולא כמו מסך נפרד ומינימלי.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'share_helper.dart'; // 🐛 שיתוף עם sharePositionOrigin - תוקן כשל שיתוף ב-iOS
import 'duel_service.dart';
import 'duel_lobby_screen.dart';
import 'missions_service.dart';
import 'level_data.dart';
import 'app_background.dart';
import 'audio_manager.dart';
import 'player_sync.dart';
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי
import 'ads_manager.dart'; // 🆕 פרסומת אחרי סיום דו-קרב + איפוס מונה "גלישה בלי לשחק"
import 'level_override_service.dart'; // 🆕 תיקוני שלבים מרחוק - חייב לחול גם בדו-קרב, לא רק במשחק הרגיל
import 'battle_pass_service.dart'; // 🆕 נקודות "באטל פאס" על ניצחון בדו-קרב
import 'app_notification.dart';
import 'not_enough_coins_dialog.dart'; // 🆕 "אין מספיק מטבעות" - עכשיו מקשר ישר לחנות
import 'starter_pack_dialog.dart'; // 🆕 מציג מארז פתיחה ברגע חיכוך אם עדיין זכאי
import 'achievements_service.dart';
import 'active_match_service.dart'; // 🆕 "חזרה למשחק" אחרי שהאפליקציה נסגרה לגמרי

class DuelRoomScreen extends StatefulWidget {
  final String matchId;
  final String myDeviceId;
  final String myUsername;

  const DuelRoomScreen({
    super.key,
    required this.matchId,
    required this.myDeviceId,
    required this.myUsername,
  });

  @override
  State<DuelRoomScreen> createState() => _DuelRoomScreenState();
}

class _DuelRoomScreenState extends State<DuelRoomScreen> with TickerProviderStateMixin {
  StreamSubscription<DuelMatch>? _sub;
  DuelMatch? _match;
  String? _prevStatus;

  // 🆕 כל שחקן מתקדם על הלוגואים שלו בעצמו - זה לא אינדקס משותף מה-
  // שרת אלא מונה מקומי, שרק נשלח החוצה (advanceLogo) בכל פעם שמתקדם.
  // _myProgress = כמה לוגואים "עברו" (כולל כאלה שהזמן נגמר עליהם),
  // _myCorrectCount = כמה מהם נענו נכון בפועל - זה מה שקובע את המנצח.
  int _myProgress = 0;
  int _myCorrectCount = 0;
  // 🆕 טיימר לכל לוגו - אם נגמר בלי תשובה נכונה, עוברים אוטומטית ללוגו
  // הבא בלי שזה נספר. בעבר זה היה קבוע (30 שניות) לכל הרמות - עכשיו
  // תלוי ברמת ההימור (ראו DuelService.stakeLogoTimeoutSeconds): "בזק"
  // (הימור 5) מהיר יותר - רק 15 שניות ללוגו, ליצירת תחושת סיבוב קצבי.
  int get logoTimeoutSeconds => _match != null ? DuelService.logoTimeoutForStake(_match!.stake) : 30;
  int _logoSecondsLeft = 30;
  Timer? _logoTimer;
  bool _showTimeoutFeedback = false;
  List<String?> _guessSlots = [];
  List<int> _typedOrder = [];
  Set<int> _hintedPositions = {};
  // 🆕 עוקבים אחרי איזה מקש-מקלדת (לפי אינדקס) כבר "נלחץ" ובאיזה תא הוא
  // מוצג - כדי שהמקש הזה ייעלם מהמקלדת (בדיוק כמו במסך הרמות הרגיל)
  // עד שמוחקים אותו בחזרה.
  final Set<int> _pressedKeyIndices = {};
  final Map<int, int> _slotToKeyIndex = {};
  bool _isPlayer1 = false;
  bool _countdownStarted = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  bool _initializedGuess = false;
  bool _showCorrectFeedback = false;

  // 🆕 באנר "מישהו ענה נכון" בולט לשני הצדדים - לפי בקשה מפורשת ("שני
  // השחקנים ידעו שמישהו ענה, לא רק וי קטן"). הבאנר "תשובה נכונה!" הקיים
  // (_showCorrectFeedback) מקומי בלבד ומוצג רק אצל מי שממש הקליד את
  // התשובה. כאן עוקבים אחרי ההתקדמות (כמה תשובות נכונות) של היריב -
  // ברגע שהיא עולה, מציגים באנר דומה גם אצלי, עם השם שלו. _prevOppCorrect
  // מתחיל כ-null כדי שלא "יורה" בטעות בעדכון הראשון (לפני שממש היה שינוי).
  int? _prevOppCorrect;
  bool _showOpponentAnsweredBanner = false;
  Timer? _opponentAnsweredBannerTimer;

  // 🆕 זיהוי ניתוק אמיתי של היריב (לא יציאה מבוקרת) - ראו הסבר מלא ליד
  // DuelService.updateHeartbeat/opponentDisconnectTimeoutSeconds. שני
  // הצדדים כותבים "פעימת חיים" כל כמה שניות; אם היריב שלי שותק יותר
  // מ-DuelService.opponentDisconnectTimeoutSeconds שניות בזמן שהמשחק
  // פעיל (status=='playing') - אני זה שמכריז עליי כמנצח, כי הוא כנראה
  // איבד אינטרנט או שהאפליקציה שלו נהרגה בלי ש-dispose() הספיק לרוץ.
  Timer? _heartbeatTimer;
  Timer? _disconnectCheckTimer;
  DateTime? _oppLastSeenLocalClock;
  DateTime? _oppLastSeenServerValuePrev;
  bool _disconnectForfeitTriggered = false;

  int _coins = 0;
  bool _coinsLoaded = false;
  bool _entryFeePaid = false;
  // 🆕 סכום ההימור בפועל של המשחק הזה (15/50/200) - נלקח מה-match ולא
  // מקבוע קבוע, כי מאז שיש כמה רמות הימור צריך לדעת בדיוק על מה שיחקו.
  int _stake = DuelService.stakeOptions.first;
  // 🆕 אם היציאה כבר טופלה (נסגר עם אישור/נענש) - כדי ש-dispose() לא
  // ידווח שוב על אותה עזיבה (זה היה מכפיל אזהרות בטעות).
  bool _exitHandled = false;
  // 🐛 תיקון: מונע פתיחת כמה דיאלוגי "לצאת מהדו-קרב?" זה על גבי זה אם
  // לוחצים כמה פעמים מהר על "אחורה"/X - בלי זה, לחיצה כפולה יכלה לגרום
  // ללחיצה בטעות על "צא בכל זאת" בדיאלוג שנפתח בשוגג בשכבה נסתרת, ולרשום
  // עזיבה/קנס גם למי שבכלל לא התכוון לצאת.
  bool _exitDialogShowing = false;

  // 🆕 "שחק שוב מול אותו יריב" - ראו DuelService.requestRematch. ברגע
  // שהמזהה של הדו-קרב החדש מופיע על המשחק הישן (rematchMatchId) -
  // עוברים אליו ישירות, אצל שני השחקנים, בלי צורך בשום פעולה נוספת.
  bool _rematchNavigated = false;
  // 🆕 "סדרת דו-קרב (הטוב מ-3)" - ראו _maybeContinueSeries/_showSeriesRoundResultDialog.
  bool _seriesContinueTriggered = false;
  bool _seriesBonusGranted = false;

  late final AnimationController _waitingSpinController;

  // 🆕 יריב-בוט (ראו DuelService.botFallbackEnabled) - הלקוח שלי "מנגן"
  // בשם הבוט: מדווח התקדמות בהשהיות אקראיות. בלי פעימות חיים (וגם לא
  // מכריזים עליו כמנותק), בלי סטטיסטיקות ובלי רימאץ'.
  Timer? _botTimer;
  bool _botStarted = false;
  final Random _botRandom = Random();
  // 🩹 תוקן: "הבוטים חלשים מדי, נורא קל לנצח אותם" - קודם דיוק קבוע
  // 65% לכל הבוטים תמיד, ללא שום שונות. עכשיו כמו במרוץ (logo_race_screen.dart) -
  // רמת מיומנות אקראית לכל דו-קרב, ובאופן כללי מעט חזקה יותר בממוצע.
  late final double _botSkill = _botRandom.nextDouble();
  double get _botAccuracy => 0.45 + _botSkill * 0.5; // 45%-95%, ממוצע ~70% (היה קבוע 65%)
  double get _botSpeedMul => 1.25 - _botSkill * 0.7; // מכפיל זמן: 1.25x איטי .. 0.55x מהיר
  bool _isBotMatch(DuelMatch m) => DuelService.isBotId(m.opponentIdFor(widget.myDeviceId));

  // 🐛 תוקן: דווח שהבוט "נתקע" באמצע סיבוב (הפסיק להתקדם) בלי שום סיבה
  // נראית לעין - במקום שהמשחק יישאר תקוע בלי שום דרך להתאושש, שומרים
  // עכשיו "שומר" תקופתי (_botWatchdog) שבודק כל 5 שניות אם היה אמור להיות
  // טיימר בוט פעיל כרגע (המשחק playing, זה משחק מול בוט, הבוט עוד לא
  // סיים) אבל אין - ואם כן, מתזמן אותו מחדש. זו רשת ביטחון שמגבילה כל
  // "תקיעה" עתידית לכמה שניות במקום שתישאר לצמיתות, גם אם הסיבה המדויקת
  // (למשל הפרעת רשת חד-פעמית שגרמה ל-Timer לא להירשם) לא ידועה בוודאות.
  Timer? _botWatchdog;

  void _startBotIfNeeded(DuelMatch match) {
    if (!_isBotMatch(match) || match.status == 'finished') return;
    _botWatchdog ??= Timer.periodic(const Duration(seconds: 5), (_) => _watchdogCheckBot());
    if (_botStarted || match.status != 'playing') return;
    _botStarted = true;
    _scheduleBotStep();
  }

  void _watchdogCheckBot() {
    final match = _match;
    if (!mounted || match == null || match.status != 'playing' || !_isBotMatch(match)) return;
    final botIsP1 = match.player1Id != widget.myDeviceId;
    final done = botIsP1 ? match.player1Progress : match.player2Progress;
    if (done >= match.totalQuestions) return; // הבוט כבר סיים את כל הלוגואים שלו - אין למה לחכות
    if (_botTimer == null || !_botTimer!.isActive) {
      debugPrint('BOT WATCHDOG: no active bot timer while match is playing - rescheduling');
      _scheduleBotStep();
    }
  }

  void _scheduleBotStep() {
    _botTimer?.cancel(); // 🩹 מונע שני טיימרי-בוט פעילים בו-זמנית אם נקרא פעמיים ברצף
    final match = _match;
    if (!mounted || match == null || match.status == 'finished') return;
    final botIsP1 = match.player1Id != widget.myDeviceId;
    final done = botIsP1 ? match.player1Progress : match.player2Progress;
    if (done >= match.totalQuestions) return;
    final timeout = DuelService.logoTimeoutForStake(match.stake);
    // דיוק ומהירות לפי רמת המיומנות שהוגרלה לדו-קרב הזה (ראו _botSkill) -
    // תשובה נכונה לוקחת 20%-65% מהזמן (מוכפל במהירות הבוט).
    // 🩹 תוקן: טעות הייתה לוקחת את מלוא ה-timeout (עד 30 שניות) - עם בוט
    // חלש (דיוק נמוך) וכמה שאלות ברצף שהוא טועה בהן, הזמן המצטבר שהשחקן
    // האמיתי (שכבר סיים את התור שלו) מחכה לבוט תפח לדקות שלמות ("מוגזם
    // ומגוחך", 3+ דקות דווח בפועל) - בעיקר בהימורים הגדולים (30s timeout
    // × עד 12 שאלות). עכשיו גם טעות לוקחת זמן קצוב וקצר (6-12 שניות,
    // מוכפל במהירות הבוט) - עדיין "לוקח לו יותר זמן כשהוא טועה" מבחינת
    // התחושה, אבל לא תלוי ב-timeout המלא של ההימור.
    final correct = _botRandom.nextDouble() < _botAccuracy;
    final seconds = correct
        ? (timeout * (0.2 + _botRandom.nextDouble() * 0.45) * _botSpeedMul).clamp(2.0, timeout - 1)
        : (6.0 + _botRandom.nextDouble() * 6.0) * _botSpeedMul;
    _botTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () async {
      // 🩹 קוראים מחדש את ההתקדמות העדכנית ביותר (לא סומכים על `done`
      // שנתפס למעלה - אם הגיע ביניים עדכון אחר, זה היה עלול לגרום
      // ל-advanceLogo להיכשל בשקט על "עדכון מיושן" ולא להתקדם בכלל).
      final m = _match;
      if (!mounted || m == null || m.status == 'finished') return;
      final freshDone = botIsP1 ? m.player1Progress : m.player2Progress;
      try {
        await DuelService.advanceLogo(
          matchId: widget.matchId,
          isPlayer1: botIsP1,
          newProgress: freshDone + 1,
          gotItRight: correct,
        );
      } catch (_) {}
      _scheduleBotStep();
    });
  }

  @override
  void initState() {
    super.initState();
    _waitingSpinController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadCoins();
    // 🆕 "חזרה למשחק" - שומר מצביע מקומי שיש דו-קרב פעיל, כדי שאם
    // האפליקציה תיסגר לגמרי ותיפתח מחדש, main.dart יוכל להכניס ישר
    // בחזרה במקום למסך הבית (ראו active_match_service.dart).
    ActiveMatchService.save(type: ActiveMatchType.duel, matchId: widget.matchId);
    _sub = DuelService.watchMatch(widget.matchId).listen(_onMatchUpdate, onError: (_) {});
    // 🆕 recordDuelEntered (לא recordGameEntered הרגיל) - כדי ש-AdsManager
    // ידע גם אם "דפדפנו הרבה ואז לחצנו על דו-קרב" (משפיע על onDuelFinished).
    AdsManager.recordDuelEntered();
    // 🆕 תיקוני שלבים מרחוק - ברקע (כבר נטען כנראה מוקדם יותר בסשן, אבל
    // preload() בטוח לקרוא כמה פעמים). מרעננים את המסך אם התוצאה השתנתה.
    LevelOverrideService.preload().then((_) {
      if (mounted) setState(() {});
    });
  }

  // 🆕 דמי הכניסה (15 מטבעות) כבר "אושרו" בלובי (בדקנו שיש מספיק), אבל
  // בפועל מנוכים רק פה - ברגע שהמשחק *באמת* קרה (countdown/playing) -
  // כדי שאם משהו נכשל בדרך, לא ניקח כסף על כלום.
  Future<void> _payEntryFeeIfNeeded() async {
    if (_entryFeePaid) return;
    _entryFeePaid = true;
    while (!_coinsLoaded) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    setState(() => _coins -= _stake);
    await _saveCoins();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _coins = prefs.getInt('coins') ?? 15;
      _coinsLoaded = true;
    });
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    PlayerSyncService.syncCurrentProgress();
  }

  void _onMatchUpdate(DuelMatch match) {
    if (!mounted) return;
    _isPlayer1 = match.player1Id == widget.myDeviceId;
    _stake = match.stake;
    _startHeartbeatIfNeeded();
    _checkOpponentHeartbeat(match);
    _startBotIfNeeded(match);

    if (_prevStatus == null && match.status == 'countdown') {
      _runCountdownThenStart(match);
    }

    if (!_entryFeePaid && (match.status == 'countdown' || match.status == 'playing')) {
      _payEntryFeeIfNeeded();
    }

    if (!_initializedGuess && match.logoIds.isNotEmpty) {
      _initializedGuess = true;
      _resetGuessForCurrentLogo(match);
    }

    if (match.status == 'finished' && _prevStatus != 'finished') {
      if (match.seriesMode && !match.seriesDecided) {
        _showSeriesRoundResultDialog(match);
        _maybeContinueSeries(match);
      } else {
        _showResultDialog(match);
      }
    }

    // 🆕 שני הצדדים ביקשו "שחק שוב" ודו-קרב חדש נוצר - עוברים אליו ישירות.
    if (!_rematchNavigated && match.rematchMatchId != null) {
      _rematchNavigated = true;
      _goToRematch(match.rematchMatchId!);
    }

    // 🆕 זיהוי "היריב ענה נכון" - ראו הערה ליד _prevOppCorrect למעלה.
    final newOppCorrect = match.opponentCorrectFor(widget.myDeviceId);
    if (_prevOppCorrect != null && newOppCorrect > _prevOppCorrect!) {
      _flashOpponentAnsweredBanner();
    }
    _prevOppCorrect = newOppCorrect;

    _prevStatus = match.status;
    setState(() => _match = match);
  }

  void _flashOpponentAnsweredBanner() {
    _opponentAnsweredBannerTimer?.cancel();
    setState(() => _showOpponentAnsweredBanner = true);
    _opponentAnsweredBannerTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showOpponentAnsweredBanner = false);
    });
  }

  // 🆕 אותו מאגר לוגואים בדיוק כמו בלובי (לפי רמת ההימור) - ראו
  // duel_lobby_screen.dart. משותף בין כפתור "שחק שוב" הרגיל ובין המשך
  // אוטומטי של סדרת דו-קרב, כדי שרמת הקושי תישאר עקבית בשני המקרים.
  List<int> _levelPoolFor(int stake) {
    final poolIds = logoIdsForWorlds(DuelService.worldsForStake(stake));
    return poolIds.isEmpty ? gameLevels.keys.toList() : poolIds;
  }

  // 🆕 באנר קליל "ניצחת/הפסדת בסיבוב X" - מוצג באמצע סדרת דו-קרב (לא
  // הוכרעה עדיין), במקום מסך התוצאה המלא עם כפתורי "שחק שוב"/"שיתוף" -
  // הסיבוב הבא מתחיל לבד תוך כמה שניות (ראו _maybeContinueSeries), אין
  // צורך בשום פעולה מהשחקן. נסגר אוטומטית ברגע ש-_goToRematch רץ (הוא
  // תמיד מנסה לסגור דיאלוג פתוח קודם - ראו למטה).
  void _showSeriesRoundResultDialog(DuelMatch match) {
    final iWon = match.winnerId == widget.myDeviceId;
    final isDraw = match.winnerId == null;
    _settleCoinsAfterMatch(iWon: iWon, isDraw: isDraw);
    if (iWon) {
      _grantWinXp(_winXpReward);
      BattlePassService.addPoints(_winBattlePassPoints);
      AchievementsService.inc('duelWins');
    }
    if (iWon) {
      AudioManager.playSuccess('audio/level_complete.mp3');
    } else if (isDraw) {
      AudioManager.playSuccess('audio/win.mp3');
    } else {
      AudioManager.playLose();
    }
    final myWins = match.seriesWinsFor(widget.myDeviceId);
    final oppId = match.opponentIdFor(widget.myDeviceId);
    final oppWins = match.seriesWinsFor(oppId);
    final oppName = widget.myDeviceId == match.player1Id ? match.player2Name : match.player1Name;
    final oppProgress = match.opponentCorrectFor(widget.myDeviceId);
    final myFinalProgress = _myCorrectCount.clamp(0, match.totalQuestions);
    // 🩹 עוצב מחדש - לפי בקשה מפורשת ("שתראה כמו מסך ניצחון"): אותו קונטיינר/
    // אנימציה/כרטיסי פודיום בדיוק כמו _showResultDialog (מסך התוצאה הרגיל),
    // רק עם ניקוד הסדרה במקום זמן, ובלי כפתורי "שחק שוב"/"שיתוף" בתחתית -
    // "עוברים לסיבוב הבא..." במקומם, כי זה קורה אוטומטית (ראו _maybeContinueSeries).
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.55, end: 1.0),
          duration: const Duration(milliseconds: 550),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 340,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF2A1B57), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              border: iWon ? Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.45), width: 1.5) : null,
              boxShadow: iWon
                  ? [
                      BoxShadow(color: const Color(0xFFFFD86B).withValues(alpha: 0.4), blurRadius: 60, spreadRadius: 6),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 12)),
                    ]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFF87171).withValues(alpha: 0.16),
                      border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.4)),
                    ),
                    child: Text('🏆 סיבוב ${match.seriesRound}/3 בסדרה', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
                  if (!iWon) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 92,
                      width: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [Icon(isDraw ? Icons.handshake_rounded : Icons.sentiment_dissatisfied_rounded, color: isDraw ? Colors.white70 : Colors.white54, size: 58)],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else
                    const SizedBox(height: 22),
                  if (iWon)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)]).createShader(bounds),
                      child: const Text("ניצחת בסיבוב!", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    )
                  else
                    Text(isDraw ? "תיקו בסיבוב" : "היריב ניצח בסיבוב", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('הסדרה: $myWins - $oppWins מול $oppName', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  // 🐛 תוקן: הוסרה כאן בכוונה תיבת "הפרס על הסיבוב" (מטבעות/XP)
                  // שהיתה קודם - לפי בקשה מפורשת, כי היא נראתה כאילו הסדרה
                  // כולה הסתיימה ("קיבל 100 מטבעות") בזמן שזה רק ניצחון בסיבוב
                  // בודד מתוך 3. הזיכוי בפועל עדיין קורה (_settleCoinsAfterMatch
                  // למעלה) - רק לא מוצג כאן בבליטות של "פרס סופי".
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _podiumCard(name: widget.myUsername, progress: myFinalProgress, totalQuestions: match.totalQuestions, isWinner: !isDraw && iWon, isDimmed: !isDraw && !iWon, ringColors: const [Color(0xFFFFD86B), Color(0xFFFF9A3C)])),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("VS", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w900))),
                      Expanded(child: _podiumCard(name: oppName, progress: oppProgress, totalQuestions: match.totalQuestions, isWinner: !isDraw && !iWon, isDimmed: !isDraw && iWon, ringColors: const [Color(0xFFFDA4AF), Color(0xFFE11D74)])),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFFFD86B), strokeWidth: 2.4)),
                      const SizedBox(width: 10),
                      Text('עוברים לסיבוב הבא...', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 מריץ את הסיבוב הבא בסדרה אוטומטית (בלי לחכות שהשחקן ילחץ על שום
  // כפתור). מול שחקן אמיתי - מבקש רימאץ' בדיוק כמו הכפתור הרגיל (ברגע
  // ששני הצדדים "ביקשו" - כאן זה קורה אוטומטית משני הצדדים - נוצר משחק
  // חדש ו-_onMatchUpdate הקיים כבר מזהה rematchMatchId ומנווט לבד).
  // מול בוט - אין צד שני אמיתי שיקרא לפונקציה, אז יוצרים ישירות.
  void _maybeContinueSeries(DuelMatch match) {
    if (_seriesContinueTriggered) return;
    _seriesContinueTriggered = true;
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final poolIds = _levelPoolFor(match.stake);
      if (_isBotMatch(match)) {
        await DuelService.createNextSeriesRoundVsBot(oldMatchId: match.matchId, allLevelIds: poolIds);
      } else {
        await DuelService.requestRematch(oldMatchId: match.matchId, myDeviceId: widget.myDeviceId, allLevelIds: poolIds);
      }
      // אם מסיבה כלשהי rematchMatchId עוד לא הגיע דרך ה-listener הרגיל
      // (למשל הפרעת רשת רגעית) - בודקים ישירות פעם אחת נוספת כרשת ביטחון.
      if (!mounted || _rematchNavigated) return;
      final fresh = await DuelService.watchMatch(match.matchId).first.catchError((_) => match);
      if (!mounted || _rematchNavigated) return;
      if (fresh.rematchMatchId != null) {
        _rematchNavigated = true;
        _goToRematch(fresh.rematchMatchId!);
      }
    });
  }

  // 🆕 סוגר כל דיאלוג פתוח (מסך התוצאה) ומחליף את המסך הזה בדו-קרב
  // החדש (pushReplacement, לא push - כדי שכפתור "אחורה" לא יחזיר
  // למסך הדו-קרב הישן/המסתיים).
  void _goToRematch(String newMatchId) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop(); // סוגר את דיאלוג התוצאה אם הוא עדיין פתוח
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DuelRoomScreen(
          matchId: newMatchId,
          myDeviceId: widget.myDeviceId,
          myUsername: widget.myUsername,
        ),
      ),
    );
  }

  // 🆕 מתחיל לשלוח "פעימת חיים" לשרת - פעם אחת מיד ואז כל
  // DuelService.heartbeatIntervalSeconds שניות. נקרא בכל _onMatchUpdate
  // אבל בפועל רץ פעם אחת בלבד הודות לבדיקת _heartbeatTimer != null -
  // ממתין לקריאה הראשונה כי רק אז _isPlayer1 כבר ידוע בוודאות.
  void _startHeartbeatIfNeeded() {
    if (_heartbeatTimer != null) return;
    DuelService.updateHeartbeat(widget.matchId, isPlayer1: _isPlayer1);
    _heartbeatTimer = Timer.periodic(Duration(seconds: DuelService.heartbeatIntervalSeconds), (_) {
      if (_match != null && _match!.status == 'finished') return;
      DuelService.updateHeartbeat(widget.matchId, isPlayer1: _isPlayer1);
    });
  }

  // 🆕 עוקב מתי ראינו לאחרונה עדכון אמיתי (לא אותו ערך ישן) בפעימת
  // החיים של היריב, ומפעיל טיימר מקומי שבודק את זה כל כמה שניות -
  // בכוונה טיימר נפרד ולא רק תגובה ל-snapshot, כי אם היריב פשוט שותק
  // (בלי אינטרנט) לא יגיע שום snapshot חדש שיפעיל בדיקה מחדש.
  void _checkOpponentHeartbeat(DuelMatch match) {
    if (match.status != 'playing') return; // לא בספירה לאחור/לפני שהתחיל/אחרי שנגמר
    if (_isBotMatch(match)) return; // בוט לא שולח פעימות - לא מנותק
    final oppLastSeen = match.opponentLastSeenFor(widget.myDeviceId);
    if (oppLastSeen != null && oppLastSeen != _oppLastSeenServerValuePrev) {
      _oppLastSeenServerValuePrev = oppLastSeen;
      _oppLastSeenLocalClock = DateTime.now();
    }
    // בסיס התחלתי - נותן ליריב "טווח חסד" עד שהוא שולח את הפעימה הראשונה שלו
    _oppLastSeenLocalClock ??= DateTime.now();
    // 🆕 גם מרענן את המסך כל 3 שניות (לא רק בודק ניצחון טכני) - כדי
    // שהספירה לאחור במסך "ממתין לחיבור מחדש" (_buildWaitingForReconnectOverlay)
    // תתקדם בעצמה גם בלי שמגיע עדכון Firestore חדש.
    _disconnectCheckTimer ??= Timer.periodic(const Duration(seconds: 3), (_) async {
      await _maybeForfeitDisconnectedOpponent();
      if (mounted) setState(() {});
    });
  }

  // 🆕 מכריז עליי כמנצח אם היריב שותק יותר מדי זמן בזמן משחק פעיל -
  // בדיוק כמו יציאה מבוקרת (forfeitMatch + applyForfeitPenalty), רק
  // שהפעם *אני* מבצע את הקריאה בשם היריב, כי הוא כנראה לא מסוגל לעשות
  // את זה בעצמו (אין לו אינטרנט, או שהאפליקציה שלו נהרגה).
  Future<void> _maybeForfeitDisconnectedOpponent() async {
    final match = _match;
    if (_disconnectForfeitTriggered || match == null || match.status != 'playing' || _oppLastSeenLocalClock == null) return;
    final silentFor = DateTime.now().difference(_oppLastSeenLocalClock!);
    if (silentFor < Duration(seconds: DuelService.opponentDisconnectTimeoutSeconds)) return;
    _disconnectForfeitTriggered = true;
    final opponentId = match.opponentIdFor(widget.myDeviceId);
    // 🐛 תוקן: applyForfeitPenalty רץ עכשיו רק אם forfeitMatch באמת קבע
    // אותי כמנצח (ראו הערה מפורטת ליד forfeitMatch ב-duel_service.dart) -
    // אם זה החזיר false (היריב כבר הכריע את המשחק לפניי, כלומר בעצם
    // *אני* זה שניתקתי מבחינתו), לא מענישים אותו בטעות על מה שלא קרה.
    final iWon = await DuelService.forfeitMatch(widget.matchId, opponentId);
    // 🆕 ניתוק מוחלט (לא יציאה מבוקרת) - תמיד נספר כאזהרה, לא משנה על
    // איזה לוגו - ראו ההסבר המלא ליד forfeitBanThreshold ב-duel_service.dart.
    if (iWon) await DuelService.applyForfeitPenalty(opponentId, countsAsWarning: true);
  }

  // הספירה לאחור (3..2..1) מוצגת מקומית אצל שני השחקנים בערך באותו זמן
  // (כי שניהם מקבלים את עדכון ה-match כמעט יחד). מי שמסיים ראשון עובר
  // ל-status 'playing' - השני פשוט "יתעדכן" מזה דרך ה-stream כרגיל.
  void _runCountdownThenStart(DuelMatch match) {
    if (_countdownStarted) return;
    _countdownStarted = true;
    // 🩹 בסיבוב המשך בסדרה (round > 1) - היריב כבר "נמצא" (זה אותו יריב
    // מהסיבוב הקודם), אז לפי בקשה מפורשת אין ספירה לאחור 3-2-1 מוצגת -
    // רק המתנה קצרה (טעינת המסך הבא) ואז מתחילים ישר, בלי מספרים.
    if (match.seriesMode && match.seriesRound > 1) {
      Timer(const Duration(milliseconds: 900), () async {
        if (!mounted) return;
        await DuelService.startMatchIfNeeded(widget.matchId);
      });
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      setState(() => _countdownValue--);
      if (_countdownValue <= 0) {
        t.cancel();
        await DuelService.startMatchIfNeeded(widget.matchId);
      }
    });
  }

  // 🆕 מפעיל תיקון אדמין (אם קיים לשלב הזה) מעל הנתונים הקבועים בקוד -
  // זהה בעיקרון ל-logo_level_screen.dart, כדי שתיקון (תשובה/מקלדת) יחול
  // גם בדו-קרב ולא רק במשחק הרגיל. imageUrl מטופל בנפרד בציור התמונה.
  LevelData? _levelWithOverride(int levelId) {
    final base = gameLevels[levelId];
    if (base == null) return null;
    final o = LevelOverrideService.overrideFor(levelId);
    if (o == null) return base;
    final overrideAnswer = o['answer'] as String?;
    final overrideKeyboardRaw = o['keyboard'];
    final overrideKeyboard = overrideKeyboardRaw is List ? overrideKeyboardRaw.map((e) => e.toString()).toList() : null;
    if (overrideAnswer == null && overrideKeyboard == null) return base;
    return LevelData(
      ans: overrideAnswer ?? base.answer,
      imagePath: base.imagePath,
      logoColor: base.logoColor,
      keyboard: overrideKeyboard ?? base.keyboard,
    );
  }

  void _resetGuessForCurrentLogo(DuelMatch match) {
    if (_myProgress >= match.logoIds.length) return;
    final levelId = match.logoIds[_myProgress];
    final level = _levelWithOverride(levelId);
    final answerLen = level?.answer.replaceAll(' ', '').length ?? 0;
    _guessSlots = List<String?>.filled(answerLen, null);
    _typedOrder = [];
    _hintedPositions = {};
    _pressedKeyIndices.clear();
    _slotToKeyIndex.clear();
    _startLogoTimer(); // 🆕 30 שניות חדשות ללוגו הזה
  }

  // 🆕 מתחיל (או מאתחל) את הטיימר של 30 השניות ללוגו הנוכחי. בלי
  // setState עצמאי כאן בכוונה - כל הקריאות לפונקציה הזו כבר קורות
  // בתוך setState של הקורא (או מיד לפני setState נפרד), כך שהערך
  // המאופס מוצג נכון בבנייה הבאה.
  void _startLogoTimer() {
    _logoTimer?.cancel();
    _logoSecondsLeft = logoTimeoutSeconds;
    _logoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_logoSecondsLeft <= 1) {
        t.cancel();
        _handleLogoTimeout();
      } else {
        setState(() => _logoSecondsLeft--);
      }
    });
  }

  // 🆕 נגמר הזמן ללוגו הזה בלי תשובה נכונה - מציגים משוב קצר ("הזמן
  // נגמר!") ואז עוברים ללוגו הבא בלי שזה נספר כהצלחה, בדיוק כמו תשובה
  // נכונה מבחינת ה"מעבר" - רק ש-gotItRight=false.
  Future<void> _handleLogoTimeout() async {
    if (_match == null || _myProgress >= _match!.totalQuestions) return;
    setState(() => _showTimeoutFeedback = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _showTimeoutFeedback = false);
    await _advanceToNextLogo(gotItRight: false);
  }

  // 🆕 מרכז את הלוגיקה המשותפת של "עוברים ללוגו הבא" - בין אם עניתי
  // נכון ובין אם נגמר הזמן. מדווח לשרת תמיד (advanceLogo), אבל רק עדכן
  // את מונה התשובות הנכונות שלי מקומית אם gotItRight.
  Future<void> _advanceToNextLogo({required bool gotItRight}) async {
    final match = _match;
    if (match == null) return;
    _logoTimer?.cancel();
    _myProgress++;
    if (gotItRight) _myCorrectCount++;

    if (!mounted) return;
    if (_myProgress < match.totalQuestions) {
      setState(() => _resetGuessForCurrentLogo(match));
    } else {
      setState(() {}); // מציג את מסך "ממתין ליריב לסיים" אם עוד לא הוכרז מנצח
    }

    // מדווחים לשרת ברקע - לא חוסם את המסך.
    // 🐛 תוקן: הקריאה רצה בלי await/טיפול בשגיאה בכלל - אם היא נכשלת
    // (הפרעת רשת רגעית), השדה progressField בשרת עדיין "מתעדכן" (נקבע,
    // לא נצבר) מהקריאה הבאה, אבל correctField (מונה התשובות הנכונות,
    // כן נצבר ב-+1 בכל קריאה) פשוט מפספס לצמיתות את התשובה הנכונה
    // מהקריאה שנכשלה - למרות שהמסך שלי מציג אותה כתשובה נכונה. זה יכול
    // להפוך תוצאה צמודה, בלי סימן חיצוני לשחקן שנפגע. עכשיו מנסים שוב
    // עד 3 פעמים עם השהיה קצרה בין ניסיונות, ברקע, בלי לחסום את המסך.
    _reportAdvanceWithRetry(newProgress: _myProgress, gotItRight: gotItRight);
  }

  Future<void> _reportAdvanceWithRetry({required int newProgress, required bool gotItRight, int attempt = 0}) async {
    try {
      await DuelService.advanceLogo(
        matchId: widget.matchId,
        isPlayer1: _isPlayer1,
        newProgress: newProgress,
        gotItRight: gotItRight,
      );
    } catch (e) {
      if (attempt >= 2) {
        debugPrint('ADVANCE LOGO FAILED (giving up after ${attempt + 1} attempts): $e');
        return;
      }
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      if (!mounted) return;
      await _reportAdvanceWithRetry(newProgress: newProgress, gotItRight: gotItRight, attempt: attempt + 1);
    }
  }

  // 🆕 תמונת השלב בדו-קרב - תמונת רשת (imageUrl) אם הוגדר תיקון אדמין
  // ללוגו הזה, אחרת תמונת ה-assets המקורית. נופל חזרה ל-assets גם אם
  // תמונת הרשת נכשלת בטעינה (קישור שבור) - בדיוק כמו במשחק הרגיל.
  Widget _buildDuelLevelImage(LevelData level, int levelId) {
    final overrideUrl = LevelOverrideService.overrideFor(levelId)?['imageUrl'] as String?;
    if (overrideUrl == null || overrideUrl.trim().isEmpty) {
      return Image.asset(level.imagePath, fit: BoxFit.contain);
    }
    return Image.network(
      overrideUrl.trim(),
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => Image.asset(level.imagePath, fit: BoxFit.contain),
    );
  }

  LevelData? get _currentLevel {
    final match = _match;
    if (match == null || _myProgress >= match.logoIds.length) return null;
    return _levelWithOverride(match.logoIds[_myProgress]);
  }

  void _onKeyTap(String letter, int keyIndex) {
    if (_match == null || _myProgress >= (_match!.logoIds.length)) return;
    if (_pressedKeyIndices.contains(keyIndex)) return; // המקש הזה כבר "נעלם" - נלחץ קודם
    final nextEmpty = _guessSlots.indexWhere((s) => s == null);
    if (nextEmpty == -1) return;
    setState(() {
      _guessSlots[nextEmpty] = letter;
      _typedOrder.add(nextEmpty);
      _pressedKeyIndices.add(keyIndex);
      _slotToKeyIndex[nextEmpty] = keyIndex;
    });
    if (!_guessSlots.contains(null)) {
      _checkAnswer();
    }
  }

  void _onBackspace() {
    // אותיות שנחשפו ברמז נעולות - לא ניתן למחוק אותן
    if (_typedOrder.isNotEmpty && _hintedPositions.contains(_typedOrder.last)) {
      return;
    }
    if (_typedOrder.isEmpty) return;
    setState(() {
      final lastIndex = _typedOrder.removeLast();
      _guessSlots[lastIndex] = null;
      final keyIndex = _slotToKeyIndex.remove(lastIndex);
      if (keyIndex != null) _pressedKeyIndices.remove(keyIndex);
    });
  }

  // 🐛 תוקן: לחיצה על תא אות ספציפי לא מחקה כלום - כי לא היה שום
  // onTap על התאים בכלל, רק כפתור "הסר אות" גלובלי שתמיד מוחק את
  // האות שהוקלדה אחרונה (_typedOrder.removeLast()) בלי קשר לאיזה תא
  // המשתמש לחץ עליו בפועל. עכשיו, בדיוק כמו ב-logo_level_screen.dart,
  // כל תא מוחק את עצמו באמצעות typedOrder.remove(i) (הסרת הערך הספציפי,
  // לא הסרת האחרון ברשימה).
  void _onTapSlot(int i) {
    if (_guessSlots[i] == null || _hintedPositions.contains(i)) return;
    setState(() {
      _guessSlots[i] = null;
      _typedOrder.remove(i);
      final keyIndex = _slotToKeyIndex.remove(i);
      if (keyIndex != null) _pressedKeyIndices.remove(keyIndex);
    });
  }

  Future<void> _checkAnswer() async {
    final match = _match;
    final level = _currentLevel;
    if (match == null || level == null) return;

    final cleanGuess = _guessSlots.map((s) => s ?? '').join();
    final cleanAnswer = level.answer.replaceAll(' ', '');

    if (cleanGuess != cleanAnswer) {
      // טעות - מרוקנים ומאפשרים ניסיון נוסף (בלי קנס, זה מצב מהיר).
      // אותיות שנחשפו ברמז נשארות במקום - רק האותיות שהוקלדו ידנית נמחקות,
      // וגם המקשים שלהן "חוזרים" למקלדת.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          for (int i = 0; i < _guessSlots.length; i++) {
            if (!_hintedPositions.contains(i)) {
              _guessSlots[i] = null;
              final keyIndex = _slotToKeyIndex.remove(i);
              if (keyIndex != null) _pressedKeyIndices.remove(keyIndex);
            }
          }
          _typedOrder = _typedOrder.where((i) => _hintedPositions.contains(i)).toList();
        });
      });
      return;
    }

    AudioManager.playSuccess('audio/win.mp3');
    _logoTimer?.cancel(); // עניתי נכון - הטיימר של הלוגו הזה כבר לא רלוונטי

    // 🆕 מציגים לרגע "תשובה נכונה! ✅" לפני שממשיכים ללוגו הבא - כדי
    // שיהיה משוב ברור על ההצלחה במקום מעבר פתאומי בלי שום אינדיקציה.
    setState(() => _showCorrectFeedback = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _showCorrectFeedback = false);

    // 🆕 מאפסים את המקלדת/תאים ללוגו הבא (ומתחילים טיימר חדש) ומדווחים
    // לשרת - הכל דרך _advanceToNextLogo המשותפת (ראו גם _handleLogoTimeout).
    await _advanceToNextLogo(gotItRight: true);
  }

  bool get _hintsAllowed => DuelService.hintsAllowedForStake(_stake);

  void _showHintMenu() {
    if (_match == null || _myProgress >= _match!.totalQuestions) return;
    if (!_hintsAllowed) {
      AppNotification.show(context, "רמזים לא זמינים בהימור הזה - זמינים רק מ-100 מטבעות ומעלה", type: AppNotificationType.error);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const Text("בחר רמז", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            _HintOptionTile(
              icon: Icons.font_download_outlined,
              title: "חשוף אות",
              subtitle: "אות אחת נוספת מתגלה מיד",
              price: DuelService.letterHintCostForStake(_stake),
              accent: const Color(0xFFFFB24D),
              onTap: () {
                Navigator.pop(context);
                _revealLetterHint();
              },
            ),
            const SizedBox(height: 12),
            _HintOptionTile(
              icon: Icons.abc_rounded,
              title: "פתור את כל המילה",
              subtitle: "כל האותיות מתגלות בבת אחת",
              price: DuelService.wordHintCostForStake(_stake),
              accent: const Color(0xFF9333EA),
              onTap: () {
                Navigator.pop(context);
                _revealWordHint();
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🐛 תוקן: היה AppNotification חולף בלי אפשרות לקנות - הרגע הזה
  // (בדיוק חסרים לך מטבעות לרמז) הוא רגע רכישה אידיאלי, בדיוק כמו בחלון
  // הרמזים במסך הרמות הרגיל (ראו logo_level_screen.dart) - עכשיו יש
  // דיאלוג עם קישור ישיר לחנות, עם החבילה הנכונה מודגשת. אם יש עדיין
  // הצעת "מארז פתיחה" זכאית שלא הוצגה בכלל - היא מוצגת קודם (ממירה
  // הרבה יותר טוב מרכישת מטבעות בודדת, ובדיוק ברגע שהמשתמש פתוח לזה).
  void _showNotEnoughCoins(int price) async {
    final prefs = await SharedPreferences.getInstance();
    final maxLevel = prefs.getInt('maxLevel') ?? 1;
    if (!mounted) return;
    final shownStarterPack = await StarterPackDialog.maybeShowAtFriction(context, maxLevel: maxLevel);
    if (shownStarterPack) return;
    showNotEnoughCoinsDialog(context, cost: price, coins: _coins, onReturnedFromShop: _loadCoins);
  }

  void _revealLetterHint() {
    final level = _currentLevel;
    if (level == null) return;
    final cost = DuelService.letterHintCostForStake(_stake);
    if (_coins < cost) {
      _showNotEnoughCoins(cost);
      return;
    }
    final emptySlots = <int>[];
    for (int i = 0; i < _guessSlots.length; i++) {
      if (_guessSlots[i] == null) emptySlots.add(i);
    }
    if (emptySlots.isEmpty) return;

    setState(() {
      final answerNoSpaces = level.answer.replaceAll(' ', '');
      final randomSlot = emptySlots[Random().nextInt(emptySlots.length)];
      final revealedLetter = answerNoSpaces[randomSlot];
      _guessSlots[randomSlot] = revealedLetter;
      _hintedPositions.add(randomSlot);
      _typedOrder.add(randomSlot);
      _coins -= cost;
      // גם המקש המתאים במקלדת "נעלם" - כדי שהמקלדת תישאר עקבית עם מה
      // שכבר גלוי בתאים, בדיוק כמו במסך הרמות הרגיל.
      for (int i = 0; i < level.keyboard.length; i++) {
        if (level.keyboard[i] == revealedLetter && !_pressedKeyIndices.contains(i)) {
          _pressedKeyIndices.add(i);
          _slotToKeyIndex[randomSlot] = i;
          break;
        }
      }
    });
    _saveCoins();
    if (!_guessSlots.contains(null)) _checkAnswer();
  }

  void _revealWordHint() {
    final level = _currentLevel;
    if (level == null) return;
    final cost = DuelService.wordHintCostForStake(_stake);
    if (_coins < cost) {
      _showNotEnoughCoins(cost);
      return;
    }
    setState(() {
      final answerNoSpaces = level.answer.replaceAll(' ', '');
      for (int i = 0; i < answerNoSpaces.length; i++) {
        _guessSlots[i] = answerNoSpaces[i];
      }
      _hintedPositions = Set<int>.from(List.generate(answerNoSpaces.length, (i) => i));
      _coins -= cost;

      _pressedKeyIndices.clear();
      _slotToKeyIndex.clear();
      final usedIndices = List<bool>.filled(level.keyboard.length, false);
      for (int c = 0; c < answerNoSpaces.length; c++) {
        final letter = answerNoSpaces[c];
        for (int i = 0; i < level.keyboard.length; i++) {
          if (!usedIndices[i] && level.keyboard[i] == letter) {
            usedIndices[i] = true;
            _pressedKeyIndices.add(i);
            _slotToKeyIndex[c] = i;
            break;
          }
        }
      }
    });
    _saveCoins();
    _checkAnswer();
  }

  static const int _winXpReward = 50;
  // 🩹 תוקן: עד עכשיו ניצחון בדו-קרב זיכה גם נקודות "באטל פאס" בכמות
  // זהה ל-XP הרגיל (50) - פי כמה מכל מקור נקודות אחר (פתרון לוגו ~1-15,
  // משימה יומית 2-4, אתגר יומי 30) - מה שהפך את "לסיים את כל הבאטל פאס"
  // לקל מדי (כמה דו-קרבים מהירים ביום = כל העונה). ה-XP הרגיל (ולוח
  // התוצאה/לידרבורד) לא השתנה - רק הנקודות שמתקדמות את הבאטל פאס.
  static const int _winBattlePassPoints = 10;

  Future<void> _grantSeriesBonus() async {
    while (!_coinsLoaded) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    setState(() => _coins += _seriesWinBonusCoins);
    await _saveCoins();
    // 🆕 לפי בקשה מפורשת ("כל ניצחון נותן גם XP") - עד עכשיו ניצחון
    // הסדרה כולה (לא כל סיבוב בנפרד, שכבר מזכה XP דרך _grantWinXp) נתן
    // רק מטבעות, בלי שום XP נוסף על ההישג המיוחד הזה.
    await _grantWinXp(_seriesWinBonusXp);
  }

  Future<void> _grantWinXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXp = prefs.getInt('xp') ?? 0;
    await prefs.setInt('xp', currentXp + amount);
    PlayerSyncService.syncCurrentProgress();
  }

  // 🆕 המנצח לוקח את כל קופת דמי הכניסה (15 שלי + 15 של היריב = 30) -
  // כבר ניכינו 15 בתחילת המשחק, אז זיכוי של 30 = רווח נטו של 15.
  // אם משום מה יצא תיקו (לא אמור לקרות בעיצוב החדש, אבל ליתר ביטחון) -
  // פשוט מחזירים לי את דמי הכניסה שלי בחזרה, בלי רווח ובלי הפסד.
  Future<void> _settleCoinsAfterMatch({required bool iWon, required bool isDraw}) async {
    while (!_coinsLoaded) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    if (iWon) {
      setState(() => _coins += _stake * 2);
    } else if (isDraw) {
      setState(() => _coins += _stake);
    }
    // אם הפסדתי - לא עושים כלום, ה-_stake כבר ירד בתחילת המשחק.
    await _saveCoins();
    // 🆕 מעדכן משימות יומיות/שבועיות - "שיחקת דו-קרב" תמיד, "ניצחת
    // דו-קרב" רק אם ניצחת. לא מחכים - לא חוסם את מסך התוצאה.
    MissionsService.recordEvent(MissionEvent.duelPlayed);
    if (iWon) MissionsService.recordEvent(MissionEvent.duelWon);
  }

  // 🆕 פורמט "M:SS" לזמן שחלף במשחק - מבוסס על match.questionStartAt
  // (שעון השרת, אותו הדבר אצל שני השחקנים) ולא על שעון המכשיר המקומי,
  // כדי שהתצוגה תהיה מדויקת ועקבית אצל שני הצדדים.
  String _formatElapsed(DuelMatch match) {
    final start = match.questionStartAt;
    if (start == null) return '--:--';
    final seconds = DateTime.now().difference(start).inSeconds.clamp(0, 3599);
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static const int _seriesWinBonusCoins = 40;
  static const int _seriesWinBonusXp = 30; // 🆕 בונוס XP על ניצחון הסדרה כולה (מעבר ל-50 XP שכל סיבוב כבר מזכה)

  void _showResultDialog(DuelMatch match) {
    final iWon = match.winnerId == widget.myDeviceId;
    final isDraw = match.winnerId == null;
    final mySeriesWins = match.seriesWinsFor(widget.myDeviceId);
    final oppSeriesWins = match.seriesWinsFor(match.opponentIdFor(widget.myDeviceId));
    // 🆕 סדרת דו-קרב שהוכרעה עכשיו (מישהו הגיע ל-2 ניצחונות) - בונוס
    // מטבעות חד-פעמי על כל הסדרה, מעבר לזיכוי הרגיל על הסיבוב האחרון.
    final seriesJustWon = match.seriesMode && match.seriesDecided && iWon && !_seriesBonusGranted;
    if (match.seriesMode && match.seriesDecided && !_seriesBonusGranted) {
      _seriesBonusGranted = true;
      if (iWon) _grantSeriesBonus();
    }
    // 🆕 מצב מקומי לכפתור "שחק שוב" - משתנה רגיל שנתפס (captured) ע"י
    // ה-StatefulBuilder בתוך הדיאלוג למטה, לא שדה של המסך כולו: זה
    // מספיק כדי שהכפתור עצמו יתעדכן ("ממתין ל-...⏳") בלי לגעת בשאר
    // ה-State, ומתאפס ממילא בכל פעם שנוצר דיאלוג תוצאה חדש.
    bool rematchRequested = false;
    // 🩹 תוקן: בעבר תוצאת הפסד ניגנה בטעות את 'audio/win.mp3' (אותו
    // סאונד שמנוגן גם בהפסד וגם - במקום אחר באפליקציה - בניצחון רגיל),
    // מה שגרם לצליל "טוב"/נייטרלי להישמע גם כשבאמת הפסדת. עכשיו הפסד
    // אמיתי מנגן צליל ירידה ייעודי (AudioManager.playLose - נוצר
    // בזיכרון, לא תלוי בקובץ חיצוני), ורק ניצחון אמיתי מנגן את צליל
    // הניצחון. תיקו נשאר עם הסאונד הקודם - הוא לא הפסד ולא ניצחון מובהק.
    if (iWon) {
      AudioManager.playSuccess('audio/level_complete.mp3');
    } else if (isDraw) {
      AudioManager.playSuccess('audio/win.mp3');
    } else {
      AudioManager.playLose();
    }

    if (iWon) {
      _grantWinXp(_winXpReward); // לא מחכים לזה - לא צריך לחסום את הדיאלוג
      BattlePassService.addPoints(_winBattlePassPoints); // 🆕 נקודות "באטל פאס" על ניצחון בדו-קרב (הופחת מ-50 - ראו ההערה ליד הקבוע)
      AchievementsService.inc('duelWins'); // 🆕 הישגים
    }
    _settleCoinsAfterMatch(iWon: iWon, isDraw: isDraw);
    if (seriesJustWon) AchievementsService.inc('duelWins'); // בונוס - גם הישג נוסף על ניצחון הסדרה
    // 🆕 סטטיסטיקות "ניצחונות"/"מאזן ראש-בראש" למסך "נמצא יריב" הבא -
    // בטוח לקרוא משני המכשירים בו-זמנית (ראה recordMatchResultOnce).
    if (!_isBotMatch(match)) {
      DuelService.recordMatchResultOnce(
      matchId: match.matchId,
      player1Id: match.player1Id,
      player2Id: match.player2Id,
      winnerId: match.winnerId,
      winnerName: match.winnerId == match.player1Id
          ? match.player1Name
          : (match.winnerId == match.player2Id ? match.player2Name : null),
    );
    }

    final oppName = widget.myDeviceId == match.player1Id ? match.player2Name : match.player1Name;
    // 🆕 בתוצאה הסופית מציגים כמה תשובות *נכונות* היו לכל אחד - לא כמה
    // לוגואים "עברו" (זה תמיד totalQuestions/totalQuestions לשני
    // הצדדים כשהמשחק מסתיים, אז זה לא היה אומר כלום).
    final oppProgress = match.opponentCorrectFor(widget.myDeviceId);
    final myFinalProgress = _myCorrectCount.clamp(0, match.totalQuestions);
    // 🩹 תוקן: "הפרס שלך" הציג רק את הזיכוי של הסיבוב האחרון (ההימור/50
    // XP) בלי בונוס ניצחון הסדרה (40 מטבעות + 30 XP), למרות שהוא כבר
    // ניתן בפועל - נראה כאילו השחקן קיבל פחות ממה שבאמת קיבל.
    final coinDelta = isDraw ? 0 : (iWon ? _stake : -_stake) + (seriesJustWon ? _seriesWinBonusCoins : 0);
    final xpDelta = iWon ? _winXpReward + (seriesJustWon ? _seriesWinBonusXp : 0) : 0;
    final elapsed = _formatElapsed(match);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        // 🆕 כניסה עם "קפיצה" קלה (elastic) במקום שהדיאלוג פשוט "יופיע" -
        // הרגע של ניצחון/סיום מרגיש הרבה יותר מיוחד ככה.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.55, end: 1.0),
          duration: const Duration(milliseconds: 550),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 340,
            // 🩹 תיקון "BOTTOM OVERFLOWED BY 84 PIXELS": על מסכים נמוכים
            // (כמו S9/Note קטנים) כל התוכן של הדיאלוג הזה לא נכנס לגובה
            // המסך הזמין. במקום שהעמודה תגלוש מחוץ לדיאלוג - מגבילים
            // אותה לגובה מקסימלי ומאפשרים גלילה פנימית קלה אם צריך.
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF2A1B57), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              border: iWon ? Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.45), width: 1.5) : null,
              boxShadow: iWon
                  ? [
                      BoxShadow(color: const Color(0xFFFFD86B).withValues(alpha: 0.4), blurRadius: 60, spreadRadius: 6),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 12)),
                    ]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🆕 תג "⚔ דו־קרב · על X 🪙" למעלה - עוגן זהות למסך, בדיוק
                // כמו שאר מסכי הדו-קרב.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFB7185).withValues(alpha: 0.16),
                    border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    match.seriesMode ? '🏆 סדרת דו־קרב · על $_stake מטבעות' : '⚔️ דו־קרב · על $_stake מטבעות',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
                // 🆕 בהתאם לבקשה - בניצחון כבר לא מוצג גביע ולא קונפטי (לא
                // הילה פועמת ולא נקודות צבעוניות) - רק כותרת "ניצחת!" למטה.
                // בתיקו/הפסד עדיין מוצג אייקון (לחיצת יד / פרצוף עצוב).
                if (!iWon) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 92,
                    width: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          isDraw ? Icons.handshake_rounded : Icons.sentiment_dissatisfied_rounded,
                          color: isDraw ? Colors.white70 : Colors.white54,
                          size: 58,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else
                  const SizedBox(height: 22),
                if (iWon)
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)]).createShader(bounds),
                    child: const Text(
                      "ניצחת!",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  )
                else
                  Text(
                    isDraw ? "תיקו!" : "היריב ניצח",
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                // 🆕 לפי בקשה מפורשת - מסך הסיום של סדרת דו-קרב היה נראה
                // זהה לדו-קרב רגיל, בלי שום סימן שזו הייתה סדרה שלמה (עד
                // 3 סיבובים). עכשיו מציג כמה סיבובים כל צד ניצח, לא רק
                // את התוצאה של הסיבוב האחרון.
                if (match.seriesMode) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: Text(
                      isDraw
                          ? 'תיקו בסדרה · $mySeriesWins-$oppSeriesWins'
                          : (iWon ? 'ניצחת את הסדרה $mySeriesWins-$oppSeriesWins' : 'הפסדת את הסדרה $mySeriesWins-$oppSeriesWins'),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '$myFinalProgress מתוך ${match.totalQuestions} לוגואים · $elapsed דקות',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                // 🆕 פודיום - שתי כרטיסיות זו מול זו: של המנצח מוגבהת/מוארת
                // עם כתר מרחף מעליה, ושל המפסיד מעומעמת - ברור מיד מי ניצח.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _podiumCard(
                        name: widget.myUsername,
                        progress: myFinalProgress,
                        totalQuestions: match.totalQuestions,
                        isWinner: !isDraw && iWon,
                        isDimmed: !isDraw && !iWon,
                        ringColors: const [Color(0xFFFFD86B), Color(0xFFFF9A3C)],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text("VS", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w900)),
                    ),
                    Expanded(
                      child: _podiumCard(
                        name: oppName,
                        progress: oppProgress,
                        totalQuestions: match.totalQuestions,
                        isWinner: !isDraw && !iWon,
                        isDimmed: !isDraw && iWon,
                        ringColors: const [Color(0xFFFDA4AF), Color(0xFFE11D74)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 🆕 "הפרס שלך" - שורת 3 סטטיסטיקות אמיתיות (לא בדויות):
                // מטבעות, XP ולוגואים שנפתרו במשחק הזה.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Text('הפרס שלך', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _prizeStat(
                              value: '${coinDelta >= 0 ? '+' : ''}$coinDelta',
                              icon: Icons.monetization_on_rounded,
                              color: coinDelta >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B),
                              label: 'מטבעות',
                            ),
                          ),
                          Expanded(
                            child: _prizeStat(
                              value: '+$xpDelta',
                              icon: Icons.bolt_rounded,
                              color: const Color(0xFFFFD86B),
                              label: 'XP',
                            ),
                          ),
                          Expanded(
                            child: _prizeStat(
                              value: '$myFinalProgress/${match.totalQuestions}',
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF60A5FA),
                              label: 'לוגואים',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 🆕 "שחק שוב מול אותו יריב" - עוקף את הלובי/matchmaking
                // האקראי לגמרי. לוחצים -> מבקשים רימאץ' (DuelService.
                // requestRematch); ברגע שגם היריב מבקש (בין אם לפני
                // ובין אם אחרי) - שני הצדדים עוברים אוטומטית לדו-קרב
                // חדש (ראה _onMatchUpdate/_goToRematch למעלה) בלי שום
                // צורך בקוד/הזמנה - כי שניהם כבר "יחד" באותו מסך תוצאה.
                if (!_isBotMatch(match)) StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFD86B),
                          side: BorderSide(color: const Color(0xFFFFD86B).withValues(alpha: rematchRequested ? 0.25 : 0.55)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: rematchRequested
                            ? null
                            : () {
                                setDialogState(() => rematchRequested = true);
                                // 🆕 אותו מאגר לוגואים בדיוק כמו בלובי (לפי
                                // רמת ההימור - ראה duel_lobby_screen.dart),
                                // כדי שהרימאץ' יישאר עקבי מבחינת קושי.
                                final poolIds = _levelPoolFor(match.stake);
                                DuelService.requestRematch(
                                  oldMatchId: match.matchId,
                                  myDeviceId: widget.myDeviceId,
                                  allLevelIds: poolIds.isEmpty ? gameLevels.keys.toList() : poolIds,
                                );
                              },
                        child: Text(
                          rematchRequested ? 'ממתין ל-$oppName... ⏳' : 'שחק שוב מול $oppName 🔁',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // 🆕 כפתור CTA ראשי (זהוב, מלא) + שורת כפתורים משניים
                // (שיתוף / חזרה לתפריט) - בדיוק כמו במסך העיצוב.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB24D),
                      foregroundColor: const Color(0xFF2A1740),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      // 🆕 טריגר פרסומת "אחרי דו-קרב" - ברגע שיוצאים ממסך התוצאה
                      // (לא בזמן שהדיאלוג מוצג, כדי לא "להתנגש" איתו חזותית).
                      AdsManager.onDuelFinished();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DuelLobbyScreen(username: widget.myUsername)));
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)]),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text('דו-קרב נוסף ⚔️', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final text = iWon
                              ? 'ניצחתי בדו-קרב במשחק "זהה את הלוגו!" 🏆 $myFinalProgress/${match.totalQuestions} לוגואים ב-$elapsed דקות. בואו תנסו לנצח אותי! 🎮'
                              : 'שיחקתי דו-קרב במשחק "זהה את הלוגו!" - בואו תתמודדו איתי! ⚔️';
                          shareText(context, text);
                        },
                        child: const Text('שיתוף', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          // 🆕 טריגר פרסומת "אחרי דו-קרב" - גם כשחוזרים ישר לתפריט.
                          AdsManager.onDuelFinished();
                        },
                        child: const Text('חזרה לתפריט', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // 🆕 כרטיסיית שחקן בפודיום - כתר מרחף (אנימציה) מעל שם המנצח, אווטאר
  // עגול עם טבעת גרדיאנט, ופס התקדמות; כרטיסיית המפסיד מעומעמת (opacity
  // נמוך) וללא כתר - כדי שיהיה ברור מיד מי ניצח בלי לקרוא טקסט.
  Widget _podiumCard({
    required String name,
    required int progress,
    required int totalQuestions,
    required bool isWinner,
    required bool isDimmed,
    required List<Color> ringColors,
  }) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed.substring(0, 1) : '?';
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [ringColors.first.withValues(alpha: isWinner ? 0.18 : 0.07), ringColors.last.withValues(alpha: isWinner ? 0.06 : 0.02)]),
        border: Border.all(color: (isWinner ? const Color(0xFFFFD86B) : Colors.white).withValues(alpha: isWinner ? 0.55 : 0.12), width: isWinner ? 1.6 : 1),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(2.4),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: ringColors)),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF241645)),
              alignment: Alignment.center,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isWinner ? const Color(0xFFFFD86B) : Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('$progress/$totalQuestions', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return Opacity(
      opacity: isDimmed ? 0.5 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (isWinner) const Positioned(top: -22, child: _FloatingCrown()),
          Padding(padding: EdgeInsets.only(top: isWinner ? 14 : 0), child: card),
        ],
      ),
    );
  }

  Widget _prizeStat({required String value, required IconData icon, required Color color, required String label}) {
    return Column(
      children: [
        // 🆕 מטבע = אימוג'י (ראו app_icons.dart) - XP נשאר אייקון וקטורי
        icon == Icons.monetization_on_rounded ? const CoinIcon(size: 18) : Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _countdownTimer?.cancel();
    _logoTimer?.cancel();
    _heartbeatTimer?.cancel();
    _disconnectCheckTimer?.cancel();
    _botTimer?.cancel();
    _botWatchdog?.cancel();
    _opponentAnsweredBannerTimer?.cancel();
    _waitingSpinController.dispose();
    // אם עוזבים באמצע דו-קרב פעיל בלי לעבור דרך _confirmExit (למשל
    // סוגרים את כל האפליקציה) - היריב עדיין מוכרז מנצח אוטומטית וגם
    // נרשם קנס, בדיוק כמו ביציאה "רגילה" דרך כפתור ה-X.
    if (!_exitHandled && _match != null && _match!.status != 'finished') {
      _exitHandled = true;
      DuelService.forfeitMatch(widget.matchId, widget.myDeviceId);
      // 🆕 סגירת האפליקציה/יציאה בלי אישור מפורש - כמו ניתוק, תמיד אזהרה.
      DuelService.applyForfeitPenalty(widget.myDeviceId, countsAsWarning: true);
    }
    // 🆕 dispose תמיד רץ ב"יציאה מנוהלת" (לא כשהתהליך נהרג ישירות על ידי
    // המערכת/המשתמש) - זה בדיוק ההבדל שגורם ל-"חזרה למשחק" לעבוד נכון,
    // ראו active_match_service.dart.
    ActiveMatchService.clear();
    super.dispose();
  }

  // 🆕 יציאה מבוקרת (כפתור X / כפתור חזרה) - אם המשחק עוד לא הוכרע,
  // מזהירים במפורש שהיציאה תיחשב הפסד+קנס לפני שבאמת יוצאים, כדי
  // שהפעולה לא תפתיע (במקום שהעונש "יקפוץ" בלי אזהרה).
  Future<void> _confirmExit() async {
    final match = _match;
    if (match == null || match.status == 'finished') {
      if (mounted) Navigator.pop(context);
      return;
    }

    // 🐛 תיקון: אם כבר יש דיאלוג "לצאת?" פתוח (למשל מלחיצה כפולה מהירה
    // על כפתור האחורה) - לא פותחים עוד אחד מעליו. בלי זה יכלו להיפתח שני
    // דיאלוגים חופפים, ולחיצה על "להישאר" בעליון בפועל הייתה פוגעת
    // בכפתור "צא בכל זאת" של התחתון שמסתתר מתחתיו - וגורמת לקנס בטעות.
    if (_exitDialogShowing) return;
    _exitDialogShowing = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("לצאת מהדו-קרב?", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(
          "אם תצא עכשיו היריב יוכרז מנצח ויקבל את כל הקופה ($_stake שהימרת + $_stake שלו) - המטבעות והאנרגיה שכבר שילמת לא יוחזרו.\n\n"
          "${_myProgress < 2 ? "זו עזיבה מוקדמת - תקבל רק אזהרה" : "עזיבה בשלב הזה נחשבת פרישה"} (${DuelService.forfeitBanThreshold} אזהרות = חסימה זמנית מדו-קרב).",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("להישאר", style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("צא בכל זאת", style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    _exitDialogShowing = false;

    if (confirmed != true || !mounted) return;
    _exitHandled = true;
    // 🆕 יציאה מבוקרת בלוגו הראשון/השני (progress<2, 0-אינדקס) = אזהרה
    // בלבד; מהשלישי ואילך = פרישה, בלי הצטברות אזהרות - ראו ההסבר המלא
    // ליד forfeitBanThreshold ב-duel_service.dart.
    await Future.wait([
      DuelService.forfeitMatch(widget.matchId, widget.myDeviceId),
      DuelService.applyForfeitPenalty(widget.myDeviceId, countsAsWarning: _myProgress < 2),
    ]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    // 🐛 תיקון: זה היה הבאג המרכזי - canPop היה קבוע על false תמיד, גם
    // אחרי שהדו-קרב כבר הסתיים (finished). כתוצאה, בדיאלוג הניצחון/הפסד,
    // הלחיצה השנייה על Navigator.pop (כדי לצאת מהמסך עצמו, אחרי סגירת
    // הדיאלוג) הייתה נחסמת שוב ושוב על ידי ה-PopScope הזה במקום להצליח -
    // מה שגרם למסך "להיתקע" חזרה בתוך הדו-קרב וללחיצה חוזרת על יציאה.
    // עכשיו: ברגע שהמשחק כבר הוכרע (או שאין עדיין נתוני משחק) - מותר
    // לצאת ישירות בלי שום אישור, כי אין כבר מה "להפסיד".
    final canPopNow = match == null || match.status == 'finished';
    return PopScope(
      canPop: canPopNow,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF120C2E),
        body: AppBackground(
          child: SafeArea(
            child: Stack(
              children: [
                match == null || !_coinsLoaded
                    ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                    : (match.status == 'countdown' ? _buildCountdown(match) : _buildGame(match)),
                // 🩹 תוקן: הבאנר "מישהו ענה נכון" היה בעבר חלק מזרימת התוכן
                // (דוחף את שאר המסך למטה כשהוא מופיע/נעלם) - לפי בקשה
                // מפורשת נשאר למעלה, אבל עכשיו צף מעל שאר המסך (לא דוחף
                // כלום) וקופץ פנימה עם אנימציית slide+fade נעימה יותר.
                if (match != null && match.status != 'countdown') _buildOpponentAnsweredOverlay(match),
                // 🆕 "ממתין לחיבור מחדש" - לפי בקשה מפורשת: כשהיריב שותק,
                // לא נשארים בשקט עד שהניצחון הטכני "קופץ" בלי אזהרה - מציגים
                // מסך חוסם עם ספירה לאחור, וגם נותנים לו הזדמנות אמיתית
                // לחזור (אם הפעימה שלו מתחדשת, המסך הזה פשוט נעלם לבד).
                if (match != null && match.status == 'playing') _buildWaitingForReconnectOverlay(match),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingForReconnectOverlay(DuelMatch match) {
    if (_oppLastSeenLocalClock == null || _disconnectForfeitTriggered) return const SizedBox.shrink();
    final silentSeconds = DateTime.now().difference(_oppLastSeenLocalClock!).inSeconds;
    // 🩹 סף חסד קטן (5s) לפני שמראים בכלל - כדי שלא "יהבהב" על כל רווח
    // רגיל בין פעימות חיים (כל 4 שניות) ורעש רשת רגיל.
    const graceSeconds = 5;
    if (silentSeconds < graceSeconds) return const SizedBox.shrink();
    final remaining = (DuelService.opponentDisconnectTimeoutSeconds - silentSeconds).clamp(0, DuelService.opponentDisconnectTimeoutSeconds);
    final oppName = widget.myDeviceId == match.player1Id ? match.player2Name : match.player1Name;
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF120C2E).withValues(alpha: 0.88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 46, height: 46, child: CircularProgressIndicator(color: Color(0xFFFFD86B), strokeWidth: 3)),
              const SizedBox(height: 20),
              Text("ממתין לחיבור מחדש של $oppName", textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                remaining > 0 ? "אם לא יתחבר תוך $remaining שניות, זה ייחשב ניצחון טכני" : "קובעים ניצחון טכני...",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpponentAnsweredOverlay(DuelMatch match) {
    final oppName = widget.myDeviceId == match.player1Id ? match.player2Name : match.player1Name;
    // 🎨 יושב מיד מתחת לפסי ההתקדמות (לא מכסה את הכפתור/הצ'יפ/המטבעות
    // למעלה) וצף מעל שאר המסך - קופץ פנימה עם slide+fade במקום לדחוף תוכן.
    return Positioned(
      left: 16,
      right: 16,
      top: 128,
      child: IgnorePointer(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 280),
          curve: _showOpponentAnsweredBanner ? Curves.easeOutBack : Curves.easeIn,
          offset: _showOpponentAnsweredBanner ? Offset.zero : const Offset(0, -1.4),
          child: AnimatedOpacity(
            opacity: _showOpponentAnsweredBanner ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: _buildOpponentAnsweredBanner(oppName),
          ),
        ),
      ),
    );
  }

  // 🩹 תוקן: "כתוב היריב נמצא בסיבוב הבא, אבל כבר היה יריב" - "היריב
  // נמצא!" מתאים רק לתחילת דו-קרב חדש (matchmaking אמיתי). בהמשך סדרת
  // דו-קרב (סיבוב 2/3) זה כבר אותו יריב בדיוק - מציגים כותרת ניטרלית.
  Widget _buildCountdown(DuelMatch match) {
    final isSeriesContinuation = match.seriesMode && match.seriesRound > 1;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isSeriesContinuation ? "מתכוננים לסיבוב הבא..." : "היריב נמצא!", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          // 🩹 בסיבוב המשך - בלי ספירה 3-2-1 (ראו _runCountdownThenStart),
          // רק מחוון טעינה קטן במקום מספר גדול שאין לו באמת מה לספור.
          if (isSeriesContinuation)
            const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Color(0xFFFFD86B), strokeWidth: 3.5))
          else
            Text(
              _countdownValue > 0 ? '$_countdownValue' : 'קדימה!',
              style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 72, fontWeight: FontWeight.w900),
            ),
        ],
      ),
    );
  }

  Widget _buildGame(DuelMatch match) {
    final level = _currentLevel;
    final oppName = widget.myDeviceId == match.player1Id ? match.player2Name : match.player1Name;
    // 🆕 הפס העליון מציג כמה תשובות *נכונות* יש לכל אחד (לא כמה לוגואים
    // "עברו") - כי זה מה שבאמת קובע מי מנצח עכשיו, לא מי מתקדם מהר יותר.
    final oppCorrect = match.opponentCorrectFor(widget.myDeviceId);
    final iAmWaiting = _myProgress >= match.totalQuestions && match.status != 'finished';
    final isEnglish = level != null && RegExp(r'[a-zA-Z]').hasMatch(level.answer);

    return Column(
      children: [
        _buildHeader(),
        if (match.seriesMode) ...[
          const SizedBox(height: 4),
          _buildSeriesBadge(match),
        ],
        const SizedBox(height: 6),
        _buildProgressHeader(oppName, oppCorrect, match.totalQuestions),
        const SizedBox(height: 14),
        if (iAmWaiting)
          Expanded(child: _buildWaitingForOpponent())
        else if (level != null) ...[
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.85), const Color(0xFFFFD86B).withValues(alpha: 0.35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 34, offset: const Offset(0, 16))],
                ),
                child: Container(
                  width: 170,
                  height: 170,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                  child: _buildDuelLevelImage(level, match.logoIds[_myProgress]),
                ),
              ),
              // 🆕 תג "לוגו X מתוך Y" צף - כדי שברור בכל רגע כמה נשאר
              // עד הסוף, בדיוק כמו בעיצוב שסיפקת.
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF9A3C)]),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Text(
                    'לוגו ${_myProgress + 1} מתוך ${match.totalQuestions}',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Color(0xFF2A1740), fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              // 🆕 באנר "תשובה נכונה!" שצף לרגע מעל הלוגו ברגע שפותרים -
              // משוב ברור לפני שממשיכים אוטומטית ללוגו הבא.
              AnimatedOpacity(
                opacity: _showCorrectFeedback ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFF0D9488).withValues(alpha: 0.92),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 46),
                        SizedBox(height: 8),
                        Text("תשובה נכונה!", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
              // 🆕 באנר "הזמן נגמר!" - מקביל לבאנר ה"תשובה נכונה", מוצג
              // כשעובר הלוגו הזה כי לא הספקת לפתור אותו תוך 30 שניות.
              AnimatedOpacity(
                opacity: _showTimeoutFeedback ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFFB91C1C).withValues(alpha: 0.92),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_off_rounded, color: Colors.white, size: 42),
                        SizedBox(height: 8),
                        Text("הזמן נגמר!", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
              // 🆕 טיימר הספירה לאחור ל-30 שניות של הלוגו הנוכחי - נראה
              // כמו התג "לוגו X מתוך Y" אבל בפינה השנייה (שמאל-עליון),
              // ומחליף צבע לאדום כשנשארו פחות מ-10 שניות כדי להזהיר.
              Positioned(
                top: -10,
                left: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _logoSecondsLeft <= 10 ? const Color(0xFFB91C1C) : Colors.black.withValues(alpha: 0.55),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '$_logoSecondsLeft',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildGuessSlots(level, isEnglish),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionChip(icon: Icons.lightbulb_rounded, label: "רמז", color: _hintsAllowed ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.22), onTap: _showHintMenu),
              const SizedBox(width: 12),
              _ActionChip(icon: Icons.backspace_rounded, label: "הסר אות", color: const Color(0xFFFB7185), onTap: _onBackspace),
            ],
          ),
          const SizedBox(height: 14),
          _buildKeyboard(level, isEnglish),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  // 🆕 מסך "ממתין ליריב" מחודש - טבעת זהובה מסתובבת סביב מדליית ניצחון
  // (הרבה יותר חגיגי מספינר אפור), ופס ההתקדמות החי של היריב מוצג כאן
  // גם כן במרכז, כדי שהמסך לא ירגיש "ריק" בזמן ההמתנה.
  Widget _buildWaitingForOpponent() {
    final match = _match;
    final oppProgress = match != null ? match.opponentProgressFor(widget.myDeviceId) : 0;
    final oppName = match == null ? '' : (widget.myDeviceId == match.player1Id ? match.player2Name : match.player1Name);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _waitingSpinController,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        const Color(0xFFFFD86B).withValues(alpha: 0.05),
                        const Color(0xFFFFD86B).withValues(alpha: 0.9),
                      ]),
                    ),
                  ),
                ),
                Container(
                  width: 122,
                  height: 122,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF241a4f)),
                ),
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD86B), size: 60),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('סיימת את כל ${match?.totalQuestions ?? DuelService.questionsPerDuel} הלוגואים! 🎉', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text("מחכים ש-$oppName יסיים גם...", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 26),
          SizedBox(
            width: 220,
            child: _progressBarChip(oppName, oppProgress, match?.totalQuestions ?? DuelService.questionsPerDuel, const Color(0xFFFF6B6B), const [Color(0xFFFDA4AF), Color(0xFFE11D74)]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          _GlassRoundIconButton(icon: Icons.close_rounded, color: Colors.white, onTap: _confirmExit),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.5)),
                  color: const Color(0xFFFB7185).withValues(alpha: 0.16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚔️', style: TextStyle(color: Color(0xFFFDA4AF), fontSize: 11)),
                    const SizedBox(width: 6),
                    Text('דו־קרב · על $_stake מטבעות', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 15),
                const SizedBox(width: 4),
                Text('$_coins', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 באנר בולט "[שם] ענה/תה נכון!" - זהה בסגנונו לבאנר המקביל במרוץ
  // (ראו _buildRoundResultBanner ב-logo_race_screen.dart), כדי שהתחושה
  // תהיה עקבית: שני הצדדים תמיד יודעים ברגע שמישהו ענה, לא רק מי שענה.
  Widget _buildOpponentAnsweredBanner(String oppName) {
    const color = Color(0xFFFB7185);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFFE11D74), Color(0xFFFB7185)]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$oppName ענה/תה נכון!',
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 "סדרה - סיבוב X/3 · Y-Z" - תג קטן שמופיע רק במשחקי סדרת דו-קרב,
  // כדי שיהיה ברור בכל רגע כמה סיבובים כל צד כבר ניצח.
  Widget _buildSeriesBadge(DuelMatch match) {
    final myWins = match.seriesWinsFor(widget.myDeviceId);
    final oppWins = match.seriesWinsFor(match.opponentIdFor(widget.myDeviceId));
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFF87171).withValues(alpha: 0.16),
          border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.4)),
        ),
        child: Text(
          'סדרה · סיבוב ${match.seriesRound}/3 · $myWins-$oppWins',
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Color(0xFFFECACA), fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(String oppName, int oppCorrect, int totalQuestions) {
    // 🆕 ה"מוביל" נקבע לפי תשובות נכונות (Correct), לא לפי כמה לוגואים
    // כל אחד כבר עבר (Progress) - כי זה מה שבאמת קובע מנצח עכשיו.
    final myCorrect = _myCorrectCount.clamp(0, totalQuestions);
    final diff = myCorrect - oppCorrect;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _progressBarChip(widget.myUsername, myCorrect, totalQuestions, const Color(0xFF4ADE80), const [Color(0xFFFFD86B), Color(0xFFFF9A3C)])),
              const SizedBox(width: 10),
              Expanded(child: _progressBarChip(oppName, oppCorrect, totalQuestions, const Color(0xFFFF6B6B), const [Color(0xFFFDA4AF), Color(0xFFE11D74)])),
            ],
          ),
          // 🆕 אינדיקטור "מי מוביל" קטן - בדיוק כמו בעיצוב שסופק, רק
          // שעכשיו לפי תשובות נכונות ולא לפי קצב התקדמות.
          if (diff != 0) ...[
            const SizedBox(height: 8),
            Text(
              diff > 0
                  ? 'אתה מוביל ב-${diff == 1 ? "תשובה נכונה אחת" : "$diff תשובות נכונות"}'
                  : '$oppName מוביל ב-${-diff == 1 ? "תשובה נכונה אחת" : "${-diff} תשובות נכונות"}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: diff > 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFDA4AF), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 אווטאר עגול קטן (32px) עם האות הראשונה של השם בתוך טבעת גרדיאנט -
  // מוצג ליד כל פס התקדמות, בדיוק כמו בעיצוב שסופק.
  Widget _miniAvatar(String name, List<Color> ringColors) {
    final trimmed = name.trim();
    final letter = trimmed.isNotEmpty ? trimmed.substring(0, 1) : '?';
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: ringColors)),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ringColors[0].withValues(alpha: 0.85), ringColors[1].withValues(alpha: 0.85)])),
        alignment: Alignment.center,
        child: Text(letter, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 13, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _progressBarChip(String name, int progress, int totalQuestions, Color color, List<Color> ringColors) {
    final ratio = (progress / totalQuestions).clamp(0.0, 1.0);
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniAvatar(name, ringColors),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(name, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  Text('$progress/$totalQuestions', style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.1), color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🆕 תאי האות של הניחוש - רוחב דינמי לפי אורך המילה ורוחב המסך בפועל
  // (בדיוק כמו במסך הרמות הרגיל), כדי שמילה ארוכה תמיד תיכנס בשורה אחת
  // ולא "תגלוש" לשורה נוספת.
  Widget _buildGuessSlots(LevelData level, bool isEnglish) {
    final totalLetters = _guessSlots.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        const double margin = 4;
        const double maxTileWidth = 35;
        const double minTileWidth = 18;
        final double idealWidth = totalLetters > 0 ? (constraints.maxWidth - (totalLetters * margin)) / totalLetters : maxTileWidth;
        final double tileWidth = idealWidth.clamp(minTileWidth, maxTileWidth);
        final double tileHeight = tileWidth * (45 / 35);
        final double fontSize = (tileWidth * 0.6).clamp(12.0, 20.0);

        return SizedBox(
          width: double.infinity,
          child: Center(
            child: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalLetters, (i) {
                  final letter = _guessSlots[i];
                  final isHinted = _hintedPositions.contains(i);
                  return GestureDetector(
                    onTap: (letter != null && !isHinted) ? () {
                      AudioManager.playClick();
                      _onTapSlot(i);
                    } : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: tileWidth,
                      height: tileHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isHinted ? Colors.amber.withValues(alpha: 0.12) : (letter != null ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05)),
                        border: Border.all(color: isHinted ? Colors.amber.withValues(alpha: 0.6) : Colors.white54),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(letter ?? '', style: TextStyle(color: isHinted ? Colors.amber : Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800)),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🆕 גם המקלדת ברוחב דינמי (שתי שורות תמיד) + Directionality נכון,
  // אותו תיקון RTL/LTR שהוחל על תאי האות.
  Widget _buildKeyboard(LevelData level, bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double spacing = 7;
          const double maxKeyWidth = 42;
          const double minKeyWidth = 28;
          final int totalKeys = level.keyboard.length;
          final int keysPerRow = (totalKeys / 2).ceil();
          final double idealWidth = (constraints.maxWidth - (keysPerRow - 1) * spacing) / keysPerRow;
          final double keyWidth = idealWidth.clamp(minKeyWidth, maxKeyWidth);
          final double keyHeight = keyWidth * (48 / 42);
          final double fontSize = (keyWidth * 0.48).clamp(14.0, 20.0);

          return Directionality(
            textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: 8,
              children: List.generate(totalKeys, (i) {
                // 🆕 מקש שכבר "נלחץ" (האות שלו כבר בתא כלשהו) - נעלם לגמרי
                // מהמקלדת (בדיוק כמו במסך הרמות הרגיל), במקום להישאר מוצג
                // ולבלבל לגבי אילו אותיות עוד זמינות.
                final isPressed = _pressedKeyIndices.contains(i);
                return Material(
                  color: isPressed ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isPressed ? null : () => _onKeyTap(level.keyboard[i], i),
                    child: Container(
                      width: keyWidth,
                      height: keyHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isPressed ? Colors.transparent : Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        isPressed ? '' : level.keyboard[i],
                        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

// 🆕 הילה זהובה פועמת (מתרחבת/דוהה בלולאה) מאחורי אייקון הגביע בדיאלוג
// הניצחון - כדי שהרגע ירגיש חי ומיוחד ולא סטטי.
// 🆕 כתר מרחף (float) מעל כרטיסיית המנצח בפודיום - תנועה עדינה למעלה/למטה
// בלולאה, בדיוק כמו אנימציית ה-crownFloat בעיצוב המקורי.
class _FloatingCrown extends StatefulWidget {
  const _FloatingCrown();

  @override
  State<_FloatingCrown> createState() => _FloatingCrownState();
}

class _FloatingCrownState extends State<_FloatingCrown> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = -6 * Curves.easeInOut.transform(_controller.value);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: const Text('👑', style: TextStyle(fontSize: 26)),
    );
  }
}

// כפתור זכוכית עגול קטן לכותרת (חזרה/סגירה) - זהה בסגנון לכפתורים
// המקבילים במסך הרמות הרגיל.
class _GlassRoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassRoundIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}

// שבב פעולה תחתון (רמז / הסר אות) - זהה בסגנון לשבבים המקבילים במסך
// הרמות הרגיל.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.05)]),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

// שורת אפשרות בתפריט הרמזים (בדיוק כמו במסך הרמות הרגיל).
class _HintOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int price;
  final Color accent;
  final VoidCallback onTap;
  const _HintOptionTile({required this.icon, required this.title, required this.subtitle, required this.price, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
            gradient: LinearGradient(colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.04)]),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.55)])),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$price', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 3),
                  const CoinIcon(size: 15),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}