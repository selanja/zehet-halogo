// tafzoret_guess_screen.dart
//
// מסך ניחוש ללוגו בודד במצב "תפזורת" - עוצב לפי מוקאפ העיצוב (Puzzle
// Mode.dc.html, מסך 03 · ניחוש הלוגו): מסגרת לוגו מוזהבת עם ריחוף עדין,
// תאי אות עם קרסור מהבהב בעמדה הפעילה, רמז וכפתור "לוגו הבא" שחוזר ללוח
// בלי לפתור.
//
// 🩹 הניחוש בפועל (בדיקה אוטומטית כשמתמלא, בלי כפתור "בדיקה" נפרד) ותפריט
// הרמזים (רמז-אות ב-20 מטבעות / פתרון מילה שלמה ב-60 מטבעות) מעותקים
// בדיוק מהמשחק הראשי (logo_level_screen.dart: _checkAnswer/_showHintMenu)
// לפי בקשה מפורשת של המשתמש - "אותו הדבר שיהיה כמו ברגיל".
//
// 🩹 "אין מספיק מטבעות" משתמש בדיאלוג המשותף (not_enough_coins_dialog.dart,
// אותו אחד שכבר בשימוש בדו-קרב/מרוץ/טורנירים) ולא בגיליון תחתון מותאם-
// אישית - ניסיון קודם עם גיליון (showModalBottomSheet שנשאר פתוח מתחת
// למסך החנות שנדחף מעליו) גרם למסך לגמרי להיתקע (לא קריסה - קפוא
// ולא מגיב) כשלוחצים "בית" בתוך החנות, כי Navigator.popUntil(isFirst)
// (ראו AppBottomNav._goHome) מנסה להסיר בבת אחת גם מסך-מלא (MaterialPageRoute)
// וגם גיליון-תחתון (modal bottom sheet route) שעדיין פתוח מתחתיו - משהו
// ב-Flutter לא מתמודד עם זה טוב. הדיאלוג המשותף סוגר את עצמו *לפני*
// שדוחפים את מסך החנות (לא אחרי כמו שהיה בגיליון) - בדיוק הדפוס שכבר
// מוכח כבטוח בכל שאר המסכים באפליקציה.
//
// 🩹 כיוון טקסט לכל חידה נקבע לפי האם התשובה בפועל מכילה אותיות לטיניות
// (isEnglish = RegExp([a-zA-Z]) על התשובה עצמה), לא לפי שפת האפליקציה -
// כמו במשחק הראשי. חלק מהמותגים (LG, WAZE, SNAPCHAT...) נשארים בלטינית
// גם כשהאפליקציה בעברית, ובלי זה הם הוצגו הפוך תחת ה-RTL הכללי של המסך.
//
// 🩹 בלי אימוג'י (🪙/💡/⏭ וכו') בשום טקסט מוצג - אותה בעיית "ריבוע ריק"
// שתועדה כבר כמה פעמים באפליקציה (ראו app_icons.dart) - רק אייקוני
// Material וקטוריים (מוכחים כעובדים בכל שאר האפליקציה) ו-CoinIcon
// (תמונת PNG קבועה) למטבעות.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tafzoret_data.dart';
import 'audio_manager.dart';
import 'locale_controller.dart';
import 'app_icons.dart';
import 'not_enough_coins_dialog.dart';

const int tafzoretLetterHintCost = 20;
const int tafzoretWordHintCost = 60;

class TafzoretGuessScreen extends StatefulWidget {
  final TafzoretLogo logo;
  final int world;
  final int indexInWorld; // 1-based, לתצוגת "לוגו X מתוך 30"
  final int totalInWorld;

  const TafzoretGuessScreen({
    super.key,
    required this.logo,
    required this.world,
    required this.indexInWorld,
    required this.totalInWorld,
  });

  @override
  State<TafzoretGuessScreen> createState() => _TafzoretGuessScreenState();
}

class _TafzoretGuessScreenState extends State<TafzoretGuessScreen> {
  List<String?> _slots = [];
  final Set<int> _pressedKeyIndices = {};
  final List<int> _fillOrder = []; // סדר מילוי התאים - לצורך מחיקה (האחרון שמולא)
  final Set<int> _hintedSlots = {}; // תאים שנחשפו ע"י רמז - נעולים, מחיקה מדלגת עליהם
  bool _solved = false;
  bool _wrongShake = false;
  int _coins = 0;

