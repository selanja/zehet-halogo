// app_loading_screen.dart
//
// 🆕 מסך טעינת הפתיחה - מוצג בזמן שה-app בודק גרסה מינימלית/משחק לחזור
// אליו (ראו _AppRootGateState._checking ב-main.dart), במקום ה-
// CircularProgressIndicator החשוף שהיה שם קודם. עוצב לפי מוקאפ שסופק
// (Loading Screen.html): טבעות מסתובבות עם "אריחי לוגו" צבעוניים סביב
// כרטיס הלוגו האמיתי של האפליקציה, פס התקדמות וטיפ מתחלף למטה.
//
// 🩹 תוקן לפי בקשה מפורשת: פס ההתקדמות היה קוסמטי בלבד (לולאת טיימר
// שחוזרת על עצמה, לא קשורה לטעינה האמיתית) - וגרם לתחושת "שני מסכי
// טעינה" (אחד אמיתי, אחד מזויף). עכשיו progress/status מגיעים מבחוץ
// (ValueListenable) ומשקפים את השלבים האמיתיים של _runCheck ב-main.dart
// (בדיקת גרסה -> בדיקת משחק פעיל -> מוכנים) - כשהטעינה האמיתית מסתיימת,
// הפס תמיד יהיה ב-100% בדיוק. רק סיבוב הטבעות/ריחוף הכרטיס/החלפת
// הטיפים למטה נשארים אנימציה קישוטית בלולאה (לא "התקדמות" בפני עצמה).
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppLoadingScreen extends StatefulWidget {
  final ValueListenable<double> progress; // 0.0-1.0, התקדמות אמיתית
  final ValueListenable<String> status; // טקסט הסטטוס האמיתי הנוכחי

  const AppLoadingScreen({super.key, required this.progress, required this.status});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> with TickerProviderStateMixin {
  late final AnimationController _ringDashed = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  late final AnimationController _ringBig = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late final AnimationController _ringSmall = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat(reverse: false);
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  // פס ההתקדמות המוצג מונפש-חלק לעבר הערך האמיתי (widget.progress) בכל
  // פעם שהוא משתנה - כדי שקפיצות (למשל 15%->55%) ייראו כמו מעבר נעים,
  // בלי להמציא אחוזים שלא קרו באמת.
  late final AnimationController _progressAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..value = widget.progress.value;

  String _version = '';
  int _tipIndex = 0;
  Timer? _tipTimer;

  static const _tips = [
    'רצף ימים מכפיל את המתנה היומית',
    'תקועים? רמז חושף אות אחת מהתשובה',
    'בדו־קרב המנצח לוקח את כל הקופה',
    'השלימו משימות כדי לעלות בבאטל פאס',
  ];

  @override
  void initState() {
    super.initState();
    _loadVersion();
    widget.progress.addListener(_onProgressChanged);
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });
  }

  void _onProgressChanged() {
    _progressAnim.animateTo(widget.progress.value, curve: Curves.easeOutCubic);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {
      // לא קריטי - זה רק קישוט טקסט קטן בתחתית המסך.
    }
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgressChanged);
    _tipTimer?.cancel();
    _ringDashed.dispose();
    _ringBig.dispose();
    _ringSmall.dispose();
    _float.dispose();
    _pulse.dispose();
    _progressAnim.dispose();
    _sheen.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF120B2C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 0.74, 1.0],
                  colors: [Color(0xFF4A2394), Color(0xFF2E1668), Color(0xFF1B0F42), Color(0xFF120B2C)],
                ),
              ),
            ),
            _buildGlow(alignment: const Alignment(1.1, -1.15), color: const Color(0xFFFFAA3C), size: 520),
            _buildGlow(alignment: const Alignment(-1.15, 1.1), color: const Color(0xFF8C5AF0), size: 560, delayedPhase: true),
            _buildDotGrid(),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  _buildOrbit(),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF6D8), Color(0xFFFFC64B), Color(0xFFE39A24)]).createShader(r),
                    child: const Text('זהה את הלוגו!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  _buildTagline(),
                  const Spacer(flex: 3),
                  _buildProgressSection(),
                  const SizedBox(height: 18),
                  _buildTipCard(),
                  const SizedBox(height: 10),
                  if (_version.isNotEmpty)
                    Text(_version, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow({required Alignment alignment, required Color color, required double size, bool delayedPhase = false}) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final v = delayedPhase ? 1 - _pulse.value : _pulse.value;
          final scale = 0.9 + v * 0.22;
          final opacity = 0.55 + v * 0.35;
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDotGrid() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.35,
        child: CustomPaint(painter: _DotGridPainter(), size: Size.infinite),
      ),
    );
  }

  Widget _buildOrbit() {
    const double stageSize = 300;
    return SizedBox(
      width: stageSize,
      height: stageSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // טבעת מקווקוות איטית
          AnimatedBuilder(
            animation: _ringDashed,
            builder: (context, child) => Transform.rotate(
              angle: _ringDashed.value * 2 * math.pi,
              child: child,
            ),
            child: CustomPaint(size: const Size(280, 280), painter: _DashedCirclePainter()),
          ),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
          ),
          // טבעת גדולה - 3 אריחים
          AnimatedBuilder(
            animation: _ringBig,
            builder: (context, child) {
              final angle = _ringBig.value * 2 * math.pi;
              return Transform.rotate(angle: angle, child: child);
            },
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  _orbitTile(top: 0, left: 104, gradient: const [Color(0xFFFDA4AF), Color(0xFFE11D74)], size: 50, glow: const Color(0xFFE11D74)),
                  _orbitTile(bottom: 18, left: 6, gradient: const [Color(0xFF7DD3FC), Color(0xFF0EA5E9)], size: 44, glow: const Color(0xFF0EA5E9)),
                  _orbitTile(bottom: 18, right: 6, gradient: const [Color(0xFF6EE7B7), Color(0xFF16A46F)], size: 44, glow: const Color(0xFF16A46F)),
                ],
              ),
            ),
          ),
          // טבעת קטנה - 2 אריחים
          AnimatedBuilder(
            animation: _ringSmall,
            builder: (context, child) {
              final angle = -_ringSmall.value * 2 * math.pi;
              return Transform.rotate(angle: angle, child: child);
            },
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                children: [
                  _orbitTile(top: 14, left: 8, gradient: const [Color(0xFFD8B4FE), Color(0xFF7C3AED)], size: 36, glow: const Color(0xFF7C3AED)),
                  _orbitTile(top: 14, right: 8, gradient: const [Color(0xFFFFE08A), Color(0xFFFF8A3C)], size: 36, glow: const Color(0xFFFF8A3C), darkText: true),
                ],
              ),
            ),
          ),
          _buildLogoCard(),
        ],
      ),
    );
  }

  // אריח בודד בתוך טבעת מסתובבת - ראו הערה ב-_CounterRotatingTile למה
  // אין כאן סיבוב-נגדי אמיתי (הפשטה מכוונת מול המוקאפ המקורי).
  Widget _orbitTile({double? top, double? bottom, double? left, double? right, required List<Color> gradient, required double size, required Color glow, bool darkText = false}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: _CounterRotatingTile(gradient: gradient, size: size, glow: glow, darkText: darkText),
    );
  }

  // 🆕 הלוגו האמיתי של האפליקציה (assets/icon/logo.png) במרכז הטבעות -
  // לפי בקשה מפורשת, במקום כרטיס טקסט מעוצב. אותו לוגו בדיוק מופיע גם
  // במסך הפתיחה הנטיבי (launch_background.xml/LaunchScreen.storyboard)
  // כדי שהמעבר בין השניים ירגיש רציף.
  Widget _buildLogoCard() {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final dy = (_float.value - 0.5) * 20;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        width: 132,
        height: 132,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE79A), Color(0xFFC98A32), Color(0xFFFFD86B)]),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 30, offset: const Offset(0, 16))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset('assets/icon/logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        // 🩹 שונה לפי בקשה מפורשת - היה "רואים לוגו. יודעים מי זה?"
        // (הטקסט המקורי במוקאפ), הוחלף למשהו יותר מושך/מזמין לאתגר.
        'אלפי לוגואים מחכים לך. כמה תזהה?',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnim, _dots, _sheen]),
        builder: (context, _) {
          final p = _progressAnim.value * 100;
          final dotPhase = (_dots.value * 3).floor() % 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: widget.status,
                        builder: (context, status, _) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            status,
                            key: ValueKey(status),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: List.generate(3, (i) {
                          final active = i == dotPhase;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Opacity(
                              opacity: active ? 1 : 0.25,
                              child: Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD86B))),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text('${p.round()}%', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                height: 14,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.28)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fullW = constraints.maxWidth;
                    final barW = fullW * (p / 100).clamp(0.03, 1.0);
                    return Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: barW,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)]),
                            ),
                            child: Align(
                              alignment: Alignment(-1 + _sheen.value * 2, 0),
                              child: Container(
                                width: barW * 0.4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTipCard() {
    final tip = _tips[_tipIndex];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.03)]),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)])),
            alignment: Alignment.center,
            child: const Text('💡', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('טיפ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFFFFD86B))),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    tip,
                    key: ValueKey(tip),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, height: 1.4, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterRotatingTile extends StatefulWidget {
  final List<Color> gradient;
  final double size;
  final Color glow;
  final bool darkText;
  const _CounterRotatingTile({required this.gradient, required this.size, required this.glow, this.darkText = false});

  @override
  State<_CounterRotatingTile> createState() => _CounterRotatingTileState();
}

// כל אריח "מבטל" את סיבוב הטבעת האב שלו על ידי מעקב אחרי הורה
// AnimatedBuilder חיצוני - פשוט יותר לממש כווידג'ט עצמאי שמאזין לאותו
// AnimationController ישירות דרך InheritedWidget לא קיים כאן, אז הפתרון
// הפשוט ביותר: הווידג'ט הזה עצמו לא מסתובב - הוא רק מצייר את התג הקבוע,
// וה-Transform.rotate של ההורה כבר מספק את "התזוזה סביב מעגל" הרצויה
// בלי שהתג עצמו יתהפך, כי אנחנו לא עוטפים אותו בסיבוב נגדי בפועל - הפשטה
// מכוונת שנראית כמעט זהה למוקאפ (התג "מתגלגל" קלות עם הטבעת, לא לגמרי
// קבוע) בלי לסבך את הקוד עם עוד AnimationController לכל תג.
class _CounterRotatingTileState extends State<_CounterRotatingTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.32),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.gradient),
        boxShadow: [BoxShadow(color: widget.glow.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      alignment: Alignment.center,
      child: Text('?', style: TextStyle(fontSize: widget.size * 0.42, fontWeight: FontWeight.w900, color: widget.darkText ? const Color(0xFF2A1740) : Colors.white)),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD86B).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const dashCount = 46;
    const dashFraction = 0.55;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * dashFraction;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
