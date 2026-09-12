// iap_manager.dart
// רכישות אמיתיות בתוך האפליקציה (In-App Purchase):
// - חבילות מטבעות (מוצרים מתכלים)
// - מנוי "ללא פרסומות": 15 ש"ח לחודש (מנוי) או 40 ש"ח לכל החיים (חד-פעמי)
//
// ⚠️ חשוב: רכישות עובדות רק אחרי שהאפליקציה הועלתה לחנות
// והמוצרים נוצרו שם עם אותם מזהים בדיוק (ראה רשימה למטה).
// בהרצה מקומית/אמולטור החנות תציג "זמין בגרסת החנות".
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'energy_service.dart'; // 🆕 חבילות אנרגיה בתשלום
import 'device_id.dart'; // 🆕 לתיעוד רכישות ב-Firestore לפי מכשיר
import 'meta_events_service.dart'; // 🆕 מעקב רכישות ל-Meta Ads (אופטימיזציית קמפיין)
import 'battle_pass_service.dart'; // 🆕 שדרוג "באטל פאס" לפרימיום
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי רכישה אמיתית - קריטי במיוחד כאן (כסף אמיתי), בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה את הרכישה במכשיר אחר

class IapManager {
  // ================================================================
  // 🔴 מזהי המוצרים - חובה ליצור אותם בקונסולת המפתחים של החנות
  // עם המזהים האלה בדיוק:
  //   coins_100, coins_200, coins_1000, coins_2500, coins_6000 -> In-app products (מתכלים)
  //   מחירים נקבעים בקונסולה: 5.90 / 10 / 35 / 80 / 160 ש"ח
  //   no_ads_lifetime                  -> In-app product (חד-פעמי, 40 ש"ח)
  //   no_ads_monthly                   -> Subscription (15 ש"ח לחודש)
//   unlock_level                     -> In-app product (מתכלה, 2.90 ש"ח) - פתיחת רמה נעולה
  //   energy_2, energy_8, energy_15, energy_30 -> In-app products (מתכלים)
  //   מחירים נקבעים בקונסולה: 2.90 / 10.90 / 19.90 / 29.90 ש"ח
  //   battle_pass_premium              -> In-app product (חד-פעמי, ₪14.90) -
  //   שדרוג ל"באטל פאס" פרימיום לעונה הנוכחית (ראה battle_pass_service.dart)
  // המחירים נקבעים בקונסולה, לא בקוד.
  // ================================================================
  static const String coins100Id = 'coins_100';
  static const String coins200Id = 'coins_200';
  static const String coins1000Id = 'coins_1000';
  static const String coins2500Id = 'coins_2500';
  static const String coins6000Id = 'coins_6000';
  static const String noAdsMonthlyId = 'no_ads_monthly';
  static const String noAdsLifetimeId = 'no_ads_lifetime';

  // 🆕 "מארז פתיחה" (Starter Pack) - הצעה חד-פעמית למשתמשים חדשים,
  // מוגבלת ל-3 שעות בלבד (ראו starter_pack_service.dart). כדי שההצעה
  // לא תרגיש "תמיד אותו דבר", יש 7 מארזים שונים בשני מחירים - בכל
  // הפעלה חדשה (שעדיין לא ראתה הצעה) נבחר אחד מהם רנדומלית (מכל
  // השבעה, בלי קשר למחיר) ונשמר קבוע למשתמש הזה.
  // 🔴 חובה ליצור את 7 המוצרים האלה בקונסולת החנות, עם המחירים
  // המדויקים המצוינים ליד כל אחד (המחיר נקבע בקונסולה, לא בקוד):
  //   starter_pack_a  -> ₪10.90  (250 מטבעות + 4 אנרגיה)
  //   starter_pack_b  -> ₪10.90  (150 מטבעות + 10 אנרגיה)
  //   starter_pack_c  -> ₪10.90  (350 מטבעות)
  //   starter_pack_d  -> ₪5.90   (120 מטבעות + 2 אנרגיה)
  //   starter_pack_e  -> ₪5.90   (70 מטבעות + 4 אנרגיה)
  //   starter_pack_f  -> ₪5.90   (50 מטבעות + 6 אנרגיה)
  //   starter_pack_g  -> ₪5.90   (150 מטבעות)
  static const String starterPackAId = 'starter_pack_a';
  static const String starterPackBId = 'starter_pack_b';
  static const String starterPackCId = 'starter_pack_c';
  static const String starterPackDId = 'starter_pack_d';
  static const String starterPackEId = 'starter_pack_e';
  static const String starterPackFId = 'starter_pack_f';
  static const String starterPackGId = 'starter_pack_g';
  static const List<String> starterPackIds = [
    starterPackAId, starterPackBId, starterPackCId,
    starterPackDId, starterPackEId, starterPackFId, starterPackGId,
  ];

