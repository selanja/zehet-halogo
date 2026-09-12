// reward_popups.dart
//
// 🆕 שלושה פופאפים חדשים למסך מלא, לפי מוקאפ עיצוב חדש:
//   1. showEnergyRewardPopup   - "קיבלת אנרגיה" (אחרי צפייה בפרסומת)
//   2. showCoinsRewardPopup    - "קיבלת מטבעות" (אחרי צפייה בפרסומת)
//   3. showPurchaseCompletePopup - "הרכישה הושלמה" (אחרי רכישה אמיתית בחנות)
//
// כל שלושתם בנויים על אותו שלד עיצובי (רקע גרדיאנט סגול כהה, תג עגול
// זוהר עם טבעת דקורטיבית מסתובבת, מספר/כותרת בטקסט גרדיאנט, כפתור CTA
// גדול, קישור משני שקוף לביטול) - אבל כל תוכן (ערכים, כותרות, תיאורים,
// רשימת פריטים) מגיע כפרמטר מבחוץ, כדי שהקובץ הזה יישאר גנרי וללא שום
// נתון מקובע (hardcoded) שקשור למשק הכלכלה בפועל של המשחק.
//
// ⚠️ בכוונה לא נעשה כאן שימוש באימוג'י 🪙/⚡ גולמי בתוך Text - לפי
// המוסכמה הקיימת בקוד (ראו app_icons.dart), במקום זה נעשה שימוש
// ב-CoinIcon/EnergyIcon (תמונת PNG קבועה) שלא תלויה בפונט האימוג'י של
// המכשיר. שאר האימוג'י הדקורטיביים (✓, ✨, ⚔ וכו') לא ידועים כבעייתיים
// ונשארו כפי שהם.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon וקטוריים

/// 🆕 פריט בודד ברשימת "נוסף לחשבון" בפופאפ הרכישה - אייקון (ווידג'ט
/// חופשי, למשל CoinIcon(size: 18) או Text('✦')) + תווית + ערך. הוגדר
/// כמחלקה (לא Record) כדי שיהיה נוח וברור לבנות ב-const/מיידית מכל מסך
/// קורא, בלי תלות בגרסת Dart שתומכת ב-Records.
class GrantedItem {
  final Widget icon;
  final String label;
  final String value;
  const GrantedItem({required this.icon, required this.label, required this.value});
}

// ====================================================================
// שלד משותף
// ====================================================================

/// רקע גרדיאנט סגול כהה משותף לשלושת הפופאפים.
const _bgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF2A1B5E), Color(0xFF150E33)],
);

/// עוטף כל פופאפ ב-Dialog מלא-מסך (בלי שוליים/עיגול פינות של Dialog
/// רגיל) עם הרקע הסגול-כהה המשותף, ומכריח RTL (כל הטקסטים בפופאפים
/// האלה בעברית).
Future<T?> _showFullScreenPopup<T>(BuildContext context, Widget child) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim, secAnim) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: _bgGradient),
          child: SafeArea(child: child),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, secAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// טבעת דקורטיבית מסתובבת מאחורי התג העגול - עיגול מקווקו שמסתובב לאט
/// לנצח, כדי לתת תחושת "חי"/חגיגי לתג בלי להיות רועש מדי.
class _SpinRing extends StatefulWidget {
  final double size;
  final Color color;
  const _SpinRing({required this.size, required this.color});

  @override
  State<_SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<_SpinRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _DashedRingPainter(color: widget.color),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const dashCount = 18;
    const dashFraction = 0.55; // חלק מכל "פלח" שבו בפועל מצוירת קשת
    for (int i = 0; i < dashCount; i++) {
      final start = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * dashFraction;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => oldDelegate.color != color;
}

/// תג עגול 104x104 עם גרדיאנט + זוהר רדיאלי מאחוריו + טבעת מסתובבת
/// דקורטיבית סביבו. משותף לשלושת הפופאפים (רק הצבעים/התוכן משתנים).
class _GlowBadge extends StatelessWidget {
  final Widget child;
  final List<Color> gradient;
  final Color glowColor;
  final Color ringColor;
  const _GlowBadge({required this.child, required this.gradient, required this.glowColor, required this.ringColor});

  static const double badgeSize = 104;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // זוהר רדיאלי
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [glowColor.withValues(alpha: 0.38), glowColor.withValues(alpha: 0.0)],
              ),
            ),
          ),
          _SpinRing(size: 148, color: ringColor.withValues(alpha: 0.55)),
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
              boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.45), blurRadius: 28, spreadRadius: 2)],
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

