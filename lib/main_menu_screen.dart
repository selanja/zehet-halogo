//main_menu_screen
// 🎨 עוצב מחדש לפי מוקאפ ה-Home_Screen שסופק: רקע "אורורה" כהה-סגלגל
// עם רשת נקודות עדינה וסימני "?" צפים (אותה שפת עיצוב שכבר נבנתה ב-
// leaderboard_screen.dart), כרטיס לוגו מרחף, גריד סטטיסטיקות (XP/מטבעות/
// רצף), כפתור CTA בגרדיאנט זהב, וכרטיסי ניווט זכוכיתיים.
// ⚠️ בלי "דילוג שלב" בשום מקום - הפיצ'ר הזה לא קיים באפליקציה שלנו.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'levels_screen.dart';
import 'level_loading_screen.dart';
import 'audio_manager.dart';
import 'leaderboard.dart';
import 'device_id.dart';
import 'package:share_plus/share_plus.dart';
import 'missions_service.dart';
import 'level_data.dart'; // 🆕 levelsCounts/gameLevels גלובליים - לחישוב התקדמות שלבים בכרטיס הבית
import 'energy_service.dart'; // 🆕 אנרגיה לדו-קרב - עכשיו מוצגת גם במסך הבית
import 'ads_manager.dart'; // 🆕 פרסומת מתוגמלת - לכרטיס בונוס המטבעות ולאתגר היומי
import 'notification_manager.dart'; // 🆕 תזכורת "הבונוס זמין שוב" - אותה מערכת בדיוק כמו בחנות
import 'notification_service.dart'; // 🆕 תזכורת יומית: משימות חדשות + אתגר יומי מחכה
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי
import 'meta_events_service.dart'; // 🆕 מעקב "הרשמה הושלמה" ל-Meta Ads
import 'daily_challenge_screen.dart'; // 🆕 קיצור דרך ישיר לאתגר היומי מהמסך הראשי
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון משותף - מופיע עכשיו בכל המסכים הראשיים
import 'starter_pack_service.dart'; // 🆕 מארז פתיחה - זכאות/וריאנט
import 'starter_pack_dialog.dart'; // 🆕 מארז פתיחה - דיאלוג ההצעה
import 'login_streak_service.dart'; // 🆕 רצף כניסה יומי - בונוס על כניסה יום אחרי יום
import 'battle_pass_service.dart'; // 🆕 באטל פאס עונתי - נקודות/שלבים/פרסים
import 'battle_pass_screen.dart'; // 🆕 באטל פאס עונתי - מסך הפרטים המלא
import 'settings_screen.dart'; // 🆕 הגדרות - עברו לאייקון גלגל-שיניים בבית (הוצא מסרגל הניווט התחתון)
import 'account_link_prompt.dart'; // 🆕 דיאלוג "שמור את ההתקדמות שלך" - הצעה לקשר חשבון Google/Apple
import 'account_service.dart'; // 🆕 מסך "ברוכים הבאים" עכשיו מציע גם Google ולא רק שם+אורח - ראה _buildWelcomeChoiceScreen
import 'account_conflict_dialog.dart'; // 🆕 דיאלוג "מצאנו לך חשבון קיים" - ראה _handleGoogleWelcomeSignIn
import 'logo_race_screen.dart'; // 🆕 "מרוץ לוגואים" - מצב אונליין חדש, 1 על 1, מי שמנחש ראשון בכל לוגו מנצח
import 'play_vs_person_mode_screen.dart'; // 🆕 מסך רכזת "שחק מול אחרים" - בחירת מוד (דו-קרב/מירוץ), עוצב לפי מסך "04 · בחירת מוד"
import 'presence_service.dart'; // 🆕 "כמה אנשים משחקים עכשיו" - נקודה ירוקה+מספר על כרטיסי דו-קרב/מרוץ
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי בונוס פרסומת - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון במכשיר אחר
import 'app_notification.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  // 🆕 "וו" סטטי - app_bottom_nav.dart קורא לזה אחרי שהכפתור המרכזי
  // "בית" מחזיר את המשתמש למסך הראשי (popUntil(isFirst)), כדי שהמסך
  // הראשי ירענן סטטיסטיקות/אנרגיה/משימות מיד עם החזרה - בלי צורך
  // ב-RouteObserver מלא. אותו דפוס בדיוק כמו IapManager.onPurchasesUpdated
  // הקיים כבר באפליקציה (ads_manager.dart/iap_manager.dart).
  static VoidCallback? onReturnedHome;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String username = "";
  bool isLoading = true;
  // 🆕 מסך "ברוכים הבאים!" (בחירת שם ראשונית) - עוצב לפי המוקאפ כמסך
  // מלא-מסך אמיתי (לא Dialog צף מעל תפריט ריק) - בדיוק כמו שהמוקאפ מציג
  // אותו: לוגו הילה, כותרת, שדה שם, כפתור CTA. עולה אחרי הספלאש כשאין
  // עדיין שם שמור, ויורד ברגע שנשמר שם תקין ופנוי.
  bool showWelcomeScreen = false;
  // 🆕 מסך "ברוכים הבאים" עכשיו מציג קודם בחירה בין Google לאורח, ולא
  // ישר שדה שם - ראה _buildWelcomeChoiceScreen. false = מציגים את שתי
  // האפשרויות; true = עברנו לשדה השם (או כי נבחר "שחק כאורח", או כי
  // ההתחברות ל-Google הצליחה אבל לחשבון הזה עדיין אין שם שמור בענן).
  bool _welcomeShowingNameEntry = false;
  bool _welcomeGoogleLoading = false;
  bool _welcomeAppleLoading = false;
  // 🩹 השם ש"ימולא מראש" בשדה השם במסך הבחירה הראשוני - ריק אם נבחר
  // "שחק כאורח", או השם שכבר שמור בענן אם ההתחברות ל-Google שחזרה שם
  // קיים (כדי שהשחקן עדיין יאשר/יוכל לשנות אותו, ולא ידלג ישר הביתה -
  // לפי בקשה מפורשת: גם אחרי אורח וגם אחרי Google תמיד לשאול שם).
  String _welcomeInitialName = "";

  // סטטיסטיקות לכרטיסי הבית - נטענות מ-SharedPreferences (אותם מפתחות
  // בדיוק שנמצאים בשימוש ב-logo_level_screen.dart / shop_screen.dart).
  int coins = 15;
  int xp = 0;
  int streak = 0;
  int maxLevel = 1;
  int _missionsUnclaimed = 0; // 🆕 כמה פרסים ממתינים לאיסוף במסך המשימות - לתג על הכרטיס

  // 🆕 אנרגיה לדו-קרב - עכשיו מוצגת ישירות במסך הבית (בעבר רק בלובי הדו-קרב).
  int _energy = EnergyService.maxEnergy;
  Duration? _energyCountdown; // null = מלאה
  Timer? _energyTickTimer;

  // 🆕 "בונוס פרסומת" - בדיוק אותו מנגנון שכבר קיים בחנות (shop_screen.dart):
  // +15 מטבעות תמורת פרסומת, פעם כל 3 שעות. הוצג כאן בכוונה עם *אותו*
  // מפתח SharedPreferences ('lastAdBonusMillis') כדי שהמצב (זמין/בקירור)
  // יהיה תמיד מסונכרן בין מסך הבית לחנות - לא שני בונוסים נפרדים.
  static const Duration _adBonusCooldown = Duration(hours: 3);
  bool _adBonusAvailable = true;
  Duration _adBonusRemaining = Duration.zero;
  bool _collectingAdBonus = false;

  // 🆕 אתגר יומי - תצוגה מקוצרת ישירות במסך הבית (קיצור דרך בלי לעבור
  // דרך מסך המשימות), עם אותם 3 מצבים בדיוק כמו ב-missions_screen.dart.
  DailyChallenge? _dailyChallenge;

  // 🆕 "באטל פאס" - תקציר מצב לכרטיס בתפריט הראשי (טוען אסינכרונית,
  // לא חוסם את שאר המסך - ראה _refreshBattlePass).
  int _bpPoints = 0;
  int _bpTier = 0;
  int _bpPendingClaims = 0;
  bool _bpPremium = false;

  // 🆕 "כמה אנשים משחקים עכשיו" - נקודה ירוקה + מספר על כרטיסי דו-קרב/
  // מרוץ (ראו presence_service.dart). null = עוד לא נטען (לא מציגים
  // כלום, כדי לא להבזיק "0" שגוי לפני שהגיע מידע אמיתי). לא מאזינים
  // בלייב (ראו ההסבר ב-presence_service.dart) - רק שאילתת .count() חד-
  // פעמית בכניסה למסך ואז כל _presenceRefreshInterval כל עוד המסך פתוח.
  int? _duelPlayersNow;
  int? _racePlayersNow;
  Timer? _presenceTimer;
  static const Duration _presenceRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // 🩹 "שחקן שכבר בתוך דו-קרב בפועל לא נספר במחוברים" - ראו הערה
    // מפורטת ב-duel_lobby_screen.dart ליד PresenceService.stopHeartbeat.
    // רשת ביטחון: בכל הגעה/חזרה למסך הבית - עוצרים כל heartbeat נוכחי,
    // כי מסך הבית עצמו אף פעם לא אמור להיספר בתור "משחק עכשיו".
    PresenceService.stopHeartbeat();
    // מתחילים את מוזיקת הרקע רק אחרי שהמסך הראשון כבר צויר,
    // כדי שהיא לא תעמיס על אתחול האפליקציה
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioManager.startBackgroundMusic();
      // 🩹 רשת ביטחון מיידית - אם המוזיקה כבר "נתקעה" מסיבה כלשהי
      // (ראו התיקון המלא ב-audio_manager.dart) - מתקנים כבר עכשיו.
      AudioManager.ensureMusicPlaying();
    });
    // 🆕 "גלישה בלי לשחק" - כל כניסה/חזרה לתפריט הראשי נספרת (ראה
    // AdsManager.recordBrowseNavigation/recordGameEntered).
    AdsManager.recordBrowseNavigation();
    _startSplashScreen();
    // 🆕 מרעננים את שעון האנרגיה/בונוס הפרסומת כל שנייה (רק תצוגה -
    // החישוב האמיתי תמיד מתבצע מול EnergyService/SharedPreferences לפי
    // זמן אמיתי, גם אם הטיימר הזה לא רץ כי המסך לא פעיל).
    _energyTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickEnergyCountdown();
      _tickAdBonusCountdown();
      // 🩹 "רשת ביטחון" נוספת - רצה כל שנייה כל עוד מסך הבית קיים
      // (גם אם הוא לא בהכרח המסך העליון כרגע) - כדי שבכל פעם שחוזרים
      // אליו המוזיקה כבר "מתוקנת" גם אם onReturnedHome לא נקרא בפועל.
      AudioManager.ensureMusicPlaying();
    });
    MainMenuScreen.onReturnedHome = () => _refreshStats();
    // 🆕 בכל פתיחה/כניסה למסך הבית - מתזמנים מחדש את תזכורת "משימות
    // חדשות + אתגר יומי מחכה" קדימה לאיפוס הבא (חצות). ככה שחקן פעיל
    // תמיד מקבל אותה רק אחרי שהוא נעדר לפחות יום אחד, בדיוק כמו תזכורות
    // "חזרה למשחק" ב-main.dart.
    NotificationService.scheduleDailyResetReminder();
    _refreshPresenceCounts();
    _presenceTimer = Timer.periodic(_presenceRefreshInterval, (_) => _refreshPresenceCounts());
  }

  // 🆕 שאילתות .count() חד-פעמיות (לא לייב) - ראו presence_service.dart
  // להסבר המלא למה זה זול (קריאה בודדת לכל שאילתה, לא תלוי בכמות
  // המסמכים). כשלון שקט (מחזיר 0) לא אמור להפריע לשום דבר אחר במסך.
  Future<void> _refreshPresenceCounts() async {
    final results = await Future.wait([
      PresenceService.countActive('duel'),
      PresenceService.countActive('race'),
    ]);
    if (!mounted) return;
    setState(() {
      _duelPlayersNow = results[0];
      _racePlayersNow = results[1];
    });
  }

  @override
  void dispose() {
    _energyTickTimer?.cancel();
    _presenceTimer?.cancel();
    if (MainMenuScreen.onReturnedHome != null) MainMenuScreen.onReturnedHome = null;
    super.dispose();
  }

  void _tickAdBonusCountdown() {
    if (!mounted || _adBonusAvailable) return;
    final next = _adBonusRemaining - const Duration(seconds: 1);
    if (next.isNegative || next == Duration.zero) {
      _refreshAdBonusState();
    } else {
      setState(() => _adBonusRemaining = next);
    }
  }

  Future<void> _refreshAdBonusState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt('lastAdBonusMillis');
    if (!mounted) return;
    if (lastMillis == null) {
      setState(() {
        _adBonusAvailable = true;
        _adBonusRemaining = Duration.zero;
      });
      return;
    }
    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastMillis));
    setState(() {
      _adBonusAvailable = elapsed >= _adBonusCooldown;
      _adBonusRemaining = _adBonusAvailable ? Duration.zero : _adBonusCooldown - elapsed;
    });
  }

  // 🎬 צפייה בפרסומת מתוגמלת -> +15 מטבעות, פעם כל 3 שעות - זהה ל-
  // shop_screen.dart._watchDailyAd בדיוק (אותו מפתח, אותה תזכורת).
  Future<void> _collectAdBonus() async {
    if (!_adBonusAvailable || _collectingAdBonus) return;
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(context, "אין פרסומת זמינה כרגע, נסה שוב עוד רגע", type: AppNotificationType.warning);
      return;
    }
    setState(() => _collectingAdBonus = true);
    AdsManager.showRewardedAd(
      onReward: () async {
        final prefs = await SharedPreferences.getInstance();
        final newCoins = (prefs.getInt('coins') ?? 15) + 15;
        await prefs.setInt('coins', newCoins);
        PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה בונוס הפרסומת לא מסתנכרן לחשבון Google/Apple מקושר
        await prefs.setInt('lastAdBonusMillis', DateTime.now().millisecondsSinceEpoch);
        NotificationManager.scheduleFreeCoinsReminder();
        if (!mounted) return;
        setState(() {
          coins = newCoins;
          _collectingAdBonus = false;
        });
        await _refreshAdBonusState();
        if (mounted) _showRewardDialog("קיבלת 15 מטבעות!"); // 🩹 הוסר אימוג'י המטבע - לא נתמך בפונט של חלק מהמכשירים ומוצג כריבוע ריק
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _adBonusAvailable) setState(() => _collectingAdBonus = false);
    });
  }

  // 🆕 הודעת אישור על המסך אחרי שקיבלת תגמול מפרסומת (מטבעות/אנרגיה) -
  // עם כפתור "סגור" מפורש, במקום Snackbar חולף שקל לפספס.
  void _showRewardDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD86B),
              foregroundColor: const Color(0xFF2A1740),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            ),
            child: const Text("סגור", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDailyChallenge() async {
    final challenge = await MissionsService.getDailyChallenge();
    if (!mounted) return;
    setState(() => _dailyChallenge = challenge);
  }

  Future<void> _playDailyChallenge() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyChallengeScreen()));
    _refreshStats();
  }

  void _tickEnergyCountdown() {
    if (!mounted) return;
    final current = _energyCountdown;
    if (current == null) return;
    final next = current - const Duration(seconds: 1);
    if (next.isNegative || next == Duration.zero) {
      _refreshEnergy(); // הגיע הזמן - מרעננים אמיתי מול EnergyService
    } else {
      setState(() => _energyCountdown = next);
    }
  }

  Future<void> _refreshEnergy() async {
    final energy = await EnergyService.getCurrentEnergy();
    final countdown = await EnergyService.timeUntilNextEnergy();
    if (!mounted) return;
    setState(() {
      _energy = energy;
      _energyCountdown = countdown;
    });
  }

  // ===================== התקדמות שלבים (עולם/שלב-משנה/אחוז) =====================
  int _firstPuzzleIdOfWorld(int world) {
    int startId = 1;
    for (int i = 1; i < world; i++) {
      startId += levelsCounts[i] ?? 23;
    }
    return startId;
  }

  // מחזיר (מספר עולם, שלב-משנה בתוך העולם [1 מבוסס], כמות שלבים בעולם)
  (int, int, int) _worldProgress(int puzzleId) {
    final worldsCount = levelsCounts.length;
    for (int w = 1; w <= worldsCount; w++) {
      final start = _firstPuzzleIdOfWorld(w);
      final count = levelsCounts[w] ?? 23;
      final end = start + count - 1;
      if (puzzleId <= end || w == worldsCount) {
        final sub = (puzzleId - start + 1).clamp(1, count);
        return (w, sub, count);
      }
    }
    return (1, 1, levelsCounts[1] ?? 35);
  }

  // 🆕 שכפול מקומי קטן של getWorldName מ-levels_screen.dart - שם לא
  // מיוצא משם (מתודת instance פרטית), אז משכפלים כאן רק את שמות העולמות.
  String _worldName(int worldNum) {
    switch (worldNum) {
      case 1:
        return "חברות חלק א";
      case 2:
        return "דגלים חלק א";
      case 3:
        return "אפליקציות";
      case 4:
        return "רכבים";
      case 5:
        return "סופרים";
      case 6:
        return "רשתות מוכרות";
      case 7:
        return "חטיפים וממתקים";
      case 8:
        return "קבוצות כדורגל";
      case 9:
        return "ערים בישראל";
      case 10:
        return "דגלים חלק ב";
      case 11:
        return "בנקים וביטוח";
      case 12:
        return "חברות חלק ב";
      case 13:
        return "משחקים מוכרים";
      case 14:
        return "קבוצות NBA";
      case 15:
        return "יחידות בצה\"ל וכוחות הביטחון";
      case 16:
        return "רכבים חלק ב";
      case 17:
        return "אלקטרוניקה ומכשירי חשמל";
      case 18:
        return "תקשורת וחדשות ישראליות";
      default:
        return "כללי";
    }
  }

  Future<void> _startSplashScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('username');
    _readStats(prefs);
    _refreshMissionsBadge(); // לא מחכים - לא צריך לעכב את פתיחת המסך בשביל התג
    _refreshEnergy();
    _refreshAdBonusState();
    _refreshDailyChallenge();

    setState(() {
      isLoading = false;
    });

    if (savedName == null || savedName.isEmpty) {
      setState(() => showWelcomeScreen = true);
    } else {
      setState(() {
        username = savedName;
      });
      // 🩹 תוקן: מארז הפתיחה לא נבדק כאן יותר (בכניסה הקרה לאפליקציה) -
      // לפי בקשה מפורשת, ההצעה לא צריכה "לקפוץ" מיד כשנכנסים, אלא רק
      // אחרי שהמשתמש כבר שיחק קצת. הבדיקה עברה ל-_refreshStats(), שרצה
      // רק כשחוזרים למסך הבית *אחרי* משחק בפועל (שלבים/דו-קרב/וכו') -
      // ראו שם.
      // 🆕 רצף כניסה יומי - בכוונה כן בכניסה הקרה (בניגוד למארז הפתיחה
      // למעלה) - זה בדיוק הרעיון: "נכנסת היום? הנה בונוס". רק למשתמש
      // קיים עם שם שמור (לא למי שרק עכשיו יוצר פרופיל).
      _checkLoginStreak();
    }
  }

  // 🆕 בודק אם היום זו כניסה חדשה (יום קלנדרי שעדיין לא "נספר"), ואם כן
  // מעניק בונוס ומציג דיאלוג חגיגי. לא חוסם כלום - רץ ברקע אחרי שהמסך
  // כבר מוצג.
  Future<void> _checkLoginStreak() async {
    final result = await LoginStreakService.checkInIfNewDay();
    if (result == null || !mounted) {
      // 🆕 אין רצף כניסה חדש היום - בודקים ישר אם להציע קישור חשבון
      // (ראו _maybeShowAccountLinkPrompt) כדי שלא "יתנגש" עם דיאלוג אחר.
      _maybeShowAccountLinkPrompt();
      return;
    }
    _readStats(await SharedPreferences.getInstance()); // המטבעות/אנרגיה כבר התעדכנו - מרעננים את התצוגה
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showLoginStreakDialog(result);
      // 🆕 רק אחרי שדיאלוג הרצף נסגר - כדי לא להציג שני דיאלוגים בו-זמנית.
      _maybeShowAccountLinkPrompt();
    });
  }

  // 🆕 "אני לא רוצה שזה ימחק לשחקנים ששיחקו עכשיו את המשתמש, מבחינתי
  // שהם נכנסים לאפליקציה זה יקפוץ להם שהם צריכים לחבר את החשבון" -
  // הצעה לא-חוסמת לקשר חשבון Google/Apple, כדי שההתקדמות תישמר גם אם
  // יוחלף מכשיר. לא מוצג בכלל אם כבר מקושר או אם ביקשו "אל תזכיר לי שוב"
  // (ראו account_link_prompt.dart).
  Future<void> _maybeShowAccountLinkPrompt() async {
    if (!mounted) return;
    await AccountLinkPrompt.maybeShow(context);
  }

  // 🆕 דיאלוג "רצף כניסה יומי" - שורת 7 נקודות שמראה איפה נמצאים
  // במחזור השבועי, בדיוק כמו שמקובל במשחקים דומים (כל נקודה שכבר
  // "נאספה" מסומנת, הנקודה הנוכחית מודגשת).
  // 🆕 עיצוב מחדש - דיאלוג "רצף כניסה" נבנה מחדש לגמרי לפי המוקאפ (מסך
  // 02 · רצף כניסה): אייקון מתנה מרובע-גרדיאנט, כותרת "יום X ברצף!",
  // שורת "גלולות" יום (נעול/הושלם/היום), שתי גלולות פרס (אנרגיה +
  // מטבעות) וכפתור "אסוף" יחיד. המחזור האמיתי הוא 7 ימים (לא 5 כמו
  // במוקאפ) - נשמר כמו שהוא כי זה חלק מהלוגיקה האמיתית ב-
  // login_streak_service.dart, רק העיצוב הוחלף.
  // 🩹 הופך ל-Future<void> (במקום void) כדי ש-_checkLoginStreak יוכל
  // להמתין לסגירתו לפני שמציג את הצעת קישור החשבון - כדי לא להציג שני
  // דיאלוגים חופפים בו-זמנית.
  // 🩹 שורת "גלולות" היום הוחלפה לשורת 7 עיגולים (עם כיתוב מספר יום
  // מתחתיו) - בדיוק כמו שמופיע בנתוני המוקאפ המדויקים שנשלחו (מסך 02),
  // ולא כרטיסי-פילים כמו קודם. ראו _buildStreakDayRow/_buildStreakDayCircle
  // למטה - אותה שורת עיגולים משמשת גם את _showDailyGiftsDialog כדי ששני
  // הדיאלוגים ייראו זהים.
  Future<void> _showLoginStreakDialog(LoginStreakResult result) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [Color(0xFF3A2A6B), Color(0xFF1D0E3C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.4), blurRadius: 22)],
                ),
                // 🩹 תוקן: היה אימוג'י (🎁) - אותה בעיית תאימות מתועדת כמו
                // אימוג'י המטבע/אנרגיה (ראו app_icons.dart).
                child: const Center(child: Icon(Icons.card_giftcard_rounded, color: Color(0xFF2A1740), size: 36)),
              ),
              const SizedBox(height: 14),
              Text(
                "יום ${result.streakDay} ברצף!",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                "תחזור מחר לפרס גדול יותר",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              // 🩹 שורת עיגולים במקום שורת הפילים הישנה - ראו הערה למעלה.
              // הדיאלוג הזה נפתח *אחרי* שהיום כבר נאסף בפועל (checkInIfNewDay
              // הצליח) - ולכן claimedToday תמיד true כאן.
              _buildStreakDayRow(dayInCycle: result.dayInCycle, claimedToday: true),
              const SizedBox(height: 16),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  if (result.energy > 0) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1E2A5A),
                          border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('+${result.energy}', style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 19, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            // 🩹 אייקון וקטורי (EnergyIcon) במקום אימוג'י ⚡ - ראו app_icons.dart.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Text('אנרגיה ', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                                const EnergyIcon(size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF2A1B4D),
                        border: Border.all(color: const Color(0xFFFFC64B).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('+${result.coins}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 19, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          // 🩹 אייקון וקטורי (CoinIcon) במקום אימוג'י 🪙 - ראו app_icons.dart.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.rtl,
                            children: [
                              Text('מטבעות ', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                              const CoinIcon(size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: Text("אסוף", style: TextStyle(color: Color(0xFF2A1740), fontSize: 16.5, fontWeight: FontWeight.w900))),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _readStats(SharedPreferences prefs) {
    coins = prefs.getInt('coins') ?? 15;
    xp = prefs.getInt('xp') ?? 0;
    streak = prefs.getInt('bestRandomStreak') ?? 0;
    maxLevel = prefs.getInt('maxLevel') ?? 1;
  }

  // כל פעם שחוזרים למסך הבית (מהחנות, מהמשחק וכו') - מרעננים את
  // הסטטיסטיקות כדי שהמספרים בכרטיסים תמיד יהיו עדכניים.
  Future<void> _refreshStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _readStats(prefs));
    _refreshMissionsBadge();
    _refreshPresenceCounts(); // 🆕 גם מספר "משחקים עכשיו" מתעדכן בכל חזרה למסך הבית
    _refreshEnergy();
    _refreshAdBonusState();
    _refreshDailyChallenge();
    _refreshBattlePass(); // 🆕 באטל פאס - נקודות/שלב/פרסים ממתינים לכרטיס בתפריט הראשי
    // 🆕 מארז פתיחה - נבדק כאן (חזרה למסך הבית אחרי משחק בפועל), לא
    // בכניסה הקרה לאפליקציה - כך ההצעה מופיעה רק אחרי שהמשתמש כבר
    // שיחק קצת, לא ישר כשהוא נכנס לאפליקציה.
    _maybeShowStarterPack();
  }

  // 🆕 טוען את מצב "באטל פאס" הנוכחי (נקודות/שלב פתוח/פרסים ממתינים)
  // כדי להציג אותם בתמצית על הכרטיס בתפריט הראשי - הפרטים המלאים
  // (רשימת השלבים, תביעת פרסים) נמצאים במסך הייעודי BattlePassScreen.
  Future<void> _refreshBattlePass() async {
    final points = await BattlePassService.getPoints();
    final pending = await BattlePassService.pendingClaimsCount();
    final premium = await BattlePassService.isPremiumUnlocked();
    if (!mounted) return;
    setState(() {
      _bpPoints = points;
      _bpTier = BattlePassService.currentTierFor(points);
      _bpPendingClaims = pending;
      _bpPremium = premium;
    });
  }

  // 🆕 בודק אם יש להציג את הצעת "מארז פתיחה" (חד-פעמית, מוגבלת בזמן,
  // עם וריאנט תוכן רנדומלי - ראו starter_pack_service.dart), ואם כן -
  // מציג אותה אחרי frame קטן כדי לא להתנגש עם אנימציית החזרה למסך.
  // 🩹 תוקן לפי בקשה מפורשת: הדיאלוג "קופץ" (מוצג אוטומטית) פעם אחת
  // בלבד לכל שחקן, לא בכל חזרה למסך הבית כל עוד חלון 3 השעות עדיין
  // פתוח (שזו ההתנהגות הישנה - הייתה מרגישה טורדנית, "כל פעם שיוצאים
  // מהמשחק זה קופץ"). ה"פעם אחת" נשמרת בדגל נפרד (starterPackAutoShown)
  // כדי לא לגעת בלוגיקת הזכאות/החלון המקורית ב-StarterPackService (היא
  // עדיין נכונה ומשמשת גם את הבאנר הזהוב בחנות - shop_screen.dart -
  // ששם ההצעה עדיין ניתנת למציאה/רכישה ידנית כל עוד החלון פתוח, רק לא
  // "קופצת" יותר על המסך מעצמה).
  Future<void> _maybeShowStarterPack() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('starterPackAutoShown') ?? false) return;
    final variant = await StarterPackService.variantToShow(maxLevel: maxLevel);
    if (variant == null || !mounted) return;
    await prefs.setBool('starterPackAutoShown', true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StarterPackDialog.show(context, variant);
    });
  }

  // 🆕 סופר כמה פרסי משימות/אתגר יומי ממתינים לאיסוף - כדי להציג תג
  // "X פרסים!" על כרטיס המשימות בתפריט הראשי, בלי צורך לפתוח את המסך.
  Future<void> _refreshMissionsBadge() async {
    final count = await MissionsService.unclaimedCount();
    if (!mounted) return;
    setState(() => _missionsUnclaimed = count);
  }

  // נקרא מ-_NameEntryCard אחרי שאומת ששם פנוי - שומר ומחליף למסך הבית.
  Future<void> _saveWelcomeName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    // 🆕 איתות "הרשמה הושלמה" ל-Meta (ראו meta_events_service.dart) -
    // נקרא פעם אחת בדיוק כשמשתמש חדש שומר שם לראשונה, לא בכל פתיחה.
    MetaEventsService.logCompletedRegistration();
    if (!mounted) return;
    setState(() {
      username = name;
      showWelcomeScreen = false;
    });
  }

  // 🆕 "המשך עם Google" ממסך הבחירה הראשוני - משתמש באותה
  // AccountService.signInWithGoogle שכבר קיימת (account_link_prompt.dart
  // מציע אותה גם היום, אחרי הכניסה) - כאן זו כניסה ראשונית, לא קישור
  // מאוחר.
  // 🩹 תוקן בחזרה לפי דיווח מפורש: "יש לי כבר משתמש שמחובר לגוגל, זה לא
  // אמור לבקש שם". אם לחשבון הזה כבר יש שם שמור בענן (AccountService.
  // _afterSignIn כבר שיחזר אותו ל-SharedPreferences *לפני* שההבטחה הזו
  // חוזרת - ראה account_service.dart) - מדלגים ישר הביתה בלי לבקש שם
  // שוב. שואלים שם רק אם זה חיבור ראשון לחשבון הזה ועדיין אין לו שם
  // בכלל (חשבון Google חדש שמעולם לא שיחק). "שחק כאורח" עדיין תמיד
  // מבקש שם (שם הוא הדרך היחידה לזהות אורח).
  // 🩹 גם מתקן את הבאג של "הכול קפץ": בלי הקריאה ל-_refreshStats()
  // כאן, מסך הבית ממשיך להציג את הערכים המקומיים הישנים (מלפני
  // השחזור מהענן) עד לפעם הבאה שהוא מתרענן במקרה - מה שגרם לתחושת
  // "התחלה מחדש" ואז "קפיצה" כשההתקדמות האמיתית סוף-סוף הוצגה.
  Future<void> _handleGoogleWelcomeSignIn() async {
    if (_welcomeGoogleLoading) return;
    setState(() => _welcomeGoogleLoading = true);
    final result = await AccountService.signInWithGoogle();
    if (!mounted) return;
    // 🆕 נמצאה התקדמות שמורה קיימת לחשבון הזה - שואלים את המשתמש לאיזו
    // התקדמות להתחבר (ראו account_conflict_dialog.dart) לפני שממשיכים,
    // במקום לדרוס אוטומטית כמו קודם.
    if (result == LinkResult.conflict) {
      final linked = await showAccountConflictDialog(context);
      if (!mounted) return;
      setState(() => _welcomeGoogleLoading = false);
      if (!linked) {
        // המשתמש ביטל, או שהשמירה נכשלה - במקרה של כישלון מציגים הודעה ידידותית
        if (AccountService.lastAuthFailed) {
          AccountService.lastAuthFailed = false;
          AppNotification.show(context, "ההתחברות נכשלה, נסה שוב מאוחר יותר", type: AppNotificationType.error);
        }
        return;
      }
      await _afterWelcomeLinkSuccess();
      return;
    }
    setState(() => _welcomeGoogleLoading = false);
    switch (result) {
      case LinkResult.success:
        await _afterWelcomeLinkSuccess();
        break;
      case LinkResult.error:
        AppNotification.show(context, "ההתחברות עם Google נכשלה - אפשר לנסות שוב או לשחק כאורח בינתיים", type: AppNotificationType.error);
        break;
      case LinkResult.cancelled:
        break; // המשתמש סגר את חלון הבחירה של Google - נשארים במסך הבחירה
      case LinkResult.conflict:
        break; // כבר טופל למעלה
    }
  }

  // 🆕 "המשך עם Apple" ממסך הבחירה הראשוני - בדיוק אותה לוגיקה כמו
  // _handleGoogleWelcomeSignIn, רק עם AccountService.signInWithApple.
  // לפי דיווח מפורש: המסך הראשוני הציע קודם רק Google, למרות ש-Apple
  // כבר נתמך לגמרי (account_link_prompt.dart כבר מציע את שניהם) - זה
  // היה חוסר-עקביות שהוחמץ בטעות, לא החלטה מכוונת.
  Future<void> _handleAppleWelcomeSignIn() async {
    if (_welcomeAppleLoading) return;
    setState(() => _welcomeAppleLoading = true);
    final result = await AccountService.signInWithApple();
    if (!mounted) return;
    if (result == LinkResult.conflict) {
      final linked = await showAccountConflictDialog(context);
      if (!mounted) return;
      setState(() => _welcomeAppleLoading = false);
      if (!linked) {
        if (AccountService.lastAuthFailed) {
          AccountService.lastAuthFailed = false;
          AppNotification.show(context, "ההתחברות נכשלה, נסה שוב מאוחר יותר", type: AppNotificationType.error);
        }
        return;
      }
      await _afterWelcomeLinkSuccess();
      return;
    }
    setState(() => _welcomeAppleLoading = false);
    switch (result) {
      case LinkResult.success:
        await _afterWelcomeLinkSuccess();
        break;
      case LinkResult.error:
        AppNotification.show(context, "ההתחברות עם Apple נכשלה - אפשר לנסות שוב או לשחק כאורח בינתיים", type: AppNotificationType.error);
        break;
      case LinkResult.cancelled:
        break;
      case LinkResult.conflict:
        break;
    }
  }

  // 🩹 חולץ מתוך _handleGoogleWelcomeSignIn/_handleAppleWelcomeSignIn כדי
  // ששני הספקים (וגם מסלול ה-conflict של כל אחד מהם) ירוצו בדיוק באותה
  // לוגיקה אחרי הצלחה.
  Future<void> _afterWelcomeLinkSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('username');
    if (!mounted) return;
    if (savedName != null && savedName.trim().isNotEmpty) {
      setState(() {
        username = savedName;
        showWelcomeScreen = false;
      });
      _refreshStats(); // 🩹 מרענן מיד את כל הסטטיסטיקות (מטבעות/XP/רמה/רצף) מהשחזור מהענן - בלי זה מסך הבית "קופץ" מאוחר יותר
    } else {
      setState(() {
        _welcomeInitialName = "";
        _welcomeShowingNameEntry = true;
      });
    }
  }

  // 🆕 מסך הבחירה הראשוני - "המשך עם Google" (מקשר/משחזר התקדמות אמיתית
  // דרך AccountService) או "שחק כאורח" (ממשיך למסך בחירת השם הרגיל, בדיוק
  // כמו שהאפליקציה עבדה עד עכשיו - בלי שום חשבון מקושר).
  Widget _buildWelcomeChoiceScreen() {
    return Column(
      children: [
        const Spacer(flex: 3),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFBE50).withValues(alpha: 0.35), const Color(0xFFFFBE50).withValues(alpha: 0.0)])),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
              ),
              child: const Center(child: Text("👋", style: TextStyle(fontSize: 28))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text("ברוכים הבאים!", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          "התחבר כדי שההתקדמות שלך תישמר גם אם תחליף מכשיר, או פשוט שחק",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 26),
        // כפתור "המשך עם Google"
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _welcomeGoogleLoading ? null : _handleGoogleWelcomeSignIn,
            borderRadius: BorderRadius.circular(21),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                color: Colors.white,
              ),
              child: Center(
                child: _welcomeGoogleLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
                            alignment: Alignment.center,
                            child: const Text("G", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 10),
                          const Text("המשך עם Google", textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
              ),
            ),
          ),
        ),
        // כפתור "המשך עם Apple" - רק ב-iOS/macOS (ראו AccountService.appleAvailable)
        if (AccountService.appleAvailable) ...[
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _welcomeAppleLoading ? null : _handleAppleWelcomeSignIn,
              borderRadius: BorderRadius.circular(21),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF000000)]),
                ),
                child: Center(
                  child: _welcomeAppleLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.apple_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            const Text("המשך עם Apple", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        // כפתור "שחק כאורח" - הזרימה המקורית (שם בלבד, בלי חשבון מקושר)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _welcomeShowingNameEntry = true),
            borderRadius: BorderRadius.circular(21),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text("שחק כאורח", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 4),
        const Text(
          "בהמשך אתם מאשרים את תנאי השימוש ומדיניות הפרטיות",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white30, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // 📐 גודל הלוגו כאחוז מרוחב המסך (בין 130 ל-220px) - כך שהוא נראה
      // מאוזן גם על טלפון קטן וגם על טאבלט, לא רק בגודל אחד קבוע
      double splashLogoSize = (MediaQuery.of(context).size.width * 0.45).clamp(130.0, 220.0);
      return Scaffold(
        backgroundColor: const Color(0xFF120C2E),
        body: Stack(
          // 🆕 תוקן: בלי fit: StackFit.expand, ה-Stack היה מתכווץ לגובה
          // התוכן בפועל (Center לא "דורש" את כל גובה המסך) - וה-
          // Positioned.fill של הרקע פשוט לא כיסה את מה שנשאר מתחת.
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _AuroraBackground()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(31),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withValues(alpha: 0.85), const Color(0xFFFFD86B).withValues(alpha: 0.35)],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 44, offset: const Offset(0, 20)),
                        BoxShadow(color: const Color(0xFFFFBE50).withValues(alpha: 0.18), blurRadius: 40),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(28)),
                      child: Image(
                        image: const AssetImage('assets/icon/logo.png'),
                        width: splashLogoSize,
                        height: splashLogoSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "ברוך הבא למשחק!",
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(color: Color(0xFFFFD86B), strokeWidth: 3),
                  ),
                ],
              ),
            ),
            // 🆕 כיתוב גרסה תחתון - כמו במוקאפ מסך "ספלאש"
            // 🩹 מסך אבחון זמני (debug log) הוסר לפי בקשה מפורשת - לא היה
            // אמור להיות נגיש למשתמשי קצה, ולחיצה ארוכה בטעות (למשל כשאין
            // אינטרנט והמשתמש מנסה שוב ושוב) הייתה חושפת אותו.
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: const Text(
                "גרסה 1.2.0 · © כל הזכויות שמורות",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    // 🆕 מסך "ברוכים הבאים!" - מסך מלא אמיתי (לא Dialog צף). עכשיו בשני
    // שלבים: קודם בחירה בין "המשך עם Google" ל"שחק כאורח"
    // (_buildWelcomeChoiceScreen), ורק אחרי הבחירה (או אחרי שהתחברות
    // Google הצליחה בלי שם שמור בענן) מגיעים לשדה השם הרגיל
    // (_NameEntryCard, ללא שינוי בלוגיקה שלו עצמו).
    if (showWelcomeScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF120C2E),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _AuroraBackground()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: _welcomeShowingNameEntry
                    ? Column(
                        children: [
                          const Spacer(flex: 3),
                          _NameEntryCard(
                            title: "ברוכים הבאים!",
                            subtitle: "איך נקרא לך בטבלה הארצית?",
                            initialName: _welcomeInitialName,
                            confirmLabel: "בואו נתחיל ›",
                            popOnSave: false,
                            onSaved: _saveWelcomeName,
                          ),
                          const Spacer(flex: 4),
                          const Text(
                            "בהמשך אתם מאשרים את תנאי השימוש ומדיניות הפרטיות",
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: Colors.white30, fontSize: 10.5, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : _buildWelcomeChoiceScreen(),
              ),
            ),
          ],
        ),
      );
    }

    // 🆕 מסך הבית עוצב מחדש לפי מוקאפ "homescreen.html" עם סרגל ניווט
    // תחתון קבוע (5 יעדים: חנות/מובילים/בית/משימות/הגדרות) - ראו
    // app_bottom_nav.dart (משותף - מופיע עכשיו בכל מסכי הטאב, לא רק כאן).
    // הסטטיסטיקות (XP/מטבעות/רצף/אנרגיה) עברו לשורת המצב העליונה +
    // כרטיס אנרגיה ייעודי.
    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            bottom: false,
            // 🩹 קריסות אדומות אמיתיות ("padding.isNonNegative", ואז
            // "given an infinite size during layout" בניסיון התיקון
            // הקודם עם OverflowBox) - שני הניסיונות הקודמים ("Padding
            // שלילי", ואז "OverflowBox" בתוך Column בגובה לא-מוגבל בתוך
            // SingleChildScrollView) התבססו על widgets שלא מתמודדים טוב
            // עם המצב הזה. התיקון היציב: מסירים לגמרי את ה-Padding
            // האופקי (18) שעטף את כל ה-SingleChildScrollView, ובמקום זה
            // עוטפים כל כרטיס בנפרד ב-Padding(horizontal: 18) - חוץ
            // מ"שחק מול אחרים"/"אתגר רנדומלי" (_buildModesGrid) שנשאר
            // בלי עטיפה, כך שהוא ממלא את כל רוחב המסך (עד השפה) באופן
            // טבעי, בלי שום widget חריג שעלול לקרוס.
            child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                // 🆕 padding תחתון כדי שהתוכן האחרון תמיד יגלול מעל סרגל
                // הניווט הקבוע (גובה 108 + מרווח בטיחות), ולא ייחסם מאחוריו.
                padding: const EdgeInsets.only(bottom: 128),
                child: Column(
                  children: [
                    // 🩹 תוקן: כל המרווחים כאן צומצמו (8→6, 14→10, 18→10,
                    // 20→12, 16→10) כדי שהמסך יתקרב לתחושת "מסך אחד" בלי
                    // גלילה ארוכה, בדיוק כמו במוקאפ (מסך 01 · בית) - קודם
                    // המרווחים היו נדיבים מדי ודחפו את הכרטיס האחרון הרחק
                    // מתחת לקצה הנראה.
                    const SizedBox(height: 12), // 🩹 "תזיז קצת" - הבועה למעלה ירדה טיפה מקצה המסך (היה 6)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 18.0), child: _buildTopBar()),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(index: 0, child: _buildStatsPillsRow()),
                    ),
                    // 🩹 "העניין של הפרסומת תמורת 2 אנרגיה לא מופיעה" - תג
                    // קטן בפינת הפיל לא היה מספיק בולט. נוסף כרטיס ייעודי
                    // מלא-רוחב מיד מתחת לשורת הפילים - מקום שאי אפשר לפספס,
                    // מוצג כל עוד האנרגיה לא מלאה.
                    if (_energy < EnergyService.maxEnergy) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _FadeSlideIn(index: 0, child: _buildEnergyAdCard()),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(index: 1, child: _buildLogoHero()),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(index: 2, child: _buildLevelsCard()),
                    ),
                    const SizedBox(height: 10),
                    // 🩹 תוקן שוב לפי הבהרה מפורשת: "הם לא באותו גודל, לא
                    // בצדדים, ולא מתאימים ברוחב לשאר הדברים שנמצאים שמה" -
                    // כלומר בדיוק ההפך ממה שניסיתי בסבב הקודם (עד-קצה-המסך).
                    // 🩹 תוקן שוב לפי בקשה מפורשת אחרי בדיקה בפועל: "הקצוות
                    // שלהם יהיו כמו של הדברים למעלה ולמטה" - כלומר אותו
                    // ריווח מהקצה כמו כל שאר הכרטיסים במסך (רמות/שלבים
                    // וכו'), לא ממש עד קצה המסך הפיזי. חוזרים לעטוף
                    // ב-Padding(18) כמו כל שאר הכרטיסים.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(index: 3, child: _buildModesGrid()),
                    ),
                    const SizedBox(height: 10),
                    // 🩹 כרטיס "מרוץ לוגואים" הנפרד הוסר מהבית לפי בקשה מפורשת -
                    // "מרוץ לוגואים" עבר להיות אחד משני המודים בתוך "שחק מול
                    // אחרים" (ראה _buildModesGrid למעלה + play_vs_person_mode_screen.dart),
                    // ואין טעם להציג אותו גם ככרטיס נפרד בבית. _buildLogoRaceCard
                    // עצמה נשארה מוגדרת למטה (לא נמחקה) למקרה שתרצה להחזיר אותה.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(index: 4, child: _buildBattlePassCard()),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(index: 5, child: _buildDailyChallengeCard()),
                    ),
                    // 🩹 הכרטיס "בונוס פרסומת" ירד ממסך הבית (לפי העיצוב מחדש +
                    // בקשה לצמצם עומס) - הוא עדיין קיים וזמין בדיוק כמו קודם
                    // בחנות (shop_screen.dart, אותו מפתח lastAdBonusMillis
                    // בדיוק) כך שהתכונה לא אבדה, רק לא תופסת מקום בבית.
                  ],
                ),
              ),
          ),
          // 🆕 סרגל ניווט תחתון קבוע ומשותף - זהה למה שמופיע גם בחנות/
          // מובילים/משימות/הגדרות (ראו app_bottom_nav.dart).
          const AppBottomNav(current: AppTab.home),
        ],
      ),
    );
  }

  // ===================== שורה עליונה: לפי העיצוב מחדש (Claude Design) -
  // מימין: פרופיל (שם + מקום בדירוג + אווטאר). משמאל: גלגל-שיניים
  // (הגדרות - עבר לכאן כי הוצא מסרגל הניווט התחתון) + אייקון מתנה
  // (רצף כניסה יומי - מציג נקודה אדומה כשיש פרס לא-נאסף היום). =====================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // גלולת פרופיל - שם + מקום בדירוג + אווטאר
          // 🩹 תוקן: "הכול אחד על השני" למעלה - גלולת הפרופיל הזו הייתה
          // בגודל חופשי (mainAxisSize.min) בלי שום הגבלת רוחב, כך שאם השם
          // ארוך היא יכלה לגדול עד כדי דחיפת כפתורי ההגדרות/מתנה מחוץ
          // לגבולות המסך (ולכן "המתנה לא מופיעה" - היא הייתה שם, רק
          // דחוסה/חתוכה מחוץ לתצוגה). עטפתי ב-Flexible + הגבלתי את שם
          // המשתמש לשורה אחת עם שלוש נקודות - כך שכפתורי ההגדרות/מתנה
          // תמיד יישארו גלויים במלואם, גם עם שם ארוך.
          Flexible(
            child: Container(
                // 🩹 "רק הגדלת את הבועה אבל לא שינית את הנראות" - עיצוב
                // אמיתי הפעם, לא רק ריפוד: מסגרת עדינה + צל שנותן עומק
                // (בועה "מרחפת" במקום כתם שטוח), האווטאר קיבל טבעת זהב
                // וזז לצד הפתיחה (ימין) עם השם לידו - לא בקצה הרחוק כמו
                // קודם, וכל הבועה ירדה טיפה למטה (ראה ה-SizedBox שלפניה).
                padding: const EdgeInsets.fromLTRB(8, 7, 16, 7),
                constraints: const BoxConstraints(minWidth: 132),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.7), width: 1.6),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF8A3C)])),
                        alignment: Alignment.center,
                        child: Text(
                          username.isNotEmpty ? username.substring(0, 1).toUpperCase() : "?",
                          style: const TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username.isNotEmpty ? username : "שלום!",
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "$xp XP",
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _topIconButton(
                icon: Icons.settings_rounded,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final name = prefs.getString('username') ?? '';
                  if (!mounted) return;
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(username: name)));
                  _refreshStats();
                },
              ),
              const SizedBox(width: 10),
              // 🩹 תוקן: הגרדיאנט המלא (זהב→ורוד) גרם לכפתור הזה להיראות
              // כמו כתם צבעוני מנותק מכל השאר בסרגל (כפתור ההגדרות לידו
              // זכוכיתי-שקוף) - "לא נראה קשור לשום דבר". עכשיו הוא באותה
              // שפה עיצובית בדיוק כמו שאר הכפתורים בסרגל (עיגול זכוכית
              // שקוף), עם טבעת+אייקון בגוון זהב כדי עדיין לבלוט קצת
              // כ"מתנה" - בלי להיראות כמו רכיב מעולם צבעים אחר.
              _topIconButton(
                icon: Icons.card_giftcard_rounded,
                ringColor: const Color(0xFFFFD86B),
                iconColor: const Color(0xFFFFD86B),
                showDot: _adBonusAvailable,
                onTap: _showDailyGiftsDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // כפתור אייקון עגול (הגדרות/מתנה) עם נקודת התראה אופציונלית - בדיוק
  // כמו במוקאפ (מסך 01 · בית): עיגול גדול יותר (56px). כשמועבר gradient
  // (המתנה) העיגול מלא בצבע במקום שקוף - כדי שיבלוט כ"מתנה" צבעונית.
  Widget _topIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
    Color? ringColor,
    Gradient? gradient,
    Color? iconColor, // 🆕 צבע אייקון אופציונלי - כדי לבלוט קצת (למשל מתנה בזהב) בלי גרדיאנט מלא שלא מתאים לשפה העיצובית של שאר הסרגל
  }) {
    return Material(
      color: gradient == null ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
      shape: CircleBorder(side: (ringColor != null && gradient == null) ? BorderSide(color: ringColor.withValues(alpha: 0.7), width: 1.6) : BorderSide.none),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: gradient != null ? [BoxShadow(color: const Color(0xFFF472B6).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))] : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: iconColor ?? Colors.white, size: gradient != null ? 25 : 22),
              if (showDot)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE11D48), border: Border.all(color: const Color(0xFF3A1E7B), width: 1.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== שורת "פילים" - רצף/אנרגיה/מטבעות =====================
  Widget _buildStatsPillsRow() {
    // 🩹 "המקום של ה-2 אנרגיה תמורת פרסומת נעלמה" - בעבר הפיל הזה היה
    // לחיץ (ובלי שום סימן חזותי לכך!) רק כשהאנרגיה בדיוק אפס - כך שרוב
    // הזמן התכונה פשוט לא הייתה קיימת בעיני המשתמש. עכשיו היא זמינה תמיד
    // כל עוד האנרגיה לא מלאה, ויש עליה תג "▶ קטן קבוע (_AdBadge למטה)
    // שמסמן בבירור שאפשר ללחוץ ולקבל עוד - "מקום שאנשים ישימו לב אליו".
    final bool canWatchForEnergy = _energy < EnergyService.maxEnergy;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(child: _bigStatPill(icon: null, emoji: '🔥', color: const Color(0xFFFB7185), text: "$streak")),
        const SizedBox(width: 8),
        Expanded(
          child: _bigStatPill(
            icon: Icons.bolt_rounded,
            emoji: null,
            color: const Color(0xFF7DD3FC),
            text: "$_energy/${EnergyService.maxEnergy}",
            onTap: canWatchForEnergy ? _watchAdForEnergyFromHome : null,
            showAdBadge: canWatchForEnergy,
            // 🆕 "עוד כמה זמן לאנרגיה הבאה" - _energyCountdown כבר מחושב
            // ומתעדכן כל שנייה (ראו _refreshEnergy/_energyCountdown), פשוט
            // לא היה מוצג באף מקום עד עכשיו.
            subtitle: (canWatchForEnergy && _energyCountdown != null) ? "עוד ${_formatMmSs(_energyCountdown!)}" : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _bigStatPill(icon: Icons.monetization_on_rounded, emoji: null, color: const Color(0xFFFFD86B), text: "$coins")),
      ],
    );
  }

  Widget _bigStatPill({
    required IconData? icon,
    required String? emoji,
    required Color color,
    required String text,
    VoidCallback? onTap,
    bool showAdBadge = false, // 🆕 תג "צפה בפרסומת +X" קבוע וגלוי - ראו _buildStatsPillsRow
    String? subtitle, // 🆕 שורת טקסט קטנה מתחת לפיל (למשל "עוד 03:24 לאנרגיה הבאה")
  }) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.14),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(width: 5),
              if (icon == Icons.monetization_on_rounded)
                const CoinIcon(size: 15)
              else if (icon == Icons.bolt_rounded)
                const EnergyIcon(size: 15)
              else if (emoji != null)
                Text(emoji, style: const TextStyle(fontSize: 15))
              else if (icon != null)
                Icon(icon, size: 15, color: color),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    final tappable = Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: pill));
    if (!showAdBadge) return tappable;
    // 🆕 תג קבוע (לא רק בלחיצה) שאומר בפירוש "יש כאן פרסומת לצפייה תמורת
    // אנרגיה" - כדי שהתכונה תהיה גלויה תמיד, לא רק כשמנחשים ללחוץ.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tappable,
        Positioned(
          top: -8,
          left: -6,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF16A46F)]),
                border: Border.all(color: const Color(0xFF120C2E), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.5), blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Color(0xFF08281C), size: 10),
                  const SizedBox(width: 1),
                  Text("+${EnergyService.adRewardAmount}", style: const TextStyle(color: Color(0xFF08281C), fontSize: 9.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 icon עכשיו nullable - כדי לאפשר "פיל" בלי שום אייקון בכלל (ראו
  // ה-XP למעלה, שאיבד את האייקון הוקטורי שלו כי הוא לא הוצג אצל המשתמש -
  // בדיוק כמו שקרה עם אייקוני המטבע/אנרגיה בעבר, לפני שהוחלפו לתמונת PNG).
  Widget _topStatPill({required IconData? icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: color.withValues(alpha: 0.13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🆕 מטבע/אנרגיה = תמונת PNG קבועה (ראו app_icons.dart). icon==null
          // (כמו ב-XP) לא מציג שום אייקון - רק את הטקסט.
          if (icon == Icons.monetization_on_rounded) ...[
            const CoinIcon(size: 13),
            const SizedBox(width: 4),
          ] else if (icon == Icons.bolt_rounded) ...[
            const EnergyIcon(size: 13),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ===================== כרטיס התקדמות שלבים =====================
  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 01 · בית): "25% / ממשיכים /
  // שם עולם · שלב X" + אייקון מפה בריבוע מעוגל, ומתחת פס התקדמות בלבד -
  // בלי "רצועת שלבים" (✓/מספר/מנעול) ובלי כפתור "כל השלבים" בתוך הכרטיס,
  // ששניהם לא קיימים במוקאפ. גרדיאנט כחול→סגול, בלי מסגרת.
  Widget _buildLevelsCard() {
    final (world, sub, count) = _worldProgress(maxLevel);
    final percent = ((sub / count) * 100).round().clamp(0, 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelsScreen()));
          _refreshStats();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF3D7EF3), Color(0xFF5B3CE0)],
            ),
            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🩹 תוקן: הסדר היה הפוך מהמוקאפ - "%" היה בצד ימין והאייקון
              // בצד שמאל. במוקאפ (מסך 01 · בית) זה בדיוק ההפך: האייקון
              // וכותרת ה"ממשיכים" בצד ימין, ואחוז ההתקדמות בצד שמאל.
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: Colors.white.withValues(alpha: 0.22)),
                    child: const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("ממשיכים", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text("${_worldName(world)} · שלב $sub", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    "$percent%",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 8,
                  color: const Color(0xFF34489F),
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: percent / 100,
                    child: Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFFE7A8)])),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== גריד מצבי משחק (דו-קרב / אתגר רנדומלי) =====================
  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 01 · בית): שני כרטיסים מלאי-צבע
  // (לא עוד מסגרת + מילוי שקוף) - "דו־קרב" ורוד/אדום מימין, "אתגר רנדומלי"
  // סגול משמאל, כל אחד עם אייקון בריבוע לבן-שקוף למעלה, כותרת ותת-כותרת
  // קצרה - בלי תג "חדש" ובלי צ'יפ "עולה X אנרגיה" שלא מופיעים במוקאפ.
  // 🩹 תוקן שוב לפי הבהרה מפורשת: "הריבוע הסגול צריך להיות ליד האדום",
  // לא מתחתיו. הניסיון הקודם (Column מלא-רוחב, אחד מעל השני) היה טעות -
  // חוזרים ל-Row צמוד (שני כרטיסים זה ליד זה, "שחק מול אחרים" אדום
  // מימין ו"אתגר רנדומלי" סגול משמאל, כל אחד תופס חצי מהרוחב ב-Expanded),
  // בדיוק כמו שהיה במקור לפני התיקון השגוי.
  Widget _buildModesGrid() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _ModeCard(
            // 🩹 תוקן: היה אימוג'י (⚔️) - אותה בעיית תאימות מתועדת כמו
            // אימוג'י המטבע/אנרגיה (ראו app_icons.dart) - הוחלף לאייקון
            // וקטורי אמין.
            // 🆕 הכרטיס הזה איחד את "דו־קרב" ו"מרוץ לוגואים" לנקודת כניסה
            // אחת - "שחק מול אחרים" - שמובילה למסך רכזת בחירת מוד חדש
            // (PlayVsPersonModeScreen, עוצב לפי מסך "04 · בחירת מוד"),
            // ושם בוחרים באיזה מוד לשחק (הימור עדיין נבחר בתוך כל מוד
            // בנפרד). כרטיס "מרוץ לוגואים" הנפרד הוסר מהבית לפי בקשה
            // מפורשת - שני המודים עכשיו רק כאן, לא כפול.
            icon: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
            gradient: const [Color(0xFFEF3B5B), Color(0xFFC2163F)],
            title: "שחק מול אחרים",
            note: "דו־קרב · מירוץ",
            liveCount: (_duelPlayersNow ?? 0) + (_racePlayersNow ?? 0) > 0 ? (_duelPlayersNow ?? 0) + (_racePlayersNow ?? 0) : null,
            onTap: () async {
              AudioManager.playClick();
              await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayVsPersonModeScreen(username: username)));
              _refreshStats();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
          icon: const Icon(Icons.casino_rounded, color: Colors.white, size: 22),
          gradient: const [Color(0xFFA250F3), Color(0xFF732CDC)],
          title: "אתגר רנדומלי",
          note: "לוגו אקראי · שומר על הרצף",
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LevelLoadingScreen(puzzleId: 0, isRandomMode: true, categoryLabel: "אתגר רנדומלי")),
            );
            _refreshStats();
          },
          ),
        ),
      ],
    );
  }

  // ===================== כרטיס "מרוץ לוגואים" (מצב אונליין חדש) =====================
  // 🆕 כרטיס מלא-רוחב, בסגנון כחול-אנרגיה (כמו _buildEnergyAdCard/
  // _buildDailyChallengeCard) - נפתח ישירות ל-LogoRaceScreen, שם כל
  // הלוגיקה של הלובי/הספירה לאחור/המשחק/התוצאות כבר בנויה
  // (logo_race_service.dart + logo_race_screen.dart).
  Widget _buildLogoRaceCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          AudioManager.playClick();
          await Navigator.push(context, MaterialPageRoute(builder: (context) => LogoRaceScreen(username: username)));
          _refreshStats();
        },
        child: Stack(
          children: [
            _buildLogoRaceCardContent(),
            // 🆕 נקודה ירוקה + "משחקים עכשיו" - הכרטיס הזה רחב ונמוך (לא
            // ריבועי כמו כרטיסי דו-קרב/אתגר רנדומלי), אז הפינה השמאלית-
            // התחתונה שלו נמצאת קרוב לכפתור "שחק" - עדיין אותה פינה בדיוק.
            if (_racePlayersNow != null)
              Positioned(
                left: 10,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.28)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ADE80))),
                      const SizedBox(width: 5),
                      Text('$_racePlayersNow', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoRaceCardContent() {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
            color: const Color(0xFF123A52).withValues(alpha: 0.7),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.flag_circle_rounded, color: Color(0xFF0C2A3D), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("מרוץ לוגואים 🏁", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      "1 על 1 · מי שמנחש ראשון מנצח",
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                ),
                child: const Text("שחק", style: TextStyle(color: Color(0xFF0C2A3D), fontSize: 14, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
  }

  // 🆕 צפייה בפרסומת תמורת אנרגיה - עכשיו נלחצת ישירות מ"פיל" האנרגיה
  // בשורת הסטטיסטיקות למעלה (_buildStatsPillsRow) כשאין אנרגיה בכלל,
  // ולא מכרטיס נפרד (שהוסר כי לא קיים במוקאפ). זהה בעיקרון ל-
  // duel_lobby_screen._watchAdForEnergy.
  Future<void> _watchAdForEnergyFromHome() async {
    // 🆕 קירור אמיתי בין פרסומות-לאנרגיה (בקשה מפורשת: פעם ב-2 דקות) -
    // ראו EnergyService.canWatchAdForEnergy/adEnergyCooldownMinutes.
    final adCooldown = await EnergyService.timeUntilNextAdEnergy();
    if (adCooldown != null) {
      if (!mounted) return;
      AppNotification.show(context, "אפשר לצפות בפרסומת נוספת בעוד ${_formatMmSs(adCooldown)}", type: AppNotificationType.warning);
      return;
    }
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(context, "אין פרסומת זמינה כרגע, נסה שוב עוד רגע", type: AppNotificationType.warning);
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      await EnergyService.addFromAd();
      if (!mounted) return;
      await _refreshEnergy();
      if (mounted) _showRewardDialog("קיבלת ${EnergyService.adRewardAmount} אנרגיה! ⚡");
    });
  }

  // ===================== כרטיס "אתגר יומי" (קיצור דרך מהמסך הראשי) =====================
  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 01 · בית): כרטיס כחול-כהה מלא
  // עם כפתור-פיל תכלת "שחק" צמוד לצד שמאל, כותרת+תיאור קצר במרכז/ימין,
  // ואייקון קטן בפינה הימנית-קיצונית - בלי כרטיס "בונוס X מטבעות" נפרד.
  Widget _buildDailyChallengeCard() {
    final challenge = _dailyChallenge;
    final done = challenge?.completed ?? false;
    final usedUp = challenge != null && !done && challenge.attempted;
    final dimmed = done || usedUp;
    final String subtitle = done
        ? "אתגר יומי · קיבלת את הפרס - חוזר מחר"
        : (usedUp ? "אתגר יומי · נוצל להיום, נסה מחר" : "אתגר יומי · ${MissionsService.dailyChallengeLogoCount} לוגואים");
    final String btnLabel = done ? "בוצע ✓" : (usedUp ? "מחר" : "שחק");

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: dimmed ? null : _playDailyChallenge,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B4A8F).withValues(alpha: 0.6)),
            color: const Color(0xFF1E2A5A),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                done ? Icons.check_circle_rounded : (usedUp ? Icons.timer_off_rounded : Icons.event_note_rounded),
                color: Colors.white.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: dimmed ? 0.5 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                  ),
                  child: Text(btnLabel, style: const TextStyle(color: Color(0xFF0C2A3D), fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== כרטיס "באטל פאס" (עונתי - נקודות/שלב/פרסים
  // ממתינים) - נכנסים למסך הייעודי BattlePassScreen לפרטים ותביעת פרסים.
  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 01 · בית): מספר הנקודות בתוך
  // השלב הנוכחי צמוד לצד שמאל, "X פרסים" (פיל אדום) + כותרת "באטל פאס"
  // צמודים לצד ימין, ומתחת פס התקדמות שמתפרס על כל הרוחב. אייקון
  // מרובע-גרדיאנט כתום עם ניצוץ בפינה הימנית-קיצונית. =====================
  Widget _buildBattlePassCard() {
    final tiers = BattlePassService.tiers;
    final maxTier = tiers.length;
    // 🩹 תוקן: כשעדיין לא הושלם אף שלב (_bpTier == 0) - הקוד הקודם השווה
    // בטעות את "כמות הנקודות הדרושות לשלב הנוכחי" ל"כמות הנקודות הדרושות
    // לשלב 1" גם לצורך ה"נוכחי" וגם לצורך ה"הבא", כך שההפרש (span) יצא
    // תמיד 0 - זו הסיבה ש"0/0" הופיע במקום "0/<כמות הנקודות לשלב 1>".
    // עכשיו: כל עוד לא הושלם אף שלב, נקודת ההתחלה (currentRequired) היא
    // פשוט 0, לא הדרישה של שלב 1 עצמו.
    final int currentRequired = _bpTier <= 0 ? 0 : tiers.firstWhere((t) => t.tier == _bpTier, orElse: () => tiers.first).pointsRequired;
    final nextDef = _bpTier < maxTier ? tiers[_bpTier] : null; // tiers[_bpTier] = השלב הבא (אינדקס 0 = tier 1)
    final int span = nextDef == null ? 0 : nextDef.pointsRequired - currentRequired;
    final int within = nextDef == null ? 0 : (_bpPoints - currentRequired).clamp(0, span);
    final double progress = nextDef == null ? 1.0 : (span == 0 ? 1.0 : within / span);
    final String fractionText = nextDef == null ? "מקסימום" : "$within/$span";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const BattlePassScreen()));
          // 🩹 באג שתוקן: כאן היה נקרא רק _refreshBattlePass() (נקודות/שלב/
          // פרסים ממתינים של הכרטיס עצמו) - אבל לא _refreshStats() המלא,
          // כך שאם נאסף פרס עם מטבעות בתוך הבאטל פאס, המספר בסרגל העליון
          // של מסך הבית לא התעדכן עד שנכנסים למסך אחר (שכן קורא ל-
          // _refreshStats בעצמו). עכשיו קוראים ל-_refreshStats המלא, שכולל
          // גם את _refreshBattlePass בתוכו.
          _refreshStats();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.5)),
            color: const Color(0xFF2B2140).withValues(alpha: 0.6),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)])),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2A1740), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🩹 תוקן: הסדר היה הפוך מהמוקאפ - "באטל פאס" צריך
                    // להיות הכי קרוב לאייקון (בצד ימין), ותג "X פרסים"
                    // מיד אחריו, לא לפניו.
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text("באטל פאס", textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
                        if (_bpPremium) ...[
                          const SizedBox(width: 5),
                          const Text("👑", style: TextStyle(fontSize: 12)),
                        ],
                        if (_bpPendingClaims > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFE11D74)),
                            child: Text('$_bpPendingClaims פרסים', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ],
                        const Spacer(),
                        Text(fractionText, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF241A38),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9A3C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== דיאלוג "המתנות של היום" - נפתח מאייקון המתנה
  // ליד ההגדרות למעלה =====================
  // 🩹 עוצב מחדש לפי בקשה מפורשת: מציג *רק* את רצף הכניסה - בדיוק אותו
  // עיצוב כמו הדיאלוג האוטומטי שקופץ בכניסה הראשונה של היום
  // (_showLoginStreakDialog, שכבר בנוי במדויק לפי המוקאפ "02 · רצף
  // כניסה"), רק עם המצב הנוכחי (לא בהכרח "עכשיו נאסף") - כדי שהמשתמש
  // יוכל לבדוק את מצב הרצף שלו בכל רגע. בונוס הפרסומת (מטבעות) הוסר
  // מכאן לגמרי - הוא עדיין קיים וזמין בדיוק כמו קודם בכרטיס הייעודי לו
  // בחנות (shop_screen.dart), רק לא מוצג יותר בדיאלוג הזה.
  // 🩹 תוקן לפי בדיקת נתוני ה-DOM המדויקים של המוקאפ (מסך "02 · רצף
  // כניסה") - שורת הימים היא שורת 7 עיגולים (40x40, עם מספר יום מתחתיו),
  // לא שורת "גלולות"/כרטיסים כמו שהיה. נוסף גם משפט "טיזר" למרחק ליום 7
  // (יום השיא/יהלום) ושורת תזכורת דקורטיבית בתחתית - בדיוק כמו במוקאפ.
  // כרטיס "כוכב" (⭐ +1) שמופיע במוקאפ *לא* נוסף בכוונה - אין שדה כזה
  // במודל הנתונים האמיתי (LoginStreakService.cycleRewards מכיל רק
  // coins/energy) ולא רצינו להמציא מערכת "נקודות/כוכבים" מזויפת. אם
  // בעתיד תרצה שדה תגמול אמיתי כזה - צריך קודם להוסיף אותו ל-
  // login_streak_service.dart.
  // 🆕 שורת 7 העיגולים של "רצף הכניסה" - עטופה כך שתתפרס שווה על פני כל
  // רוחב הדיאלוג. משמשת גם את _showLoginStreakDialog וגם את
  // _showDailyGiftsDialog כדי ששני הדיאלוגים ייראו זהים.
  Widget _buildStreakDayRow({required int dayInCycle, required bool claimedToday}) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        return _buildStreakDayCircle(dayNum: dayNum, dayInCycle: dayInCycle, claimedToday: claimedToday);
      }),
    );
  }

  // 🆕 עיגול יום בודד בשורת "רצף הכניסה" - תואם למוקאפ "02 · רצף כניסה":
  // עיגול 40x40 עם כיתוב מספר יום מתחתיו. שלושה מצבים (הושלם/היום/נעול),
  // ועבור יום 7 (יום השיא) - אייקון יהלום במקום וי/מנעול רגילים.
  // 🩹 אייקון וקטורי (Icons.*) ולא אימוג'י (✓/🎁/🔒/💎) - כדי למנוע את
  // בעיית "הריבוע הריק" בפונט האימוג'י שכבר תועדה כמה פעמים באפליקציה
  // הזו (ראו app_icons.dart).
  Widget _buildStreakDayCircle({required int dayNum, required int dayInCycle, required bool claimedToday}) {
    final bool isMilestone = dayNum == 7; // יום 7 - מארז היהלום
    final bool done = dayNum < dayInCycle || (dayNum == dayInCycle && claimedToday);
    final bool isToday = dayNum == dayInCycle && !claimedToday;
    final bool locked = dayNum > dayInCycle;

    final IconData icon;
    final Color iconColor;
    final Color circleColor;
    final Color borderColor;
    List<BoxShadow> shadows = const [];

    if (isToday) {
      icon = Icons.card_giftcard_rounded;
      iconColor = const Color(0xFF2A1740);
      circleColor = const Color(0xFFFF9A3C);
      borderColor = Colors.white.withValues(alpha: 0.5);
      shadows = [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.55), blurRadius: 14, spreadRadius: 1)];
    } else if (done) {
      icon = isMilestone ? Icons.diamond_rounded : Icons.check_rounded;
      iconColor = isMilestone ? const Color(0xFFFFD86B) : const Color(0xFF6EE7B7);
      circleColor = const Color(0xFF1E2A5A);
      borderColor = Colors.white.withValues(alpha: 0.18);
    } else {
      // locked - ימים עתידיים
      icon = isMilestone ? Icons.diamond_rounded : Icons.lock_rounded;
      iconColor = Colors.white.withValues(alpha: 0.3);
      circleColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white.withValues(alpha: 0.08);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(color: borderColor),
            boxShadow: shadows,
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
        const SizedBox(height: 5),
        Text(
          '$dayNum',
          style: TextStyle(
            color: isToday ? Colors.white : Colors.white.withValues(alpha: locked ? 0.35 : 0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Future<void> _showDailyGiftsDialog() async {
    final streakDay = await LoginStreakService.getCurrentStreak();
    final dayInCycle = await LoginStreakService.getCurrentDayInCycle();
    final claimedToday = await LoginStreakService.claimedToday();
    final todayReward = LoginStreakService.cycleRewards[dayInCycle - 1];
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [Color(0xFF3A2A6B), Color(0xFF1D0E3C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.4), blurRadius: 22)],
                ),
                child: const Center(child: Icon(Icons.card_giftcard_rounded, color: Color(0xFF2A1740), size: 36)),
              ),
              const SizedBox(height: 14),
              Text(
                "יום $streakDay ברצף!",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                claimedToday ? "כבר נאסף היום - תחזור מחר לפרס הבא" : "תחזור מחר לפרס גדול יותר",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              // 🩹 שורת עיגולים במקום שורת הפילים הישנה - ראו הערה למעלה.
              _buildStreakDayRow(dayInCycle: dayInCycle, claimedToday: claimedToday),
              const SizedBox(height: 14),
              // 🆕 משפט "טיזר" למרחק ליום 7 (יום השיא/מארז היהלום) - בדיוק
              // כמו שמופיע במוקאפ. אייקון יהלום וקטורי (לא אימוג'י 💎) -
              // אותו טעם כמו כל שאר האייקונים בדיאלוג הזה.
              Builder(builder: (_) {
                final daysLeft = 7 - dayInCycle;
                final String teaserText;
                if (dayInCycle >= 7 && claimedToday) {
                  teaserText = "מזל טוב - זכית במארז היהלום של יום 7!";
                } else if (dayInCycle >= 7) {
                  teaserText = "היום היום הגדול - יום 7 ומארז היהלום!";
                } else if (daysLeft == 1) {
                  teaserText = "עוד יום אחד - ומקבל מארז יהלום";
                } else {
                  teaserText = "עוד $daysLeft ימים - ומקבל מארז יהלום";
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(teaserText, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 5),
                    const Icon(Icons.diamond_rounded, size: 13, color: Color(0xFF7DD3FC)),
                  ],
                );
              }),
              const SizedBox(height: 16),
              // 🆕 כותרת "הפרס של היום" מעל שורת הפרסים - בדיוק כמו במוקאפ.
              // כרטיס ה"כוכב" (⭐ +1) שמופיע שם *לא* נכלל - ראו הערה למעלה.
              Align(
                alignment: Alignment.centerRight,
                child: Text("הפרס של היום", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  if ((todayReward['energy'] ?? 0) > 0) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1E2A5A),
                          border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('+${todayReward['energy']}', style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 19, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            // 🩹 אייקון וקטורי (EnergyIcon) במקום אימוג'י ⚡ - ראו app_icons.dart.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Text('אנרגיה ', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                                const EnergyIcon(size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF2A1B4D),
                        border: Border.all(color: const Color(0xFFFFC64B).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('+${todayReward['coins']}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 19, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          // 🩹 אייקון וקטורי (CoinIcon) במקום אימוג'י מטבע (🪙) - לא נתמך
                          // בפונט של חלק מהמכשירים ומוצג כריבוע ריק. ראו app_icons.dart.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.rtl,
                            children: [
                              Text('מטבעות ', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                              const CoinIcon(size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(dialogContext),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: Text("סגור", style: TextStyle(color: Color(0xFF2A1740), fontSize: 16.5, fontWeight: FontWeight.w900))),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 🆕 שורת תזכורת דקורטיבית בתחתית הדיאלוג - בדיוק כמו במוקאפ.
              // אין באפליקציה כרגע מנגנון "שעת תזכורת" אמיתי לרצף כניסה
              // (בדקתי ב-notification_service.dart / notification_manager.dart -
              // התזכורות המתוזמנות שם הן על משימות/בונוס פרסומת בלבד, לא על
              // רצף הכניסה) - אז זו שורת טקסט קישוטית קבועה בלבד, לא הבטחה
              // אמיתית לפוש בשעה הזו. אם בעתיד תרצה תזכורת אמיתית לרצף -
              // צריך להוסיף לה תזמון ייעודי משלה, בדומה ל-scheduleFreeCoinsReminder.
              Text(
                "תזכורת מחר · 20:00",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 כרטיס "צפה בפרסומת - קבל אנרגיה" מלא-רוחב, ליד שורת הפילים -
  // אותו רעיון בדיוק כמו "בונוס פרסומת" (מטבעות), רק בצבע כחול-אנרגיה
  // ובלי קירור (זמין תמיד כל עוד האנרגיה לא מלאה, בלי מגבלת 3 שעות).
  Widget _buildEnergyAdCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _watchAdForEnergyFromHome,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.4)),
            gradient: LinearGradient(colors: [const Color(0xFF38BDF8).withValues(alpha: 0.16), const Color(0xFF38BDF8).withValues(alpha: 0.02)]),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFF38BDF8).withValues(alpha: 0.22)),
                child: const Icon(Icons.smart_display_rounded, color: Color(0xFF7DD3FC), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("צריך אנרגיה?", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      "צפה בפרסומת - קבל ${EnergyService.adRewardAmount} אנרגיה מיידית",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.5)),
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                ),
                child: const Text("צפה", textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // גרסה קלה של _buildDailyBonusCard עם onTap שהוזרם מבחוץ (סוגר קודם
  // את דיאלוג "המתנות של היום"), כדי שהמצב לא יישאר "תקוע" ישן בתוך
  // הדיאלוג אחרי שהבונוס נאסף בפועל.
  Widget _dailyGiftAdBonusTile({required VoidCallback onCollect}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _adBonusAvailable ? onCollect : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.35)),
            gradient: LinearGradient(colors: [const Color(0xFF34D399).withValues(alpha: 0.12), const Color(0xFF34D399).withValues(alpha: 0.02)]),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFF34D399).withValues(alpha: 0.22)),
                child: const Icon(Icons.smart_display_rounded, color: Color(0xFFA7F3D0), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("בונוס פרסומת", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      _adBonusAvailable ? "צפה בפרסומת - קבל 15 מטבעות" : "זמין שוב בעוד ${_formatHms(_adBonusRemaining)}",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.5)),
                  color: const Color(0xFF34D399).withValues(alpha: _adBonusAvailable ? 0.18 : 0.07),
                ),
                child: Text(
                  _adBonusAvailable ? "צפה" : "ממתין",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: _adBonusAvailable ? const Color(0xFFA7F3D0) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== כרטיס "בונוס פרסומת" (מוקטן, אותו מנגנון בדיוק
  // כמו בחנות - +15 מטבעות פעם כל 3 שעות) - נשאר קיים כרכיב עצמאי, אבל
  // כרגע לא בשימוש בשום מקום אחר (הוחלף ב-_dailyGiftAdBonusTile בתוך
  // דיאלוג "המתנות של היום" למעלה). =====================
  Widget _buildDailyBonusCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _adBonusAvailable ? _collectAdBonus : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.35)),
            gradient: LinearGradient(colors: [const Color(0xFF34D399).withValues(alpha: 0.12), const Color(0xFF34D399).withValues(alpha: 0.02)]),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFF34D399).withValues(alpha: 0.22)),
                child: const Icon(Icons.smart_display_rounded, color: Color(0xFFA7F3D0), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("בונוס פרסומת", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      _adBonusAvailable ? "צפה בפרסומת - קבל 15 מטבעות" : "זמין שוב בעוד ${_formatHms(_adBonusRemaining)}",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.5)),
                  color: const Color(0xFF34D399).withValues(alpha: _adBonusAvailable ? 0.18 : 0.07),
                ),
                child: _collectingAdBonus
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA7F3D0)))
                    : Text(
                        _adBonusAvailable ? "צפה" : "בהמתנה",
                        style: TextStyle(color: const Color(0xFFA7F3D0).withValues(alpha: _adBonusAvailable ? 1 : 0.55), fontSize: 12, fontWeight: FontWeight.w900),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 עוד:שנייה קצר (בלי שעות) - לתצוגת "עוד כמה זמן לאנרגיה הבאה"
  // (עד 5 דקות תמיד, אין צורך בשעות כמו ב-_formatHms).
  String _formatMmSs(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _formatHms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ===================== לוגו מרחף =====================
  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 01 · בית): הלוגו עצמו (שכבר
  // כולל מסגרת/הילה זהובה מצוירת בתוך התמונה) מוצג ישירות על הרקע, בלי
  // שום כרטיס/מסגרת נוספת מסביבו - לא עוד "קופסה" סגולה עוטפת אותו.
  Widget _buildLogoHero() {
    return _FloatHero(
      child: Builder(builder: (context) {
        // 🩹 תוקן: היה 0.56 עם מינימום 210 - יצא לוגו ענק שתפס כמעט את
        // כל רוחב המסך. במוקאפ (מסך 01 · בית) הלוגו הוא בגודל "אייקון"
        // בינוני, בערך שליש מרוחב המסך - לא הירו-אלמנט דומיננטי.
        final double size = (MediaQuery.of(context).size.width * 0.34).clamp(130.0, 170.0);
        return Image.asset('assets/icon/logo.png', width: size, fit: BoxFit.contain);
      }),
    );
  }

  // 📤 הזמנת חברים - נפתח תפריט השיתוף הרגיל של הטלפון (Share.share),
  // כדי שהחבר יוכל לבחור וואטסאפ/מסרונים/כל אפליקציה אחרת בעצמו, וכולל
  // קישור אמיתי למשחק - לינק ל-App Store וגם ל-Google Play יחד באותה
  // הודעה, כי אין לדעת מראש אם החבר על אייפון או גלקסי.
  // ⚠️ דורש את חבילת share_plus (יש להוסיף ל-pubspec.yaml:
  //    dependencies:
  //      share_plus: ^10.0.0
  //    ואז להריץ: flutter pub get)
  static const String _iosStoreLink = "https://apps.apple.com/au/app/%D7%96%D7%94%D7%94-%D7%90%D7%AA-%D7%94%D7%9C%D7%95%D7%92%D7%95/id6797976197";
  static const String _androidStoreLink = "https://play.google.com/store/apps/details?id=com.ofeksela.zehethalogo&hl=he";

  Future<void> _inviteFriends() async {
    final String text =
        "בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n"
        "📱 אייפון: $_iosStoreLink\n"
        "🤖 אנדרואיד/גלקסי: $_androidStoreLink";
    try {
      await Share.share(text, subject: "זהה את הלוגו!");
    } catch (_) {
      if (mounted) _showShareFallback(text);
    }
  }

  void _showShareFallback(String text) {
    AppNotification.show(context, "לא נמצאה אפליקציית שיתוף. אפשר להעתיק ולשלוח ידנית:\n$text", duration: const Duration(seconds: 5));
  }


}

enum _NameCheckStatus { idle, checking, available, taken }


// ============================================================
// הליבה המשותפת: שדה קלט שם + בדיקת זמינות אמיתית מול Firestore (debounce)
// + כפתור CTA - בלי שום "מעטפת" חיצונית (Dialog/Scaffold), כדי שאפשר
// יהיה להשתמש באותה לוגיקה בדיוק גם בתוך Dialog (שינוי שם) וגם במסך מלא
// (הרשמה ראשונית - אחרי מסך הבחירה Google/אורח, ראה _buildWelcomeChoiceScreen,
// או ישירות משם החשבון בהגדרות).
// ============================================================
class _NameEntryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String initialName;
  final String confirmLabel;
  final bool showCancel;
  final Future<void> Function(String name) onSaved;
  // true = לסגור עם Navigator.pop אחרי שמירה מוצלחת (שימוש בתוך Dialog).
  // false = לא לגעת בניווט בכלל - הקורא (onSaved) אחראי להחליף מסך בעצמו
  // (שימוש במסך "הרשמה" מלא, שאין לו Route לסגור).
  final bool popOnSave;

  const _NameEntryCard({
    required this.title,
    required this.subtitle,
    required this.initialName,
    required this.confirmLabel,
    required this.onSaved,
    required this.popOnSave,
    this.showCancel = false,
  });

  @override
  State<_NameEntryCard> createState() => _NameEntryCardState();
}

