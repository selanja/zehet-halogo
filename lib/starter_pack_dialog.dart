// starter_pack_dialog.dart
//
// 🆕 דיאלוג הצעת "מארז פתיחה" (Starter Pack) - מוצג פעם אחת (או עד
// שהחלון של 48 שעות נגמר) למשתמשים חדשים שכבר סיימו לפחות 2 רמות.
// עיצוב עקבי עם שאר האפליקציה (רקע סגול כהה + זהב, בהשראת shop_screen.dart).
//
// שימוש: ראו main_menu_screen.dart - נקרא מ-initState (postFrameCallback)
// עם התוצאה של StarterPackService.variantToShow(maxLevel: ...).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';
import 'starter_pack_service.dart';
import 'app_icons.dart';
import 'app_notification.dart';

class StarterPackDialog extends StatefulWidget {
  final String variantId; // starter_pack_a/b/c
  const StarterPackDialog({super.key, required this.variantId});

  /// פותח את הדיאלוג. לא זורק אם ה-context כבר לא תקף.
  static Future<void> show(BuildContext context, String variantId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StarterPackDialog(variantId: variantId),
    );
  }

  // 🆕 מציג את הצעת המארז (אם זכאי) ברגע חיכוך אמיתי - למשל "אין מספיק
  // מטבעות"/"נגמרה האנרגיה" - במקום להמתין לחזרה הבאה למסך הבית
  // (ראו main_menu_screen.dart._maybeShowStarterPack). זה בדיוק הרגע
  // שבו משתמש חדש הכי פתוח לרכישה - הוא כבר נתקל בבעיה שהמארז פותר.
  // "פעם אחת בלבד" (starterPackAutoShown) עדיין חל - אם היא כבר הוצגה
  // (מכאן או ממסך הבית), לא מוצגת שוב. מחזיר true אם ההצעה הוצגה בפועל
  // (שימושי כדי לדעת אם צריך גם להציג הודעה/דיאלוג חלופי אחר).
  static Future<bool> maybeShowAtFriction(BuildContext context, {required int maxLevel}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('starterPackAutoShown') ?? false) return false;
    final variant = await StarterPackService.variantToShow(maxLevel: maxLevel);
    if (variant == null || !context.mounted) return false;
    await prefs.setBool('starterPackAutoShown', true);
    await show(context, variant);
    return true;
  }

  @override
  State<StarterPackDialog> createState() => _StarterPackDialogState();
}

class _StarterPackDialogState extends State<StarterPackDialog> {
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _refreshCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshCountdown());
  }

  Future<void> _refreshCountdown() async {
    final left = await StarterPackService.remaining();
    if (!mounted) return;
    setState(() => _left = left ?? Duration.zero);
    if (left != null && left == Duration.zero) {
      _timer?.cancel();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Future<void> _buy() async {
    setState(() => _buying = true);
    final ok = await IapManager.buy(widget.variantId);
    if (!mounted) return;
    setState(() => _buying = false);
    if (!ok) {
      AppNotification.show(context, "הרכישה אינה זמינה כרגע, נסה שוב מאוחר יותר", type: AppNotificationType.error);
      return;
    }
    // הרכישה בפועל מטופלת אסינכרונית ב-IapManager.purchaseStream - סוגרים
    // את הדיאלוג מיד, המטבעות/אנרגיה יתעדכנו כשה-stream יחזיר תשובה.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final coins = IapManager.starterPackCoins[widget.variantId] ?? 0;
    final energy = IapManager.starterPackEnergy[widget.variantId] ?? 0;
    final product = IapManager.product(widget.variantId);
    // 🩹 אם המוצר האמיתי מהחנות עוד לא נטען (למשל אין רשת כרגע, או
    // שהמוצר עוד לא נוצר בקונסולה) - במקום להציג "קבל הכל" בלי שום
    // מחיר, נופלים למחיר הגיבוי שכבר מוגדר בקוד (ראה
    // IapManager.starterPackFallbackPrice). ברגע שהמוצר האמיתי נטען,
    // הוא תמיד גובר.
    final priceLabel = product?.price ?? IapManager.starterPackFallbackPriceLabel(widget.variantId);
    // 🆕 "שווי X · חיסכון Y%" - בדיוק כמו במוקאפ (מסך 12 · מארז פתיחה),
    // מחושב אמיתית לפי המחיר הרגיל של מטבעות/אנרגיה בחנות עצמה
    // (חבילת זהב 200 מטבעות ב-₪10, מטען קטן 2 אנרגיה ב-₪2.90) - לא
    // מספר בדוי.
    const double coinUnitPrice = 10.0 / 200;
    const double energyUnitPrice = 2.90 / 2;
    final double rawPrice = product?.rawPrice ?? (IapManager.starterPackFallbackPrice[widget.variantId] ?? 0);
    final String currencySymbol = product?.currencySymbol ?? "₪";
    final double estValue = coins * coinUnitPrice + energy * energyUnitPrice;
    final int discountPct = (rawPrice > 0 && estValue > rawPrice) ? (100 - (rawPrice / estValue * 100)).round() : 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A2668), Color(0xFF1D0E3C)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFC64B).withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFFC64B).withValues(alpha: 0.25), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 עיצוב מחדש - תג "מוגבל בזמן" + אייקון מתנה ריבועי-גרדיאנט,
            // בדיוק כמו המוקאפ (מסך 12 · מארז פתיחה).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D74)]),
              ),
              child: const Text("מוגבל בזמן", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 14),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)]),
                boxShadow: [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.4), blurRadius: 22)],
              ),
              // 🩹 תוקן: היה אימוג'י (🎁) - אותה בעיית תאימות מתועדת כמו
              // אימוג'י המטבע/אנרגיה (ראו app_icons.dart).
              child: const Center(child: Icon(Icons.card_giftcard_rounded, color: Color(0xFF2A1740), size: 34)),
            ),
            const SizedBox(height: 14),
            const Text("מארז פתיחה",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFFD86B), fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text("פג בעוד ${_fmt(_left)}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFB7185), fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            // 🆕 עיצוב מחדש - קופסאות ריבועיות קבועות-רוחב זו-ליד-זו
            // במרכז (בדיוק כמו במוקאפ), במקום קופסאות שנמתחות לכל הרוחב.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (coins > 0)
                  Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1B4D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFC64B).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        const CoinIcon(size: 24),
                        const SizedBox(height: 6),
                        Text("$coins", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                if (energy > 0)
                  Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A5A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const EnergyIcon(size: 24),
                        const SizedBox(height: 6),
                        Text("$energy", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            // 🆕 עיצוב מחדש - כפתור אחד גדול "קבל הכל · [מחיר]" עם שורת
            // "שווי/חיסכון" קטנה מתחתיו בתוך אותו כפתור, בדיוק כמו במוקאפ -
            // במקום מחיר בנפרד מעל כפתור "קנה עכשיו".
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _buying ? null : _buy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _buying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("קבל הכל · $priceLabel", style: const TextStyle(color: Color(0xFF2A1740), fontSize: 16.5, fontWeight: FontWeight.w900)),
                            if (discountPct > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                "שווי $currencySymbol${estValue.toStringAsFixed(0)} · חיסכון $discountPct%",
                                style: const TextStyle(color: Color(0xFF5C3A1A), fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("לא תודה", style: TextStyle(color: Colors.white54, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}