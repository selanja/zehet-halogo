// tournament_result_popup.dart
//
// 🆕 פופאפ מלא-מסך "תוצאת הטורניר היומי" - נפתח אוטומטית בכניסה לאפליקציה
// (ראו main_menu_screen.dart:_maybeShowTournamentResult) בנוסף לנקודת
// הכניסה הקיימת ממסך הלובי (tournament_lobby_screen.dart), כדי שהשחקן
// יראה אם זכה/קיבל החזר גם אם הוא לא נכנס בעצמו למסך הטורניר. בכוונה
// קובץ נפרד ומשותף בין שתי נקודות הכניסה (ולא דיאלוג כפול) - כך שהעיצוב
// יישאר עקבי בלי תחזוקה כפולה.
//
// 🎨 השפה העיצובית (רקע גרדיאנט סגול כהה, מסגרת זהב, כניסה בקנה-מידה
// עם easeOutBack, אייקון זוהר עם קרני-אור מסתובבות מאחוריו, כותרת
// טקסט-גרדיאנט, כפתור CTA בגרדיאנט זהב) מועתקת בכוונה מ-
// battle_pass_reward_popup.dart כדי שכל פופאפי התגמול באפליקציה ייראו
// כמו משפחה אחת - אבל עם פרמטרים גנריים של TournamentPrizeResult במקום
// המשתנים הספציפיים לבאטל פאס.
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_icons.dart';
import 'tournament_service.dart';
import 'iap_manager.dart'; // 🆕 מבצע אלוף - ראו _buildWinnerBonusChip

// 🆕 label ניתן לפרמטר (ברירת מחדל "אתגר 3 הימים") - כדי שאפשר יהיה
// להשתמש באותו פופאפ בדיוק גם לטורניר המתוזמן (ראו scheduled_tournament_service.dart)
// בלי לשכפל את כל הקובץ הזה, רק עם כיתוב שונה בשתי השורות שמזכירות
// את שם המוד בפירוש.
Future<void> showTournamentResultPopup(BuildContext context, TournamentPrizeResult prize, {String label = 'אתגר 3 הימים'}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, secAnim) => _TournamentResultPopup(prize: prize, label: label),
    transitionBuilder: (ctx, anim, sec, child) {
      return FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child);
    },
  );
}

class _TournamentResultPopup extends StatefulWidget {
  final TournamentPrizeResult prize;
  final String label;
  const _TournamentResultPopup({required this.prize, required this.label});

  @override
  State<_TournamentResultPopup> createState() => _TournamentResultPopupState();
}

class _TournamentResultPopupState extends State<_TournamentResultPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _isRefund => widget.prize.outcome == TournamentOutcome.refund;

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
                          widget.label,
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
                                child: Text(
                                  _isRefund ? 'דמי הכניסה הוחזרו' : 'זכית במקום ה-${widget.prize.rank}!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isRefund ? 'לא היו מספיק משתתפים באתגר האחרון, אז דמי הכניסה שלכם חזרו אליכם במלואם' : 'סיימתם במקום ה-${widget.prize.rank} ב${widget.label} - כל הכבוד!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                              const SizedBox(height: 16),
                              _buildRewardPill(),
                              // 🆕 "ניצחון בטורניר נותן 20% הנחה על כמה חבילות
                              // ספציפיות" - בלי השורה הזו הזוכה לא היה יודע
                              // בכלל שיש לו מבצע שמחכה לו בחנות (ראו
                              // IapManager.activateTournamentBonus, שכבר
                              // הופעל בשלב הזה ע"י tournament_service.dart).
                              if (!_isRefund && widget.prize.rank == 1) ...[
                                const SizedBox(height: 10),
                                _buildWinnerBonusChip(),
                              ],
                              const SizedBox(height: 18),
                              _buildBottomButton(),
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
      ),
    );
  }

  Widget _buildMedalAnimation() {
    final Color glowColor = _isRefund ? const Color(0xFF60A5FA) : const Color(0xFFF2793B);
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
                      gradient: _isRefund
                          ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA5D8FF), Color(0xFF3B82F6)])
                          : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_medalColorLight, _medalColorDark]),
                      boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 2)],
                    ),
                    alignment: Alignment.center,
                    child: _isRefund
                        ? const Icon(Icons.replay_circle_filled_rounded, color: Colors.white, size: 38)
                        : Icon(Icons.emoji_events_rounded, color: Colors.white, size: 42),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color get _medalColorLight {
    switch (widget.prize.rank) {
      case 1:
        return const Color(0xFFFFF3C4);
      case 2:
        return const Color(0xFFEDEDED);
      default:
        return const Color(0xFFE6B37E);
    }
  }

  Color get _medalColorDark {
    switch (widget.prize.rank) {
      case 1:
        return const Color(0xFFF2793B);
      case 2:
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildRewardPill() {
    final accent = _isRefund ? const Color(0xFF93C5FD) : const Color(0xFFFFD86B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: (_isRefund ? const Color(0xFF3B82F6) : const Color(0xFFFFC64B)).withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isRefund
                  ? const LinearGradient(colors: [Color(0xFFA5D8FF), Color(0xFF3B82F6)])
                  : const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
            ),
            alignment: Alignment.center,
            child: const CoinIcon(size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('+${widget.prize.coins}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    const CoinIcon(size: 15),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_isRefund ? 'הוחזר לחשבונכם' : 'נוסף לחשבונכם', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 "מבצע אלוף!" - מציג לזוכה במקום הראשון שיש לו 20% הנחה אפקטיבית
  // (ראו IapManager.tournamentBonusEligibleIds/activateTournamentBonus)
  // על חבילות המטבעות הגדולות בחנות, ל-24 השעות הקרובות. בלי השורה הזו
  // הזוכה לעולם לא היה מגלה שיש לו מבצע שמחכה לו.
  Widget _buildWinnerBonusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [const Color(0xFFFFD979).withValues(alpha: 0.22), const Color(0xFFF59E0B).withValues(alpha: 0.08)]),
        border: Border.all(color: const Color(0xFFFFD979).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD979), size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('מבצע אלוף! 20% הנחה בחנות', style: TextStyle(color: Color(0xFFFFE9A8), fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('על חבילות המטבעות הגדולות, ל-${IapManager.tournamentBonusHours} שעות', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).pop(),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
              boxShadow: [BoxShadow(color: const Color(0xFFF2793B).withValues(alpha: 0.42), blurRadius: 26, offset: const Offset(0, 12))],
            ),
            child: const Center(
              child: Text('מעולה!', style: TextStyle(color: Color(0xFF40170F), fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }
}

// 🩹 זהה ל-_StarburstPainter ב-battle_pass_reward_popup.dart - מועתק (לא
// משותף) כדי לא ליצור תלות הדדית מוזרה בין שני קבצי פופאפ נפרדים; הציור
// עצמו פשוט מספיק שלא מצדיק קובץ משותף ייעודי רק בשבילו.
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