  /// תוכן כל מארז - מטבעות + אנרגיה, שונה בין המארזים כדי שההצעה תרגיש
  /// מגוונת.
  static const Map<String, int> starterPackCoins = {
    starterPackAId: 250,
    starterPackBId: 150,
    starterPackCId: 350,
    starterPackDId: 120,
    starterPackEId: 70,
    starterPackFId: 50,
    starterPackGId: 150,
  };
  static const Map<String, int> starterPackEnergy = {
    starterPackAId: 4,
    starterPackBId: 10,
    starterPackCId: 0,
    starterPackDId: 2,
    starterPackEId: 4,
    starterPackFId: 6,
    starterPackGId: 0,
  };

  // 🩹 מחיר "רגיל/מתוכנן" לכל מארז - זהה למה שכתוב למעלה שצריך להגדיר
  // בקונסולת החנות. משמש כ*גיבוי בלבד* לתצוגה בדיאלוג המארז (ראה
  // starter_pack_dialog.dart) למקרה שהמוצר האמיתי מהחנות עוד לא נטען
  // (למשל: אין רשת כרגע, החנות לא זמינה בהרצה מקומית, או שהמוצר עוד לא
  // נוצר בקונסולה) - כדי שהכפתור לעולם לא יציג "קבל הכל" בלי שום מחיר.
  // ⚠️ ברגע שהחנות זמינה והמוצר נטען בהצלחה, המחיר האמיתי מהחנות (עם
  // המטבע/עיצוב המקומי הנכון למדינת המשתמש) תמיד גובר על הגיבוי הזה.
  static const Map<String, double> starterPackFallbackPrice = {
    starterPackAId: 10.90,
    starterPackBId: 10.90,
    starterPackCId: 10.90,
    starterPackDId: 5.90,
    starterPackEId: 5.90,
    starterPackFId: 5.90,
    starterPackGId: 5.90,
  };

  /// תווית מחיר גיבוי מוצגת ("₪10.90") - ראה starterPackFallbackPrice.
  static String starterPackFallbackPriceLabel(String id) {
    final price = starterPackFallbackPrice[id];
    if (price == null) return "";
    return "₪${price.toStringAsFixed(2)}";
  }

  /// פתיחת רמה נעולה - מוצר מתכלה (₪2.90). כל רכישה פותחת רמה אחת.
  static const String unlockLevelId = 'unlock_level';

  /// 🆕 שדרוג "באטל פאס" לפרימיום לעונה הנוכחית - מוצר חד-פעמי (לא
  /// מתכלה), נשאר "פעיל" עד סוף העונה (ראה battle_pass_service.dart).
  static const String battlePassPremiumId = 'battle_pass_premium';

  // 🆕 חבילות אנרגיה בתשלום - כל אחת מזכה בכמות קבועה, בלי תקרה של 8
  // (ראו EnergyService.addFromPurchase).
  static const String energy2Id = 'energy_2';
  static const String energy8Id = 'energy_8';
  static const String energy15Id = 'energy_15';
  static const String energy30Id = 'energy_30';
  static const Map<String, int> _energyProductAmounts = {
    energy2Id: 2,
    energy8Id: 8,
    energy15Id: 15,
    energy30Id: 30,
  };

  static const Set<String> _productIds = {
    coins100Id, coins200Id, coins1000Id, coins2500Id, coins6000Id,
    noAdsMonthlyId, noAdsLifetimeId, unlockLevelId,
    energy2Id, energy8Id, energy15Id, energy30Id,
    starterPackAId, starterPackBId, starterPackCId,
    starterPackDId, starterPackEId, starterPackFId, starterPackGId,
    battlePassPremiumId,
  };

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;

