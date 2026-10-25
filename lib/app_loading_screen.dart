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
import 'l10n/app_localizations.dart';

class AppLoadingScreen extends StatefulWidget {
  final ValueListenable<double> progress; // 0.0-1.0, התקדמות אמיתית
  final ValueListenable<String> status; // טקסט הסטטוס האמיתי הנוכחי

  const AppLoadingScreen({super.key, required this.progress, required this.status});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  // 🆕 עיצוב מחדש "Splash" (לפי המוקאפ שסופק) - רצף כניסה חד-פעמי אחד
  // (לא לולאה) של הלוגו: האייקון "קופץ" פנימה, טבעות "פינג" מתרחבות
  // מאחוריו, 3 "אריחי" אות צבעוניים קופצים סביבו ועוברים לריחוף עדין
  // אינסופי, והכותרת "זהה את הלוגו!" נכנסת אות-אות. כל שלב הוא Interval
  // על אותו controller משותף (_hero) - לא עוד controller נפרד לכל אפקט.
  late final AnimationController _hero = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final AnimationController _tileBob = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);

  Animation<double> _in(double start, double end, {Curve curve = Curves.easeOutCubic}) =>
      CurvedAnimation(parent: _hero, curve: Interval(start, end, curve: curve));

  late final Animation<double> _iconIn = _in(0.0, 0.34, curve: Curves.easeOutBack);
  late final Animation<double> _ring1 = _in(0.22, 0.55);
  late final Animation<double> _ring2 = _in(0.30, 0.66);
  late final Animation<double> _heroSheen = _in(0.46, 0.72, curve: Curves.easeInOut);
  late final List<Animation<double>> _tileIn = [
    _in(0.40, 0.62, curve: Curves.easeOutBack),
    _in(0.44, 0.66, curve: Curves.easeOutBack),
    _in(0.48, 0.70, curve: Curves.easeOutBack),
  ];
  late final Animation<double> _spark1 = _in(0.48, 0.64);
  late final Animation<double> _spark2 = _in(0.54, 0.70);
  late final Animation<double> _pillIn = _in(0.52, 0.72);
  // כל אות ב"הלוגו!" (6 תווים) נכנסת בנפרד, עם חפיפה קלה - אותו עיקרון
  // כמו sp-letter במוקאפ.
  late final List<Animation<double>> _letterIn = List.generate(6, (i) {
    final start = (0.58 + i * 0.045).clamp(0.0, 0.85);
    return _in(start, (start + 0.22).clamp(0.0, 1.0), curve: Curves.easeOutBack);
  });
  late final Animation<double> _lineIn = _in(0.86, 1.0);
  late final Animation<double> _taglineIn = _in(0.9, 1.0);

  // פס ההתקדמות המוצג מונפש-חלק לעבר הערך האמיתי (widget.progress) בכל
  // פעם שהוא משתנה - כדי שקפיצות (למשל 15%->55%) ייראו כמו מעבר נעים,
  // בלי להמציא אחוזים שלא קרו באמת.
  late final AnimationController _progressAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..value = widget.progress.value;

  String _version = '';
  int _tipIndex = 0;
  Timer? _tipTimer;

  static const int _tipCount = 4;

  List<String> _tips(AppLocalizations loc) => [
        loc.appLoadingTip1,
        loc.appLoadingTip2,
        loc.appLoadingTip3,
        loc.appLoadingTip4,
      ];

  @override
  void initState() {
    super.initState();
    _loadVersion();
    widget.progress.addListener(_onProgressChanged);
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _tipCount);
    });
    _hero.forward();
    // 🆕 הריחוף האינסופי של 3 האריחים מתחיל רק אחרי שהם "נחתו" (סוף
    // רצף הכניסה החד-פעמי) - בדיוק כמו ה-sp-bob במוקאפ שמתחיל רק אחרי
    // ה-sp-tile. לפני זה _tileIn בלבד קובע את המיקום/גודל שלהם.
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) _tileBob.repeat(reverse: true);
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
    _pulse.dispose();
    _progressAnim.dispose();
    _sheen.dispose();
    _dots.dispose();
    _hero.dispose();
    _tileBob.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _buildHeroIntro(),
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

  // 🆕 עיצוב מחדש "Splash" - רצף כניסה חד-פעמי: טבעות "פינג" מתרחבות
  // מאחורי הלוגו, הלוגו עצמו "קופץ" פנימה עם ברק חולף, 3 אריחי אות
  // צבעוניים קופצים סביבו ועוברים לריחוף עדין אינסופי, וסימני "?" צפים
  // ברקע. 🩹 שונה בכוונה מהמוקאפ בנקודה אחת: במוקאפ מוצג גדל "?" מעוצב
  // בתוך הריבוע המעוגל - אבל הלוגו האמיתי של האפליקציה (assets/icon/logo.png)
  // כבר הוחלף לשם בעבר לפי בקשה מפורשת, כי אותו לוגו בדיוק מופיע במסך
  // הפתיחה הנטיבי (launch_background.xml/LaunchScreen.storyboard) - שומר
  // על "?" רק באריחים הצבעוניים הקטנים ובסימנים הצפים ברקע, לא על הלוגו
  // המרכזי עצמו, כדי לא לאבד את הרציפות החזותית בין שני מסכי הפתיחה.
  Widget _buildHeroIntro() {
    return AnimatedBuilder(
      animation: Listenable.merge([_hero, _tileBob, _drift]),
      builder: (context, child) {
        final floatDy = math.sin(_tileBob.value * 2 * math.pi) * 5;
        return Column(
          children: [
            SizedBox(
              width: 300,
              height: 250,
              child: Transform.translate(
                offset: Offset(0, floatDy),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ..._buildDriftMarks(),
                    _buildRingPing(_ring1, maxScale: 1.8, opacity: 0.55),
                    _buildRingPing(_ring2, maxScale: 2.2, opacity: 0.35),
                    _buildHeroIcon(),
                    _buildTile(phase: 0.0, top: 34, right: 10, gradient: const [Color(0xFFFF8FB0), Color(0xFFD81B63)], glow: const Color(0xFF9E0F45), size: 52, anim: _tileIn[0]),
                    _buildTile(phase: 2.1, bottom: 36, left: 14, gradient: const [Color(0xFF8EDCFF), Color(0xFF0E8FD8)], glow: const Color(0xFF075E9A), size: 46, anim: _tileIn[1]),
                    _buildTile(phase: 4.2, top: 108, left: 2, gradient: const [Color(0xFF8FF0C4), Color(0xFF13A56C)], glow: const Color(0xFF0A6E47), size: 36, anim: _tileIn[2]),
                    _buildSparkle(_spark1, top: 96, right: 4, size: 20, color: const Color(0xFFFFF1BE)),
                    _buildSparkle(_spark2, bottom: 54, left: 20, size: 16, color: const Color(0xFFA5F3FC)),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: _pillIn.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - _pillIn.value.clamp(0.0, 1.0)) * 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.6), width: 1.5),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.04)]),
                  ),
                  child: Text(AppLocalizations.of(context)!.appLoadingTitlePrefix, style: const TextStyle(color: Color(0xFFFFE7A8), fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildWordmark(),
            const SizedBox(height: 12),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(_lineIn.value.clamp(0.0, 1.0), 1, 1),
              child: Container(
                width: 140,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(colors: [Color(0x00FF8A3C), Color(0xFFFF8A3C), Color(0xFFFFD86B), Color(0xFFFF8A3C), Color(0x00FF8A3C)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFBE50).withValues(alpha: 0.6), blurRadius: 12)],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Opacity(opacity: _taglineIn.value.clamp(0.0, 1.0), child: _buildTagline(context)),
          ],
        );
      },
    );
  }

  List<Widget> _buildDriftMarks() {
    final d = math.sin(_drift.value * 2 * math.pi);
    return [
      Positioned(top: 6, left: 10, child: _driftMark(30, 0.07, -0.22, d)),
      Positioned(top: 36, right: 6, child: _driftMark(20, 0.09, 0.2, -d)),
      Positioned(bottom: 40, left: 18, child: _driftMark(24, 0.07, 0.16, d)),
      Positioned(bottom: 6, right: 24, child: _driftMark(34, 0.06, -0.14, -d)),
    ];
  }

  Widget _driftMark(double size, double opacity, double rotate, double driftValue) {
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, driftValue * 8),
        child: Transform.rotate(
          angle: rotate,
          child: Text('?', style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: opacity))),
        ),
      ),
    );
  }

  Widget _buildRingPing(Animation<double> anim, {required double maxScale, required double opacity}) {
    final v = anim.value.clamp(0.0, 1.0);
    final scale = 0.6 + v * (maxScale - 0.6);
    final alpha = (opacity * (1 - v)).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: alpha), width: 2.5)),
        ),
      ),
    );
  }

  // 🆕 הלוגו האמיתי של האפליקציה (assets/icon/logo.png) - ראו ההערה
  // המתועדת למעלה ב-_buildHeroIntro למה הוא נשאר (ולא "?" מעוצב).
  Widget _buildHeroIcon() {
    final v = _iconIn.value.clamp(0.0, 1.0);
    final scale = v == 0 ? 0.0 : (0.001 + v * 0.999); // מתחיל מ-0 (לא נראה) בלי חלוקה באפס
    final sheenT = _heroSheen.value.clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 132,
        height: 132,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE79A), Color(0xFFC98A32), Color(0xFFFFD86B)]),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 30, offset: const Offset(0, 16)),
            BoxShadow(color: const Color(0xFFFFAA3C).withValues(alpha: 0.45), blurRadius: 40),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/icon/logo.png', fit: BoxFit.cover),
              if (sheenT > 0 && sheenT < 1)
                Align(
                  alignment: Alignment(-1 + sheenT * 3, 0),
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Container(
                      width: 40,
                      height: 220,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0)])),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({required double phase, double? top, double? bottom, double? left, double? right, required List<Color> gradient, required Color glow, required double size, required Animation<double> anim}) {
    final v = anim.value.clamp(0.0, 1.0);
    final bob = math.sin(_tileBob.value * 2 * math.pi + phase) * 3.5;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Transform.scale(
          scale: v == 0 ? 0.0 : (0.001 + v * 0.999),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
              boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            alignment: Alignment.center,
            child: Text('?', style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkle(Animation<double> anim, {double? top, double? bottom, double? left, double? right, required double size, required Color color}) {
    final v = anim.value;
    final scale = v <= 0.4 ? (v / 0.4).clamp(0.0, 1.0) * 1.2 : (1.2 - ((v - 0.4) / 0.6).clamp(0.0, 1.0) * 1.2);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: v * math.pi / 2,
        child: Transform.scale(
          scale: scale.clamp(0.0, 1.2),
          child: CustomPaint(size: Size(size, size), painter: _SparkPainter(color: color)),
        ),
      ),
    );
  }

  // "זהה את" + "הלוגו!" - הכותרת פוצלה לשני חלקים לפי המוקאפ: פיל קטן
  // קבוע (ראו למעלה) + המילה הגדולה כאן, שנכנסת אות-אות (ראו _letterIn).
  Widget _buildWordmark() {
    final text = AppLocalizations.of(context)!.appLoadingTitleMain;
    final letters = List.generate(text.length, (i) => text[i]);
    return Directionality(
      textDirection: Directionality.of(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(letters.length, (i) {
          final anim = _letterIn[i.clamp(0, _letterIn.length - 1)];
          final v = anim.value.clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, (1 - v) * 22),
            child: Transform.scale(
              scale: v == 0 ? 0.0 : (0.001 + v * 0.999),
              child: Text(
                letters[i],
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFFFFD34D),
                  shadows: [
                    Shadow(color: Color(0xFFFFB24D), offset: Offset(0, 2)),
                    Shadow(color: Color(0xFFF59A23), offset: Offset(0, 4)),
                    Shadow(color: Color(0xFFDB7C14), offset: Offset(0, 6)),
                    Shadow(color: Color(0x73000000), offset: Offset(0, 14), blurRadius: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        // 🩹 שונה לפי בקשה מפורשת - היה "רואים לוגו. יודעים מי זה?"
        // (הטקסט המקורי במוקאפ), הוחלף למשהו יותר מושך/מזמין לאתגר.
        AppLocalizations.of(context)!.appLoadingTagline,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
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
    final loc = AppLocalizations.of(context)!;
    final tip = _tips(loc)[_tipIndex];
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
                Text(loc.appLoadingTipLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFFFFD86B))),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    tip,
                    key: ValueKey(tip),
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

// 🆕 כוכבון "ניצוץ" קטן (4 קודקודים) ליד הלוגו - ראו _buildSparkle.
// מצייר אותו polygon בדיוק כמו clip-path במוקאפ (מעוין מחודד בכל כיוון).
class _SparkPainter extends CustomPainter {
  final Color color;
  const _SparkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.62, h * 0.38)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.38, h * 0.62)
      ..lineTo(0, h * 0.5)
      ..lineTo(w * 0.38, h * 0.38)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.color != color;
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