class _NameEntryCardState extends State<_NameEntryCard> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);
  Timer? _debounce;
  _NameCheckStatus _status = _NameCheckStatus.idle;
  bool _saving = false;
  String? _myDeviceId;

  @override
  void initState() {
    super.initState();
    DeviceId.get().then((id) => _myDeviceId = id);
    // אם נכנסים עם שם קיים (מסך "שינוי שם") - השם הנוכחי כמובן "פנוי"
    // עבורנו (הוא כבר שלנו), בלי צורך לבדוק מול Firestore מיד בפתיחה.
    if (widget.initialName.trim().isNotEmpty) _status = _NameCheckStatus.available;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _status = _NameCheckStatus.idle);
      return;
    }
    if (trimmed == widget.initialName.trim()) {
      // אותו שם שכבר יש לנו - תמיד "פנוי" מבחינתנו, בלי לבדוק שוב
      setState(() => _status = _NameCheckStatus.available);
      return;
    }
    setState(() => _status = _NameCheckStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final taken = await LeaderboardService.isNameTaken(trimmed, excludeDeviceId: _myDeviceId);
      if (!mounted) return;
      // ⚠️ בודקים שהטקסט לא השתנה בינתיים (המשתמש המשיך להקליד) - כדי
      // שתוצאה איטית של בקשה ישנה לא "תדרוס" תוצאה עדכנית יותר.
      if (_controller.text.trim() != trimmed) return;
      setState(() => _status = taken ? _NameCheckStatus.taken : _NameCheckStatus.available);
    });
  }

  Future<void> _onConfirm() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _status == _NameCheckStatus.taken || _status == _NameCheckStatus.checking || _saving) return;
    setState(() => _saving = true);
    // בדיקה אחרונה וסופית ממש לפני השמירה - מונעת מקרה קצה נדיר שבו שני
    // שחקנים "תפסו" בו-זמנית את אותו השם בין הבדיקה האחרונה לשמירה.
    final taken = await LeaderboardService.isNameTaken(name, excludeDeviceId: _myDeviceId);
    if (!mounted) return;
    if (taken) {
      setState(() {
        _status = _NameCheckStatus.taken;
        _saving = false;
      });
      return;
    }
    await widget.onSaved(name);
    if (mounted && widget.popOnSave) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // הילת-זוהר + לוגו קטן, כמו במוקאפ מסך ה"הרשמה"
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFBE50).withValues(alpha: 0.35), const Color(0xFFFFBE50).withValues(alpha: 0.0)])),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
              ),
              child: const Center(child: Text("?", style: TextStyle(fontSize: 28, color: Color(0xFF2A1740), fontWeight: FontWeight.w900))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(widget.title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(widget.subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),

        // גלולת קלט השם - גבול בגרדיאנט זהב, כמו במוקאפ
        Container(
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.15)]),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(21), color: const Color(0xFF170F38).withValues(alpha: 0.9)),
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 12,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _onConfirm(),
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      hintText: "הקלד את שמך כאן...",
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusPill(),
        const SizedBox(height: 18),

        // כפתור CTA - "פועל" רק אם השם פנוי ותקין
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onConfirm,
            borderRadius: BorderRadius.circular(21),
            child: Opacity(
              opacity: (_status == _NameCheckStatus.taken || _controller.text.trim().isEmpty) ? 0.45 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                      : Text(widget.confirmLabel, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
        ),

        if (widget.showCancel) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusPill() {
    switch (_status) {
      case _NameCheckStatus.idle:
        return const SizedBox(height: 1);
      case _NameCheckStatus.checking:
        return _statusRow(
          icon: const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD86B))),
          text: "בודק זמינות...",
          textColor: Colors.white.withValues(alpha: 0.55),
          borderColor: Colors.white.withValues(alpha: 0.14),
          bgColor: Colors.white.withValues(alpha: 0.05),
        );
      case _NameCheckStatus.available:
        return _statusRow(
          icon: const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF6EE7B7)),
          text: "השם פנוי",
          textColor: const Color(0xFFA7F3D0),
          borderColor: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
          bgColor: const Color(0xFF34D399).withValues(alpha: 0.1),
        );
      case _NameCheckStatus.taken:
        return _statusRow(
          icon: const Icon(Icons.cancel_rounded, size: 15, color: Color(0xFFFB7185)),
          text: "השם הזה כבר תפוס, נסה שם אחר",
          textColor: const Color(0xFFFFC9D1),
          borderColor: const Color(0xFFFB7185).withValues(alpha: 0.4),
          bgColor: const Color(0xFFFB7185).withValues(alpha: 0.1),
        );
    }
  }

  Widget _statusRow({required Widget icon, required String text, required Color textColor, required Color borderColor, required Color bgColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor), color: bgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

// ============================================================
// אנימציית "ריחוף" עדינה לכרטיס הלוגו (מקביל ל-floatY ב-CSS של המוקאפ) -
// עולה ויורד ברכות באופן אינסופי.
// ============================================================
class _FloatHero extends StatefulWidget {
  final Widget child;
  const _FloatHero({required this.child});

  @override
  State<_FloatHero> createState() => _FloatHeroState();
}

class _FloatHeroState extends State<_FloatHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = Curves.easeInOut.transform(_controller.value) * -8;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

// ============================================================
// רקע "אורורה" אנימטיבי (גרדיאנט סגול-כהה + כתמי צבע נעים + רשת נקודות
// + סימני "?" צפים) - זהה בעיצובו ל-_AuroraBackground שנבנה כבר
// ב-leaderboard_screen.dart, משוכפל כאן (בפרטיות לקובץ) כדי לשמור על
// עקביות חזותית בכל האפליקציה בלי ליצור תלות בין שני המסכים.
// ============================================================
// 🆕 תוקן סופית: הוסרו לגמרי ה-ImageFiltered(ImageFilter.blur) המקורי,
// ה-RadialGradient שהוחלף בו, וגם רשת הנקודות (CustomPaint) - בבדיקות
// בפועל על מכשיר אמיתי התברר שכל שלושת אלה (blur / RadialGradient /
// CustomPaint עם לולאת drawCircle) גורמים לאותה תקיעה/קריסה ב-iOS,
// ככל הנראה shader/raster jank ב-Impeller. לעומת זאת LinearGradient
// (גם עם כמה שכבות שקופות חלקית זו על זו) לא גרם לשום בעיה בכל
// שאר האפליקציה - ולכן העומק/הצבעוניות כאן מגיעים אך ורק משכבות
// LinearGradient, בדיוק כמו ב-app_background.dart.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF34186E), Color(0xFF3A1B78), Color(0xFF241154), Color(0xFF120C2E)],
                stops: [0.0, 0.3, 0.64, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0x2EFF8E3C), Color(0x00FF8E3C)],
                stops: [0.0, 0.55],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Color(0x2438BDF8), Color(0x0038BDF8)],
                stops: [0.0, 0.55],
              ),
            ),
          ),
        ),
        // ⚠️ בכוונה בלי _FloatingMarks (סימני "?" צפים וענקיים) במסך הבית
        // הספציפי הזה - לפי הבקשה "להוריד את הרקע" כדי שהמסך ירגיש פחות
        // עמוס ויתן יותר "אוויר" לתוכן המכווץ (לוגו/כרטיסים/כפתורים).
        // הם עדיין קיימים במסכים אחרים (טבלה ארצית, בחירת רמה) ללא שינוי.
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingMarks extends StatelessWidget {
  final AnimationController controller;
  const _FloatingMarks({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        double drift(double phase) => sin((t + phase) * 2 * pi) * 8;
        return Stack(
          children: [
            Positioned(top: 90 + drift(0), left: -18, child: Text("?", style: TextStyle(fontSize: 150, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900))),
            Positioned(bottom: 190 + drift(0.4), right: -14, child: Text("?", style: TextStyle(fontSize: 120, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900))),
            Positioned(top: size.height * 0.5, right: 30 + drift(0.7), child: Text("?", style: TextStyle(fontSize: 90, color: Colors.white.withValues(alpha: 0.04), fontWeight: FontWeight.w900))),
            Positioned(top: 130, right: 40, child: _Twinkle(controller: controller, phase: 0)),
            Positioned(top: size.height * 0.4, left: 36, child: _Twinkle(controller: controller, phase: 0.4, color: const Color(0xFFFFD86B))),
            Positioned(bottom: 150, right: 66, child: _Twinkle(controller: controller, phase: 0.75, color: const Color(0xFFA5F3FC))),
          ],
        );
      },
    );
  }
}

