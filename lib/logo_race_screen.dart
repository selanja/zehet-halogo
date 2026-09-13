// logo_race_screen.dart
//
// "מרוץ לוגואים" - 1 מול 1 (ראו logo_race_service.dart להסבר המלא): בוחרים
// רמת הימור (20/50/100/200 מטבעות, בדיוק כמו בדו-קרב), מתמודדים מול יריב
// על כמה לוגואים שתלוי ברמה שנבחרה. כל לוגו מתחיל מכוסה כמעט לגמרי בעיגול
// שחור שנחשף מהמרכז כלפי חוץ (לא וילון מהצד) על פני 25 שניות. מתחת לתמונה
// יש "צ'אט" חי - כל ניחוש *שלם* שכל שחקן מקליד (באמצעות אותו מנגנון
// תאי-אות+מקלדת הקיים בכל המשחק, לא הקלדה חופשית) מתפרסם לשני הצדדים כמו
// הודעה, נכון או לא נכון. מי שמקליד ראשון את השם הנכון מנצח את הסיבוב.
//
// 🆕 מסכי "בוחר הימור"/"מחפש יריב" בנויים באותה שפה חזותית בדיוק כמו
// duel_lobby_screen.dart (עיגולי אווטאר, VS מסתובב, פס התקדמות, טיפים
// מתחלפים, כרטיס "תנאי המרוץ") - כדי שהתחושה תהיה עקבית עם שאר המשחק.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // 🆕 כפתור "שיתוף" במסך התוצאה - בדיוק כמו ב-duel_room_screen.dart
import 'app_background.dart';
import 'level_data.dart';
import 'device_id.dart';
import 'audio_manager.dart';
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי
import 'ads_manager.dart'; // 🆕 זה משחק בפועל - מאפס את מונה "גלישה בלי לשחק"
import 'energy_service.dart';
import 'presence_service.dart'; // 🆕 "כמה אנשים משחקים עכשיו" - פעימת חיים בזמן שהמסך הזה פעיל
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי כל שינוי מטבעות/XP - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון במכשיר אחר (אותו תיקון כמו duel_room_screen.dart)
import 'logo_race_service.dart';
import 'opponent_found_widgets.dart'; // 🆕 מסך "נמצא יריב!" - זהה בדיוק לזה שבדו-קרב (ראו הערה בקובץ)

class LogoRaceScreen extends StatefulWidget {
  final String username;
  // 🆕 הימור שכבר נבחר מראש (ראה main_menu_screen.dart -
  // _showPlayVsPersonFlow, כרטיס "משחק נגד שחקן אחר" המאוחד) - אם קיים
  // ותקין (מופיע ב-LogoRaceService.stakeOptions ויש מספיק מטבעות),
  // מדלגים ישר לחיפוש יריב בלי להציג שוב את בורר ההימור של המסך הזה.
  final int? initialStake;
  const LogoRaceScreen({super.key, required this.username, this.initialStake});

  @override
  State<LogoRaceScreen> createState() => _LogoRaceScreenState();
}

enum _Phase { connecting, noEnergy, noCoins, error, selectingStake, searching, noOpponent, countdown, playing, finished }

// 🆕 טיפים קצרים שמתחלפים בזמן החיפוש - אותו רעיון בדיוק כמו
// _searchingTips ב-duel_lobby_screen.dart, מותאם למרוץ.
const List<String> _raceSearchingTips = [
  "טיפ: הלוגו מתחיל מכוסה כמעט לגמרי - ככל שהעיגול נפתח יותר, קל יותר לנחש",
  "טיפ: מי שמקליד ראשון את התשובה המלאה הנכונה - זוכה בסיבוב",
  "טיפ: אפשר לראות בזמן אמת גם את הניחושים השגויים של היריב בצ'אט",
  "טיפ: המנצח לוקח את כל קופת המטבעות של שני השחקנים",
  "טיפ: ככל שרמת ההימור גבוהה יותר - יש יותר לוגואים במרוץ",
];

class _LogoRaceScreenState extends State<LogoRaceScreen> with TickerProviderStateMixin {
  _Phase _phase = _Phase.connecting;
  final LogoRaceService _service = LogoRaceService();
  String? _raceId;
  String _myDeviceId = '';
  StreamSubscription<LogoRaceMatch>? _raceSub;
  LogoRaceMatch? _race;

  int _coins = 0;
  int _energy = 0;
  bool _coinsLoaded = false;
  int? _selectedStake;
  bool _entryFeePaid = false;
  // 🆕 בורר ההימור עבר להיות bottom sheet אמיתי (showModalBottomSheet)
  // במקום החלפת state מלאה בתוך אותו Scaffold - ראו _openStakeSheet.
  // הדגל הזה מסמן שבפועל נבחרה רמת הימור בתוך הגליון (ולא רק שהגליון
  // נסגר מעצמו בגרירה/הקשה על הרקע), כדי לדעת אם לפרש סגירה של הגליון
  // כ"ביטול" (בדיוק כמו שכפתור "ביטול" הישן עשה) או לא.
  bool _stakeChosen = false;
  // 🩹 קריסה אדומה ("Failed assertion... check that it really is our
  // descendant... is not true") שקרתה "בכניסה למשחק" - אותו באג בדיוק
  // כמו ב-duel_lobby_screen.dart (ראו שם הערה מפורטת): לא קוראים
  // ל-_onStakeSelected ישירות מתוך onTap בגליון (זה גרם ל-setState על
  // מסך שמתחת בזמן שהגליון עדיין באמצע אנימציית סגירה) - רק שומרים את
  // הבחירה כאן וקוראים בפועל רק אחרי שהגליון נסגר לגמרי, ב-_openStakeSheet.
  int? _pendingStake;

  // ספירה לאחור 3-2-1
  Timer? _countdownTicker;
  int _countdownLeft = LogoRaceService.countdownSeconds;
  bool _startRaceCalled = false;

  // שלב נוכחי
  int? _renderedStage;
  List<String?> _guessSlots = [];
  List<int> _typedOrder = [];
  final Set<int> _pressedKeyIndices = {};
  final Map<int, int> _slotToKeyIndex = {};
  bool _showCorrectFeedback = false;
  Timer? _stageTicker;
  double _stageSecondsLeft = LogoRaceService.revealDurationSeconds.toDouble();
  int? _timeoutFiredForStage;
  final ScrollController _chatScroll = ScrollController();

