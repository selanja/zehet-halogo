// ads_manager.dart
// ניהול כל הפרסומות במשחק:
// 1. Interstitial (מסך מלא) - כל 7 שלבים שנפתרו
// 2. Rewarded (מתגמלת) - צפייה בפרסומת תמורת רמז חינם / בונוס מטבעות בחנות
//
// ⚠️ מזהי בדיקה משמשים בזמן פיתוח בלבד.
// לפני פרסום בחנות: החלף את המזהים למזהים האמיתיים שלך מ-AdMob.
//
// 🔒 חשוב מאוד ותועד בכוונה כאן במפורש: רכישת "ללא פרסומות" (IapManager.noAds)
// חוסמת אך ורק את פרסומות ה-Interstitial הכפויות (onLevelSolved, כל 7
// שלבים) - ראו את הבדיקה "if (IapManager.noAds) return;" בתחילת הפונקציה
// הזו למטה. היא בכוונה לא נבדקת בשום מקום בתוך showRewardedAd/isRewardedReady
// (פרסומות ה-Rewarded, כולל "בונוס פרסומת" בחנות שנותן 15 מטבעות, ורמז
// חינם תמורת צפייה). הרעיון: פרסומות Rewarded הן וולונטריות לגמרי -
// המשתמש בוחר בעצמו לצפות בהן כדי לקבל תגמול, אז אין שום סיבה לחסום
// אותן גם למי שקנה "ללא פרסומות" - למי שרוצה מטבעות/רמז חינם ומוכן
// לצפות בפרסומת מרצונו, אין סיבה למנוע ממנו את זה. אם מישהו בעתיד ירצה
// "לתקן" את זה ולהוסיף בדיקת noAds גם כאן - זו תהיה טעות, לא באג.
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';
import 'debug_log.dart';

class AdsManager {
  // ================================================================
  // 🔴 המתג המרכזי: true = פרסומות בדיקה (לפיתוח), false = אמיתיות.
  // לפני העלאה לחנות: ודא שהערך false ושמזהה האפליקציה בהגדרות
  // הפרויקט הוא המזהה האמיתי שלך.
  // ================================================================
  static const bool useTestAds = false;

  // מזהי בדיקה (מותר ללחוץ עליהם בחופשיות)
  static const String _testInterstitialId = "ca-app-pub-3940256099942544/1033173712";
  static const String _testRewardedId = "ca-app-pub-3940256099942544/5224354917";

  // ================================================================
  // 🔴 המזהים האמיתיים שלך מ-AdMob — מופרדים לפי פלטפורמה!
  // Android ו-iOS הם אפליקציות נפרדות ב-AdMob עם מזהים שונים.
  // ================================================================

  // Android
  static const String _androidInterstitialId = "ca-app-pub-1340341478728321/1748762136";
  static const String _androidRewardedId     = "ca-app-pub-1340341478728321/6973288791";

  // iOS
  static const String _iosInterstitialId = "ca-app-pub-1340341478728321/4132619994";
  static const String _iosRewardedId     = "ca-app-pub-1340341478728321/9434233933";

  static String get _interstitialUnitId {
    if (useTestAds) return _testInterstitialId;
    return Platform.isIOS ? _iosInterstitialId : _androidInterstitialId;
  }

  static String get _rewardedUnitId {
    if (useTestAds) return _testRewardedId;
    return Platform.isIOS ? _iosRewardedId : _androidRewardedId;
  }

  static const int levelsBetweenAds = 7; // פרסומת כל כמה שלבים

  // 🆕 מרווח מינימלי בין שתי הצגות Interstitial כלשהן (מכל טריגר שהוא -
  // "כל 7 שלבים", "אחרי דו-קרב", "גלישה בלי לשחק") - כדי שלא "יתחברו"
  // שני טריגרים שונים כמעט יחד ותהיה תחושה של הפגזה בפרסומות. נבדק
  // בתוך _showInterstitialNow (המקום המשותף היחיד שבו פרסומת Interstitial
  // באמת מוצגת בפועל).
  static DateTime? _lastAdShownAt;
  static const int _minSecondsBetweenAds = 45;

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static bool _initialized = false;

