// shop_screen.dart
// חנות המשחק: בונוס פרסומת כל 3 שעות בראש החנות, כרטיס "הכי משתלם",
// רשת חבילות מטבעות 2x2, ומנוי ללא פרסומות.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_background.dart';
import 'iap_manager.dart';
import 'ads_manager.dart';
import 'energy_service.dart'; // 🆕 פיל אנרגיה בכותרת החנות, לפי העיצוב מחדש
import 'audio_manager.dart';
import 'notification_manager.dart';
import 'coupon_service.dart';
import 'device_id.dart';
import 'package:url_launcher/url_launcher.dart';
import 'debug_log.dart';
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון משותף - מופיע גם כאן, לא רק במסך הבית
import 'starter_pack_service.dart'; // 🆕 מארז פתיחה - זכאות/וריאנט/ספירה לאחור
import 'starter_pack_dialog.dart'; // 🆕 מארז פתיחה - דיאלוג הרכישה עצמו
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי כל שינוי מטבעות - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון במכשיר אחר
import 'reward_popups.dart'; // 🆕 פופאפי "קיבלת אנרגיה"/"קיבלת מטבעות"/"הרכישה הושלמה" החדשים
import 'main_menu_screen.dart'; // 🩹 MainMenuScreen.onReturnedHome - לרענון מיידי של המטבעות/אנרגיה במסך הבית

class ShopScreen extends StatefulWidget {
  // 🆕 כשנפתחים לכאן מכרטיס "ללא פרסומות" בתפריט הראשי - גוללים אוטומטית
  // ישר לאזור הזה בחנות, במקום להשאיר את המשתמש למעלה וצריך לחפש בעצמו.
  final bool scrollToNoAds;
  // 🆕 כנ"ל - כשנפתחים לכאן ממסך "נגמרה האנרגיה" (כפתור "קנה בחנות ⚡")
  // גוללים ישר לאזור "חנות האנרגיה".
  final bool scrollToEnergy;
  const ShopScreen({super.key, this.scrollToNoAds = false, this.scrollToEnergy = false});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // ⏰ כל כמה זמן אפשר לקבל שוב את בונוס ה-15 המטבעות תמורת פרסומת
  static const Duration adCooldown = Duration(hours: 3);

  int currentCoins = 0;
  int currentEnergy = 0; // 🆕 מוצג עכשיו גם בחנות (פיל בכותרת), לפי העיצוב מחדש
  bool dailyAdAvailable = true; // בונוס תמורת פרסומת - זמין כל 3 שעות
  Duration remaining = Duration.zero; // כמה זמן נשאר עד שהבונוס הבא זמין
  Timer? _cooldownTicker;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _noAdsSectionKey = GlobalKey();
  final GlobalKey _energySectionKey = GlobalKey();

  // 🆕 מימוש קוד קופון
  final TextEditingController _couponController = TextEditingController();
  bool _redeemingCoupon = false;

  // 🆕 באנר "מארז פתיחה" בולט למעלה - מוצג רק אם למשתמש יש הצעה פעילה
  // וממתינה (כבר הוצגה פעם, עוד לא נרכשה, עוד בתוך חלון 3 השעות) - כדי
  // שאם הוא סגר את הדיאלוג בלי לקנות, הוא עדיין יוכל למצוא ולהשלים את
  // הרכישה מהחנות. ראו starter_pack_service.dart.
  String? _starterPackVariant;
  Duration? _starterPackRemaining;
  Timer? _starterPackTicker;

  // 🆕 לשמירת ה-callback הקודם (אם היה) לפני שרושמים את שלנו - כמו
  // הדפוס הקיים ב-battle_pass_screen.dart ל-onPurchasesUpdated - כדי
  // שלא "נגנוב" רישום ממסך אחר שנרשם לפני שהמסך הזה נפתח.
  void Function(String productId)? _prevOnPurchaseGranted;

