// social_follow_popup.dart
//
// 🆕 פופאפ "עקבו אחרינו וקבלו מטבעות!" - לפי בקשה מפורשת: פיצ'ר שמעודד
// עקיבה באינסטגרם ובטיקטוק (@zehet_halogo בשתיהן). לוחצים על כפתור
// הפלטפורמה -> נפתח הדף החיצוני (url_launcher, כמו שכבר נעשה ב-
// settings_screen.dart ל-privacy/תמיכה). לוחצים "סימנתי לייק, קיבלתי
// את המטבעות!" -> מקבלים 30 מטבעות חד-פעמי (honor system - אין שום
// דרך לאמת מצד השרת שהעקיבה באמת קרתה, בדיוק כמו כל שאר כלכלת המטבעות
// הקיימת באפליקציה - ראו ההערה המתועדת ב-tournament_service.dart/
// duel_service.dart על אותו טרייד-אוף ב-MVP הזה).
//
// 🎨 השפה העיצובית (רקע גרדיאנט סגול כהה, מסגרת זהב, כניסה בקנה-מידה
// עם easeOutBack, אייקון זוהר עם קרני-אור מסתובבות מאחוריו, כותרת
// טקסט-גרדיאנט, כפתור CTA בגרדיאנט זהב) זהה בכוונה לשאר פופאפי התגמול
// באפליקציה (tournament_result_popup.dart/battle_pass_reward_popup.dart)
// כדי שהכול ירגיש כמו משפחה אחת.
//
// 🩹 אין אייקון אינסטגרם אמיתי ב-Material Icons (בניגוד לטיקטוק - יש
// Icons.tiktok_rounded אמיתי!) - לכן לאינסטגרם נעשה שימוש ב-
// Icons.camera_alt_rounded (הכי קרוב מבחינת זיהוי ויזואלי: אינסטגרם
// מזוהה כאפליקציית תמונות/מצלמה), בדיוק באותה שיטה שכבר קיימת באפליקציה
// ל-Google/Apple (Icons.g_mobiledata_rounded/Icons.apple_rounded ב-
// account_link_prompt.dart) - כשאין אייקון מותג אמיתי, משתמשים בווקטור
// הכי קרוב מבחינת משמעות, לא באימוג'י (ראו app_icons.dart).
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_icons.dart';
import 'audio_manager.dart';
import 'player_sync.dart';

const int socialFollowCoinReward = 30;
const String socialFollowInstagramUrl = 'https://www.instagram.com/zehet_halogo';
const String socialFollowTikTokUrl = 'https://www.tiktok.com/@zehet_halogo';
const String _socialFollowClaimedKey = 'socialFollowClaimed';

Future<void> showSocialFollowPopup(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, secAnim) => const _SocialFollowPopup(),
    transitionBuilder: (ctx, anim, sec, child) {
      return FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child);
    },
  );
}

class _SocialFollowPopup extends StatefulWidget {
  const _SocialFollowPopup();

  @override
  State<_SocialFollowPopup> createState() => _SocialFollowPopupState();
}

