// out_of_resource.dart
//
// 🆕 "כשנגמר משהו (מטבעות/אנרגיה) - שיקפוץ שאפשר לקבל בפרסומת או לקנות בחנות".
// עזרים משותפים למסכי המשחק (לובי דו-קרב, מרוץ, אתגר חבר): כפתורי "צפה
// בפרסומת" ו"קנה בחנות" עם אותם כללי קירור כמו בחנות ובמסך הבית, כדי שאי אפשר
// "לחלוב" יותר מהמותר.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ads_manager.dart';
import 'app_notification.dart';
import 'energy_service.dart';
import 'main_menu_screen.dart';
import 'notification_manager.dart';
import 'player_sync.dart';
import 'reward_popups.dart';
import 'shop_screen.dart';
import 'l10n/app_localizations.dart';

class OutOfResource {
  OutOfResource._();

  // אותו בונוס ואותו קירור כמו "בונוס פרסומת" בחנות (shop_screen.dart._watchDailyAd).
  static const int adCoinsReward = 15;
  static const Duration adCoinsCooldown = Duration(hours: 3);
  static const String _keyLastCoinsAdMs = 'lastAdBonusMillis';

  /// כמה זמן נשאר עד שאפשר לקבל שוב מטבעות מפרסומת - null אם אפשר עכשיו.
  static Future<Duration?> coinsAdRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastCoinsAdMs);
    if (last == null) return null;
    final next = DateTime.fromMillisecondsSinceEpoch(last).add(adCoinsCooldown);
    final remaining = next.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  static String _fmt(BuildContext context, Duration d) {
    final loc = AppLocalizations.of(context)!;
    if (d.inHours >= 1) return loc.outOfResourceTimeHours('${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}');
    return loc.outOfResourceTimeMinutes('${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}');
  }

  /// פרסומת תמורת מטבעות. [onDone] נקרא אחרי שהמטבעות נוספו בפועל.
  static Future<void> watchAdForCoins(BuildContext context, {VoidCallback? onDone}) async {
    final remaining = await coinsAdRemaining();
    if (!context.mounted) return;
    final loc = AppLocalizations.of(context)!;
    if (remaining != null) {
      AppNotification.show(context, loc.outOfResourceAdCoinsCooldownMsg(_fmt(context, remaining)), type: AppNotificationType.warning);
      return;
    }
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(context, loc.outOfResourceNoAdAvailable, type: AppNotificationType.warning);
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      final prefs = await SharedPreferences.getInstance();
      final coins = (prefs.getInt('coins') ?? 15) + adCoinsReward;
      await prefs.setInt('coins', coins);
      await prefs.setInt(_keyLastCoinsAdMs, DateTime.now().millisecondsSinceEpoch);
      PlayerSyncService.syncCurrentProgress();
      NotificationManager.scheduleFreeCoinsReminder();
      MainMenuScreen.onReturnedHome?.call();
      if (!context.mounted) return;
      await showCoinsRewardPopup(
        context,
        rewardAmount: adCoinsReward,
        currentCoins: coins,
        subtitle: AppLocalizations.of(context)!.outOfResourceCoinsRewardSubtitle(adCoinsCooldown.inHours),
      );
      onDone?.call();
    });
  }

  /// פרסומת תמורת אנרגיה. [onDone] נקרא אחרי שהאנרגיה נוספה בפועל.
  static Future<void> watchAdForEnergy(BuildContext context, {VoidCallback? onDone}) async {
    final cooldown = await EnergyService.timeUntilNextAdEnergy();
    if (!context.mounted) return;
    final loc = AppLocalizations.of(context)!;
    if (cooldown != null) {
      AppNotification.show(context, loc.outOfResourceAdEnergyCooldownMsg('${cooldown.inMinutes}:${(cooldown.inSeconds % 60).toString().padLeft(2, '0')}'), type: AppNotificationType.warning);
      return;
    }
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(context, loc.outOfResourceNoAdAvailable, type: AppNotificationType.warning);
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      await EnergyService.addFromAd();
      final energyNow = await EnergyService.getCurrentEnergy();
      MainMenuScreen.onReturnedHome?.call();
      if (!context.mounted) return;
      await showEnergyRewardPopup(
        context,
        rewardAmount: EnergyService.adRewardAmount,
        currentEnergy: energyNow,
        maxEnergy: EnergyService.maxEnergy,
        onDuelTap: () {},
      );
      onDone?.call();
    });
  }

  static Future<void> openShop(BuildContext context, {bool energy = false, int? neededCoins}) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(scrollToEnergy: energy, highlightNeededCoins: neededCoins)));
  }

  /// שני כפתורים מוכנים למסכי "אין מספיק ...": פרסומת + חנות.
  // 🩹 [neededCoins] - כמה מטבעות בדיוק חסרים (אם ידוע למסך הקורא) - כדי
  // שבפתיחת החנות היא תגלול ישר ותדגיש את החבילה הקטנה ביותר שבאמת
  // פותרת את המחסור (ShopScreen.highlightNeededCoins כבר קיים, רק לא
  // היה מחובר מכאן - המשתמש היה מגיע ל"חנות כללית" בלי שום כיוון).
  // 🆕 "המטרה שלנו זה שאנשים יקנו, תסמן בצהוב את הקנה מטבעות בחנות" -
  // כפתור "קנה בחנות" הוא עכשיו הכפתור הראשי (מלא, זהוב), וכפתור הפרסומת
  // הוא המשני (מתאר) - לפי בקשה מפורשת, כדי לדחוף רכישה אמיתית ולא רק
  // תגמול חינמי. סדר ההצגה נשאר אותו דבר (פרסומת למעלה, חנות למטה).
  static List<Widget> offerButtons(
    BuildContext context, {
    required bool coins,
    required VoidCallback onGranted,
    int? neededCoins,
  }) {
    final loc = AppLocalizations.of(context)!;
    Widget filled(String label, VoidCallback onTap) => SizedBox(
          width: 260,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB24D),
              foregroundColor: const Color(0xFF2A1740),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
          ),
        );
    Widget outlined(String label, VoidCallback onTap) => SizedBox(
          width: 260,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        );
    return [
      filled(
        coins ? loc.outOfResourceBuyCoinsButton : loc.outOfResourceBuyEnergyButton,
        () async {
          await openShop(context, energy: !coins, neededCoins: coins ? neededCoins : null);
          onGranted(); // חוזרים מהחנות - בודקים שוב אם עכשיו יש מספיק
        },
      ),
      const SizedBox(height: 10),
      outlined(
        coins ? loc.outOfResourceWatchAdCoins(adCoinsReward) : loc.outOfResourceWatchAdEnergy(EnergyService.adRewardAmount),
        () => coins ? watchAdForCoins(context, onDone: onGranted) : watchAdForEnergy(context, onDone: onGranted),
      ),
    ];
  }
}