class _Twinkle extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  final Color color;
  const _Twinkle({required this.controller, required this.phase, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = (sin((controller.value + phase) * 2 * pi) + 1) / 2;
        return Opacity(
          opacity: 0.18 + v * 0.52,
          child: Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        );
      },
    );
  }
}

// ============================================================
// כניסה מדורגת (Fade + Slide) - זהה לזו שכבר קיימת ב-leaderboard_screen.dart.
// ============================================================
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  const _FadeSlideIn({required this.child, required this.index});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    final delay = Duration(milliseconds: 55 * widget.index.clamp(0, 10));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ============================================================
// "צ'יפ" קטן (אייקון+טקסט) לשימוש בכרטיסי מצבי המשחק ובכרטיס "בונוס יומי" -
// למשל "⚡ עולה 2 אנרגיה" / "🪙 +5".
// 🆕 מטבע/אנרגיה = אימוג'י (ראו app_icons.dart) - שאר האייקונים נשארים וקטוריים
// ============================================================
// ============================================================
// כרטיס מצב משחק בגריד הבית (דו-קרב/אתגר רנדומלי) - עוצב מחדש בדיוק
// לפי המוקאפ (מסך 01 · בית): כרטיס מלא-צבע (גרדיאנט אלכסוני), אייקון
// בריבוע לבן-שקוף בפינה העליונה, כותרת ותת-כותרת קצרה בתחתית. בלי מסגרת,
// בלי תג "חדש", בלי צ'יפ נוסף - בדיוק כמו שמופיע בעיצוב.

