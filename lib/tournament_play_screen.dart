// tournament_play_screen.dart
//
// משחק יום אחד בתוך האתגר הרב-יומי: tournamentDailyLogoCount הלוגואים
// הקבועים של היום (TournamentService.levelIdsForEventDay), ברצף אחד אחרי
// השני, עם שעון עצר כולל (לא לכל לוגו בנפרד). בסיום הלוגו האחרון נשלחת
// התוצאה של היום (TournamentService.submitDayResult, מצטברת מול שאר ימי
// האירוע) ועוברים למסך התוצאות.
//
// 🩹 ממחזר כמעט אחד לאחד את הקוד שכבר הוכח ומתוקן ב-tafzoret_guess_screen.dart
// (גודל תאי אות דינמי לפי רוחב המסך, בדיקה אוטומטית כשמתמלא בלי כפתור
// נפרד, תפריט רמזים זהה ב-20/60 מטבעות, כיוון טקסט לפי תוכן התשובה
// בפועל ולא לפי שפת האפליקציה) - אותם באגים האלה כבר נמצאו ותוקנו שם,
// אין טעם לגלות אותם מחדש כאן.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_data.dart';
import 'tournament_service.dart';
import 'tournament_results_screen.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'locale_controller.dart';
import 'app_icons.dart';

class TournamentPlayScreen extends StatefulWidget {
  const TournamentPlayScreen({super.key});

  @override
  State<TournamentPlayScreen> createState() => _TournamentPlayScreenState();
}

class _TournamentPlayScreenState extends State<TournamentPlayScreen> {
  late final List<int> _levelIds;
  int _index = 0;
  int _correctCount = 0;
  final Stopwatch _stopwatch = Stopwatch();

  List<String?> _slots = [];
  final Set<int> _pressedKeyIndices = {};
  final List<int> _fillOrder = [];
  final Set<int> _hintedSlots = {};
  bool _solved = false;
  bool _wrongShake = false;
  int _coins = 0;

  LevelData get _level => gameLevels[_levelIds[_index]]!;
  String get _answer => _level.answerFor(localeController.isHebrew).replaceAll(' ', '');
  List<String> get _keyboard => _level.keyboardFor(localeController.isHebrew);
  bool get _isEnglish => RegExp(r'[a-zA-Z]').hasMatch(_answer);
  bool get _allFilled => _slots.every((s) => s != null);