  // 🔁 מונעים כמה בקשות טעינה מקבילות בו-זמנית (זה עלול לגרום לבזבוז
  // בקשות ולמצב שבו טעינה "מוצלחת" נדרסת ע"י טעינה כושלת שרצה איתה יחד)
  static bool _interstitialLoading = false;
  static bool _rewardedLoading = false;

  // ⏱️ Retry עם השהיה גדלה בהדרגה (backoff) - אם טעינה נכשלת (למשל בגלל
  // שאין עדיין מספיק "fill" ליחידת פרסומת חדשה ב-AdMob, או תקלת רשת
  // זמנית), מנסים שוב אוטומטית במקום לחכות רק לפעם הבאה שהמשתמש יפעל.
  static Timer? _interstitialRetryTimer;
  static Timer? _rewardedRetryTimer;
  static int _interstitialRetrySeconds = 15;
  static int _rewardedRetrySeconds = 15;
  static const int _maxRetrySeconds = 120;

  /// אתחול - נקרא פעם אחת ב-main
  static Future<void> init() async {
    DebugLog.add("AdsManager.init START (already=$_initialized)");
    if (_initialized) return;
    _initialized = true;
    try {
      DebugLog.add("AdsManager.init: calling MobileAds.instance.initialize()");
      await MobileAds.instance.initialize();
      DebugLog.add("AdsManager.init: MobileAds initialized OK");
      debugPrint('AdsManager: אותחל. Interstitial ID=$_interstitialUnitId | Rewarded ID=$_rewardedUnitId | iOS=${Platform.isIOS}');
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      DebugLog.add("AdsManager.init ERROR: $e");
      debugPrint('שגיאת אתחול פרסומות: $e');
    }
    DebugLog.add("AdsManager.init END");
  }

  // ==================== Interstitial - כל 7 שלבים ====================