/// טקסט עם מילוי גרדיאנט (למספרים הגדולים/כותרות מוזהבות-כחולות).
class _GradientText extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final double fontSize;
  final FontWeight fontWeight;
  const _GradientText(this.text, {required this.gradient, required this.fontSize, this.fontWeight = FontWeight.w900});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradient,
      ).createShader(bounds),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.white, height: 1.0),
      ),
    );
  }
}

/// כפתור CTA גדול משותף (רדיוס ≈22, גרדיאנט, טקסט כהה).
class _CtaButton extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final Color textColor;
  final VoidCallback onTap;
  final double fontSize;
  const _CtaButton({
    required this.label,
    required this.gradient,
    required this.onTap,
    this.textColor = const Color(0xFF241a4f),
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: gradient),
              boxShadow: [BoxShadow(color: gradient.last.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Center(
              child: Text(
                label,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// קישור טקסט משני שקוף (למשל "המשך"/"לחנות") מתחת לכפתור ה-CTA.
class _SecondaryLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.32), fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// שורת סטטיסטיקה ("האנרגיה שלך: 5/5" וכו') - תג עגלגל עם ערך גדול
/// ותווית קטנה מעליו/לידו.
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatPill({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, textDirection: TextDirection.rtl, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ====================================================================
// פופאפ 1: "קיבלת אנרגיה" (תגמול פרסומת)
// ====================================================================

/// מציג פופאפ מלא-מסך "קיבלת אנרגיה" אחרי צפייה בפרסומת (+2 אנרגיה).
///
/// [rewardAmount] - כמות האנרגיה שהוענקה (למשל EnergyService.adRewardAmount).
/// [currentEnergy]/[maxEnergy] - הערך האמיתי הנוכחי, מהמסך הקורא (אחרי
/// הזיכוי בפועל - למשל EnergyService.getCurrentEnergy() ו-EnergyService.maxEnergy).
/// [subtitle] - שורת ההסבר מתחת לתווית "אנרגיה" - פרמטר, כדי שכל מסך
/// קורא יוכל לנסח אותה לפי ההקשר שלו.
/// [onDuelTap] - נקרא אחרי סגירת הפופאפ, כשלוחצים על כפתור ה-CTA
/// ("יאללה, לדו-קרב"). אופציונלי - אם המסך הקורא כבר נמצא במסך הדו-קרב
/// עצמו, אפשר להשאיר null (אז הכפתור רק סוגר את הפופאפ).
Future<void> showEnergyRewardPopup(
  BuildContext context, {
  required int rewardAmount,
  required int currentEnergy,
  required int maxEnergy,
  String subtitle = "מספיק לשני דו־קרבים נוספים",
  VoidCallback? onDuelTap,
}) {
  const cyanGradient = [Color(0xFFA5F3FC), Color(0xFF38BDF8), Color(0xFF2563EB)];
  return _showFullScreenPopup(
    context,
    Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowBadge(
              gradient: const [Color(0xFFA5F3FC), Color(0xFF2563EB)],
              glowColor: const Color(0xFF22D3EE),
              ringColor: const Color(0xFF67E8F9),
              child: EnergyIcon(size: 46),
            ),
            const SizedBox(height: 18),
            Text("קיבלת", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            _GradientText("+$rewardAmount", gradient: cyanGradient, fontSize: 46),
            const SizedBox(height: 2),
            const Text("אנרגיה", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
            const SizedBox(height: 24),
            _StatPill(label: "האנרגיה שלך", value: "$currentEnergy/$maxEnergy", valueColor: const Color(0xFF67E8F9)),
            const SizedBox(height: 30),
            _CtaButton(
              label: "יאללה, לדו־קרב ⚔",
              gradient: const [Color(0xFF7DD3FC), Color(0xFF2563EB)],
              onTap: () {
                Navigator.of(context).pop();
                onDuelTap?.call();
              },
            ),
            _SecondaryLink(label: "המשך", onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    ),
  );
}

// ====================================================================
// פופאפ 2: "קיבלת מטבעות" (תגמול פרסומת)
// ====================================================================

/// מציג פופאפ מלא-מסך "קיבלת מטבעות" אחרי צפייה בפרסומת (ברירת מחדל
/// +15 מטבעות, ניתן לשינוי).
///
/// [subtitle] - חובה (לא ברירת מחדל בכוונה) כי הניסוח תלוי בהקשר שממנו
/// נפתח הפופאפ (בונוס פרסומת רגיל / רצף התחברות וכו') - כדי לא לקבע
/// כאן ניסוח ספציפי שלא תמיד נכון.
/// [currentCoins] - סך המטבעות האמיתי הנוכחי מהמסך הקורא (אחרי הזיכוי
/// בפועל, למשל מ-SharedPreferences מפתח 'coins').
/// [onShopTap] - נקרא אחרי סגירת הפופאפ בלחיצה על "לחנות" (אופציונלי -
/// אם לא סופק, הקישור רק סוגר את הפופאפ).
Future<void> showCoinsRewardPopup(
  BuildContext context, {
  required int rewardAmount,
  required int currentCoins,
  required String subtitle,
  VoidCallback? onShopTap,
}) {
  const goldGradient = [Color(0xFFFFF3C4), Color(0xFFFFD86B), Color(0xFFF59E0B)];
  return _showFullScreenPopup(
    context,
    Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowBadge(
              gradient: const [Color(0xFFFFE08A), Color(0xFFF59E0B)],
              glowColor: const Color(0xFFFFD86B),
              ringColor: const Color(0xFFFFE08A),
              child: CoinIcon(size: 46),
            ),
            const SizedBox(height: 18),
            Text("קיבלת", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            _GradientText("+$rewardAmount", gradient: goldGradient, fontSize: 46),
            const SizedBox(height: 2),
            const Text("מטבעות", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
            const SizedBox(height: 24),
            _StatPill(label: "המטבעות שלך", value: "$currentCoins", valueColor: const Color(0xFFFFD86B)),
            const SizedBox(height: 30),
            _CtaButton(
              label: "מעולה",
              gradient: const [Color(0xFFFFE08A), Color(0xFFF59E0B)],
              onTap: () => Navigator.of(context).pop(),
            ),
            _SecondaryLink(
              label: "לחנות",
              onTap: () {
                Navigator.of(context).pop();
                onShopTap?.call();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// ====================================================================
// פופאפ 3: "הרכישה הושלמה" (רכישה אמיתית מהחנות)
// ====================================================================

/// מציג פופאפ מלא-מסך "הרכישה הושלמה" אחרי רכישה אמיתית מוצלחת בחנות.
///
/// [itemName]/[itemPrice]/[itemDescription] - פרטי הפריט שנרכש בפועל,
/// מהמסך הקורא (לא מקובע כאן לפריט ספציפי אחד).
/// [grantedItems] - רשימת 1-3 שורות "נוסף לחשבון" (איקון+תווית+ערך),
/// לפי מה שהוענק בפועל לרכישה הספציפית הזו (למשל מטבעות/אנרגיה/נקודות
/// באטל פאס) - גם היא מגיעה כפרמטר, לא מקובעת.
/// ⚠️ בכוונה אין כאן שורת "קבלה נשלחה למייל" - באפליקציה הזו אין כרגע
/// מנגנון קבלות/מיילים אמיתי (נבדק מול iap_manager.dart), אז לא הומצאה
/// כאן תכונה שלא קיימת בפועל.
Future<void> showPurchaseCompletePopup(
  BuildContext context, {
  required String itemName,
  required String itemPrice,
  required String itemDescription,
  required List<GrantedItem> grantedItems,
}) {
  const greenGradient = [Color(0xFFBBF7D0), Color(0xFF22C55E), Color(0xFF15803D)];
  return _showFullScreenPopup(
    context,
    Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowBadge(
              gradient: const [Color(0xFF86EFAC), Color(0xFF16A34A)],
              glowColor: const Color(0xFF4ADE80),
              ringColor: const Color(0xFF86EFAC),
              child: const Text("✓", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF0F3D22))),
            ),
            const SizedBox(height: 18),
            const Text("הרכישה הושלמה!", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text("הפריטים כבר בחשבון שלך", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5)),
            const SizedBox(height: 22),
            // כרטיס סיכום הפריט שנרכש
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD86B).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD86B).withValues(alpha: 0.18),
                    ),
                    child: const Center(child: Text("✨", style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemName, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 17, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(itemDescription, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(itemPrice, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerRight,
              child: Text("נוסף לחשבון", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            ...grantedItems.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 22, height: 22, child: Center(child: g.icon)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(g.label, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))),
                        Text(g.value, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFBBF7D0), fontSize: 14, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 26),
            _CtaButton(
              label: "מעולה, בחזרה למשחק",
              gradient: const [Color(0xFF86EFAC), Color(0xFF16A34A)],
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}