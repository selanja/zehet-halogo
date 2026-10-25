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
import 'boost_service.dart'; // 🆕 בוסטים זמניים (רמזים חינם/נקודות כפולות) הנרכשים במטבעות
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
import 'app_notification.dart';
import 'l10n/app_localizations.dart';
import 'analytics_service.dart'; // 🆕 מעקב Firebase Analytics אחרי מימוש קודי קופון

class ShopScreen extends StatefulWidget {
  // 🆕 כשנפתחים לכאן מכרטיס "ללא פרסומות" בתפריט הראשי - גוללים אוטומטית
  // ישר לאזור הזה בחנות, במקום להשאיר את המשתמש למעלה וצריך לחפש בעצמו.
  final bool scrollToNoAds;
  // 🆕 כנ"ל - כשנפתחים לכאן ממסך "נגמרה האנרגיה" (כפתור "קנה בחנות ⚡")
  // גוללים ישר לאזור "חנות האנרגיה".
  final bool scrollToEnergy;
  // 🆕 כשנפתחים לכאן מ"אין מספיק מטבעות" (דו-קרב/מירוץ/רמז) - גוללים
  // ישר ל"חנות המטבעות" *וגם* מסמנים חזותית את החבילה הקטנה ביותר
  // שבאמת מכסה את המחסור (לא סתם "כל החבילות זהות" - רואים ישר איזו
  // אחת פותרת את הבעיה הנוכחית). ראו _recommendedCoinsProductId למטה.
  final int? highlightNeededCoins;
  const ShopScreen({super.key, this.scrollToNoAds = false, this.scrollToEnergy = false, this.highlightNeededCoins});

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
  BoostType? _activeBoost; // 🆕 בוסט פעיל כרגע (אם יש)
  Duration _activeBoostRemaining = Duration.zero;
  Timer? _cooldownTicker;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _noAdsSectionKey = GlobalKey();
  final GlobalKey _energySectionKey = GlobalKey();
  final GlobalKey _coinsSectionKey = GlobalKey();

  // 🆕 איזו חבילת מטבעות "מומלצת" כרגע (ראו highlightNeededCoins למעלה) -
  // הקטנה ביותר שמכסה את המחסור, או הגדולה ביותר אם המחסור עולה על הכל.
  static const Map<String, int> _coinPackAmounts = {
    IapManager.coins100Id: 100,
    IapManager.coins200Id: 200,
    IapManager.coins1000Id: 1000,
    IapManager.coins2500Id: 2500,
    IapManager.coins6000Id: 6000,
  };
  String? get _recommendedCoinsProductId {
    final needed = widget.highlightNeededCoins;
    if (needed == null || needed <= 0) return null;
    final sorted = _coinPackAmounts.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    for (final e in sorted) {
      if (e.value >= needed) return e.key;
    }
    return sorted.last.key;
  }

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

  // 🆕 "מבצע אלוף!" - בונוס 20% הנחה אפקטיבית (מכפיל 1.25×) על חבילות
  // המטבעות הבינוניות-גדולות, פעיל 24 שעות אחרי ניצחון בטורניר (ראו
  // IapManager.activateTournamentBonus/tournamentBonusActive/
  // tournamentBonusRemaining). אותו דפוס בדיוק כמו מארז הפתיחה למעלה -
  // טעינה ב-initState + טיימר ייעודי שמרענן כל שנייה לספירה לאחור חיה.
  bool _tournamentBonusActive = false;
  Duration _tournamentBonusRemaining = Duration.zero;
  Timer? _tournamentBonusTicker;

