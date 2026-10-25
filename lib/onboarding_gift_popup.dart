// onboarding_gift_popup.dart
//
// 🆕 פופאפ "פרס נאסף!" לסיום ההדרכה הראשונית - לפי בקשה מפורשת: הפרס
// (50 מטבעות, אנרגיה כבר מלאה מראש לשחקן חדש - ראו main_menu_screen.dart)
// ניתן בסוף ההדרכה (אחרי שסיימו את הרמה הראשונה), לא בהתחלה, ובעיצוב
// "יפה" כמו פופאפ הפרס של הבאטל פאס
// (battle_pass_reward_popup.dart) - מדליה עגולה עם קרני-אור וטבעת
// זוהרת, רסיסים עפים, כותרת גרדיאנט, גלולת סיכום פרס, כפתור CTA.
// קובץ נפרד (לא import של המחלקות הפרטיות שם) כי הלוגיקה כאן הרבה יותר
// פשוטה (אין "דרגה הבאה"/פס התקדמות/נתיב פרימיום) - אבל אותה שפה
// עיצובית בדיוק, בכוונה.
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_icons.dart';
import 'l10n/app_localizations.dart';

Future<void> showOnboardingGiftPopup(
  BuildContext context, {
  required int coins,
  int energy = 0,
  VoidCallback? onContinue,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, secAnim) => _OnboardingGiftPopup(coins: coins, energy: energy, onContinue: onContinue),
    transitionBuilder: (ctx, anim, sec, child) {
      return FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child);
    },
  );
}

class _OnboardingGiftPopup extends StatefulWidget {
  final int coins;
  final int energy;
  // 🆕 נקרא אחרי שהפופאפ נסגר (כפתור "המשיכו לשחק") - ראו logo_level_screen.dart
  // (_maybeGrantFirstLevelGift) שמעביר לשלב הבא כי הלוגו הראשון כבר נפתר אוטומטית.
  final VoidCallback? onContinue;
  const _OnboardingGiftPopup({required this.coins, this.energy = 0, this.onContinue});

  @override
  State<_OnboardingGiftPopup> createState() => _OnboardingGiftPopupState();
}

class _OnboardingGiftPopupState extends State<_OnboardingGiftPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const List<_Shard> _shards = [
    _Shard(dx: -56, dy: -80, delay: 0.00, color: Color(0xFFFFD979), square: true),
    _Shard(dx: 50, dy: -92, delay: 0.06, color: Color(0xFF7DD3FC), square: false),
    _Shard(dx: -24, dy: -102, delay: 0.12, color: Color(0xFF6EE7B7), square: false),
    _Shard(dx: 30, dy: -74, delay: 0.18, color: Color(0xFFE9D5FF), square: true),
    _Shard(dx: -74, dy: -50, delay: 0.24, color: Color(0xFFFDA4AF), square: false),
    _Shard(dx: 70, dy: -55, delay: 0.30, color: Color(0xFFFFE08A), square: false),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: AnimatedBuilder(
                animation: _c,
                builder: (ctx, child) {
                  final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
                  return Opacity(
                    opacity: _c.value.clamp(0.0, 1.0),
                    child: Transform.scale(scale: 0.75 + 0.25 * t, child: child),
                  );
                },
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A2170), Color(0xFF1C1145)]),
                    border: Border.all(color: const Color(0xFFFFC64B).withValues(alpha: 0.45)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 24))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.onboardingGiftHeader,
                        style: TextStyle(color: const Color(0xFFFFD979).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 14),
                      _buildMedalAnimation(),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _c,
                        builder: (ctx, child) {
                          final local = ((_c.value - 0.45) / 0.55).clamp(0.0, 1.0);
                          final eased = Curves.easeOut.transform(local);
                          return Opacity(
                            opacity: eased,
                            child: Transform.translate(offset: Offset(0, (1 - eased) * 18), child: child),
                          );
                        },
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFF6D8), Color(0xFFF2793B)],
                              ).createShader(bounds),
                              child: Text(loc.onboardingGiftTitle, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              loc.onboardingGiftSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            _buildRewardSummaryPill(loc),
                            const SizedBox(height: 18),
                            _buildBottomButton(loc),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalAnimation() {
    const glowColor = Color(0xFFF2793B);
    return SizedBox(
      width: 150,
      height: 118,
      child: AnimatedBuilder(
        animation: _c,
        builder: (ctx, _) {
          final v = _c.value;
          final rayAngle = v * 0.9;
          final medalT = Curves.easeOutBack.transform(((v - 0.2) / 0.5).clamp(0.0, 1.0));
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final s in _shards) _buildShard(s, v),
              Transform.rotate(
                angle: rayAngle,
                child: Opacity(
                  opacity: (0.35 + 0.25 * (0.5 + 0.5 * (v * 6).remainder(1))).clamp(0.0, 0.6),
                  child: CustomPaint(size: const Size(126, 126), painter: _StarburstPainter(color: glowColor)),
                ),
              ),
              Opacity(
                opacity: medalT.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.6 + 0.4 * medalT,
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
                      boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 2)],
                    ),
                    alignment: Alignment.center,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const CoinIcon(size: 22),
                      if (widget.energy > 0) ...[const SizedBox(width: 4), const EnergyIcon(size: 22)],
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShard(_Shard s, double v) {
    final local = ((v - s.delay) / 0.5).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(local);
    final opacity = local < 0.2 ? local / 0.2 : (1 - local);
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(s.dx * eased, s.dy * eased),
        child: Container(
          width: s.square ? 9 : 7,
          height: s.square ? 9 : 7,
          decoration: BoxDecoration(color: s.color, borderRadius: s.square ? BorderRadius.circular(3) : null, shape: s.square ? BoxShape.rectangle : BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildRewardSummaryPill(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFFFC64B).withValues(alpha: 0.16),
        border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2793B)])),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinIcon(size: 15),
              if (widget.energy > 0) ...[const SizedBox(width: 2), const EnergyIcon(size: 15)],
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.energy > 0 ? loc.onboardingGiftRewardCoinsEnergy(widget.coins, widget.energy) : loc.onboardingGiftRewardCoinsOnly(widget.coins), style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(loc.onboardingGiftRewardLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.of(context).pop();
            widget.onContinue?.call();
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
              boxShadow: [BoxShadow(color: const Color(0xFFF2793B).withValues(alpha: 0.42), blurRadius: 26, offset: const Offset(0, 12))],
            ),
            child: Center(
              child: Text(loc.onboardingGiftContinueButton, style: const TextStyle(color: Color(0xFF40170F), fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shard {
  final double dx;
  final double dy;
  final double delay;
  final Color color;
  final bool square;
  const _Shard({required this.dx, required this.dy, required this.delay, required this.color, required this.square});
}

class _StarburstPainter extends CustomPainter {
  final Color color;
  const _StarburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer * 0.32;
    final paint = Paint()..color = color.withValues(alpha: 0.5);
    const rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi / rayCount) * i;
      const widthAngle = 0.16;
      final p1 = center + Offset(inner * math.cos(angle - widthAngle), inner * math.sin(angle - widthAngle));
      final p2 = center + Offset(outer * math.cos(angle), outer * math.sin(angle));
      final p3 = center + Offset(inner * math.cos(angle + widthAngle), inner * math.sin(angle + widthAngle));
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter oldDelegate) => oldDelegate.color != color;
}
