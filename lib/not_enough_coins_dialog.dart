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
import 'l10n/app_localizations.dart';

void showNotEnoughCoinsDialog(
  BuildContext context, {
  required int cost,
  required int coins,
  VoidCallback? onReturnedFromShop,
}) {
  // 🩹 נשמר בנפרד מה-context שבתוך builder (ראו ההערה למטה ליד onTap) -
  // זה ה-context של המסך הקורא עצמו (דו-קרב/מרוץ/טורניר), לא של הדיאלוג.
  final callerContext = context;
  showDialog(
    context: context,
    // 🩹 בדיקה אמיתית בהאמולטור: אחרי שחוזרים מהחנות עם "בית" (לא "חזרה"),
    // AppBottomNav._goHome עושה Navigator.popUntil על ה-Navigator *הקרוב*
    // (לא ה-root) - ו-showDialog כברירת מחדל נדחף ל-root navigator. בלי
    // useRootNavigator: false הדיאלוג הזה לא על אותו Navigator שה-popUntil
    // מרוקן, אז הוא נשאר תלוי מעל מסך הבית (לא קורס, לא תקוע - עדיין אפשר
    // לסגור אותו - אבל לא אמור להישאר שם בכלל). עכשיו הוא על אותו Navigator
    // כמו שאר המעברים באפליקציה, אז popUntil מנקה גם אותו.
    useRootNavigator: false,
    builder: (context) {
      final loc = AppLocalizations.of(context)!;
      return Dialog(
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
            Text(loc.notEnoughCoinsTitle, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(loc.notEnoughCoinsMessage(cost, coins),
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.4)),
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
                      Text(loc.notEnoughCoinsMissing((cost - coins).clamp(0, cost)), style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11.5, fontWeight: FontWeight.w900)),
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
                    callerContext,
                    MaterialPageRoute(builder: (context) => ShopScreen(highlightNeededCoins: (cost - coins).clamp(1, cost))),
                  ).then((_) {
                    // 🩹 תוקנה קריסה אמיתית: אם מתוך החנות לוחצים "בית"
                    // (לא "חזרה" רגיל), AppBottomNav._goHome עושה
                    // Navigator.popUntil(isFirst) שמסיר בבת אחת גם את
                    // החנות וגם את המסך שממנו נפתח הדיאלוג הזה (דו-קרב/
                    // מרוץ/טורניר). משותף ל-7 מסכים שונים (דו-קרב/מרוץ/
                    // טורניר רגיל/טורניר מתוזמן) - תיקון כאן מגן על כולם
                    // בבת אחת.
                    //
                    // 🩹 נבדק בפועל באמולטור, פעמיים: גם callerContext.mounted
                    // מיד, וגם אחרי WidgetsBinding.addPostFrameCallback - אף
                    // אחד מהם לא הספיק. פירוק ה-Element בפועל (וה-mounted
                    // flag שלו) נראה שקורה רק אחרי אנימציית היציאה של המסך
                    // (כמה פריימים, לא רק אחד), אז mounted עדיין קורא True
                    // ברגע שהקוד הזה רץ - onReturnedFromShop (=ניסיון הרמז
                    // שוב) מופעל, מגלה שוב "אין מספיק מטבעות", ופותח דיאלוג
                    // *חדש* שצף מעל מסך הבית (לא קורס - נשאר תלוי שם בטעות).
                    // ModalRoute.of(callerContext)?.isCurrent הוא בדיקה
                    // טובה יותר: היא משקפת את רשימת ה-routes בפועל של
                    // ה-Navigator (עדכון סינכרוני בתוך popUntil עצמו), לא
                    // תלויה בתזמון פירוק ה-Element/אנימציה בכלל.
                    final route = ModalRoute.of(callerContext);
                    if (callerContext.mounted && (route?.isCurrent ?? false)) {
                      onReturnedFromShop?.call();
                    }
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)])),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_rounded, color: Color(0xFF2A1740)),
                      const SizedBox(width: 8),
                      Text(loc.notEnoughCoinsShopButton, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.notEnoughCoinsCancelButton, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
            ),
          ],
        ),
      ),
      );
    },
  );
}
