// tafzoret_worlds_screen.dart
//
// רשימת 23 העולמות של מצב "תפזורת" - עוצב בדיוק לפי מוקאפ העיצוב
// (Puzzle Mode.dc.html, מסכים 01+04: רשימת העולמות + מסך דילוג בתשלום).
// כרטיס "המשך" עליון עם טבעת התקדמות קונית לעולם הפתוח האחרון, רשימת
// שורות ב-3 מצבים (פתור/פתוח/נעול) עם הסטייל המדויק לכל אחד, ו-bottom
// sheet לדילוג בתשלום (₪2.90) על עולם נעול.
import 'package:flutter/material.dart';
import 'dart:math';
import 'tafzoret_data.dart';
import 'tafzoret_service.dart';
import 'tafzoret_board_screen.dart';
import 'iap_manager.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'app_notification.dart';

class TafzoretWorldsScreen extends StatefulWidget {
  const TafzoretWorldsScreen({super.key});

  @override
  State<TafzoretWorldsScreen> createState() => _TafzoretWorldsScreenState();
}

class _TafzoretWorldsScreenState extends State<TafzoretWorldsScreen> {
  int _unlockedWorld = 1;
  final Map<int, int> _solvedCounts = {};
  final Set<int> _completedWorlds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // 🐛 תוקן: מסך רשימת העולמות של תפזורת מעולם לא נספר כ"גלישה".
    AdsManager.recordBrowseNavigation();
  }

  Future<void> _load() async {
    final unlocked = await TafzoretService.unlockedWorld();
    final counts = <int, int>{};
    final completed = <int>{};
    for (int w = 1; w <= tafzoretWorldCount; w++) {
      final solved = await TafzoretService.solvedIdsForWorld(w);
      counts[w] = solved.length;
      if (await TafzoretService.isWorldFullyCompleted(w)) completed.add(w);
    }
    if (!mounted) return;
    setState(() {
      _unlockedWorld = unlocked;
      _solvedCounts.addAll(counts);
      _completedWorlds.addAll(completed);
      _loading = false;
    });
  }

  Future<void> _openWorld(int world) async {
    AudioManager.playClick();
    await Navigator.push(context, MaterialPageRoute(builder: (context) => TafzoretBoardScreen(world: world)));
    _load();
  }

  Future<void> _showUnlockSheet(int world) async {
    AudioManager.playClick();
    final bought = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UnlockWorldSheet(world: world),
    );
    if (bought == true) _load();
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
                    stops: [0.0, 0.35, 1.0],
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
                          const Text('תפזורת', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _ContinueCard(
                            world: _unlockedWorld,
                            solved: _solvedCounts[_unlockedWorld] ?? 0,
                            total: tafzoretWorlds[_unlockedWorld]?.length ?? tafzoretLogosPerWorld,
                            onTap: () => _openWorld(_unlockedWorld),
                          ),
                          const SizedBox(height: 22),
                          ...List.generate(tafzoretWorldCount, (i) {
                            final world = i + 1;
                            final isCompleted = _completedWorlds.contains(world);
                            final isUnlocked = world <= _unlockedWorld;
                            final isNext = world == _unlockedWorld + 1;
                            final solved = _solvedCounts[world] ?? 0;
                            final total = tafzoretWorlds[world]?.length ?? tafzoretLogosPerWorld;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _WorldRow(
                                world: world,
                                solved: solved,
                                total: total,
                                completed: isCompleted,
                                unlocked: isUnlocked,
                                next: isNext,
                                onTap: isUnlocked ? () => _openWorld(world) : () => _showUnlockSheet(world),
                              ),
                            );
                          }),
                        ],
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

class _ContinueCard extends StatelessWidget {
  final int world;
  final int solved;
  final int total;
  final VoidCallback onTap;
  const _ContinueCard({required this.world, required this.solved, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : solved / total;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF7A59), Color(0xFF8B2FD1)]),
          boxShadow: [BoxShadow(color: const Color(0xFF8B2FD1).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size(68, 68), painter: _ConicRingPainter(progress: progress)),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2A1740)),
                    alignment: Alignment.center,
                    child: Text('$world', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('המשך לשחק', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('עולם $world · $solved מתוך $total נפתרו', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}

class _ConicRingPainter extends CustomPainter {
  final double progress;
  _ConicRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant _ConicRingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _WorldRow extends StatelessWidget {
  final int world;
  final int solved;
  final int total;
  final bool completed;
  final bool unlocked;
  final bool next;
  final VoidCallback? onTap;
  const _WorldRow({
    required this.world,
    required this.solved,
    required this.total,
    required this.completed,
    required this.unlocked,
    required this.next,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked;
    final progress = total == 0 ? 0.0 : (solved / total).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: completed
              ? const Color(0xFF34D399).withValues(alpha: 0.12)
              : (locked ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.08)),
          border: Border.all(
            color: completed
                ? const Color(0xFF34D399).withValues(alpha: 0.4)
                : (next ? const Color(0xFFFFD86B).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
            width: next ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? const Color(0xFF34D399).withValues(alpha: 0.22)
                    : (locked ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFD86B).withValues(alpha: 0.16)),
              ),
              alignment: Alignment.center,
              child: completed
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20)
                  : (locked
                      ? Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.35), size: 18)
                      : Text('$world', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 16, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'עולם $world',
                    style: TextStyle(
                      color: locked ? Colors.white.withValues(alpha: 0.4) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (locked) ...[
                    Text(
                      'לעבור לעולם הבא יש להשלים את העולם הקודם',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'או לחצו לדילוג בתשלום · ₪2.90',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    Text('$solved מתוך $total נפתרו', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: [
                          Container(height: 5, color: Colors.white.withValues(alpha: 0.08)),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: completed
                                    ? const [Color(0xFF34D399), Color(0xFF10B981)]
                                    : const [Color(0xFFFFE08A), Color(0xFFFF9F45)]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (!locked) Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _UnlockWorldSheet extends StatefulWidget {
  final int world;
  const _UnlockWorldSheet({required this.world});

  @override
  State<_UnlockWorldSheet> createState() => _UnlockWorldSheetState();
}

class _UnlockWorldSheetState extends State<_UnlockWorldSheet> {
  bool _buying = false;

  Future<void> _buy() async {
    if (_buying) return;
    setState(() => _buying = true);
    await TafzoretService.setPendingUnlock(widget.world);
    final ok = await IapManager.buy(IapManager.unlockTafzoretWorldId);
    if (!mounted) return;
    setState(() => _buying = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      AppNotification.show(context, 'הרכישה לא הושלמה', type: AppNotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1F1150),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 18),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)]),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.lock_open_rounded, color: Color(0xFF2A1740), size: 30),
            ),
            const SizedBox(height: 16),
            Text('לדלג לעולם ${widget.world}?', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'תוכל לשחק בעולם הזה בלי להשלים את העולם הקודם',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _buy,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)]),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 5))],
                ),
                alignment: Alignment.center,
                child: _buying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                    : const Text('פתח עכשיו · ₪2.90', style: TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Text('לא עכשיו', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
