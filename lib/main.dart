import 'dart:async'; // 🆕 StreamSubscription/Timer - הזמנות חברים נכנסות + פעימת נוכחות
import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter; // 🆕 טשטוש (BackdropFilter) למסך "פרטיות" ברקע
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 🔒 תיקון אבטחה - ראו הערה מפורטת ליד _activateAppCheck
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🆕 קריאת שם המשתמש כשמקבלים הזמנת חבר נכנסת
import 'main_menu_screen.dart';
import 'ads_manager.dart';
import 'iap_manager.dart';
import 'referral_service.dart';
import 'audio_manager.dart';
import 'leaderboard.dart';
import 'player_sync.dart';
import 'friend_service.dart'; // 🆕 "החברים שלי" - פעימת נוכחות ("מחובר") + הזמנות דו-קרב נכנסות
import 'friend_challenge_screen.dart'; // 🆕 מסך קבלת הזמנה נכנסת מחבר
import 'duel_service.dart'; // 🆕 declineInvite - מודיעים למזמין בזמן אמת שההזמנה נדחתה
import 'logo_race_service.dart'; // 🆕 הזמנות חברים נכנסות עכשיו יכולות להיות גם למרוץ, לא רק לדו-קרב
import 'energy_service.dart'; // 🆕 דיאלוג "הזמנה מחבר" מציג כמה אנרגיה יש למשתמש
import 'notification_manager.dart';
import 'game_settings.dart'; // 🆕 העדפות משחק קטנות (למשל "אישור לפני קניית רמז") - טאב "משחק" בהגדרות
import 'notification_service.dart'; // 🆕 התראות מקומיות: אנרגיה מלאה, משימות חדשות, חזרה למשחק
import 'push_notification_service.dart'; // 🆕 Push (FCM) - שידורים ידניים/אוטומטיים מהשרת
import 'meta_events_service.dart'; // 🆕 מעקב פרסומות Meta (פייסבוק/אינסטגרם)
import 'screenshot_guard_service.dart'; // 🆕 זיהוי צילום/הקלטת מסך (iOS בלבד)
import 'update_checker.dart';
import 'update_required_screen.dart';
import 'app_notification.dart';
import 'reward_popups.dart';
import 'active_match_service.dart'; // 🆕 "חזרה למשחק" - זיהוי דו-קרב/מרוץ פעיל בפתיחת האפליקציה
import 'duel_room_screen.dart';
import 'logo_race_screen.dart';
import 'device_id.dart';
import 'app_loading_screen.dart'; // 🆕 מסך הטעינה החדש בזמן _checking (ראו AppRootGate)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'locale_controller.dart'; // 🆕 שפת האפליקציה (עברית/אנגלית) - ראו LocaleController