  @override
  void initState() {
    super.initState();
    _levelIds = TournamentService.levelIdsForEventDay(TournamentService.eventId(), TournamentService.dayInEvent());
    _slots = List<String?>.filled(_answer.length, null);
    _stopwatch.start();
    _loadCoins();
    // 🐛 תוקן: מצב הטורניר היומי מעולם לא חיבר לשום פרסומת - "נכנסים
    // למשחק בפועל" כמו בכל מצב אחר (ראו logo_level_screen.dart,
    // duel_room_screen.dart) - מאפס את מונה "גלישה בלי לשחק".
    AdsManager.recordGameEntered();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _coins = prefs.getInt('coins') ?? 15);
  }

  void _onLetterTap(int keyIndex, String letter) {
    if (_pressedKeyIndices.contains(keyIndex) || _solved) return;
    final emptySlot = _slots.indexWhere((s) => s == null);
    if (emptySlot == -1) return;
    AudioManager.playClick();
    setState(() {
      _slots[emptySlot] = letter;
      _pressedKeyIndices.add(keyIndex);
      _fillOrder.add(emptySlot);
    });
    if (_allFilled) _checkAnswer();
  }

  void _onBackspace() {
    if (_solved) return;
    for (int i = _fillOrder.length - 1; i >= 0; i--) {
      final slot = _fillOrder[i];
      if (_hintedSlots.contains(slot)) continue;
      AudioManager.playClick();
      setState(() {
        _slots[slot] = null;
        _fillOrder.removeAt(i);
        _pressedKeyIndices.clear();
        final usedLetters = <String>[..._slots.whereType<String>()];
        for (int k = 0; k < _keyboard.length; k++) {
          if (usedLetters.contains(_keyboard[k])) {
            usedLetters.remove(_keyboard[k]);
            _pressedKeyIndices.add(k);
          }
        }
      });
      return;
    }
  }

  void _removeAt(int slotIndex) {
    if (_hintedSlots.contains(slotIndex) || _slots[slotIndex] == null) return;
    AudioManager.playClick();
    setState(() {
      _slots[slotIndex] = null;
      _fillOrder.remove(slotIndex);
      _pressedKeyIndices.clear();
      final usedLetters = <String>[..._slots.whereType<String>()];
      for (int k = 0; k < _keyboard.length; k++) {
        if (usedLetters.contains(_keyboard[k])) {
          usedLetters.remove(_keyboard[k]);
          _pressedKeyIndices.add(k);
        }
      }
    });
  }

  Future<void> _revealLetterHint() async {
    if (_solved) return;
    final emptySlots = <int>[];
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) emptySlots.add(i);
    }
    if (emptySlots.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final fresh = prefs.getInt('coins') ?? _coins;
    if (fresh < 20) {
      if (mounted) setState(() => _coins = fresh);
      return;
    }
    await prefs.setInt('coins', fresh - 20);
    AudioManager.playClick();
    final slot = emptySlots[Random().nextInt(emptySlots.length)];
    final letter = _answer[slot];
    setState(() {
      _coins = fresh - 20;
      _slots[slot] = letter;
      _hintedSlots.add(slot);
      _fillOrder.add(slot);
      for (int i = 0; i < _keyboard.length; i++) {
        if (_keyboard[i] == letter && !_pressedKeyIndices.contains(i)) {
          _pressedKeyIndices.add(i);
          break;
        }
      }
    });
    if (_allFilled) _checkAnswer();
  }

  Future<void> _revealWordHint() async {
    if (_solved) return;
    final prefs = await SharedPreferences.getInstance();
    final fresh = prefs.getInt('coins') ?? _coins;
    if (fresh < 60) {
      if (mounted) setState(() => _coins = fresh);
      return;
    }
    await prefs.setInt('coins', fresh - 60);
    AudioManager.playClick();
    setState(() {
      _coins = fresh - 60;
      for (int i = 0; i < _answer.length; i++) {
        _slots[i] = _answer[i];
      }
      _hintedSlots.addAll(List.generate(_answer.length, (i) => i));
      _fillOrder
        ..clear()
        ..addAll(List.generate(_answer.length, (i) => i));
      _pressedKeyIndices.clear();
      final usedIndices = List<bool>.filled(_keyboard.length, false);
      for (final letter in _answer.split('')) {
        for (int i = 0; i < _keyboard.length; i++) {
          if (!usedIndices[i] && _keyboard[i] == letter) {
            usedIndices[i] = true;
            _pressedKeyIndices.add(i);
            break;
          }
        }
      }
    });
    _checkAnswer();
  }

  void _showHintMenu() {
    AudioManager.playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
            child: Container(
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
                  const Text('בחירת רמז', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  _HintOptionTile(
                    icon: Icons.font_download_outlined,
                    title: 'חשיפת אות',
                    subtitle: 'חושף אות אחת אקראית בחידה',
                    price: 20,
                    accent: const Color(0xFFFFB24D),
                    onTap: () {
                      Navigator.pop(context);
                      _revealLetterHint();
                    },
                  ),
                  const SizedBox(height: 12),
                  _HintOptionTile(
                    icon: Icons.abc_rounded,
                    title: 'פתרון מילה שלמה',
                    subtitle: 'חושף את כל התשובה',
                    price: 60,
                    accent: const Color(0xFF9333EA),
                    onTap: () {
                      Navigator.pop(context);
                      _revealWordHint();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('ביטול', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkAnswer() async {
    if (!_allFilled || _solved) return;
    final guess = _slots.map((s) => s ?? '').join();
    if (guess == _answer) {
      AudioManager.playSuccess('audio/win.mp3');
      setState(() {
        _solved = true;
        _correctCount++;
      });
      // 🩹 לפי בקשה מפורשת: לא להציג פרסומת באמצע הריצה בטורניר ("הקטע
      // בטורניר זה הלחץ") - הספירה לקראת הפרסומת (AdsManager.onLevelSolved)
      // עברה ל-_finish למטה, אחרי שיוצאים מהטורניר, לא כאן.
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (_index == _levelIds.length - 1) {
        await _finish();
      } else {
        setState(() {
          _index++;
          _slots = List<String?>.filled(_answer.length, null);
          _pressedKeyIndices.clear();
          _fillOrder.clear();
          _hintedSlots.clear();
          _solved = false;
        });
      }
    } else {
      AudioManager.playClick();
      setState(() => _wrongShake = true);
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      setState(() {
        _wrongShake = false;
        _slots = List<String?>.filled(_answer.length, null);
        _pressedKeyIndices.clear();
        _fillOrder.clear();
        _hintedSlots.clear();
      });
    }
  }

  Future<void> _finish() async {
    _stopwatch.stop();
    await TournamentService.submitDayResult(correctCount: _correctCount, totalTimeMs: _stopwatch.elapsedMilliseconds);
    // 🩹 לפי בקשה מפורשת: "אל תעשה אחרי 7 שלבים כי הקטע בטורניר זה
    // הלחץ... תעשה אחרי שיוצאים מהטורניר כאילו סיימתם את העשר להיום" -
    // במקום לספור כל לוגו בזמן הריצה (מפריע לתחושת הלחץ/זרימה), סופרים
    // כאן בבת אחת את כל הלוגואים שנפתרו היום, בדיוק כאילו נפתרו ברצף
    // רגיל - אותו מנגנון סף-7 בדיוק (AdsManager.onLevelSolved), רק שהוא
    // "מתעדכן" כולו ברגע היציאה, לא תוך כדי.
    for (int i = 0; i < _correctCount; i++) {
      // 🩹 ממתינים לכל קריאה (לא "יורים" את כולן בבת אחת) - onLevelSolved
      // קורא/כותב ל-SharedPreferences ('solvedSinceAd'); בלי await כאן
      // כמה קריאות היו יכולות לרוץ זו על זו ולאבד עדכונים של המונה.
      await AdsManager.onLevelSolved();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TournamentResultsScreen(correctCount: _correctCount, totalMs: _stopwatch.elapsedMilliseconds)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0818),
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.38, 0.72, 1.0],
                      colors: [Color(0xFF4A2394), Color(0xFF2E1668), Color(0xFF1B0F42), Color(0xFF120B2C)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Row(
                        children: [
                          _RoundIconButton(icon: Icons.close_rounded, onTap: _confirmQuit),
                          Expanded(
                            child: Column(
                              children: [
                                Text('יום ${TournamentService.dayInEvent()} מתוך $tournamentEventDays', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(
                                  'לוגו ${_index + 1} מתוך ${_levelIds.length}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          _CoinPill(coins: _coins),
                        ],
                      ),
                    ),
                    // 🆕 פס התקדמות דק מתחת לכותרת - כמה לוגואים כבר נפתרו
                    // מתוך הסך הכול, כולל "קפיצה" חלקה (AnimatedContainer)
                    // כשעוברים ללוגו הבא. פולישינג זול למסך המשחק עצמו, בלי
                    // לגעת במכניקת הפתרון של החידה (ראו הערת הקובץ למעלה).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 6,
                          child: LayoutBuilder(builder: (context, constraints) {
                            final progress = ((_index + (_solved ? 1 : 0)) / _levelIds.length).clamp(0.0, 1.0);
                            return Stack(
                              children: [
                                Container(color: Colors.white.withValues(alpha: 0.08)),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOut,
                                  width: constraints.maxWidth * progress,
                                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)])),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            _LogoFrame(imagePath: _level.imagePath, solved: _solved, wrong: _wrongShake),
                            const SizedBox(height: 22),
                            _buildSlots(),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _ActionChip(icon: Icons.lightbulb_rounded, label: 'רמז', color: const Color(0xFFFFD86B), onTap: _showHintMenu),
                                _ActionChip(icon: Icons.backspace_rounded, label: 'מחיקה', color: const Color(0xFFFB7185), onTap: _onBackspace),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    _buildKeyboardArea(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmQuit() async {
    AudioManager.playClick();
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF241a4f),
          title: const Text('לצאת מהטורניר?', style: TextStyle(color: Colors.white)),
          content: Text('דמי הכניסה לא יוחזרו ולא תוכלו לנסות שוב היום.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('המשך לשחק')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('צא', style: TextStyle(color: Color(0xFFFB7185)))),
          ],
        ),
      ),
    );
    if (quit == true && mounted) Navigator.pop(context);
  }

  Widget _buildSlots() {
    final words = _level.answerFor(localeController.isHebrew).split(' ');
    final activeIndex = _slots.indexWhere((s) => s == null);
    return LayoutBuilder(builder: (context, constraints) {
      const double margin = 4;
      const double maxTileWidth = 35;
      const double minTileWidth = 20;
      final int totalLetters = _answer.length;
      final double idealWidth = totalLetters > 0 ? (constraints.maxWidth - (totalLetters * margin)) / totalLetters : maxTileWidth;
      final double tileWidth = idealWidth.clamp(minTileWidth, maxTileWidth);
      final double tileHeight = tileWidth * (45 / 35);
      final double fontSize = (tileWidth * 0.6).clamp(13.0, 22.0);

      final rows = <Widget>[];
      int gi = 0;
      for (final word in words) {
        final letters = <Widget>[];
        for (int i = 0; i < word.length; i++) {
          final slotIndex = gi;
          final filled = slotIndex < _slots.length ? _slots[slotIndex] : null;
          final isActive = slotIndex == activeIndex;
          gi++;
          letters.add(GestureDetector(
            onTap: filled != null ? () => _removeAt(slotIndex) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _LetterSlot(letter: filled, active: isActive, width: tileWidth, height: tileHeight, fontSize: fontSize),
            ),
          ));
        }
        rows.add(Row(mainAxisSize: MainAxisSize.min, children: letters));
      }
      return SizedBox(
        width: double.infinity,
        child: Center(
          child: Directionality(
            textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
            child: Wrap(alignment: WrapAlignment.center, runAlignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: rows),
          ),
        ),
      );
    });
  }

  Widget _buildKeyboardArea() {
    final keyboard = _keyboard;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 26),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0720).withValues(alpha: 0.75),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        const spacing = 7.0;
        const maxKeyWidth = 42.0;
        const minKeyWidth = 30.0;
        final keysPerRow = (keyboard.length / 2).ceil();
        final idealWidth = (constraints.maxWidth - (keysPerRow - 1) * spacing) / keysPerRow;
        final keyWidth = idealWidth.clamp(minKeyWidth, maxKeyWidth);
        final keyHeight = keyWidth * (48 / 42);
        final fontSize = (keyWidth * 0.48).clamp(14.0, 20.0);
        return Directionality(
          textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: 10,
            children: List.generate(keyboard.length, (index) {
              final isPressed = _pressedKeyIndices.contains(index);
              return GestureDetector(
                onTap: isPressed ? null : () => _onLetterTap(index, keyboard[index]),
                child: Container(
                  width: keyWidth,
                  height: keyHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isPressed ? 0.04 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isPressed ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 3))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    keyboard[index],
                    style: TextStyle(
                      color: isPressed ? Colors.transparent : Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: color.withValues(alpha: 0.14), border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 17), const SizedBox(width: 7), Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900))]),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.03)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.55)]), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: const Color(0xFF2A1740), size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFFFD86B).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text("$price", style: const TextStyle(color: Color(0xFF2A1740), fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(width: 3), const CoinIcon(size: 15)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterSlot extends StatefulWidget {
  final String? letter;
  final bool active;
  final double width;
  final double height;
  final double fontSize;
  const _LetterSlot({required this.letter, required this.active, required this.width, required this.height, required this.fontSize});

  @override
  State<_LetterSlot> createState() => _LetterSlotState();
}

class _LetterSlotState extends State<_LetterSlot> with SingleTickerProviderStateMixin {
  // 🩹 תוקנה אותה קריסה אמיתית שתוקנה ב-tafzoret_guess_screen.dart -
  // "late final" עם יוצר-תופעות-לוואי נגע בו לראשונה רק ב-dispose() עבור
  // תאים שמעולם לא היו "פעילים" (ראו build, _blink נקרא רק כש-widget.active),
  // וזה יצר AnimationController חדש (צריך context פעיל) בדיוק כש-ה-context
  // כבר לא פעיל. עכשיו נוצר רק לפי דרישה בתוך build().
  AnimationController? _blink;

  AnimationController _ensureBlink() {
    return _blink ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.letter != null;
    final borderRadius = BorderRadius.circular((widget.width * 0.3).clamp(6.0, 13.0));
    if (filled) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: borderRadius, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 4))]),
        alignment: Alignment.center,
        child: Text(widget.letter!, style: TextStyle(color: const Color(0xFF2A1740), fontSize: widget.fontSize, fontWeight: FontWeight.w900)),
      );
    }
    if (widget.active) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: const Color(0xFFFFD86B).withValues(alpha: 0.14), borderRadius: borderRadius, border: Border.all(color: const Color(0xFFFFD86B), width: 2)),
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: _ensureBlink(),
          child: Container(width: 2.2, height: widget.height * 0.42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFFFFD86B))),
        ),
      );
    }
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: borderRadius, border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.3)),
    );
  }
}

class _LogoFrame extends StatefulWidget {
  final String imagePath;
  final bool solved;
  final bool wrong;
  const _LogoFrame({required this.imagePath, required this.solved, required this.wrong});

  @override
  State<_LogoFrame> createState() => _LogoFrameState();
}

class _LogoFrameState extends State<_LogoFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        final dy = (_bob.value - 0.5) * 12;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        width: 186,
        height: 186,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(46),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE79A), Color(0xFFC98A32), Color(0xFFFFD86B)]),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 16))],
          border: widget.solved ? Border.all(color: const Color(0xFF34D399), width: 4) : (widget.wrong ? Border.all(color: const Color(0xFFFB7185), width: 4) : null),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(41), color: Colors.white),
          alignment: Alignment.center,
          child: Padding(padding: const EdgeInsets.all(24), child: Image.asset(widget.imagePath, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.09), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFFFD86B).withValues(alpha: 0.13), border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 15), const SizedBox(width: 5), Text('$coins', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w900))]),
    );
  }
}
