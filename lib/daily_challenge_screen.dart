// daily_challenge_screen.dart
//
// "אתגר היום" - 6 לוגואים רנדומליים (אותם 6 לכולם, נבחרים לפי התאריך
// דרך MissionsService.getDailyChallenge) שצריך לפתור ברצף תוך 30 שניות
// בסך הכל. בלי רמזים ובלי עלות מטבעות - זה מבחן מהירות טהור. הצלחה =
// פרס חד-פעמי ליום (מטבעות + XP), נכשל = "נסה שוב" עם אותם 6 לוגואים
// וטיימר טרי, בלי שום קנס.
//
// מנגנון הקלט (תאי אות + מקלדת) מבוסס בדיוק על אותה לוגיקה שכבר בנויה
// ב-duel_room_screen.dart, כדי שהתחושה תהיה עקבית עם שאר המשחק.

import 'dart:async';
import 'package:flutter/material.dart';
import 'app_background.dart';
import 'level_data.dart';
import 'locale_controller.dart'; // 🆕 שפת האפליקציה (עברית/אנגלית) - קובעת איזה ans/keyboard מוצגים
import 'missions_service.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'notification_service.dart';
import 'notification_manager.dart'; // 🆕 מתג "תזכורות יומיות" בטאב ההתראות (ראו _onRemindMeTomorrow)
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי (ראו app_icons.dart)
import 'l10n/app_localizations.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