  bool _rewardClaimed = false;
  bool _leftRace = false;
  // 🆕 מסך התוצאה (ניצחון/הפסד) עבר להיות בדיוק כמו בדו-קרב - דיאלוג
  // (showDialog) שקופץ מעל המסך הקפוא האחרון, ולא state נפרד שמחליף
  // את כל גוף המסך. הדגל הזה מוודא שהדיאלוג נפתח פעם אחת בלבד לכל מרוץ.
  bool _resultDialogShown = false;

  // 🆕 טיפ מתחלף + שעון "מחפש… 0:07" חי - בדיוק כמו בדו-קרב.
  Timer? _tipTimer;
  int _tipIndex = 0;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  late final AnimationController _radarController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    AdsManager.recordGameEntered();
    _connect();
  }

  Future<void> _connect() async {
    _myDeviceId = await DeviceId.get();
    if (!mounted) return;
    await _loadCoinsAndEnergy();
    if (!mounted) return;
    if (_energy < EnergyService.duelCost) {
      setState(() => _phase = _Phase.noEnergy);
      return;
    }
    if (_coins < LogoRaceService.stakeOptions.first) {
      setState(() => _phase = _Phase.noCoins);
      return;
    }
    // 🆕 אם הגענו לפה עם הימור שכבר נבחר מראש (מהזרימה המאוחדת "משחק
    // נגד שחקן אחר" במסך הבית) - מדלגים ישר לחיפוש בלי להציג שוב את
    // בורר ההימור. בודקים תקינות (קיים ברשימת ההימורים של המרוץ, ויש
    // מספיק מטבעות) לפני שסומכים עליו - אחרת נופלים חזרה לבורר הרגיל.
    final preselected = widget.initialStake;
    if (preselected != null && LogoRaceService.stakeOptions.contains(preselected) && _coins >= preselected) {
      await _onStakeSelected(preselected);
      return;
    }
    setState(() => _phase = _Phase.selectingStake);
    // 🆕 בורר ההימור עולה כגליון תחתון (bottom sheet אמיתי) שנפתח מעל
    // המסך הנוכחי, ולא כהחלפת state מלאה בתוך אותו Scaffold - כדי שזה
    // יראה ויתנהג כמו bottom sheet אמיתי (רקע מטושטש/מוכהה של המסך
    // הקודם מאחור, החלקה מלמטה כלפי מעלה) - בדיוק כמו שהתבקש, ואותו דבר
    // בדיוק כמו ב-duel_lobby_screen.dart.
    _openStakeSheet();
  }

  // 🆕 פותח את בורר ההימור כ-bottom sheet אמיתי (showModalBottomSheet)
  // במקום להציג אותו inline בתוך גוף המסך - כך יש רקע כהה מטושטש עם
  // המסך הקודם מוצג (ומוכהה) מאחורי הגליון, והגליון עצמו מחליק פנימה
  // מלמטה עם אנימציה סטנדרטית, בדיוק כמו bottom sheet אמיתי. אם הגליון
  // נסגר בלי שנבחרה בפועל רמת הימור (גרירה למטה/הקשה על הרקע הכהה) -
  // מתפרש בדיוק כמו שכפתור "ביטול" הישן התנהג: חוזרים אחורה מהמסך.
  Future<void> _openStakeSheet() async {
    _stakeChosen = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (sheetContext) => _buildStakeSheet(sheetContext),
    );
    if (!mounted) return;
    if (_stakeChosen && _pendingStake != null) {
      // 🩹 רק עכשיו, אחרי שהגליון נסגר לגמרי בפועל - ראו הערה מפורטת
      // ליד _pendingStake למעלה.
      await _onStakeSelected(_pendingStake!);
    } else if (!_stakeChosen) {
      Navigator.pop(context);
    }
  }

  Future<void> _loadCoinsAndEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    final energy = await EnergyService.getCurrentEnergy();
    if (!mounted) return;
    setState(() {
      _coins = prefs.getInt('coins') ?? 15;
      _energy = energy;
      _coinsLoaded = true;
    });
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה מטבעות שהרוויחו/הפסידו במרוץ לא מסתנכרנים לחשבון Google/Apple מקושר
  }

  // 🆕 נבחרה רמת הימור - מתחילים לחפש יריב. האנרגיה נצרכת בתוך
  // service.findMatch; דמי ההימור עצמם (מטבעות) נגבים רק כש-*באמת* נמצא
  // יריב (ראו _payEntryFeeIfNeeded), בדיוק כמו בדו-קרב.
  Future<void> _onStakeSelected(int stake) async {
    if (_coins < stake) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("חסרים לך מטבעות לרמה הזו (יש לך $_coins)", textDirection: TextDirection.rtl)),
      );
      return;
    }
    _selectedStake = stake;
    await _startSearch(stake);
  }

  Future<void> _startSearch(int stake) async {
    setState(() {
      _phase = _Phase.searching;
      _elapsedSeconds = 0;
    });
    // 🆕 "כמה אנשים משחקים עכשיו במרוץ" - ראו presence_service.dart.
    // מתחיל ברגע שנכנסים בפועל לחיפוש/משחק, נעצר ב-dispose.
    PresenceService.startHeartbeat(_myDeviceId, 'race');
    _startTipRotation();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });

    final allLevelIds = gameLevels.keys.toList();
    final result = await _service.findMatch(deviceId: _myDeviceId, username: widget.username, allLevelIds: allLevelIds, stake: stake);
    if (!mounted) return;
    _tipTimer?.cancel();
    _elapsedTimer?.cancel();

    switch (result.status) {
      case RaceSearchStatus.matched:
        _raceId = result.raceId;
        _raceSub = LogoRaceService.watchRace(_raceId!).listen(_onRaceUpdate);
        break;
      case RaceSearchStatus.noPlayersFound:
        setState(() => _phase = _Phase.noOpponent);
        break;
      case RaceSearchStatus.cancelled:
        break;
      case RaceSearchStatus.error:
        setState(() => _phase = result.errorMessage == 'אין מספיק אנרגיה' ? _Phase.noEnergy : _Phase.error);
        break;
    }
  }

  void _startTipRotation() {
    _tipTimer?.cancel();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _raceSearchingTips.length);
    });
  }

  void _onRaceUpdate(LogoRaceMatch race) {
    if (!mounted) return;
    setState(() => _race = race);

    if (!_entryFeePaid && (race.status == 'countdown' || race.status == 'playing')) {
      _payEntryFeeIfNeeded(race.stake);
    }

    switch (race.status) {
      case 'countdown':
        if (_phase != _Phase.countdown && _phase != _Phase.playing) {
          setState(() => _phase = _Phase.countdown);
          _startLocalCountdown();
        }
        break;
      case 'playing':
        if (_phase != _Phase.playing) setState(() => _phase = _Phase.playing);
        _syncStage(race);
        break;
      case 'finished':
        _stageTicker?.cancel();
        setState(() => _phase = _Phase.finished);
        _claimRewardOnce(race);
        // 🆕 מסך התוצאה מוצג כדיאלוג (showDialog) מעל המסך הקפוא האחרון -
        // בדיוק כמו ב-duel_room_screen.dart (_showResultDialog) - ולא
        // כהחלפת state מלאה בתוך גוף המסך. ראה _showRaceResultDialog.
        if (!_resultDialogShown) {
          _resultDialogShown = true;
          _showRaceResultDialog(race);
        }
        break;
    }
  }

  // 🆕 דמי ההימור (מטבעות) כבר "אושרו" בבחירת הרמה (בדקנו שיש מספיק), אבל
  // בפועל מנוכים רק פה - ברגע שהמרוץ *באמת* קרה (countdown/playing) -
  // בדיוק כמו _payEntryFeeIfNeeded ב-duel_room_screen.dart.
  Future<void> _payEntryFeeIfNeeded(int stake) async {
    if (_entryFeePaid) return;
    _entryFeePaid = true;
    while (!_coinsLoaded) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    setState(() => _coins -= stake);
    await _saveCoins();
  }

  void _startLocalCountdown() {
    _countdownLeft = LogoRaceService.countdownSeconds;
    _countdownTicker?.cancel();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdownLeft--);
      if (_countdownLeft <= 0) {
        _countdownTicker?.cancel();
        if (!_startRaceCalled) {
          _startRaceCalled = true;
          LogoRaceService.startRaceIfNeeded(_raceId!);
        }
      }
    });
  }

  void _syncStage(LogoRaceMatch race) {
    if (_renderedStage == race.currentStage) return;
    _renderedStage = race.currentStage;
    _timeoutFiredForStage = null;
    _resetGuessForStage(race);
    _startStageTicker(race);
  }

  LevelData? _levelForStage(LogoRaceMatch race, int stage) {
    if (stage < 0 || stage >= race.logoIds.length) return null;
    return gameLevels[race.logoIds[stage]];
  }

  void _resetGuessForStage(LogoRaceMatch race) {
    final level = _levelForStage(race, race.currentStage);
    final answerLen = level?.answer.replaceAll(' ', '').length ?? 0;
    setState(() {
      _guessSlots = List<String?>.filled(answerLen, null);
      _typedOrder = [];
      _pressedKeyIndices.clear();
      _slotToKeyIndex.clear();
    });
  }

  // 🩹 תוקן: "הבזק לוגו בלי כיסוי שחור לרגע" בכל מעבר בין לוגואים -
  // _stageSecondsLeft נשאר עם הערך השייר מהשלב הקודם (קרוב לאפס = כמעט
  // הכל חשוף) עד לטיק הראשון של הטיימר התקופתי, שרץ רק אחרי 100
  // מילישניות. בינתיים התמונה כבר הוחלפה ללוגו החדש (דרך _renderedStage/
  // level ב-_buildPlaying) אבל blackFraction עדיין מחושב לפי הערך הישן,
  // כך שהעיגול השחור שמכסה את הלוגו כמעט לא קיים לרגע - בדיוק ה"הבזק"
  // שדווח. הפתרון: מחשבים ומעדכנים את _stageSecondsLeft *מיידית וסינכרונית*
  // (tick() נקרא פעם אחת ישירות, לא רק דרך הטיימר) לפני שהטיימר התקופתי
  // בכלל מתחיל לרוץ - כך הכיסוי השחור המלא (או כמעט מלא) כבר מצויר
  // באותו frame בדיוק שבו הלוגו החדש מוצג, בלי שום רגע ביניים חשוף.
  void _startStageTicker(LogoRaceMatch race) {
    _stageTicker?.cancel();
    final startAt = race.stageStartAt ?? DateTime.now();
    void tick() {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(startAt).inMilliseconds / 1000.0;
      final remaining = (LogoRaceService.revealDurationSeconds - elapsed).clamp(0.0, LogoRaceService.revealDurationSeconds.toDouble());
      setState(() => _stageSecondsLeft = remaining);
      if (remaining <= 0 && _timeoutFiredForStage != race.currentStage) {
        _timeoutFiredForStage = race.currentStage;
        LogoRaceService.forceAdvanceOnTimeout(raceId: _raceId!, stage: race.currentStage);
      }
    }

    tick();
    _stageTicker = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
  }

  bool get _roundDecided => _race != null && _race!.stageWinner.containsKey(_race!.currentStage.toString());

  void _onKeyTap(String letter, int keyIndex) {
    if (_phase != _Phase.playing || _roundDecided) return;
    if (_pressedKeyIndices.contains(keyIndex)) return;
    final nextEmpty = _guessSlots.indexWhere((s) => s == null);
    if (nextEmpty == -1) return;
    setState(() {
      _guessSlots[nextEmpty] = letter;
      _typedOrder.add(nextEmpty);
      _pressedKeyIndices.add(keyIndex);
      _slotToKeyIndex[nextEmpty] = keyIndex;
    });
    if (!_guessSlots.contains(null)) _submitGuess();
  }

  void _onBackspace() {
    if (_roundDecided || _typedOrder.isEmpty) return;
    setState(() {
      final lastIndex = _typedOrder.removeLast();
      _guessSlots[lastIndex] = null;
      final keyIndex = _slotToKeyIndex.remove(lastIndex);
      if (keyIndex != null) _pressedKeyIndices.remove(keyIndex);
    });
  }

  Future<void> _submitGuess() async {
    final race = _race;
    if (race == null) return;
    final level = _levelForStage(race, race.currentStage);
    if (level == null) return;
    final guess = _guessSlots.map((s) => s ?? '').join();
    final isCorrect = guess.replaceAll(' ', '') == level.answer.replaceAll(' ', '');

    await LogoRaceService.sendGuess(
      raceId: _raceId!,
      stage: race.currentStage,
      deviceId: _myDeviceId,
      text: guess,
      correctAnswer: level.answer,
    );
    if (!mounted) return;

    if (isCorrect) {
      AudioManager.playSuccess('audio/win.mp3');
      setState(() => _showCorrectFeedback = true);
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _showCorrectFeedback = false);
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _roundDecided) return;
      setState(() {
        _guessSlots = List<String?>.filled(_guessSlots.length, null);
        _typedOrder = [];
        _pressedKeyIndices.clear();
        _slotToKeyIndex.clear();
      });
    }
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScroll.hasClients) return;
      _chatScroll.animateTo(_chatScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  // 🆕 המנצח לוקח את כל קופת ההימור (הימור שלי + הימור היריב), בתיקו
  // כל אחד מקבל בחזרה רק את ההימור שלו - בדיוק כמו _settleCoinsAfterMatch
  // ב-duel_room_screen.dart. XP רק על ניצחון (50 קבועים).
  Future<void> _claimRewardOnce(LogoRaceMatch race) async {
    if (_rewardClaimed) return;
    _rewardClaimed = true;
    final iWon = race.winnerId == _myDeviceId;
    final isDraw = race.winnerId == null;
    while (!_coinsLoaded) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    final stake = race.stake;
    if (iWon) {
      setState(() => _coins += stake * 2);
    } else if (isDraw) {
      setState(() => _coins += stake);
    }
    await _saveCoins();
    if (iWon) {
      final prefs = await SharedPreferences.getInstance();
      final xp = prefs.getInt('xp') ?? 0;
      await prefs.setInt('xp', xp + LogoRaceService.winXpReward);
      PlayerSyncService.syncCurrentProgress(); // 🩹 מסנכרן את ה-XP המעודכן (הקריאה בתוך _saveCoins() לעיל רצה לפני שה-XP הזה נכתב)
    }
  }

  void _leaveIfNeeded() {
    if (_leftRace) return;
    _leftRace = true;
    PresenceService.stopHeartbeat();
    if (_phase == _Phase.searching) {
      _service.cancelSearch(_myDeviceId);
    } else if (_raceId != null && (_phase == _Phase.countdown || _phase == _Phase.playing)) {
      LogoRaceService.forfeitRace(_raceId!, _myDeviceId);
    }
  }

  @override
  void dispose() {
    _leaveIfNeeded();
    _raceSub?.cancel();
    _countdownTicker?.cancel();
    _stageTicker?.cancel();
    _tipTimer?.cancel();
    _elapsedTimer?.cancel();
    _radarController.dispose();
    _pulseController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _leaveIfNeeded();
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: switch (_phase) {
              _Phase.connecting => const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3FC))),
              _Phase.noEnergy => _buildMessageScreen(icon: Icons.bolt_rounded, title: 'אין מספיק אנרגיה', subtitle: 'למרוץ נדרשות ${EnergyService.duelCost} אנרגיות מתוך ${EnergyService.maxEnergy}. אנרגיה מתמלאת אוטומטית כל ${EnergyService.regenMinutes} דקות.'),
              _Phase.noCoins => _buildMessageScreen(icon: Icons.monetization_on_rounded, title: 'אין מספיק מטבעות', subtitle: 'דמי כניסה למרוץ: החל מ-${LogoRaceService.stakeOptions.first} מטבעות (יש לך $_coins). המנצח לוקח את כל הקופה!'),
              _Phase.error => _buildMessageScreen(icon: Icons.wifi_off_rounded, title: 'לא הצלחנו להתחבר', subtitle: 'בדוק את החיבור לאינטרנט ונסה שוב'),
              _Phase.noOpponent => _buildMessageScreen(icon: Icons.person_search_rounded, title: 'אין כרגע יריב זמין', subtitle: 'האנרגיה הוחזרה אליך - נסה שוב עוד רגע'),
              // 🆕 בורר ההימור עצמו כבר לא מוצג כאן inline - הוא נפתח
              // כ-bottom sheet מעל המסך (ראו _openStakeSheet). מה שנשאר
              // גלוי כאן ברקע (מטושטש/מוכהה על ידי ה-barrier של הגליון)
              // הוא רק סרגל העליון, בדיוק כמו שרואים מאחורי כל bottom
              // sheet אמיתי.
              _Phase.selectingStake => _buildTopBar(),
              _Phase.searching => _buildSearching(),
              _Phase.countdown => _buildCountdown(),
              _Phase.playing => _buildPlaying(),
              // 🆕 בדיוק כמו duel_room_screen.dart - כשהמרוץ מסתיים, המסך
              // עצמו ממשיך להראות את הרגע האחרון של המשחק (קפוא), ומסך
              // התוצאה מוצג כדיאלוג מעל זה (ראה _showRaceResultDialog),
              // לא כהחלפת state מלאה של גוף המסך.
              _Phase.finished => _buildPlaying(),
            },
          ),
        ),
      ),
    );
  }

  (String, String) get _topBarTexts {
    switch (_phase) {
      case _Phase.searching:
        final stake = _selectedStake;
        final sub = stake == null ? '' : 'מרוץ על $stake מטבעות · ${LogoRaceService.stagesForStake(stake)} לוגואים';
        return ('מחפש יריב', sub);
      case _Phase.selectingStake:
        return ('מרוץ לוגואים 🏁', 'בחר על מה משחקים');
      case _Phase.finished:
        return ('תוצאות המרוץ 🏁', '');
      default:
        return ('מרוץ לוגואים 🏁', '');
    }
  }

  Widget _buildTopBar() {
    final (title, subtitle) = _topBarTexts;
    final showBadge = _phase == _Phase.selectingStake || _phase == _Phase.searching;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.4)),
                color: const Color(0xFF38BDF8).withValues(alpha: 0.13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EnergyIcon(size: 15),
                  const SizedBox(width: 3),
                  Text('$_energy', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 12.5, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  const CoinIcon(size: 14),
                  const SizedBox(width: 3),
                  Text('$_coins', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 12.5, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          else
            _RaceRoundIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          Expanded(
            child: Column(
              children: [
                Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          if (showBadge) _RaceRoundIconButton(icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pop(context)) else const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageScreen({required IconData icon, required String title, required String subtitle}) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFFFB7185), size: 64),
                  const SizedBox(height: 18),
                  Text(title, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13.5)),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0B2233), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('חזרה', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 עיגול אווטאר עם האות הראשונה של השם, בתוך טבעת גרדיאנט - אותו
  // רעיון בדיוק כמו _avatarCircle ב-duel_lobby_screen.dart, בצבעי מרוץ
  // (ציאן/כחול) במקום זהב.
  Widget _avatarCircle(String name, {double size = 60}) {
    final trimmed = name.trim();
    final letter = trimmed.isNotEmpty ? trimmed.substring(0, 1) : '?';
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
        boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), blurRadius: 16)],
      ),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0C2A3D)),
        alignment: Alignment.center,
        child: Text(letter, style: TextStyle(color: Colors.white, fontSize: size * 0.36, fontWeight: FontWeight.w900)),
      ),
    );
  }

  // 🆕 בחירת רמת הימור - 4 אפשרויות (20/50/100/200), כל אחת עם כמות
  // הלוגואים והזכייה הפוטנציאלית. רמה שאין מספיק מטבעות בשבילה מוצגת
  // עמומה (לא נעלמת) - אותו רעיון בדיוק כמו _buildStakePicker בדו-קרב.
  // 🆕 עוצב מחדש כדי לתאום לעיצוב החדש של בורר ההימור בדו-קרב (מסך "05 ·
  // גודל ההימור" - ראה duel_lobby_screen.dart) - אותה מסגרת בדיוק
  // (כותרת "על מה משחקים?" + תת-כותרת, כרטיסי הימור, שורת מידע, קישור
  // "ביטול"), רק בצבעי המרוץ (ציאן/כחול) ובלי שורת "VS" - שם היריב עוד
  // לא נמצא כשבוחרים הימור, בדיוק כמו בדו-קרב.
  // 🆕 תוכן הגליון עצמו (bottom sheet) - אותו תוכן/עיצוב בדיוק כמו
  // שהיה קודם ב-_buildStakePicker (המסך המלא הישן), רק עטוף עכשיו
  // בכרטיס עם פינות עליונות מעוגלות + ידית גרירה, בדיוק כמו bottom
  // sheet אמיתי (ראו _openStakeSheet, ואותו רעיון בדיוק כמו
  // duel_lobby_screen.dart). הכפתור "ביטול" וגרירה למטה/הקשה מחוץ
  // לגליון סוגרים את הגליון עם sheetContext (לא את המסך כולו) - ה"ביטול"
  // בפועל של המסך קורה ב-_openStakeSheet אחרי שהגליון נסגר, אם לא נבחרה
  // רמת הימור.
  Widget _buildStakeSheet(BuildContext sheetContext) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C2A3D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // 🆕 ידית גרירה - הרמז החזותי הסטנדרטי לכך שאפשר לגרור את
              // הגליון למטה כדי לסגור אותו.
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "על מה משחקים?",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                "ההימור נלקח משני השחקנים",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),
              ...LogoRaceService.stakeOptions.map((stake) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _stakeOption(stake, sheetContext),
                  )),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "כל לוגו מוסתר כמעט לגמרי - מי שמנחש נכון ראשון בצ'אט זוכה בסיבוב.",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stakeOption(int stake, BuildContext sheetContext) {
    final canAfford = _coins >= stake;
    final logos = LogoRaceService.stagesForStake(stake);
    final prize = stake * 2;
    final subtitle = '$logos לוגואים · המנצח לוקח $prize';
    final bool isPopular = stake == 50;
    final Color accent = isPopular ? const Color(0xFFFFD86B) : const Color(0xFF38BDF8);
    final Color accentDark = isPopular ? const Color(0xFFFF9A3C) : const Color(0xFF0284C7);

    // 🆕 סוגרים את הגליון (bottom sheet) *לפני* שממשיכים בלוגיקת הבחירה
    // רק אם באמת אפשר להרשות את הרמה הזו - מסמנים שנבחרה רמת הימור
    // בפועל (_stakeChosen) כדי ש-_openStakeSheet לא יפרש את הסגירה הזו
    // כ"ביטול". אם אין מספיק מטבעות - הגליון נשאר פתוח ומוצגת הודעה,
    // בדיוק כמו קודם.
    void onTap() {
      if (!canAfford) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("חסרים לך מטבעות לרמה הזו (יש לך $_coins)", textDirection: TextDirection.rtl)),
        );
        return;
      }
      // 🩹 תוקן - ראו הערה מפורטת ליד _pendingStake למעלה (זה בדיוק מה
      // שגרם לקריסה האדומה "בכניסה למשחק"): רק שומרים ולא קוראים
      // ל-_onStakeSelected כאן ישירות.
      _stakeChosen = true;
      _pendingStake = stake;
      Navigator.pop(sheetContext);
    }

    return Opacity(
      opacity: canAfford ? 1 : 0.45,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
                  gradient: LinearGradient(colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.03)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accentDark]), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const CoinIcon(size: 20),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$stake מטבעות', textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accentDark]), borderRadius: BorderRadius.circular(14)),
                      child: const Text('שחק', style: TextStyle(color: Color(0xFF0B2233), fontSize: 13.5, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isPopular)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D74)]),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: const Text('הכי פופולרי', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
    );
  }

  // 🆕 טבעת "מחפש…" מסתובבת - אותו רעיון בדיוק כמו _spinningOpponentAvatar
  // בדו-קרב, בצבעי מרוץ.
  Widget _spinningOpponentAvatar({double size = 64}) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: 0.35 + _pulseController.value * 0.35,
                child: Container(
                  width: size + 16,
                  height: size + 16,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF38BDF8).withValues(alpha: 0.4), const Color(0xFF38BDF8).withValues(alpha: 0)])),
                ),
              ),
            ),
            Transform.rotate(
              angle: _radarController.value * 2 * 3.14159,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Color(0x007DD3FC), Color(0xFF7DD3FC), Color(0xFF0284C7), Color(0x007DD3FC)])),
              ),
            ),
            Container(
              width: size - 10,
              height: size - 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0C2A3D)),
              alignment: Alignment.center,
              child: Text('?', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: size * 0.32, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearching() {
    final elapsedText = '0:${_elapsedSeconds.toString().padLeft(2, '0')}';
    final stake = _selectedStake;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.45)),
                            gradient: LinearGradient(colors: [const Color(0xFF7DD3FC).withValues(alpha: 0.18), const Color(0xFF7DD3FC).withValues(alpha: 0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                          child: Column(
                            children: [
                              _avatarCircle(widget.username, size: 66),
                              const SizedBox(height: 10),
                              Text(widget.username, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 15, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 9),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFF34D399).withValues(alpha: 0.18), border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.45))),
                                child: const Text('מוכן ✓', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10.5, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.18)), color: const Color(0xFF0C2A3D).withValues(alpha: 0.9)),
                            alignment: Alignment.center,
                            child: Text('VS', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w900)),
                          ),
                          Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.01)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                          child: Column(
                            children: [
                              _spinningOpponentAvatar(),
                              const SizedBox(height: 10),
                              Text('מחפש…', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 9),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.07), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
                                child: Text('מתחבר…', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(color: Colors.white.withValues(alpha: 0.1)),
                        AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, child) {
                            final t = _radarController.value;
                            return Align(
                              alignment: Alignment(-1 + t * 2.4, 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.45,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)]),
                                    boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), blurRadius: 10)],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('מחפש יריב… $elapsedText', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 34,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      key: ValueKey(_tipIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _raceSearchingTips[_tipIndex],
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (stake != null) _buildRaceConditionsGrid(stake),
                const SizedBox(height: 22),
                TextButton(
                  onPressed: () {
                    _leaveIfNeeded();
                    Navigator.pop(context);
                  },
                  child: const Text('ביטול', style: TextStyle(color: Color(0xFFFB7185), fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceConditionsGrid(int stake) {
    final logos = LogoRaceService.stagesForStake(stake);
    final prize = stake * 2;
    Widget stat(String value, String label, Color color, Color bg) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: bg.withValues(alpha: 0.14), border: Border.all(color: bg.withValues(alpha: 0.35))),
            child: Column(
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: const [
              Text('🏁', style: TextStyle(fontSize: 13)),
              SizedBox(width: 8),
              Text('תנאי המרוץ', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('$stake', 'הימור', const Color(0xFFFFE7A8), const Color(0xFFFFD86B)),
              const SizedBox(width: 9),
              stat('$logos', 'לוגואים', const Color(0xFFBFDBFE), const Color(0xFF60A5FA)),
              const SizedBox(width: 9),
              stat('$prize', 'למנצח', const Color(0xFFA7F3D0), const Color(0xFF34D399)),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 "נמצא יריב!" - כרטיסי שני השחקנים + VS + ספירה לאחור אמיתית, בדיוק
  // כמו התחושה במסך המקביל בדו-קרב, רק בלי הסטטיסטיקות (מקום/XP/היסטוריה) -
  // אלה לא קיימות למרוץ ולא התבקשו.
  Widget _buildCountdown() {
    final race = _race;
    if (race == null) {
      return Column(
        children: [
          _buildTopBar(),
          const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF7DD3FC)))),
        ],
      );
    }
    final oppName = race.opponentNameFor(_myDeviceId);
    const blueInner = [Color(0xFF7DD3FC), Color(0xFF38BDF8)];
    const blueGlow = Color(0xFF38BDF8);
    // 🆕 מסך "נמצא יריב!" - עכשיו בדיוק אותו מבנה כמו בדו-קרב (ראו
    // opponent_found_widgets.dart): באדג' ירוק, שני כרטיסי שחקן + מפריד
    // VS, כרטיס "תנאי המרוץ", ואז טבעת ספירה-לאחור - רק בלי שורות
    // סטטיסטיקה (מקום/XP/ניצחונות) כי אלה לא קיימות במרוץ, ובצבעי התכלת
    // של המרוץ במקום הזהב/ורוד של הדו-קרב.
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  foundOpponentBadge(),
                  const SizedBox(height: 22),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: foundPlayerCard(
                            name: widget.username,
                            label: "אתה",
                            borderColor: const Color(0xFF7DD3FC),
                            nameColor: const Color(0xFF7DD3FC),
                            innerColors: blueInner,
                            ringColors: blueInner,
                            glowColor: blueGlow,
                          ),
                        ),
                        foundVsDivider(),
                        Expanded(
                          child: foundPlayerCard(
                            name: oppName,
                            label: "היריב",
                            borderColor: Colors.white,
                            nameColor: Colors.white,
                            innerColors: const [Color(0xFF0C2A3D), Color(0xFF0C2A3D)],
                            ringColors: blueInner,
                            glowColor: blueGlow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  gameTermsCard(
                    title: "תנאי המרוץ",
                    emoji: "🏁",
                    accent: const Color(0xFF7DD3FC),
                    stake: race.stake,
                    logos: LogoRaceService.stagesForStake(race.stake),
                    winnerReward: race.stake * 2,
                  ),
                  const SizedBox(height: 28),
                  Text("המרוץ מתחיל בעוד", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  readyCountdownRing(
                    value: _countdownLeft,
                    color: const Color(0xFF7DD3FC),
                    label: _countdownLeft > 0 ? null : 'צאו!',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying() {
    final race = _race;
    if (race == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3FC)));
    final level = _levelForStage(race, race.currentStage);
    final urgent = _stageSecondsLeft <= 6;
    final myScore = race.scoreFor(_myDeviceId);
    final oppId = race.opponentIdFor(_myDeviceId);
    final oppScore = race.scoreFor(oppId);
    final oppName = race.opponentNameFor(_myDeviceId);

    // 🆕 שבר "כיסוי" - 1.0 = הכל עוד שחור, 0.0 = הכל נחשף. במקום וילון
    // שנסוג מהצד, העיגול השקוף גדל מהמרכז כלפי חוץ (ראו _CenterRevealClipper).
    final blackFraction = (_stageSecondsLeft / LogoRaceService.revealDurationSeconds).clamp(0.0, 1.0);
    final revealFraction = 1 - blackFraction;
    final roundWinnerId = race.stageWinner[race.currentStage.toString()];
    final roundDecided = roundWinnerId != null;

    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(child: Text('אתה: $myScore', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
              Text('לוגו ${race.currentStage + 1}/${race.totalStages}', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w700)),
              Expanded(
                child: Text('$oppName: $oppScore', textAlign: TextAlign.left, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: revealFraction,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: urgent ? const Color(0xFFFB7185) : const Color(0xFF7DD3FC),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (level != null)
          Container(
            width: 160,
            height: 160,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 14))]),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(padding: const EdgeInsets.all(14), child: Image.asset(level.imagePath, fit: BoxFit.contain)),
                // 🆕 הוילון השחור - עכשיו עיגול שקוף שגדל מהמרכז כלפי חוץ
                // (במקום וילון שנסוג מהצד) - ראו _CenterRevealClipper למטה.
                ClipPath(
                  clipper: _CenterRevealClipper(revealFraction),
                  child: Container(color: Colors.black),
                ),
                AnimatedOpacity(
                  opacity: _showCorrectFeedback ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(child: Container(color: const Color(0xFF0D9488).withValues(alpha: 0.92), child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 54))),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        // 🆕 "צ'אט" - כל הניחושים המלאים (נכונים/שגויים) של שני הצדדים לשלב הזה
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: ListView(
              controller: _chatScroll,
              children: race.messagesForStage(race.currentStage).map((m) {
                final mine = m.senderId == _myDeviceId;
                final level2 = _levelForStage(race, m.stage);
                final correct = level2 != null && m.text.replaceAll(' ', '') == level2.answer.replaceAll(' ', '');
                return Align(
                  alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: correct ? const Color(0xFF16A34A).withValues(alpha: 0.35) : (mine ? const Color(0xFF38BDF8).withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: correct ? FontWeight.w900 : FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (roundDecided) ...[
          // 🩹 בעבר זו הייתה שורת טקסט שקטה מתחת לצ'אט - קל לפספס. לפי
          // בקשה מפורשת ("שיקפוץ משהו וירשום שמישהו ניחש נכון עם השם
          // שלו") - עכשיו זה באנר בולט שקופץ עם אנימציית קנה-מידה בכל
          // פעם שמתקבל תוצאה חדשה לשלב (keyed לפי currentStage כדי
          // שהאנימציה תרוץ מחדש בכל שלב, לא רק בפעם הראשונה).
          TweenAnimationBuilder<double>(
            key: ValueKey('round_result_${race.currentStage}'),
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: _buildRoundResultBanner(roundWinnerId, oppName),
          ),
          const SizedBox(height: 8),
        ] else if (level != null) ...[
          _buildGuessSlots(level),
          const SizedBox(height: 8),
          _buildKeyboard(level),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _onBackspace,
              icon: const Icon(Icons.backspace_rounded, color: Color(0xFFFB7185), size: 16),
              label: const Text('הסר אות', style: TextStyle(color: Color(0xFFFB7185), fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ],
    );
  }

  // 🆕 באנר "מישהו ניחש נכון" בולט - קופץ מעל הצ'אט בסוף כל שלב (ראו
  // הקריאה ב-_buildPlaying). ירוק אם ניצחת את הסיבוב, אדום-אפרסק אם
  // היריב ניצח (עם שמו במפורש), אפור-נייטרלי אם נגמר הזמן בלי ניחוש.
  Widget _buildRoundResultBanner(String roundWinnerId, String oppName) {
    final bool none = roundWinnerId == 'none';
    final bool won = !none && roundWinnerId == _myDeviceId;
    final Color color = none ? const Color(0xFF64748B) : (won ? const Color(0xFF16A34A) : const Color(0xFFFB7185));
    final String text = none ? 'הזמן נגמר - אף אחד לא ניחש' : (won ? 'ניחשת נכון! עובר ללוגו הבא...' : '$oppName ניחש/ה נכון! עובר ללוגו הבא...');
    final IconData icon = none ? Icons.timer_off_rounded : (won ? Icons.check_circle_rounded : Icons.flash_on_rounded);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessSlots(LevelData level) {
    final isEnglish = RegExp(r'[a-zA-Z]').hasMatch(level.answer);
    final totalLetters = _guessSlots.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        const double margin = 3;
        const double maxTileWidth = 28;
        const double minTileWidth = 16;
        final double idealWidth = totalLetters > 0 ? (constraints.maxWidth - (totalLetters * margin)) / totalLetters : maxTileWidth;
        final double tileWidth = idealWidth.clamp(minTileWidth, maxTileWidth);
        final double tileHeight = tileWidth * (40 / 28);
        final double fontSize = (tileWidth * 0.6).clamp(11.0, 17.0);

        return SizedBox(
          width: double.infinity,
          child: Center(
            child: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalLetters, (i) {
                  final letter = _guessSlots[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: tileWidth,
                    height: tileHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: letter != null ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(letter ?? '', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800)),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyboard(LevelData level) {
    final isEnglish = RegExp(r'[a-zA-Z]').hasMatch(level.answer);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double spacing = 6;
          const double maxKeyWidth = 36;
          const double minKeyWidth = 24;
          final int totalKeys = level.keyboard.length;
          final int keysPerRow = (totalKeys / 2).ceil();
          final double idealWidth = (constraints.maxWidth - (keysPerRow - 1) * spacing) / keysPerRow;
          final double keyWidth = idealWidth.clamp(minKeyWidth, maxKeyWidth);
          final double keyHeight = keyWidth * (44 / 36);
          final double fontSize = (keyWidth * 0.46).clamp(12.0, 18.0);

          return Directionality(
            textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: 7,
              children: List.generate(totalKeys, (i) {
                final isPressed = _pressedKeyIndices.contains(i);
                return Material(
                  color: isPressed ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: isPressed ? null : () => _onKeyTap(level.keyboard[i], i),
                    child: Container(
                      width: keyWidth,
                      height: keyHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: isPressed ? Colors.transparent : Colors.white.withValues(alpha: 0.18))),
                      child: Text(isPressed ? '' : level.keyboard[i], style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800)),
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

  // 🆕 מסך "ניצחת/הפסדת" של המרוץ - בנוי פיקסל-לפיקסל לפי מסך התוצאה של
  // הדו-קרב (_showResultDialog ב-duel_room_screen.dart, קובץ קריאה-בלבד):
  // אותו דיאלוג בדיוק (כניסה elastic, גרדיאנט/מסגרת/זוהר זהים, אותו תג
  // עליון, אותה כותרת "ניצחת!"/"תיקו!"/"היריב ניצח", אותו פודיום שני
  // שחקנים עם כתר מרחף למנצח, אותו כרטיס "הפרס שלך", ואותם כפתורים
  // (CTA ראשי בגרדיאנט זהב + "שיתוף"/"חזרה לתפריט") - רק עם הנתונים/
  // התוויות של המרוץ (ניקוד סיבובים במקום תשובות נכונות, בלי "שחק שוב
  // מול אותו יריב" כי למרוץ אין תמיכת rematch בשרת - ראה logo_race_service.dart).
  void _showRaceResultDialog(LogoRaceMatch race) {
    final myScore = race.scoreFor(_myDeviceId);
    final oppId = race.opponentIdFor(_myDeviceId);
    final oppScore = race.scoreFor(oppId);
    final oppName = race.opponentNameFor(_myDeviceId);
    final iWon = race.winnerId == _myDeviceId;
    final isDraw = race.winnerId == null;
    final stake = race.stake;
    final coinDelta = isDraw ? 0 : (iWon ? stake : -stake);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        // 🆕 כניסה עם "קפיצה" קלה (elastic) במקום שהדיאלוג פשוט "יופיע" -
        // בדיוק כמו במסך התוצאה של הדו-קרב.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.55, end: 1.0),
          duration: const Duration(milliseconds: 550),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 340,
            // 🩹 אותו תיקון "BOTTOM OVERFLOWED" כמו בדו-קרב - מגבילים לגובה
            // מקסימלי ומאפשרים גלילה פנימית קלה אם צריך על מסכים נמוכים.
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
                  // 🆕 תג "🏁 מרוץ · על X 🪙" למעלה - אותו תג בדיוק כמו
                  // הדו-קרב, רק עם אמוג'י+מילה של מרוץ.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFFB7185).withValues(alpha: 0.16),
                      border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.4)),
                    ),
                    child: Text('🏁 מרוץ · על $stake מטבעות', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
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
                  const SizedBox(height: 4),
                  // 🆕 במרוץ אין "זמן שחלף" זמין (לא נשמר על המסמך) - במקום
                  // זה מוצג ניקוד הסיבובים, שהוא המקבילה הישירה של "כמה
                  // תשובות נכונות" בדו-קרב.
                  Text(
                    '$myScore מתוך ${race.totalStages} לוגואים',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  // 🆕 פודיום - בדיוק כמו בדו-קרב: שתי כרטיסיות זו מול זו,
                  // של המנצח מוגבהת/מוארת עם כתר מרחף מעליה.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _racePodiumCard(
                          name: widget.username,
                          score: myScore,
                          totalStages: race.totalStages,
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
                        child: _racePodiumCard(
                          name: oppName,
                          score: oppScore,
                          totalStages: race.totalStages,
                          isWinner: !isDraw && !iWon,
                          isDimmed: !isDraw && iWon,
                          ringColors: const [Color(0xFFFDA4AF), Color(0xFFE11D74)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 🆕 "הפרס שלך" - שורת 3 סטטיסטיקות אמיתיות (לא בדויות):
                  // מטבעות, XP וסיבובים שנוצחו במרוץ הזה. בדיוק כמו בדו-קרב.
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
                              child: _racePrizeStat(
                                value: '${coinDelta >= 0 ? '+' : ''}$coinDelta',
                                icon: Icons.monetization_on_rounded,
                                color: coinDelta >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B),
                                label: 'מטבעות',
                              ),
                            ),
                            Expanded(
                              child: _racePrizeStat(
                                value: iWon ? '+${LogoRaceService.winXpReward}' : '+0',
                                icon: Icons.bolt_rounded,
                                color: const Color(0xFFFFD86B),
                                label: 'XP',
                              ),
                            ),
                            Expanded(
                              child: _racePrizeStat(
                                value: '$myScore/${race.totalStages}',
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
                  const SizedBox(height: 20),
                  // 🆕 כפתור CTA ראשי (זהוב, מלא) + שורת כפתורים משניים
                  // (שיתוף / חזרה לתפריט) - בדיוק כמו בדו-קרב. אין כאן
                  // כפתור "שחק שוב מול אותו יריב" - למרוץ אין תמיכת
                  // rematch בשרת (ראה logo_race_service.dart), אז לא
                  // ממציאים פיצ'ר שלא קיים.
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
                        // 🆕 יוצאים מהמסך הנוכחי (מרוץ שהסתיים) ופותחים
                        // מרוץ חדש - המקבילה של "דו-קרב נוסף" מבחינת המרוץ
                        // (שאין לו לובי נפרד מהמסך עצמו, בניגוד לדו-קרב).
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LogoRaceScreen(username: widget.username)));
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)]),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text('מרוץ נוסף 🏁', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900)),
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
                                ? 'ניצחתי במרוץ לוגואים במשחק "זהה את הלוגו!" 🏁 $myScore/${race.totalStages} לוגואים. בואו תנסו לנצח אותי! 🎮'
                                : 'שיחקתי מרוץ לוגואים במשחק "זהה את הלוגו!" - בואו תתמודדו איתי! 🏁';
                            Share.share(text);
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

  // 🆕 כרטיסיית שחקן בפודיום - בדיוק כמו _podiumCard ב-duel_room_screen.dart
  // (קובץ קריאה-בלבד): כתר מרחף מעל שם המנצח, אווטאר עגול עם טבעת
  // גרדיאנט, ומספר הסיבובים שנוצחו (המקבילה של "תשובות נכונות/סה״כ" בדו-קרב).
  Widget _racePodiumCard({
    required String name,
    required int score,
    required int totalStages,
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
          Text('$score/$totalStages', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return Opacity(
      opacity: isDimmed ? 0.5 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (isWinner) const Positioned(top: -22, child: _RaceFloatingCrown()),
          Padding(padding: EdgeInsets.only(top: isWinner ? 14 : 0), child: card),
        ],
      ),
    );
  }

  Widget _racePrizeStat({required String value, required IconData icon, required Color color, required String label}) {
    return Column(
      children: [
        // 🆕 מטבע = אימוג'י (ראו app_icons.dart) - XP נשאר אייקון וקטורי,
        // בדיוק כמו _prizeStat ב-duel_room_screen.dart.
        icon == Icons.monetization_on_rounded ? const CoinIcon(size: 18) : Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// 🆕 כתר מרחף (אנימציית ריחוף עדינה) מעל שם המנצח בפודיום - בדיוק כמו
// _FloatingCrown ב-duel_room_screen.dart (קובץ קריאה-בלבד, לא ניתן
// לייבא class פרטי ממנו - ממומש כאן מחדש עם אותה אנימציה בדיוק).
class _RaceFloatingCrown extends StatefulWidget {
  const _RaceFloatingCrown();

  @override
  State<_RaceFloatingCrown> createState() => _RaceFloatingCrownState();
}

class _RaceFloatingCrownState extends State<_RaceFloatingCrown> with SingleTickerProviderStateMixin {
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

// 🆕 חושף את הלוגו בעיגול שגדל מהמרכז כלפי חוץ, במקום וילון שנסוג מהצד -
// חלופה שביקש המשתמש ("אולי מהאמצע"). מצייר מלבן שחור מלא ואז "חותך" ממנו
// עיגול הולך וגדל (PathOperation.difference) - השטח שבתוך העיגול שקוף
// (הלוגו נראה), השטח מחוץ לו נשאר שחור. revealFraction: 0 = שחור לגמרי
// (רדיוס 0), 1 = הכל גלוי (רדיוס גדול מספיק לכסות גם את הפינות הרחוקות).
class _CenterRevealClipper extends CustomClipper<Path> {
  final double revealFraction; // 0..1
  const _CenterRevealClipper(this.revealFraction);

  @override
  Path getClip(Size size) {
    final fullRect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (revealFraction <= 0) return fullRect; // כלום עוד לא נחשף - כל המלבן נשאר שחור
    final center = Offset(size.width / 2, size.height / 2);
    // קוטר האלכסון/2 + מרווח ביטחון קטן - מבטיח שברדיוס המקסימלי גם
    // הפינות הרחוקות ביותר של הריבוע כבר בתוך העיגול (חשיפה מלאה אמיתית).
    final maxRadius = (size.width * size.width + size.height * size.height) > 0
        ? (Offset(size.width, size.height).distance / 2) * 1.06
        : 1.0;
    final radius = maxRadius * revealFraction;
    if (radius <= 0) return fullRect;
    final holePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, fullRect, holePath);
  }

  @override
  bool shouldReclip(covariant _CenterRevealClipper oldClipper) => oldClipper.revealFraction != revealFraction;
}

class _RaceRoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RaceRoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, color: Colors.white, size: 19)),
      ),
    );
  }
}