  static bool storeAvailable = false;
  static List<ProductDetails> products = [];

  /// האם למשתמש יש מנוי/רכישת "ללא פרסומות" (נשמר במכשיר)
  static bool noAds = false;

  /// callback שמסכים יכולים לרשום כדי להתרענן אחרי רכישה
  static VoidCallback? onPurchasesUpdated;

  /// נקרא אחרי שרכישת "פתיחת רמה" אושרה והרמה נפתחה בפועל.
  /// מסך הרמות רושם אותו כדי לרענן את התצוגה מיד.
  static VoidCallback? onLevelUnlocked;

  /// 🆕 callback שנקרא מיד אחרי שהתמורה על רכישה אמיתית מוצלחת (purchased/
  /// restored) ניתנה בפועל בצד הלקוח (_grant הסתיים), עם מזהה המוצר
  /// שנרכש. בשונה מ-onPurchasesUpdated (שהוא "משהו התעדכן, תרענן"
  /// כללי בלי פרטים) - זה מיועד למסך חנות שרוצה להציג פופאפ "הרכישה
  /// הושלמה" עם פרטי הפריט הספציפי שנקנה עכשיו (ראו reward_popups.dart,
  /// showPurchaseCompletePopup). הקוד עצמו context-less (סטטי, בלי
  /// BuildContext) - לכן המסך הקורא (למשל ShopScreen) הוא זה שממפה את
  /// מזהה המוצר לתוכן הפופאפ ומציג אותו.
  static void Function(String productId)? onPurchaseGranted;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      noAds = prefs.getBool('noAds') ?? false;

      storeAvailable = await _iap.isAvailable();
      if (!storeAvailable) {
        debugPrint('IAP: חנות לא זמינה (רגיל בהרצה מקומית)');
        return;
      }

      // מאזין קבוע לעדכוני רכישות (כולל שחזורים)
      _sub ??= _iap.purchaseStream.listen(_onPurchaseUpdates,
          onError: (e) => debugPrint('IAP stream error: $e'));

      final resp = await _iap.queryProductDetails(_productIds);
      products = resp.productDetails;
      if (resp.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: מוצרים שלא נמצאו בקונסולה: ${resp.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('IAP init error: $e');
    }
  }

  /// רושם איזו רמה המשתמש מבקש לפתוח, לפני שמתחילים את הרכישה
  static Future<void> setPendingUnlock(int world, int firstPuzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pendingUnlockWorld', world);
    await prefs.setInt('pendingUnlockFirstPuzzle', firstPuzzleId);
  }

