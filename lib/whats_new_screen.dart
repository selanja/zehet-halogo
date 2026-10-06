// whats_new_screen.dart
//
// 🆕 מסך "מה חדש בגרסה" - מוצג פעם אחת בלבד למשתמש קיים (לא למשתמש חדש
// לגמרי - הוא כבר מקבל את מסך "ברוך הבא") בכניסה הראשונה אחרי עדכון
// לגרסה חדשה. עוצב בדיוק לפי מוקאפ שסופק (Whats New.html, שעוצב ב-
// Claude Design לפי בריף שהכנתי): אותו רקע/גרדיאנט/זוהרים כמו מסך
// הטעינה (app_loading_screen.dart), כרטיס תכונה "מודגש" ראשון (עם תג
// "חדש" וברק נע), ועוד 3 כרטיסי תכונה רגילים, וכפתור "בואו נתחיל" קבוע
// למטה.
//
// ⚠️ הלוגיקה של "מתי להציג את זה בכלל" (שמירת הגרסה האחרונה שנצפתה,
// השוואה לגרסה הנוכחית) נמצאת ב-main_menu_screen.dart - הקובץ הזה הוא
// רק התצוגה עצמה, לא מחליט מתי להופיע.
import 'package:flutter/material.dart';

class WhatsNewScreen extends StatefulWidget {
  final String version;
  final VoidCallback onContinue;

  const WhatsNewScreen({super.key, required this.version, required this.onContinue});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _FeatureData {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> iconGradient;
  final Color glow;
  final bool featured;
  final Widget? trailing;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconGradient,
    required this.glow,
    this.featured = false,
    this.trailing,
  });
}

