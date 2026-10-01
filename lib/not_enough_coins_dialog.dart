// not_enough_coins_dialog.dart
//
// 🆕 דיאלוג "אין מספיק מטבעות" משותף - עד עכשיו רק logo_level_screen.dart
// (חלון הרמזים) קישר בפועל לחנות; דו-קרב/מירוץ/הימור הציגו רק הודעת
// שגיאה חולפת (AppNotification) בלי אפשרות לקנות ישר משם - הרגע הכי
// טוב לרכישה היה מפוספס. הדיאלוג הזה זהה בעיצובו לחלון של logo_level_screen.dart
// (בלי אופציית "צפה בפרסומת לרמז" - זו ספציפית לחידה בודדת), ומעביר
// ל-ShopScreen עם highlightNeededCoins כדי שהחבילה הנכונה תודגש שם.
import 'package:flutter/material.dart';
import 'app_icons.dart';
import 'shop_screen.dart';

void showNotEnoughCoinsDialog(
  BuildContext context, {
  required int cost,
  required int coins,
  VoidCallback? onReturnedFromShop,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.22), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20))],
        ),
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.35), const Color(0xFFFFD86B).withValues(alpha: 0.0)]),
              ),
              child: const CoinIcon(size: 36),
            ),
            const SizedBox(height: 20),
            const Text("אין לך מספיק מטבעות", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text("זה עולה $cost מטבעות ויש לך רק $coins",
                textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.4)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.05), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (coins / cost).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD86B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("חסרים ${(cost - coins).clamp(0, cost)}", style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11.5, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 3),
                      const CoinIcon(size: 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ShopScreen(highlightNeededCoins: (cost - coins).clamp(1, cost))),
                  ).then((_) => onReturnedFromShop?.call());
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)])),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_rounded, color: Color(0xFF2A1740)),
                      SizedBox(width: 8),
                      Text("לחנות המטבעות", style: TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
            ),
          ],
        ),
      ),
    ),
  );
}