  @override
  void initState() {
    super.initState();
    DebugLog.add("ShopScreen.initState START (scrollToNoAds=${widget.scrollToNoAds})");
    AdsManager.recordBrowseNavigation(); // 🆕 "גלישה בלי לשחק"
    _loadCoins();
    _checkAdCooldown();
    _loadStarterPackOffer();
    DebugLog.add("ShopScreen.initState END");
    // מרעננים כל שנייה כדי שהטיימר על הכפתור יתעדכן בזמן אמת
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) => _checkAdCooldown());
    // 🆕 מרעננים כל שנייה גם את ספירת הזמן שנשארה למארז הפתיחה (אם קיים)
    _starterPackTicker = Timer.periodic(const Duration(seconds: 1), (_) => _loadStarterPackOffer());
    IapManager.onPurchasesUpdated = () {
      if (mounted) setState(() {});
      _loadCoins();
    };
    // 🆕 רושמים גם ל-onPurchaseGranted (חדש - ראו iap_manager.dart) כדי
    // להציג את פופאפ "הרכישה הושלמה" (reward_popups.dart) עם פרטי המוצר
    // הספציפי שנרכש, מיד אחרי שהתמורה עליו ניתנה בפועל.
    _prevOnPurchaseGranted = IapManager.onPurchaseGranted;
    IapManager.onPurchaseGranted = _onPurchaseGranted;
    // 🆕 אם הגענו לכאן דרך "PRO" בתפריט הראשי - גוללים אוטומטית לאזור
    // "ללא פרסומות" אחרי שהמסך נבנה. תוקן: פריים אחד (addPostFrameCallback)
    // לא תמיד מספיק - המסך הזה נפתח דרך Navigator.push עם אנימציית מעבר
    // (slide-in), וב-frame הראשון ה-GlobalKey לפעמים עדיין לא מחובר ל-
    // context אמיתי עם גודל/מיקום סופיים (האנימציה עדיין "בדרך"). לכן
    // עכשיו יש ניסיון חוזר על כמה frames + עוד ניסיון אחרי שהאנימציה
    // (כ-300 מ"ש) מסתיימת, כדי לתפוס בוודאות את המצב הסופי.
    if (widget.scrollToNoAds) {
      _scrollToSection(_noAdsSectionKey, attemptsLeft: 6);
    } else if (widget.scrollToEnergy) {
      _scrollToSection(_energySectionKey, attemptsLeft: 6);
    }
  }

  @override
  void dispose() {
    IapManager.onPurchasesUpdated = null;
    IapManager.onPurchaseGranted = _prevOnPurchaseGranted; // 🆕 משחזרים callback קודם, לא סתם מאפסים
    _cooldownTicker?.cancel();
    _starterPackTicker?.cancel();
    _couponController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🆕 בודק אם יש הצעת מארז פתיחה פעילה וממתינה, ומעדכן את הבאנר.
  Future<void> _loadStarterPackOffer() async {
    final variant = await StarterPackService.activePendingOffer();
    final left = variant == null ? null : await StarterPackService.remaining();
    if (!mounted) return;
    setState(() {
      _starterPackVariant = variant;
      _starterPackRemaining = left;
    });
  }

  /// 🆕 גרסה כללית (הייתה קודם ספציפית ל"ללא פרסומות" בלבד, שוכפלה כדי
  /// לתמוך גם בגלילה לאזור "חנות האנרגיה") - מנסה לגלול לאזור לפי
  /// GlobalKey נתון, עם ניסיונות חוזרים כי ה-GlobalKey עלול לא להיות
  /// מחובר ל-context מדיד בפריים הראשון (במיוחד תוך כדי אנימציית המעבר
  /// של Navigator.push). כל ניסיון שנכשל (context עדיין null, או
  /// שהגלילה בפועל לא זזה) מתוזמן שוב פריים אחר פריים.
  void _scrollToSection(GlobalKey key, {required int attemptsLeft}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null && _scrollController.hasClients) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
        // בודקים אחרי הגלילה שהיא באמת "תפסה" (ליתר ביטחון, מכיוון
        // שבפריים הראשון-שני אחרי Navigator.push הגודל של ה-ListView
        // לפעמים עדיין לא סופי בזמן אנימציית המעבר). אם לא - עוד ניסיון.
        if (attemptsLeft > 1) {
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) _scrollToSection(key, attemptsLeft: attemptsLeft - 1);
          });
        }
      } else if (attemptsLeft > 1) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) _scrollToSection(key, attemptsLeft: attemptsLeft - 1);
        });
      }
    });
  }

  /// מנסה לממש את הקוד שהוקלד. אטומי מול Firestore (ראו coupon_service.dart)
  /// - כך שלא ניתן לחרוג ממגבלת מספר המימושים גם בלחיצות בו-זמניות.
  Future<void> _redeemCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _redeemingCoupon) return;
    AudioManager.playClick();
    setState(() => _redeemingCoupon = true);

    final deviceId = await DeviceId.get();
    final outcome = await CouponService.redeem(code, deviceId);

    if (!mounted) return;
    setState(() => _redeemingCoupon = false);

    switch (outcome.result) {
      case CouponResult.success:
        final prefs = await SharedPreferences.getInstance();
        final coins = prefs.getInt('coins') ?? 15;
        await prefs.setInt('coins', coins + outcome.coins);
        PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה מימוש קופון לא מסתנכרן לחשבון Google/Apple מקושר
        if (!mounted) return;
        _couponController.clear();
        _loadCoins();
        _toast("הקוד מומש! קיבלת ${outcome.coins} מטבעות 🎉", Colors.green);
        break;
      case CouponResult.notFound:
        _toast("קוד לא קיים - בדוק שהקלדת נכון", Colors.redAccent);
        break;
      case CouponResult.inactive:
        _toast("הקוד הזה כבר לא פעיל", Colors.redAccent);
        break;
      case CouponResult.usedUp:
        _toast("הקוד הזה נוצל עד הסוף על ידי שחקנים אחרים", Colors.redAccent);
        break;
      case CouponResult.alreadyUsedByThisDevice:
        _toast("כבר מימשת את הקוד הזה בעבר", Colors.orange);
        break;
      case CouponResult.error:
        // 🩺 זמני, לצורך אבחון: מציג את הודעת השגיאה האמיתית מ-Firestore
        // (למשל "permission-denied") במקום הודעה גנרית - כדי שאפשר יהיה
        // לצלם מסך ולזהות בדיוק מה משתבש. אפשר להחזיר להודעה הרגילה
        // ("שגיאה - בדוק חיבור לאינטרנט") ברגע שהתקלה נמצאת ונפתרת.
        _toast("שגיאה: ${outcome.debugMessage ?? 'לא ידועה'}", Colors.redAccent);
        break;
    }
  }

  void _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    final energy = await EnergyService.getCurrentEnergy();
    if (!mounted) return;
    setState(() {
      currentCoins = prefs.getInt('coins') ?? 15;
      currentEnergy = energy;
    });
  }

  void _checkAdCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final lastMillis = prefs.getInt('lastAdBonusMillis');
    setState(() {
      if (lastMillis == null) {
        dailyAdAvailable = true;
        remaining = Duration.zero;
        return;
      }
      final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      final elapsed = DateTime.now().difference(last);
      if (elapsed >= adCooldown) {
        dailyAdAvailable = true;
        remaining = Duration.zero;
      } else {
        dailyAdAvailable = false;
        remaining = adCooldown - elapsed;
      }
    });
  }

  /// שעון ספרתי קטן בפורמט H:MM:SS (למשל "2:59:40") - קריא ומדויק הרבה
  /// יותר מ"עוד 2ש 59ד" שהיה נראה מגושם ולא התעדכן חי לפי שניות.
  String get _remainingLabel {
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return "$h:$mm:$ss";
  }

  void _watchDailyAd() {
    AudioManager.playClick();
    if (!dailyAdAvailable) return;
    if (!AdsManager.isRewardedReady) {
      _toast("אין פרסומת זמינה כרגע, נסה שוב עוד רגע 🎬", Colors.deepPurple);
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      final prefs = await SharedPreferences.getInstance();
      int coins = prefs.getInt('coins') ?? 15;
      await prefs.setInt('coins', coins + 15);
      PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה בונוס הפרסומת לא מסתנכרן לחשבון Google/Apple מקושר
      await prefs.setInt('lastAdBonusMillis', DateTime.now().millisecondsSinceEpoch);
      // 🔔 מתזמן התראה לטלפון בעוד 3 שעות (בדיוק כשה-Cooldown נגמר) שתזכיר
      // לשחקן שהבונוס זמין שוב - גם אם האפליקציה סגורה לגמרי באותו זמן.
      NotificationManager.scheduleFreeCoinsReminder();
      // 🩹 "המטבעות לא מתעדכנים במסך הראשי מיד" - מסך הבית חי מתחת לחנות
      // הזו במחסנית הניווט, אבל היה מתעדכן רק כשחוזרים אליו בפועל.
      // הקריאה הזו מרעננת אותו מיידית (ראו main_menu_screen.dart).
      MainMenuScreen.onReturnedHome?.call();
      if (!mounted) return;
      _loadCoins();
      _checkAdCooldown();
      // 🩹 הוחלף מדיאלוג הטקסט הישן (עם 🪙 גולמי) בפופאפ המסך-מלא החדש
      // (reward_popups.dart) - עם CoinIcon וקטורי במקום אימוג'י גולמי.
      // 🩹 onShopTap לא סופק בכוונה - אנחנו כבר בתוך מסך החנות עצמו כאן,
      // אז "לחנות" רק סוגר את הפופאפ (אין לאן לנווט).
      showCoinsRewardPopup(
        context,
        rewardAmount: 15,
        currentCoins: currentCoins,
        subtitle: "חוזר שוב בעוד 3 שעות",
      );
    });
  }

  // 🆕 "העניין של הפרסומת תמורת 2 אנרגיה לא מופיעה" - נוסף כאן בתוך
  // "פעולות מהירות", ממש ליד בונוס הפרסומת הרגיל (מקום שאי אפשר לפספס),
  // בנוסף לזה שכבר קיים במסך הבית. בלי קירור בכלל (בשונה מבונוס ה-15
  // מטבעות) - זמין תמיד כל עוד האנרגיה לא מלאה, בדיוק כמו
  // _watchAdForEnergyFromHome ב-main_menu_screen.dart (אותו מנגנון
  // EnergyService.addFromAd).
  Future<void> _watchAdForEnergyShop() async {
    AudioManager.playClick();
    if (!AdsManager.isRewardedReady) {
      _toast("אין פרסומת זמינה כרגע, נסה שוב עוד רגע 🎬", Colors.deepPurple);
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      await EnergyService.addFromAd();
      final energyNow = await EnergyService.getCurrentEnergy(); // 🆕 ערך מדויק לאחר הזיכוי, לתצוגה בפופאפ
      // 🩹 "האנרגיה לא מתעדכנת במסך הראשי מיד" - ראו הערה זהה ב-_watchDailyAd למעלה
      MainMenuScreen.onReturnedHome?.call();
      if (!mounted) return;
      _loadCoins(); // 🩹 גם מרעננת currentEnergy, למרות השם (ראו הגדרתה למעלה)
      // 🩹 הוחלף מדיאלוג הטקסט הישן בפופאפ המסך-מלא החדש (reward_popups.dart)
      showEnergyRewardPopup(
        context,
        rewardAmount: EnergyService.adRewardAmount,
        currentEnergy: energyNow,
        maxEnergy: EnergyService.maxEnergy,
      );
    });
  }

  // 🆕 נקרא מ-IapManager.onPurchaseGranted מיד אחרי שרכישה אמיתית הוענקה
  // בפועל - ממפה את מזהה המוצר לתוכן פופאפ "הרכישה הושלמה" (שם/מחיר/
  // תיאור + רשימת "נוסף לחשבון") ומציג אותו. הרשימה כאן מכסה את המוצרים
  // שנמכרים ישירות במסך הזה (מטבעות/אנרגיה/ללא פרסומות) - מוצר לא מוכר
  // (למשל נרכש ממסך אחר בזמן שהחנות ברקע) פשוט לא מציג פופאפ כאן, כדי
  // לא להמציא תוכן שגוי.
  void _onPurchaseGranted(String productId) {
    _prevOnPurchaseGranted?.call(productId);
    // 🩹 "המטבעות/אנרגיה לא מתעדכנים במסך הראשי מיד" - ראו הערה זהה
    // ב-_watchDailyAd למעלה. גם רכישה אמיתית (לא רק פרסומת) צריכה לרענן
    // את מסך הבית באותו רגע, לא רק כשחוזרים אליו.
    MainMenuScreen.onReturnedHome?.call();
    if (!mounted) return;

    String? name;
    String description = "";
    List<GrantedItem> granted = [];

    switch (productId) {
      case 'coins_100':
        name = "100 מטבעות"; description = "חבילת מטבעות";
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: "מטבעות", value: "+100")];
        break;
      case 'coins_200':
        name = "200 מטבעות"; description = "חבילת מטבעות";
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: "מטבעות", value: "+200")];
        break;
      case 'coins_1000':
        name = "1000 מטבעות"; description = "חבילת מטבעות";
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: "מטבעות", value: "+1000")];
        break;
      case 'coins_2500':
        name = "2500 מטבעות"; description = "חבילת מטבעות";
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: "מטבעות", value: "+2500")];
        break;
      case 'coins_6000':
        name = "6000 מטבעות"; description = "חבילת מטבעות - הכי משתלם";
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: "מטבעות", value: "+6000")];
        break;
      case 'energy_2':
        name = "2 אנרגיה"; description = "חבילת אנרגיה";
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: "אנרגיה", value: "+2")];
        break;
      case 'energy_8':
        name = "8 אנרגיה"; description = "חבילת אנרגיה";
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: "אנרגיה", value: "+8")];
        break;
      case 'energy_15':
        name = "15 אנרגיה"; description = "חבילת אנרגיה";
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: "אנרגיה", value: "+15")];
        break;
      case 'energy_30':
        name = "30 אנרגיה"; description = "חבילת אנרגיה";
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: "אנרגיה", value: "+30")];
        break;
      case 'no_ads_monthly':
        name = "ללא פרסומות - חודשי"; description = "מנוי חודשי";
        granted = [GrantedItem(icon: const Text("🚫", style: TextStyle(fontSize: 16)), label: "הוסרו כל הפרסומות", value: "✓")];
        break;
      case 'no_ads_lifetime':
        name = "ללא פרסומות - לתמיד"; description = "רכישה חד-פעמית";
        granted = [GrantedItem(icon: const Text("🚫", style: TextStyle(fontSize: 16)), label: "הוסרו כל הפרסומות", value: "✓")];
        break;
      default:
        // 🆕 מוצר שלא מנוהל ישירות במסך הזה (למשל מארז פתיחה/באטל פאס/
        // פתיחת רמה) - לא מציגים כאן פופאפ שגוי, המסך הרלוונטי מטפל בו.
        return;
    }

    final price = _price(productId, "");
    showPurchaseCompletePopup(
      context,
      itemName: name,
      itemPrice: price,
      itemDescription: description,
      grantedItems: granted,
    );
  }

  // 🩹 הוסר _showRewardDialog הישן (דיאלוג טקסט גנרי) - שני מקומות
  // הקריאה היחידים לו (בונוס מטבעות/אנרגיה מפרסומת) הוחלפו בפופאפים
  // המסך-מלא החדשים (showCoinsRewardPopup/showEnergyRewardPopup,
  // reward_popups.dart) לפי המוקאפ, כך שהפונקציה הזו הפכה למתה.

  void _toast(String msg, Color color, {Duration duration = const Duration(seconds: 4)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    AudioManager.playClick();
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast("לא ניתן לפתוח את הקישור כרגע", Colors.redAccent);
    } catch (_) {
      if (mounted) _toast("לא ניתן לפתוח את הקישור כרגע", Colors.redAccent);
    }
  }

  Future<void> _buy(String productId) async {
    AudioManager.playClick();
    bool started = await IapManager.buy(productId);
    if (!started && mounted) {
      _toast("הרכישה אינה זמינה כרגע, נסה שוב מאוחר יותר 🛍️", Colors.deepPurple);
    }
  }

  /// מחיר להצגה: אמיתי מהחנות אם נטען, אחרת מחיר משוער
  String _price(String productId, String fallback) {
    return IapManager.product(productId)?.price ?? fallback;
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  // 🆕 פיל קטן לכותרת החנות (מטבעות/אנרגיה) - אותו סגנון בדיוק כמו
  // הפילים במסך הבית, לפי העיצוב מחדש.
  Widget _headerPill({required Widget child, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: color.withValues(alpha: 0.13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  /// 🆕 באנר בולט למעלה עבור הצעת "מארז פתיחה" הפעילה של המשתמש - זהב
  /// עם גרדיאנט וגבול זוהר, כדי שהוא יבלוט ברור מעל שאר תוכן החנות.
  Widget _starterPackBanner() {
    final variant = _starterPackVariant!;
    final coins = IapManager.starterPackCoins[variant] ?? 0;
    final energy = IapManager.starterPackEnergy[variant] ?? 0;
    final left = _starterPackRemaining ?? Duration.zero;
    final priceLabel = _price(variant, "");
    String content = "$coins מטבעות";
    if (energy > 0) content += " + $energy אנרגיה";
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          AudioManager.playClick();
          StarterPackDialog.show(context, variant);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFC64B).withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("מארז פתיחה ממתין לך!",
                        style: TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      priceLabel.isEmpty ? content : "$content - $priceLabel",
                      style: const TextStyle(color: Color(0xFF2A1740), fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text("נשארו ${_fmtDuration(left)} - ל-3 שעות בלבד",
                        style: const TextStyle(color: Color(0xFF5A3A1A), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2A1740), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DebugLog.add("ShopScreen.build START");
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF1D0E3C),
      body: Stack(
        children: [
          AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ===== כותרת - עודכן לפי העיצוב מחדש: פילי מטבעות/אנרגיה
              // בכותרת עצמה (במקום קופסת "יתרת מטבעות" נפרדת שתפסה מקום
              // בראש הרשימה הנגללת) - חוסך מקום ומראה את שני המשאבים יחד. =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      "חנות",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _headerPill(child: const CoinIcon(size: 15), text: "$currentCoins", color: const Color(0xFFFFC64B)),
                    const SizedBox(width: 7),
                    _headerPill(child: const EnergyIcon(size: 15), text: "$currentEnergy", color: const Color(0xFF7DD3FC)),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 128),
                  children: [
                    // 🆕 באנר "מארז פתיחה" - זהוב ובולט, למעלה ממש, רק אם
                    // יש הצעה פעילה וממתינה למשתמש הזה (ראו _loadStarterPackOffer).
                    if (_starterPackVariant != null) _starterPackBanner(),

                    // 🆕 תוקן: "יש לי קוד קופון" ו-"בונוס פרסומת" היו שני
                    // בלוקים נפרדים, כל אחד עם כותרת section משלו וריווח
                    // גדול - זה דחף את חנות המטבעות רחוק למטה וגרם לגלילה
                    // ארוכה ומיותרת. עכשיו שניהם תחת כותרת משותפת אחת
                    // "פעולות מהירות" עם ריווח מצומצם, כדי שהחנות עצמה
                    // תהיה נגישה הרבה יותר מהר.
                    const SizedBox(height: 14),
                    const _SectionTitle("פעולות מהירות", icon: Icons.bolt_rounded),
                    const SizedBox(height: 10),

                    // ===== 🆕 מימוש קוד קופון =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1B4D),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFC64B).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: "הקלד קוד קופון",
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14, fontWeight: FontWeight.w500),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.06),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
                              ),
                              onSubmitted: (_) => _redeemCoupon(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(13),
                              onTap: _redeemingCoupon ? null : _redeemCoupon,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)]),
                                ),
                                child: _redeemingCoupon
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                                    : const Text("מימוש", style: TextStyle(color: Color(0xFF2A1740), fontSize: 14.5, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ===== בונוס פרסומת - כל 3 שעות, תמיד בראש החנות =====
                    // 🆕 הצטמצם: אייקון 50x50 -> 38x38, padding 15 -> 11,
                    // בלי כותרת section נפרדת - חלק מ"פעולות מהירות" למעלה.
                    InkWell(
                      onTap: dailyAdAvailable ? _watchDailyAd : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: dailyAdAvailable
                              ? const Color(0xFF2A1B4D)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dailyAdAvailable
                                ? Colors.deepPurpleAccent.withValues(alpha: 0.55)
                                : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (dailyAdAvailable
                                        ? Colors.deepPurpleAccent
                                        : Colors.white38)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                dailyAdAvailable
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.timer_rounded,
                                color: dailyAdAvailable
                                    ? Colors.deepPurpleAccent
                                    : Colors.white54,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: dailyAdAvailable
                                  ? Column(
                                      textDirection: TextDirection.rtl,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "צפה בפרסומת - קבל 15 מטבעות",
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "זמין שוב כל 3 שעות - מטבעות חינם",
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                              color: Colors.white54, fontSize: 12.5),
                                        ),
                                      ],
                                    )
                                  // 🆕 תוקן: "הבונוס הבא זמין בעוד:" והשעון עצמו
                                  // (_remainingLabel) באותה שורה - התווית
                                  // בצד ימין והמספר בצד שמאל שלה (Row עם
                                  // textDirection.rtl: הילד הראשון ברשימה
                                  // מוצג ראשון מימין).
                                  : Row(
                                      textDirection: TextDirection.rtl,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "הבונוס הבא זמין בעוד: ",
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        // ⏱️ שעון ספרתי קטן שסופר בזמן אמת (מתעדכן כל שנייה)
                                        Text(
                                          _remainingLabel,
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===== 🆕 פרסומת תמורת אנרגיה - זמין תמיד (בלי קירור),
                    // אותו סגנון בדיוק כמו בונוס הפרסומת למעלה, רק כחול-
                    // אנרגיה, ומוצג רק כשהאנרגיה לא מלאה. חלק מ"פעולות
                    // מהירות" - ליד בונוס המטבעות, מקום שאי אפשר לפספס. =====
                    if (currentEnergy < EnergyService.maxEnergy) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _watchAdForEnergyShop,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF123A52),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.55), width: 1.5),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(color: const Color(0xFF38BDF8).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF7DD3FC), size: 22),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  textDirection: TextDirection.rtl,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("צפה בפרסומת - קבל ${EnergyService.adRewardAmount} אנרגיה", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    const Text("אין הגבלת פעמים - זמין תמיד כשהאנרגיה לא מלאה", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    const _SectionTitle("חנות המטבעות", icon: Icons.auto_awesome_rounded),
                    const SizedBox(height: 12),

                    // ===== כרטיס מוביל =====
                    _FeaturedCard(
                      title: "חבילת אגדה",
                      amount: "6,000 מטבעות",
                      price: _price(IapManager.coins6000Id, "₪160.00"),
                      onTap: () => _buy(IapManager.coins6000Id),
                    ),

                    const SizedBox(height: 14),

                    // ===== רשת חבילות 2x2 =====
                    Row(
                      children: [
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.workspace_premium_rounded,
                            iconColor: const Color(0xFFFFC64B),
                            title: "חבילת זהב",
                            amount: "200",
                            price: _price(IapManager.coins200Id, "₪10.00"),
                            onTap: () => _buy(IapManager.coins200Id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.shield_rounded,
                            iconColor: const Color(0xFF64B5F6),
                            title: "חבילת מתחילים",
                            amount: "100",
                            price: _price(IapManager.coins100Id, "₪5.90"),
                            onTap: () => _buy(IapManager.coins100Id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.diamond_rounded,
                            iconColor: const Color(0xFF4DD0E1),
                            title: "חבילת מלכים",
                            amount: "2,500",
                            price: _price(IapManager.coins2500Id, "₪80.00"),
                            onTap: () => _buy(IapManager.coins2500Id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.rocket_launch_rounded,
                            iconColor: const Color(0xFFFF8A65),
                            title: "חבילת VIP",
                            amount: "1,000",
                            price: _price(IapManager.coins1000Id, "₪35.00"),
                            onTap: () => _buy(IapManager.coins1000Id),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18, key: _energySectionKey),
                    const _SectionTitle("חנות האנרגיה", icon: Icons.bolt_rounded),
                    const SizedBox(height: 12),

                    // ===== רשת חבילות אנרגיה 2x2 - זהה בעיצוב לחבילות
                    // המטבעות למעלה, רק עם כמויות/מחירים של אנרגיה. =====
                    Row(
                      children: [
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFF7DD3FC),
                            title: "מטען קטן",
                            amount: "2 ⚡",
                            price: _price(IapManager.energy2Id, "₪2.90"),
                            onTap: () => _buy(IapManager.energy2Id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.electric_bolt_rounded,
                            iconColor: const Color(0xFF38BDF8),
                            title: "מטען בינוני",
                            amount: "8 ⚡",
                            price: _price(IapManager.energy8Id, "₪10.90"),
                            onTap: () => _buy(IapManager.energy8Id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.battery_charging_full_rounded,
                            iconColor: const Color(0xFF0EA5E9),
                            title: "מטען גדול",
                            amount: "15 ⚡",
                            price: _price(IapManager.energy15Id, "₪19.90"),
                            onTap: () => _buy(IapManager.energy15Id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.flash_on_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: "מטען ענק",
                            amount: "30 ⚡",
                            price: _price(IapManager.energy30Id, "₪29.90"),
                            onTap: () => _buy(IapManager.energy30Id),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18, key: _noAdsSectionKey),
                    const _SectionTitle("ללא פרסומות",
                        icon: Icons.workspace_premium_rounded),
                    const SizedBox(height: 12),

                    // ===== מנוי ללא פרסומות =====
                    if (IapManager.noAds)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.6),
                              width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.greenAccent, size: 26),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                "מצב ללא פרסומות פעיל! תודה על התמיכה 💜",
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _WideCard(
                        icon: Icons.autorenew_rounded,
                        title: "מנוי חודשי",
                        subtitle: "בלי פרסומות בין שלבים, מתחדש כל חודש",
                        price: _price(IapManager.noAdsMonthlyId, "₪15.00"),
                        accent: const Color(0xFFB388FF),
                        onTap: () => _buy(IapManager.noAdsMonthlyId),
                      ),
                      const SizedBox(height: 14),
                      _WideCard(
                        icon: Icons.star_rounded,
                        title: "לכל החיים",
                        subtitle: "תשלום אחד - בלי פרסומות לתמיד",
                        price: _price(IapManager.noAdsLifetimeId, "₪40.00"),
                        accent: const Color(0xFFFFC64B),
                        badge: "הכי משתלם",
                        onTap: () => _buy(IapManager.noAdsLifetimeId),
                      ),
                    ],

                    // 🆕 חובה לפי כללי אפל (Guideline 3.1.2) לכל אפליקציה
                    // עם מנוי: קישורים פונקציונליים למדיניות פרטיות ולתנאי
                    // שימוש (EULA), צמודים לאזור הרכישה עצמו - לא מספיק
                    // שהם רשומים רק ב-App Store Connect.
                    // ⚠️ קישור מדיניות הפרטיות עודכן לעמוד ה-Google Sites
                    // הקיים שלך (כבר מוגש בעבר לאפל בלי בעיה). כפתור "תנאי
                    // שימוש" הוסר לגמרי כי הצביע על כתובת placeholder שלא
                    // חוברה לשום דבר אמיתי - אם/כשיהיה דף תנאי שימוש אמיתי
                    // אפשר להוסיף אותו בחזרה באותה צורה.
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => _openLink("https://sites.google.com/view/zehet-halogo-privacy"),
                        child: Text("מדיניות פרטיות", style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5, decoration: TextDecoration.underline)),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ===== שחזור רכישות (חובה לפי כללי החנויות) =====
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          AudioManager.playClick();
                          await IapManager.restorePurchases();
                          if (!mounted) return;
                          _toast("בודק רכישות קודמות...", Colors.deepPurple);
                        },
                        icon: const Icon(Icons.restore_rounded,
                            color: Colors.white54, size: 20),
                        label: const Text("שחזור רכישות",
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
          AppBottomNav(current: AppTab.shop),
        ],
      ),
    );
    DebugLog.add("ShopScreen.build END (widget tree constructed)");
    return scaffold;
  }
}