  static void _loadInterstitial() {
    if (_interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;
    _interstitialRetryTimer?.cancel();
    // 🆕 לוג גם ל-DebugLog (נראה בתוך האפליקציה עצמה - הגדרות -> לחיצה
    // ארוכה על "גרסה..." -> מסך דיבאג) ולא רק ל-debugPrint (שנראה רק
    // ב-flutter logs/adb מהמחשב) - כדי שאפשר יהיה לאבחן ישירות מהטלפון
    // אם ה-Interstitial בכלל נטען, בלי לחבר למחשב.
    DebugLog.add("AdsManager._loadInterstitial: requesting load (unitId=$_interstitialUnitId)");
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          _interstitialRetrySeconds = 15; // אחרי הצלחה, מאפסים את ה-backoff
          DebugLog.add("AdsManager._loadInterstitial: LOADED OK ✅");
          debugPrint('Interstitial נטען בהצלחה ✅');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialLoading = false;
          DebugLog.add("AdsManager._loadInterstitial: FAILED - $error (retry in ${_interstitialRetrySeconds}s)");
          debugPrint('Interstitial נכשל בטעינה: $error - ננסה שוב בעוד $_interstitialRetrySeconds שניות');
          _interstitialRetryTimer = Timer(Duration(seconds: _interstitialRetrySeconds), _loadInterstitial);
          _interstitialRetrySeconds = (_interstitialRetrySeconds * 2).clamp(15, _maxRetrySeconds);
        },
      ),
    );
  }

  /// 🆕 מציג בפועל Interstitial אם יש אחת מוכנה וגם עבר מספיק זמן מאז
  /// הפרסומת הקודמת (_minSecondsBetweenAds) - המקום המשותף היחיד שבו
  /// פרסומת Interstitial באמת מוצגת, כדי שכל הטריגרים (שלבים/דו-קרב/
  /// גלישה) ידווחו דרך אותו "שער" ולא יציגו שתיים כמעט יחד. מחזיר true
  /// אם בפועל הוצגה פרסומת.
  static bool _showInterstitialNow() {
    if (_interstitialAd == null) {
      DebugLog.add("AdsManager._showInterstitialNow: skipped - no interstitial loaded yet, requesting one");
      _loadInterstitial();
      return false;
    }
    final last = _lastAdShownAt;
    if (last != null && DateTime.now().difference(last).inSeconds < _minSecondsBetweenAds) {
      DebugLog.add("AdsManager._showInterstitialNow: skipped - too soon since last ad");
      return false;
    }
    _lastAdShownAt = DateTime.now();
    final ad = _interstitialAd!;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        DebugLog.add("AdsManager: interstitial dismissed");
        ad.dispose();
        _loadInterstitial(); // טוענים את הבאה מראש
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        DebugLog.add("AdsManager: interstitial failed to show: $error");
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    return true;
  }

  /// נקרא אחרי כל פתרון שלב. סופר, וכל 7 שלבים מציג פרסומת מסך מלא.
  static Future<void> onLevelSolved() async {
    DebugLog.add("AdsManager.onLevelSolved START");
    // 💎 מנוי ללא פרסומות - לא מציגים פרסומות בין שלבים בכלל
    if (IapManager.noAds) {
      DebugLog.add("AdsManager.onLevelSolved: noAds=true, skipping");
      return;
    }
    // 🆕 שלב נפתר = "שיחק בפועל" - מאפס גם את מונה "גלישה בלי לשחק"
    // (ראו recordGameEntered/_browseSinceGameCount למטה).
    recordGameEntered();
    try {
      final prefs = await SharedPreferences.getInstance();
      int solved = (prefs.getInt('solvedSinceAd') ?? 0) + 1;

      if (solved >= levelsBetweenAds) {
        DebugLog.add("AdsManager.onLevelSolved: attempting interstitial (solved=$solved)");
        final shown = _showInterstitialNow();
        if (shown) {
          await prefs.setInt('solvedSinceAd', 0);
        } else {
          // 🕐 אם הגענו למכסה אבל הפרסומת לא הוצגה בפועל (עוד לא נטענה,
          // או שעוד מוקדם מדי מאז הפרסומת הקודמת) - לא מאפסים את המונה.
          // הוא נשאר "תקוע" על הערך הגבוה כדי שברגע שיהיה אפשר להציג -
          // השלב הבא שייפתר יציג אותה מיד.
          await prefs.setInt('solvedSinceAd', solved);
        }
      } else {
        await prefs.setInt('solvedSinceAd', solved);
      }
    } catch (e) {
      DebugLog.add("AdsManager.onLevelSolved ERROR: $e");
      debugPrint('שגיאת Interstitial: $e');
    }
    DebugLog.add("AdsManager.onLevelSolved END");
  }

  // ==================== 🆕 טריגר: אחרי דו-קרב ====================
  //
  // 🆕 עודכן לפי בקשה מפורשת - לא כל דו-קרב מציג פרסומת מיד אחריו (זה
  // הרגיש "מפוצץ פרסומות"). ההיגיון עכשיו:
  //  (א) אם המשתמש דפדף הרבה (ראה _heavyBrowsingThreshold למטה) *ולפני
  //      שנכנס לדו-קרב* - כלומר "דפדף המון ואז החליט לשחק דו-קרב" -
  //      מציגים פרסומת מיד בסיום אותו דו-קרב ספציפי.
  //  (ב) אחרת - לא כל דו-קרב, אלא בממוצע כל 2 דו-קרבים (לפעמים 1,
  //      לפעמים 2, לפעמים 3 - כדי שזה לא ירגיש כמו נוסחה קבועה וצפויה).
  //  (ג) אם כבר הוצגה פרסומת "גלישה" (ראו _navigationsBeforeIdleAd למטה)
  //      *מאז* הדו-קרב הקודם - לא מציגים עוד פרסומת מיד אחרי הדו-קרב
  //      הזה, כדי לא "להכפיל" - המשתמש כבר קיבל פרסומת לאחרונה.
  // כל המקרים עדיין כפופים למרווח המינימלי הכללי (_showInterstitialNow).

  static const int _heavyBrowsingThreshold = 4; // מתוך _navigationsBeforeIdleAd=6 - "דפדף הרבה"
  static bool _heavyBrowsingBeforeCurrentDuel = false;
  static bool _idleAdShownSinceLastDuel = false;

  static int _duelsSincePostDuelAd = 0;
  static int _nextDuelAdTarget = 2; // מתעדכן רנדומלית - ראו _randomDuelsBetweenAds

  /// בממוצע כל 2 דו-קרבים - אבל לא בדיוק אותו מספר בכל פעם, כדי שזה
  /// לא ירגיש כמו נוסחה קבועה שאפשר "לחשב" מתי הפרסומת הבאה מגיעה.
  static int _randomDuelsBetweenAds() {
    final r = Random().nextInt(10);
    if (r < 3) return 1; // 30% מהזמן - כבר אחרי דו-קרב אחד
    if (r < 8) return 2; // 50% מהזמן - אחרי 2 (ברירת המחדל שביקשת)
    return 3; // 20% מהזמן - נותנים "הפסקה" ומחכים 3
  }

  /// נקרא אחרי שדו-קרב מסתיים (ראו duel_room_screen.dart, _showResultDialog).
  static void onDuelFinished() {
    DebugLog.add("AdsManager.onDuelFinished START");
    if (IapManager.noAds) {
      DebugLog.add("AdsManager.onDuelFinished: noAds=true, skipping");
      recordGameEntered();
      return;
    }

    final heavyBrowsing = _heavyBrowsingBeforeCurrentDuel;
    _heavyBrowsingBeforeCurrentDuel = false; // "נצרך" - לא משפיע על דו-קרבים הבאים
    final skipBecauseRecentIdleAd = _idleAdShownSinceLastDuel;
    _idleAdShownSinceLastDuel = false; // "נצרך" בכל מקרה, גם אם לא מדלגים

    recordGameEntered(); // דו-קרב = "שיחק בפועל" - מאפס גם את מונה הגלישה

    if (skipBecauseRecentIdleAd) {
      // כבר קיבל פרסומת "גלישה" לאחרונה - לא מציקים עוד אחת מיד אחרי
      // הדו-קרב הזה. מתחילים לספור מחדש לקראת הפעם הבאה.
      DebugLog.add("AdsManager.onDuelFinished: skipped (recent idle-browsing ad already shown)");
      _duelsSincePostDuelAd = 0;
      _nextDuelAdTarget = _randomDuelsBetweenAds();
      return;
    }

    bool shouldTryShow;
    if (heavyBrowsing) {
      DebugLog.add("AdsManager.onDuelFinished: heavy browsing before this duel - showing now");
      shouldTryShow = true;
    } else {
      _duelsSincePostDuelAd++;
      shouldTryShow = _duelsSincePostDuelAd >= _nextDuelAdTarget;
      DebugLog.add("AdsManager.onDuelFinished: duelsSincePostDuelAd=$_duelsSincePostDuelAd / target=$_nextDuelAdTarget");
    }

    if (!shouldTryShow) {
      DebugLog.add("AdsManager.onDuelFinished END (not yet)");
      return;
    }

    final shown = _showInterstitialNow();
    if (shown) {
      _duelsSincePostDuelAd = 0;
      _nextDuelAdTarget = _randomDuelsBetweenAds();
    }
    // אם לא הוצגה בפועל (אין פרסומת טעונה/עוד מוקדם מדי) - לא מאפסים,
    // כדי שננסה שוב בדיוק בדו-קרב הבא (לא "מפסידים" את התור).
    DebugLog.add("AdsManager.onDuelFinished END (shown=$shown)");
  }

  // ============== 🆕 טריגר: גלישה הרבה בלי להיכנס למשחק ==============

  // כל מסך "גלישה" (תפריט ראשי, חנות, משימות, אתגר יומי, לובי דו-קרב וכו')
  // קורא ל-recordBrowseNavigation() ב-initState שלו. כל מסך "משחק" בפועל
  // (רמה/דו-קרב) קורא ל-recordGameEntered() (לחדר הדו-קרב - recordDuelEntered()
  // הספציפית, ראו למטה). אחרי _navigationsBeforeIdleAd מעברי-מסך רצופים
  // *בלי* שהיה בינהם משחק בפועל - מציגים Interstitial אחת ומאפסים את
  // המונה (לא חוזר על עצמו בכל מעבר-מסך אחרי זה).
  static int _browseSinceGameCount = 0;
  static const int _navigationsBeforeIdleAd = 6;

  static void recordBrowseNavigation() {
    // 🆕 לוג מפורש גם כשמדלגים בגלל noAds - כדי שאפשר יהיה להבחין
    // במסך הדיבאג (הגדרות -> לחיצה ארוכה על "גרסה..." -> DebugLogScreen)
    // בין "לא הגענו לסף עדיין" לבין "יש רכישת ללא-פרסומות פעילה".
    if (IapManager.noAds) {
      DebugLog.add("AdsManager.recordBrowseNavigation: SKIPPED - IapManager.noAds=true");
      return;
    }
    _browseSinceGameCount++;
    DebugLog.add("AdsManager.recordBrowseNavigation: count=$_browseSinceGameCount / interstitialLoaded=${_interstitialAd != null}");
    if (_browseSinceGameCount >= _navigationsBeforeIdleAd) {
      final shown = _showInterstitialNow();
      if (shown) {
        _browseSinceGameCount = 0;
        // 🆕 סימון שהוצגה פרסומת "גלישה" - כדי ש-onDuelFinished ידע לא
        // להציג עוד אחת מיד אחרי הדו-קרב הבא (ראו _idleAdShownSinceLastDuel).
        _idleAdShownSinceLastDuel = true;
      }
      // אם לא הוצגה בפועל (עוד מוקדם מדי/אין פרסומת טעונה) - המונה נשאר
      // גבוה כדי שננסה שוב במעבר-המסך הבא, בדיוק כמו ב-onLevelSolved.
    }
  }

  /// נקרא כשנכנסים בפועל למשחק (רמה רגילה או חדר דו-קרב) - "מאפס את
  /// השעון" של מונה הגלישה, כי המשתמש כבר לא "גולש בלי לשחק".
  static void recordGameEntered() {
    _browseSinceGameCount = 0;
  }

  /// 🆕 נקרא ספציפית בכניסה לחדר דו-קרב (DuelRoomScreen.initState, לא
  /// logo_level_screen) - בנוסף לאיפוס הרגיל, זוכר אם ממש לפני זה הייתה
  /// "גלישה כבדה" (_browseSinceGameCount כבר גבוה) - זה בדיוק המידע ש-
  /// onDuelFinished צריך כדי להחליט אם להציג פרסומת מיד בסיום הדו-קרב הזה.
  static void recordDuelEntered() {
    _heavyBrowsingBeforeCurrentDuel = _browseSinceGameCount >= _heavyBrowsingThreshold;
    DebugLog.add("AdsManager.recordDuelEntered: heavyBrowsingBefore=$_heavyBrowsingBeforeCurrentDuel (count=$_browseSinceGameCount)");
    recordGameEntered();
  }

  // ==================== Rewarded - פרסומת תמורת רמז ====================

  static void _loadRewarded() {
    if (_rewardedLoading || _rewardedAd != null) return;
    _rewardedLoading = true;
    _rewardedRetryTimer?.cancel();
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
          _rewardedRetrySeconds = 15;
          debugPrint('Rewarded נטען בהצלחה ✅');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedLoading = false;
          debugPrint('Rewarded נכשל בטעינה: $error - ננסה שוב בעוד $_rewardedRetrySeconds שניות');
          _rewardedRetryTimer = Timer(Duration(seconds: _rewardedRetrySeconds), _loadRewarded);
          _rewardedRetrySeconds = (_rewardedRetrySeconds * 2).clamp(15, _maxRetrySeconds);
        },
      ),
    );
  }

  /// האם יש פרסומת מתגמלת מוכנה להצגה.
  /// אם לא מוכנה - מנסה לטעון ברקע כדי שבלחיצה הבאה תהיה מוכנה.
  static bool get isRewardedReady {
    if (_rewardedAd == null) {
      _loadRewarded(); // retry אוטומטי - כדי שבפעם הבאה תהיה מוכנה
      return false;
    }
    return true;
  }

  /// מציג פרסומת מתגמלת. onReward נקרא רק אם המשתמש צפה עד הסוף.
  static void showRewardedAd({required VoidCallback onReward}) {
    DebugLog.add("AdsManager.showRewardedAd START");
    final ad = _rewardedAd;
    if (ad == null) {
      DebugLog.add("AdsManager.showRewardedAd: no ad ready, loading");
      _loadRewarded();
      return;
    }
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        DebugLog.add("AdsManager: rewarded dismissed");
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        DebugLog.add("AdsManager: rewarded failed to show: $error");
        ad.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) {
      DebugLog.add("AdsManager.showRewardedAd: reward earned, calling onReward()");
      onReward(); // המשתמש סיים לצפות - מגיע לו הרמז!
    });
  }
}