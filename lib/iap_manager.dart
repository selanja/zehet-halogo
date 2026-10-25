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
import 'analytics_service.dart'; // 📊 מעקב רכישות ל-Firebase Analytics/Google Ads
import 'battle_pass_service.dart'; // 🆕 שדרוג "באטל פאס" לפרימיום
import 'tafzoret_service.dart'; // 🆕 דילוג בתשלום על עולם במצב "תפזורת"
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
//   unlock_tafzoret_world            -> In-app product (מתכלה, 2.90 ש"ח) - פתיחת עולם נעול במצב "תפזורת"
  //   energy_2, energy_8, energy_15, energy_30 -> In-app products (מתכלים)
  //   מחירים נקבעים בקונסולה: 2.90 / 10.90 / 19.90 / 29.90 ש"ח
  //   battle_pass_premium              -> In-app product **מתכלה** (₪24.90) -
  //   שדרוג ל"באטל פאס" פרימיום לעונה הנוכחית (ראה battle_pass_service.dart)
  //   🐛 תוקן: היה מוגדר "לא מתכלה" (non-consumable) - אבל זה שגוי לגמרי
  //   למוצר שאמור להירכש מחדש כל עונה (45 יום): מוצר לא-מתכלה נשאר קנוי
  //   *לצמיתות* אצל הקונה, וחנויות (Apple/Google) מאפשרות "שחזור רכישות"
  //   שלו בחינם לכל החיים - כלומר מי שקנה פעם אחת יכול היה ללחוץ "שחזר
  //   רכישות" בכל עונה עתידית ולקבל פרימיום בחינם בלי לשלם שוב אף פעם.
  //   מוצר מתכלה נצרך מיד עם כל רכישה ואי אפשר "לשחזר" אותו בחינם - כל
  //   עונה שהשחקן רוצה פרימיום, הוא צריך לשלם שוב, בדיוק כמו שמתוכנן.
  //   ⚠️ חובה ליצור את המוצר הזה בקונסולות בתור Consumable (לא Non-
  //   Consumable) - אם כבר נוצר כלא-מתכלה ויש לו רכישות אמיתיות, כדאי
  //   מזהה חדש (למשל battle_pass_premium_v2) במקום לשנות את הקיים.
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

  /// 🆕 פתיחת עולם נעול במצב "תפזורת" - מוצר מתכלה (₪2.90), אותו מחיר
  /// ואותו רעיון בדיוק כמו unlockLevelId, רק עם מפתחות/לוגיקה נפרדים
  /// לגמרי (ראו tafzoret_service.dart) כי תפזורת היא מערכת התקדמות
  /// עצמאית מהמשחק הראשי.
  static const String unlockTafzoretWorldId = 'unlock_tafzoret_world';

  /// 🆕 שדרוג "באטל פאס" לפרימיום לעונה הנוכחית - מוצר מתכלה (Consumable,
  /// ראו ההסבר המפורט בבלוק ההערות בראש המחלקה) - נצרך מיד עם כל רכישה,
  /// ונרכש מחדש בכל עונה שהשחקן רוצה פרימיום (ראה battle_pass_service.dart).
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
    noAdsMonthlyId, noAdsLifetimeId, unlockLevelId, unlockTafzoretWorldId,
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

  // 🆕 "בונוס רכישה ראשונה" - הרכישה הראשונה אי-פעם של חבילת מטבעות
  // *קטנה* (ראו _firstPurchaseBonusEligibleIds למטה - לפי בקשה מפורשת
  // מוגבל לחבילות הקטנות בלבד, לא הגדולות) מזכה כפול, חד-פעמי, כדי
  // להוריד את החיכוך הפסיכולוגי של "הרכישה הראשונה" בלי להוריד בפועל
  // את המחיר. "הרכישה הראשונה" עצמה נצרכת (מסומנת) בכל רכישת מטבעות
  // ראשונה, גם אם זו חבילה גדולה - היא פשוט לא מזכה בבונוס במקרה הזה
  // (אין "לשמור" את הזכאות לרכישה קטנה מאוחרת יותר). נבדק/מוגדר ב-
  // _grant() ממש לפני קריאת onPurchaseGranted, כדי שהמסך הקורא
  // (ShopScreen._onPurchaseGranted) יידע להציג את הכמות הכפולה בפועל
  // בפופאפ "הרכישה הושלמה" - לא רק לזכות בשקט בלי שהמשתמש ידע שקיבל בונוס.
  static bool lastGrantWasFirstPurchaseBonus = false;

  static const Map<String, int> _coinPackAmounts = {
    coins100Id: 100,
    coins200Id: 200,
    coins1000Id: 1000,
    coins2500Id: 2500,
    coins6000Id: 6000,
  };
  // 🆕 רק החבילות הקטנות זכאיות לבונוס רכישה ראשונה - 100/200 מטבעות.
  // חבילות גדולות (1000/2500/6000) לא מוכפלות אף פעם, גם ברכישה ראשונה.
  static const Set<String> _firstPurchaseBonusEligibleIds = {coins100Id, coins200Id};

  // 🆕 "ניצחון בטורניר נותן 20% הנחה על כמה חבילות ספציפיות" - לפי בקשה
  // מפורשת. אי אפשר לשנות בפועל את המחיר של מוצר IAP אמיתי מקוד הלקוח
  // (המחיר נקבע בקונסולת החנות לכל מזהה מוצר, בדיוק כמו שאר המוצרים כאן -
  // ראו ההערה הגדולה למעלה) - אז "20% הנחה" ממומש באותה שיטה בדיוק שכבר
  // קיימת פה לבונוס רכישה ראשונה: אותו מחיר מדויק, יותר מטבעות. המכפיל
  // (1.25×) נבחר כך שה"מחיר האפקטיבי" למטבע באמת יורד ב-20% בדיוק
  // (100%/1.25 = 80% מהמחיר למטבע) - לא סתם "+25% בונוס" סתמי.
  // בכוונה *לא* חופף לחבילות הקטנות (100/200) שכבר מכוסות ע"י בונוס
  // הרכישה הראשונה למעלה - ממוקד בחבילות הבינוניות-גדולות (1000/2500/6000),
  // בדיוק "כמה חבילות ספציפיות" כמו שהתבקש, במקום בכולן.
  static const Set<String> tournamentBonusEligibleIds = {coins1000Id, coins2500Id, coins6000Id};
  static const double tournamentBonusMultiplier = 1.25; // = הנחה אפקטיבית של 20% למטבע
  static const int tournamentBonusHours = 24;
  static const String _tournamentBonusExpiryKey = 'tournamentBonusExpiresAt';

  /// נקרא מ-tournament_service.dart כש-rank==0 (ניצחון בפועל, מקום ראשון) -
  /// מפעיל חלון של 24 שעות שבו רכישת אחת מ-tournamentBonusEligibleIds
  /// מזכה 25% יותר מטבעות באותו מחיר בדיוק (ראו _grant למטה).
  static Future<void> activateTournamentBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now().add(const Duration(hours: tournamentBonusHours));
    await prefs.setInt(_tournamentBonusExpiryKey, expiresAt.millisecondsSinceEpoch);
  }

  /// true אם חלון מבצע-האלוף עדיין פעיל כרגע (לשימוש מסך החנות - תג/באנר
  /// "מבצע אלוף!" - ו-_grant בזמן הרכישה עצמה).
  static Future<bool> tournamentBonusActive() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_tournamentBonusExpiryKey);
    if (ms == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(ms).isAfter(DateTime.now());
  }

  /// כמה זמן נשאר למבצע האלוף (Duration.zero אם לא פעיל/פג) - לספירה
  /// לאחור חיה במסך החנות, בדיוק כמו shopStarterPackTimeLeft הקיים.
  static Future<Duration> tournamentBonusRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_tournamentBonusExpiryKey);
    if (ms == null) return Duration.zero;
    final diff = DateTime.fromMillisecondsSinceEpoch(ms).difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // 🆕 כמו lastGrantWasFirstPurchaseBonus - כדי שהמסך הקורא ידע להציג
  // בפופאפ "הרכישה הושלמה" שהכמות כוללת את בונוס ניצחון הטורניר.
  static bool lastGrantWasTournamentBonus = false;

  /// true אם המשתמש עדיין לא ניצל את בונוס הרכישה הראשונה (חבילות מטבעות
  /// קטנות בלבד) - לשימוש מסך החנות כדי להציג את זה *מראש*, לפני הרכישה
  /// (תג "פעם ראשונה = כפול!" על החבילות הקטנות), לא רק לגלות את זה
  /// בפופאפ אחרי שכבר שילמו.
  static Future<bool> firstCoinsPurchaseBonusAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('firstCoinsPurchaseUsed') ?? false);
  }

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

  /// 🩹 טוען מחדש את פרטי המוצרים מהחנות. init() רץ פעם אחת בלבד בפתיחת האפליקציה -
  /// אם באותו רגע לא הייתה רשת/החנות עוד לא הייתה מוכנה, products נשאר ריק
  /// לכל הסשן, והחנות הציגה מחירים (גיבוי) אבל כל לחיצה על "קנה" נכשלה
  /// ("הרכישה אינה זמינה כרגע"). עכשיו ננסה לטעון שוב כשצריך.
  static Future<void> reloadProducts() async {
    try {
      storeAvailable = await _iap.isAvailable();
      if (!storeAvailable) return;
      _sub ??= _iap.purchaseStream.listen(_onPurchaseUpdates, onError: (e) => debugPrint('IAP stream error: $e'));
      final resp = await _iap.queryProductDetails(_productIds);
      if (resp.productDetails.isNotEmpty) products = resp.productDetails;
      if (resp.notFoundIDs.isNotEmpty) debugPrint('IAP: מוצרים שלא נמצאו בקונסולה: ${resp.notFoundIDs}');
    } catch (e) {
      debugPrint('IAP reload error: $e');
    }
  }

  /// התחלת רכישה. מחזיר false אם המוצר לא זמין.
  static Future<bool> buy(String id) async {
    var p = product(id);
    if (p == null) {
      await reloadProducts(); // ניסיון נוסף לפני שמוותרים
      p = product(id);
    }
    if (p == null) return false;
    final param = PurchaseParam(productDetails: p);
    try {
      if (id == coins100Id || id == coins200Id || id == coins1000Id ||
          id == coins2500Id || id == coins6000Id || id == unlockLevelId ||
          id == unlockTafzoretWorldId ||
          _energyProductAmounts.containsKey(id) ||
          starterPackIds.contains(id) ||
          id == battlePassPremiumId) {
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

  // 🐛 תוקן: _grant() רץ תמיד ללא שום בדיקת אידמפוטנטיות, לכל אירוע
  // purchased/restored - אבל אם completePurchase() לא מספיק להסתיים
  // (קריסה/סגירת אפליקציה בדיוק בין _grant() להשלמה, או פשוט
  // restorePurchases() שחוזר על אותה עסקה שוב), החנות (Play/App Store)
  // "מחזירה" את אותה רכישה שוב באתחול הבא - ו-_grant() רץ שוב על אותה
  // עסקה בדיוק, מזכה מטבעות/אנרגיה/קרדיט-פתיחת-רמה פעמיים על תשלום
  // אמיתי אחד. עכשיו שומרים סט של purchaseID-ים שכבר טופלו ומדלגים על
  // grant חוזר לאותו מזהה (ה-completePurchase עדיין רץ כרגיל, כדי
  // שהחנות תפסיק להחזיר את העסקה).
  static const _keyProcessedPurchaseIds = 'iapProcessedPurchaseIds';

  static Future<bool> _alreadyGranted(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return false; // אין מזהה - אי אפשר לזהות כפילות, ממשיכים כרגיל
    final prefs = await SharedPreferences.getInstance();
    final processed = prefs.getStringList(_keyProcessedPurchaseIds) ?? [];
    return processed.contains(purchaseId);
  }

  static Future<void> _markGranted(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final processed = prefs.getStringList(_keyProcessedPurchaseIds) ?? [];
    processed.add(purchaseId);
    // מגבלת בטיחות - לא צריך להחזיק היסטוריה אינסופית, רק מספיק כדי
    // למנוע כפילות קרובה בזמן (redelivery קורה כמעט תמיד תוך דקות/שעות).
    final trimmed = processed.length > 200 ? processed.sublist(processed.length - 200) : processed;
    await prefs.setStringList(_keyProcessedPurchaseIds, trimmed);
  }

  static Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (await _alreadyGranted(purchase.purchaseID)) {
            debugPrint('IAP: מדלג על grant כפול לעסקה ${purchase.purchaseID}');
          } else {
            await _grant(purchase.productID);
            await _markGranted(purchase.purchaseID);
          }
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
      // 🩹 מסמך לפי מזהה העסקה (כשקיים) - במקום add() עם מזהה אקראי - כדי
      // שאותה עסקה שהחנות מחזירה שוב (redelivery/שחזור) לא תיכתב פעמיים
      // (נראה בפרודקשן: אותה עסקה coins_6000 תועדה פעמיים בהפרש 11 שניות).
      final purchasesCol = FirebaseFirestore.instance.collection('purchases');
      final purchaseDoc = (purchase.purchaseID ?? '').isNotEmpty ? purchasesCol.doc(purchase.purchaseID) : purchasesCol.doc();
      await purchaseDoc.set({
        'deviceId': deviceId,
        'productId': purchase.productID,
        'status': purchase.status.name,
        'purchaseId': purchase.purchaseID,
        'transactionDate': purchase.transactionDate,
        'price': details?.rawPrice,
        'currency': details?.currencyCode,
        // 🆕 הקבלה/הטוקן הגולמי מהחנות - כדי שאפשר יהיה לאמת בדיעבד מול
        // Apple/Google אם רכישה אמיתית נראית חשודה (סביבת Sandbox או אמיתית,
        // ואם בכלל קיימת אצלם).
        'verificationSource': purchase.verificationData.source,
        'verificationToken': purchase.verificationData.serverVerificationData,
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
    // 📊 אותו דיווח גם ל-Firebase Analytics (עבור Google Ads) - ראו analytics_service.dart.
    AnalyticsService.logPurchase(
      amount: details.rawPrice,
      currency: details.currencyCode,
      productId: purchase.productID,
    );
  }

  /// מתן התמורה בפועל אחרי רכישה מאושרת
  static Future<void> _grant(String id) async {
    // 🐛 מאופס בכל קריאה - בלי זה, בונוס רכישה ראשונה שהודלק ברכישת
    // מטבעות היה "נדבק" בטעות גם לפופאפ של הרכישה הבאה (למשל ללא-פרסומות)
    // אם היא קרתה מהר מספיק אחריו בלי שהמסך הספיק לקרוא את הדגל.
    lastGrantWasFirstPurchaseBonus = false;
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
    final coinPackBaseAmount = _coinPackAmounts[id];
    if (coinPackBaseAmount != null) {
      final isFirstCoinsPurchase = !(prefs.getBool('firstCoinsPurchaseUsed') ?? false);
      final appliesFirstPurchaseBonus = isFirstCoinsPurchase && _firstPurchaseBonusEligibleIds.contains(id);
      // 🆕 בונוס ניצחון הטורניר לא חל אם כבר חל בונוס הרכישה הראשונה על
      // אותה רכישה בדיוק (אין סיבה/חפיפה מעשית בפועל - הקבוצות זרות לגמרי
      // בכוונה, ראו ההערה ליד tournamentBonusEligibleIds - אבל ה-guard
      // כאן שומר על ההתנהגות חד-משמעית גם אם זה ישתנה בעתיד).
      final appliesTournamentBonus = !appliesFirstPurchaseBonus &&
          tournamentBonusEligibleIds.contains(id) &&
          await tournamentBonusActive();
      lastGrantWasFirstPurchaseBonus = appliesFirstPurchaseBonus;
      lastGrantWasTournamentBonus = appliesTournamentBonus;
      final grantedAmount = appliesFirstPurchaseBonus
          ? coinPackBaseAmount * 2
          : appliesTournamentBonus
              ? (coinPackBaseAmount * tournamentBonusMultiplier).round()
              : coinPackBaseAmount;
      // 🆕 "הרכישה הראשונה" נצרכת כאן על כל רכישת מטבעות ראשונה - גם אם
      // זו חבילה גדולה שלא זכאית לבונוס (אין "לשמור" את הזכאות לפעם הבאה).
      if (isFirstCoinsPurchase) await prefs.setBool('firstCoinsPurchaseUsed', true);
      await prefs.setInt('coins', coins + grantedAmount);
    }
    switch (id) {
      case coins100Id:
      case coins200Id:
      case coins1000Id:
      case coins2500Id:
      case coins6000Id:
        break; // הזיכוי כבר קרה למעלה (כולל בונוס רכישה ראשונה אם רלוונטי)
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
      case unlockTafzoretWorldId:
        await TafzoretService.grantPendingUnlock();
        onLevelUnlocked?.call();
        break;
    }
    // 🩹 קריטי - זו רכישה בכסף אמיתי (מטבעות/באטל פאס/פתיחת רמה/הסרת
    // פרסומות), חייבת להסתנכרן לחשבון Google/Apple מקושר, בדיוק כמו
    // ה-return המוקדם למעלה עבור חבילת מארז הפתיחה.
    PlayerSyncService.syncCurrentProgress();
  }
}