// ============================================================
// ווידג'טים פנימיים
// ============================================================

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionTitle(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        // 🆕 ברק = אימוג'י אנרגיה (ראו app_icons.dart) - שאר האייקונים נשארים וקטוריים
        icon == Icons.bolt_rounded ? const EnergyIcon(size: 19) : Icon(icon, color: const Color(0xFFFFC64B), size: 21),
      ],
    );
  }
}

/// כרטיס הזהב הגדול - פריסה אנכית כדי שהמחיר לא ידרוס את הכותרת
class _FeaturedCard extends StatelessWidget {
  final String title, amount, price;
  final VoidCallback onTap;
  const _FeaturedCard({
    required this.title,
    required this.amount,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFFFE08A), Color(0xFFE9A82C)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC64B).withValues(alpha: 0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // שורה עליונה: אייקון + טקסטים
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF3A2405), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF3A2405),
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            amount,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: const Color(0xFF3A2405).withValues(alpha: 0.72),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // כפתור מחיר ברוחב מלא - אין סיכוי לחפיפה
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241634),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // תג "הכי משתלם" - יושב על הקצה העליון, לא על התוכן
        Positioned(
          top: -10,
          right: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE5397A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 7,
                ),
              ],
            ),
            child: const Text(
              "הכי משתלם",
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// אריח חבילת מטבעות ברשת
class _CoinTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, amount, price;
  final VoidCallback onTap;
  const _CoinTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.price,
    required this.onTap,
  });

  // 🆕 אייקוני "משפחת אנרגיה" (בכל 4 חבילות חנות האנרגיה) - מוצגים כאימוג'י
  // ⚡ במקום אייקון וקטורי (ראו app_icons.dart). שאר האייקונים (חבילות
  // מטבעות - כתר/מגן/יהלום/רקטה) נשארים וקטוריים כרגיל.
  // 🩹 static final ולא static const: IconData מממש == בעצמו, ו-Dart לא
  // מרשה לזה להיות איבר בתוך const Set (דורש שוויון "פרימיטיבי" לצורך
  // קנוניזציה בזמן קומפילציה) - final פותר את זה בלי לאבד כלום בפועל.
  static final _energyFamilyIcons = {
    Icons.bolt_rounded,
    Icons.electric_bolt_rounded,
    Icons.battery_charging_full_rounded,
    Icons.flash_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1B4D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
        ),
        child: Column(
          children: [
            _energyFamilyIcons.contains(icon) ? const EnergyIcon(size: 26) : Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Color(0xFFFFC64B),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF2E9E5B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
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
}

/// כרטיס רוחב מלא (מנוי)
class _WideCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, price;
  final Color accent;
  final String? badge;
  final VoidCallback onTap;
  const _WideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1B4D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF1D0E3C),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -9,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5397A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                badge!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}