class _WhatsNewScreenState extends State<WhatsNewScreen> with TickerProviderStateMixin {
  // 🆕 אנימציית כניסה אחת (1.3s) שמניעה את כל ה-stagger (כותרת + כל
  // כרטיס בתורו) דרך Interval, בדיוק כמו העיכובים השונים במוקאפ
  // (wn-pop/wn-up/wn-icon עם delay עולה לכל אלמנט).
  late final AnimationController _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat();
  bool _pressed = false;

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _sheen.dispose();
    super.dispose();
  }

  Animation<double> _fadeIn(double start, double end) => CurvedAnimation(parent: _entrance, curve: Interval(start, end, curve: Curves.easeOut));

  List<_FeatureData> get _features => const [
        _FeatureData(
          icon: '🏆',
          title: 'סדרת דו-קרב',
          subtitle: 'דו-קרב חדש: הטוב מ-3! אותו יריב, עד 3 סיבובים, ובונוס מטבעות שמן לניצחון בסדרה',
          iconGradient: [Color(0xFFFFE08A), Color(0xFFFF8A3C)],
          glow: Color(0xFFFF8A3C),
          featured: true,
        ),
        _FeatureData(
          icon: '🗺️',
          title: 'נוספו רמות חדשות',
          subtitle: 'עוד שלבים ועוד לוגואים לזהות, מחכים לכם במסך השלבים',
          iconGradient: [Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
          glow: Color(0xFF0EA5E9),
        ),
        _FeatureData(
          icon: '⭐',
          title: 'רמות קושי 1-5',
          subtitle: 'כל עולם מקבל דירוג קושי — וככל שההימור בדו-קרב גבוה יותר, כך גם רמת הלוגואים',
          iconGradient: [Color(0xFFD8B4FE), Color(0xFF7C3AED)],
          glow: Color(0xFF7C3AED),
          trailing: _DifficultyBars(),
        ),
        _FeatureData(
          icon: '🎁',
          title: 'בונוס הזמנת חברים גדול יותר',
          subtitle: 'עכשיו מקבלים 75 מטבעות (במקום 30) על כל חבר שמצטרף דרך הקוד שלכם',
          iconGradient: [Color(0xFF6EE7B7), Color(0xFF16A46F)],
          glow: Color(0xFF16A46F),
        ),
      ];

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
            IgnorePointer(child: Opacity(opacity: 0.35, child: CustomPaint(painter: _DotGridPainter(), size: Size.infinite))),
            SafeArea(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 26),
                      for (int i = 0; i < _features.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _buildFeatureCard(_features[i], index: i),
                      ],
                    ],
                  ),
                  _buildBottomButton(),
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

  Widget _buildHeader() {
    final fade = _fadeIn(0.0, 0.25);
    return AnimatedBuilder(
      animation: fade,
      builder: (context, child) => Opacity(
        opacity: fade.value,
        child: Transform.scale(scale: 0.85 + fade.value * 0.15, child: child),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.45)),
              color: const Color(0xFFFFD86B).withValues(alpha: 0.13),
            ),
            child: Text('✨ גרסה ${widget.version}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFFFFD86B))),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF6D8), Color(0xFFFFD86B), Color(0xFFFF8A3C)]).createShader(r),
            child: const Text('עדכנו בשבילכם!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, height: 1.1, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text('מה חדש בגרסה ${widget.version}?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Colors.white.withValues(alpha: 0.68))),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureData f, {required int index}) {
    final start = 0.3 + index * 0.08;
    final end = (start + 0.35).clamp(0.0, 1.0);
    final slide = _fadeIn(start, end);
    final iconPop = _fadeIn(start + 0.08, (start + 0.08 + 0.3).clamp(0.0, 1.0));

    final card = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: f.featured ? 18 : 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(f.featured ? 24 : 22),
        border: Border.all(color: f.featured ? const Color(0xFFFFD86B).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.12), width: f.featured ? 1.5 : 1),
        gradient: f.featured
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFFFD86B).withValues(alpha: 0.20), const Color(0xFFFF8A3C).withValues(alpha: 0.06)])
            : null,
        color: f.featured ? null : Colors.white.withValues(alpha: 0.08),
        boxShadow: f.featured ? [BoxShadow(color: const Color(0xFFFF963C).withValues(alpha: 0.18), blurRadius: 34, offset: const Offset(0, 14))] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (f.featured)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (context, child) {
                    final t = _sheen.value;
                    return Align(
                      alignment: Alignment(-1.6 + t * 5.6, 0),
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          width: 50,
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0)])),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (f.featured)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF8A3C)])),
                child: const Text('חדש', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF2A1740))),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: f.featured ? 8 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: iconPop,
                  builder: (context, child) => Transform.scale(scale: iconPop.value, child: child),
                  child: Container(
                    width: f.featured ? 58 : 50,
                    height: f.featured ? 58 : 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(f.featured ? 18 : 16),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: f.iconGradient),
                      boxShadow: [BoxShadow(color: f.glow.withValues(alpha: 0.4), blurRadius: f.featured ? 22 : 18, offset: const Offset(0, 8))],
                    ),
                    alignment: Alignment.center,
                    child: Text(f.icon, style: TextStyle(fontSize: f.featured ? 28 : 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title, textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.w900, fontSize: f.featured ? 18 : 16, color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(f.subtitle, textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.w500, fontSize: f.featured ? 13.5 : 13, height: 1.5, color: Colors.white.withValues(alpha: f.featured ? 0.82 : 0.72))),
                      if (f.trailing != null) ...[const SizedBox(height: 9), f.trailing!],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: slide,
      builder: (context, child) => Opacity(
        opacity: slide.value,
        child: Transform.translate(offset: Offset(0, (1 - slide.value) * 28), child: child),
      ),
      child: card,
    );
  }

  Widget _buildBottomButton() {
    final fade = _fadeIn(0.75, 1.0);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: fade,
        builder: (context, child) => IgnorePointer(ignoring: fade.value < 0.3, child: Opacity(opacity: fade.value, child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.38, 1.0],
              colors: [Color(0x00120B2C), Color(0xEB120B2C), Color(0xFF120B2C)],
            ),
          ),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onContinue,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              height: 58,
              transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)]),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFC2600E), offset: Offset(0, _pressed ? 2 : 6)),
                  if (!_pressed) BoxShadow(color: const Color(0xFFFF8A3C).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 16)),
                ],
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('בואו נתחיל', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2A1740))),
                  SizedBox(width: 8),
                  Text('←', style: TextStyle(fontSize: 16, color: Color(0xFF2A1740))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🆕 5 הפסים הצבעוניים (ירוק->אדום) שמייצגים את טווח רמות הקושי 1-5,
// בדיוק כמו במוקאפ, מתחת לטקסט בכרטיס "רמות קושי 1-5".
class _DifficultyBars extends StatelessWidget {
  const _DifficultyBars();

  static const _colors = [Color(0xFF6EE7B7), Color(0xFFA3E635), Color(0xFFFFD86B), Color(0xFFFFB24D), Color(0xFFFB7185)];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (final c in _colors) ...[
          Container(width: 22, height: 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
          if (c != _colors.last) const SizedBox(width: 5),
        ],
      ],
    );
  }
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