  /// כמה פתיחות ששולמו עליהן עדיין לא מומשו
  static Future<int> unlockCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('unlockCredits') ?? 0;
  }

  /// מממש קרדיט פתיחה אחד. מחזיר true אם היה קרדיט זמין.
  static Future<bool> consumeUnlockCredit() async {
    final prefs = await SharedPreferences.getInstance();
    int n = prefs.getInt('unlockCredits') ?? 0;
    if (n <= 0) return false;
    await prefs.setInt('unlockCredits', n - 1);
    return true;
  }

  /// שליפת פרטי מוצר לפי מזהה (null אם לא נטען)
  static ProductDetails? product(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// התחלת רכישה. מחזיר false אם המוצר לא זמין.
  static Future<bool> buy(String id) async {
    final p = product(id);
    if (p == null) return false;
    final param = PurchaseParam(productDetails: p);
    try {
      if (id == coins100Id || id == coins200Id || id == coins1000Id ||
          id == coins2500Id || id == coins6000Id || id == unlockLevelId ||
          _energyProductAmounts.containsKey(id) ||
          starterPackIds.contains(id)) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
      return true;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return false;
    }
  }

  /// שחזור רכישות (למשל אחרי החלפת מכשיר) - חובה לפי כללי החנויות
  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore error: $e');
    }
  }

  static Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant(purchase.productID);
          // 🆕 מדווח למסך הקורא (אם רשם את עצמו) שהתמורה על המוצר הזה
          // ניתנה בפועל - כדי שיוכל להציג פופאפ "הרכישה הושלמה" עם
          // פרטי המוצר. לא רלוונטי ל-restored (שחזור רכישות ישנות בלי
          // שהמשתמש עשה כרגע שום פעולה) - רק לרכישה חדשה בפועל.
          if (purchase.status == PurchaseStatus.purchased) {
            onPurchaseGranted?.call(purchase.productID);
          }
          // 🆕 מתעד את הרכישה ב-Firestore (collection 'purchases') כדי
          // שיהיה מעקב אמיתי - לא חוסם/מעכב את מתן התמורה למשתמש, ולא
          // מפיל כלום אם זה נכשל (אין אינטרנט וכו') - זו תוספת מעקב,
          // לא חלק קריטי מהרכישה עצמה.
          _logPurchaseToFirestore(purchase);
          // 🆕 מדווח את הרכישה גם ל-Meta (לא חוסם, לא מפיל כלום אם נכשל) -
          // כדי שקמפיין Meta Ads יוכל למדוד המרות תשלום אמיתיות, לא רק התקנות.
          _reportPurchaseToMeta(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('IAP purchase error: ${purchase.error}');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
    }
    onPurchasesUpdated?.call();
  }

  /// 🆕 שומר תיעוד של הרכישה ב-Firestore, ל-collection בשם 'purchases' -
  /// מסמך חדש לכל רכישה (auto-id), כדי שתוכל לעקוב בקלות אחרי כל רכישה
  /// שקרתה (מתי, מה, על ידי איזה מכשיר, באיזה פלטפורמה, ומה המחיר/מטבע
  /// המדויקים כפי שהוחזרו מהחנות - אם היו זמינים). לא קריטי לרכישה
  /// עצמה - אם זה נכשל (למשל אין אינטרנט כרגע), המשתמש עדיין מקבל את
  /// מה שקנה כרגיל, פשוט לא יהיה תיעוד לרכישה הספציפית הזו.
  static Future<void> _logPurchaseToFirestore(PurchaseDetails purchase) async {
    try {
      final deviceId = await DeviceId.get();
      final details = product(purchase.productID);
      await FirebaseFirestore.instance.collection('purchases').add({
        'deviceId': deviceId,
        'productId': purchase.productID,
        'status': purchase.status.name,
        'purchaseId': purchase.purchaseID,
        'transactionDate': purchase.transactionDate,
        'price': details?.rawPrice,
        'currency': details?.currencyCode,
        'priceLabel': details?.price,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('IAP purchase logging error: $e');
    }
  }

  /// מדווח את הרכישה גם ל-Meta Events (ראו meta_events_service.dart) -
  /// כדי שקמפיין Meta Ads יוכל למדוד המרות תשלום אמיתיות ולבצע
  /// אופטימיזציה לפי זה, לא רק למדוד התקנות. לא קריטי - עטוף ב-try/catch
  /// משלו בתוך MetaEventsService.logPurchase, אז אף פעם לא מפיל את הרכישה.
  static void _reportPurchaseToMeta(PurchaseDetails purchase) {
    final details = product(purchase.productID);
    if (details == null) return; // אין מחיר/מטבע ידועים - אין מה לדווח
    MetaEventsService.logPurchase(
      amount: details.rawPrice,
      currency: details.currencyCode,
      productId: purchase.productID,
    );
  }

  /// מתן התמורה בפועל אחרי רכישה מאושרת
  static Future<void> _grant(String id) async {
    // 🆕 חבילות אנרגיה - מטופלות בנפרד לפני ה-switch (לא נוגעות במטבעות
    // בכלל), כי הכמות תלויה במוצר (ראה _energyProductAmounts).
    final energyAmount = _energyProductAmounts[id];
    if (energyAmount != null) {
      await EnergyService.addFromPurchase(energyAmount);
      return;
    }

    // 🆕 "מארז פתיחה" - מזכה גם מטבעות וגם (בחלק מהמארזים) אנרגיה יחד,
    // ומסמן שהמארז נרכש כדי ש-StarterPackService לא יציע אותו שוב.
    if (starterPackIds.contains(id)) {
      final prefsSp = await SharedPreferences.getInstance();
      final coinsToAdd = starterPackCoins[id] ?? 0;
      final energyToAdd = starterPackEnergy[id] ?? 0;
      if (coinsToAdd > 0) {
        int coinsNow = prefsSp.getInt('coins') ?? 15;
        await prefsSp.setInt('coins', coinsNow + coinsToAdd);
      }
      if (energyToAdd > 0) {
        await EnergyService.addFromPurchase(energyToAdd);
      }
      await prefsSp.setBool('starterPackPurchased', true);
      PlayerSyncService.syncCurrentProgress(); // 🩹 קריטי - זו רכישה בכסף אמיתי, חייבת להסתנכרן לחשבון Google/Apple מקושר
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int coins = prefs.getInt('coins') ?? 15;
    switch (id) {
      case coins100Id:
        await prefs.setInt('coins', coins + 100);
        break;
      case coins200Id:
        await prefs.setInt('coins', coins + 200);
        break;
      case coins1000Id:
        await prefs.setInt('coins', coins + 1000);
        break;
      case coins2500Id:
        await prefs.setInt('coins', coins + 2500);
        break;
      case coins6000Id:
        await prefs.setInt('coins', coins + 6000);
        break;
      case noAdsMonthlyId:
      case noAdsLifetimeId:
        noAds = true;
        await prefs.setBool('noAds', true);
        break;
      case battlePassPremiumId:
        await BattlePassService.markPremiumPurchased();
        break;
      case unlockLevelId:
        // הרמה שהמשתמש ביקש לפתוח נשמרה לפני הרכישה. אם משהו השתבש -
        // שומרים "קרדיט" שימומש בפעם הבאה שייפתח מסך הרמות.
        int world = prefs.getInt('pendingUnlockWorld') ?? 0;
        int firstPuzzle = prefs.getInt('pendingUnlockFirstPuzzle') ?? 0;
        if (world > 0 && firstPuzzle > 0) {
          int current = prefs.getInt('maxLevel') ?? 1;
          if (firstPuzzle > current) {
            // העולם נפתח "מוקדם" - לפני שההתקדמות הרגילה הגיעה אליו.
            // ⚠️ בכוונה לא נוגעים כאן ב-maxLevel הגלובלי! עדכון שלו
            // היה מסמן בטעות את כל הרמות הקודמות שלא נפתרו כאילו
            // נפתרו (כי sub_levels_screen.dart קובע "הושלם" לפי
            // puzzleId < maxLevel). במקום זה שומרים את העולם הזה
            // כ"נרכש בנפרד" עם סמן התקדמות פנימי משלו, שמתחיל מ-0
            // פתרונות (הפאזל הראשון שלו) - כך הרמה הקודמת נשארת בדיוק
            // איפה שהייתה, וגם הרמה החדשה נפתחת ופתירה מההתחלה שלה.
            // ⚠️ אותו מנגנון קיים ב-levels_screen.dart וב-sub_levels_screen.dart.
            List<String> purchased = prefs.getStringList('purchasedWorlds') ?? [];
            String worldKey = world.toString();
            if (!purchased.contains(worldKey)) {
              purchased.add(worldKey);
              await prefs.setStringList('purchasedWorlds', purchased);
            }
            String cursorKey = 'worldCursor_$world';
            if ((prefs.getInt(cursorKey) ?? 0) < firstPuzzle) {
              await prefs.setInt(cursorKey, firstPuzzle);
            }
          }
          // אם firstPuzzle <= current - העולם כבר נגיש דרך ההתקדמות
          // הרגילה, אין צורך לעשות כלום נוסף.
          await prefs.remove('pendingUnlockWorld');
          await prefs.remove('pendingUnlockFirstPuzzle');
        } else {
          await prefs.setInt('unlockCredits', (prefs.getInt('unlockCredits') ?? 0) + 1);
        }
        onLevelUnlocked?.call();
        break;
    }
    // 🩹 קריטי - זו רכישה בכסף אמיתי (מטבעות/באטל פאס/פתיחת רמה/הסרת
    // פרסומות), חייבת להסתנכרן לחשבון Google/Apple מקושר, בדיוק כמו
    // ה-return המוקדם למעלה עבור חבילת מארז הפתיחה.
    PlayerSyncService.syncCurrentProgress();
  }
}