  // 🆕 "פעם ראשונה = כפול!" מראש על החבילות הקטנות (לפני הרכישה, לא רק
  // בפופאפ אחרי) - ראו IapManager.firstCoinsPurchaseBonusAvailable.
  bool _firstPurchaseBonusAvailable = false;

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
    _loadFirstPurchaseBonusAvailability();
    _loadTournamentBonus(); // 🆕 מבצע אלוף! - ראו ההערה למעלה ליד השדות
    _initBoosts(); // 🆕 בוסט ניסיון חינמי חד-פעמי + טעינת מצב הבוסט - ראו boost_service.dart
    DebugLog.add("ShopScreen.initState END");
    // מרעננים כל שנייה כדי שהטיימר על הכפתור יתעדכן בזמן אמת
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAdCooldown();
      _loadActiveBoost(); // 🆕 אותו טיימר קיים - גם מרענן את ספירת הזמן של הבוסט
    });
    // 🆕 מרעננים כל שנייה גם את ספירת הזמן שנשארה למארז הפתיחה (אם קיים)
    _starterPackTicker = Timer.periodic(const Duration(seconds: 1), (_) => _loadStarterPackOffer());
    // 🆕 וכנ"ל לספירה לאחור של מבצע האלוף (אם פעיל) - טיימר ייעודי נפרד,
    // בדיוק כמו הטיימר של מארז הפתיחה שורה אחת למעלה.
    _tournamentBonusTicker = Timer.periodic(const Duration(seconds: 1), (_) => _loadTournamentBonus());
    IapManager.onPurchasesUpdated = () {
      if (mounted) setState(() {});
      _loadCoins();
      _loadFirstPurchaseBonusAvailability();
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
    } else if (widget.highlightNeededCoins != null) {
      _scrollToSection(_coinsSectionKey, attemptsLeft: 6);
    }
  }

  @override
  void dispose() {
    IapManager.onPurchasesUpdated = null;
    IapManager.onPurchaseGranted = _prevOnPurchaseGranted; // 🆕 משחזרים callback קודם, לא סתם מאפסים
    _cooldownTicker?.cancel();
    _starterPackTicker?.cancel();
    _tournamentBonusTicker?.cancel();
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

  /// 🆕 בודק אם "מבצע אלוף!" (בונוס ניצחון טורניר) פעיל כרגע, ומעדכן את
  /// הבאנר/כרטיסי החבילות בהתאם - אותו דפוס בדיוק כמו _loadStarterPackOffer
  /// למעלה.
  Future<void> _loadTournamentBonus() async {
    final active = await IapManager.tournamentBonusActive();
    final left = active ? await IapManager.tournamentBonusRemaining() : Duration.zero;
    if (!mounted) return;
    setState(() {
      _tournamentBonusActive = active;
      _tournamentBonusRemaining = left;
    });
  }

  /// 🆕 הכמות האמיתית שתתקבל עבור חבילת מטבעות בסיסית אם "מבצע אלוף!" פעיל
  /// (base × IapManager.tournamentBonusMultiplier, מעוגל - ראו iap_manager.dart).
  int _tournamentBoostedAmount(int base) => (base * IapManager.tournamentBonusMultiplier).round();

  /// 🆕 מוסיף פסיקים כמפרידי אלפים (כמו "2,500") לכמות מוגדלת - לשימוש
  /// בהצגת הכמות האמיתית על כרטיסי החבילות כשמבצע האלוף פעיל, באותו
  /// פורמט בדיוק שהכרטיסים כבר כותבים אותו באופן קבוע (ראו amount למטה).
  String _fmtThousands(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
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
    final loc = AppLocalizations.of(context)!;
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
        AnalyticsService.logPromoCodeRedeemed(code.trim().toUpperCase()); // 🆕 מעקב אחרי קודים שמופצים בערוצים חיצוניים (למשל TIKTOK בביו)
        if (!mounted) return;
        _couponController.clear();
        _loadCoins();
        _toast(loc.shopCouponRedeemedMessage(outcome.coins), Colors.green);
        break;
      case CouponResult.notFound:
        _toast(loc.shopCouponNotFound, Colors.redAccent);
        break;
      case CouponResult.inactive:
        _toast(loc.shopCouponInactive, Colors.redAccent);
        break;
      case CouponResult.usedUp:
        _toast(loc.shopCouponUsedUp, Colors.redAccent);
        break;
      case CouponResult.alreadyUsedByThisDevice:
        _toast(loc.shopCouponAlreadyUsed, Colors.orange);
        break;
      case CouponResult.error:
        // 🩺 זמני, לצורך אבחון: מציג את הודעת השגיאה האמיתית מ-Firestore
        // (למשל "permission-denied") במקום הודעה גנרית - כדי שאפשר יהיה
        // לצלם מסך ולזהות בדיוק מה משתבש. אפשר להחזיר להודעה הרגילה
        // ("שגיאה - בדוק חיבור לאינטרנט") ברגע שהתקלה נמצאת ונפתרת.
        _toast(loc.shopCouponGenericError(outcome.debugMessage ?? loc.shopUnknownErrorDetail), Colors.redAccent);
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

  /// 🆕 נקרא פעם אחת ב-initState בלבד: מעניק בוסט ניסיון חינמי חד-פעמי
  /// (3 דקות רמזים חינם, "טעימה" לפני שמוכרים את הבוסט האמיתי ב-150
  /// מטבעות - ראו boost_service.dart.grantFreeTrialIfEligible) בפעם
  /// הראשונה שהחנות נפתחת, ואז טוען את מצב הבוסט (כדי שאם הוא הוענק
  /// כרגע - הכרטיס יציג אותו פעיל מיד).
  Future<void> _initBoosts() async {
    final granted = await BoostService.grantFreeTrialIfEligible();
    if (!mounted) return;
    _loadActiveBoost();
    if (granted) {
      final loc = AppLocalizations.of(context)!;
      AppNotification.show(context, loc.shopBoostFreeTrialToast(BoostService.trialDuration.inMinutes), color: const Color(0xFFB8860A));
    }
  }

  /// 🆕 מרענן את מצב הבוסט הפעיל (ראו boost_service.dart) - נקרא גם
  /// ב-initState וגם כל שנייה מאותו טיימר שכבר קיים לקולדאון הפרסומת,
  /// כדי שהספירה לאחור בכרטיס תתעדכן בזמן אמת בלי טיימר נוסף.
  void _loadActiveBoost() async {
    final active = await BoostService.getActive();
    final left = active == null ? Duration.zero : await BoostService.getRemaining();
    if (!mounted) return;
    setState(() {
      _activeBoost = active;
      _activeBoostRemaining = left;
    });
  }

  /// 🆕 קניית בוסט במטבעות - חסומה אם כבר יש בוסט פעיל, או אם אין מספיק
  /// מטבעות. בניגוד לרכישות IAP (שעוברות דרך iap_manager.dart), זו קנייה
  /// במטבע-המשחק הפנימי בלבד - אין צורך בשום מוצר בקונסולת החנות.
  Future<void> _buyBoost(BoostType type) async {
    AudioManager.playClick();
    final loc = AppLocalizations.of(context)!;
    if (_activeBoost != null) {
      _toast(loc.shopBoostAlreadyActiveToast, Colors.orange);
      return;
    }
    if (currentCoins < BoostService.priceCoins) {
      _toast(loc.shopBoostNotEnoughCoinsToast, Colors.redAccent);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', currentCoins - BoostService.priceCoins);
    await BoostService.activate(type);
    PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה ניכוי המטבעות לא מסתנכרן לחשבון Google/Apple מקושר
    if (!mounted) return;
    _loadCoins();
    _loadActiveBoost();
    _toast(type == BoostType.freeHints ? loc.shopBoostHintsActivatedToast : loc.shopBoostDoubleActivatedToast, Colors.green);
  }

  /// 🆕 כרטיס בוסט בודד - אותו סגנון בדיוק כמו כרטיס "בונוס פרסומת" למעלה
  /// (InkWell+Container, אייקון עגול + כותרת/תת-כותרת), עם שתי מצבים:
  /// ניתן לקנייה (מחיר + לחיצה קונה), או פעיל כרגע (ספירה לאחור, נעול).
  Widget _boostTile({required BoostType type, required IconData icon, required String title, required String subtitle, required Color color}) {
    final loc = AppLocalizations.of(context)!;
    final isThisActive = _activeBoost == type;
    final isLocked = _activeBoost != null && !isThisActive;
    return InkWell(
      onTap: isLocked || isThisActive ? null : () => _buyBoost(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isThisActive ? color.withValues(alpha: 0.14) : const Color(0xFF2A1B4D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isThisActive ? color : color.withValues(alpha: isLocked ? 0.18 : 0.55), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white.withValues(alpha: isLocked ? 0.45 : 1), fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: isLocked ? 0.3 : 0.54), fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isThisActive)
              Text(loc.shopBoostActiveLabel(BoostService.formatRemaining(_activeBoostRemaining)), style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isLocked ? 0.04 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Opacity(
                  opacity: isLocked ? 0.35 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 13),
                      const SizedBox(width: 4),
                      Text("${BoostService.priceCoins}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _loadFirstPurchaseBonusAvailability() async {
    final available = await IapManager.firstCoinsPurchaseBonusAvailable();
    if (!mounted) return;
    setState(() => _firstPurchaseBonusAvailable = available);
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
      _toast(AppLocalizations.of(context)!.logoLevelNoAdAvailable, Colors.deepPurple);
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
        subtitle: AppLocalizations.of(context)!.shopAdBonusResetSubtitle,
      );
    });
  }

  // 🆕 "העניין של הפרסומת תמורת 2 אנרגיה לא מופיעה" - נוסף כאן בתוך
  // "פעולות מהירות", ממש ליד בונוס הפרסומת הרגיל (מקום שאי אפשר לפספס),
  // בנוסף לזה שכבר קיים במסך הבית.
  // 🐛 תוקן: ההערה כאן טענה "בלי קירור בכלל... בדיוק כמו
  // main_menu_screen.dart" - אבל זה לא נכון, main_menu_screen.dart כן
  // בודק את EnergyService.timeUntilNextAdEnergy() (קירור 2 דקות בין
  // פרסומות-לאנרגיה, לפי בקשה מפורשת בעבר) לפני שמציג את הפרסומת. כאן
  // הבדיקה פשוט לא הייתה קיימת בפועל - כלומר משתמש יכול היה "לחלוב"
  // אנרגיה הרבה יותר מהר מהמיועד, רק דרך מסך החנות, בלי שום הגבלה מלבד
  // זמינות הפרסומת מה-SDK.
  Future<void> _watchAdForEnergyShop() async {
    AudioManager.playClick();
    final adCooldown = await EnergyService.timeUntilNextAdEnergy();
    if (!mounted) return;
    if (adCooldown != null) {
      final m = adCooldown.inMinutes;
      final s = adCooldown.inSeconds % 60;
      _toast(AppLocalizations.of(context)!.shopNextAdAvailableIn('$m:${s.toString().padLeft(2, '0')}'), Colors.deepPurple);
      return;
    }
    if (!AdsManager.isRewardedReady) {
      _toast(AppLocalizations.of(context)!.logoLevelNoAdAvailable, Colors.deepPurple);
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
    final loc = AppLocalizations.of(context)!;

    String? name;
    String description = "";
    List<GrantedItem> granted = [];

    // 🆕 "בונוס רכישה ראשונה" - ראו IapManager.lastGrantWasFirstPurchaseBonus.
    // הכמות שכבר נזכתה בפועל (_grant) הייתה כפולה - חייבים להציג את זה
    // כאן בפופאפ, אחרת המשתמש פשוט לא ידע שקיבל בונוס בכלל.
    final bool firstPurchaseBonus = IapManager.lastGrantWasFirstPurchaseBonus;
    // 🆕 "מבצע אלוף!" - ראו IapManager.lastGrantWasTournamentBonus. שני
    // הבונוסים בלעדיים הדדית ברמת _grant() (בונוס ניצחון טורניר לא חל
    // כשבונוס רכישה ראשונה כבר חל), אז שרשרת if/else פשוטה מספיקה.
    final bool tournamentBonus = IapManager.lastGrantWasTournamentBonus;
    String coinsValue(int base) {
      if (firstPurchaseBonus) return loc.shopDoubleBonusValue(base);
      if (tournamentBonus) return loc.shopTournamentBonusValue(_tournamentBoostedAmount(base));
      return "+$base";
    }
    String coinsDesc(String bestValueDesc) {
      if (firstPurchaseBonus) return loc.shopFirstPurchaseBonusDesc;
      if (tournamentBonus) return loc.shopTournamentBonusDesc;
      return bestValueDesc;
    }

    switch (productId) {
      case 'coins_100':
        name = loc.shopCoinsAmountLabel('100'); description = firstPurchaseBonus ? loc.shopFirstPurchaseBonusDesc : loc.shopCoinsPackDesc;
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: loc.shopCoinsLabel, value: coinsValue(100))];
        break;
      case 'coins_200':
        name = loc.shopCoinsAmountLabel('200'); description = firstPurchaseBonus ? loc.shopFirstPurchaseBonusDesc : loc.shopCoinsPackDesc;
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: loc.shopCoinsLabel, value: coinsValue(200))];
        break;
      case 'coins_1000':
        name = loc.shopCoinsAmountLabel('1000'); description = coinsDesc(loc.shopCoinsPackDesc);
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: loc.shopCoinsLabel, value: coinsValue(1000))];
        break;
      case 'coins_2500':
        name = loc.shopCoinsAmountLabel('2500'); description = coinsDesc(loc.shopCoinsPackDesc);
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: loc.shopCoinsLabel, value: coinsValue(2500))];
        break;
      case 'coins_6000':
        name = loc.shopCoinsAmountLabel('6000'); description = coinsDesc(loc.shopCoinsPackBestValueDesc);
        granted = [GrantedItem(icon: const CoinIcon(size: 18), label: loc.shopCoinsLabel, value: coinsValue(6000))];
        break;
      case 'energy_2':
        name = loc.shopEnergyAmountLabel('2'); description = loc.shopEnergyPackDesc;
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: loc.shopEnergyLabel, value: "+2")];
        break;
      case 'energy_8':
        name = loc.shopEnergyAmountLabel('8'); description = loc.shopEnergyPackDesc;
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: loc.shopEnergyLabel, value: "+8")];
        break;
      case 'energy_15':
        name = loc.shopEnergyAmountLabel('15'); description = loc.shopEnergyPackDesc;
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: loc.shopEnergyLabel, value: "+15")];
        break;
      case 'energy_30':
        name = loc.shopEnergyAmountLabel('30'); description = loc.shopEnergyPackDesc;
        granted = [GrantedItem(icon: const EnergyIcon(size: 18), label: loc.shopEnergyLabel, value: "+30")];
        break;
      case 'no_ads_monthly':
        name = loc.shopNoAdsMonthlyName; description = loc.shopMonthlySubscriptionDesc;
        granted = [GrantedItem(icon: const Text("🚫", style: TextStyle(fontSize: 16)), label: loc.shopAllAdsRemovedLabel, value: "✓")];
        break;
      case 'no_ads_lifetime':
        name = loc.shopNoAdsLifetimeName; description = loc.shopOneTimePurchaseDesc;
        granted = [GrantedItem(icon: const Text("🚫", style: TextStyle(fontSize: 16)), label: loc.shopAllAdsRemovedLabel, value: "✓")];
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
    AppNotification.show(context, msg, color: color, duration: duration);
  }

  Future<void> _openLink(String url) async {
    AudioManager.playClick();
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast(AppLocalizations.of(context)!.shopCannotOpenLinkError, Colors.redAccent);
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.shopCannotOpenLinkError, Colors.redAccent);
    }
  }

  Future<void> _buy(String productId) async {
    AudioManager.playClick();
    bool started = await IapManager.buy(productId);
    if (!started && mounted) {
      _toast(AppLocalizations.of(context)!.shopPurchaseUnavailable, Colors.deepPurple);
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
    final loc = AppLocalizations.of(context)!;
    final variant = _starterPackVariant!;
    final coins = IapManager.starterPackCoins[variant] ?? 0;
    final energy = IapManager.starterPackEnergy[variant] ?? 0;
    final left = _starterPackRemaining ?? Duration.zero;
    final priceLabel = _price(variant, "");
    String content = loc.shopCoinsAmountLabel('$coins');
    if (energy > 0) content += loc.shopStarterPackEnergySuffix(energy);
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
                    Text(loc.shopStarterPackWaitingTitle,
                        style: const TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      priceLabel.isEmpty ? content : "$content - $priceLabel",
                      style: const TextStyle(color: Color(0xFF2A1740), fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(loc.shopStarterPackTimeLeft(_fmtDuration(left)),
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

  /// 🆕 באנר "מבצע אלוף!" - מוצג רק כש-IapManager.tournamentBonusActive()
  /// חוזר true (24 שעות אחרי ניצחון בטורניר - ראו tournament_service.dart).
  /// אותו מבנה חזותי בדיוק כמו _starterPackBanner למעלה (אייקון + כותרת +
  /// שורת ספירה לאחור עם _fmtDuration), רק בלי onTap (אין דיאלוג נפרד
  /// לפתוח - הבונוס פשוט חל אוטומטית על הכרטיסים הרלוונטיים למטה) וגוון
  /// זהב-ירקרק כדי לא להתבלבל עם באנר מארז הפתיחה.
  Widget _tournamentBonusBanner() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFF6EE7B7)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6EE7B7).withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.32), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF123A2A), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.shopTournamentBonusBannerTitle,
                      style: const TextStyle(color: Color(0xFF123A2A), fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(loc.shopTournamentBonusTimeLeft(_fmtDuration(_tournamentBonusRemaining)),
                      style: const TextStyle(color: Color(0xFF1E4A38), fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DebugLog.add("ShopScreen.build START");
    final loc = AppLocalizations.of(context)!;
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
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      loc.shopScreenTitle,
                      style: const TextStyle(
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
                  // 🩹 תוקן לפי בקשה מפורשת ("המניו למטה... מופיעים מאחוריו
                  // דברים") - ריפוד 128 קבוע לא כלל את MediaQuery.padding.bottom
                  // (אזור הבטוח התחתון), בדיוק אותו באג שתוקן גם ב-
                  // missions_screen.dart/leaderboard_screen.dart - במכשירים עם
                  // אזור בטוח תחתון גדול יותר, הסרגל הצף (AppBottomNav) בפועל
                  // גבוה יותר מהריפוד שחושב לו, כך שהפריט האחרון ברשימה מציץ מתחתיו.
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 128 + MediaQuery.of(context).padding.bottom),
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
                    _SectionTitle(loc.shopQuickActionsSection, icon: Icons.bolt_rounded),
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
                                hintText: loc.shopCouponHint,
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
                                    : Text(loc.shopRedeemButton, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 14.5, fontWeight: FontWeight.w900)),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.shopWatchAdGet15CoinsTitle,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loc.shopAdBonusAvailableSubtitle,
                                          style: const TextStyle(
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          loc.shopNextBonusAvailableInLabel,
                                          style: const TextStyle(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(loc.shopWatchAdGetEnergyTitle(EnergyService.adRewardAmount), style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(loc.shopEnergyAdUnlimitedSubtitle, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    _SectionTitle(loc.shopBoostSectionTitle, icon: Icons.flash_on_rounded),
                    const SizedBox(height: 10),
                    _boostTile(
                      type: BoostType.freeHints,
                      icon: Icons.lightbulb_rounded,
                      title: loc.shopBoostHintsTitle,
                      subtitle: loc.shopBoostHintsSubtitle,
                      color: const Color(0xFFFFB24D),
                    ),
                    const SizedBox(height: 10),
                    _boostTile(
                      type: BoostType.doublePoints,
                      icon: Icons.bolt_rounded,
                      title: loc.shopBoostDoubleTitle,
                      subtitle: loc.shopBoostDoubleSubtitle,
                      color: const Color(0xFF9333EA),
                    ),

                    SizedBox(height: 18, key: _coinsSectionKey),
                    _SectionTitle(loc.shopCoinsSectionTitle, icon: Icons.auto_awesome_rounded),
                    const SizedBox(height: 12),

                    // 🆕 באנר "מבצע אלוף!" - רק אם בונוס ניצחון הטורניר פעיל
                    // כרגע (ראו _loadTournamentBonus/IapManager.tournamentBonusActive).
                    if (_tournamentBonusActive) _tournamentBonusBanner(),

                    // ===== כרטיס מוביל =====
                    _RecommendedHighlight(
                      highlighted: _recommendedCoinsProductId == IapManager.coins6000Id,
                      child: _FeaturedCard(
                        title: loc.shopLegendPackTitle,
                        amount: _tournamentBonusActive
                            ? loc.shopCoinsAmountLabel(_fmtThousands(_tournamentBoostedAmount(6000)))
                            : loc.shopCoinsAmountLabel('6,000'),
                        bonusNote: _tournamentBonusActive ? loc.shopTournamentBonusTileNote : null,
                        price: _price(IapManager.coins6000Id, "₪160.00"),
                        onTap: () => _buy(IapManager.coins6000Id),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== רשת חבילות 2x2 =====
                    Row(
                      children: [
                        Expanded(
                          child: _RecommendedHighlight(
                            highlighted: _recommendedCoinsProductId == IapManager.coins200Id,
                            child: _CoinTile(
                              icon: Icons.workspace_premium_rounded,
                              iconColor: const Color(0xFFFFC64B),
                              title: loc.shopGoldPackTitle,
                              amount: "200",
                              price: _price(IapManager.coins200Id, "₪10.00"),
                              badge: _firstPurchaseBonusAvailable ? loc.shopFirstPurchaseDoubleBadge : null,
                              onTap: () => _buy(IapManager.coins200Id),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RecommendedHighlight(
                            highlighted: _recommendedCoinsProductId == IapManager.coins100Id,
                            child: _CoinTile(
                              icon: Icons.shield_rounded,
                              iconColor: const Color(0xFF64B5F6),
                              title: loc.shopBeginnerPackTitle,
                              amount: "100",
                              price: _price(IapManager.coins100Id, "₪5.90"),
                              badge: _firstPurchaseBonusAvailable ? loc.shopFirstPurchaseDoubleBadge : null,
                              onTap: () => _buy(IapManager.coins100Id),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RecommendedHighlight(
                            highlighted: _recommendedCoinsProductId == IapManager.coins2500Id,
                            child: _CoinTile(
                              icon: Icons.diamond_rounded,
                              iconColor: const Color(0xFF4DD0E1),
                              title: loc.shopKingsPackTitle,
                              amount: _tournamentBonusActive ? _fmtThousands(_tournamentBoostedAmount(2500)) : "2,500",
                              price: _price(IapManager.coins2500Id, "₪80.00"),
                              badge: _tournamentBonusActive ? loc.shopTournamentBonusBadge : null,
                              onTap: () => _buy(IapManager.coins2500Id),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RecommendedHighlight(
                            highlighted: _recommendedCoinsProductId == IapManager.coins1000Id,
                            child: _CoinTile(
                              icon: Icons.rocket_launch_rounded,
                              iconColor: const Color(0xFFFF8A65),
                              title: loc.shopVipPackTitle,
                              amount: _tournamentBonusActive ? _fmtThousands(_tournamentBoostedAmount(1000)) : "1,000",
                              price: _price(IapManager.coins1000Id, "₪35.00"),
                              // 🆕 כשמבצע האלוף פעיל מעדיפים להציג אותו (מידע יקר-ערך
                              // ומוגבל בזמן) במקום לערום את שני התגים זה על זה.
                              badge: _tournamentBonusActive ? loc.shopTournamentBonusBadge : loc.shopMostPopularBadge,
                              onTap: () => _buy(IapManager.coins1000Id),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18, key: _energySectionKey),
                    _SectionTitle(loc.shopEnergySectionTitle, icon: Icons.bolt_rounded),
                    const SizedBox(height: 12),

                    // ===== רשת חבילות אנרגיה 2x2 - זהה בעיצוב לחבילות
                    // המטבעות למעלה, רק עם כמויות/מחירים של אנרגיה. =====
                    Row(
                      children: [
                        Expanded(
                          child: _CoinTile(
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFF7DD3FC),
                            title: loc.shopEnergySmallTitle,
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
                            title: loc.shopEnergyMediumTitle,
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
                            title: loc.shopEnergyLargeTitle,
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
                            title: loc.shopEnergyHugeTitle,
                            amount: "30 ⚡",
                            price: _price(IapManager.energy30Id, "₪29.90"),
                            onTap: () => _buy(IapManager.energy30Id),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18, key: _noAdsSectionKey),
                    _SectionTitle(loc.shopNoAdsSectionTitle,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.greenAccent, size: 26),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                loc.shopNoAdsActiveMessage,
                                style: const TextStyle(
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
                        title: loc.shopMonthlySubTitle,
                        subtitle: loc.shopMonthlySubSubtitle,
                        price: _price(IapManager.noAdsMonthlyId, "₪15.00"),
                        accent: const Color(0xFFB388FF),
                        onTap: () => _buy(IapManager.noAdsMonthlyId),
                      ),
                      const SizedBox(height: 14),
                      _WideCard(
                        icon: Icons.star_rounded,
                        title: loc.shopLifetimeTitle,
                        subtitle: loc.shopLifetimeSubtitle,
                        price: _price(IapManager.noAdsLifetimeId, "₪40.00"),
                        accent: const Color(0xFFFFC64B),
                        badge: loc.shopBestValueBadge,
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
                        child: Text(loc.shopPrivacyPolicyLink, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5, decoration: TextDecoration.underline)),
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
                          _toast(loc.shopCheckingPurchasesMessage, Colors.deepPurple);
                        },
                        icon: const Icon(Icons.restore_rounded,
                            color: Colors.white54, size: 20),
                        label: Text(loc.shopRestorePurchasesButton,
                            style: const TextStyle(color: Colors.white54)),
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
/// 🆕 עוטף חבילת מטבעות שהומלצה (הגיע ל"אין מספיק מטבעות" - ראו
/// ShopScreen.highlightNeededCoins) בטבעת זוהרת + תג "מומלץ לך" קטן,
/// כדי שיהיה מיידית ברור איזו חבילה בדיוק פותרת את המחסור הנוכחי -
/// לא רק "יש כמה חבילות, תבחר משהו". שקוף לגמרי כשלא מומלצת.
class _RecommendedHighlight extends StatelessWidget {
  final bool highlighted;
  final Widget child;
  const _RecommendedHighlight({required this.highlighted, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!highlighted) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF22C79A)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6EE7B7).withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 1)],
          ),
          child: child,
        ),
        Positioned(
          top: -10,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFF16A46F),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 7)],
            ),
            child: Text(AppLocalizations.of(context)!.shopRecommendedForYouBadge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title, amount, price;
  // 🆕 הערה קטנה אופציונלית מתחת לכמות - מוצגת רק כש"מבצע אלוף!" פעיל
  // (ראו ShopScreen.build), כדי לציין שהכמות שמוצגת למעלה היא כבר הכמות
  // המוגדלת (base × IapManager.tournamentBonusMultiplier) ולא הבסיסית.
  final String? bonusNote;
  final VoidCallback onTap;
  const _FeaturedCard({
    required this.title,
    required this.amount,
    required this.price,
    this.bonusNote,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
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
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: const Color(0xFF3A2405).withValues(alpha: 0.72),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (bonusNote != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              bonusNote!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF16A46F),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
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
            child: Text(
              AppLocalizations.of(context)!.shopBestValueBadge,
              style: const TextStyle(
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
  // 🆕 תג קטן אופציונלי בפינה (כמו ב-_WideCard) - "הכי פופולרי" על חבילה
  // אמצעית, או בונוס רכישה ראשונה על חבילות קטנות (ראו shop_screen build).
  final String? badge;
  const _CoinTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.price,
    required this.onTap,
    this.badge,
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
    final card = InkWell(
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
    if (badge == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -9,
          right: 10,
          left: 10,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5397A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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