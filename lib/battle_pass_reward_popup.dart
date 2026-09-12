// battle_pass_reward_popup.dart
//
// 🆕 פופאפ "פרס נאסף!" מלא-מסך שנפתח אחרי לחיצה על "אסוף" בשורת שלב
// במסך הבאטל פאס (battle_pass_screen.dart) - לפי מוקאפ עיצוב חדש
// ("אסיפת פרס"). קובץ נפרד מ-reward_popups.dart (ולא תוספת אליו) כי
// יש כאן לוגיקה ספציפית לבאטל פאס (חישוב התקדמות לדרגה הבאה, שרשור
// לתביעת דרגה נוספת שכבר נפתחה) שלא שייכת לפופאפי התגמול הכלליים שם -
// אבל השפה העיצובית (רקע גרדיאנט סגול כהה, כפתור CTA גדול, קישור טקסט
// משני שקוף, טקסט-גרדיאנט לכותרות) נשמרת עקבית איתם בכוונה.
//
// ⚠️ בכוונה לא נעשה כאן שימוש באימוג'י 🪙/⚡ גולמי בטקסט - בדיוק כמו
// בשאר האפליקציה (ראו app_icons.dart) - נעשה שימוש ב-CoinIcon/EnergyIcon
// האמיתיים בכל מקום שבמוקאפ יש אימוג'י מטבע/אנרגיה.
//
// 🩹 פושט לעומת המוקאפ: אנימציית "תיבה נפתחת" (מכסה+רסיסים) רצה על
// קונטרולר אחד קצר (900ms) במקום שרשרת עיכובים עד 2 שניות כמו ב-CSS,
// ותוכן הכרטיס (כותרת/גלולת סיכום/פס התקדמות/כפתור) עולה כקבוצה אחת
// (fade+slide) במקום מדורג פריט-פריט - כדי לשמור על הקוד פשוט וקריא
// בלי לאבד את התחושה הכללית של "משהו נפתח וקופץ למעלה".
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_icons.dart';
import 'battle_pass_service.dart';

/// 🆕 מציג פופאפ מלא-מסך "פרס נאסף!" אחרי תביעת שלב בבאטל פאס.
///
/// [tier] - השלב שנתבע כרגע. [premium] - האם הנתיב שנתבע הוא הפרימיום
/// (משפיע על תווית "נתיב חינם/פרימיום" ועל חישוב שרשור הדרגה הבאה).
/// [coins]/[energy] - הפרס שהוענק בפועל (מה-Map שמחזיר
/// BattlePassService.claimTier). [currentPoints] - סך הנקודות הנוכחי
/// בעונה (BattlePassService.getPoints() - לא משתנה מעצם התביעה, רק
/// מנקודות שנצברו קודם), משמש לחישוב פס ההתקדמות לדרגה הבאה.
/// [nextTier] - אם כבר יש דרגה נוספת שנפתחה (מספיק נקודות) באותו נתיב
/// ועדיין לא נתבעה - מספרה, אחרת null. [onClaimNext] - נקרא כשלוחצים
/// "אסוף את דרגה X" (רק כש-nextTier != null) - סוגר את הפופאפ הזה
/// ומפעיל את תביעת הדרגה הבאה מהמסך הקורא (שבתורו יפתח פופאפ חדש לתוצאה).
Future<void> showBattlePassRewardPopup(
  BuildContext context, {
  required int tier,
  required bool premium,
  required int coins,
  required int energy,
  required int currentPoints,
  int? nextTier,
  VoidCallback? onClaimNext,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, secAnim) => _BattlePassRewardPopup(
      tier: tier,
      premium: premium,
      coins: coins,
      energy: energy,
      currentPoints: currentPoints,
      nextTier: nextTier,
      onClaimNext: onClaimNext,
    ),
    transitionBuilder: (ctx, anim, sec, child) {
      return FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child);
    },
  );
}