// 🍎 App Tracking Transparency (ATT) - חובה של אפל: כל אפליקציה שמשתמשת
// ב-IDFA לצורך פרסומות ממוקדות (וזה בדיוק מה ש-Google Mobile Ads/AdMob
// עושה) חייבת קודם לבקש מהמשתמש רשות מפורשת עם חלון המערכת המובנה של
// אפל, לפני שהיא ניגשת ל-IDFA. בלי זה - אפל דוחה את האפליקציה ב-Review
// (Guideline 5.1.2, "Data Use and Sharing"). ב-Android אין דבר כזה (לא
// רלוונטי), ולכן זה רץ רק ב-iOS.
// ⚠️ דורש הוספה ל-pubspec.yaml:
//   dependencies:
//     app_tracking_transparency: ^2.0.6
// וגם הוספת מפתח ל-Info.plist (ב-Xcode, לא בקוד Dart) - ראו הסבר מלא
// שנשלח בנפרד בצ'אט, כי את זה אי אפשר לערוך מכאן.
//
// 🩹 תוקן (דחיית אפל 1.2.0, Guideline 2.1: "unable to locate the App
// Tracking Transparency permission request ... iPadOS 27"): הבקשה רצה קודם
// ב-main() *לפני* runApp - כלומר לפני שיש בכלל מסך והאפליקציה "פעילה" -
// ובגרסאות iOS/iPadOS החדשות בקשה כזו נבלעת בשקט בלי להציג חלון. עכשיו
// היא נקראת רק אחרי הפריים הראשון, מחכה שהאפליקציה תהיה במצב resumed, ואם
// החלון עדיין לא הוצג (הסטטוס נשאר notDetermined) מנסה פעם נוספת.
Future<void> _waitForAppActive() async {
  for (var i = 0; i < 20; i++) {
    final s = WidgetsBinding.instance.lifecycleState;
    if (s == null || s == AppLifecycleState.resumed) return;
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

Future<void> _requestTrackingIfNeeded() async {
  if (!Platform.isIOS) return; // רלוונטי רק ב-iOS
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;
    await _waitForAppActive();
    await Future.delayed(const Duration(milliseconds: 1000));
    final result = await AppTrackingTransparency.requestTrackingAuthorization();
    if (result == TrackingStatus.notDetermined) {
      await _waitForAppActive();
      await Future.delayed(const Duration(seconds: 2));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    debugPrint('ATT request error: $e');
  }
}

/// ATT קודם, ורק אחריו כל מה שעלול לעקוב (AdMob, Meta) - אחרי הפריים הראשון.
Future<void> _initTrackingAndAds() async {
  await _requestTrackingIfNeeded();
  try {
    await AdsManager.init();
  } catch (e) {
    debugPrint('שגיאת אתחול AdsManager: $e');
  }
  try {
    await MetaEventsService.init();
  } catch (e) {
    debugPrint('שגיאת אתחול MetaEventsService: $e');
  }
}

// 🔒 תיקון אבטחה קריטי - "חבר בדק ומצא שאפשר לכתוב ל-Firestore ישירות
// עם ה-API של הפרויקט, בלי לעבור דרך האפליקציה בכלל (שינה XP/שם וכו')".
// זה קרה כי חוקי האבטחה של Firestore היום פתוחים ("if true") כמעט
// בכל מקום - זה בכוונה, כי לאפליקציה הזו אין Firebase Auth אמיתי (רק
// deviceId), אז אין דרך היום להבדיל "בקשה מהאפליקציה האמיתית" מ"בקשה
// מסקריפט חיצוני שמכיר את ה-API key". App Check הוא בדיוק הפתרון לזה:
// הוא נותן לכל בקשה שיוצאת מהאפליקציה "אישור" חתום שמוכיח שהיא באמת
// יצאה מהתקנה אמיתית של האפליקציה הזו (Play Integrity באנדרואיד /
// DeviceCheck+App Attest באייפון) - ולא מכלי חיצוני (Postman/סקריפט/
// curl) שרק מכיר את מפתח ה-API (שהוא ממילא לא סוד - זה תקין ומוכר
// שמפתחות Firebase לצד הלקוח גלויים, האבטחה האמיתית תמיד אמורה להיות
// בחוקי Firestore + App Check, לא בהסתרת המפתח).
// ⚠️ שלבים שאני לא יכול לבצע מכאן (אין לי גישה לפרויקט Firebase/למחשב
// שלך) - חובה לעשות את זה בעצמך, בדיוק לפי הסדר הזה:
//   1. להוסיף ל-pubspec.yaml: firebase_app_check: ^0.3.1 (או הגרסה
//      התואמת לשאר חבילות ה-Firebase שלך - `flutter pub outdated`
//      יראה לך) ואז להריץ flutter pub get.
//   2. במסוף Firebase (console.firebase.google.com) -> הפרויקט
//      zehe-et-halogo -> App Check -> לרשום את שני האפליקציות (Android
//      עם ספק Play Integrity, iOS עם ספק App Attest/DeviceCheck).
//   3. חשוב מאוד - שלבי הפעלה: קודם מפיצים גרסה חדשה עם הקוד הזה
//      לכל המשתמשים (חנויות האפליקציות) ומחכים כמה ימים שרוב המשתמשים
//      יעדכנו. *רק אחרי זה* עוברים במסוף App Check ממצב "Unenforced"
//      ל-"Enforced" לכל שירות (Firestore וכו'). אם תפעיל Enforced *לפני*
//      שהמשתמשים עדכנו לגרסה הזו - כל מי שעדיין על הגרסה הישנה יאבד
//      גישה לגמרי (הבקשות שלו ייחסמו, כי אין לו את הטוקן).
//   4. לבדיקות פיתוח (סימולטור/אמולטור, שלא עוברים את Play
//      Integrity/App Attest אמיתי) - תצטרך "debug token": ריצה ראשונה
//      תדפיס בקונסולה שורה עם הטוקן, מוסיפים אותו במסוף App Check תחת
//      "Manage debug tokens".
// אחרי שזה יופעל ב-Enforced - חוקי ה-Firestore (firestore.rules, כבר
// עודכן) ידחו אוטומטית כל בקשה בלי טוקן App Check תקין, כולל בדיוק
// התרחיש שהחבר שלך הדגים (סקריפט חיצוני עם ה-API key בלבד).
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('שגיאת אתחול App Check: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🆕 נעילת כיוון המסך לפורטרט בלבד - האפליקציה כולה לא מותאמת ל-
  // לנדסקייפ (לפי בקשה מפורשת). חייב לרוץ לפני runApp כדי שהנעילה
  // תיכנס לתוקף כבר מהפריים הראשון ולא רק אחרי שהמשתמש כבר הספיק לסובב.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // 🍎 בקשת ATT + אתחול AdMob/Meta עברו ל-_initTrackingAndAds, שנקרא אחרי
  // הפריים הראשון (ראו runApp למטה) - לא כאן, לפני שיש מסך.
  // 🔥 אתחול Firebase (חובה לפני כל שימוש ב-Firestore) - עטוף ב-try/catch
  // כדי שכשל בחיבור לא ימנע פתיחת המשחק, בדיוק כמו שאר האתחולים כאן.
  try {
    await Firebase.initializeApp();
    await _activateAppCheck(); // 🔒 ראו הערה מפורטת למעלה - תיקון אבטחה
    // מעביר פעם אחת בלבד (לכל הפרויקט, לא לכל מכשיר) את השחקנים
    // הקיימים מהגיליון הישן של Google ל-Firestore. בטוח להרצה חוזרת -
    // אם ההעברה כבר בוצעה היא פשוט לא עושה כלום.
    LeaderboardService.migrateFromSheetsIfNeeded();
  } catch (e) {
    debugPrint('שגיאת אתחול Firebase: $e');
  }
  // אתחול מערכת הפרסומות, הרכישות והקליק ברקע.
  // כל אחד עטוף ב-try/catch פנימי, כך ששגיאה באחד לא תמנע
  // את פתיחת האפליקציה — חשוב במיוחד ב-iPad ובמכשירים שבהם
  // AdMob או IAP עשויים להיכשל (למשל בסביבת review של אפל).
  await IapManager.init();
  // 🆕 "מביאים חבר חדש למשחק" - הבדיקה עצמה (ReferralService.checkForReferral)
  // עברה ל-AppLifecycleManager.initState, כי כדי להציג פופאפ "קיבלת X
  // מטבעות!" יפה (לא רק לזכות בשקט) צריך BuildContext/Navigator שעדיין
  // לא קיים כאן, לפני runApp().
  await NotificationManager.init(); // 🔔 התראות מקומיות (תזכורת בונוס מטבעות)
  await GameSettings.loadSettings(); // 🆕 העדפות משחק קטנות (אישור לפני קניית רמז וכו')
  // 🆕 היו קיימים כבר בקוד (energy_service.dart קורא להם) אבל בלי
  // האתחול הזה הם היו no-op שקט לגמרי - שום התראת "אנרגיה מלאה" או
  // "חזרה למשחק" לא באמת נשלחה עד עכשיו. עטופים ב-try/catch כמו כל
  // שאר האתחולים כאן, כדי שכשל בהרשאת התראות לא ימנע פתיחת המשחק.
  try {
    await NotificationService.init(); // 🔔 אנרגיה מלאה / משימות חדשות / חזרה למשחק
    await NotificationService.scheduleComeBackReminders();
  } catch (e) {
    debugPrint('שגיאת אתחול NotificationService: $e');
  }
  // 🆕 Push (FCM) - שומר טוקן לכל מכשיר ב-Firestore (players/{deviceId}.fcmToken)
  // כדי שאפשר יהיה לשלוח התראות ידניות (Firebase Console -> Engage ->
  // Messaging) או אוטומטיות (Cloud Functions, ראה cloud_functions_notifications_snippet.js).
  try {
    await PushNotificationService.init();
  } catch (e) {
    debugPrint('שגיאת אתחול PushNotificationService: $e');
  }
  // 🆕 מעקב פרסומות Meta (פייסבוק/אינסטגרם) - ראו meta_events_service.dart
  // להסבר המלא ולשלבי ההגדרה הידניים הנדרשים (App ID/Client Token).
  // בלי ההגדרה הידנית הזו, הקריאה כאן לא תעשה כלום בפועל - אבל גם לא
  // תקריס כלום, בדיוק כמו שאר האתחולים.
  // 🆕 זיהוי צילום/הקלטת מסך (ראו screenshot_guard_service.dart) - לא
  // עושה כלום באנדרואיד (שם כבר יש FLAG_SECURE, הרבה יותר חזק). לא
  // דורש try/catch - הפונקציה עצמה בטוחה לגמרי גם בלי ההגדרה הידנית
  // הנדרשת ב-iOS (ראו קובץ ההוראות הנפרד).
  ScreenshotGuardService.init();
  // כשמזהים צילום מסך בפועל (רק iOS, אחרי המעשה - ראו ההסבר בקובץ
  // השירות) - מציגים הודעת אזהרה קצרה למשתמש דרך ה-navigatorKey
  // הגלובלי, כי אין כאן BuildContext ישיר לשירות עצמו.
  ScreenshotGuardService.onScreenshotTaken = () {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    AppNotification.show(ctx, AppLocalizations.of(ctx)!.mainScreenshotWarning, type: AppNotificationType.warning, duration: const Duration(seconds: 4));
  };
  AudioManager.warmUpClick(); // כדי שגם הלחיצה הראשונה תהיה מיידית
  await localeController.init(); // 🆕 טוען את שפת האפליקציה (שמורה, או שפת המכשיר בריצה ראשונה) לפני runApp
  runApp(const AppRoot());
  WidgetsBinding.instance.addPostFrameCallback((_) => _initTrackingAndAds());
}

// 🆕 עטיפה דקה מעל MaterialApp כדי שהחלפת שפה ב-LocaleController (ראו
// locale_controller.dart) תפעיל רינדור מחדש של כל האפליקציה - MaterialApp
// עצמו היה עובר קודם ל-runApp ישירות, בלי שום State שיכול להגיב לשינוי שפה.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    localeController.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    localeController.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      locale: localeController.locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 🆕 תמיכה בטאבלטים/אייפדים: כל המסכים עוצבו למידות טלפון (רוב
      // הקוד מניח ~380-430dp רוחב, כולל חישובי מיקום מוחלטים לפי
      // MediaQuery.of(context).size.width, לא רק LayoutBuilder יחסי).
      // במקום לעצב מחדש כל מסך, "ממסגרים" את כל האפליקציה לרוחב טלפון
      // קבוע וממורכזים אותה על מסכים רחבים (טאבלט/אייפד/דסקטופ) - בדיוק
      // כמו שרוב האפליקציות הפופולריות בסגנון טלפון מתנהגות באייפד.
      // ה-MediaQuery המדווח כלפי פנים גם מתוקן לאותו רוחב מצומצם, כך
      // שחישובי מיקום מוחלטים (למשל Positioned לפי size.width/2) ימשיכו
      // להיות נכונים בתוך המסגרת, ולא יניחו את הרוחב המלא והשגוי של הטאבלט.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        const double phoneMaxWidth = 520;
        if (mq.size.width <= phoneMaxWidth) return child;
        return Container(
          color: const Color(0xFF0B0818),
          alignment: Alignment.center,
          child: SizedBox(
            width: phoneMaxWidth,
            height: mq.size.height,
            child: MediaQuery(
              data: mq.copyWith(size: Size(phoneMaxWidth, mq.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
      home: const AppLifecycleManager(child: AppRootGate()),
    );
  }
}

// 🆕 מפתח ניווט גלובלי - כדי שאפשר יהיה להציג SnackBar/דיאלוג (למשל
// אזהרת צילום מסך למעלה) מקוד שרץ מחוץ לעץ ה-Widgets (כמו callback
// שמגיע מ-native דרך MethodChannel), שאין לו BuildContext משלו.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// שער הכניסה לאפליקציה: לפני שמציגים את התפריט הראשי, בודקים מול
/// Firestore (ראה update_checker.dart) אם הגרסה המותקנת נמוכה מדי ודורשת
/// עדכון חובה. אם כן - מוצג מסך חסימה שלא ניתן לעקוף. אם אין אינטרנט
/// או שיש שגיאה - לא חוסמים את המשתמש (checkForRequiredUpdate מחזיר null).
class AppRootGate extends StatefulWidget {
  const AppRootGate({super.key});

  @override
  State<AppRootGate> createState() => _AppRootGateState();
}

class _AppRootGateState extends State<AppRootGate> {
  bool _checking = true;
  Map<String, String>? _blockInfo;
  // 🆕 "חזרה למשחק" - ראו ההסבר המלא ב-active_match_service.dart ו-
  // _checkResumeMatch למטה. null = אין משחק לחזור אליו (המקרה הרגיל).
  Widget? _resumeScreen;

  // 🆕 התקדמות/סטטוס *אמיתיים* של מסך הטעינה (app_loading_screen.dart) -
  // מתעדכנים כאן, בכל שלב בפועל של _runCheck, לא מספרים מומצאים. ראו
  // ההערה המלאה ב-app_loading_screen.dart למה זה תוקן ככה.
  final ValueNotifier<double> _loadProgress = ValueNotifier(0.05);
  final ValueNotifier<String> _loadStatus = ValueNotifier('');
  bool _startedCheck = false; // 🐛 ראו didChangeDependencies - מונע הרצה כפולה

  // 🐛 תוקן: AppLocalizations.of(context) נקרא פעם קודם בתוך initState()
  // (ישירות, ועוד פעם בעקיפין כברירת ה-await הראשונה של _runCheck, שנקראה
  // גם היא מ-initState) - זה קרס עם "dependOnInheritedWidgetOfExactType...
  // was called before _AppRootGateState.initState() completed", כי בשלב
  // initState() ה-Localizations (InheritedWidget) עדיין לא זמין ל-context
  // הזה. didChangeDependencies() נקרא תמיד מיד אחרי initState(), ברגע שבו
  // ה-InheritedWidgets כבר זמינים - בדיוק הזמן הנכון לקריאה הראשונה הזו.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedCheck) return;
    _startedCheck = true;
    _loadStatus.value = AppLocalizations.of(context)!.mainCheckingVersion;
    _runCheck();
  }

  @override
  void dispose() {
    _loadProgress.dispose();
    _loadStatus.dispose();
    super.dispose();
  }

  // 🩹 תוקן: "האחוזים לא עולים" - הבדיקות האמיתיות (checkForRequiredUpdate/
  // _checkResumeMatch) מסתיימות לפעמים כל כך מהר (רשת/מטמון מהירים) שה-
  // State כולו עובר מ-5% ל-100% תוך פחות מפריים אחד - לא "לא עולה", אלא
  // עולה כל כך מהר שאי אפשר לראות את זה בעין. התיקון *לא* מחזיר התקדמות
  // מזויפת (אין לולאה/טיימר שרץ בלי קשר למצב האמיתי) - כל ערך כאן עדיין
  // משקף שלב אמיתי שבאמת הסתיים, רק עם רווח קצר מינימלי בין שלב לשלב כדי
  // שהעין תספיק לקלוט את העלייה, בדיוק כמו שרוב האפליקציות עושות למסכי
  // פתיחה (אם הבדיקה האמיתית איטית מהרווח הזה - היא זו שקובעת את הקצב,
  // לא ההפך).
  static const _minStepGap = Duration(milliseconds: 220);

  Future<void> _pacedProgress(double value, String status) async {
    _loadStatus.value = status;
    _loadProgress.value = value;
    await Future.delayed(_minStepGap);
  }

  Future<void> _runCheck() async {
    final loc = AppLocalizations.of(context)!;
    await _pacedProgress(0.12, loc.mainConnectingToServer);
    final result = await UpdateChecker.checkForRequiredUpdate();
    await _pacedProgress(0.5, loc.mainCheckingVersion);
    // 🆕 בודקים "חזרה למשחק" רק אם אין חסימת גרסה - אין טעם להכניס שחקן
    // ישר לתוך דו-קרב/מרוץ שהוא ממילא ייחסם תוך שנייה על ידי UpdateRequiredScreen.
    if (result == null) {
      _loadStatus.value = loc.mainCheckingActiveGame;
      await _checkResumeMatch();
    }
    await _pacedProgress(0.9, loc.mainAlmostReady);
    _loadProgress.value = 1.0;
    _loadStatus.value = loc.mainReady;
    await Future.delayed(_minStepGap);
    if (!mounted) return;
    setState(() {
      _blockInfo = result;
      _checking = false;
    });
  }

  // 🆕 "המערכת צריכה לזהות שהטלפון היה במשחק ולהכניס אותו ישר" - בודק
  // אם יש מצביע מקומי למשחק פעיל (ראו active_match_service.dart), ואם
  // כן - מוודא מול Firestore שהמשחק עדיין 'playing' באמת (לא הוכרע כבר
  // בינתיים, למשל על ידי ניצחון טכני של היריב בזמן שהיינו מנותקים) לפני
  // שממש קופצים ישר לתוכו. אם משהו לא תקין (המשחק נגמר/נמחק/לא נמצא) -
  // פשוט מנקים את המצביע וממשיכים כרגיל למסך הבית, בלי שגיאה.
  Future<void> _checkResumeMatch() async {
    try {
      final pending = await ActiveMatchService.get();
      if (pending == null) return;
      final myDeviceId = await DeviceId.get();
      final collection = pending.type == ActiveMatchType.duel ? 'duels' : 'logoRaces';
      final doc = await FirebaseFirestore.instance.collection(collection).doc(pending.matchId).get();
      final data = doc.data();
      if (data == null || data['status'] != 'playing') {
        await ActiveMatchService.clear();
        return;
      }
      final player1Id = data['player1Id'] as String?;
      final player2Id = data['player2Id'] as String?;
      if (myDeviceId != player1Id && myDeviceId != player2Id) {
        await ActiveMatchService.clear();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      _resumeScreen = pending.type == ActiveMatchType.duel
          ? DuelRoomScreen(matchId: pending.matchId, myDeviceId: myDeviceId, myUsername: username)
          : LogoRaceScreen(username: username, initialRaceId: pending.matchId);
    } catch (_) {
      // לא קריטי - אם משהו נכשל (בעיית רשת וכו') פשוט ממשיכים למסך הבית הרגיל.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return AppLoadingScreen(progress: _loadProgress, status: _loadStatus);
    }
    if (_blockInfo != null) {
      return UpdateRequiredScreen(
        message: _blockInfo!['message'] ?? '',
        storeUrlAndroid: _blockInfo!['storeUrlAndroid'] ?? '',
        storeUrlIos: _blockInfo!['storeUrlIos'] ?? '',
        currentVersion: _blockInfo!['currentVersion'] ?? '',
        minVersion: _blockInfo!['minVersion'] ?? '',
      );
    }
    return _resumeScreen ?? const MainMenuScreen();
  }
}

/// עוטף את כל האפליקציה ומאזין למצב שלה (פתוחה/ברקע). ברגע שהמשתמש
/// ממזער, מחליק לאפליקציה אחרת, או נועל את המסך - המוזיקה נעצרת, וגם
/// מוצג מסך "טשטוש" מעל כל התוכן (ראו _obscured למטה) - כדי שבתצוגה
/// המקדימה של החלפת אפליקציות (Recents/App Switcher) ובזמן שהאפליקציה
/// ברקע, לא יהיה אפשר לראות/לצלם את הלוגו שבודקים כרגע ולהעביר אותו
/// בצ'אט לחברים. כשחוזרים לאפליקציה - המוזיקה ממשיכה והטשטוש יורד מיד.
///
/// ⚠️ הגבלה חשובה שכדאי שתדע עליה: זה מטשטש את מה שרואים בזמן החלפת
/// אפליקציות/ברקע, אבל זה *לא* חוסם צילום מסך אקטיבי בזמן שהאפליקציה
/// פתוחה ובשימוש - Flutter/Dart טהור לא יכול לעשות את זה. אם אתה רוצה
/// גם לחסום ממש צילומי מסך:
///   - Android: אפשר לגמרי, אבל דורש שינוי קוד native קטן (לא Flutter) -
///     שלחתי לך בנפרד קובץ הוראות (android_flag_secure_instructions.txt)
///     עם השורה המדויקת להוסיף ל-MainActivity.
///   - iOS: אפל בכוונה **לא מאפשרת** לשום אפליקציה לחסום צילום מסך בכלל
///     (מגבלת מערכת הפעלה, לא מגבלה טכנית שלי) - אפשר לכל היותר *לזהות*
///     שצולם צילום מסך אחרי שזה כבר קרה ולהראות אזהרה, אבל לא למנוע את
///     הצילום עצמו. אם תרצה גם את זה, תגיד ואני אוסיף.
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  // 🆕 true = מציגים את מסך הטשטוש מעל הכול (בזמן שהאפליקציה לא פעילה/ברקע)
  bool _obscured = false;

  // 🆕 "החברים שלי" (friend_service.dart) - ראו _startFriendPresenceAndInvites.
  StreamSubscription<Map<String, dynamic>?>? _incomingInviteSub;
  Timer? _presenceTimer;
  bool _showingIncomingInviteDialog = false;
  String? _shownInviteCode;
  BuildContext? _inviteDialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 🔴 מאזין בזמן אמת לאיפוס/עדכון מטבעות מרחוק (ראה player_sync.dart) -
    // נשאר פתוח לאורך כל חיי האפליקציה כדי שהשינוי "יתפוס" מיד, גם אם
    // השחקן כבר באמצע משחק, ולא רק בפעם הבאה שהוא פותח את האפליקציה.
    PlayerSyncService.startListening();
    _startFriendPresenceAndInvites();
    // 🆕 "קיבלת X מטבעות כי הורדת דרך ההזמנה של Y!" - צד המותקן החדש.
    _checkReferralAndShowPopup();
    // 🆕 "קיבלת X מטבעות! חבר הצטרף למשחק" - צד המזמין (מגיע מאוחר יותר,
    // כשה-listener החי ב-player_sync.dart קולט pendingBonusCoins).
    PlayerSyncService.referralBonusReceived.addListener(_onReferralBonusReceived);
  }

  Future<void> _checkReferralAndShowPopup() async {
    final result = await ReferralService.checkForReferral();
    if (result == null || !mounted) return;
    final subtitle = AppLocalizations.of(context)!.mainReferralDownloadedSubtitle(result.referrerName);
    final prefs = await SharedPreferences.getInstance();
    final currentCoins = prefs.getInt('coins') ?? 15;
    if (!mounted) return;
    _showBonusPopup(rewardAmount: result.coins, currentCoins: currentCoins, subtitle: subtitle);
  }

  void _onReferralBonusReceived() {
    final amount = PlayerSyncService.referralBonusReceived.amount;
    if (amount == null || amount <= 0) return;
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      _showBonusPopup(rewardAmount: amount, currentCoins: prefs.getInt('coins') ?? 15, subtitle: AppLocalizations.of(context)!.mainReferralFriendJoinedSubtitle);
    });
  }

  // 🆕 אותו פופאפ מסך-מלא של "קיבלת מטבעות" (reward_popups.dart) שכבר
  // מוכר מכל שאר בונוסי המטבעות באפליקציה - מנסה כמה פעמים אם ה-
  // Navigator עדיין לא מוכן (בדיוק כמו _showIncomingInviteDialog למטה).
  void _showBonusPopup({required int rewardAmount, required int currentCoins, required String subtitle, int attempt = 0}) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      if (attempt < 5) Future.delayed(const Duration(seconds: 1), () => _showBonusPopup(rewardAmount: rewardAmount, currentCoins: currentCoins, subtitle: subtitle, attempt: attempt + 1));
      return;
    }
    showCoinsRewardPopup(ctx, rewardAmount: rewardAmount, currentCoins: currentCoins, subtitle: subtitle);
  }

  // 🆕 "הוא יכול להזמין אותו למשחק והוא יכול לראות אם הוא מחובר" -
  // (א) פעימת נוכחות תקופתית (כל 90 שניות כל עוד האפליקציה פעילה) -
  // זה מה שגורם לחברים לראות "מחובר" לצידך (ראה FriendService.fetchFriends,
  // מבוסס lastActiveAt). (ב) האזנה בזמן אמת להזמנות דו-קרב נכנסות מחברים
  // (FriendService.watchIncomingInvite) - כל עוד האפליקציה פתוחה, הזמנה
  // חדשה מציגה מיד דיאלוג "X הזמין אותך לדו-קרב!" מעל כל מסך, בדיוק כמו
  // שההתראה על צילום מסך כבר עושה למעלה (דרך אותו rootNavigatorKey).
  Future<void> _startFriendPresenceAndInvites() async {
    FriendService.touchPresence(); // מיידי בפתיחה
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 90), (_) => FriendService.touchPresence());
    try {
      final myId = await FriendService.myId();
      if (!mounted) return;
      _incomingInviteSub?.cancel();
      _incomingInviteSub = FriendService.watchIncomingInvite(myId).listen((invite) {
        if (invite != null) _showIncomingInviteDialog(myId, invite);
      });
    } catch (_) {}
  }

  // 🆕 עוצב מחדש בדיוק לפי Friend_Invite.html שנשלח - כרטיס "הזמנה
  // לדו-קרב" עם שני אווטארים מול VS, מאזן ראש-בראש, "תנאי הדו-קרב"
  // (הימור/לוגואים/פרס), פס התקדמות עם ספירה לאחור, וכפתור קבלה גדול +
  // שתי אפשרויות משנה ("אחר כך" / "דחה") - ראו _IncomingInviteDialog למטה.
  void _showIncomingInviteDialog(String myId, Map<String, dynamic> invite, {int attempt = 0}) {
    final code = invite['code'] as String?;
    if (code == null || code.isEmpty) return;
    // 🩹 "ההזמנה לא קפצה" - (1) הזמנה ישנה שלא טופלה (למשל "אחר כך" או שהאפליקציה
    // הייתה סגורה) נשארה במסמך ותפסה את הדיאלוג/הוצגה באיחור - הזמנה פגה אחרי
    // דקה, אז מתעלמים ומנקים כל הזמנה ישנה מ-3 דקות. (2) אם כבר מוצג דיאלוג
    // של הזמנה *אחרת* - מחליפים אותו בחדשה במקום להתעלם ממנה. (3) אם ה-Navigator
    // עוד לא מוכן (פתיחה קרה) - מנסים שוב אחרי שנייה במקום לוותר בשקט.
    final rawSent = invite['sentAt'];
    DateTime? sentAtOrNull;
    try {
      sentAtOrNull = (rawSent as dynamic).toDate() as DateTime;
    } catch (_) {}
    if (sentAtOrNull != null && DateTime.now().difference(sentAtOrNull) > const Duration(minutes: 3)) {
      FriendService.clearIncomingInvite(myId);
      return;
    }
    if (_showingIncomingInviteDialog) {
      if (_shownInviteCode == code) return; // אותה הזמנה - כבר מוצגת
      final old = _inviteDialogContext;
      if (old != null && old.mounted) Navigator.of(old).pop();
    }
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      if (attempt < 5) Future.delayed(const Duration(seconds: 1), () => _showIncomingInviteDialog(myId, invite, attempt: attempt + 1));
      return;
    }
    final fromId = (invite['fromId'] as String?) ?? '';
    final fromName = (invite['fromName'] as String?) ?? AppLocalizations.of(ctx)!.friendChallengeFriendFallback;
    // 🆕 "אתגר חבר" עכשיו תומך גם במרוץ - ההזמנה הנכנסת חייבת לדעת לאיזה
    // מוד היא שייכת (ראו FriendService.notifyFriendOfInvite), כי הקוד
    // חי באוסף Firestore שונה לגמרי לכל מוד. ברירת מחדל true (דו-קרב)
    // לתאימות עם הזמנות ישנות שנשלחו לפני התוספת הזו.
    final isDuel = (invite['isDuel'] as bool?) ?? true;
    final stake = (invite['stake'] as int?) ?? (isDuel ? DuelService.stakeOptions.first : LogoRaceService.stakeOptions.first);
    DateTime sentAt;
    try {
      sentAt = (invite['sentAt'] as dynamic).toDate() as DateTime;
    } catch (_) {
      sentAt = DateTime.now();
    }
    _showingIncomingInviteDialog = true;
    _shownInviteCode = code;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        _inviteDialogContext = dialogContext;
        return _IncomingInviteDialog(
        myId: myId,
        fromId: fromId,
        fromName: fromName,
        stake: stake,
        sentAt: sentAt,
        isDuel: isDuel,
        onDecline: () async {
          Navigator.pop(dialogContext);
          await FriendService.clearIncomingInvite(myId);
          // 🆕 מודיעים למזמין מיד (לא רק מנקים אצלנו) - כדי שהוא יראה
          // "החבר דחה את ההזמנה" במקום לחכות סתם עד שהקוד פג תוקף אחרי
          // 15 דקות (ראה friend_challenge_screen.dart - _listenToMyInvite).
          if (isDuel) {
            await DuelService.declineInvite(code);
          } else {
            await LogoRaceService.declineInvite(code);
          }
        },
        onLater: () {
          // 🆕 "אחר כך" - רק סוגר את הדיאלוג, בלי לדחות ובלי לנקות את
          // incomingInvite: ההזמנה נשארת ותופיע שוב בפעם הבאה שהאפליקציה
          // נפתחת (או אם ה-listener מקבל עדכון חדש על אותו מסמך).
          Navigator.pop(dialogContext);
        },
        onAccept: () async {
          Navigator.pop(dialogContext);
          await FriendService.clearIncomingInvite(myId);
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username') ?? '';
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => FriendChallengeScreen(username: username, prefillJoinCode: code, isDuel: isDuel)),
          );
        },
        );
      },
    ).then((_) {
      // רק אם זה עדיין הדיאלוג הנוכחי (ייתכן שהוחלף בהזמנה חדשה יותר)
      if (_shownInviteCode == code) {
        _showingIncomingInviteDialog = false;
        _shownInviteCode = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PlayerSyncService.stopListening();
    PlayerSyncService.referralBonusReceived.removeListener(_onReferralBonusReceived);
    _incomingInviteSub?.cancel();
    _presenceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        AudioManager.pauseMusic();
        // 🆕 מציגים את הטשטוש כבר ב-inactive (לא רק ב-paused) - inactive
        // נורה *לפני* שהמערכת מצלמת את התמונה הממוזערת להצגה ב-Recents/
        // App Switcher, כך שיש הכי הרבה סיכוי שהטשטוש "יספיק" להיכנס
        // לפני שהתמונה הזו נלכדת.
        if (!_obscured) setState(() => _obscured = true);
        break;
      case AppLifecycleState.resumed:
        AudioManager.resumeMusicFromBackground();
        if (_obscured) setState(() => _obscured = false);
        FriendService.touchPresence(); // 🆕 רענון מיידי של "מחובר" בחזרה לאפליקציה
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 שני מקורות נפרדים יכולים "לדרוש" טשטוש - _obscured (מעבר
    // לרקע/לא פעיל, מטופל למעלה) ו-isScreenRecordingNow (הקלטת מסך
    // פעילה כרגע ב-iOS, ראו screenshot_guard_service.dart). כל עוד
    // אחד מהם true - מציגים את הטשטוש.
    return ValueListenableBuilder<bool>(
      valueListenable: isScreenRecordingNow,
      builder: (context, recording, child) {
        final showOverlay = _obscured || recording;
        return Stack(
          children: [
            widget.child,
            // 🆕 מסך הטשטוש - ignoreIgnorePointer/AnimatedSwitcher לא נחוצים
            // כאן: זה מוצג רק ברגעים שבהם המשתמש ממילא לא יכול לגעת במסך
            // (האפליקציה ברקע/לא פעילה) או בזמן הקלטה (שלא מטרתה אינטראקציה
            // עדינה), אז אין סיכון "לתפוס" לחיצות בטעות.
            if (showOverlay) const _PrivacyObscureOverlay(),
          ],
        );
      },
    );
  }
}

/// שכבת "פרטיות" מלאה-מסך: רקע כהה עמום + טשטוש (BackdropFilter) של
/// כל מה שמתחתיה + לוגו האפליקציה במרכז - כדי שהתצוגה המקדימה של
/// האפליקציה (Recents/App Switcher) תיראה כמו מסך פתיחה נקי ומכוון,
/// לא כמו תקלה, ובעיקר בלי לחשוף שום לוגו/תשובה שהיו על המסך.
class _PrivacyObscureOverlay extends StatelessWidget {
  const _PrivacyObscureOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: const Color(0xFF1D0E3C).withValues(alpha: 0.92),
            alignment: Alignment.center,
            child: Image.asset('assets/icon/logo.png', width: 88, height: 88, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 🆕 דיאלוג "הזמנה מחבר" - עוצב בדיוק לפי Friend_Invite.html שנשלח:
// כרטיס סגול עם תג "⚔ הזמנה לדו־קרב" למעלה, שני אווטארים (המזמין מול
// "אתה") סביב VS, מאזן ראש-בראש, רשת "תנאי הדו-קרב" (הימור/לוגואים/
// למנצח), פס התקדמות עם ספירה לאחור לפקיעת הקוד, כפתור קבלה גדול
// ("מקבל את האתגר ⚔" + כמה אנרגיה זה עולה/יש לך), ושתי אפשרויות משנה
// ("אחר כך" / "דחה"). StatefulWidget נפרד (לא רק builder בתוך showDialog)
// כי צריך Timer לספירה לאחור + טעינה אסינכרונית של מאזן ראש-בראש/אנרגיה.
// ================================================================
class _IncomingInviteDialog extends StatefulWidget {
  final String myId;
  final String fromId;
  final String fromName;
  final int stake;
  final DateTime sentAt;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onLater;
  // 🆕 "אתגר חבר" עכשיו תומך גם במרוץ - קובע אם להציג ספירת "לוגואים"/
  // מאזן ראש-בראש בנוסחה של דו-קרב (DuelService) או של מרוץ
  // (LogoRaceService, שאין לו כרגע מעקב ראש-בראש - מוצג מסר כללי במקום).
  final bool isDuel;
  const _IncomingInviteDialog({
    required this.myId,
    required this.fromId,
    required this.fromName,
    required this.stake,
    required this.sentAt,
    required this.onAccept,
    required this.onDecline,
    required this.onLater,
    required this.isDuel,
  });

  @override
  State<_IncomingInviteDialog> createState() => _IncomingInviteDialogState();
}

class _IncomingInviteDialogState extends State<_IncomingInviteDialog> {
  Timer? _timer;
  late Duration _remaining;
  Map<String, int>? _h2h;
  int _energy = 0;
  bool _loadedEnergy = false;

  @override
  void initState() {
    super.initState();
    final elapsed = DateTime.now().difference(widget.sentAt);
    _remaining = (widget.isDuel ? DuelService.inviteExpiry : LogoRaceService.inviteExpiry) - elapsed;
    if (_remaining.isNegative) _remaining = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final next = _remaining - const Duration(seconds: 1);
      if (next.isNegative || next == Duration.zero) {
        t.cancel();
        // 🆕 הקוד פג תוקף בזמן שהדיאלוג פתוח - סוגרים לבד בלי לדרוש
        // מהמשתמש ללחוץ כלום (בדיוק כמו שהמזמין רואה "פג תוקף" משלו).
        widget.onLater();
        return;
      }
      setState(() => _remaining = next);
    });
    // 🩹 h2h נשלף לפי FriendService.myId()/fromId (effectiveId - עלול
    // להיות uid מחובר, לא deviceId גולמי) בעוד ש-duelH2H בפועל נכתב לפי
    // deviceId גולמי מתוך משחקים אמיתיים (ראו DuelService/duel_room_screen).
    // אצל משתמש שלא חיבר חשבון effectiveId==deviceId וזה מדויק; אצל
    // משתמש מחובר זה עשוי לא להתאים למאזן ה"אמיתי" - תיעוד מכוון, לא
    // תוקן לעומק כדי לא לגעת בלוגיקת ההתאמה של הדו-קרב עצמה.
    // 🆕 מאזן ראש-בראש קיים רק לדו-קרב (DuelService.getHeadToHead) - למרוץ
    // אין כרגע מעקב כזה בכלל, אז פשוט לא טוענים כלום (h2hText למטה כבר
    // יודע להציג הודעה כללית כשאין _h2h).
    if (widget.isDuel) {
      DuelService.getHeadToHead(widget.myId, widget.fromId).then((v) {
        if (mounted) setState(() => _h2h = v);
      });
    }
    EnergyService.getCurrentEnergy().then((v) {
      if (mounted) setState(() {
        _energy = v;
        _loadedEnergy = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final questions = widget.isDuel ? DuelService.questionsForStake(widget.stake) : LogoRaceService.stagesForStake(widget.stake);
    final prize = widget.stake * 2;
    final total = (widget.isDuel ? DuelService.inviteExpiry : LogoRaceService.inviteExpiry).inSeconds;
    final progress = total == 0 ? 0.0 : (_remaining.inSeconds / total).clamp(0.0, 1.0);
    final min = _remaining.inMinutes;
    final sec = _remaining.inSeconds % 60;

    String h2hText = widget.isDuel ? loc.mainNoHeadToHeadYet : loc.mainInvitedToRace;
    if (widget.isDuel && _h2h != null) {
      final mine = _h2h!['mine'] ?? 0;
      final theirs = _h2h!['theirs'] ?? 0;
      if (mine > 0 || theirs > 0) {
        final side = mine == theirs ? loc.mainTie : (mine > theirs ? loc.mainInYourFavor : loc.mainInTheirFavor);
        h2hText = loc.mainHeadToHeadBalance(mine, theirs, side);
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A2170), Color(0xFF1E1247)]),
              border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.42)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _avatarCol(letter: widget.fromName.trim().isNotEmpty ? widget.fromName.trim().substring(0, 1) : '?', name: widget.fromName, glow: true)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.18)), color: const Color(0xFF140D34).withValues(alpha: 0.9)),
                          alignment: Alignment.center,
                          child: Text('VS', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      Expanded(child: _avatarCol(letter: loc.duelLobbyYouLabel.isNotEmpty ? loc.duelLobbyYouLabel.substring(0, 1) : '?', name: loc.duelLobbyYouLabel, glow: false)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(loc.mainInviteFromName(widget.fromName), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(h2hText, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // 🩹 הוסר אימוג'י המטבע (🪙) מהתוויות - בפונט של חלק מהמכשירים
                    // (בעיקר סמסונג/אנדרואיד ישן) הוא לא נתמך ומוצג כריבוע ריק.
                    _statCell(value: '${widget.stake}', label: loc.duelLobbyStatStake, bg: const Color(0xFFFFC64B)),
                    const SizedBox(width: 8),
                    _statCell(value: '$questions', label: loc.duelLobbyStatLogos, bg: const Color(0xFF60A5FA)),
                    const SizedBox(width: 8),
                    _statCell(value: '$prize', label: loc.duelLobbyStatWinner, bg: const Color(0xFF34D399)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black.withValues(alpha: 0.24)),
                  child: Row(
                    children: [
                      const Text('⏳', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.black.withValues(alpha: 0.35),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFBE123C)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text("$min:${sec.toString().padLeft(2, '0')}", style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 12.5, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: widget.onAccept,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
                        boxShadow: [BoxShadow(color: const Color(0xFFF2793B).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          Text(widget.isDuel ? loc.mainAcceptDuelChallenge : loc.mainAcceptRaceChallenge, style: const TextStyle(color: Color(0xFF40170F), fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(
                            _loadedEnergy ? loc.mainAcceptCostWithEnergy(EnergyService.duelCost, _energy) : loc.mainAcceptCost(EnergyService.duelCost),
                            style: TextStyle(color: const Color(0xFF40170F).withValues(alpha: 0.62), fontSize: 10.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(17),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: widget.onLater,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(loc.accountLinkLaterButton, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(17),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: widget.onDecline,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(loc.mainDeclineButton, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 14, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFBE123C)]),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Text(loc.mainInviteBadge, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCol({required String letter, required String name, required bool glow}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (glow)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFF43F5E).withValues(alpha: 0.4), const Color(0xFFF43F5E).withValues(alpha: 0)]),
                  ),
                ),
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: glow ? [const Color(0xFFFDA4AF), const Color(0xFFBE123C)] : [const Color(0xFFFFE08A), const Color(0xFFF2793B)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(letter.toUpperCase(), style: TextStyle(color: glow ? Colors.white : const Color(0xFF40170F), fontSize: 26, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: glow ? const Color(0xFFFDA4AF) : const Color(0xFFFFD979), fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _statCell({required String value, required String label, required Color bg}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: bg.withValues(alpha: 0.18), border: Border.all(color: bg.withValues(alpha: 0.35))),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: bg, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}