class _ModeCard extends StatelessWidget {
  final Widget icon;
  final List<Color> gradient;
  final String title;
  final String? note;
  final VoidCallback onTap;
  // 🆕 "כמה אנשים משחקים עכשיו" - null = עוד לא נטען (לא מציגים כלום),
  // אחרת מספר אמיתי (יכול להיות 0) - ראו presence_service.dart.
  final int? liveCount;
  // 🆕 גובה ניתן להתאמה - "שחק מול אחרים" מקבל כרטיס גבוה/רחב יותר
  // (150) עכשיו שהוא כרטיס-רוחב-מלא ומוביל לשני מודים, בעוד "אתגר
  // רנדומלי" נשאר בגובה הרגיל (136 כברירת מחדל).
  final double height;

  const _ModeCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.onTap,
    this.note,
    this.liveCount,
    this.height = 136,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            _buildCard(),
            // 🆕 נקודה ירוקה + מספר "משחקים עכשיו" - בדיוק בפינה השמאלית-
            // התחתונה של הכרטיס, לפי הבקשה המפורשת.
            if (liveCount != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ADE80))),
                      const SizedBox(width: 5),
                      Text('$liveCount', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
          // 🩹 תוקן: "אתגר רנדומלי נמצא על הלוגו של עצמו" / "דו קרב מופיע
          // חלק ממנו" - הבאג האמיתי: הכרטיס בנוי מ-Stack עם שני Positioned
          // נפרדים (אייקון מלמעלה, כותרת+תת-כותרת מהתחתית) בלי שום הגבלת
          // גובה על בלוק הטקסט - כשה-note ארוך (כמו "לוגו אקראי · שומר על
          // הרצף") הוא עלול "לגלוש" לשתי שורות ולצמוח כלפי מעלה עד שהוא
          // ממש חופף את ריבוע האייקון, כי Positioned לא חוסם/גוזר תוכן
          // שגדל מעבר לגודל שתוכנן. אחרי שגובה הכרטיס גם צומצם (158->120)
          // בעדכון הקודם, המרווח שנשאר היה קטן מדי וזה קרה בפועל. התיקון:
          // Column זורם רגיל (בלי Stack/Positioned) + maxLines/ellipsis על
          // הטקסטים כדי שלעולם לא יגדלו מעבר לשטח שהוקצה להם, וגובה מעט
          // גדול יותר (136 במקום 120) כדי שיהיה רווח נשימה אמיתי.
          // 🩹 זה היה הבאג האמיתי מאחורי "שחק מול אחרים קטן יותר מאתגר
          // רנדומלי ומופיע באמצע": ל-Container הזה לא היה width בכלל, אז
          // הוא התכווץ לפי רוחב התוכן שלו (Column) בלבד - וכיוון שהוא ילד
          // לא-Positioned בתוך Stack (שנותן לילדים שלו אילוצים רופפים/
          // loose, גם אם ל-Stack עצמו יש רוחב נוקשה מ-Expanded למעלה),
          // כרטיס עם טקסט ארוך יותר ("אתגר רנדומלי" + התת-כותרת הארוכה
          // "לוגו אקראי · שומר על הרצף") יצא רחב יותר בפועל מכרטיס עם
          // טקסט קצר ("שחק מול אחרים" + "דו־קרב · מירוץ") - למרות ששניהם
          // אמורים לתפוס בדיוק חצי-חצי. width: double.infinity מכריח את
          // ה-Container למלא את כל הרוחב שהוקצה לו (מה-Expanded), בלי
          // קשר לאורך הטקסט בפנים - קורה בכל מכשיר/פלטפורמה, לא קשור
          // לאייפון בכלל.
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          ),
          // 🩹 תוקן: הכותרת/תת-הכותרת "זזו שמאלה" - ה-Column הזה לא היה
          // עטוף ב-Directionality משלו, אז CrossAxisAlignment.start התיישר
          // לפי כיוון ברירת המחדל (LTR) של האפליקציה = שמאל, למרות
          // ש-textDirection: rtl בכל Text בפנים קובע רק את כיוון האותיות
          // עצמן ולא את יישור הבלוק כולו. CrossAxisAlignment.end מיישר את
          // כל הבלוק לימין (בלי קשר לכיוון האב), בדיוק כמו שצריך ב-RTL.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.28)),
                alignment: Alignment.center,
                child: icon,
              ),
              const Spacer(),
              Text(
                title,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
              ),
              if (note != null) ...[
                const SizedBox(height: 3),
                Text(
                  note!,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        );
  }
}