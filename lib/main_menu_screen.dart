//main_menu_screen
// 🎨 עוצב מחדש לפי מוקאפ ה-Home_Screen שסופק: רקע "אורורה" כהה-סגלגל
// עם רשת נקודות עדינה וסימני "?" צפים (אותה שפת עיצוב שכבר נבנתה ב-
// leaderboard_screen.dart), כרטיס לוגו מרחף, גריד סטטיסטיקות (XP/מטבעות/
// רצף), כפתור CTA בגרדיאנט זהב, וכרטיסי ניווט זכוכיתיים.
// ⚠️ בלי "דילוג שלב" בשום מקום - הפיצ'ר הזה לא קיים באפליקציה שלנו.
import 'dart:async';
import 'dart:ui'; // 🆕 ImageFilter.blur - אפקט הזכוכית של סרגל הניווט התחתון החדש (Home v7)
import 'achievements_service.dart';
import 'achievements_screen.dart'; // 🆕 לחיצה על "X/Y מדליות" בבועת הפרופיל פותחת את מסך ההישגים
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'levels_screen.dart';
import 'tafzoret_worlds_screen.dart';
import 'tafzoret_data.dart'; // 🆕 tafzoretWorlds.length - מספר עולמות אמיתי לכרטיס "תפזורת" בגיליון המודים
import 'tournament_lobby_screen.dart';
import 'tournament_service.dart'; // 🆕 checkAndClaimPendingPrize - תוצאת הטורניר היומי, נבדקת גם בכניסה הכללית לאפליקציה
import 'tournament_result_popup.dart'; // 🆕 הפופאפ המושקע "זכית!/הוחזר לך" - ראו _maybeShowTournamentResult
import 'scheduled_tournament_screen.dart'; // 🆕 "טורניר מתוזמן" - פורמט שני, בנוסף לטורניר היומי
import 'scheduled_tournament_service.dart'; // 🆕 checkAndClaimPendingPrize - אותה בדיקה גם לטורניר המתוזמן
import 'social_follow_popup.dart'; // 🆕 "עקבו אחרינו וקבלו מטבעות" - ראו _maybeShowSocialFollowPrompt
import 'level_loading_screen.dart';
import 'first_visit_explainer.dart'; // 🆕 FirstVisitExplainer.hasRealProgress - שחקן ותיק לא מקבל הדרכה
import 'audio_manager.dart';
import 'leaderboard.dart';
import 'leaderboard_screen.dart'; // 🆕 כפתור "טבלה" בסרגל התחתון החדש של מסך הבית
import 'shop_screen.dart'; // 🆕 כפתור "חנות" בסרגל התחתון החדש של מסך הבית
import 'device_id.dart';
import 'package:package_info_plus/package_info_plus.dart'; // 🆕 גרסה נוכחית - למסך "מה חדש" (ראו _checkWhatsNew)
import 'whats_new_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'missions_service.dart';
import 'missions_screen.dart'; // 🆕 כפתור "משימות" בשורה העליונה של מסך הבית - Home v7
import 'level_data.dart'; // 🆕 levelsCounts/gameLevels גלובליים - לחישוב התקדמות שלבים בכרטיס הבית
import 'energy_service.dart'; // 🆕 אנרגיה לדו-קרב - עכשיו מוצגת גם במסך הבית
import 'ads_manager.dart'; // 🆕 פרסומת מתוגמלת - לכרטיס בונוס המטבעות ולאתגר היומי
import 'notification_manager.dart'; // 🆕 תזכורת "הבונוס זמין שוב" - אותה מערכת בדיוק כמו בחנות
import 'notification_service.dart'; // 🆕 תזכורת יומית: משימות חדשות + אתגר יומי מחכה
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי
import 'meta_events_service.dart'; // 🆕 מעקב "הרשמה הושלמה" ל-Meta Ads
import 'analytics_service.dart'; // 📊 אותו מעקב ל-Firebase Analytics/Google Ads
import 'push_notification_service.dart'; // 🐛 שומר את ה-FCM token בפעם הראשונה שיש שם אמיתי
import 'daily_challenge_screen.dart'; // 🆕 קיצור דרך ישיר לאתגר היומי מהמסך הראשי
import 'starter_pack_service.dart'; // 🆕 מארז פתיחה - זכאות/וריאנט
import 'starter_pack_dialog.dart'; // 🆕 מארז פתיחה - דיאלוג ההצעה
import 'login_streak_service.dart'; // 🆕 רצף כניסה יומי - בונוס על כניסה יום אחרי יום
import 'battle_pass_service.dart'; // 🆕 באטל פאס עונתי - נקודות/שלבים/פרסים
import 'battle_pass_screen.dart'; // 🆕 באטל פאס עונתי - מסך הפרטים המלא
import 'settings_screen.dart'; // 🆕 הגדרות - עברו לאייקון גלגל-שיניים בבית (הוצא מסרגל הניווט התחתון)
import 'app_bottom_nav.dart'; // 🆕 מניו תחתון משותף - מוצג גם בגיליון "בחרו מוד" (ראו _buildModesSheetV7), לפי בקשה מפורשת
import 'account_link_prompt.dart'; // 🆕 דיאלוג "שמור את ההתקדמות שלך" - הצעה לקשר חשבון Google/Apple
import 'account_service.dart'; // 🆕 מסך "ברוכים הבאים" עכשיו מציע גם Google ולא רק שם+אורח - ראה _buildWelcomeChoiceScreen
import 'account_conflict_dialog.dart'; // 🆕 דיאלוג "מצאנו לך חשבון קיים" - ראה _handleGoogleWelcomeSignIn
import 'logo_race_screen.dart'; // 🆕 "מרוץ לוגואים" - מצב אונליין חדש, 1 על 1, מי שמנחש ראשון בכל לוגו מנצח
import 'play_vs_person_mode_screen.dart'; // 🆕 מסך רכזת "שחק מול אחרים" - בחירת מוד (דו-קרב/מירוץ), עוצב לפי מסך "04 · בחירת מוד"
import 'presence_service.dart'; // 🆕 "כמה אנשים משחקים עכשיו" - נקודה ירוקה+מספר על כרטיסי דו-קרב/מרוץ
import 'friend_service.dart'; // 🆕 כרטיסון "מחוברים" במסך הבית - עיצוב מחדש Home v7
import 'friends_screen.dart'; // 🆕 כפתור "חברים" בסרגל התחתון החדש של מסך הבית
import 'duel_lobby_screen.dart'; // 🆕 "דו-קרב"/"סדרת דו-קרב" - נגישים עכשיו ישירות מגיליון המודים
import 'player_sync.dart'; // 🩹 סנכרון לענן אחרי בונוס פרסומת - בלי זה שחקן שמקושר לחשבון Google/Apple לא רואה עדכון במכשיר אחר
import 'iap_manager.dart'; // 🆕 IapManager.tournamentBonusActive/Remaining - כרטיס "מבצע בחנות" האמיתי בגיליון "קורה עכשיו" (Home v7, וריאנט 1b)
import 'app_notification.dart';
import 'l10n/app_localizations.dart';

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
  // 🆕 מסך "מה חדש בגרסה" (whats_new_screen.dart) - מוצג פעם אחת בלבד
  // למשתמש *קיים* (לא חדש - הוא מקבל showWelcomeScreen במקום) בכניסה
  // הראשונה אחרי עדכון לגרסה שונה מהגרסה האחרונה שנשמרה. ראו _checkWhatsNew.
  bool showWhatsNewScreen = false;
  String _appVersion = '';
  // 🆕 מסך "ברוכים הבאים" עכשיו מציג קודם בחירה בין Google לאורח, ולא
  // ישר שדה שם - ראה _buildWelcomeChoiceScreen. false = מציגים את שתי
  // האפשרויות; true = עברנו לשדה השם (או כי נבחר "שחק כאורח", או כי
  // ההתחברות ל-Google הצליחה אבל לחשבון הזה עדיין אין שם שמור בענן).
  bool _welcomeShowingNameEntry = false;
  bool _welcomeGoogleLoading = false;
  bool _welcomeAppleLoading = false;

  // 🆕 הדרכה ראשונית (onboarding) - מוצגת פעם אחת בלבד, רק למשתמש *חדש*
  // לגמרי (מיד אחרי _saveWelcomeName, לא בכניסה הקרה הרגילה - בדיוק אותה
  // קונבנציה כמו showWelcomeScreen/showWhatsNewScreen). סיור קצר (3
  // טיפים) מעל מסך הבית, ואז (בסיום ההדרכה בתוך המשחק עצמו, ראו
  // logo_level_screen.dart._maybeGrantFirstLevelGift) פופאפ פרס - ראו
  // onboarding_gift_popup.dart. אין מסך "מתנת פתיחה" נפרד בהתחלה -
  // showHomeTour מופעל ישר.
  // יש כפתור "דלג" בכל שלב (ראו _buildHomeTourOverlayV5) - לפי בקשה מפורשת.
  bool showHomeTour = false;
  // 🆕 אנימציית לחיצה (כיווץ קל) לכפתור "שחק" המרכזי - לפי בקשה מפורשת
  // ("תעשה אנימציה שלוחצים").
  bool _playButtonPressed = false;
  int _tourStep = 0;
  // 🩹 תוקן לפי בקשה מפורשת: "זה אומר לו ללחוץ על השחק ואז זה לא אומר
  // לו ללחוץ על השלבים" - הסיור חזר לשני שלבים: (0) כפתור "שחק" המרכזי
  // כאן במסך הבית, (1) כרטיס "שלבים" בתוך גיליון המודים שנפתח ממנו
  // (ראו _buildModesSheetV7/_tourLevelsCardKey) - כדי שהשחקן לא "ייתקע"
  // בגיליון בלי שום הנחיה על מה ללחוץ בפועל כדי להתחיל לשחק.
  static const int _tourStepCount = 2;
  final GlobalKey _tourPlayButtonKey = GlobalKey();
  final GlobalKey _tourLevelsCardKey = GlobalKey();
  // 🆕 לפי דיווח מפורש: "לא היה הסבר ראשוני שקודם אומר ברוכים הבאים
  // לאפליקציה... היא המדריך" - הסיור קפץ ישר לספוטלייט הראשון בלי שום
  // "ברוכים הבאים, הנה סיור קצר" כללי קודם. כרטיסיה ממורכזת אחת, לא
  // קשורה לרכיב ספציפי, מוצגת לפני שהספוטלייט (_buildHomeTourOverlayV5)
  // מתחיל בכלל.
  bool _tourWelcomeDismissed = false;
  // 🩹 השם ש"ימולא מראש" בשדה השם במסך הבחירה הראשוני - ריק אם נבחר
  // "שחק כאורח", או השם שכבר שמור בענן אם ההתחברות ל-Google שחזרה שם
  // קיים (כדי שהשחקן עדיין יאשר/יוכל לשנות אותו, ולא ידלג ישר הביתה -
  // לפי בקשה מפורשת: גם אחרי אורח וגם אחרי Google תמיד לשאול שם).
  String _welcomeInitialName = "";

  // סטטיסטיקות לכרטיסי הבית - נטענות מ-SharedPreferences (אותם מפתחות
  // בדיוק שנמצאים בשימוש ב-logo_level_screen.dart / shop_screen.dart).
  int coins = 15;
  int xp = 0;
  int _medalsEarned =
      0; // 🆕 מדליות שהושגו - מוצג במקום XP בכרטיס הפרופיל (ראו AchievementsService)
  int streak = 0;
  int maxLevel = 1;
  int _missionsUnclaimed =
      0; // 🆕 כמה פרסים ממתינים לאיסוף במסך המשימות - לתג על הכרטיס

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
  int?
  _superdualPlayersNow; // 🆕 מוד presence נפרד ל"סדרת דו-קרב" - ראו duel_lobby_screen.dart
  Timer? _presenceTimer;
  static const Duration _presenceRefreshInterval = Duration(seconds: 30);

  // 🆕 עיצוב מחדש "Home v7" - באנר הטורניר היומי במסך הבית: קופה/משתתפים
  // אמיתיים (אותם חישובים בדיוק כמו tournament_lobby_screen.dart -
  // currentPoolEstimate + fetchLeaderboard), בלי מצב "הצטרפתם/שיחקתם" -
  // זו רק "ויטרינה" שמובילה למסך הטורניר המלא, לא כפתור הרשמה ישיר.
  List<TournamentEntry> _tournamentTop = [];

  // 🆕 כל החברים (לא רק מחוברים) - לתא "חברים" בתלתן של מסך הבית
  // (friend_service.dart, אותו מקור נתונים בדיוק כמו friends_screen.dart).
  List<FriendInfo> _friends = [];

  // 🆕 "בונוס פעיל!" בתא "חנות" בתלתן - חלון הבונוס האמיתי של פי 1.25
  // מטבעות אחרי ניצחון בטורניר (IapManager.activateTournamentBonus), לא
  // הנחה כללית מזויפת שתמיד פעילה כמו במוקאפ.
  bool _tournamentBonusActive = false;
  // 🆕 "אותו דבר עם הטורנירים" - תג זהוב על אריח הטורנירים כשהצטרפתם
  // לאתגר אבל עדיין לא שיחקתם את השלב של היום, כדי שלא תשכחו לחזור
  // (אותו עיקרון בדיוק כמו תג ההנחה בחנות - "יש כאן משהו שמחכה לך").
  bool _tournamentActionAvailable = false;

  // 🆕 עיצוב מחדש "Home v10" - רצף הכניסה היומי האמיתי (LoginStreakService,
  // אותו מקור בדיוק כמו _showLoginStreakDialog/_showDailyGiftsDialog) -
  // מוצג עכשיו ליד השם בשורה העליונה ("🔥 X"), לא רק בתוך הדיאלוג.
  int _loginStreakDays = 0;

  // 🆕 כמה מהמשימות היומיות הפעילות כבר הושלמו (לא רק "מוכנות לאיסוף" -
  // ראו _missionsUnclaimed) - "{completed}/{total}" בתת-הכותרת של תא
  // "משימות" בתלתן, במקום פס התקדמות גנרי בלי שום מספר/הקשר.
  int _missionsCompletedCount = 0;
  int _missionsTotalCount = 0;

  @override
  void initState() {
    super.initState();
    // 🩹 לפי בקשה מפורשת: "אם הבנאדם כבר שיחק במשחק ועכשיו עושה עדכון...
    // שלא יהיה לו מדריך" - הגירה חד-פעמית (רצה פעם אחת בדיוק אי-פעם לכל
    // התקנה, לא בכל פתיחה) - ראו FirstVisitExplainer.migrateExistingPlayersOnce.
    // נקרא כבר כאן, מוקדם ככל האפשר, לפני שכל מסך אחר מספיק לבדוק
    // FirstVisitExplainer.shouldShow בעצמו.
    FirstVisitExplainer.migrateExistingPlayersOnce();
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
      // 🆕 "מתאפס בעוד" בבאנר הטורניר - מחושב מול השעון האמיתי בכל
      // טיק (לא נספר למטה בפני עצמו), אותו עיקרון כמו tournament_lobby_screen.dart.
      if (mounted) setState(() {});
    });
    MainMenuScreen.onReturnedHome = () => _refreshStats();
    // 🆕 בכל פתיחה/כניסה למסך הבית - מתזמנים מחדש את תזכורת "משימות
    // חדשות + אתגר יומי מחכה" קדימה לאיפוס הבא (חצות). ככה שחקן פעיל
    // תמיד מקבל אותה רק אחרי שהוא נעדר לפחות יום אחד, בדיוק כמו תזכורות
    // "חזרה למשחק" ב-main.dart.
    // 🆕 מגודר לפי מתג "תזכורות יומיות" בטאב ההתראות - ראו notification_manager.dart.
    if (NotificationManager.notificationsEnabled && NotificationManager.dailyNotificationsEnabled) {
      NotificationService.scheduleDailyResetReminder();
    }
    _refreshPresenceCounts();
    AchievementsService.recordActiveDay(); // 🆕 הישגים - ימי משחק
    _refreshMedals();
    _presenceTimer = Timer.periodic(
      _presenceRefreshInterval,
      (_) => _refreshPresenceCounts(),
    );
    _refreshTournamentHero();
    _refreshFriends();
    _refreshTournamentBonus();
    _refreshTournamentActionAvailable();
    _refreshLoginStreakDays();
    _refreshMissionsProgress();
  }

  // 🕐 זמן שנותר עד סוף האתגר הרב-יומי הנוכחי - אותו חישוב בדיוק כמו
  // tournament_lobby_screen.dart._timeUntilReset (TournamentService.eventEndTime),
  // מחושב מחדש מול השעון האמיתי בכל build (לא "נספר" עצמאית).
  Duration get _tournamentTimeUntilReset {
    final diff = TournamentService.eventEndTime().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // 🆕 נתוני "ויטרינה" לבאנר האתגר הרב-יומי במסך הבית - אותם חישובים
  // בדיוק כמו tournament_lobby_screen.dart (currentPoolEstimate על בסיס
  // כמות השחקנים שכבר בטבלה המצטברת של האירוע הנוכחי). כשלון שקט (רשימה
  // ריקה) - הבאנר פשוט מציג "0 משתתפים", לא קורס.
  Future<void> _refreshTournamentHero() async {
    final board = await TournamentService.fetchLeaderboard(
      TournamentService.eventId(),
    );
    if (!mounted) return;
    setState(() => _tournamentTop = board);
  }

  // 🆕 כל החברים - לשורת ה"סטוריז" במסך הבית. אותו מקור בדיוק כמו
  // friends_screen.dart (FriendService.fetchFriends).
  Future<void> _refreshFriends() async {
    final all = await FriendService.fetchFriends();
    if (!mounted) return;
    setState(() => _friends = all);
  }

  // 🆕 עיצוב מחדש "Home v10" - רצף הכניסה היומי האמיתי (LoginStreakService,
  // אותו מקור בדיוק כמו _checkLoginStreak/_showDailyGiftsDialog) - מוצג
  // עכשיו ליד השם בשורה העליונה.
  Future<void> _refreshLoginStreakDays() async {
    final days = await LoginStreakService.getCurrentStreak();
    if (!mounted) return;
    setState(() => _loginStreakDays = days);
  }

  // 🆕 כמה מהמשימות היומיות הפעילות כבר הושלמו (לא רק "כמה מוכנות
  // לאיסוף") - "{completed}/{total}" בתת-הכותרת של תא "משימות" בתלתן.
  Future<void> _refreshMissionsProgress() async {
    final daily = await MissionsService.getDailyMissions();
    if (!mounted) return;
    final completed = daily.where((m) => m.isComplete).length;
    setState(() {
      _missionsCompletedCount = completed;
      _missionsTotalCount = daily.length;
    });
  }

  // 🆕 חלון בונוס "פי 1.25 מטבעות" האמיתי (IapManager, מופעל אחרי ניצחון
  // בטורניר) - לתא "חנות" בתלתן. מתעדכן שוב בכל _refreshStats (למשל אחרי
  // שהתקבל פרס טורניר חדש, ראו _maybeShowTournamentResult).
  Future<void> _refreshTournamentBonus() async {
    final active = await IapManager.tournamentBonusActive();
    if (!mounted) return;
    setState(() => _tournamentBonusActive = active);
  }

  // 🆕 ראו ההערה ליד _tournamentActionAvailable - פעיל רק אם הצטרפתם
  // לאתגר הנוכחי ועוד לא שיחקתם את השלב של היום.
  Future<void> _refreshTournamentActionAvailable() async {
    final joined = await TournamentService.hasJoinedEvent();
    if (!joined) {
      if (mounted) setState(() => _tournamentActionAvailable = false);
      return;
    }
    final playedToday = await TournamentService.hasPlayedToday();
    if (!mounted) return;
    setState(() => _tournamentActionAvailable = !playedToday);
  }

  // 🆕 שאילתות .count() חד-פעמיות (לא לייב) - ראו presence_service.dart
  // להסבר המלא למה זה זול (קריאה בודדת לכל שאילתה, לא תלוי בכמות
  // המסמכים). כשלון שקט (מחזיר 0) לא אמור להפריע לשום דבר אחר במסך.
  Future<void> _refreshPresenceCounts() async {
    final results = await Future.wait([
      PresenceService.countActive('duel'),
      PresenceService.countActive('race'),
      PresenceService.countActive('superdual'),
    ]);
    if (!mounted) return;
    setState(() {
      _duelPlayersNow = results[0];
      _racePlayersNow = results[1];
      _superdualPlayersNow = results[2];
    });
  }

  @override
  void dispose() {
    _energyTickTimer?.cancel();
    _presenceTimer?.cancel();
    if (MainMenuScreen.onReturnedHome != null)
      MainMenuScreen.onReturnedHome = null;
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
    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastMillis),
    );
    setState(() {
      _adBonusAvailable = elapsed >= _adBonusCooldown;
      _adBonusRemaining = _adBonusAvailable
          ? Duration.zero
          : _adBonusCooldown - elapsed;
    });
  }

  // 🎬 צפייה בפרסומת מתוגמלת -> +15 מטבעות, פעם כל 3 שעות - זהה ל-
  // shop_screen.dart._watchDailyAd בדיוק (אותו מפתח, אותה תזכורת).
  Future<void> _collectAdBonus() async {
    if (!_adBonusAvailable || _collectingAdBonus) return;
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(
        context,
        AppLocalizations.of(context)!.duelLobbyNoAdAvailable,
        type: AppNotificationType.warning,
      );
      return;
    }
    setState(() => _collectingAdBonus = true);
    AdsManager.showRewardedAd(
      onReward: () async {
        final prefs = await SharedPreferences.getInstance();
        final newCoins = (prefs.getInt('coins') ?? 15) + 15;
        await prefs.setInt('coins', newCoins);
        PlayerSyncService.syncCurrentProgress(); // 🩹 בלי זה בונוס הפרסומת לא מסתנכרן לחשבון Google/Apple מקושר
        await prefs.setInt(
          'lastAdBonusMillis',
          DateTime.now().millisecondsSinceEpoch,
        );
        NotificationManager.scheduleFreeCoinsReminder();
        if (!mounted) return;
        setState(() {
          coins = newCoins;
          _collectingAdBonus = false;
        });
        await _refreshAdBonusState();
        if (mounted)
          _showRewardDialog(
            AppLocalizations.of(context)!.mainMenuCollected15Coins,
          ); // 🩹 הוסר אימוג'י המטבע - לא נתמך בפונט של חלק מהמכשירים ומוצג כריבוע ריק
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _adBonusAvailable)
        setState(() => _collectingAdBonus = false);
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            ),
            child: Text(
              AppLocalizations.of(context)!.mainMenuCloseButton,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyChallengeScreen()),
    );
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
    final loc = AppLocalizations.of(context)!;
    switch (worldNum) {
      case 1:
        return loc.worldName1;
      case 2:
        return loc.worldName2;
      case 3:
        return loc.worldName3;
      case 4:
        return loc.worldName4;
      case 5:
        return loc.worldName5;
      case 6:
        return loc.worldName6;
      case 7:
        return loc.worldName7;
      case 8:
        return loc.worldName8;
      case 9:
        return loc.worldName9;
      case 10:
        return loc.worldName10;
      case 11:
        return loc.worldName11;
      case 12:
        return loc.worldName12;
      case 13:
        return loc.worldName13;
      case 14:
        return loc.worldName14;
      case 15:
        return loc.worldName15;
      case 16:
        return loc.worldName16;
      case 17:
        return loc.worldName17;
      case 18:
        return loc.worldName18;
      case 22:
        return loc.worldName22;
      default:
        return loc.worldNameDefault;
    }
  }

  Future<void> _startSplashScreen() async {
    // 🩹 הוסרה השהיה מלאכותית של 3 שניות + מסך "ברוך הבא למשחק!" הכפול
    // שהיה כאן (לוגו ענק + טקסט "ברוך הבא" שהופיע תמיד, גם לשחקן קיים
    // עם שם שמור) - לפי בקשה מפורשת: מסך הטעינה האמיתי כבר קורה לפני
    // MainMenuScreen בכלל (AppLoadingScreen ב-main.dart, עם התקדמות
    // אמיתית), אז מסך "טעינה" שני כאן היה מיותר ומטעה. עכשיו רק ממתינים
    // לטעינת הנתונים האמיתית (prefs/סטטיסטיקות) בלי שום מסך ענק מעליה.
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
      // 🆕 מסך "מה חדש בגרסה" - רק למשתמש קיים (יש לו שם שמור), פעם אחת
      // בלבד לכל גרסה. אם מוצג - דוחים את רצף הכניסה היומי עד שהמשתמש
      // סוגר אותו (ראו _dismissWhatsNew), כדי לא לערום כמה דיאלוגים/מסכים
      // זה על זה בכניסה אחת.
      final shouldShowWhatsNew = await _checkWhatsNew();
      if (shouldShowWhatsNew) {
        if (!mounted) return;
        setState(() => showWhatsNewScreen = true);
      } else {
        // 🆕 רצף כניסה יומי - בכוונה כן בכניסה הקרה (בניגוד למארז הפתיחה
        // למעלה) - זה בדיוק הרעיון: "נכנסת היום? הנה בונוס". רק למשתמש
        // קיים עם שם שמור (לא למי שרק עכשיו יוצר פרופיל).
        _checkLoginStreak();
      }
    }
  }

  // 🆕 בודק אם הגרסה הנוכחית שונה מהגרסה האחרונה שהמשתמש כבר ראה לגביה
  // את מסך "מה חדש" - אם כן, מעדכן מיד את הגרסה השמורה (כדי שלא יוצג
  // שוב גם אם המסך נסגר בלי שהמשתמש הגיע לכפתור, או בכניסה הבאה) ומחזיר
  // true. כשל שקט (אין רשת/שגיאה) = לא מציגים, בטוח יותר מלהציג כל פעם.
  Future<bool> _checkWhatsNew() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      final prefs = await SharedPreferences.getInstance();
      // 🩹 lastSeen == null מטופל כ"שונה" (מציגים) ולא כ"לא מציגים" - כי
      // הפונקציה הזו נקראת רק למשתמש *קיים* עם שם שמור (ראו _startSplashScreen),
      // אז אם אין עדיין ערך שמור זה אומר שזו הפעם הראשונה שהתכונה הזו
      // בכלל קיימת אצלו - בדיוק המקרה שרוצים להראות לו "מה חדש" (לתפוס
      // אותו על כל מה שהוא פספס). משתמש *חדש* לגמרי מקבל את הערך מיד
      // ב-_saveWelcomeName, ולכן לעולם לא מגיע לכאן עם lastSeen null.
      final lastSeen = prefs.getString('lastSeenWhatsNewVersion');
      final changed = lastSeen != info.version;
      await prefs.setString('lastSeenWhatsNewVersion', info.version);
      return changed;
    } catch (_) {
      return false;
    }
  }

  // 🆕 נקרא כש"בואו נתחיל" נלחץ במסך "מה חדש" - סוגר אותו וממשיך בדיוק
  // לאותה זרימה שהייתה קורית אם המסך הזה לא היה קיים בכלל (רצף כניסה).
  void _dismissWhatsNew() {
    setState(() => showWhatsNewScreen = false);
    _checkLoginStreak();
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
    _readStats(
      await SharedPreferences.getInstance(),
    ); // המטבעות/אנרגיה כבר התעדכנו - מרעננים את התצוגה
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
    // 🆕 רק אחרי שדיאלוג קישור החשבון נסגר - כדי לא להציג שני דיאלוגים
    // בו-זמנית, בדיוק כמו שאר השרשרת הזו.
    _maybeShowTournamentResult();
  }

  // 🆕 "יום אחריי בכללי אחריי הטורניר... הודעה שהוא נכנס למשחק משהו יפה
  // ומושקע" - בודקים את תוצאת הטורניר היומי (פרס מיקום/החזר על מעט
  // משתתפים) בכל כניסה כללית לאפליקציה, לא רק כשנכנסים ידנית למסך
  // הלובי (tournament_lobby_screen.dart עושה את אותה בדיקה בעצמו -
  // TournamentService.checkAndClaimPendingPrize שומר דגל "claimed" לכל
  // periodId, אז אין סכנה שהפרס יינתן פעמיים גם אם שתי הבדיקות רצות
  // קרוב אחת לשנייה).
  Future<void> _maybeShowTournamentResult() async {
    final prize = await TournamentService.checkAndClaimPendingPrize();
    if (prize != null && mounted) {
      await showTournamentResultPopup(context, prize);
    }
    // 🆕 אותה בדיקה גם לטורניר המתוזמן (ראו scheduled_tournament_service.dart) -
    // ברצף (await, לא בו-זמנית) כדי שלעולם לא יוצגו שני פופאפי "זכית!"
    // ביחד, בדיוק כמו שאר שרשרת הפופאפים במסך הזה.
    final scheduledPrize =
        await ScheduledTournamentService.checkAndClaimPendingPrize();
    if (scheduledPrize != null && mounted) {
      await showTournamentResultPopup(
        context,
        scheduledPrize,
        label: 'הטורניר המתוזמן',
      );
    }
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
            gradient: const LinearGradient(
              colors: [Color(0xFF3A2A6B), Color(0xFF1D0E3C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFD86B).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9A3C).withValues(alpha: 0.4),
                      blurRadius: 22,
                    ),
                  ],
                ),
                // 🩹 תוקן: היה אימוג'י (🎁) - אותה בעיית תאימות מתועדת כמו
                // אימוג'י המטבע/אנרגיה (ראו app_icons.dart).
                child: const Center(
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFF2A1740),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(
                  context,
                )!.mainMenuStreakDayTitle(result.streakDay),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.mainMenuComeBackTomorrow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              // 🩹 שורת עיגולים במקום שורת הפילים הישנה - ראו הערה למעלה.
              // הדיאלוג הזה נפתח *אחרי* שהיום כבר נאסף בפועל (checkInIfNewDay
              // הצליח) - ולכן claimedToday תמיד true כאן.
              _buildStreakDayRow(
                dayInCycle: result.dayInCycle,
                claimedToday: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (result.energy > 0) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1E2A5A),
                          border: Border.all(
                            color: const Color(
                              0xFF7DD3FC,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '+${result.energy}',
                              style: const TextStyle(
                                color: Color(0xFF7DD3FC),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // 🩹 אייקון וקטורי (EnergyIcon) במקום אימוג'י ⚡ - ראו app_icons.dart.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.mainMenuEnergyLabel,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                        border: Border.all(
                          color: const Color(0xFFFFC64B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '+${result.coins}',
                            style: const TextStyle(
                              color: Color(0xFFFFD86B),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // 🩹 אייקון וקטורי (CoinIcon) במקום אימוג'י 🪙 - ראו app_icons.dart.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.mainMenuCoinsLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.mainMenuCollectButton,
                            style: const TextStyle(
                              color: Color(0xFF2A1740),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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
    _refreshMedals();
    _refreshTournamentHero();
    _refreshFriends();
    _refreshTournamentBonus();
    _refreshTournamentActionAvailable();
    _refreshLoginStreakDays();
    _refreshMissionsProgress();
    // 🩹 "פרס סיום הדרכה" עבר להיות מוצג ישירות בתוך logo_level_screen.dart
    // ברגע שההדרכה-בתוך-המשחק מסתיימת (לא יותר נדחה לחזרה הביתה) - ראו
    // _maybeGrantFirstLevelGift שם. מארז הפתיחה נבדק כאן כרגיל.
    _maybeShowStarterPack();
  }

  // 🆕 טוען את מצב "באטל פאס" הנוכחי (נקודות/שלב פתוח/פרסים ממתינים)
  // כדי להציג אותם בתמצית על הכרטיס בתפריט הראשי - הפרטים המלאים
  // (רשימת השלבים, תביעת פרסים) נמצאים במסך הייעודי BattlePassScreen.
  // 🆕 "במקום XP שיוצר תחושת נחיתות לשחקן חדש מול ותיקים" - כרטיס הפרופיל
  // מציג כמה מדליות/הישגים כבר הושגו (ראו AchievementsService) - כל שחקן
  // מתחיל מ-0/15 ורואה יעדים קרובים, לא מספר ענק של מישהו אחר.
  Future<void> _refreshMedals() async {
    final count = await AchievementsService.earnedCount();
    if (!mounted) return;
    setState(() => _medalsEarned = count);
  }

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
    if (prefs.getBool('starterPackAutoShown') ?? false) {
      _maybeShowSocialFollowPrompt();
      return;
    }
    final variant = await StarterPackService.variantToShow(maxLevel: maxLevel);
    if (variant == null || !mounted) {
      _maybeShowSocialFollowPrompt();
      return;
    }
    await prefs.setBool('starterPackAutoShown', true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StarterPackDialog.show(context, variant);
    });
    // 🩹 מארז הפתיחה כן מוצג הפעם - לא מציעים גם עקיבה באותו רגע (ראו
    // הערה למעלה ב-_maybeShowSocialFollowPrompt), היא תוצע בחזרה הבאה
    // ממשחק אחרי שדגל מארז הפתיחה כבר "נשרף".
  }

  // 🆕 "משהו שיגרום לאנשים לעקוב באינסטגרם ובטיקטוק" - פופאפ חד-פעמי
  // שמוצע כש-_refreshStats רץ (כלומר אחרי שהשחקן כבר חזר ממשחק אחד
  // לפחות, לא מיד בפתיחה הראשונה של האפליקציה - אותו עיקרון תזמון כמו
  // מארז הפתיחה למעלה). "פעם אחת בלבד" נשמר בדגל נפרד
  // (socialFollowPromptShown) - ראו social_follow_popup.dart לדגל
  // הנפרד שמסמן אם המטבעות כבר נתבעו בפועל.
  Future<void> _maybeShowSocialFollowPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('socialFollowPromptShown') ?? false) return;
    await prefs.setBool('socialFollowPromptShown', true);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showSocialFollowPopup(context);
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
    // 🐛 תוקן: "ישר אחרי שרושמים שם מתחיל ההסבר, בגלל המקלדת שנמצאת למטה
    // הסימון מופיע במקום אחר" - המקלדת עדיין הייתה פתוחה (או באמצע אנימציית
    // סגירה) כשהסיור חושב את מיקום הספוטלייט, אז ה-Rect שחושב לא תאם את
    // המיקום הסופי האמיתי של הכרטיסים (אחרי שהמקלדת נסגרת ומפנה מקום).
    // מבטלים פוקוס *כבר כאן*, לפני כל ה-await-ים הבאים, כדי שאנימציית סגירת
    // המקלדת תתחיל מוקדם כל כך שעד שמסך הבית עולה היא כבר הסתיימה.
    FocusManager.instance.primaryFocus?.unfocus();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    // 🆕 משתמש חדש לגמרי "מתחיל" כבר עם כל התוכן הנוכחי - אין לו שום דבר
    // "חדש" לפספס, אז מסך "מה חדש" לעולם לא אמור להופיע לו. מסמנים את
    // הגרסה הנוכחית כ"כבר נראתה" מיד כאן.
    try {
      final info = await PackageInfo.fromPlatform();
      await prefs.setString('lastSeenWhatsNewVersion', info.version);
    } catch (_) {}
    // 🆕 איתות "הרשמה הושלמה" ל-Meta (ראו meta_events_service.dart) -
    // נקרא פעם אחת בדיוק כשמשתמש חדש שומר שם לראשונה, לא בכל פתיחה.
    MetaEventsService.logCompletedRegistration();
    AnalyticsService.logCompletedRegistration(); // 📊 אותו איתות גם ל-Firebase Analytics/Google Ads
    // 🐛 תוקן: PushNotificationService.init() ב-main() רץ לפני שהיה שם -
    // הטוקן לא נשמר אז בכוונה (ראו ההערה שם) כדי לא ליצור מסמך players
    // "רפאים". עכשיו שיש שם אמיתי לראשונה, שומרים את הטוקן בפועל.
    PushNotificationService.retrySaveTokenIfNeeded();
    // 🆕 מסמנים שההדרכה "כבר נראתה" מיד כאן (אותו דפוס בדיוק כמו
    // lastSeenWhatsNewVersion למעלה) - כדי שגם אם המשתמש סוגר את
    // האפליקציה באמצע ההדרכה, היא לא תחזור שוב בכניסה הבאה.
    await prefs.setBool('hasSeenOnboarding', true);
    // 🆕 לפי בקשה מפורשת: "לפני שהם מקבלים את המתנה לא יהיה להם מטבעות
    // וזה" - מאפסים את המטבעות של משתמש חדש לגמרי ל-0 (היו מתחילים עם
    // ברירת מחדל - 15 מטבעות). מתנת סיום ההדרכה (50 מטבעות) היא המקור
    // האמיתי הראשון למטבעות שלהם.
    await prefs.setInt('coins', 0);
    // 🩹 תוקן לפי בקשה מפורשת: "תוריד את העניין שהם מקבלים מתנה 5
    // אנרגיה, אני רוצה שיהיה להם 8 אנרגיה פול כשהם נכנסים למשחק" - בוטל
    // ה-resetToZero שהיה כאן; EnergyService.getCurrentEnergy() כבר
    // מתחיל מ-maxEnergy כברירת מחדל כש-duelEnergy עוד לא קיים ב-prefs
    // בכלל, אז אין צורך לאפס דבר - שחקן חדש מתחיל מלא אוטומטית.
    // 🩹 תוקן: "אני לא מקבל את הפרס שאני אמור לקבל" - הפרס היה תלוי
    // בדגל _isOnboardingLevel בתוך logo_level_screen.dart, שהוא *אותו*
    // דגל שקובע אם ספוטלייט ההדרכה מוצג - אם משום מה הספוטלייט לא
    // מוצג (seenExplainer_soloLevel כבר true מהתקנה/בדיקה קודמת על
    // אותו מכשיר), השחקן לא קיבל גם את הפרס, ונשאר תקוע עם 0
    // מטבעות/אנרגיה לנצח. דגל נפרד ועצמאי לגמרי - נבדק רק מול "האם
    // שחקן חדש ענה נכון בפעם הראשונה אי-פעם", בלי שום תלות בתצוגת
    // הספוטלייט.
    await prefs.setBool('pendingFirstLevelGift', true);
    // 🩹 תוקן לפי בקשה מפורשת: "תעשה שהיא תופיע בכל משתמש חדש" - עד
    // עכשיו ההדרכות (seenExplainer_*) היו "פעם אחת לכל התקנה", לא "פעם
    // אחת לכל שם" - מישהו ש"ממלא שם חדש" על אותה התקנה (בלי למחוק
    // ולהתקין מחדש בפועל) לא היה רואה אותן שוב, מה שנראה כמו תקלה
    // אקראית. עכשיו כל מעבר דרך מסך "ברוכים הבאים!" (גם עם שם חדש על
    // התקנה קיימת) מאפס את כל ההדרכות, כך שהחוויה המלאה חוזרת מההתחלה
    // בכל פעם שממלאים שם - עקבי וצפוי, לא תלוי בהיסטוריה נסתרת של המכשיר.
    for (final key in [
      'missions',
      'friends',
      'leaderboard',
      'soloLevel',
      'playVsPerson',
      'levels',
      'subLevels',
    ]) {
      await prefs.remove('seenExplainer_$key');
    }
    if (!mounted) return;
    setState(() {
      username = name;
      coins = 0;
      _energy = EnergyService.maxEnergy;
      showWelcomeScreen = false;
      showHomeTour = true;
      _tourStep = 0;
      _tourWelcomeDismissed = false;
    });
  }

  void _skipOnboarding() {
    AudioManager.playClick();
    setState(() => showHomeTour = false);
  }

  // 🐛 תוקן: "הכפתור המואר היה למטה, בפועל מואר כפתור אחר" - מסך הבית
  // גולל (SingleChildScrollView), ו"מול אחרים"/"רנדומלי" יכולים להיות
  // מחוץ לתצוגה (מתחת לקצה הנראה) כשהסיור מגיע אליהם, בעיקר במסכים
  // נמוכים. בלי לגלול אליהם קודם, חישוב ה-Rect (RenderBox.localToGlobal)
  // עדיין מחזיר מיקום אמיתי - אבל מחוץ לחלק הנראה של המסך, כך שה"חור"
  // בספוטלייט לא תאם שום דבר שרואים בפועל, ובטעות "האיר" כרגע מה שבאמת
  // יושב שם על המסך הגלוי (כרטיס אחר לגמרי). עכשיו גוללים את הרכיב
  // האמיתי לתצוגה (Scrollable.ensureVisible) *לפני* שמציגים את הספוטלייט
  // עליו, וממתינים לסיום האנימציה לפני שמחשבים/מציירים את החור.
  // 🩹 פושט: הצעד היחיד שנותר (_tourPlayButtonKey) מצביע על כפתור "שחק"
  // שיושב בסרגל ניווט תחתון קבוע (Positioned, לא בתוך ה-SingleChildScrollView)
  // - הוא תמיד נראה על המסך, אז אין עוד צורך ב-Scrollable.ensureVisible
  // (שהיה נחוץ רק כשהמטרה הייתה כרטיס בתוך האזור הגולל). עדיין מחכים
  // שהמקלדת תיסגר בפועל (ראו ההערה ההיסטורית למטה) לפני שמציירים את
  // הספוטלייט, כדי שה-Rect שמחושב יתאים למסך הסופי.
  Future<void> _ensureTourStepVisible() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    var waited = 0;
    while (mounted &&
        MediaQuery.of(context).viewInsets.bottom > 0 &&
        waited < 500) {
      await Future.delayed(const Duration(milliseconds: 50));
      waited += 50;
    }
    if (mounted) setState(() {});
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
          AppNotification.show(
            context,
            AppLocalizations.of(context)!.mainMenuSignInFailed,
            type: AppNotificationType.error,
          );
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
        AppNotification.show(
          context,
          AppLocalizations.of(context)!.mainMenuGoogleSignInFailed,
          type: AppNotificationType.error,
        );
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
          AppNotification.show(
            context,
            AppLocalizations.of(context)!.mainMenuSignInFailed,
            type: AppNotificationType.error,
          );
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
        AppNotification.show(
          context,
          AppLocalizations.of(context)!.mainMenuAppleSignInFailed,
          type: AppNotificationType.error,
        );
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFBE50).withValues(alpha: 0.35),
                    const Color(0xFFFFBE50).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text("👋", style: TextStyle(fontSize: 28)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context)!.mainMenuWelcomeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.mainMenuWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
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
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF2A1740),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4285F4),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "G",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.accountLinkContinueWithGoogle,
                            style: const TextStyle(
                              color: Color(0xFF2A1740),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
                  ),
                ),
                child: Center(
                  child: _welcomeAppleLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.apple_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.accountLinkContinueWithApple,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.mainMenuPlayAsGuest,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 4),
        Text(
          AppLocalizations.of(context)!.mainMenuTermsNotice,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // 🩹 תוקן שוב לפי בקשה מפורשת ("עוד הפעם מופיעה עוד טעינה אחרי
      // המסך טעינה") - גם ספינר באמצע המסך נקרא כ"מסך טעינה נוסף" בעין,
      // למרות שהרקע (_AuroraBackground) כבר כמעט זהה לרקע app_loading_screen.dart.
      // בלי שום אלמנט חדש על המסך (לא ספינר, לא לוגו) - אם השלב הזה אכן
      // קצר (קריאת SharedPreferences בלבד), הוא עובר כפריים חולף של אותו
      // רקע בדיוק, לא נתפס כמסך נפרד.
      return const Scaffold(
        backgroundColor: Color(0xFF120C2E),
        body: SizedBox.expand(child: _AuroraBackground()),
      );
    }

    // 🆕 מסך "מה חדש בגרסה" - ראו _checkWhatsNew/_dismissWhatsNew. מוצג
    // רק פעם אחת למשתמש קיים אחרי עדכון, לפני תוכן הבית הרגיל.
    if (showWhatsNewScreen) {
      return WhatsNewScreen(version: _appVersion, onContinue: _dismissWhatsNew);
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
                            title: AppLocalizations.of(
                              context,
                            )!.mainMenuWelcomeTitle,
                            subtitle: AppLocalizations.of(
                              context,
                            )!.mainMenuNameEntrySubtitle,
                            initialName: _welcomeInitialName,
                            confirmLabel: AppLocalizations.of(
                              context,
                            )!.mainMenuLetsStartButton,
                            popOnSave: false,
                            onSaved: _saveWelcomeName,
                          ),
                          const Spacer(flex: 4),
                          Text(
                            AppLocalizations.of(context)!.mainMenuTermsNotice,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
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

    // 🆕 עיצוב מחדש "Home v10" (מחליף לגמרי את 1b הקודם, לפי מוקאפ חדש
    // שסופק) - כותרת ראשית + "תלתן" של 4 כרטיסים (חברים/טורנירים/חנות/
    // משימות) עם כפתור "שחק" מרכזי צף במרכזם שפותח את גיליון "בחרו מוד"
    // עם *כל* המודים (ראו _buildModesSheetV7) + פס התקדמות רמה אמיתי.
    // הסרגל התחתון (_buildHomeBottomNavV7, מקומי למסך הזה בלבד) חוזר
    // עכשיו לסט המקורי: חנות·מובילים·שחק·משימות·הגדרות - "חברים" נגיש
    // דרך כרטיס התלתן במקום טאב נפרד, ו"הגדרות"/"משימות" חוזרים לסרגל.
    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              // 🩹 אותו חישוב פדינג-תחתון דינמי שכבר היה כאן (ראו הערה
              // מתועדת למטה בהיסטוריה) - רק מותאם לגובה הסרגל התחתון
              // החדש (80 + המרווחים סביבו, ראו _buildHomeBottomNavV7).
              padding: EdgeInsets.only(
                bottom: 96 + MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: _buildTopBarV7(),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: _buildMedalsButtonV10(),
                  ),
                  if (_energy < EnergyService.maxEnergy) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _FadeSlideIn(
                        index: 0,
                        child: _buildEnergyAdCard(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildHomeTitleHeaderV10(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: _FadeSlideIn(index: 1, child: _buildCloverGridV10()),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: _FadeSlideIn(
                      index: 2,
                      child: _buildBattlePassBannerV7(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🆕 סרגל ניווט תחתון חדש, ייעודי למסך הבית בלבד - ראו הערה
          // למעלה.
          _buildHomeBottomNavV7(),
          // 🆕 הדרכה ראשונית - שלב 1 (מתוך 2) הוא ספוטלייט על כפתור "שחק"
          // המרכזי כאן (ראו _tourPlayButtonKey/_buildCenterPlayButtonV10);
          // שלב 2 ("שלבים" בגיליון המודים) מוצג בנפרד בתוך
          // _buildModesSheetV7 עצמו - ראו _tourLevelsCardKey.
          if (showHomeTour && _tourStep == 0)
            (_tourWelcomeDismissed
                ? _buildHomeTourOverlayV5()
                : _buildHomeTourWelcomeOverlay()),
        ],
      ),
    );
  }

  // ===================== מסך הבית - עיצוב "Home v5" =====================
  // כל המתודות מכאן ועד _buildTopBar הישנה (למטה) שייכות לעיצוב החדש
  // שיובא ישירות מפרויקט העיצוב של המשתמש (claude.ai/design, "Home v5").
  // כל נתון כאן ממוחזר מהמצב הקיים (coins/_energy/streak/maxLevel/
  // _bpTier/_bpPendingClaims/_dailyChallenge/presence) - שום state חדש.

  // שורה עליונה מצומצמת: אווטאר עם תג-רמה (ימין, RTL) → פיל מטבעות →
  // פיל אנרגיה → כפתור מתנה (קיים, _showDailyGiftsDialog) → הגדרות.
  // 🩹 שם המשתמש הוסר מהשורה הזו (לא מופיע במוקאפ בכלל - שם האווטאר שם
  // קטן ודחוס) - הלחיצה על "מדליות" שהייתה מתחת לשם הועברה לאווטאר עצמו,
  // כדי לא לאבד את הגישה למסך ההישגים.
  // 🆕 עיצוב מחדש "Home v10" - שורה עליונה מצומצמת: אווטאר+שם+רצף כניסה
  // (ליד השם, לא עוד כפתור נפרד) + פילי מטבעות/אנרגיה. אין יותר כפתורי
  // מתנה/משימות/הגדרות כאן - משימות והגדרות עברו לסרגל הניווט התחתון
  // (ראו _buildHomeBottomNavV7), ומתנת הרצף היומי ממשיכה לצוץ אוטומטית
  // לבד (_checkLoginStreak, ללא שינוי) כשרלוונטי.
  Widget _buildTopBarV7() {
    final loc = AppLocalizations.of(context)!;
    final (world, _, _) = _worldProgress(maxLevel);
    // 🩹 אוחד לשורה אחת לפי בקשה מפורשת - בניגוד לניסיון קודם עם שורה
    // אחת (שם אנרגיה "נעלמה" כי כל הפילים התכווצו/נדחקו לגלילה באופן
    // שווה), כאן רק בלוק הפרופיל (אווטאר+שם+עולם+רצף) עטוף ב-Expanded
    // ומתכווץ (שם המשתמש עובר ל-ellipsis ככל שצריך); 4 תגי הסטטיסטיקה
    // והמתנה תמיד בגודל הקבוע והקטן שלהם ולעולם לא נגללים/נעלמים - הם
    // הכי חשובים לראות תמיד. נבדק ב-393dp (רוחב אייפון אמיתי).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                AudioManager.playClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 170),
                padding: const EdgeInsets.fromLTRB(5, 5, 11, 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.09),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: const Color(
                                0xFFFFD86B,
                              ).withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/icon/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          left: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFF1E2A5A),
                              border: Border.all(
                                color: const Color(0xFF120C2E),
                                width: 1.3,
                              ),
                            ),
                            child: Text(
                              '$world',
                              style: const TextStyle(
                                color: Color(0xFFFFD86B),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username.isNotEmpty
                                ? username
                                : loc.mainMenuHelloFallback,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          // 🩹 תוקן: "🔥 {days}" כמחרוזת טקסט אחת תחת RTL אמביינטי
                          // התהפך ויזואלית ל-"{days} 🔥" (אין בו שום תו "חזק"
                          // שיעגן את כיוון הקריאה - בדיוק אותו באג bidi
                          // שתועד כבר במקומות אחרים בקובץ הזה עם ספרות/שעון).
                          // אייקון אמיתי + Row נפרד פותר את זה לגמרי (אין
                          // יותר תלות ב-bidi על מחרוזת מעורבת אימוג'י+ספרה).
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: const Color(
                                  0xFFFF8A3C,
                                ).withValues(alpha: 0.85),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$_loginStreakDays',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _topPillV5(
          icon: Icons.monetization_on_rounded,
          color: const Color(0xFFFFD86B),
          text: '$coins',
        ),
        const SizedBox(width: 4),
        _topPillV5(
          icon: Icons.bolt_rounded,
          color: const Color(0xFF7DD3FC),
          text: '$_energy/${EnergyService.maxEnergy}',
        ),
        const SizedBox(width: 4),
        _topPillV5(
          icon: Icons.star_rounded,
          color: const Color(0xFFC4B5FD),
          text: '$xp',
        ),
        const SizedBox(width: 6),
        _topBarGiftButtonV10(),
      ],
    );
  }

  // 🆕 כפתור "מדליות" מפורש עם מילה כתובה (לא רק אייקון/מספר כמו הפיל
  // שהיה בשורה העליונה) - לפי בקשה מפורשת: "ככה יהיה לאנשים יותר קל"
  // (יותר ברור/מזוהה מפיל קטן). פותח את מסך ההישגים, בדיוק כמו שהלחיצה
  // על כרטיס הפרופיל כבר עושה (ראו _buildTopBarV7) - נקודת כניסה נוספת
  // ובולטת יותר, לא מחליפה את הקיימת.
  Widget _buildMedalsButtonV10() {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AudioManager.playClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFDA4AF).withValues(alpha: 0.2),
                const Color(0xFFFDA4AF).withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFDA4AF).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: Color(0xFFFDA4AF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.mainMenuMedalsCount(
                    _medalsEarned,
                    AchievementsService.all.length,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🩹 הועבר לכאן לפי בקשה מפורשת ("איפה שרשום רמה 1 שלב 2... יש סימה
  // של מתנה, תיקח אותו תשים אותו למעלה צד שמאל") - היה חלק מכרטיס פס
  // ההתקדמות (_buildLevelProgressRibbonV10, נמחק כעת כולו לפי אותה
  // בקשה: "ואת איפה שרשום רמה 1 שלב 2 תמחק"). הכפתור עצמו (דיאלוג
  // המתנות היומיות האמיתי) לא השתנה בהתנהגותו - רק קיבל גרסה קומפקטית
  // שמתאימה לשורת הפילים העליונה, ועבר להיות הילד האחרון ב-Row של
  // _buildTopBarV7 - תחת RTL אמביינטי זה ממקם אותו הכי בצד שמאל, בדיוק
  // כמו שהתבקש.
  Widget _topBarGiftButtonV10() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: _showDailyGiftsDialog,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB4531A).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF2A1740),
                size: 18,
              ),
              if (_adBonusAvailable)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE11D48),
                      border: Border.all(
                        color: const Color(0xFF120C2E),
                        width: 1.4,
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

  Widget _topPillV5({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      // 🩹 צומצם עוד (7→6) - עכשיו באותה שורה ממש עם הפרופיל והמתנה
      // (ראו _buildTopBarV7), צריך כל פיקסל אפשרי.
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          // 🆕 XP/מדליות (ראו קריאות _topPillV5 למטה) - אין להם אייקון
          // נכס ייעודי כמו מטבעות/אנרגיה, אז פשוט אייקון Material וקטורי
          // (מוכח כעובד בכל שאר האפליקציה - בניגוד לאימוג'י).
          if (icon == Icons.monetization_on_rounded)
            const CoinIcon(size: 13)
          else if (icon == Icons.bolt_rounded)
            const EnergyIcon(size: 13)
          else
            Icon(icon, color: color, size: 13),
        ],
      ),
    );
  }

  // ===================== מסך הבית - עיצוב "Home v10" (מחליף את 1b) =====================
  // כותרת ראשית + "תלתן" של 4 כרטיסים (חברים/טורנירים/חנות/משימות) עם
  // כפתור "שחק" מרכזי צף שפותח את גיליון המודים + פס התקדמות רמה אמיתי.

  Widget _buildHomeTitleHeaderV10() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          loc.mainMenuHomeTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD86B),
            shadows: [Shadow(color: Color(0xFFB4531A), offset: Offset(0, 3))],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loc.mainMenuHomeTagline,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 🩹 "תלתן" הכרטיסים נבנה בתוך Directionality(ltr) מכוונת, בדיוק כמו
  // ב-dir="ltr" שעוטף את ה-grid במוקאפ - כדי שסדר הכרטיסים (חברים
  // למעלה-ימין בפועל) לא יתהפך לפי כיוון RTL של שאר האפליקציה. כל כרטיס
  // עצמו עוטף את התוכן שלו חזרה ב-Directionality(rtl) כדי שהטקסט
  // העברי יתיישר נכון (ראו dir="rtl" על כל תא-תוכן במוקאפ).
  Widget _buildCloverGridV10() {
    final loc = AppLocalizations.of(context)!;
    final participants = _tournamentTop.length;
    final onlineFriends = _friends.where((f) => f.online).length;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 330,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _cloverTileV10(
                          icon: Icons.groups_rounded,
                          title: loc.appBottomNavFriends,
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                loc.playVsPersonConnectedCount(onlineFriends),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          gradient: const [
                            Color(0xFF38BDF8),
                            Color(0xFF1D4ED8),
                          ],
                          shadowColor: const Color(0xFF1D4ED8),
                          radius: const BorderRadius.only(
                            topLeft: Radius.circular(48),
                            topRight: Radius.circular(48),
                            bottomRight: Radius.circular(18),
                            bottomLeft: Radius.circular(48),
                          ),
                          pushToTop: true,
                          onTap: () async {
                            AudioManager.playClick();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FriendsScreen(username: username),
                              ),
                            );
                            _refreshStats();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cloverTileV10(
                          icon: Icons.emoji_events_rounded,
                          title: loc.mainMenuBottomNavTournaments,
                          statusBadgeIcon: _tournamentActionAvailable ? Icons.priority_high_rounded : null,
                          // 🩹 תוקן באג bidi: צירוף שעון HH:MM:SS (ספרות
                          // + נקודתיים) בתוך אותה מחרוזת עם טקסט עברי תחת
                          // RTL הסתיר/בלבל את הספרות (אותו דפוס באג שכבר
                          // תועד ומטופל בתת-כותרת תא המשימות למטה) - השעון
                          // עכשיו ב-Text נפרד בתוך Directionality(ltr) משלו.
                          // 🩹 תוקן סופית: לא עוד ellipsis/Flexible חלקי -
                          // על מסך צר (אייפון אמיתי, לא האמולטור הרחב
                          // שבדקתי בו) המחרוזת המלאה ("קופה 200 · 71:59:59"
                          // בתחילת אירוע 3 ימים) עדיין לא נכנסה ברוחב
                          // האריח, והמספר האחרון "נקטע"/נדחס לתוך הפינה
                          // המעוגלת (רדיוס קטן, 18, בפינה הפנימית). FittedBox
                          // עם scaleDown מכווץ את כל השורה (קופה+שעון יחד,
                          // ביחס אחיד) אם היא לא נכנסת - במקום שחלק ממנה
                          // יחרוג/ייחתך. זה לא תלוי ברוחב מסך ספציפי - בטוח
                          // בכל מכשיר.
                          subtitle: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.mainMenuTournamentTileSubtitlePrefix(
                                    currentPoolEstimate(participants),
                                  ),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    _formatHms(_tournamentTimeUntilReset),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          gradient: const [
                            Color(0xFFFBBF24),
                            Color(0xFFEA580C),
                          ],
                          shadowColor: const Color(0xFFEA580C),
                          radius: const BorderRadius.only(
                            topLeft: Radius.circular(48),
                            topRight: Radius.circular(48),
                            bottomRight: Radius.circular(48),
                            bottomLeft: Radius.circular(18),
                          ),
                          pushToTop: true,
                          onTap: _showTournamentChooserV7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _cloverTileV10(
                          icon: Icons.shopping_cart_rounded,
                          title: loc.appBottomNavShop,
                          statusBadgeIcon: _tournamentBonusActive ? Icons.percent_rounded : null,
                          subtitle: Text(
                            _tournamentBonusActive
                                ? loc.mainMenuShopTileBonusActive
                                : loc.mainMenuShopQuickLinkSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          gradient: const [
                            Color(0xFF059669),
                            Color(0xFF34D399),
                          ],
                          shadowColor: const Color(0xFF059669),
                          radius: const BorderRadius.only(
                            topLeft: Radius.circular(48),
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(48),
                            bottomLeft: Radius.circular(48),
                          ),
                          pushToTop: false,
                          onTap: () async {
                            AudioManager.playClick();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ShopScreen(),
                              ),
                            );
                            _refreshStats();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cloverTileV10(
                          icon: Icons.track_changes_rounded,
                          title: loc.appBottomNavMissions,
                          badgeCount: _missionsUnclaimed > 0
                              ? _missionsUnclaimed
                              : null,
                          subtitle: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '$_missionsCompletedCount/$_missionsTotalCount',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          gradient: const [
                            Color(0xFFBE185D),
                            Color(0xFFF472B6),
                          ],
                          shadowColor: const Color(0xFFBE185D),
                          radius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(48),
                            bottomRight: Radius.circular(48),
                            bottomLeft: Radius.circular(48),
                          ),
                          pushToTop: false,
                          onTap: () async {
                            AudioManager.playClick();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MissionsScreen(),
                              ),
                            );
                            _refreshStats();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildCenterPlayButtonV10(),
          ],
        ),
      ),
    );
  }

  // 🩹 תוקן סופית לפי בקשה חוזרת ("אותו הדבר עדיין הזמן מאחוריי הכפתור") -
  // נבדק בפועל במסך צר (393dp, רוחב אייפון אמיתי - לא האמולטור הרחב יותר
  // שבדקתי בו קודם, ששם זה פשוט לא נראה) ושוחזר במדויק: כפתור "שחק"
  // המרכזי (קוטר 150, ממורכז אנכית בתוך ה-SizedBox בגובה 330) תופס את
  // הטווח האנכי y=90..240 מתוך ה-330. תוכן אריח "pushToTop" (עליון, דחוף
  // להתחלה) היה מגיע עד y≈110 (16 ריפוד + 42 אייקון + 10 + 22 כותרת + 4 +
  // 16 תת-כותרת) - נכנס לתוך הטווח הזה, ועל אריח צר שבו תוכן ממורכז
  // אופקית מגיע קרוב לפינה הפנימית, הטקסט ממש נחתך מאחורי העיגול. אייקון/
  // מרווחים/גופן כותרת קטנים יותר כאן מצמצמים את גובה התוכן ל-~72px -
  // מסתיים ב-y≈88, לפני שהעיגול בכלל מתחיל (y=90). אותו תיקון חל גם על
  // אריחי "pushToBottom" (דחופים לסוף) באותה סימטריה.
  Widget _cloverTileV10({
    required IconData icon,
    required String title,
    required Widget subtitle,
    required List<Color> gradient,
    required Color shadowColor,
    required BorderRadius radius,
    required VoidCallback onTap,
    required bool pushToTop,
    int? badgeCount,
    // 🆕 "יופיע להם בצד ימין לוגו צהוב... עם סימן של הנחה ככה הם ידעו
    // שעדיין יש להם את ההנחה" / "אותו דבר עם הטורנירים" - תג פינתי זהוב
    // קבוע (לא מספר) לציון "יש כאן משהו פעיל שמחכה לך" - בונוס הנחה פעיל
    // בחנות, או שלב היום באתגר הרב-יומי שעדיין לא שוחק. לא מוצג יחד עם
    // badgeCount (אף אריח לא צריך את שניהם בפועל).
    IconData? statusBadgeIcon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: pushToTop
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    if (badgeCount != null)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Text(
                            '$badgeCount',
                            style: TextStyle(
                              color: shadowColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    else if (statusBadgeIcon != null)
                      Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFD86B),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Icon(statusBadgeIcon, color: const Color(0xFF2A1740), size: 13),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // כפתור "שחק" המרכזי הצף - פותח את אותו גיליון מודים כמו כפתור "שחק"
  // בסרגל הניווט התחתון (_openModesSheetV7, משותף). נושא את
  // _tourPlayButtonKey - המטרה של הסיור הראשוני (הועבר לכאן מהסרגל
  // התחתון כי זה עכשיו הכפתור הבולט/מרכזי יותר בעיצוב Home v10).
  Widget _buildCenterPlayButtonV10() {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: _tourPlayButtonKey,
        customBorder: const CircleBorder(),
        onTap: _openModesSheetV7,
        child: Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF2A145E),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE08A),
                  Color(0xFFFFB24D),
                  Color(0xFFFF8A3C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: const Color(0xFFFFAA3C).withValues(alpha: 0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF2A1740),
                  size: 36,
                ),
                Text(
                  loc.appBottomNavPlay,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF2A1740),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ניווט למסך השלבים - נקרא מתוך גיליון המודים (_buildModesSheetV7,
  // כרטיס "שלבים"). סגירת הסיור (אם פעיל) מטופלת בכפתור "שחק" עצמו
  // (_buildHomeBottomNavV7) שפותח את הגיליון, לא כאן.
  Future<void> _goToLevels() async {
    AudioManager.playClick();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LevelsScreen()),
    );
    _refreshStats();
  }

  // ===================== מסך הבית - עיצוב "Home v10" (מחליף את 1b) =====================

  // ===================== סרגל ניווט תחתון ייעודי למסך הבית (Home v10) =====================
  // 🆕 מחליף כאן את AppBottomNav המשותף - ראו הערה ב-build(). חוזר לסט
  // המקורי של המוקאפ: חנות · מובילים · שחק · משימות · הגדרות. "חברים"
  // ו"טורנירים" לא נעלמו - נגישים עכשיו דרך כרטיסי התלתן (ראו
  // _buildCloverGridV10), בדיוק לפי המוקאפ שכבר לא כולל אותם כאן.
  // 🩹 תוקן לפי בקשה מפורשת ("המניו למטה הוא לא הכי למטה ומופיעים מאחוריו
  // דברים") - הסרגל היה "כרית" צפה עם שוליים מכל 4 הצדדים (left/right:18,
  // bottom:safeArea+14), שמשאירה פער שקוף בינה לבין קצה המסך האמיתי - בדיוק
  // שם תוכן גלול יכול "להציץ" מתחת לסרגל. בדיקה מול המוקאפ המקורי
  // (Home v10.html, "bottom tab bar") מראה שהסרגל שם למעשה צמוד לקצה
  // (left:0, right:0, bottom:0, רק הפינות העליונות מעוגלות) - לא כרית צפה.
  // עכשיו תואם את זה בדיוק: צמוד לקצה התחתון האמיתי, בלי שום פער.
  Widget _buildHomeBottomNavV7() {
    final loc = AppLocalizations.of(context)!;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              8,
              12,
              8,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              border: const Border(
                top: BorderSide(color: Colors.white24, width: 1),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E1448).withValues(alpha: 0.95),
                  const Color(0xFF120C2E).withValues(alpha: 0.99),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 36,
                  offset: const Offset(0, -14),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _navTabV7(
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF6EE7B7),
                    label: loc.appBottomNavShop,
                    discountBadge: _tournamentBonusActive,
                    onTap: () async {
                      AudioManager.playClick();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShopScreen(),
                        ),
                      );
                      _refreshStats();
                    },
                  ),
                ),
                Expanded(
                  child: _navTabV7(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFFFDA4AF),
                    label: loc.appBottomNavLeaderboard,
                    onTap: () async {
                      AudioManager.playClick();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaderboardScreen(),
                        ),
                      );
                      _refreshStats();
                    },
                  ),
                ),
                SizedBox(width: 88, child: _navPlayButtonV7()),
                Expanded(
                  child: _navTabV7(
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFF34D399),
                    label: loc.appBottomNavMissions,
                    badgeCount: _missionsUnclaimed > 0
                        ? _missionsUnclaimed
                        : null,
                    onTap: () async {
                      AudioManager.playClick();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MissionsScreen(),
                        ),
                      );
                      _refreshStats();
                    },
                  ),
                ),
                Expanded(
                  child: _navTabV7(
                    icon: Icons.settings_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    label: loc.settingsScreenTitle,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final name = prefs.getString('username') ?? '';
                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(username: name),
                        ),
                      );
                      _refreshStats();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navTabV7({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
    bool showDot = false,
    // 🆕 "שיופיע להם בצד ימין לוגו צהוב של החנות עם סימן של הנחה" - טאב
    // "חנות" הוא הראשון ב-Row הזה, שמוצג בפועל הכי מימין בגלל ה-RTL -
    // בדיוק "בצד ימין" שהתבקש. תג זהוב עם "%" כשיש בונוס מבצע-אלוף פעיל
    // (IapManager.tournamentBonusActive), כדי שלא ישכחו שההנחה עדיין בתוקף.
    bool discountBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: color, size: 23),
                  if (discountBadge)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFD86B),
                        ),
                        child: const Icon(Icons.percent_rounded, color: Color(0xFF2A1740), size: 10),
                      ),
                    ),
                  if (showDot)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: const Color(0xFF120C2E),
                            width: 1.3,
                          ),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Color(0xFF120C2E),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // כפתור "שחק" בסרגל הניווט התחתון - מוגבה ומוגדל (זהה בעיקרון
  // ל-_buildHomeSlot של AppBottomNav, רק עם onTap שפותח את גיליון
  // המודים במקום popUntil). 🩹 ה-_tourPlayButtonKey עבר לכפתור "שחק"
  // המרכזי הגדול של התלתן (_buildCenterPlayButtonV10) - הוא הבולט/
  // המרכזי יותר בעיצוב Home v10, אז הסיור מצביע עליו ולא עוד על הכפתור
  // הזה (אי אפשר שאותו GlobalKey יהיה על שני ווידג'טים בעת ובעונה אחת).
  Widget _navPlayButtonV7() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _playButtonPressed = true),
        onTapUp: (_) => setState(() => _playButtonPressed = false),
        onTapCancel: () => setState(() => _playButtonPressed = false),
        onTap: _openModesSheetV7,
        child: AnimatedScale(
          scale: _playButtonPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFE08A),
                  Color(0xFFFFB24D),
                  Color(0xFFFF8A3C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFFFAA3C).withValues(alpha: 0.4),
                  blurRadius: 26,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF2A1740),
                  size: 24,
                ),
                Text(
                  loc.appBottomNavPlay,
                  style: const TextStyle(
                    color: Color(0xFF2A1740),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== גיליון "איך משחקים היום?" (Home v7) =====================
  // 🆕 פותח עם כל המודים של המשחק - "יש הרבה מודים" לפי הבקשה המקורית
  // שהניעה את העיצוב מחדש הזה, אז במקום גריד קבוע על מסך הבית, כל
  // האפשרויות מרוכזות כאן בגיליון אחד שנפתח מכפתור "שחק" המרכזי.
  // 🩹 תוקן לפי בקשה מפורשת ("תעביר את המניו שנפתח אחריי שלוחצים על
  // השחק", עם צירוף חוזר של המוקאפ) - במוקאפ המקורי (Home v10.html,
  // ה-sc-if של isOpen) המסך הזה הוא עמוד מסך-מלא (inset:0 על כל גובה/
  // רוחב הפלאפון) שמחליף את מסך הבית לגמרי, לא גיליון חלקי שעולה
  // מלמטה ומשאיר פס מהבית גלוי למעלה (showModalBottomSheet הקודם).
  // עכשיו נפתח כ-route מסך-מלא רגיל (Navigator.push), עם אנימציית
  // fade+scale קלה במקום slide-up - התוכן עצמו (כותרת/שורות המודים)
  // לא השתנה, רק המארז סביבו.
  void _openModesSheetV7() {
    AudioManager.playClick();
    // 🩹 לפי בקשה מפורשת - לא סוגרים את הסיור כאן יותר. במקום זה מתקדמים
    // לשלב הבא (הכרטיס "שלבים" בתוך הגיליון שנפתח עכשיו, ראו
    // _buildModesSheetV7/_tourLevelsCardKey) - הסיור ממשיך שם, לא נעצר.
    if (showHomeTour && _tourStep == 0) {
      setState(() => _tourStep = 1);
    }
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (routeContext, animation, secondaryAnimation) =>
            _buildModesSheetV7(routeContext),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModesSheetV7(BuildContext sheetContext) {
    final loc = AppLocalizations.of(context)!;
    final challenge = _dailyChallenge;
    final done = challenge?.completed ?? false;
    final usedUp = challenge != null && !done && challenge.attempted;
    final dailySubtitle = done
        ? loc.mainMenuDailyRewardClaimed
        : (usedUp
              ? loc.mainMenuDailyUsedUp
              : loc.playVsPersonLogosRangeSingle(
                  MissionsService.dailyChallengeLogoCount,
                ));
    // 🩹 תוקן לפי בקשה מפורשת: "רשום בשני רמה 2 ואני ברמה 1" - הכרטיס
    // "שלבים" הציג את maxLevel הגולמי (מונה הלוגו הכללי לאורך כל המשחק,
    // למשל 2 = "הלוגו השני בסך הכול") תחת התווית "רמה 2", מה שנראה כמו
    // "עולם/רמה 2" - אבל המשתמש עדיין בעולם 1. עכשיו מציג "עולם · שלב"
    // אמיתיים (אותו _worldProgress בדיוק כמו בפס ההתקדמות בבית), כך
    // שהמספר תואם למה שבאמת רואים שם.
    final (levelsWorld, levelsSub, _) = _worldProgress(maxLevel);

    return Scaffold(
      backgroundColor: const Color(0xFF1E0F4A),
      // 🩹 תוקן לפי בקשה מפורשת ("תקטין טיפה את זה... ושיהיה למטה
      // המניו") - נוסף Stack עם AppBottomNav המשותף בתחתית (לא היה כאן
      // בכלל קודם), ורוב הגדלים/הריפודים בתוכן קוטנו כדי שכל התוכן יכנס
      // קרוב ככל האפשר למסך אחד בלי גלילה.
      body: Stack(
        children: [
          SizedBox.expand(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A1B82), Color(0xFF1E0F4A)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    110 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🩹 נבנה מחדש לפי בקשה מפורשת ("שלחתי לך את המסך שאני
                      // רוצה תשים אותו") - תואם עכשיו בדיוק את גיליון isOpen
                      // במוקאפ (Home v10.html): כפתור סגירה "›" + פילי מטבעות/
                      // אנרגיה בשורה אחת, כותרת גדולה ממורכזת + משפט קריצה,
                      // רשת 2x2 לכרטיסי "לבד" (לא עוד רשימת שורות), ו"מול
                      // אחרים" עם מחוון "X מחוברים" חי ליד הכותרת. כל המספרים
                      // עדיין אמיתיים (coins/_energy/world/sub/tafzoretWorlds/
                      // streak/dailySubtitle/players), רק המארז הוויזואלי תואם
                      // את המוקאפ עכשיו.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(sheetContext),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: 0.09),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _topPillV5(
                                icon: Icons.monetization_on_rounded,
                                color: const Color(0xFFFFD86B),
                                text: '$coins',
                              ),
                              const SizedBox(width: 6),
                              _topPillV5(
                                icon: Icons.bolt_rounded,
                                color: const Color(0xFF7DD3FC),
                                text: '$_energy/${EnergyService.maxEnergy}',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              loc.mainMenuModesSheetTitle,
                              style: const TextStyle(
                                color: Color(0xFFFFD86B),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFB4531A),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.mainMenuModesSheetSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _modesSheetSectionDividerV7(
                        loc.mainMenuModesSheetSoloSection,
                      ),
                      const SizedBox(height: 6),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 7,
                        crossAxisSpacing: 7,
                        childAspectRatio: 150 / 98,
                        children: [
                          _modesSoloCardV7(
                            cardKey: _tourLevelsCardKey,
                            icon: Icons.map_rounded,
                            gradient: const [
                              Color(0xFFA78BFA),
                              Color(0xFF6D28D9),
                            ],
                            shadowColor: const Color(0xFF4C1D95),
                            title: loc.mainMenuModesLevelsTitle,
                            note: loc.mainMenuLevelProgressTitle(
                              levelsWorld,
                              levelsSub,
                            ),
                            onTap: () {
                              // 🩹 שלב 2 (האחרון) של הסיור הראשוני מסתיים
                              // כאן, בדיוק כמו שהתבקש - ראו _tourLevelsCardKey.
                              if (showHomeTour) {
                                setState(() => showHomeTour = false);
                              }
                              Navigator.pop(sheetContext);
                              _goToLevels();
                            },
                          ),
                          _modesSoloCardV7(
                            icon: Icons.extension_rounded,
                            gradient: const [
                              Color(0xFFF472B6),
                              Color(0xFFBE185D),
                            ],
                            shadowColor: const Color(0xFF831843),
                            title: loc.mainMenuModesTafzoretTitle,
                            note: loc.mainMenuModesTafzoretNote(
                              tafzoretWorlds.length,
                            ),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              AudioManager.playClick();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TafzoretWorldsScreen(),
                                ),
                              );
                              _refreshStats();
                            },
                          ),
                          _modesSoloCardV7(
                            icon: Icons.casino_rounded,
                            gradient: const [
                              Color(0xFFFBBF24),
                              Color(0xFFEA580C),
                            ],
                            shadowColor: const Color(0xFF9A3412),
                            title: loc.mainMenuRandomTitle,
                            note: loc.mainMenuRandomSubtitle(streak),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              AudioManager.playClick();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LevelLoadingScreen(
                                    puzzleId: 0,
                                    isRandomMode: true,
                                    categoryLabel:
                                        loc.mainMenuRandomChallengeLabel,
                                  ),
                                ),
                              );
                              _refreshStats();
                            },
                          ),
                          _modesSoloCardV7(
                            icon: Icons.event_note_rounded,
                            gradient: const [
                              Color(0xFF38BDF8),
                              Color(0xFF1D4ED8),
                            ],
                            shadowColor: const Color(0xFF1E3A8A),
                            title: loc.mainMenuDailyChallengeMiniTitle,
                            note: dailySubtitle,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _playDailyChallenge();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _modesSheetSectionDividerV7(
                        loc.mainMenuVsOthersTitle,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              loc.playVsPersonConnectedCount(
                                (_superdualPlayersNow ?? 0) +
                                    (_duelPlayersNow ?? 0) +
                                    (_racePlayersNow ?? 0),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _modesVersusRowV7(
                        icon: Icons.emoji_events_rounded,
                        gradient: const [Color(0xFFFFC94D), Color(0xFFF97316)],
                        shadowColor: const Color(0xFF9A3412),
                        title: loc.playVsPersonSeriesTitle,
                        note: loc.playVsPersonSeriesSubtitle,
                        onlineCount: _superdualPlayersNow,
                        energyCost: 2,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          AudioManager.playClick();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DuelLobbyScreen(
                                username: username,
                                seriesMode: true,
                              ),
                            ),
                          );
                          _refreshStats();
                        },
                      ),
                      const SizedBox(height: 6),
                      _modesVersusRowV7(
                        icon: Icons.bolt_rounded,
                        gradient: const [Color(0xFFFB7185), Color(0xFFBE123C)],
                        shadowColor: const Color(0xFF881337),
                        title: loc.playVsPersonDuelTitle,
                        note: loc.playVsPersonDuelSubtitle,
                        onlineCount: _duelPlayersNow,
                        energyCost: 2,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          AudioManager.playClick();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DuelLobbyScreen(username: username),
                            ),
                          );
                          _refreshStats();
                        },
                      ),
                      const SizedBox(height: 6),
                      _modesVersusRowV7(
                        icon: Icons.flag_rounded,
                        gradient: const [Color(0xFF34D399), Color(0xFF047857)],
                        shadowColor: const Color(0xFF064E3B),
                        title: loc.playVsPersonRaceTitle,
                        note: loc.playVsPersonRaceSubtitle,
                        onlineCount: _racePlayersNow,
                        energyCost: 2,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          AudioManager.playClick();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LogoRaceScreen(username: username),
                            ),
                          );
                          _refreshStats();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 🩹 none (לא home) - ראו ההערה המתועדת ב-app_bottom_nav.dart -
          // כדי שכפתור "בית" כאן יסגור את הגיליון הזה בפועל, במקום no-op.
          AppBottomNav(current: AppTab.none),
          // 🆕 שלב 2 (האחרון) של הסיור הראשוני - ראו _tourLevelsCardKey.
          // הגיליון הזה נפתח כ-route מסך-מלא נפרד (לא overlay על מסך
          // הבית), אז ספוטלייט הסיור חייב להיות מצויר כאן בתוך הגיליון
          // עצמו ולא ב-Stack של main_menu_screen.dart - אחרת הוא פשוט
          // לא יהיה גלוי (מתחת לגיליון האטום הזה).
          if (showHomeTour && _tourStep == 1)
            // 🩹 StatefulBuilder מקומי - ראו ההסבר המלא ב-_buildTourSpotlight
            // (onRetryRebuild): הגיליון הזה route נפרד, this.setState לא
            // יכול לרענן אותו - ה-setState המקומי של ה-StatefulBuilder כן.
            StatefulBuilder(
              builder: (sbContext, setSheetState) => _buildTourSpotlight(
                targetKey: _tourLevelsCardKey,
                title: loc.mainMenuTourLevelsCardTitle,
                body: loc.mainMenuTourLevelsCardBody,
                onRetryRebuild: () => setSheetState(() {}),
              ),
            ),
        ],
      ),
    );
  }

  // שורת מוד "מול אחרים" - אייקון בריבוע מעוגל + שם/הערה + פיל "מחוברים
  // עכשיו" (אמיתי, ראו קריאות ל-PresenceService ב-_refreshPresenceCounts).
  // onlineCount == null מוצג כ"עוד לא נטען" (לא מציג פיל בכלל) - בדיוק
  // כמו הדפוס הקיים ב-_ModeCard.liveCount.
  // 🆕 נוסף בחזרה למסך הבית לפי בקשה מפורשת ("הלוגו פאס עדיין לא
  // מופיע... תעשה עיצוב אחר ומיוחד", ואז "הוא אמור להיות במקום איפה
  // שרשום למטה רמה X שלב X") - במעבר ל-Home v10 נמחק הכרטיס הישן
  // (_buildBattlePassCard למטה - עדיין קיים אך הפך ללא מקושר) בלי שנוספה
  // לו נקודת כניסה חדשה, כך שהלוגו פאס נעלם לגמרי מהתפריט. בניסיון
  // ראשון הוא הוצג בתוך גיליון "בחרו מוד", ואז עבר לאזור פס ההתקדמות
  // "רמה · שלב" - אבל אותו פס נמחק לגמרי בעקבות בקשה נוספת ("ואת איפה
  // שרשום רמה 1 שלב 2 תמחק"), אז הבאנר הזה הפך לכרטיס היחיד באזור הזה
  // (ראו build()). עדיין "באנר" ייעודי - זהוב, גדול ומבריק יותר מכרטיסי
  // המוד הרגילים - בדיוק כי זה פיצ'ר פרימיום שראוי לבלוט. ה-state
  // (_bpTier/_bpPoints/...) כבר חי ומתעדכן (_refreshBattlePass נקרא
  // מ-_refreshStats), רק חסרה הייתה נקודת תצוגה - חישוב ההתקדמות כאן
  // זהה ל-_buildBattlePassCard הישן.
  Widget _buildBattlePassBannerV7() {
    final loc = AppLocalizations.of(context)!;
    final tiers = BattlePassService.tiers;
    final maxTier = tiers.length;
    final int currentRequired = _bpTier <= 0
        ? 0
        : tiers
              .firstWhere((t) => t.tier == _bpTier, orElse: () => tiers.first)
              .pointsRequired;
    final nextDef = _bpTier < maxTier ? tiers[_bpTier] : null;
    final int span = nextDef == null
        ? 0
        : nextDef.pointsRequired - currentRequired;
    final int within = nextDef == null
        ? 0
        : (_bpPoints - currentRequired).clamp(0, span);
    final double progress = nextDef == null
        ? 1.0
        : (span == 0 ? 1.0 : within / span);
    final String fractionText = nextDef == null
        ? loc.mainMenuMaxLabel
        : "$within/$span";

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          AudioManager.playClick();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BattlePassScreen()),
          );
          _refreshStats();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7A4E12), Color(0xFF3A2306)],
            ),
            border: Border.all(
              color: const Color(0xFFFFD86B).withValues(alpha: 0.6),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB84D).withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -24,
                  top: -36,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.14),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)],
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF2A1740),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    loc.mainMenuBattlePassTitle,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD86B),
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (_bpPremium) ...[
                                    const SizedBox(width: 5),
                                    const Text(
                                      "👑",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              // 🩹 תוקן לפי בקשה מפורשת ("לא רואים את
                              // המספרים טוב") - "X/Y" היה שורה נפרדת,
                              // קטנה ולבנה, מרוחקת לגמרי מתחת לפס ההתקדמות
                              // (בלי שום קשר חזותי ישיר אליו) - קל לפספס.
                              // עכשיו צמוד לתווית "דרגה" באותה שורה
                              // (spaceBetween), גדול וזהוב בוהק - אותו
                              // דפוס מוכח שהיה בפס ההתקדמות של השלבים
                              // (שנמחק מאז, ראו ההערה מעל הפונקציה).
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${loc.battlePassTierLabel} $_bpTier',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      fractionText,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD86B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_bpPendingClaims > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFE11D74),
                            ),
                            child: Text(
                              loc.mainMenuClaimsCount(_bpPendingClaims),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white.withValues(alpha: 0.55),
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFD86B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 כותרת section בגיליון המודים - תואמת עכשיו את המוקאפ (Home v10.html):
  // כותרת מודגשת + קו מפריד שמתפרס על שאר הרוחב, ואופציונלית ווידג'ט נוסף
  // בקצה (למשל מחוון "X מחוברים" חי ליד "מול אחרים").
  Widget _modesSheetSectionDividerV7(String label, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing],
      ],
    );
  }

  // 🆕 כרטיס "לבד" ברשת 2x2 - תואם עכשיו את המוקאפ (Home v10.html) במקום
  // שורת-רשימה: כרטיס גבוה עם רקע גרדיאנט מלא, "צל כפתור" מוצק (לא רק
  // טשטוש) שנותן תחושת לחיצה תלת-מימדית, עיגול דקורטיבי ואייקון גדול
  // שמציצים מהפינה, וכותרת+הערה בראש. 🩹 אייקון וקטורי (לא אימוג'י כמו
  // במוקאפ המקורי) - אותה בעיית "ריבוע ריק" שתועדה כבר כמה פעמים
  // באפליקציה הזו (ראו app_icons.dart).
  Widget _modesSoloCardV7({
    Key? cardKey,
    required IconData icon,
    required List<Color> gradient,
    required Color shadowColor,
    required String title,
    required String note,
    required VoidCallback onTap,
  }) {
    return Material(
      key: cardKey,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          // 🩹 תוקן לפי בקשה מפורשת ("האות הראשונה חתוכה") - הריפוד
          // (12px) היה על ה-Container החיצוני, ואילו ה-ClipRRect שמעגל
          // את הפינות (רדיוס 22) עטף את ה-Stack *בפנים* כבר-מצומצם ב-
          // 12px מכל צד - כך שהעיגול הוחל על קופסה קטנה משמעותית מהכרטיס
          // האמיתי, וקצץ עמוק מדי לתוך הפינה הימנית-עליונה שם מתחיל
          // הכיתוב (הימנית = תחילת הטקסט ב-RTL). עכשיו ה-ClipRRect עוטף
          // את הגבולות האמיתיים (לא מצומצם), והריפוד עבר להיות רק סביב
          // הכיתוב עצמו (לא סביב האלמנטים הדקורטיביים, שעדיין "מציצים"
          // עד הקצה האמיתי בדיוק כמו במוקאפ).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(0, 5)),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -22,
                  bottom: -22,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 0,
                  child: Transform.rotate(
                    angle: -0.14,
                    child: Icon(
                      icon,
                      size: 38,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // קטע "● N משחקים" / "⚡ N" - פיל שחור-שקוף קטן בתוך שורת "מול אחרים".
  // 🩹 האנרגיה כ-Icon וקטורי נפרד (לא "⚡ $cost" במחרוזת אחת) - אותה
  // בעיית bidi (אימוג'י+ספרה בלי עוגן RTL) שתועדה כבר כמה פעמים בקובץ
  // הזה (ראו למשל הסבר ליד _loginStreakDays ב-_buildTopBarV7).
  Widget _versusInfoPillV7({
    Color? dotColor,
    IconData? icon,
    required String text,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 11, color: textColor ?? Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // 🩹 עוצב מחדש לפי בקשה מפורשת ("שלחתי לך את המסך שאני רוצה תשים
  // אותו") - תואם עכשיו במדויק את שורות "versus" במוקאפ (Home v10.html):
  // ריבוע-אייקון 60x60 על רקע לבן שקוף (לא עוד ריבוע-גרדיאנט נפרד),
  // עיגול דקורטיבי שמציץ מהפינה, "צל כפתור" מוצק, ושורת פילים "● N
  // משחקים" / "⚡ N" מתחת לכותרת/הערה. גם משמש את גיליון בחירת הטורניר
  // (_showTournamentChooserV7) - שם אין onlineCount/energyCost אמיתיים,
  // אז הפילים פשוט לא מוצגים (שום דבר לא מומצא).
  Widget _modesVersusRowV7({
    required IconData icon,
    required List<Color> gradient,
    required Color shadowColor,
    required String title,
    required String note,
    int? onlineCount,
    int? energyCost,
    required VoidCallback onTap,
  }) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          // 🩹 אותו תיקון בדיוק כמו ב-_modesSoloCardV7 ("האות הראשונה
          // חתוכה") - הריפוד עבר מה-Container החיצוני (לפני ה-ClipRRect,
          // שגרם לעיגול הפינות להיות מוחל על קופסה כבר-מצומצמת) לתוך
          // ה-Row עצמו (אחרי ה-ClipRRect, על הגבולות האמיתיים).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(0, 5)),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -26,
                  top: -26,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (onlineCount != null || energyCost != null) ...[
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onlineCount != null)
                                    _versusInfoPillV7(
                                      dotColor: const Color(0xFF6EE7B7),
                                      text:
                                          '$onlineCount ${loc.playVsPersonPlayingLabel}',
                                    ),
                                  if (onlineCount != null && energyCost != null)
                                    const SizedBox(width: 6),
                                  if (energyCost != null)
                                    _versusInfoPillV7(
                                      icon: Icons.bolt_rounded,
                                      textColor: const Color(0xFFBAE6FD),
                                      text: '$energyCost',
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== גיליון בחירת סוג טורניר (Home v7) =====================
  // 🆕 כפתור "טורנירים" בסרגל התחתון החדש מוביל לכאן - שני פורמטי הטורניר
  // הקיימים (יומי/מתוזמן) במקום לבחור אחד מהם כברירת מחדל.
  void _showTournamentChooserV7() {
    AudioManager.playClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final loc = AppLocalizations.of(context)!;
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3A1B82), Color(0xFF1E0F4A)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  loc.mainMenuTournamentChooserTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _modesVersusRowV7(
                  icon: Icons.emoji_events_rounded,
                  gradient: const [Color(0xFFFF7A59), Color(0xFF8B2FD1)],
                  shadowColor: const Color(0xFF5B1F87),
                  title: loc.mainMenuTournamentChooserDailyTitle,
                  note: loc.mainMenuTournamentChooserDailySubtitle(
                    tournamentEntryFee,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    AudioManager.playClick();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TournamentLobbyScreen(),
                      ),
                    );
                    _refreshStats();
                  },
                ),
                const SizedBox(height: 10),
                _modesVersusRowV7(
                  icon: Icons.bolt_rounded,
                  gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  shadowColor: const Color(0xFF3730A3),
                  title: loc.mainMenuTournamentChooserScheduledTitle,
                  note: loc.mainMenuTournamentChooserScheduledSubtitle(
                    scheduledTournamentEntryFee,
                    scheduledTournamentLogoCount,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    AudioManager.playClick();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduledTournamentScreen(),
                      ),
                    );
                    _refreshStats();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== הדרכה ראשונית: סיור קצר מעל מסך הבית =====================
  // 🩹 עוצב מחדש לגמרי לפי שתי בקשות מפורשות:
  // 1. "ברגע שיש הסבר על משהו זה ממש יתמקד עליו" - במקום כרטיסיה שצפה
  //    במיקום קבוע (שיכולה לשבת בדיוק מעל מה שהיא מסבירה עליו), עכשיו
  //    זה "ספוטלייט" אמיתי: מחפשים את המיקום/גודל הממשי של הרכיב האמיתי
  //    על המסך (GlobalKey + RenderBox.localToGlobal) ומציירים הדהוי כהה
  //    עם "חור" מדויק בדיוק מעל הרכיב הזה (4 מלבנים כהים מסביב לחור,
  //    לא ממש ציור Path עם חור - פשוט וחסין יותר) + מסגרת זוהרת סביבו.
  //    הכרטיסיה עצמה תמיד מוצבת *מחוץ* לאזור המודגש (מעליו/מתחתיו, לפי
  //    מי מהם יותר קרוב לקצה המסך), כך שהיא לעולם לא מכסה את מה שמוסבר.
  // 2. "הסבר על שחק מול אחרים שיסביר, ירשום לחץ עליו, ואז בפנים יסביר" -
  //    שלב 3 (האחרון) לא מציג כפתור "הבא" - החור בהדהוי חושף את הכרטיס
  //    האמיתי "מול אחרים" ומאפשר ללחוץ עליו ישירות (אין שום Widget חוסם
  //    מעל החור), והלחיצה עצמה (ראו _buildHomeGridV5) גם מסיימת את הסיור
  //    וגם פותחת את PlayVsPersonModeScreen עם showOnboardingIntro: true,
  //    שמציג שם הסבר נוסף על 3 המודים (ראו play_vs_person_mode_screen.dart).
  // 🆕 כרטיסיית "ברוכים הבאים" כללית - שלב 0 של ההדרכה, לפני שהספוטלייט
  // מתחיל להדגיש רכיבים ספציפיים. לא קשורה למיקום של שום רכיב במסך,
  // ולכן ממורכזת במקום "חור" בהדהוי כמו שאר שלבי הסיור.
  Widget _buildHomeTourWelcomeOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Container(color: const Color(0xCC0C0820)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 18,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                AppLocalizations.of(context)!.mainMenuSkipButton,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🐛 תוקן: "הלוגו נמצא מוזר למעלה" - בתוך Column עם
                    // crossAxisAlignment.stretch, תמונה עם width מפורש (72)
                    // עדיין נדחסת/נמתחת לרוחב המלא של הכרטיס ע"י אילוצי הרוחב
                    // ה"הדוקים" שה-Column כופה (stretch=תמיד למלא את הרוחב),
                    // כך שהלוגו יצא רצועה רחבה ומעוותת בגובה 72 בלבד, לא ריבוע
                    // מרוכז. עטפתי ב-Center + מסגרת זהב כמו בשאר האפליקציה.
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFE79A),
                              Color(0xFFC98A32),
                              Color(0xFFFFD86B),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            'assets/icon/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.mainMenuTourWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2A1740),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.mainMenuTourWelcomeBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          AudioManager.playClick();
                          setState(() => _tourWelcomeDismissed = true);
                          _ensureTourStepVisible();
                        },
                        child: Text(
                          AppLocalizations.of(context)!.mainMenuLetsStartButton,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTourOverlayV5() {
    // 🆕 עיצוב מחדש "Home v7" - שלב 1 (מתוך 2 - ראו _tourStepCount)
    // שמצביע על כפתור "שחק" המרכזי. לחיצה על הכפתור המואר (tap-through)
    // מתקדמת לשלב 2 (ראו _openModesSheetV7) ופותחת את גיליון המודים.
    final loc = AppLocalizations.of(context)!;
    return _buildTourSpotlight(
      targetKey: _tourPlayButtonKey,
      title: loc.mainMenuTourPlayButtonTitle,
      body: loc.mainMenuTourPlayButtonBody,
    );
  }

  // 🆕 ציור הספוטלייט עצמו (חור מואר מעל הרכיב + כרטיסיית הסבר) - הופרד
  // לפונקציה משותפת כדי ששני השלבים (כפתור "שחק" כאן, "שלבים" בתוך
  // _buildModesSheetV7) ישתמשו באותו ציור בדיוק, רק עם מטרה/טקסט שונים -
  // ראו _buildHomeTourOverlayV5 (שלב 1) וההפעלה הישירה ב-_buildModesSheetV7
  // (שלב 2). שני השלבים תמיד tap-through (לוחצים על הרכיב המואר עצמו
  // כדי להתקדם/לסיים - אין כפתור "הבא" נפרד).
  Widget _buildTourSpotlight({
    required GlobalKey targetKey,
    required String title,
    required String body,
    // 🩹 תוקן: כברירת מחדל מרעננים את מסך הבית עצמו (this.setState) - נכון
    // לשלב 1 (כפתור "שחק"), שהספוטלייט שלו חי בתוך ה-Stack של build() של
    // מסך הבית. אבל שלב 2 ("שלבים") חי בתוך _buildModesSheetV7, שנבנה
    // *פעם אחת* ע"י PageRouteBuilder.pageBuilder ונשאר ב-route נפרד
    // משלו (לא child אמיתי של build() כאן) - this.setState לא גורם לאותו
    // route להיבנות מחדש בכלל, אז אם הרכיב עוד לא היה מוכן בפריים
    // הראשון, הספוטלייט שם נשאר תקוע ריק לנצח. הקריאה מ-_buildModesSheetV7
    // עוטפת את עצמה ב-StatefulBuilder ומעבירה את ה-setState המקומי שלו
    // במקום זה - ראו שם.
    VoidCallback? onRetryRebuild,
  }) {
    final loc = AppLocalizations.of(context)!;

    final ctx = targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      // הרכיב עוד לא צויר בפריים הזה (למשל מיד אחרי מעבר שלב) - מתזמנים
      // רענון לפריים הבא במקום להציג ספוטלייט ללא חור בכלל.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (onRetryRebuild != null) {
          onRetryRebuild();
        } else {
          setState(() {});
        }
      });
      return const SizedBox.shrink();
    }
    final screenSize = MediaQuery.of(context).size;
    final topLeft = box.localToGlobal(Offset.zero);
    final hole = (topLeft & box.size).inflate(8);
    final showCardBelow = hole.center.dy < screenSize.height * 0.6;
    const dimColor = Color(0xCC0C0820);

    return Positioned.fill(
      child: Stack(
        children: [
          // 4 מלבנים כהים מסביב לחור (למעלה/למטה/שמאל/ימין) - משאירים
          // את שטח ה-hole עצמו לגמרי חשוף (לא מצייר שם כלום), כך שהרכיב
          // האמיתי מתחתיו גלוי לגמרי *וגם* לחיץ (אין Widget חוסם מעליו).
          // 🐛 תוקן: IgnorePointer על המלבנים האלה גרם להם *לא* לחסום
          // לחיצות (IgnorePointer = "שקוף ללחיצות", ההפך ממה שרצינו) -
          // אפשר היה ללחוץ "דרך" האזור הכהה על תוכן אמיתי מתחתיו. עכשיו
          // כל מלבן הוא GestureDetector חוסם אמיתי (בולע את הלחיצה).
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: hole.top.clamp(0, screenSize.height),
            child: GestureDetector(
              onTap: () {},
              child: Container(color: dimColor),
            ),
          ),
          Positioned(
            left: 0,
            top: hole.bottom.clamp(0, screenSize.height),
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {},
              child: Container(color: dimColor),
            ),
          ),
          Positioned(
            left: 0,
            top: hole.top,
            width: hole.left.clamp(0, screenSize.width),
            height: hole.height,
            child: GestureDetector(
              onTap: () {},
              child: Container(color: dimColor),
            ),
          ),
          Positioned(
            left: hole.right,
            top: hole.top,
            right: 0,
            height: hole.height,
            child: GestureDetector(
              onTap: () {},
              child: Container(color: dimColor),
            ),
          ),
          // מסגרת זוהרת סביב החור - מדגישה ויזואלית מה בדיוק "מואר".
          Positioned(
            left: hole.left,
            top: hole.top,
            width: hole.width,
            height: hole.height,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD86B),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 18,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                loc.mainMenuSkipButton,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            top: showCardBelow ? hole.bottom + 14 : null,
            bottom: showCardBelow ? null : (screenSize.height - hole.top + 14),
            left: 18,
            right: 18,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.4),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.mainMenuTourProgress(
                              _tourStep + 1,
                              _tourStepCount,
                            ),
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.4),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              _tourStepCount,
                              (i) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _tourStep
                                      ? const Color(0xFFFF8A3C)
                                      : Colors.black12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF2A1740),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 🩹 שני השלבים (ראו _buildTourSpotlight) תמיד
                      // tap-through - לוחצים על הרכיב המואר עצמו כדי
                      // להתקדם/לסיים, אין יותר כפתור "הבא" נפרד.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👆 ', style: TextStyle(fontSize: 15)),
                          Text(
                            loc.mainMenuTourTapHighlighted,
                            style: const TextStyle(
                              color: Color(0xFFFF8A3C),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== שורה עליונה: לפי העיצוב מחדש (Claude Design) -
  // מימין: פרופיל (שם + מקום בדירוג + אווטאר). משמאל: גלגל-שיניים
  // (הגדרות - עבר לכאן כי הוצא מסרגל הניווט התחתון) + אייקון מתנה
  // (רצף כניסה יומי - מציג נקודה אדומה כשיש פרס לא-נאסף היום). =====================
  Widget _buildTopBar() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🩹 תוקן לפי בקשה מפורשת: במקום עיגול עם האות הראשונה
                  // של השם, הלוגו האמיתי של המשחק משמש כאן כ"תמונת
                  // הפרופיל" - גם ממותג וגם פותר את "הלוגו הגדול באמצע
                  // הבית לא מתחבר" (הלוגו הגדול הוסר לגמרי, ראו למעלה).
                  // 🩹 תוקן לפי עיצוב חדש (Claude Design) - ריבוע מעוגל
                  // (כמו אייקון האפליקציה עצמו) במקום עיגול.
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFD86B).withValues(alpha: 0.7),
                        width: 1.6,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/icon/logo.png',
                        fit: BoxFit.cover,
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
                          username.isNotEmpty
                              ? username
                              : loc.mainMenuHelloFallback,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        // 🆕 לפי בקשה מפורשת - לחיצה על שורת המדליות פותחת
                        // את מסך ההישגים (achievements_screen.dart), בדיוק
                        // כמו הקישור "הישגים" שכבר קיים במסך המובילים.
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            AudioManager.playClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AchievementsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            loc.mainMenuMedalsCount(
                              _medalsEarned,
                              AchievementsService.all.length,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(username: name),
                    ),
                  );
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
    IconData? icon,
    required VoidCallback onTap,
    bool showDot = false,
    Color? ringColor,
    Gradient? gradient,
    Color?
    iconColor, // 🆕 צבע אייקון אופציונלי - כדי לבלוט קצת (למשל מתנה בזהב) בלי גרדיאנט מלא שלא מתאים לשפה העיצובית של שאר הסרגל
    // 🆕 תמונת PNG (כמו GiftIcon) במקום אייקון וקטורי - ראו app_icons.dart
    // להסבר המלא למה (אייקוני Material לא תמיד נטענים אצל המשתמש הזה).
    // כשסופק - מחליף לגמרי את ה-Icon(icon) הרגיל.
    Widget? iconWidget,
    // 🆕 תג-ספירה מספרי (לא רק נקודה) - לכפתור "משימות" בשורה העליונה
    // (ראו _buildTopBarV7), אותו עיצוב כמו ב-app_bottom_nav.dart._TabItem.
    int? badgeCount,
    // 🩹 "RIGHT OVERFLOWED BY 80 PIXELS" בצילום מסך אמיתי - השורה
    // העליונה החדשה (Home v7) דחוסה מדי מכדי ש-3 כפתורים ב-56x56 (הגודל
    // הישן, מ-עיצוב קודם) ייכנסו לצד פיל השם+אווטאר/מטבעות/אנרגיה בלי
    // לגלוש. גודל קטן יותר כברירת מחדל כאן (40, במקום ב-_buildTopBarV7
    // עצמו) כדי לא לשנות כפתורים ישנים/לא-בשימוש שעדיין קוראים לפונקציה
    // הזו בגודל המקורי.
    double size = 56,
  }) {
    assert(
      icon != null || iconWidget != null,
      '_topIconButton needs either icon or iconWidget',
    );
    return Material(
      color: gradient == null
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      shape: CircleBorder(
        side: (ringColor != null && gradient == null)
            ? BorderSide(color: ringColor.withValues(alpha: 0.7), width: 1.6)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: gradient != null
                ? [
                    BoxShadow(
                      color: const Color(0xFFF472B6).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              iconWidget ??
                  Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: (gradient != null ? 25 : 22) * (size / 56),
                  ),
              if (showDot)
                Positioned(
                  top: size * 0.11,
                  right: size * 0.11,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE11D48),
                      border: Border.all(
                        color: const Color(0xFF3A1E7B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              if (badgeCount != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF16A46F)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF120C2E),
                        width: 1.3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Color(0xFF08281C),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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

  // ===================== שורת "פילים" - רצף/אנרגיה/מטבעות =====================
  // 🩹 כמה ניסיונות עיצוב מחדש (קפסולה אחידה) גרמו למסך לא לעלות אצל
  // המשתמש בפועל, שוב ושוב, בלי שום שגיאה שניתן לאתר ב-logcat ולמרות
  // בדיקה מעמיקה (כולל עם צילומי מסך אמיתיים). חוזרים לגרסה המוכחת-
  // עובדת (3 פילים נפרדים) לפי בקשה מפורשת של המשתמש - "פשוט תחזיר
  // למסך הישן וזהו".
  Widget _buildStatsPillsRow() {
    final bool canWatchForEnergy = _energy < EnergyService.maxEnergy;
    return Row(
      children: [
        Expanded(
          child: _bigStatPill(
            icon: null,
            emoji: '🔥',
            color: const Color(0xFFFB7185),
            text: "$streak",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _bigStatPill(
            icon: Icons.bolt_rounded,
            emoji: null,
            color: const Color(0xFF7DD3FC),
            text: "$_energy/${EnergyService.maxEnergy}",
            onTap: canWatchForEnergy ? _watchAdForEnergyFromHome : null,
            showAdBadge: canWatchForEnergy,
            subtitle: (canWatchForEnergy && _energyCountdown != null)
                ? AppLocalizations.of(
                    context,
                  )!.mainMenuMoreTime(_formatMmSs(_energyCountdown!))
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _bigStatPill(
            icon: Icons.monetization_on_rounded,
            emoji: null,
            color: const Color(0xFFFFD86B),
            text: "$coins",
          ),
        ),
      ],
    );
  }

  Widget _bigStatPill({
    required IconData? icon,
    required String? emoji,
    required Color color,
    required String text,
    VoidCallback? onTap,
    bool showAdBadge =
        false, // 🆕 תג "צפה בפרסומת +X" קבוע וגלוי - ראו _buildStatsPillsRow
    String?
    subtitle, // 🆕 שורת טקסט קטנה מתחת לפיל (למשל "עוד 03:24 לאנרגיה הבאה")
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
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
            Text(
              subtitle,
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: pill,
      ),
    );
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF16A46F)],
                ),
                border: Border.all(color: const Color(0xFF120C2E), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF08281C),
                    size: 10,
                  ),
                  const SizedBox(width: 1),
                  Text(
                    "+${EnergyService.adRewardAmount}",
                    style: const TextStyle(
                      color: Color(0xFF08281C),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
  Widget _topStatPill({
    required IconData? icon,
    required Color color,
    required String text,
  }) {
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
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== כרטיס התקדמות שלבים =====================
  // 🩹 כמה ניסיונות עיצוב מחדש (תג "ממשיכים" + טבעת עגולה) גרמו למסך לא
  // לעלות אצל המשתמש בפועל, שוב ושוב, בלי שום שגיאה שניתן לאתר ב-logcat
  // ולמרות בדיקה מעמיקה (כולל עם צילומי מסך אמיתיים מהמכשיר). חוזרים
  // לגרסה המוכחת-עובדת (פס התקדמות ליניארי) לפי בקשה מפורשת של המשתמש -
  // "פשוט תחזיר למסך הישן וזהו".
  Widget _buildLevelsCard() {
    final (world, sub, count) = _worldProgress(maxLevel);
    final percent = ((sub / count) * 100).round().clamp(0, 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LevelsScreen()),
          );
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.mainMenuContinuingLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.mainMenuWorldStepLabel(_worldName(world), sub),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    "$percent%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD86B), Color(0xFFFFE7A8)],
                        ),
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
    final loc = AppLocalizations.of(context)!;
    return Row(
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
            icon: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 22,
            ),
            gradient: const [Color(0xFFEF3B5B), Color(0xFFC2163F)],
            title: loc.mainMenuPlayVsOthersTitle,
            note: loc.mainMenuDuelRaceNote,
            liveCount: () {
              final total =
                  (_duelPlayersNow ?? 0) +
                  (_racePlayersNow ?? 0) +
                  (_superdualPlayersNow ?? 0);
              return total > 0 ? total : null;
            }(),
            onTap: () async {
              AudioManager.playClick();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlayVsPersonModeScreen(username: username),
                ),
              );
              _refreshStats();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: const Icon(
              Icons.casino_rounded,
              color: Colors.white,
              size: 22,
            ),
            gradient: const [Color(0xFFA250F3), Color(0xFF732CDC)],
            title: loc.mainMenuRandomChallengeLabel,
            note: loc.mainMenuRandomNote,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LevelLoadingScreen(
                    puzzleId: 0,
                    isRandomMode: true,
                    categoryLabel: loc.mainMenuRandomChallengeLabel,
                  ),
                ),
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
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LogoRaceScreen(username: username),
            ),
          );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_racePlayersNow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
        ),
        color: const Color(0xFF123A52).withValues(alpha: 0.7),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.flag_circle_rounded,
              color: Color(0xFF0C2A3D),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mainMenuLogoRaceTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context)!.mainMenuLogoRaceSubtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.mainMenuPlayButton,
              style: const TextStyle(
                color: Color(0xFF0C2A3D),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
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
      AppNotification.show(
        context,
        AppLocalizations.of(
          context,
        )!.duelLobbyAdCooldownMsg(_formatMmSs(adCooldown)),
        type: AppNotificationType.warning,
      );
      return;
    }
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(
        context,
        AppLocalizations.of(context)!.duelLobbyNoAdAvailable,
        type: AppNotificationType.warning,
      );
      return;
    }
    AdsManager.showRewardedAd(
      onReward: () async {
        await EnergyService.addFromAd();
        if (!mounted) return;
        await _refreshEnergy();
        if (mounted)
          _showRewardDialog(
            AppLocalizations.of(
              context,
            )!.mainMenuEnergyRewardMessage(EnergyService.adRewardAmount),
          );
      },
    );
  }

  // ===================== כרטיס "אתגר יומי" (קיצור דרך מהמסך הראשי) =====================
  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 01 · בית): כרטיס כחול-כהה מלא
  // עם כפתור-פיל תכלת "שחק" צמוד לצד שמאל, כותרת+תיאור קצר במרכז/ימין,
  // ואייקון קטן בפינה הימנית-קיצונית - בלי כרטיס "בונוס X מטבעות" נפרד.
  Widget _buildDailyChallengeCard() {
    final loc = AppLocalizations.of(context)!;
    final challenge = _dailyChallenge;
    final done = challenge?.completed ?? false;
    final usedUp = challenge != null && !done && challenge.attempted;
    final dimmed = done || usedUp;
    final String subtitle = done
        ? loc.mainMenuDailyChallengeSubtitleDone
        : (usedUp
              ? loc.mainMenuDailyChallengeSubtitleUsedUp
              : loc.mainMenuDailyChallengeSubtitleDefault(
                  MissionsService.dailyChallengeLogoCount,
                ));
    // 🐛 תוקן: "לא מופיע העניין של ההתראות" - הכרטיס הזה היה onTap: null
    // (לגמרי לא לחיץ) ברגע שהאתגר כבר נוצל/הושלם היום - בדיוק המצב שבו
    // כפתור "תזכיר לי מחר" (daily_challenge_screen.dart, _buildAlreadyDone/
    // _buildUsedUp) אמור להופיע. כלומר אי אפשר היה בכלל להגיע למסך שבו
    // הכפתור קיים. עכשיו הכרטיס תמיד לחיץ (הניגוה/הדהוי נשאר ויזואלית
    // בלבד), ותווית הכפתור במצב "נוצל" משתנה מ"מחר" (משתמע לא-לחיץ)
    // ל"תזכורת" כדי לרמוז שיש עוד משהו לעשות שם.
    final String btnLabel = done
        ? loc.mainMenuDoneCheckLabel
        : (usedUp ? loc.mainMenuReminderLabel : loc.mainMenuPlayButton);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _playDailyChallenge,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B4A8F).withValues(alpha: 0.6),
            ),
            color: const Color(0xFF1E2A5A),
          ),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : (usedUp
                          ? Icons.timer_off_rounded
                          : Icons.event_note_rounded),
                color: Colors.white.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: dimmed ? 0.5 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
                    ),
                  ),
                  child: Text(
                    btnLabel,
                    style: const TextStyle(
                      color: Color(0xFF0C2A3D),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
  Widget _buildStreakDayRow({
    required int dayInCycle,
    required bool claimedToday,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        return _buildStreakDayCircle(
          dayNum: dayNum,
          dayInCycle: dayInCycle,
          claimedToday: claimedToday,
        );
      }),
    );
  }

  // 🆕 עיגול יום בודד בשורת "רצף הכניסה" - תואם למוקאפ "02 · רצף כניסה":
  // עיגול 40x40 עם כיתוב מספר יום מתחתיו. שלושה מצבים (הושלם/היום/נעול),
  // ועבור יום 7 (יום השיא) - אייקון יהלום במקום וי/מנעול רגילים.
  // 🩹 אייקון וקטורי (Icons.*) ולא אימוג'י (✓/🎁/🔒/💎) - כדי למנוע את
  // בעיית "הריבוע הריק" בפונט האימוג'י שכבר תועדה כמה פעמים באפליקציה
  // הזו (ראו app_icons.dart).
  Widget _buildStreakDayCircle({
    required int dayNum,
    required int dayInCycle,
    required bool claimedToday,
  }) {
    final bool isMilestone = dayNum == 7; // יום 7 - מארז היהלום
    final bool done =
        dayNum < dayInCycle || (dayNum == dayInCycle && claimedToday);
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
      shadows = [
        BoxShadow(
          color: const Color(0xFFFF9A3C).withValues(alpha: 0.55),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
    } else if (done) {
      icon = isMilestone ? Icons.diamond_rounded : Icons.check_rounded;
      iconColor = isMilestone
          ? const Color(0xFFFFD86B)
          : const Color(0xFF6EE7B7);
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
            color: isToday
                ? Colors.white
                : Colors.white.withValues(alpha: locked ? 0.35 : 0.7),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF3A2A6B), Color(0xFF1D0E3C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFD86B).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9A3C).withValues(alpha: 0.4),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFF2A1740),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.mainMenuStreakDayTitle(streakDay),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                claimedToday
                    ? AppLocalizations.of(context)!.mainMenuAlreadyClaimedToday
                    : AppLocalizations.of(context)!.mainMenuComeBackTomorrow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              // 🩹 שורת עיגולים במקום שורת הפילים הישנה - ראו הערה למעלה.
              _buildStreakDayRow(
                dayInCycle: dayInCycle,
                claimedToday: claimedToday,
              ),
              const SizedBox(height: 14),
              // 🆕 משפט "טיזר" למרחק ליום 7 (יום השיא/מארז היהלום) - בדיוק
              // כמו שמופיע במוקאפ. אייקון יהלום וקטורי (לא אימוג'י 💎) -
              // אותו טעם כמו כל שאר האייקונים בדיאלוג הזה.
              Builder(
                builder: (ctx) {
                  final loc = AppLocalizations.of(ctx)!;
                  final daysLeft = 7 - dayInCycle;
                  final String teaserText;
                  if (dayInCycle >= 7 && claimedToday) {
                    teaserText = loc.mainMenuDiamondWonToday;
                  } else if (dayInCycle >= 7) {
                    teaserText = loc.mainMenuDiamondTodayIsDay7;
                  } else if (daysLeft == 1) {
                    teaserText = loc.mainMenuDiamondOneDayLeft;
                  } else {
                    teaserText = loc.mainMenuDiamondDaysLeft(daysLeft);
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        teaserText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.diamond_rounded,
                        size: 13,
                        color: Color(0xFF7DD3FC),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // 🆕 כותרת "הפרס של היום" מעל שורת הפרסים - בדיוק כמו במוקאפ.
              // כרטיס ה"כוכב" (⭐ +1) שמופיע שם *לא* נכלל - ראו הערה למעלה.
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppLocalizations.of(context)!.mainMenuTodaysRewardLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if ((todayReward['energy'] ?? 0) > 0) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1E2A5A),
                          border: Border.all(
                            color: const Color(
                              0xFF7DD3FC,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '+${todayReward['energy']}',
                              style: const TextStyle(
                                color: Color(0xFF7DD3FC),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // 🩹 אייקון וקטורי (EnergyIcon) במקום אימוג'י ⚡ - ראו app_icons.dart.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.mainMenuEnergyLabel,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                        border: Border.all(
                          color: const Color(0xFFFFC64B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '+${todayReward['coins']}',
                            style: const TextStyle(
                              color: Color(0xFFFFD86B),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // 🩹 אייקון וקטורי (CoinIcon) במקום אימוג'י מטבע (🪙) - לא נתמך
                          // בפונט של חלק מהמכשירים ומוצג כריבוע ריק. ראו app_icons.dart.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.mainMenuCoinsLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE08A), Color(0xFFFF9A3C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(dialogContext),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.mainMenuCloseButton,
                            style: const TextStyle(
                              color: Color(0xFF2A1740),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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
                AppLocalizations.of(context)!.mainMenuReminderTomorrow8pm,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
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
            border: Border.all(
              color: const Color(0xFF7DD3FC).withValues(alpha: 0.4),
            ),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF38BDF8).withValues(alpha: 0.16),
                const Color(0xFF38BDF8).withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                ),
                child: const Icon(
                  Icons.smart_display_rounded,
                  color: Color(0xFF7DD3FC),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.mainMenuNeedEnergyTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.mainMenuWatchAdEnergySubtitle(
                        EnergyService.adRewardAmount,
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7DD3FC).withValues(alpha: 0.5),
                  ),
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                ),
                child: Text(
                  AppLocalizations.of(context)!.mainMenuWatchButton,
                  style: const TextStyle(
                    color: Color(0xFF7DD3FC),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
            border: Border.all(
              color: const Color(0xFF6EE7B7).withValues(alpha: 0.35),
            ),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF34D399).withValues(alpha: 0.12),
                const Color(0xFF34D399).withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF34D399).withValues(alpha: 0.22),
                ),
                child: const Icon(
                  Icons.smart_display_rounded,
                  color: Color(0xFFA7F3D0),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.mainMenuAdBonusTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _adBonusAvailable
                          ? AppLocalizations.of(
                              context,
                            )!.mainMenuWatchAdCoinsSubtitle
                          : AppLocalizations.of(
                              context,
                            )!.mainMenuAvailableAgainIn(
                              _formatHms(_adBonusRemaining),
                            ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6EE7B7).withValues(alpha: 0.5),
                  ),
                  color: const Color(
                    0xFF34D399,
                  ).withValues(alpha: _adBonusAvailable ? 0.18 : 0.07),
                ),
                child: Text(
                  _adBonusAvailable
                      ? AppLocalizations.of(context)!.mainMenuWatchButton
                      : AppLocalizations.of(context)!.mainMenuWaitingLabel,
                  style: TextStyle(
                    color: _adBonusAvailable
                        ? const Color(0xFFA7F3D0)
                        : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
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
            border: Border.all(
              color: const Color(0xFF6EE7B7).withValues(alpha: 0.35),
            ),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF34D399).withValues(alpha: 0.12),
                const Color(0xFF34D399).withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF34D399).withValues(alpha: 0.22),
                ),
                child: const Icon(
                  Icons.smart_display_rounded,
                  color: Color(0xFFA7F3D0),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.mainMenuAdBonusTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _adBonusAvailable
                          ? AppLocalizations.of(
                              context,
                            )!.mainMenuWatchAdCoinsSubtitle
                          : AppLocalizations.of(
                              context,
                            )!.mainMenuAvailableAgainIn(
                              _formatHms(_adBonusRemaining),
                            ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6EE7B7).withValues(alpha: 0.5),
                  ),
                  color: const Color(
                    0xFF34D399,
                  ).withValues(alpha: _adBonusAvailable ? 0.18 : 0.07),
                ),
                child: _collectingAdBonus
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFA7F3D0),
                        ),
                      )
                    : Text(
                        _adBonusAvailable
                            ? AppLocalizations.of(context)!.mainMenuWatchButton
                            : AppLocalizations.of(
                                context,
                              )!.mainMenuWaitingLabel2,
                        style: TextStyle(
                          color: const Color(
                            0xFFA7F3D0,
                          ).withValues(alpha: _adBonusAvailable ? 1 : 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
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
  // 🩹 תוקן שוב לפי בקשה מפורשת ("משהו בלוגו לא מתחבר") - הלוגו החדש
  // בלי שום מסגרת נראה שטוח/תלוש מהרקע הסגול (הרקע שלו דומה מדי לרקע
  // המסך, אין ניגודיות). הוספתי זוהר זהוב רך מאחוריו + מסגרת זהובה דקה -
  // בדיוק אותו טיפול עיצובי כמו כרטיס הלוגו במסך הטעינה (app_loading_screen.dart)
  // - כך שהלוגו "בולט" וקופץ מהרקע במקום להיטמע בו, ויש עקביות ויזואלית
  // בין שני המסכים.
  Widget _buildLogoHero() {
    return _FloatHero(
      child: Builder(
        builder: (context) {
          // 🩹 תוקן: היה 0.56 עם מינימום 210 - יצא לוגו ענק שתפס כמעט את
          // כל רוחב המסך. במוקאפ (מסך 01 · בית) הלוגו הוא בגודל "אייקון"
          // בינוני, בערך שליש מרוחב המסך - לא הירו-אלמנט דומיננטי.
          final double size = (MediaQuery.of(context).size.width * 0.34).clamp(
            130.0,
            170.0,
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 1.5,
                height: size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFB24D).withValues(alpha: 0.35),
                      const Color(0xFFFFB24D).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE79A),
                      Color(0xFFC98A32),
                      Color(0xFFFFD86B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(size * 0.2),
                  child: Image.asset('assets/icon/logo.png', fit: BoxFit.cover),
                ),
              ),
            ],
          );
        },
      ),
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
  static const String _iosStoreLink =
      "https://apps.apple.com/au/app/%D7%96%D7%94%D7%94-%D7%90%D7%AA-%D7%94%D7%9C%D7%95%D7%92%D7%95/id6797976197";
  static const String _androidStoreLink =
      "https://play.google.com/store/apps/details?id=com.ofeksela.zehethalogo&hl=he";

  Future<void> _inviteFriends() async {
    final loc = AppLocalizations.of(context)!;
    final String text = loc.mainMenuInviteShareText(
      _iosStoreLink,
      _androidStoreLink,
    );
    try {
      // 🐛 תוקן: "באייפון שיתוף כותב שאי אפשר לשתף" - חסר sharePositionOrigin
      // (נקודת העיגון של ה-popover ב-iOS, ראו share_helper.dart להסבר המלא).
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        text,
        subject: loc.appLoadingTitle,
        sharePositionOrigin: box != null
            ? (box.localToGlobal(Offset.zero) & box.size)
            : null,
      );
    } catch (_) {
      if (mounted) _showShareFallback(text);
    }
  }

  void _showShareFallback(String text) {
    AppNotification.show(
      context,
      AppLocalizations.of(context)!.friendChallengeNoShareAppFallback(text),
      duration: const Duration(seconds: 5),
    );
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
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
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
    if (widget.initialName.trim().isNotEmpty)
      _status = _NameCheckStatus.available;
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
      final taken = await LeaderboardService.isNameTaken(
        trimmed,
        excludeDeviceId: _myDeviceId,
      );
      if (!mounted) return;
      // ⚠️ בודקים שהטקסט לא השתנה בינתיים (המשתמש המשיך להקליד) - כדי
      // שתוצאה איטית של בקשה ישנה לא "תדרוס" תוצאה עדכנית יותר.
      if (_controller.text.trim() != trimmed) return;
      setState(
        () => _status = taken
            ? _NameCheckStatus.taken
            : _NameCheckStatus.available,
      );
    });
  }

  Future<void> _onConfirm() async {
    final name = _controller.text.trim();
    if (name.isEmpty ||
        _status == _NameCheckStatus.taken ||
        _status == _NameCheckStatus.checking ||
        _saving)
      return;
    setState(() => _saving = true);
    // בדיקה אחרונה וסופית ממש לפני השמירה - מונעת מקרה קצה נדיר שבו שני
    // שחקנים "תפסו" בו-זמנית את אותו השם בין הבדיקה האחרונה לשמירה.
    final taken = await LeaderboardService.isNameTaken(
      name,
      excludeDeviceId: _myDeviceId,
    );
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFBE50).withValues(alpha: 0.35),
                    const Color(0xFFFFBE50).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  "?",
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF2A1740),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // גלולת קלט השם - גבול בגרדיאנט זהב, כמו במוקאפ
        Container(
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD86B).withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              color: const Color(0xFF170F38).withValues(alpha: 0.9),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 12,
                    textAlign: TextAlign.center,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _onConfirm(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      hintText: AppLocalizations.of(context)!.mainMenuNameHint,
                      hintStyle: const TextStyle(
                        color: Colors.white30,
                        fontSize: 15,
                      ),
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
              opacity:
                  (_status == _NameCheckStatus.taken ||
                      _controller.text.trim().isEmpty)
                  ? 0.45
                  : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFE08A),
                      Color(0xFFFFB24D),
                      Color(0xFFFF8A3C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF2A1740),
                          ),
                        )
                      : Text(
                          widget.confirmLabel,
                          style: const TextStyle(
                            color: Color(0xFF2A1740),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),

        if (widget.showCancel) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.duelLobbyCancelButton,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          icon: const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFD86B),
            ),
          ),
          text: AppLocalizations.of(context)!.mainMenuCheckingAvailability,
          textColor: Colors.white.withValues(alpha: 0.55),
          borderColor: Colors.white.withValues(alpha: 0.14),
          bgColor: Colors.white.withValues(alpha: 0.05),
        );
      case _NameCheckStatus.available:
        return _statusRow(
          icon: const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: Color(0xFF6EE7B7),
          ),
          text: AppLocalizations.of(context)!.mainMenuNameAvailable,
          textColor: const Color(0xFFA7F3D0),
          borderColor: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
          bgColor: const Color(0xFF34D399).withValues(alpha: 0.1),
        );
      case _NameCheckStatus.taken:
        return _statusRow(
          icon: const Icon(
            Icons.cancel_rounded,
            size: 15,
            color: Color(0xFFFB7185),
          ),
          text: AppLocalizations.of(context)!.mainMenuNameTaken,
          textColor: const Color(0xFFFFC9D1),
          borderColor: const Color(0xFFFB7185).withValues(alpha: 0.4),
          bgColor: const Color(0xFFFB7185).withValues(alpha: 0.1),
        );
    }
  }

  Widget _statusRow({
    required Widget icon,
    required String text,
    required Color textColor,
    required Color borderColor,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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

class _FloatHeroState extends State<_FloatHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
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
                colors: [
                  Color(0xFF34186E),
                  Color(0xFF3A1B78),
                  Color(0xFF241154),
                  Color(0xFF120C2E),
                ],
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
            Positioned(
              top: 90 + drift(0),
              left: -18,
              child: Text(
                "?",
                style: TextStyle(
                  fontSize: 150,
                  color: Colors.white.withValues(alpha: 0.045),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              bottom: 190 + drift(0.4),
              right: -14,
              child: Text(
                "?",
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white.withValues(alpha: 0.045),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.5,
              right: 30 + drift(0.7),
              child: Text(
                "?",
                style: TextStyle(
                  fontSize: 90,
                  color: Colors.white.withValues(alpha: 0.04),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              top: 130,
              right: 40,
              child: _Twinkle(controller: controller, phase: 0),
            ),
            Positioned(
              top: size.height * 0.4,
              left: 36,
              child: _Twinkle(
                controller: controller,
                phase: 0.4,
                color: const Color(0xFFFFD86B),
              ),
            ),
            Positioned(
              bottom: 150,
              right: 66,
              child: _Twinkle(
                controller: controller,
                phase: 0.75,
                color: const Color(0xFFA5F3FC),
              ),
            ),
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
  const _Twinkle({
    required this.controller,
    required this.phase,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = (sin((controller.value + phase) * 2 * pi) + 1) / 2;
        return Opacity(
          opacity: 0.18 + v * 0.52,
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
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

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$liveCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.28),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 3),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