class _BattlePassRewardPopup extends StatefulWidget {
  final int tier;
  final bool premium;
  final int coins;
  final int energy;
  final int currentPoints;
  final int? nextTier;
  final VoidCallback? onClaimNext;

  const _BattlePassRewardPopup({
    required this.tier,
    required this.premium,
    required this.coins,
    required this.energy,
    required this.currentPoints,
    required this.nextTier,
    required this.onClaimNext,
  });

  @override
  State<_BattlePassRewardPopup> createState() => _BattlePassRewardPopupState();
}

class _BattlePassRewardPopupState extends State<_BattlePassRewardPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 🆕 6 "רסיסים" קטנים שעפים החוצה ממרכז התיבה בפתיחתה - צבעים/כיווני
  // עפיפה (dx,dy) לקוחים בקירוב מהאנימציה shardUp במוקאפ, רק בקנה מידה
  // קצת יותר קטן כדי להתאים לגודל הכרטיס בפלאטר.
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
    final tiers = BattlePassService.tiers;
    final pathLabel = widget.premium ? 'נתיב פרימיום' : 'נתיב חינם';
    final isEnergy = widget.energy > 0 && widget.coins <= 0;
    final bothRewards = widget.coins > 0 && widget.energy > 0;

    // 🩹 פס התקדמות לדרגה הבאה שעדיין ממש לא נפתחה (לא קשור ל-nextTier
    // שהוא כבר פתוח ומחכה לתביעה) - השלב הראשון שדורש יותר נקודות ממה
    // שיש כרגע.
    BattlePassTier? upcomingTier;
    for (final t in tiers) {
      if (t.pointsRequired > widget.currentPoints) {
        upcomingTier = t;
        break;
      }
    }
    final int prevReq = tiers.where((t) => t.tier < (upcomingTier?.tier ?? 1)).fold(0, (p, t) => t.pointsRequired);
    final double barRatio = upcomingTier == null
        ? 1.0
        : ((widget.currentPoints - prevReq) / (upcomingTier.pointsRequired - prevReq)).clamp(0.0, 1.0);

    // תיאור הפרס של הדרגה הבאה שכבר פתוחה (nextTier) - לצורך כרטיס
    // "דרגה X נפתחה" (אם קיים).
    String? nextTierDesc;
    if (widget.nextTier != null) {
      final def = tiers.firstWhere((t) => t.tier == widget.nextTier);
      final nCoins = widget.premium ? def.premiumCoins : def.freeCoins;
      final nEnergy = widget.premium ? def.premiumEnergy : def.freeEnergy;
      final parts = <String>[];
      if (nCoins > 0) parts.add('$nCoins מטבעות');
      if (nEnergy > 0) parts.add('$nEnergy אנרגיה');
      nextTierDesc = parts.join(' + ');
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // רקע כהה מטושטש (blur) - "מרחיק" את מסך הבאטל פאס מאחורי הפופאפ.
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
                    // 🆕 כניסת הכרטיס - קירוב ל-burstIn במוקאפ: מתחיל קטן
                    // וקצת מסובב, "קופץ" מעבר לגודל המלא ואז מתייצב.
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
                          'באטל פאס · דרגה ${widget.tier}',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: const Color(0xFFFFD979).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 14),
                        _buildChestAnimation(isEnergy: isEnergy, bothRewards: bothRewards),
                        const SizedBox(height: 8),
                        // 🆕 שאר תוכן הכרטיס עולה כקבוצה אחת (fade+slide) -
                        // פישוט של המדרג פריט-פריט שבמוקאפ (ראו הערה למעלה).
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
                                child: const Text('פרס נאסף!', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
                              ),
                              const SizedBox(height: 16),
                              _buildRewardSummaryPill(pathLabel: pathLabel, tiersCount: tiers.length),
                              const SizedBox(height: 16),
                              _buildProgressBlock(upcomingTier: upcomingTier, barRatio: barRatio),
                              if (widget.nextTier != null && nextTierDesc != null) ...[
                                const SizedBox(height: 16),
                                _buildNextTierCard(nextTierDesc),
                              ],
                              const SizedBox(height: 18),
                              _buildBottomButton(),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('חזרה לפאס', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.32), fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ),
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

  // 🩹 תוקן: הגרסה הקודמת (תיבת-אוצר עם גוף מלבני חום + מכסה + עיגול-
  // אייקון במרכז) נראתה בפועל כמו לוגו מצלמה (מלבן עם "עדשה" עגולה
  // באמצע) - המשתמש דיווח על זה במפורש. במקום זה - מדליית ניצחון
  // עגולה עם קרני-אור נפתחות (starburst) מאחוריה וטבעת זוהרת סביבה,
  // בלי שום צורה מלבנית שיכולה להתבלבל עם עדשת מצלמה. הרסיסים
  // (shardUp) נשארו כפי שהיו.
  Widget _buildChestAnimation({required bool isEnergy, required bool bothRewards}) {
    final Color glowColor = isEnergy ? const Color(0xFF0284C7) : const Color(0xFFF2793B);
    return SizedBox(
      width: 150,
      height: 118,
      child: AnimatedBuilder(
        animation: _c,
        builder: (ctx, _) {
          final v = _c.value;
          // קרני האור: מסתובבות לאט לאורך כל האנימציה.
          final rayAngle = v * 0.9;
          // המדליה: "קופצת" פנימה בין 20%-70% מהאנימציה (במקום לצאת מתיבה).
          final medalT = Curves.easeOutBack.transform(((v - 0.2) / 0.5).clamp(0.0, 1.0));

          return Stack(
            alignment: Alignment.center,
            children: [
              // רסיסים עפים החוצה - נשאר כמו קודם.
              for (final s in _shards) _buildShard(s, v),
              // קרני אור מסתובבות מאחורי המדליה.
              Transform.rotate(
                angle: rayAngle,
                child: Opacity(
                  opacity: (0.35 + 0.25 * (0.5 + 0.5 * (v * 6).remainder(1))).clamp(0.0, 0.6),
                  child: CustomPaint(size: const Size(126, 126), painter: _StarburstPainter(color: glowColor)),
                ),
              ),
              // המדליה העגולה עם אייקון הפרס במרכז (ללא שום מלבן מסביב).
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
                      gradient: isEnergy
                          ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA5F3FC), Color(0xFF0284C7)])
                          : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
                      boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 2)],
                    ),
                    alignment: Alignment.center,
                    child: bothRewards
                        ? const Row(mainAxisSize: MainAxisSize.min, children: [CoinIcon(size: 22), SizedBox(width: 4), EnergyIcon(size: 22)])
                        : (isEnergy ? const EnergyIcon(size: 30) : const CoinIcon(size: 30)),
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

  // 🆕 גלולת סיכום הפרס: אייקון + כמות + "נתיב .../דרגה X" + מונה
  // "דרגה/סה"כ דרגות" (במוקאפ יש כאן "5/5" - מונה פרסים מאותו סוג
  // באותו נתיב; אין לנו דאטה כזו בפועל, אז במקום זה מוצג "דרגה $tier
  // מתוך סה"כ $tiersCount" שהוא מספר אמיתי וקיים).
  Widget _buildRewardSummaryPill({required String pathLabel, required int tiersCount}) {
    final isEnergy = widget.energy > 0 && widget.coins <= 0;
    final parts = <String>[];
    if (widget.coins > 0) parts.add('${widget.coins} מטבעות');
    if (widget.energy > 0) parts.add('${widget.energy} אנרגיה');
    final title = parts.join(' + ');
    final accent = isEnergy ? const Color(0xFF7DD3FC) : const Color(0xFFFFD86B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: (isEnergy ? const Color(0xFF38BDF8) : const Color(0xFFFFC64B)).withValues(alpha: 0.16),
        border: Border.all(color: (isEnergy ? const Color(0xFF7DD3FC) : const Color(0xFFFFD86B)).withValues(alpha: 0.4)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isEnergy
                  ? const LinearGradient(colors: [Color(0xFFA5F3FC), Color(0xFF0284C7)])
                  : const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
            ),
            alignment: Alignment.center,
            child: bothRewardsIcon(isEnergy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('$pathLabel · דרגה ${widget.tier}', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text('${widget.tier}/$tiersCount', textDirection: TextDirection.ltr, style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  bool get bothRewards => widget.coins > 0 && widget.energy > 0;

  Widget bothRewardsIcon(bool isEnergy) {
    if (bothRewards) {
      return const Row(mainAxisSize: MainAxisSize.min, children: [CoinIcon(size: 15), SizedBox(width: 2), EnergyIcon(size: 15)]);
    }
    return isEnergy ? const EnergyIcon(size: 19) : const CoinIcon(size: 19);
  }

  // 🆕 פס התקדמות לדרגה הבאה שעדיין לא נפתחה (upcomingTier), לפי
  // הנקודות האמיתיות בעונה - אם כל הדרגות כבר נפתחו, מוצג פס מלא
  // עם כיתוב "כל הדרגות נפתחו!".
  Widget _buildProgressBlock({required BattlePassTier? upcomingTier, required double barRatio}) {
    final label = upcomingTier == null ? 'כל הדרגות נפתחו!' : 'התקדמות לדרגה ${upcomingTier.tier}';
    final valueLabel = upcomingTier == null ? '⭐ מקסימום' : '⭐ ${(barRatio * 100).round()}%';
    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, fontWeight: FontWeight.w900)),
            Text(valueLabel, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFFD979), fontSize: 10.5, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: Colors.black.withValues(alpha: 0.32)),
                AnimatedBuilder(
                  animation: _c,
                  builder: (ctx, _) {
                    final local = ((_c.value - 0.55) / 0.45).clamp(0.0, 1.0);
                    final eased = Curves.easeOutCubic.transform(local);
                    return FractionallySizedBox(
                      widthFactor: barRatio * eased,
                      child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD8B4FE), Color(0xFFFFD979)]))),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 כרטיס "דרגה X נפתחה" - מוצג רק אם כבר יש דרגה נוספת שנפתחה
  // (מספיק נקודות) באותו נתיב ועדיין לא נתבעה.
  Widget _buildNextTierCard(String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [const Color(0xFFD8B4FE).withValues(alpha: 0.22), const Color(0xFF7C3AED).withValues(alpha: 0.06)]),
        border: Border.all(color: const Color(0xFFD8B4FE).withValues(alpha: 0.45), style: BorderStyle.solid),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(colors: [Color(0xFFD8B4FE), Color(0xFF7C3AED)]),
            ),
            alignment: Alignment.center,
            child: Text('${widget.nextTier}', style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('דרגה ${widget.nextTier} נפתחה', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 14.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(desc, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  // 🆕 כפתור תחתון: "אסוף את דרגה X" אם יש עוד שלב פתוח לתביעה מיידית,
  // אחרת "סגור" (סתם סוגר את הפופאפ).
  Widget _buildBottomButton() {
    final hasNext = widget.nextTier != null && widget.onClaimNext != null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (hasNext) {
              widget.onClaimNext!();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
              boxShadow: [BoxShadow(color: const Color(0xFFF2793B).withValues(alpha: 0.42), blurRadius: 26, offset: const Offset(0, 12))],
            ),
            child: Center(
              child: Text(
                hasNext ? 'אסוף את דרגה ${widget.nextTier}' : 'סגור',
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Color(0xFF40170F), fontSize: 17, fontWeight: FontWeight.w900),
              ),
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

// 🆕 מצייר "קרני אור" פשוטות (8 קווים יוצאים מהמרכז החוצה) מאחורי
// מדליית הפרס - מחליף את הרקע המסתובב (rayspin) מהמוקאפ בציור וקטורי
// פשוט, בלי תמונה/asset חיצוני (כדי לא ליצור עוד תלות בקובץ שעלול
// להיעדר בדיוק כמו הבעיה עם "לוגו המצלמה" הקודם).
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