// 🆕 אתגר היום ניתן לניסיון *פעם אחת ביום בלבד* - גם אם נכשלת (לא רק
// אם הצלחת). alreadyDone = הצלחת היום. usedUp = כבר ניסית היום ונכשלת
// (ואין עוד ניסיון עד מחר) - נראה כשחוזרים למסך הזה אחרי כישלון קודם.
enum _Phase { loading, alreadyDone, usedUp, intro, playing, success, failed }

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  _Phase _phase = _Phase.loading;
  List<int> _logoIds = [];
  int _index = 0;

  List<String?> _guessSlots = [];
  List<int> _typedOrder = [];
  final Set<int> _pressedKeyIndices = {};
  final Map<int, int> _slotToKeyIndex = {};
  bool _showCorrectFeedback = false;

  Timer? _ticker;
  DateTime? _deadline;
  double _remainingSeconds = MissionsService.dailyChallengeSeconds.toDouble();
  // 🆕 "תזכיר לי מחר" - סטייט מקומי למסך הזה בלבד (לא נשמר), רק כדי
  // שהכפתור יתחלף למצב "מסומן" אחרי לחיצה ולא יאפשר ללחוץ שוב.
  bool _reminderSet = false;

  void _onRemindMeTomorrow() {
    if (_reminderSet) return;
    AudioManager.playClick();
    // 🆕 מגודר לפי מתג "תזכורות יומיות" בטאב ההתראות - ראו notification_manager.dart.
    if (NotificationManager.notificationsEnabled && NotificationManager.dailyNotificationsEnabled) {
      NotificationService.scheduleDailyChallengeReminder();
    }
    setState(() => _reminderSet = true);
  }

  Widget _buildRemindMeButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton.icon(
        onPressed: _reminderSet ? null : _onRemindMeTomorrow,
        icon: Icon(_reminderSet ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, size: 18, color: _reminderSet ? const Color(0xFF4ADE80) : Colors.white.withValues(alpha: 0.65)),
        label: Text(
          _reminderSet ? AppLocalizations.of(context)!.dailyChallengeReminderSet : AppLocalizations.of(context)!.dailyChallengeRemindMe,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _reminderSet ? const Color(0xFF4ADE80) : Colors.white.withValues(alpha: 0.65)),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenge = await MissionsService.getDailyChallenge();
    if (!mounted) return;
    setState(() {
      _logoIds = challenge.levelIds;
      _phase = challenge.completed ? _Phase.alreadyDone : (challenge.attempted ? _Phase.usedUp : _Phase.intro);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startRun() {
    // 🆕 מסמנים "נוצל" *מיד* עם ההתחלה - כך שהניסיון היחיד ליום נחשב
    // גם אם השחקן יוצא מהמסך באמצע הריצה בלי לסיים, לא רק על כישלון
    // מלא בתום הזמן.
    MissionsService.markDailyChallengeAttempted();
    // 🐛 תוקן: אתגר היום מעולם לא חיבר לשום פרסומת - "נכנסים למשחק בפועל".
    AdsManager.recordGameEntered();
    setState(() {
      _index = 0;
      _remainingSeconds = MissionsService.dailyChallengeSeconds.toDouble();
      _phase = _Phase.playing;
      _resetGuessForCurrent();
    });
    _deadline = DateTime.now().add(Duration(seconds: MissionsService.dailyChallengeSeconds));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null || _phase != _Phase.playing) return;
    final remaining = deadline.difference(DateTime.now()).inMilliseconds / 1000.0;
    if (remaining <= 0) {
      _ticker?.cancel();
      setState(() {
        _remainingSeconds = 0;
        _phase = _Phase.failed;
      });
      return;
    }
    setState(() => _remainingSeconds = remaining);
  }

  LevelData? get _currentLevel {
    if (_index >= _logoIds.length) return null;
    return gameLevels[_logoIds[_index]];
  }

  void _resetGuessForCurrent() {
    final level = _currentLevel;
    final answerLen = level?.answerFor(localeController.isHebrew).replaceAll(' ', '').length ?? 0;
    _guessSlots = List<String?>.filled(answerLen, null);
    _typedOrder = [];
    _pressedKeyIndices.clear();
    _slotToKeyIndex.clear();
  }

  void _onKeyTap(String letter, int keyIndex) {
    if (_phase != _Phase.playing) return;
    if (_pressedKeyIndices.contains(keyIndex)) return;
    final nextEmpty = _guessSlots.indexWhere((s) => s == null);
    if (nextEmpty == -1) return;
    setState(() {
      _guessSlots[nextEmpty] = letter;
      _typedOrder.add(nextEmpty);
      _pressedKeyIndices.add(keyIndex);
      _slotToKeyIndex[nextEmpty] = keyIndex;
    });
    if (!_guessSlots.contains(null)) _checkAnswer();
  }

  void _onBackspace() {
    if (_typedOrder.isEmpty) return;
    setState(() {
      final lastIndex = _typedOrder.removeLast();
      _guessSlots[lastIndex] = null;
      final keyIndex = _slotToKeyIndex.remove(lastIndex);
      if (keyIndex != null) _pressedKeyIndices.remove(keyIndex);
    });
  }

  Future<void> _checkAnswer() async {
    final level = _currentLevel;
    if (level == null) return;
    final cleanGuess = _guessSlots.map((s) => s ?? '').join();
    final cleanAnswer = level.answerFor(localeController.isHebrew).replaceAll(' ', '');

    if (cleanGuess != cleanAnswer) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _phase != _Phase.playing) return;
        setState(() {
          _guessSlots = List<String?>.filled(_guessSlots.length, null);
          _typedOrder = [];
          _pressedKeyIndices.clear();
          _slotToKeyIndex.clear();
        });
      });
      return;
    }

    AudioManager.playSuccess('audio/win.mp3');
    setState(() => _showCorrectFeedback = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _phase != _Phase.playing) return;
    setState(() => _showCorrectFeedback = false);

    _index++;
    if (_index >= _logoIds.length) {
      _ticker?.cancel();
      final granted = await MissionsService.completeDailyChallenge();
      if (!mounted) return;
      // 🐛 תוקן: השלמת אתגר היום מעולם לא נספרה לקראת פרסומת, בדיוק
      // כמו השלמת שלב רגיל.
      AdsManager.onLevelSolved();
      setState(() => _phase = _Phase.success);
      if (!granted) {
        // מקרה קצה נדיר (למשל שני טאבים) - עדיין מציגים הצלחה, רק בלי זיכוי כפול.
      }
    } else {
      setState(() => _resetGuessForCurrent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: switch (_phase) {
            _Phase.loading => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B))),
            _Phase.alreadyDone => _buildAlreadyDone(),
            _Phase.usedUp => _buildUsedUp(),
            _Phase.intro => _buildIntro(),
            _Phase.playing => _buildPlaying(),
            _Phase.success => _buildSuccess(),
            _Phase.failed => _buildFailed(),
          },
        ),
      ),
    );
  }

  Widget _buildTopBar({String? title}) {
    final resolvedTitle = title ?? AppLocalizations.of(context)!.dailyChallengeTitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          Expanded(
            child: Center(
              child: Text(resolvedTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 40), // מאזן את כפתור הסגירה כדי שהכותרת תישאר במרכז
        ],
      ),
    );
  }

  Widget _buildAlreadyDone() {
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
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 70),
                  const SizedBox(height: 18),
                  Text(AppLocalizations.of(context)!.dailyChallengeAlreadyDoneTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.dailyChallengeComeBackTomorrow, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13.5)),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB24D), foregroundColor: const Color(0xFF2A1740), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.duelLobbyBackButton, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                  ),
                  _buildRemindMeButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 מוצג כשחוזרים למסך אחרי שכבר נוצל הניסיון היחיד היום בכישלון -
  // אין עוד הזדמנות עד מחר, בלי כפתור "נסה שוב".
  Widget _buildUsedUp() {
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
                  const Icon(Icons.timer_off_rounded, color: Color(0xFFFB7185), size: 64),
                  const SizedBox(height: 18),
                  Text(AppLocalizations.of(context)!.dailyChallengeUsedUpTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.dailyChallengeUsedUpMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13.5)),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB24D), foregroundColor: const Color(0xFF2A1740), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.duelLobbyBackButton, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                  ),
                  _buildRemindMeButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntro() {
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
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)])),
                    alignment: Alignment.center,
                    child: const EnergyIcon(size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.dailyChallengeIntroStats(MissionsService.dailyChallengeLogoCount, MissionsService.dailyChallengeSeconds), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.dailyChallengeIntroBody, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5, height: 1.5)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFB7185).withValues(alpha: 0.14)),
                    child: Text(AppLocalizations.of(context)!.dailyChallengeOneAttemptWarning, style: TextStyle(color: const Color(0xFFFDA4AF).withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFFFFD86B).withValues(alpha: 0.14)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+${MissionsService.dailyChallengeCoinReward}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 3),
                        const CoinIcon(size: 16),
                        const SizedBox(width: 10),
                        Text('+${MissionsService.dailyChallengeXpReward} XP', style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB24D), foregroundColor: const Color(0xFF2A1740), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _startRun,
                      child: Text(AppLocalizations.of(context)!.dailyChallengeStartButton, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying() {
    final level = _currentLevel;
    final isEnglish = level != null && RegExp(r'[a-zA-Z]').hasMatch(level.answerFor(localeController.isHebrew));
    final urgent = _remainingSeconds <= 10;
    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 10),
        // 🆕 בר זמן שמתכווץ + מספר שניות - האלמנט המרכזי של המסך הזה,
        // כדי שהלחץ של הספירה לאחור תמיד יהיה מול העיניים.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.duelRoomLogoCounter(_index + 1, _logoIds.length), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_remainingSeconds.toStringAsFixed(1), style: TextStyle(color: urgent ? const Color(0xFFFB7185) : const Color(0xFFFFD86B), fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 4),
                  Icon(Icons.timer_rounded, color: urgent ? const Color(0xFFFB7185) : const Color(0xFFFFD86B), size: 16),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_remainingSeconds / MissionsService.dailyChallengeSeconds).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: urgent ? const Color(0xFFFB7185) : const Color(0xFFFFD86B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (level != null) ...[
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
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                  child: Image.asset(level.imagePath, fit: BoxFit.contain),
                ),
              ),
              AnimatedOpacity(
                opacity: _showCorrectFeedback ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: const Color(0xFF0D9488).withValues(alpha: 0.92)),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 54),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGuessSlots(level, isEnglish),
          const Spacer(),
          _buildKeyboard(level, isEnglish),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _onBackspace,
              icon: const Icon(Icons.backspace_rounded, color: Color(0xFFFB7185), size: 16),
              label: Text(AppLocalizations.of(context)!.logoRaceRemoveLetterButton, style: const TextStyle(color: Color(0xFFFB7185), fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

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
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: tileWidth,
                    height: tileHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: letter != null ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildKeyboard(LevelData level, bool isEnglish) {
    final keyboard = level.keyboardFor(localeController.isHebrew);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double spacing = 7;
          const double maxKeyWidth = 42;
          const double minKeyWidth = 28;
          final int totalKeys = keyboard.length;
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
                final isPressed = _pressedKeyIndices.contains(i);
                return Material(
                  color: isPressed ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isPressed ? null : () => _onKeyTap(keyboard[i], i),
                    child: Container(
                      width: keyWidth,
                      height: keyHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isPressed ? Colors.transparent : Colors.white.withValues(alpha: 0.18))),
                      child: Text(isPressed ? '' : keyboard[i], style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800)),
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

  Widget _buildSuccess() {
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
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD86B), size: 74),
                  const SizedBox(height: 14),
                  Text(AppLocalizations.of(context)!.dailyChallengeSuccessTitle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(AppLocalizations.of(context)!.dailyChallengeSuccessTime((MissionsService.dailyChallengeSeconds - _remainingSeconds).toStringAsFixed(1)), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFFFD86B).withValues(alpha: 0.14)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+${MissionsService.dailyChallengeCoinReward}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 17, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 3),
                        const CoinIcon(size: 18),
                        const SizedBox(width: 12),
                        Text('+${MissionsService.dailyChallengeXpReward} XP', style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 17, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB24D), foregroundColor: const Color(0xFF2A1740), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.duelLobbyBackButton, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed() {
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
                  const Icon(Icons.timer_off_rounded, color: Color(0xFFFB7185), size: 64),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.dailyChallengeTimeUpTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(AppLocalizations.of(context)!.dailyChallengeFailedProgress(_index + 1, _logoIds.length), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.dailyChallengeTryTomorrow, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB24D), foregroundColor: const Color(0xFF2A1740), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.duelLobbyBackButton, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

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