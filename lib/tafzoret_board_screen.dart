// tafzoret_board_screen.dart
//
// לוח 30 הלוגואים של עולם בודד במצב "תפזורת" - עוצב בדיוק לפי מוקאפ
// העיצוב (Puzzle Mode.dc.html, מסכים 02+05: לוח העולם + מסך "עולם הושלם").
// כרטיס התקדמות עם פיל "🎁 +40 / +400 / +250" אמיתי, רשת 5 עמודות עם
// 3 מצבי תא (פתור מוצג בבירור / פתוח עם "רמז רפאים" מעומעם ומטושטש /
// עדיין לא פתוח), ומסך חגיגה מלא-מסך עם קונפטי וטבעת מסתובבת כש-25/30
// נפתרים.
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'tafzoret_data.dart';
import 'tafzoret_service.dart';
import 'tafzoret_guess_screen.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'app_icons.dart';

class TafzoretBoardScreen extends StatefulWidget {
  final int world;
  const TafzoretBoardScreen({super.key, required this.world});

  @override
  State<TafzoretBoardScreen> createState() => _TafzoretBoardScreenState();
}

class _TafzoretBoardScreenState extends State<TafzoretBoardScreen> {
  Set<String> _solvedIds = {};
  bool _loading = true;
  bool _showCompleteOverlay = false;

  List<TafzoretLogo> get _logos => tafzoretWorlds[widget.world] ?? [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final solved = await TafzoretService.solvedIdsForWorld(widget.world);
    if (!mounted) return;
    setState(() {
      _solvedIds = solved;
      _loading = false;
    });
  }

  Future<void> _openLogo(int index) async {
    final logo = _logos[index];
    if (_solvedIds.contains(logo.id)) return;
    AudioManager.playClick();
    // 🐛 תוקן: מצב תפזורת מעולם לא חיבר לשום פרסומת - "נכנסים למשחק
    // בפועל" כמו בכל מצב אחר.
    AdsManager.recordGameEntered();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TafzoretGuessScreen(
          logo: logo,
          world: widget.world,
          indexInWorld: index + 1,
          totalInWorld: _logos.length,
        ),
      ),
    );
    if (result != true) return;
    // 🐛 תוקן: לוגו שנפתר בתפזורת מעולם לא נספר לקראת פרסומת ה-
    // Interstitial (כל 7 שלבים), בדיוק כמו לוגו שנפתר במצב הרגיל.
    AdsManager.onLevelSolved();
    final res = await TafzoretService.markSolved(widget.world, logo.id);
    if (!mounted) return;
    setState(() => _solvedIds = {..._solvedIds, logo.id});
    if (res.justFullyCompleted) {
      setState(() => _showCompleteOverlay = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _logos.length;
    final solved = _solvedIds.length;
    final remainingForPass = (tafzoretPassThreshold - solved).clamp(0, tafzoretPassThreshold);
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
                    stops: [0.0, 0.4, 1.0],
                    colors: [Color(0xFF3A1D7A), Color(0xFF1F1150), Color(0xFF120B2C)],
                  ),
                ),
              ),
            ),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B)))
            else
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                color: Colors.white.withValues(alpha: 0.09),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('עולם ${widget.world}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: _ProgressCard(solved: solved, total: total, remainingForPass: remainingForPass),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                        itemCount: total,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final logo = _logos[index];
                          final isSolved = _solvedIds.contains(logo.id);
                          return _LogoTile(logo: logo, solved: isSolved, onTap: () => _openLogo(index));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (_showCompleteOverlay)
              _WorldCompleteOverlay(
                world: widget.world,
                onClose: () {
                  setState(() => _showCompleteOverlay = false);
                  Navigator.pop(context, true);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// פיל פרס העולם - GiftIcon (PNG קבוע) + CoinIcon, לא אימוג'י (ראו הערת הקובץ).
class _WorldRewardSummary extends StatelessWidget {
  const _WorldRewardSummary();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GiftIcon(size: 14),
        const SizedBox(width: 4),
        Text('+$tafzoretWorldCoinsReward', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(width: 3),
        const CoinIcon(size: 12),
        const SizedBox(width: 6),
        const Text('·', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 11)),
        const SizedBox(width: 6),
        Text('+$tafzoretWorldXpReward XP', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        const Text('·', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 11)),
        const SizedBox(width: 6),
        Text('+$tafzoretWorldBattlePassPoints', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(width: 3),
        const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFFD86B), size: 12),
      ],
    );
  }
}