  String get _answer => widget.logo.answerFor(localeController.isHebrew).replaceAll(' ', '');
  List<String> get _keyboard => widget.logo.keyboardFor(localeController.isHebrew);
  // 🩹 כיוון לפי תוכן התשובה בפועל, לא לפי שפת האפליקציה - ראו הערת הקובץ.
  bool get _isEnglish => RegExp(r'[a-zA-Z]').hasMatch(_answer);
  bool get _allFilled => _slots.every((s) => s != null);

  @override
  void initState() {
    super.initState();
    _slots = List<String?>.filled(_answer.length, null);
    _loadCoins();
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
    // האחרון שמולא, שלא הגיע מרמז (רמזים נעולים - אי אפשר למחוק אותם)
    for (int i = _fillOrder.length - 1; i >= 0; i--) {
      final slot = _fillOrder[i];
      if (_hintedSlots.contains(slot)) continue;
      AudioManager.playClick();
      setState(() {
        _slots[slot] = null;
        _fillOrder.removeAt(i);
        // משחררים את כל מקשי המקלדת ובונים מחדש לפי מה שעדיין מופיע בתאים
        // בפועל - פשוט יותר ופחות שביר ממעקב slot->key נפרד, ומדויק באותה מידה.
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

  Future<void> _revealLetterHint() async {
    if (_solved) return;
    final emptySlots = <int>[];
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) emptySlots.add(i);
    }
    if (emptySlots.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final fresh = prefs.getInt('coins') ?? _coins;
    if (fresh < tafzoretLetterHintCost) {
      if (mounted) setState(() => _coins = fresh);
      // 🩹 הוחלף מגיליון תחתון מותאם-אישית לדיאלוג המשותף (ראו ההערה
      // הגדולה למטה ליד המקום שבו _showNotEnoughCoinsSheet הוסר) - תקוע
      // (לא קריסה, אבל תקוע לגמרי) כשלוחצים "בית" בתוך החנות.
      if (mounted) {
        showNotEnoughCoinsDialog(context, cost: tafzoretLetterHintCost, coins: fresh, onReturnedFromShop: _revealLetterHint);
      }
      return;
    }
    await prefs.setInt('coins', fresh - tafzoretLetterHintCost);
    AudioManager.playClick();
    final slot = emptySlots[Random().nextInt(emptySlots.length)];
    final letter = _answer[slot];
    setState(() {
      _coins = fresh - tafzoretLetterHintCost;
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
    if (fresh < tafzoretWordHintCost) {
      if (mounted) setState(() => _coins = fresh);
      if (mounted) {
        showNotEnoughCoinsDialog(context, cost: tafzoretWordHintCost, coins: fresh, onReturnedFromShop: _revealWordHint);
      }
      return;
    }
    await prefs.setInt('coins', fresh - tafzoretWordHintCost);
    AudioManager.playClick();
    setState(() {
      _coins = fresh - tafzoretWordHintCost;
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
                    price: tafzoretLetterHintCost,
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
                    price: tafzoretWordHintCost,
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
      setState(() => _solved = true);
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
            Positioned(
              top: 90,
              left: MediaQuery.of(context).size.width / 2 - 170,
              child: _GlowBlob(size: 340, color: const Color(0xFFFFB24D), opacity: 0.3),
            ),
            Positioned.fill(child: _DotGrid()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Row(
                      children: [
                        _RoundIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context, false)),
                        Expanded(
                          child: Column(
                            children: [
                              Text('עולם ${widget.world}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                'לוגו ${widget.indexInWorld} מתוך ${widget.totalInWorld}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        _CoinPill(coins: _coins),
                      ],
                    ),
                  ),
                  // 🩹 כל התוכן שבין הכותרת למקלדת (לוגו/תאים/שבבי פעולה) בתוך
                  // Expanded+SingleChildScrollView, כדי שהמקלדת עצמה - למטה,
                  // מחוץ ל-Expanded - תמיד תקבל את הגובה שהיא צריכה ולא
                  // תיחתך על המסך. בלי זה, לוגואים עם מקלדת ארוכה מהרגיל
                  // (למשל שמות קבוצות NFL/חברות תעופה, 20-26 אותיות) דחפו
                  // את הטור הכולל גבוה מגובה המסך, וגרמו לשורת האותיות
                  // האחרונה במקלדת (ולפעמים לריפוד התחתון שלה) להיחתך.
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _LogoFrame(imagePath: widget.logo.imagePath, solved: _solved, wrong: _wrongShake),
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
                              _ActionChip(icon: Icons.skip_next_rounded, label: 'לוגו הבא', color: Colors.white.withValues(alpha: 0.5), onTap: () => Navigator.pop(context, false)),
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
    );
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

  // 🩹 גודל תא דינמי לפי רוחב המסך בפועל, בדיוק כמו ב-_buildInputArea של
  // logo_level_screen.dart - בלי זה מילים ארוכות (הברוקרים/Logo Pass וכו')
  // "ברחו" מהמסך עם תאים ברוחב קבוע (44px). totalLetters מחושב על פני
  // התשובה כולה (לא לכל מילה בנפרד) כדי שכל התאים יצטמצמו באופן אחיד.
  Widget _buildSlots() {
    return LayoutBuilder(builder: (context, constraints) {
      const double margin = 4;
      const double maxTileWidth = 35;
      const double minTileWidth = 20;
      final int totalLetters = _answer.length;
      final double idealWidth = totalLetters > 0 ? (constraints.maxWidth - (totalLetters * margin)) / totalLetters : maxTileWidth;
      final double tileWidth = idealWidth.clamp(minTileWidth, maxTileWidth);
      final double tileHeight = tileWidth * (45 / 35);
      final double fontSize = (tileWidth * 0.6).clamp(13.0, 22.0);

      int globalIndex = 0;
      final words = widget.logo.answerFor(localeController.isHebrew).split(' ');
      final activeIndex = _slots.indexWhere((s) => s == null);
      final rows = <Widget>[];
      for (final word in words) {
        final letters = <Widget>[];
        for (int i = 0; i < word.length; i++) {
          final slotIndex = globalIndex;
          final filled = slotIndex < _slots.length ? _slots[slotIndex] : null;
          final isActive = slotIndex == activeIndex;
          globalIndex++;
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.14),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.55)]),
                borderRadius: BorderRadius.circular(14),
              ),
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
                children: [
                  Text("$price", style: const TextStyle(color: Color(0xFF2A1740), fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(width: 3),
                  const CoinIcon(size: 15),
                ],
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
  // 🩹 תוקנה קריסה אמיתית: "late final" עם יוצר-תופעות-לוואי (יוצר
  // AnimationController) מתאתחל רק במגע הראשון - ותא-אות שמעולם לא היה
  // "פעיל" (ראו build, _blink נקרא רק כש-widget.active) אף פעם לא נוגע
  // בו, עד dispose() שקורא ל-_blink.dispose() - וזה בדיוק המגע הראשון!
  // זה מפעיל את יצירת ה-AnimationController (צריך vsync/ticker תקין) בדיוק
  // ברגע שה-context כבר לא פעיל (בתהליך dispose) - "Looking up a
  // deactivated widget's ancestor is unsafe". עכשיו נוצר רק לפי דרישה
  // בתוך build() (שם ה-context תמיד פעיל), ו-dispose בודק null לפני
  // שהוא מנסה לסגור - גם בטוח וגם לא יוצר טיקר מיותר לתאים שלעולם לא
  // יהבהבו.
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: borderRadius,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(widget.letter!, style: TextStyle(color: const Color(0xFF2A1740), fontSize: widget.fontSize, fontWeight: FontWeight.w900)),
      );
    }
    if (widget.active) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD86B).withValues(alpha: 0.14),
          borderRadius: borderRadius,
          border: Border.all(color: const Color(0xFFFFD86B), width: 2),
        ),
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: _ensureBlink(),
          child: Container(
            width: 2.2,
            height: widget.height * 0.42,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFFFFD86B)),
          ),
        ),
      );
    }
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.3),
      ),
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
          border: widget.solved
              ? Border.all(color: const Color(0xFF34D399), width: 4)
              : (widget.wrong ? Border.all(color: const Color(0xFFFB7185), width: 4) : null),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(41), color: Colors.white),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Image.asset(widget.imagePath, fit: BoxFit.contain),
          ),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.09),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFFFD86B).withValues(alpha: 0.13),
        border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 15),
          const SizedBox(width: 5),
          Text('$coins', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowBlob({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.35,
      child: CustomPaint(painter: _DotGridPainter()),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    const step = 24.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