class _SocialFollowPopupState extends State<_SocialFollowPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  bool _claimed = false;
  bool _claiming = false;

  // 🆕 עיכוב קצר לפני שאפשר לתבוע את המטבעות - לא אימות אמיתי (אי אפשר
  // מצד הלקוח, ראו ההערה הגדולה למעלה), רק חסם קטן נגד "לוחצים על שני
  // הכפתורים מיד ברצף בלי באמת לעקוב" - לפי בקשה מפורשת. מתחיל לרוץ רק
  // אחרי שהמשתמש לחץ על אחת הפלטפורמות (_openLink), לא מיד בפתיחת הפופאפ.
  static const int _waitSeconds = 9;
  bool _linkTapped = false;
  int _secondsLeft = _waitSeconds;
  Timer? _waitTimer;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted && (prefs.getBool(_socialFollowClaimedKey) ?? false)) {
        setState(() => _claimed = true);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _waitTimer?.cancel();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    AudioManager.playClick();
    if (!_linkTapped) {
      setState(() => _linkTapped = true);
      _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_secondsLeft <= 1) {
          timer.cancel();
          setState(() => _secondsLeft = 0);
        } else {
          setState(() => _secondsLeft -= 1);
        }
      });
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  bool get _canClaim => _linkTapped && _secondsLeft <= 0;

  Future<void> _claim() async {
    if (_claimed || _claiming || !_canClaim) return;
    AudioManager.playClick();
    setState(() => _claiming = true);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_socialFollowClaimedKey) ?? false)) {
      final coins = prefs.getInt('coins') ?? 15;
      await prefs.setInt('coins', coins + socialFollowCoinReward);
      await prefs.setBool(_socialFollowClaimedKey, true);
      PlayerSyncService.syncCurrentProgress();
    }
    if (!mounted) return;
    setState(() {
      _claimed = true;
      _claiming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
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
                          'עקבו ותרוויחו',
                          style: TextStyle(color: const Color(0xFFFFD979).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 14),
                        _buildIconAnimation(),
                        const SizedBox(height: 14),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFF6D8), Color(0xFFF2793B)],
                          ).createShader(bounds),
                          child: const Text(
                            'עקבו אחרינו\nוקבלו מטבעות!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.15),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFFFD86B).withValues(alpha: 0.16)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('+$socialFollowCoinReward', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 16, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 6),
                              const CoinIcon(size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '@zehet_halogo באינסטגרם ובטיקטוק - עדכונים, טיזרים ועוד',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: _platformButton(
                              label: 'אינסטגרם',
                              icon: Icons.camera_alt_rounded,
                              gradient: const [Color(0xFFFEDA77), Color(0xFFD62976), Color(0xFF962FBF), Color(0xFF4F5BD5)],
                              onTap: () => _openLink(socialFollowInstagramUrl),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _platformButton(
                              label: 'טיקטוק',
                              icon: Icons.tiktok_rounded,
                              gradient: const [Color(0xFF25F4EE), Color(0xFF000000), Color(0xFFFE2C55)],
                              onTap: () => _openLink(socialFollowTikTokUrl),
                            )),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildClaimButton(),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            _claimed ? 'סגור' : 'אולי מאוחר יותר',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.32), fontSize: 12.5, fontWeight: FontWeight.w700),
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
      ),
    );
  }

  Widget _buildIconAnimation() {
    return SizedBox(
      width: 140,
      height: 110,
      child: AnimatedBuilder(
        animation: _c,
        builder: (ctx, _) {
          final v = _c.value;
          final rayAngle = v * 0.9;
          final iconT = Curves.easeOutBack.transform(((v - 0.2) / 0.5).clamp(0.0, 1.0));
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rayAngle,
                child: Opacity(
                  opacity: (0.35 + 0.25 * (0.5 + 0.5 * (v * 6).remainder(1))).clamp(0.0, 0.6),
                  child: CustomPaint(size: const Size(120, 120), painter: _StarburstPainter(color: const Color(0xFFFFD86B))),
                ),
              ),
              Opacity(
                opacity: iconT.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.6 + 0.4 * iconT,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFD86B).withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 2)],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _platformButton({required String label, required IconData icon, required List<Color> gradient, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [BoxShadow(color: gradient.last.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimButton() {
    final locked = !_claimed && !_canClaim;
    final active = !_claimed && _canClaim;
    String label;
    if (_claimed) {
      label = 'המטבעות כבר נוספו!';
    } else if (!_linkTapped) {
      label = 'עקבו למעלה קודם 👆';
    } else if (!_canClaim) {
      label = 'רגע... $_secondsLeft';
    } else {
      label = 'סימנתי לייק, קיבלתי את המטבעות!';
    }
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: active ? _claim : null,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: active
                  ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)])
                  : LinearGradient(colors: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.06)]),
              boxShadow: active ? [BoxShadow(color: const Color(0xFFF2793B).withValues(alpha: 0.42), blurRadius: 26, offset: const Offset(0, 12))] : null,
            ),
            child: Center(
              child: _claiming
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_claimed) ...[
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
                          const SizedBox(width: 6),
                        ] else if (locked && _linkTapped) ...[
                          Icon(Icons.hourglass_bottom_rounded, color: Colors.white.withValues(alpha: 0.55), size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(color: active ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🩹 זהה בעקרון ל-_StarburstPainter ב-tournament_result_popup.dart/
// battle_pass_reward_popup.dart - מועתק (לא משותף, קובץ פרטי לכל Widget)
// בדיוק לפי אותו תקדים.
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