/// גרסת-טקסט בלבד של פרס העולם (בלי GiftIcon - מוצג בנפרד לצידה במסך החגיגה).
class _WorldRewardSummaryText extends StatelessWidget {
  const _WorldRewardSummaryText();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('+$tafzoretWorldCoinsReward', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 3),
        const CoinIcon(size: 14),
        const SizedBox(width: 8),
        const Text('·', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 13)),
        const SizedBox(width: 8),
        Text('+$tafzoretWorldXpReward XP', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        const Text('·', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 13)),
        const SizedBox(width: 8),
        Text('+$tafzoretWorldBattlePassPoints', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 3),
        const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFFD86B), size: 14),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int solved;
  final int total;
  final int remainingForPass;
  const _ProgressCard({required this.solved, required this.total, required this.remainingForPass});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : solved / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$solved מתוך $total נפתרו', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFFFD86B).withValues(alpha: 0.14),
                ),
                child: const _WorldRewardSummary(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 10, color: Colors.white.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    height: 10,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remainingForPass > 0 ? 'עוד $remainingForPass לוגואים לעולם הבא' : 'עברת את הסף! אפשר להמשיך לעולם הבא',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  final TafzoretLogo logo;
  final bool solved;
  final VoidCallback onTap;
  const _LogoTile({required this.logo, required this.solved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: solved ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: solved ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.14),
            width: solved ? 2 : 1,
          ),
          boxShadow: solved
              ? [BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: solved
                  ? Image.asset(logo.imagePath, fit: BoxFit.contain)
                  : ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 0.35, 0,
                        ]),
                        child: Image.asset(logo.imagePath, fit: BoxFit.contain),
                      ),
                    ),
            ),
            if (solved)
              const Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorldCompleteOverlay extends StatefulWidget {
  final int world;
  final VoidCallback onClose;
  const _WorldCompleteOverlay({required this.world, required this.onClose});

  @override
  State<_WorldCompleteOverlay> createState() => _WorldCompleteOverlayState();
}

class _WorldCompleteOverlayState extends State<_WorldCompleteOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final List<_ConfettiPiece> _pieces = List.generate(28, (i) => _ConfettiPiece(Random(i)));

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Stack(
          children: [
            ...List.generate(_pieces.length, (i) {
              final p = _pieces[i];
              return AnimatedBuilder(
                animation: _ring,
                builder: (context, child) {
                  final t = (_ring.value + p.phase) % 1.0;
                  final size = MediaQuery.of(context).size;
                  final dy = t * size.height;
                  final dx = p.x * size.width + sin(t * 6.28 * 2) * 18;
                  return Positioned(
                    left: dx,
                    top: dy,
                    child: Opacity(
                      opacity: (1 - t).clamp(0, 1),
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  );
                },
              );
            }),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ring,
                          builder: (context, child) => Transform.rotate(
                            angle: _ring.value * 6.28,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(colors: [
                                  Color(0xFFFFE08A),
                                  Color(0xFFFF9F45),
                                  Color(0xFFFFE08A),
                                ]),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 128,
                          height: 128,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1F1150)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD86B), size: 56),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('עולם ${widget.world} הושלם!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [GiftIcon(size: 18), SizedBox(width: 6), _WorldRewardSummaryText()],
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)]),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 5))],
                      ),
                      child: const Text('מעולה!', style: TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double phase;
  final double size;
  final Color color;
  _ConfettiPiece(Random r)
      : x = r.nextDouble(),
        phase = r.nextDouble(),
        size = 5 + r.nextDouble() * 6,
        color = [
          const Color(0xFFFFD86B),
          const Color(0xFFFB7185),
          const Color(0xFF34D399),
          const Color(0xFF8B5CF6),
          const Color(0xFF60A5FA),
        ][r.nextInt(5)];
}
