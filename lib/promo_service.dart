// promo_service.dart
//
// 🆕 קידום יזום ללוגו פאס ולחנות - לפי בקשה מפורשת של המשתמש: לפני זה שני
// המסכים האלה היו אך ורק reactive (המשתמש חייב ללחוץ בעצמו כדי להגיע
// אליהם, או נתקל בהם רק כשחסרים לו מטבעות/אנרגיה) - אין שום הצעה יזומה
// מהמשחק. בנוי לפי אותו דפוס בדיוק של ads_manager.dart.onLevelSolved
// (מונה שלבים שנפתרו ב-SharedPreferences, כל N שלבים מפעילים קידום).
//
// 🩹 שונה מדיאלוג מסך-מלא (עם כפתורי "קחו אותי"/"אולי אחר כך") להתראה
// עליונה קטנה שנעלמת לבד - לפי בקשה מפורשת: "נראה לי נואש מידי שאנשים
// יקנו". דיאלוג חוסם שדורש החלטה מרגיש כמו מכירה אגרסיבית; התראה
// שאפשר פשוט להתעלם ממנה (בדיוק כמו כל שאר ההתראות באפליקציה - ראו
// app_notification.dart) מציעה בלי ללחוץ. לחיצה על ההתראה עצמה (לא על
// כפתור נפרד) היא הדרך היחידה לנווט - אם לא נוגעים בה, היא פשוט נעלמת.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_notification.dart';
import 'battle_pass_service.dart';
import 'battle_pass_screen.dart';
import 'shop_screen.dart';
import 'l10n/app_localizations.dart';

class PromoService {
  PromoService._();

  // כל כמה שלבים שנפתרו מוצע קידום - תדיר במכוון (בקשה מפורשת: "הרבה
  // פעמים"), יותר תדיר מהפרסומות (כל 7 שלבים, ראו ads_manager.dart).
  static const int levelsBetweenPromos = 4;

  static const _keySolvedSincePromo = 'solvedSincePromo';
  static const _keyLastPromoWasShop = 'lastPromoWasShop';

  /// נקרא אחרי כל פתרון שלב מוצלח (בדיוק כמו AdsManager.onLevelSolved).
  /// מציג התראה עליונה קצרה כל levelsBetweenPromos שלבים, לסירוגין בין
  /// לוגו פאס לחנות - לא חוסמת, נעלמת לבד אחרי כמה שניות.
  static Future<void> onLevelSolved(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final solved = (prefs.getInt(_keySolvedSincePromo) ?? 0) + 1;
      if (solved < levelsBetweenPromos) {
        await prefs.setInt(_keySolvedSincePromo, solved);
        return;
      }
      await prefs.setInt(_keySolvedSincePromo, 0);

      final showShopThisTime = prefs.getBool(_keyLastPromoWasShop) ?? false; // מתחילים בלוגו פאס
      await prefs.setBool(_keyLastPromoWasShop, !showShopThisTime);

      if (showShopThisTime) {
        if (!context.mounted) return;
        _showPromoToast(context, isShop: true);
      } else {
        // תור הלוגו פאס - אבל רק למי שעוד לא קנה פרימיום לעונה הנוכחית,
        // אין טעם להציע למישהו משהו שכבר יש לו - מציעים חנות במקום כדי
        // שההצעה לא "תתבזבז".
        final hasPremium = await BattlePassService.isPremiumUnlocked();
        if (!context.mounted) return;
        _showPromoToast(context, isShop: hasPremium);
      }
    } catch (_) {
      // קידום הוא תוספת לא-קריטית - כשל בו לעולם לא אמור לעצור את המשחק.
    }
  }

  static void _showPromoToast(BuildContext context, {required bool isShop}) {
    final loc = AppLocalizations.of(context)!;
    AppNotification.show(
      context,
      isShop ? loc.promoShopBody : loc.promoLogoPassBody,
      color: isShop ? const Color(0xFF16A46F) : const Color(0xFFB8860A),
      duration: const Duration(seconds: 5),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => isShop ? const ShopScreen() : const BattlePassScreen()));
      },
    );
  }
}
