import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// שורת 'שפה' במסך ההגדרות
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get settingsLanguageLabel;

  /// כותרת דיאלוג בחירת השפה
  ///
  /// In he, this message translates to:
  /// **'בחרו שפה'**
  String get languageChoiceTitle;

  /// שם השפה העברית, כפי שמוצג בבורר השפה
  ///
  /// In he, this message translates to:
  /// **'עברית'**
  String get languageHebrew;

  /// שם השפה האנגלית, כפי שמוצג בבורר השפה
  ///
  /// In he, this message translates to:
  /// **'אנגלית'**
  String get languageEnglish;

  /// כותרת דיאלוג התנגשות חשבונות
  ///
  /// In he, this message translates to:
  /// **'מצאנו לך חשבון קיים'**
  String get accountConflictTitle;

  /// תת-כותרת דיאלוג התנגשות חשבונות
  ///
  /// In he, this message translates to:
  /// **'לחשבון הזה כבר יש התקדמות שמורה ממכשיר אחר. לאיזו התקדמות תרצה להתחבר?'**
  String get accountConflictMessage;

  /// כותרת כרטיס ההתקדמות השמורה בעננה
  ///
  /// In he, this message translates to:
  /// **'ההתקדמות השמורה בחשבון'**
  String get accountConflictCloudProgressTitle;

  /// כותרת כרטיס ההתקדמות המקומית
  ///
  /// In he, this message translates to:
  /// **'ההתקדמות הנוכחית במכשיר הזה'**
  String get accountConflictLocalProgressTitle;

  /// כפתור בחירת ההתקדמות השמורה בעננה
  ///
  /// In he, this message translates to:
  /// **'התחבר עם ההתקדמות השמורה'**
  String get accountConflictUseCloudButton;

  /// כפתור בחירת ההתקדמות המקומית
  ///
  /// In he, this message translates to:
  /// **'השאר את ההתקדמות הנוכחית שלי'**
  String get accountConflictUseLocalButton;

  /// אזהרה בדיאלוג התנגשות חשבונות
  ///
  /// In he, this message translates to:
  /// **'שים לב: האפשרות שלא תבחר תימחק ולא תהיה ניתנת לשחזור.'**
  String get accountConflictWarning;

  /// כפתור ביטול בדיאלוג התנגשות חשבונות
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get accountConflictCancelButton;

  /// תווית רמה בכרטיס ההתקדמות
  ///
  /// In he, this message translates to:
  /// **'רמה {level}'**
  String accountConflictLevelLabel(int level);

  /// כותרת דיאלוג חיבור חשבון
  ///
  /// In he, this message translates to:
  /// **'שמור את ההתקדמות שלך'**
  String get accountLinkTitle;

  /// תת-כותרת דיאלוג חיבור חשבון
  ///
  /// In he, this message translates to:
  /// **'חבר חשבון Google או Apple - כך אם תחליף טלפון, כל המטבעות וההתקדמות שלך יישמרו ויחכו לך.'**
  String get accountLinkMessage;

  /// כפתור ביטול בזמן טעינה בדיאלוג חיבור חשבון
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get accountLinkCancelButton;

  /// כפתור המשך עם גוגל
  ///
  /// In he, this message translates to:
  /// **'המשך עם Google'**
  String get accountLinkContinueWithGoogle;

  /// כפתור המשך עם אפל
  ///
  /// In he, this message translates to:
  /// **'המשך עם Apple'**
  String get accountLinkContinueWithApple;

  /// כפתור דחיית חיבור החשבון
  ///
  /// In he, this message translates to:
  /// **'אחר כך'**
  String get accountLinkLaterButton;

  /// כפתור אל תזכיר לי שוב
  ///
  /// In he, this message translates to:
  /// **'אל תזכיר לי שוב'**
  String get accountLinkDontShowAgain;

  /// הודעת הצלחה לאחר קישור חשבון
  ///
  /// In he, this message translates to:
  /// **'החשבון קושר בהצלחה! ההתקדמות שלך שמורה'**
  String get accountLinkSuccessMessage;

  /// הודעת שגיאה כאשר קישור החשבון נכשל
  ///
  /// In he, this message translates to:
  /// **'החיבור נכשל, נסה שוב מאוחר יותר'**
  String get accountLinkFailedMessage;

  /// כותרת דיאלוג אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'אין לך מספיק מטבעות'**
  String get notEnoughCoinsTitle;

  /// הודעת חוסר מטבעות עם עלות ומטבעות נוכחיים
  ///
  /// In he, this message translates to:
  /// **'זה עולה {cost} מטבעות ויש לך רק {coins}'**
  String notEnoughCoinsMessage(int cost, int coins);

  /// כמות המטבעות החסרה
  ///
  /// In he, this message translates to:
  /// **'חסרים {amount}'**
  String notEnoughCoinsMissing(int amount);

  /// כפתור מעבר לחנות המטבעות
  ///
  /// In he, this message translates to:
  /// **'לחנות המטבעות'**
  String get notEnoughCoinsShopButton;

  /// כפתור ביטול בדיאלוג אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get notEnoughCoinsCancelButton;

  /// כותרת עליונה קטנה בפופאפ פרס ההדרכה
  ///
  /// In he, this message translates to:
  /// **'סיימתם את ההדרכה'**
  String get onboardingGiftHeader;

  /// כותרת ראשית בפופאפ פרס ההדרכה
  ///
  /// In he, this message translates to:
  /// **'פרס נאסף!'**
  String get onboardingGiftTitle;

  /// תת-כותרת בפופאפ פרס ההדרכה
  ///
  /// In he, this message translates to:
  /// **'מגיע לכם על הרמה הראשונה - אתם מוכנים להמשיך בעצמכם!'**
  String get onboardingGiftSubtitle;

  /// סיכום פרס מטבעות ואנרגיה
  ///
  /// In he, this message translates to:
  /// **'{coins} מטבעות + {energy} אנרגיה'**
  String onboardingGiftRewardCoinsEnergy(int coins, int energy);

  /// סיכום פרס מטבעות בלבד
  ///
  /// In he, this message translates to:
  /// **'{coins} מטבעות'**
  String onboardingGiftRewardCoinsOnly(int coins);

  /// תווית גלולת הפרס
  ///
  /// In he, this message translates to:
  /// **'מתנת השלמת ההדרכה'**
  String get onboardingGiftRewardLabel;

  /// כפתור המשך לשחק בפופאפ פרס ההדרכה
  ///
  /// In he, this message translates to:
  /// **'המשיכו לשחק ›'**
  String get onboardingGiftContinueButton;

  /// פורמט זמן בשעות ודקות
  ///
  /// In he, this message translates to:
  /// **'{time} שעות'**
  String outOfResourceTimeHours(String time);

  /// פורמט זמן בדקות ושניות
  ///
  /// In he, this message translates to:
  /// **'{time} דקות'**
  String outOfResourceTimeMinutes(String time);

  /// הודעת קירור לפרסומת מטבעות
  ///
  /// In he, this message translates to:
  /// **'אפשר לקבל מטבעות מפרסומת שוב בעוד {time}'**
  String outOfResourceAdCoinsCooldownMsg(String time);

  /// הודעה שאין פרסומת זמינה
  ///
  /// In he, this message translates to:
  /// **'אין פרסומת זמינה כרגע, נסה שוב עוד רגע'**
  String get outOfResourceNoAdAvailable;

  /// הודעת קירור לפרסומת אנרגיה
  ///
  /// In he, this message translates to:
  /// **'אפשר לצפות בפרסומת נוספת בעוד {time}'**
  String outOfResourceAdEnergyCooldownMsg(String time);

  /// תת-כותרת בפופאפ פרס מטבעות - מתי זה חוזר
  ///
  /// In he, this message translates to:
  /// **'חוזר שוב בעוד {hours} שעות'**
  String outOfResourceCoinsRewardSubtitle(int hours);

  /// כפתור צפייה בפרסומת תמורת מטבעות
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת (+{amount} מטבעות) 🎬'**
  String outOfResourceWatchAdCoins(int amount);

  /// כפתור צפייה בפרסומת תמורת אנרגיה
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת (+{amount} אנרגיה) 🎬'**
  String outOfResourceWatchAdEnergy(int amount);

  /// כפתור קניית מטבעות בחנות
  ///
  /// In he, this message translates to:
  /// **'קנה מטבעות בחנות 🪙'**
  String get outOfResourceBuyCoinsButton;

  /// כפתור קניית אנרגיה בחנות
  ///
  /// In he, this message translates to:
  /// **'קנה אנרגיה בחנות ⚡'**
  String get outOfResourceBuyEnergyButton;

  /// כפתור ברירת מחדל בכרטיסיית הסבר (first-visit explainer)
  ///
  /// In he, this message translates to:
  /// **'הבנתי!'**
  String get explainerGotItButton;

  /// כותרת סרגל עליון בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'מחפש יריב'**
  String get duelLobbyBarTitleSearching;

  /// תת-כותרת סרגל עליון בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'דו־קרב על {stake} מטבעות · {logos} לוגואים'**
  String duelLobbyBarSubtitleSearching(int stake, int logos);

  /// כותרת ברירת מחדל של סרגל עליון בלובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'דו־קרב 1 על 1'**
  String get duelLobbyBarTitleDefault;

  /// תת-כותרת בעת בחירת הימור
  ///
  /// In he, this message translates to:
  /// **'בחר על מה משחקים'**
  String get duelLobbyBarSubtitleChoosing;

  /// כותרת מסך חסימה זמנית
  ///
  /// In he, this message translates to:
  /// **'חסום זמנית מדו-קרב'**
  String get duelLobbyBannedTitle;

  /// הודעת חסימה זמנית מדו-קרב
  ///
  /// In he, this message translates to:
  /// **'עזבת דו-קרב באמצע המשחק יותר מפעם אחת - זו לא הוגן כלפי היריבים שממתינים לתשובה. תוכל לשחק דו-קרב שוב בעוד {time}.'**
  String duelLobbyBannedMessage(String time);

  /// זמן חסימה שנותר - פחות מרגע
  ///
  /// In he, this message translates to:
  /// **'כמה רגעים'**
  String get duelLobbyBannedTimeFewMoments;

  /// זמן חסימה שנותר בשעות ודקות
  ///
  /// In he, this message translates to:
  /// **'{hours} שעות ו-{minutes} דקות'**
  String duelLobbyBannedTimeHoursMinutes(int hours, int minutes);

  /// זמן חסימה שנותר בדקות בלבד
  ///
  /// In he, this message translates to:
  /// **'{minutes} דקות'**
  String duelLobbyBannedTimeMinutes(int minutes);

  /// כפתור חזרה בלובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'חזרה'**
  String get duelLobbyBackButton;

  /// כפתור דיבאג לניקוי חסימה
  ///
  /// In he, this message translates to:
  /// **'נקה חסימה (דיבאג)'**
  String get duelLobbyClearBanDebugButton;

  /// כותרת גליון בחירת הימור
  ///
  /// In he, this message translates to:
  /// **'על מה משחקים?'**
  String get duelLobbyStakeSheetTitle;

  /// שורת מידע על עלות אנרגיה בגליון בחירת הימור
  ///
  /// In he, this message translates to:
  /// **'כל דו-קרב עולה {cost} אנרגיה · יש לך {energy}'**
  String duelLobbyEnergyInfoRow(int cost, int energy);

  /// כפתור ביטול בלובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get duelLobbyCancelButton;

  /// תת-כותרת כרטיס הימור
  ///
  /// In he, this message translates to:
  /// **'{logos} לוגואים · המנצח לוקח {prize}'**
  String duelLobbyStakeSubtitle(int logos, int prize);

  /// תג 'הכי פופולרי' על כרטיס הימור
  ///
  /// In he, this message translates to:
  /// **'הכי פופולרי'**
  String get duelLobbyMostPopularBadge;

  /// תווית סכום המטבעות על כרטיס הימור
  ///
  /// In he, this message translates to:
  /// **'{stake} מטבעות'**
  String duelLobbyStakeCoinsLabel(int stake);

  /// תג רמת הימור - בזק
  ///
  /// In he, this message translates to:
  /// **'בזק ⚡'**
  String get duelLobbyBadgeBlitz;

  /// תג רמת הימור - חימום
  ///
  /// In he, this message translates to:
  /// **'חימום'**
  String get duelLobbyBadgeWarmup;

  /// תג רמת הימור - מנוסים
  ///
  /// In he, this message translates to:
  /// **'מנוסים'**
  String get duelLobbyBadgeExperienced;

  /// תג רמת הימור - מקסימלי
  ///
  /// In he, this message translates to:
  /// **'מקסימלי'**
  String get duelLobbyBadgeMax;

  /// תג רמת הימור - מקצועי
  ///
  /// In he, this message translates to:
  /// **'מקצועי'**
  String get duelLobbyBadgePro;

  /// תג 'מוכן' ליד השחקן בזמן חיפוש
  ///
  /// In he, this message translates to:
  /// **'מוכן ✓'**
  String get duelLobbyReadyLabel;

  /// תווית מצב חיפוש ליד היריב
  ///
  /// In he, this message translates to:
  /// **'מחפש…'**
  String get duelLobbySearchingLabel;

  /// תג מתחבר ליד היריב בזמן חיפוש
  ///
  /// In he, this message translates to:
  /// **'מתחבר…'**
  String get duelLobbyConnectingLabel;

  /// טקסט חיפוש יריב עם זמן שחלף
  ///
  /// In he, this message translates to:
  /// **'מחפש יריב… {time}'**
  String duelLobbySearchingElapsed(String time);

  /// כותרת כרטיס תנאי הדו-קרב
  ///
  /// In he, this message translates to:
  /// **'תנאי הדו־קרב'**
  String get duelLobbyConditionsTitle;

  /// תווית סטטיסטיקה - הימור
  ///
  /// In he, this message translates to:
  /// **'הימור'**
  String get duelLobbyStatStake;

  /// תווית סטטיסטיקה - לוגואים
  ///
  /// In he, this message translates to:
  /// **'לוגואים'**
  String get duelLobbyStatLogos;

  /// תווית סטטיסטיקה - למנצח
  ///
  /// In he, this message translates to:
  /// **'למנצח'**
  String get duelLobbyStatWinner;

  /// כותרת מסך אין מספיק אנרגיה
  ///
  /// In he, this message translates to:
  /// **'נגמרה האנרגיה ⚡'**
  String get duelLobbyNotEnoughEnergyTitle;

  /// הודעת אין מספיק אנרגיה
  ///
  /// In he, this message translates to:
  /// **'כל דו-קרב עולה {cost} אנרגיות מתוך {max}. אנרגיה מתמלאת אוטומטית כל {minutes} דקות.'**
  String duelLobbyNotEnoughEnergyMessage(int cost, int max, int minutes);

  /// כפתור צפייה בפרסומת תמורת אנרגיה בלובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת (+{amount} אנרגיה) 🎬'**
  String duelLobbyWatchAdEnergyButton(int amount);

  /// כפתור קניית אנרגיה בחנות מתוך לובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'קנה בחנות ⚡'**
  String get duelLobbyBuyEnergyButton;

  /// כותרת מסך אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'אין מספיק מטבעות'**
  String get duelLobbyNotEnoughCoinsTitle;

  /// הודעת אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'דמי כניסה לדו-קרב: החל מ-{stake} מטבעות (יש לך {coins}). המנצח לוקח את כל הקופה!'**
  String duelLobbyNotEnoughCoinsMessage(int stake, int coins);

  /// כותרת גיבוי נמצא יריב
  ///
  /// In he, this message translates to:
  /// **'נמצא יריב! ⚔️'**
  String get duelLobbyFoundTitleFallback;

  /// שם גיבוי כשאין שם יריב
  ///
  /// In he, this message translates to:
  /// **'יריב'**
  String get duelLobbyOpponentFallbackName;

  /// שם גיבוי 'היריב' כשאין שם יריב (בהקשר מאזן ראש בראש)
  ///
  /// In he, this message translates to:
  /// **'היריב'**
  String get duelLobbyOpponentFallbackNameWithThe;

  /// באדג' נמצא יריב
  ///
  /// In he, this message translates to:
  /// **'נמצא יריב!'**
  String get duelLobbyFoundBadge;

  /// תווית 'אתה' בכרטיס שחקן
  ///
  /// In he, this message translates to:
  /// **'אתה'**
  String get duelLobbyYouLabel;

  /// תווית 'היריב' בכרטיס שחקן
  ///
  /// In he, this message translates to:
  /// **'היריב'**
  String get duelLobbyOpponentLabel;

  /// טקסט לפני ספירה לאחור
  ///
  /// In he, this message translates to:
  /// **'הדו־קרב מתחיל בעוד'**
  String get duelLobbyStartingIn;

  /// כפתור ביטול הדו-קרב במסך נמצא יריב
  ///
  /// In he, this message translates to:
  /// **'ביטול הדו־קרב'**
  String get duelLobbyCancelDuelButton;

  /// תווית מקום בכרטיס שחקן
  ///
  /// In he, this message translates to:
  /// **'מקום'**
  String get duelLobbyRankLabel;

  /// תווית ניצחונות בכרטיס שחקן
  ///
  /// In he, this message translates to:
  /// **'ניצחונות'**
  String get duelLobbyWinsLabel;

  /// כותרת כרטיס מאזן ראש בראש
  ///
  /// In he, this message translates to:
  /// **'מאזן ראש בראש'**
  String get duelLobbyH2hTitle;

  /// מספר הניצחונות שלי מול יריב זה
  ///
  /// In he, this message translates to:
  /// **'אתה {wins} ניצחונות'**
  String duelLobbyH2hYouWins(int wins);

  /// שם היריב ומספר הניצחונות שלו מולי
  ///
  /// In he, this message translates to:
  /// **'{name} {wins}'**
  String duelLobbyH2hOpponentScore(String name, int wins);

  /// כותרת מסך אין שחקנים
  ///
  /// In he, this message translates to:
  /// **'אין כרגע שחקנים מחוברים 🙁'**
  String get duelLobbyNoPlayersTitle;

  /// הודעת מסך אין שחקנים
  ///
  /// In he, this message translates to:
  /// **'נסה שוב בעוד כמה דקות, או שתף חברים כדי לשחק ביחד'**
  String get duelLobbyNoPlayersMessage;

  /// כפתור נסה שוב
  ///
  /// In he, this message translates to:
  /// **'נסה שוב'**
  String get duelLobbyRetryButton;

  /// כותרת מסך שגיאה כללית
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש'**
  String get duelLobbyErrorTitle;

  /// הודעת שגיאה בבחירת הימור
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש, האנרגיה הוחזרה. נסה שוב.'**
  String get duelLobbyStakeErrorMessage;

  /// הודעת קירור פרסומת אנרגיה בלובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'אפשר לצפות בפרסומת נוספת בעוד {time}'**
  String duelLobbyAdCooldownMsg(String time);

  /// הודעת אין פרסומת זמינה בלובי דו-קרב
  ///
  /// In he, this message translates to:
  /// **'אין פרסומת זמינה כרגע, נסה שוב עוד רגע'**
  String get duelLobbyNoAdAvailable;

  /// הודעה שהיריב ביטל לפני תחילת המשחק
  ///
  /// In he, this message translates to:
  /// **'היריב ביטל את הדו-קרב לפני שהתחיל'**
  String get duelLobbyOpponentCancelledMessage;

  /// טיפ 1 בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'טיפ: כל אחד עונה בקצב שלו - מי שמסיים ראשון את 10 הלוגואים מנצח'**
  String get duelLobbySearchingTip1;

  /// טיפ 2 בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'טיפ: אפשר לקנות רמז זול במיוחד בתוך הדו-קרב אם נתקעים'**
  String get duelLobbySearchingTip2;

  /// טיפ 3 בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'טיפ: המנצח לוקח את כל קופת המטבעות של שני השחקנים'**
  String get duelLobbySearchingTip3;

  /// טיפ 4 בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'טיפ: אין אינטרנט טוב ליריב? הוא יחזור לתור אחרי שנייה'**
  String get duelLobbySearchingTip4;

  /// טיפ 5 בזמן חיפוש יריב
  ///
  /// In he, this message translates to:
  /// **'טיפ: תרגלו במצב הרגיל כדי להכיר יותר לוגואים לפני דו-קרב'**
  String get duelLobbySearchingTip5;

  /// טיפ 1 בזמן חיפוש יריב למרוץ
  ///
  /// In he, this message translates to:
  /// **'טיפ: הלוגו מתחיל מכוסה כמעט לגמרי - ככל שהעיגול נפתח יותר, קל יותר לנחש'**
  String get logoRaceSearchingTip1;

  /// טיפ 2 בזמן חיפוש יריב למרוץ
  ///
  /// In he, this message translates to:
  /// **'טיפ: מי שמקליד ראשון את התשובה המלאה הנכונה - זוכה בסיבוב'**
  String get logoRaceSearchingTip2;

  /// טיפ 3 בזמן חיפוש יריב למרוץ
  ///
  /// In he, this message translates to:
  /// **'טיפ: אפשר לראות בזמן אמת גם את הניחושים השגויים של היריב בצ\'אט'**
  String get logoRaceSearchingTip3;

  /// טיפ 4 בזמן חיפוש יריב למרוץ
  ///
  /// In he, this message translates to:
  /// **'טיפ: המנצח לוקח את כל קופת המטבעות של שני השחקנים'**
  String get logoRaceSearchingTip4;

  /// טיפ 5 בזמן חיפוש יריב למרוץ
  ///
  /// In he, this message translates to:
  /// **'טיפ: ככל שרמת ההימור גבוהה יותר - יש יותר לוגואים במרוץ'**
  String get logoRaceSearchingTip5;

  /// כותרת מסך אין מספיק אנרגיה במרוץ
  ///
  /// In he, this message translates to:
  /// **'אין מספיק אנרגיה'**
  String get logoRaceNotEnoughEnergyTitle;

  /// הודעת אין מספיק אנרגיה במרוץ
  ///
  /// In he, this message translates to:
  /// **'למרוץ נדרשות {cost} אנרגיות מתוך {max}. אנרגיה מתמלאת אוטומטית כל {minutes} דקות.'**
  String logoRaceNotEnoughEnergyMessage(int cost, int max, int minutes);

  /// הודעת אין מספיק מטבעות במרוץ
  ///
  /// In he, this message translates to:
  /// **'דמי כניסה למרוץ: החל מ-{stake} מטבעות (יש לך {coins}). המנצח לוקח את כל הקופה!'**
  String logoRaceNotEnoughCoinsMessage(int stake, int coins);

  /// כותרת שגיאת התחברות במרוץ
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו להתחבר'**
  String get logoRaceConnectErrorTitle;

  /// הודעת שגיאת התחברות במרוץ
  ///
  /// In he, this message translates to:
  /// **'בדוק את החיבור לאינטרנט ונסה שוב'**
  String get logoRaceConnectErrorMessage;

  /// כותרת אין יריב זמין במרוץ
  ///
  /// In he, this message translates to:
  /// **'אין כרגע יריב זמין'**
  String get logoRaceNoOpponentTitle;

  /// הודעת אין יריב זמין במרוץ
  ///
  /// In he, this message translates to:
  /// **'האנרגיה הוחזרה אליך - נסה שוב עוד רגע'**
  String get logoRaceNoOpponentMessage;

  /// הודעת ממתין לחיבור מחדש של היריב
  ///
  /// In he, this message translates to:
  /// **'ממתין לחיבור מחדש של {name}'**
  String logoRaceWaitingReconnect(String name);

  /// אזהרת ניצחון טכני בעקבות ניתוק
  ///
  /// In he, this message translates to:
  /// **'אם לא יתחבר תוך {seconds} שניות, זה ייחשב ניצחון טכני'**
  String logoRaceReconnectTimeoutWarning(int seconds);

  /// הודעה שקובעים ניצחון טכני
  ///
  /// In he, this message translates to:
  /// **'קובעים ניצחון טכני...'**
  String get logoRaceDecidingTechnicalWin;

  /// תת-כותרת סרגל עליון בזמן חיפוש יריב למרוץ
  ///
  /// In he, this message translates to:
  /// **'מרוץ על {stake} מטבעות · {logos} לוגואים'**
  String logoRaceBarSubtitleSearching(int stake, int logos);

  /// כותרת ברירת מחדל סרגל עליון במרוץ
  ///
  /// In he, this message translates to:
  /// **'מרוץ לוגואים 🏁'**
  String get logoRaceBarTitleDefault;

  /// כותרת סרגל עליון בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'תוצאות המרוץ 🏁'**
  String get logoRaceBarTitleResults;

  /// תת-כותרת גליון בחירת הימור במרוץ
  ///
  /// In he, this message translates to:
  /// **'ההימור נלקח משני השחקנים'**
  String get logoRaceStakeSheetSubtitle;

  /// שורת מידע בגליון בחירת הימור במרוץ
  ///
  /// In he, this message translates to:
  /// **'כל לוגו מוסתר כמעט לגמרי - מי שמנחש נכון ראשון בצ\'אט זוכה בסיבוב.'**
  String get logoRaceInfoRow;

  /// כפתור שחק על כרטיס הימור במרוץ
  ///
  /// In he, this message translates to:
  /// **'שחק'**
  String get logoRacePlayButton;

  /// כותרת כרטיס תנאי המרוץ
  ///
  /// In he, this message translates to:
  /// **'תנאי המרוץ'**
  String get logoRaceConditionsTitle;

  /// טקסט לפני ספירה לאחור במרוץ
  ///
  /// In he, this message translates to:
  /// **'המרוץ מתחיל בעוד'**
  String get logoRaceStartingIn;

  /// תווית הניקוד שלי במרוץ
  ///
  /// In he, this message translates to:
  /// **'אתה: {score}'**
  String logoRaceYouScoreLabel(int score);

  /// מונה לוגו נוכחי מתוך הכול במרוץ
  ///
  /// In he, this message translates to:
  /// **'לוגו {current}/{total}'**
  String logoRaceLogoCounter(int current, int total);

  /// תווית ניקוד היריב במרוץ
  ///
  /// In he, this message translates to:
  /// **'{name}: {score}'**
  String logoRaceOpponentScoreLabel(String name, int score);

  /// באנר סיבוב - אף אחד לא ניחש
  ///
  /// In he, this message translates to:
  /// **'הזמן נגמר - אף אחד לא ניחש'**
  String get logoRaceRoundNoneGuessed;

  /// באנר סיבוב - אני ניחשתי נכון
  ///
  /// In he, this message translates to:
  /// **'ניחשת נכון! עובר ללוגו הבא...'**
  String get logoRaceRoundYouWon;

  /// באנר סיבוב - היריב ניחש נכון
  ///
  /// In he, this message translates to:
  /// **'{name} ניחש/ה נכון! עובר ללוגו הבא...'**
  String logoRaceRoundOpponentWon(String name);

  /// כפתור הסרת האות האחרונה שהוקלדה
  ///
  /// In he, this message translates to:
  /// **'הסר אות'**
  String get logoRaceRemoveLetterButton;

  /// כותרת תוצאת ניצחון במרוץ
  ///
  /// In he, this message translates to:
  /// **'ניצחת!'**
  String get logoRaceWinTitle;

  /// כותרת תוצאת תיקו במרוץ
  ///
  /// In he, this message translates to:
  /// **'תיקו!'**
  String get logoRaceDrawTitle;

  /// כותרת תוצאת הפסד במרוץ
  ///
  /// In he, this message translates to:
  /// **'היריב ניצח'**
  String get logoRaceLossTitle;

  /// תג בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'🏁 מרוץ · על {stake} מטבעות'**
  String logoRaceResultBadge(int stake);

  /// סיכום ניקוד בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'{score} מתוך {total} לוגואים'**
  String logoRaceScoreSummary(int score, int total);

  /// כותרת כרטיס הפרס בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'הפרס שלך'**
  String get logoRacePrizeLabel;

  /// תווית סטטיסטיקת מטבעות בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'מטבעות'**
  String get logoRacePrizeCoinsLabel;

  /// כפתור מרוץ נוסף בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'מרוץ נוסף 🏁'**
  String get logoRacePlayAgainButton;

  /// כפתור שיתוף בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'שיתוף'**
  String get logoRaceShareButton;

  /// טקסט שיתוף בניצחון במרוץ
  ///
  /// In he, this message translates to:
  /// **'ניצחתי במרוץ לוגואים במשחק \"זהה את הלוגו!\" 🏁 {score}/{total} לוגואים. בואו תנסו לנצח אותי! 🎮'**
  String logoRaceShareTextWin(int score, int total);

  /// טקסט שיתוף בלא-ניצחון במרוץ
  ///
  /// In he, this message translates to:
  /// **'שיחקתי מרוץ לוגואים במשחק \"זהה את הלוגו!\" - בואו תתמודדו איתי! 🏁'**
  String get logoRaceShareTextLose;

  /// כפתור חזרה לתפריט בתוצאות המרוץ
  ///
  /// In he, this message translates to:
  /// **'חזרה לתפריט'**
  String get logoRaceBackToMenuButton;

  /// כותרת דיאלוג אישור יציאה מהמרוץ
  ///
  /// In he, this message translates to:
  /// **'לצאת מהמרוץ?'**
  String get logoRaceExitConfirmTitle;

  /// הודעת אישור יציאה מהמרוץ
  ///
  /// In he, this message translates to:
  /// **'אם תצא עכשיו היריב יוכרז מנצח ויקבל את כל הקופה ({stake1} שהימרת + {stake2} שלו) - המטבעות שכבר שילמת לא יוחזרו.'**
  String logoRaceExitConfirmMessage(int stake1, int stake2);

  /// אזהרת יציאה מוקדמת מהמרוץ
  ///
  /// In he, this message translates to:
  /// **'זו עזיבה מוקדמת - תקבל רק אזהרה'**
  String get logoRaceExitEarlyWarning;

  /// אזהרת פרישה ביציאה מהמרוץ
  ///
  /// In he, this message translates to:
  /// **'עזיבה בשלב הזה נחשבת פרישה'**
  String get logoRaceExitForfeitWarning;

  /// סף אזהרות לחסימה זמנית
  ///
  /// In he, this message translates to:
  /// **'({count} אזהרות = חסימה זמנית).'**
  String logoRaceExitBanThreshold(int count);

  /// כפתור להישאר במרוץ
  ///
  /// In he, this message translates to:
  /// **'להישאר'**
  String get logoRaceStayButton;

  /// כפתור יציאה בכל זאת מהמרוץ
  ///
  /// In he, this message translates to:
  /// **'צא בכל זאת'**
  String get logoRaceLeaveAnywayButton;

  /// תווית 'צאו!' בסוף הספירה לאחור במרוץ
  ///
  /// In he, this message translates to:
  /// **'צאו!'**
  String get logoRaceGoLabel;

  /// תג סיבוב בסדרת דו-קרב
  ///
  /// In he, this message translates to:
  /// **'🏆 סיבוב {round}/3 בסדרה'**
  String duelRoomSeriesRoundBadge(int round);

  /// כותרת ניצחון בסיבוב סדרה
  ///
  /// In he, this message translates to:
  /// **'ניצחת בסיבוב!'**
  String get duelRoomRoundWinTitle;

  /// כותרת תיקו בסיבוב סדרה
  ///
  /// In he, this message translates to:
  /// **'תיקו בסיבוב'**
  String get duelRoomRoundDrawTitle;

  /// כותרת הפסד בסיבוב סדרה
  ///
  /// In he, this message translates to:
  /// **'היריב ניצח בסיבוב'**
  String get duelRoomRoundLossTitle;

  /// שורת ניקוד הסדרה
  ///
  /// In he, this message translates to:
  /// **'הסדרה: {myWins} - {oppWins} מול {oppName}'**
  String duelRoomSeriesScoreLine(int myWins, int oppWins, String oppName);

  /// הודעת מעבר לסיבוב הבא בסדרה
  ///
  /// In he, this message translates to:
  /// **'עוברים לסיבוב הבא...'**
  String get duelRoomMovingToNextRound;

  /// כותרת גליון בחירת רמז
  ///
  /// In he, this message translates to:
  /// **'בחר רמז'**
  String get duelRoomChooseHintTitle;

  /// כפתור חשיפת אות
  ///
  /// In he, this message translates to:
  /// **'חשוף אות'**
  String get duelRoomRevealLetterTitle;

  /// תת-כותרת חשיפת אות
  ///
  /// In he, this message translates to:
  /// **'אות אחת נוספת מתגלה מיד'**
  String get duelRoomRevealLetterSubtitle;

  /// כפתור פתרון כל המילה
  ///
  /// In he, this message translates to:
  /// **'פתור את כל המילה'**
  String get duelRoomSolveWordTitle;

  /// תת-כותרת פתרון כל המילה
  ///
  /// In he, this message translates to:
  /// **'כל האותיות מתגלות בבת אחת'**
  String get duelRoomSolveWordSubtitle;

  /// הודעה שרמזים לא זמינים בהימור הנוכחי
  ///
  /// In he, this message translates to:
  /// **'רמזים לא זמינים בהימור הזה - זמינים רק מ-100 מטבעות ומעלה'**
  String get duelRoomHintsNotAvailable;

  /// תג עליון בתוצאות סדרת דו-קרב
  ///
  /// In he, this message translates to:
  /// **'🏆 סדרת דו־קרב · על {stake} מטבעות'**
  String duelRoomSeriesBadge(int stake);

  /// תג עליון בתוצאות דו-קרב רגיל
  ///
  /// In he, this message translates to:
  /// **'⚔️ דו־קרב · על {stake} מטבעות'**
  String duelRoomDuelBadge(int stake);

  /// כותרת ניצחון בתוצאות דו-קרב
  ///
  /// In he, this message translates to:
  /// **'ניצחת!'**
  String get duelRoomWinTitle;

  /// כותרת תיקו בתוצאות דו-קרב
  ///
  /// In he, this message translates to:
  /// **'תיקו!'**
  String get duelRoomDrawTitle;

  /// כותרת הפסד בתוצאות דו-קרב
  ///
  /// In he, this message translates to:
  /// **'היריב ניצח'**
  String get duelRoomLossTitle;

  /// תג תיקו בסדרה עם ניקוד
  ///
  /// In he, this message translates to:
  /// **'תיקו בסדרה · {myWins}-{oppWins}'**
  String duelRoomSeriesDrawScore(int myWins, int oppWins);

  /// תג ניצחון הסדרה עם ניקוד
  ///
  /// In he, this message translates to:
  /// **'ניצחת את הסדרה {myWins}-{oppWins}'**
  String duelRoomSeriesWinScore(int myWins, int oppWins);

  /// תג הפסד הסדרה עם ניקוד
  ///
  /// In he, this message translates to:
  /// **'הפסדת את הסדרה {myWins}-{oppWins}'**
  String duelRoomSeriesLossScore(int myWins, int oppWins);

  /// סיכום ניקוד וזמן בתוצאות דו-קרב
  ///
  /// In he, this message translates to:
  /// **'{score} מתוך {total} לוגואים · {elapsed} דקות'**
  String duelRoomScoreTimeSummary(int score, int total, String elapsed);

  /// כפתור ממתין לרימאץ'
  ///
  /// In he, this message translates to:
  /// **'ממתין ל-{name}... ⏳'**
  String duelRoomWaitingForRematch(String name);

  /// כפתור בקשת רימאץ'
  ///
  /// In he, this message translates to:
  /// **'שחק שוב מול {name} 🔁'**
  String duelRoomRematchButton(String name);

  /// כפתור דו-קרב נוסף
  ///
  /// In he, this message translates to:
  /// **'דו-קרב נוסף ⚔️'**
  String get duelRoomPlayAgainButton;

  /// טקסט שיתוף בניצחון בדו-קרב
  ///
  /// In he, this message translates to:
  /// **'ניצחתי בדו-קרב במשחק \"זהה את הלוגו!\" 🏆 {score}/{total} לוגואים ב-{elapsed} דקות. בואו תנסו לנצח אותי! 🎮'**
  String duelRoomShareTextWin(int score, int total, String elapsed);

  /// טקסט שיתוף בלא-ניצחון בדו-קרב
  ///
  /// In he, this message translates to:
  /// **'שיחקתי דו-קרב במשחק \"זהה את הלוגו!\" - בואו תתמודדו איתי! ⚔️'**
  String get duelRoomShareTextLose;

  /// כותרת דיאלוג אישור יציאה מהדו-קרב
  ///
  /// In he, this message translates to:
  /// **'לצאת מהדו-קרב?'**
  String get duelRoomExitConfirmTitle;

  /// הודעת אישור יציאה מהדו-קרב
  ///
  /// In he, this message translates to:
  /// **'אם תצא עכשיו היריב יוכרז מנצח ויקבל את כל הקופה ({stake1} שהימרת + {stake2} שלו) - המטבעות והאנרגיה שכבר שילמת לא יוחזרו.'**
  String duelRoomExitConfirmMessage(int stake1, int stake2);

  /// סף אזהרות לחסימה זמנית מדו-קרב
  ///
  /// In he, this message translates to:
  /// **'({count} אזהרות = חסימה זמנית מדו-קרב).'**
  String duelRoomExitBanThreshold(int count);

  /// הודעת הכנה לסיבוב הבא בסדרה
  ///
  /// In he, this message translates to:
  /// **'מתכוננים לסיבוב הבא...'**
  String get duelRoomPreparingNextRound;

  /// כותרת ספירה לאחור - היריב נמצא
  ///
  /// In he, this message translates to:
  /// **'היריב נמצא!'**
  String get duelRoomOpponentFoundTitle;

  /// תווית בסוף הספירה לאחור של הדו-קרב
  ///
  /// In he, this message translates to:
  /// **'קדימה!'**
  String get duelRoomGoLabel;

  /// מונה לוגו נוכחי מתוך הכול בדו-קרב
  ///
  /// In he, this message translates to:
  /// **'לוגו {current} מתוך {total}'**
  String duelRoomLogoCounter(int current, int total);

  /// באנר תשובה נכונה על גבי הלוגו
  ///
  /// In he, this message translates to:
  /// **'תשובה נכונה!'**
  String get duelRoomCorrectAnswerBanner;

  /// באנר הזמן נגמר על גבי הלוגו
  ///
  /// In he, this message translates to:
  /// **'הזמן נגמר!'**
  String get duelRoomTimeUpBanner;

  /// תווית שבב רמז
  ///
  /// In he, this message translates to:
  /// **'רמז'**
  String get duelRoomHintChipLabel;

  /// הודעת סיום כל הלוגואים - ממתין ליריב
  ///
  /// In he, this message translates to:
  /// **'סיימת את כל {total} הלוגואים! 🎉'**
  String duelRoomFinishedAllLogos(int total);

  /// הודעת המתנה ליריב לסיים
  ///
  /// In he, this message translates to:
  /// **'מחכים ש-{name} יסיים גם...'**
  String duelRoomWaitingForOpponentToFinish(String name);

  /// תג כותרת עליונה בחדר הדו-קרב
  ///
  /// In he, this message translates to:
  /// **'דו־קרב · על {stake} מטבעות'**
  String duelRoomHeaderBadge(int stake);

  /// באנר שהיריב ענה נכון
  ///
  /// In he, this message translates to:
  /// **'{name} ענה/תה נכון!'**
  String duelRoomOpponentAnsweredBanner(String name);

  /// תג סיבוב וניקוד סדרה מעל פס ההתקדמות
  ///
  /// In he, this message translates to:
  /// **'סדרה · סיבוב {round}/3 · {myWins}-{oppWins}'**
  String duelRoomSeriesRoundHeader(int round, int myWins, int oppWins);

  /// אני מוביל בכמה תשובות נכונות
  ///
  /// In he, this message translates to:
  /// **'אתה מוביל ב-{amount}'**
  String duelRoomYouLeadBy(String amount);

  /// היריב מוביל בכמה תשובות נכונות
  ///
  /// In he, this message translates to:
  /// **'{name} מוביל ב-{amount}'**
  String duelRoomOpponentLeadBy(String name, String amount);

  /// תשובה נכונה אחת (יחיד)
  ///
  /// In he, this message translates to:
  /// **'תשובה נכונה אחת'**
  String get duelRoomCorrectAnswersSingular;

  /// מספר תשובות נכונות (רבים)
  ///
  /// In he, this message translates to:
  /// **'{count} תשובות נכונות'**
  String duelRoomCorrectAnswersPlural(int count);

  /// כותרת טבלת עונת הדו-קרבים
  ///
  /// In he, this message translates to:
  /// **'טבלת עונת הדו-קרבים'**
  String get duelSeasonLbTitle;

  /// כותרת מסך ריק בטבלת העונה
  ///
  /// In he, this message translates to:
  /// **'עדיין אין ניצחונות החודש'**
  String get duelSeasonLbEmptyTitle;

  /// הודעת מסך ריק בטבלת העונה
  ///
  /// In he, this message translates to:
  /// **'תהיה הראשון לנצח דו-קרב החודש ולפתוח את הטבלה!'**
  String get duelSeasonLbEmptyMessage;

  /// כותרת קטע שאר המובילים
  ///
  /// In he, this message translates to:
  /// **'שאר המובילים'**
  String get duelSeasonLbOthersSection;

  /// כותרת קטע המקום שלי
  ///
  /// In he, this message translates to:
  /// **'המקום שלך'**
  String get duelSeasonLbYourPlaceSection;

  /// שם גיבוי לשחקן ללא שם
  ///
  /// In he, this message translates to:
  /// **'שחקן'**
  String get duelSeasonLbPlayerFallbackName;

  /// שם השחקן עם סיומת (אתה) בפודיום
  ///
  /// In he, this message translates to:
  /// **'{name} (אתה)'**
  String duelSeasonLbYouSuffix(String name);

  /// כותרת כרטיס מוד סדרת דו-קרב
  ///
  /// In he, this message translates to:
  /// **'סדרת דו-קרב'**
  String get playVsPersonSeriesTitle;

  /// תת-כותרת כרטיס מוד סדרת דו-קרב
  ///
  /// In he, this message translates to:
  /// **'הטוב מ-3 מול אותו יריב · בונוס מטבעות על ניצחון בסדרה'**
  String get playVsPersonSeriesSubtitle;

  /// תג 'חדש' על כרטיס מוד
  ///
  /// In he, this message translates to:
  /// **'חדש'**
  String get playVsPersonNewBadge;

  /// כותרת כרטיס מוד דו-קרב
  ///
  /// In he, this message translates to:
  /// **'דו־קרב'**
  String get playVsPersonDuelTitle;

  /// תת-כותרת כרטיס מוד דו-קרב
  ///
  /// In he, this message translates to:
  /// **'1 על 1 · מי שפותר יותר לוגואים מנצח'**
  String get playVsPersonDuelSubtitle;

  /// כותרת כרטיס מוד מירוץ
  ///
  /// In he, this message translates to:
  /// **'מירוץ'**
  String get playVsPersonRaceTitle;

  /// תת-כותרת כרטיס מוד מירוץ
  ///
  /// In he, this message translates to:
  /// **'1 על 1 · מי שמנחש ראשון בכל לוגו מנצח'**
  String get playVsPersonRaceSubtitle;

  /// תווית מספר לוגואים קבוע
  ///
  /// In he, this message translates to:
  /// **'{count} לוגואים'**
  String playVsPersonLogosRangeSingle(int count);

  /// תווית טווח מספר לוגואים
  ///
  /// In he, this message translates to:
  /// **'{min}–{max} לוגואים'**
  String playVsPersonLogosRange(int min, int max);

  /// כפתור טבלת העונה
  ///
  /// In he, this message translates to:
  /// **'טבלת העונה'**
  String get playVsPersonSeasonBoardButton;

  /// כפתור קרא לחבר
  ///
  /// In he, this message translates to:
  /// **'קרא לחבר'**
  String get playVsPersonInviteFriendButton;

  /// כותרת כרטיסיית ההסבר הראשונית
  ///
  /// In he, this message translates to:
  /// **'3 דרכים לשחק נגד אחרים'**
  String get playVsPersonIntroTitle;

  /// תיאור סדרת דו-קרב בכרטיסיית ההסבר
  ///
  /// In he, this message translates to:
  /// **'הטוב מ-3 מול אותו יריב - בונוס מטבעות על ניצחון בסדרה'**
  String get playVsPersonSeriesIntroDesc;

  /// כותרת דו-קרב בכרטיסיית ההסבר
  ///
  /// In he, this message translates to:
  /// **'דו-קרב'**
  String get playVsPersonDuelIntroTitle;

  /// תיאור דו-קרב בכרטיסיית ההסבר
  ///
  /// In he, this message translates to:
  /// **'עימות 1 על 1 - מי שפותר יותר לוגואים מנצח'**
  String get playVsPersonDuelIntroDesc;

  /// תיאור מירוץ בכרטיסיית ההסבר
  ///
  /// In he, this message translates to:
  /// **'עימות 1 על 1 - מי שמנחש ראשון בכל לוגו מנצח'**
  String get playVsPersonRaceIntroDesc;

  /// כפתור סגירת כרטיסיית ההסבר
  ///
  /// In he, this message translates to:
  /// **'הבנתי, בואו נבחר!'**
  String get playVsPersonIntroGotItButton;

  /// כותרת קטע הזמנת חברים
  ///
  /// In he, this message translates to:
  /// **'הזמן חבר ישירות'**
  String get playVsPersonInviteDirectlyTitle;

  /// תווית חבר לא מחובר
  ///
  /// In he, this message translates to:
  /// **'לא מחובר'**
  String get playVsPersonFriendOffline;

  /// כותרת סרגל עליון - בחר מוד
  ///
  /// In he, this message translates to:
  /// **'בחר מוד'**
  String get playVsPersonChooseModeTitle;

  /// מספר השחקנים המחוברים כעת
  ///
  /// In he, this message translates to:
  /// **'{count} מחוברים'**
  String playVsPersonConnectedCount(int count);

  /// תווית 'משחקים' ליד מספר השחקנים בכרטיס מוד
  ///
  /// In he, this message translates to:
  /// **'משחקים'**
  String get playVsPersonPlayingLabel;

  /// כפתור בחר על כרטיס מוד
  ///
  /// In he, this message translates to:
  /// **'בחר'**
  String get playVsPersonChooseButton;

  /// שם המוד - דו-קרב
  ///
  /// In he, this message translates to:
  /// **'דו-קרב'**
  String get friendChallengeModeDuel;

  /// שם המוד - מרוץ
  ///
  /// In he, this message translates to:
  /// **'מרוץ'**
  String get friendChallengeModeRace;

  /// הודעת שגיאה ביצירת קוד הזמנה
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו ליצור קוד הזמנה - נסה שוב'**
  String get friendChallengeCreateInviteFailed;

  /// הודעת העתקת קוד
  ///
  /// In he, this message translates to:
  /// **'הקוד הועתק! שלח אותו לחבר'**
  String get friendChallengeCodeCopied;

  /// טקסט שיתוף קוד הזמנה
  ///
  /// In he, this message translates to:
  /// **'בוא נשחק {mode} ב\"זהה את הלוגו!\" 🔗 הקוד שלי: {code}'**
  String friendChallengeShareText(String mode, String code);

  /// נושא שיתוף קוד הזמנה
  ///
  /// In he, this message translates to:
  /// **'אתגר {mode}'**
  String friendChallengeShareSubject(String mode);

  /// הודעת גיבוי כשאין אפליקציית שיתוף
  ///
  /// In he, this message translates to:
  /// **'לא נמצאה אפליקציית שיתוף. אפשר להעתיק ולשלוח ידנית:\n{text}'**
  String friendChallengeNoShareAppFallback(String text);

  /// הודעת שגיאת אורך קוד
  ///
  /// In he, this message translates to:
  /// **'קוד חייב להיות בן {length} תווים'**
  String friendChallengeCodeLengthError(int length);

  /// הודעת קוד לא נמצא (מפורטת)
  ///
  /// In he, this message translates to:
  /// **'לא נמצא קוד כזה - ודא שהקלדת נכון'**
  String get friendChallengeCodeNotFoundDetailed;

  /// הודעת זה הקוד שלך (מפורטת)
  ///
  /// In he, this message translates to:
  /// **'זה הקוד שלך - שלח אותו לחבר, לא להזין אותו כאן'**
  String get friendChallengeOwnCodeDetailed;

  /// הודעת קוד כבר נוצל
  ///
  /// In he, this message translates to:
  /// **'מישהו כבר הצטרף לקוד הזה'**
  String get friendChallengeCodeAlreadyUsed;

  /// הודעת קוד פג תוקף
  ///
  /// In he, this message translates to:
  /// **'הקוד הזה כבר פג תוקף'**
  String get friendChallengeCodeExpired;

  /// הודעת אין מספיק מטבעות להימור שנבחר
  ///
  /// In he, this message translates to:
  /// **'אין לך מספיק מטבעות להימור הזה ({stake})'**
  String friendChallengeNotEnoughCoinsForStake(int stake);

  /// הודעת קוד לא נמצא (קצרה)
  ///
  /// In he, this message translates to:
  /// **'לא נמצא קוד כזה'**
  String get friendChallengeCodeNotFound;

  /// הודעת זה הקוד שלך (קצרה)
  ///
  /// In he, this message translates to:
  /// **'זה הקוד שלך'**
  String get friendChallengeOwnCode;

  /// הודעת שגיאה כללית בהצטרפות
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש - נסה שוב'**
  String get friendChallengeGenericError;

  /// כותרת עליונה - ממתין לחבר
  ///
  /// In he, this message translates to:
  /// **'ממתין לחבר'**
  String get friendChallengeWaitingTitle;

  /// כותרת עליונה - הצטרפות עם קוד
  ///
  /// In he, this message translates to:
  /// **'הצטרפות עם קוד'**
  String get friendChallengeJoinWithCodeTitle;

  /// כותרת עליונה - ברירת מחדל
  ///
  /// In he, this message translates to:
  /// **'אתגר חבר'**
  String get friendChallengeDefaultTitle;

  /// הודעת חסימה זמנית מדו-קרב
  ///
  /// In he, this message translates to:
  /// **'עזבת דו-קרב באמצע המשחק יותר מפעם אחת. תוכל לשחק דו-קרב שוב בעוד {time}.'**
  String friendChallengeBannedMessage(String time);

  /// הודעת אין מספיק אנרגיה
  ///
  /// In he, this message translates to:
  /// **'כל {mode} עולה {cost} אנרגיות. אנרגיה מתמלאת אוטומטית כל {minutes} דקות.'**
  String friendChallengeNotEnoughEnergyMessage(
    String mode,
    int cost,
    int minutes,
  );

  /// הודעת אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'צריך לפחות {stake} מטבעות כדי להתחיל {mode}.'**
  String friendChallengeNotEnoughCoinsMessage(int stake, String mode);

  /// כותרת הזמנה ישירה לחבר
  ///
  /// In he, this message translates to:
  /// **'הזמנת {friendName} ל{mode}'**
  String friendChallengeDirectInviteTitle(String friendName, String mode);

  /// כותרת הזמנה כללית
  ///
  /// In he, this message translates to:
  /// **'אתגר חבר ל{mode}'**
  String friendChallengeGenericInviteTitle(String mode);

  /// תת-כותרת הזמנה ישירה לחבר
  ///
  /// In he, this message translates to:
  /// **'בחר על מה משחקים - {friendName} יקבל הזמנה מיידית.'**
  String friendChallengeDirectInviteSubtitle(String friendName);

  /// תת-כותרת הזמנה כללית
  ///
  /// In he, this message translates to:
  /// **'בחר על מה משחקים, ואז צור קוד לשלוח לחבר - או הזן קוד שכבר קיבלת.'**
  String get friendChallengeGenericInviteSubtitle;

  /// כפתור שליחת הזמנה ישירה
  ///
  /// In he, this message translates to:
  /// **'שלח הזמנה 🎟️'**
  String get friendChallengeSendInviteButton;

  /// כפתור יצירת קוד הזמנה
  ///
  /// In he, this message translates to:
  /// **'צור קוד לחבר 🎟️'**
  String get friendChallengeCreateCodeButton;

  /// מילת 'או' בין שתי אפשרויות
  ///
  /// In he, this message translates to:
  /// **'או'**
  String get friendChallengeOrDivider;

  /// שאלה - יש לך קוד מחבר
  ///
  /// In he, this message translates to:
  /// **'יש לך קוד מחבר?'**
  String get friendChallengeHaveCodeQuestion;

  /// כפתור הצטרפות עם קוד
  ///
  /// In he, this message translates to:
  /// **'הצטרף עם קוד ⌨️'**
  String get friendChallengeJoinWithCodeButton;

  /// שם גיבוי גנרי 'חבר'
  ///
  /// In he, this message translates to:
  /// **'חבר'**
  String get friendChallengeFriendFallback;

  /// שם גיבוי 'החבר' (עם ה' הידיעה)
  ///
  /// In he, this message translates to:
  /// **'החבר'**
  String get friendChallengeTheFriendFallback;

  /// תווית הקוד שלי
  ///
  /// In he, this message translates to:
  /// **'הקוד שלך'**
  String get friendChallengeYourCodeLabel;

  /// כפתור שתף קוד
  ///
  /// In he, this message translates to:
  /// **'שתף קוד'**
  String get friendChallengeShareCodeButton;

  /// הודעת המתנה שהחבר יזין את הקוד
  ///
  /// In he, this message translates to:
  /// **'ממתין ש{friendName} יזין את הקוד… {time}'**
  String friendChallengeWaitingForFriendToEnter(String friendName, String time);

  /// תווית ממתין על כרטיס החבר
  ///
  /// In he, this message translates to:
  /// **'ממתין…'**
  String get friendChallengeWaitingEllipsis;

  /// כותרת כרטיס תנאי המשחק
  ///
  /// In he, this message translates to:
  /// **'תנאי ה{mode}'**
  String friendChallengeConditionsTitle(String mode);

  /// כותרת תצוגת הזמנה שהתקבלה
  ///
  /// In he, this message translates to:
  /// **'אתגר מ-{name}'**
  String friendChallengeInviteFromName(String name);

  /// כפתור הצטרפות למשחק
  ///
  /// In he, this message translates to:
  /// **'הצטרף ל{mode} {emoji}'**
  String friendChallengeJoinModeButton(String mode, String emoji);

  /// כותרת החבר דחה את ההזמנה
  ///
  /// In he, this message translates to:
  /// **'{name} דחה את ההזמנה'**
  String friendChallengeDeclinedTitle(String name);

  /// הודעת החבר דחה את ההזמנה
  ///
  /// In he, this message translates to:
  /// **'אפשר לנסות שוב מאוחר יותר, או להזמין חבר אחר.'**
  String get friendChallengeDeclinedMessage;

  /// כותרת קוד פג תוקף
  ///
  /// In he, this message translates to:
  /// **'הקוד פג תוקף'**
  String get friendChallengeExpiredTitle;

  /// הודעת קוד פג תוקף
  ///
  /// In he, this message translates to:
  /// **'החבר לא הספיק להצטרף בזמן. אפשר ליצור קוד חדש.'**
  String get friendChallengeExpiredMessage;

  /// כפתור יצירת קוד חדש
  ///
  /// In he, this message translates to:
  /// **'צור קוד חדש'**
  String get friendChallengeNewCodeButton;

  /// טיפ 1 במסך ממתין לחבר
  ///
  /// In he, this message translates to:
  /// **'טיפ: שלח לחבר את הקוד בוואטסאפ - הוא יקליד אותו במסך \"יש לי קוד\"'**
  String get friendChallengeWaitingTip1;

  /// טיפ 2 במסך ממתין לחבר
  ///
  /// In he, this message translates to:
  /// **'טיפ: הקוד בתוקף ל-15 דקות - אם הוא פג, פשוט תיצור קוד חדש'**
  String get friendChallengeWaitingTip2;

  /// טיפ 3 במסך ממתין לחבר
  ///
  /// In he, this message translates to:
  /// **'טיפ: שני השחקנים מקבלים בדיוק אותם לוגואים - הראשון שמסיים מנצח'**
  String get friendChallengeWaitingTip3;

  /// טיפ 4 במסך ממתין לחבר
  ///
  /// In he, this message translates to:
  /// **'טיפ: אפשר לקנות רמז זול בתוך הדו-קרב אם נתקעים על לוגו'**
  String get friendChallengeWaitingTip4;

  /// כותרת מסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'מכינים את השלב…'**
  String get levelLoadingTitle;

  /// כותרת כרטיס טיפ
  ///
  /// In he, this message translates to:
  /// **'ידעת?'**
  String get levelLoadingDidYouKnow;

  /// טיפ 1 במסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'רצף של 5 תשובות נכונות מכפיל את ה-XP שתקבלו בשלב הבא'**
  String get levelLoadingTip1;

  /// טיפ 2 במסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'נגמרו המטבעות? אפשר לצפות בפרסומת ולקבל רמז אות אחת בחינם'**
  String get levelLoadingTip2;

  /// טיפ 3 במסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'פתרון עצמאי (בלי רמזים) מזכה תמיד ביותר XP מפתרון עם רמז'**
  String get levelLoadingTip3;

  /// טיפ 4 במסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'במצב אתגר רנדומלי הרצף נשמר גם כשיוצאים - הוא מתאפס רק אם טועים במילה'**
  String get levelLoadingTip4;

  /// טיפ 5 במסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'כל רמז-אות שמשתמשים בו מוריד נקודת XP אחת מהפרס על פתרון השלב'**
  String get levelLoadingTip5;

  /// טיפ 6 במסך טעינת שלב
  ///
  /// In he, this message translates to:
  /// **'אפשר להזמין חברים למשחק ולהתחרות יחד על המקום הראשון בטבלה הארצית'**
  String get levelLoadingTip6;

  /// תווית טאב חנות בסרגל התחתון
  ///
  /// In he, this message translates to:
  /// **'חנות'**
  String get appBottomNavShop;

  /// תווית טאב מובילים בסרגל התחתון
  ///
  /// In he, this message translates to:
  /// **'מובילים'**
  String get appBottomNavLeaderboard;

  /// תווית טאב משימות בסרגל התחתון
  ///
  /// In he, this message translates to:
  /// **'משימות'**
  String get appBottomNavMissions;

  /// תווית טאב חברים בסרגל התחתון
  ///
  /// In he, this message translates to:
  /// **'חברים'**
  String get appBottomNavFriends;

  /// תווית כפתור הבית המרכזי (שחק) בסרגל התחתון
  ///
  /// In he, this message translates to:
  /// **'שחק'**
  String get appBottomNavPlay;

  /// תווית כפתור הבית המרכזי (בית) בסרגל התחתון המשותף - מסכי טאב אחרים, לא מסך הבית עצמו
  ///
  /// In he, this message translates to:
  /// **'בית'**
  String get appBottomNavHome;

  /// שם האפליקציה במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'זהה את הלוגו!'**
  String get appLoadingTitle;

  /// חלק קטן (פיל) של כותרת מסך הטעינה - לפני המילה המונפשת
  ///
  /// In he, this message translates to:
  /// **'זהה את'**
  String get appLoadingTitlePrefix;

  /// חלק גדול ומונפש (אות-אות) של כותרת מסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'הלוגו!'**
  String get appLoadingTitleMain;

  /// משפט קריצה במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'אלפי לוגואים מחכים לך. כמה תזהה?'**
  String get appLoadingTagline;

  /// תווית 'טיפ' בכרטיס הטיפ במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'טיפ'**
  String get appLoadingTipLabel;

  /// טיפ 1 במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'רצף ימים מכפיל את המתנה היומית'**
  String get appLoadingTip1;

  /// טיפ 2 במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'תקועים? רמז חושף אות אחת מהתשובה'**
  String get appLoadingTip2;

  /// טיפ 3 במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'בדו־קרב המנצח לוקח את כל הקופה'**
  String get appLoadingTip3;

  /// טיפ 4 במסך הטעינה
  ///
  /// In he, this message translates to:
  /// **'השלימו משימות כדי לעלות בלוגו פאס'**
  String get appLoadingTip4;

  /// סטטוס טעינה - בודקים גרסה
  ///
  /// In he, this message translates to:
  /// **'בודקים גרסה...'**
  String get mainCheckingVersion;

  /// סטטוס טעינה - מתחברים לשרת
  ///
  /// In he, this message translates to:
  /// **'מתחברים לשרת...'**
  String get mainConnectingToServer;

  /// סטטוס טעינה - בודקים משחק פעיל
  ///
  /// In he, this message translates to:
  /// **'בודקים משחק פעיל...'**
  String get mainCheckingActiveGame;

  /// סטטוס טעינה - כמעט מוכנים
  ///
  /// In he, this message translates to:
  /// **'כמעט מוכנים...'**
  String get mainAlmostReady;

  /// סטטוס טעינה - מוכנים
  ///
  /// In he, this message translates to:
  /// **'מוכנים'**
  String get mainReady;

  /// אזהרת צילום מסך
  ///
  /// In he, this message translates to:
  /// **'שים לב: צילומי מסך מהמשחק אסורים לשיתוף מחוץ לאפליקציה'**
  String get mainScreenshotWarning;

  /// תת-כותרת פופאפ בונוס הפניה - צד המותקן החדש
  ///
  /// In he, this message translates to:
  /// **'כי הורדת את המשחק דרך ההזמנה של {name}! 🎉'**
  String mainReferralDownloadedSubtitle(String name);

  /// תת-כותרת פופאפ בונוס הפניה - צד המזמין
  ///
  /// In he, this message translates to:
  /// **'חבר הצטרף למשחק דרך ההזמנה שלך! 🎉'**
  String get mainReferralFriendJoinedSubtitle;

  /// כותרת דיאלוג הזמנה נכנסת
  ///
  /// In he, this message translates to:
  /// **'{name} מזמין אותך!'**
  String mainInviteFromName(String name);

  /// הודעה שאין היסטוריית דו-קרב
  ///
  /// In he, this message translates to:
  /// **'עדיין לא שיחקתם דו-קרב אחד נגד השני'**
  String get mainNoHeadToHeadYet;

  /// הודעה בהזמנה למרוץ
  ///
  /// In he, this message translates to:
  /// **'מוזמן למרוץ לוגואים 1 על 1'**
  String get mainInvitedToRace;

  /// מאזן ראש בראש בהזמנה נכנסת
  ///
  /// In he, this message translates to:
  /// **'מאזן ביניכם: {mine} — {theirs} {side}'**
  String mainHeadToHeadBalance(int mine, int theirs, String side);

  /// מילה - תיקו
  ///
  /// In he, this message translates to:
  /// **'תיקו'**
  String get mainTie;

  /// מאזן לטובתך
  ///
  /// In he, this message translates to:
  /// **'לטובתך'**
  String get mainInYourFavor;

  /// מאזן לטובתו
  ///
  /// In he, this message translates to:
  /// **'לטובתו'**
  String get mainInTheirFavor;

  /// כפתור קבלת אתגר דו-קרב
  ///
  /// In he, this message translates to:
  /// **'מקבל את האתגר ⚔'**
  String get mainAcceptDuelChallenge;

  /// כפתור קבלת אתגר מרוץ
  ///
  /// In he, this message translates to:
  /// **'מקבל את האתגר 🏁'**
  String get mainAcceptRaceChallenge;

  /// עלות אנרגיה עם כמות נוכחית
  ///
  /// In he, this message translates to:
  /// **'עולה {cost} ⚡ · יש לך {energy}'**
  String mainAcceptCostWithEnergy(int cost, int energy);

  /// עלות אנרגיה בלבד
  ///
  /// In he, this message translates to:
  /// **'עולה {cost} ⚡'**
  String mainAcceptCost(int cost);

  /// כפתור דחיית הזמנה
  ///
  /// In he, this message translates to:
  /// **'דחה'**
  String get mainDeclineButton;

  /// תג עליון בדיאלוג הזמנה נכנסת
  ///
  /// In he, this message translates to:
  /// **'⚔ הזמנה לדו־קרב'**
  String get mainInviteBadge;

  /// שם עולם 1
  ///
  /// In he, this message translates to:
  /// **'חברות חלק א'**
  String get worldName1;

  /// שם עולם 2
  ///
  /// In he, this message translates to:
  /// **'דגלים חלק א'**
  String get worldName2;

  /// שם עולם 3
  ///
  /// In he, this message translates to:
  /// **'אפליקציות'**
  String get worldName3;

  /// שם עולם 4
  ///
  /// In he, this message translates to:
  /// **'רכבים'**
  String get worldName4;

  /// שם עולם 5
  ///
  /// In he, this message translates to:
  /// **'סופרים'**
  String get worldName5;

  /// שם עולם 6
  ///
  /// In he, this message translates to:
  /// **'רשתות מוכרות'**
  String get worldName6;

  /// שם עולם 7
  ///
  /// In he, this message translates to:
  /// **'חטיפים וממתקים'**
  String get worldName7;

  /// שם עולם 8
  ///
  /// In he, this message translates to:
  /// **'קבוצות כדורגל'**
  String get worldName8;

  /// שם עולם 9
  ///
  /// In he, this message translates to:
  /// **'ערים בישראל'**
  String get worldName9;

  /// שם עולם 10
  ///
  /// In he, this message translates to:
  /// **'דגלים חלק ב'**
  String get worldName10;

  /// שם עולם 11
  ///
  /// In he, this message translates to:
  /// **'בנקים וביטוח'**
  String get worldName11;

  /// שם עולם 12
  ///
  /// In he, this message translates to:
  /// **'חברות חלק ב'**
  String get worldName12;

  /// שם עולם 13
  ///
  /// In he, this message translates to:
  /// **'משחקים מוכרים'**
  String get worldName13;

  /// שם עולם 14
  ///
  /// In he, this message translates to:
  /// **'קבוצות NBA'**
  String get worldName14;

  /// שם עולם 15
  ///
  /// In he, this message translates to:
  /// **'יחידות בצה\"ל וכוחות הביטחון'**
  String get worldName15;

  /// שם עולם 16
  ///
  /// In he, this message translates to:
  /// **'רכבים חלק ב'**
  String get worldName16;

  /// שם עולם 17
  ///
  /// In he, this message translates to:
  /// **'אלקטרוניקה ומכשירי חשמל'**
  String get worldName17;

  /// שם עולם 18
  ///
  /// In he, this message translates to:
  /// **'תקשורת וחדשות ישראליות'**
  String get worldName18;

  /// שם עולם 22
  ///
  /// In he, this message translates to:
  /// **'קבוצות NFL'**
  String get worldName22;

  /// שם עולם ברירת מחדל
  ///
  /// In he, this message translates to:
  /// **'כללי'**
  String get worldNameDefault;

  /// הודעת קיבלת בונוס פרסומת מטבעות
  ///
  /// In he, this message translates to:
  /// **'קיבלת 15 מטבעות!'**
  String get mainMenuCollected15Coins;

  /// כפתור סגור
  ///
  /// In he, this message translates to:
  /// **'סגור'**
  String get mainMenuCloseButton;

  /// כותרת דיאלוג רצף כניסה
  ///
  /// In he, this message translates to:
  /// **'יום {day} ברצף!'**
  String mainMenuStreakDayTitle(int day);

  /// תת-כותרת דיאלוג רצף כניסה
  ///
  /// In he, this message translates to:
  /// **'תחזור מחר לפרס גדול יותר'**
  String get mainMenuComeBackTomorrow;

  /// תווית אנרגיה בפרס היומי
  ///
  /// In he, this message translates to:
  /// **'אנרגיה '**
  String get mainMenuEnergyLabel;

  /// תווית מטבעות בפרס היומי
  ///
  /// In he, this message translates to:
  /// **'מטבעות '**
  String get mainMenuCoinsLabel;

  /// כפתור איסוף פרס
  ///
  /// In he, this message translates to:
  /// **'אסוף'**
  String get mainMenuCollectButton;

  /// כותרת מסך ברוכים הבאים
  ///
  /// In he, this message translates to:
  /// **'ברוכים הבאים!'**
  String get mainMenuWelcomeTitle;

  /// תת-כותרת מסך ברוכים הבאים
  ///
  /// In he, this message translates to:
  /// **'התחבר כדי שההתקדמות שלך תישמר גם אם תחליף מכשיר, או פשוט שחק'**
  String get mainMenuWelcomeSubtitle;

  /// כפתור שחק כאורח
  ///
  /// In he, this message translates to:
  /// **'שחק כאורח'**
  String get mainMenuPlayAsGuest;

  /// הודעת תנאי שימוש
  ///
  /// In he, this message translates to:
  /// **'בהמשך אתם מאשרים את תנאי השימוש ומדיניות הפרטיות'**
  String get mainMenuTermsNotice;

  /// הודעת כישלון התחברות כללית
  ///
  /// In he, this message translates to:
  /// **'ההתחברות נכשלה, נסה שוב מאוחר יותר'**
  String get mainMenuSignInFailed;

  /// הודעת כישלון התחברות Google
  ///
  /// In he, this message translates to:
  /// **'ההתחברות עם Google נכשלה - אפשר לנסות שוב או לשחק כאורח בינתיים'**
  String get mainMenuGoogleSignInFailed;

  /// הודעת כישלון התחברות Apple
  ///
  /// In he, this message translates to:
  /// **'ההתחברות עם Apple נכשלה - אפשר לנסות שוב או לשחק כאורח בינתיים'**
  String get mainMenuAppleSignInFailed;

  /// תת-כותרת שדה הזנת שם
  ///
  /// In he, this message translates to:
  /// **'איך נקרא לך בטבלה הארצית?'**
  String get mainMenuNameEntrySubtitle;

  /// כפתור בואו נתחיל
  ///
  /// In he, this message translates to:
  /// **'בואו נתחיל ›'**
  String get mainMenuLetsStartButton;

  /// כפתור דלג בהדרכה
  ///
  /// In he, this message translates to:
  /// **'דלג'**
  String get mainMenuSkipButton;

  /// כותרת כרטיסיית ברוכים הבאים בהדרכה
  ///
  /// In he, this message translates to:
  /// **'ברוכים הבאים ל\"זהה את הלוגו!\" 🎉'**
  String get mainMenuTourWelcomeTitle;

  /// תוכן כרטיסיית ברוכים הבאים בהדרכה
  ///
  /// In he, this message translates to:
  /// **'בואו נראה לכם בקצרה איך המשחק עובד - זה ייקח רק חצי דקה, ואפשר לדלג בכל שלב.'**
  String get mainMenuTourWelcomeBody;

  /// כותרת שלב 1 בהדרכה
  ///
  /// In he, this message translates to:
  /// **'שחק מול אחרים'**
  String get mainMenuTourStep1Title;

  /// תוכן שלב 1 בהדרכה
  ///
  /// In he, this message translates to:
  /// **'דו-קרב, מירוץ וסדרת דו-קרב נגד שחקנים אמיתיים בזמן אמת.'**
  String get mainMenuTourStep1Body;

  /// כותרת שלב 2 בהדרכה
  ///
  /// In he, this message translates to:
  /// **'אתגר רנדומלי'**
  String get mainMenuTourStep2Title;

  /// תוכן שלב 2 בהדרכה
  ///
  /// In he, this message translates to:
  /// **'לוגו רנדומלי בכל פעם - פותר נכון שומר על הרצף (🔥) שרואים כאן.'**
  String get mainMenuTourStep2Body;

  /// כותרת שלב 3 בהדרכה
  ///
  /// In he, this message translates to:
  /// **'כאן מתחילים לשחק'**
  String get mainMenuTourStep3Title;

  /// תוכן שלב 3 בהדרכה
  ///
  /// In he, this message translates to:
  /// **'כפתור \"שחקו את רמה X\" לוקח אתכם למסך השלבים, שם בוחרים את העולם והלוגו הבא לשחק בו. לחצו על הכפתור המואר כדי להתחיל!'**
  String get mainMenuTourStep3Body;

  /// מונה שלב בהדרכה
  ///
  /// In he, this message translates to:
  /// **'{step} מתוך {count}'**
  String mainMenuTourProgress(int step, int count);

  /// הנחיה ללחוץ על הכרטיס המואר
  ///
  /// In he, this message translates to:
  /// **'לחצו על הכרטיס המואר למעלה'**
  String get mainMenuTourTapHighlighted;

  /// כפתור הבא בהדרכה
  ///
  /// In he, this message translates to:
  /// **'הבא'**
  String get mainMenuTourNextButton;

  /// פיל התקדמות רמה
  ///
  /// In he, this message translates to:
  /// **'רמה {world} • לוגו {sub} מתוך {count}'**
  String mainMenuLevelPill(int world, int sub, int count);

  /// טקסט תחת תצוגת הלוגו הבא
  ///
  /// In he, this message translates to:
  /// **'מוכנים לזהות את הלוגו הבא?'**
  String get mainMenuNextLogoTeaser;

  /// כפתור שחקו את רמה X
  ///
  /// In he, this message translates to:
  /// **'שחקו את רמה {world}'**
  String mainMenuPlayLevelButton(int world);

  /// תת-כותרת אתגר יומי שהושלם
  ///
  /// In he, this message translates to:
  /// **'קיבלת את הפרס - חוזר מחר'**
  String get mainMenuDailyRewardClaimed;

  /// תת-כותרת אתגר יומי שנוצל
  ///
  /// In he, this message translates to:
  /// **'נוצל להיום, נסה מחר'**
  String get mainMenuDailyUsedUp;

  /// תת-כותרת באטל פאס עם פרסים ממתינים
  ///
  /// In he, this message translates to:
  /// **'דרגה {tier} • {claims} פרסים מחכים'**
  String mainMenuBpSubtitleWithClaims(int tier, int claims);

  /// תת-כותרת באטל פאס - דרגה בלבד
  ///
  /// In he, this message translates to:
  /// **'דרגה {tier}'**
  String mainMenuBpTier(int tier);

  /// כותרת כרטיס אתגר רנדומלי בגריד הבית
  ///
  /// In he, this message translates to:
  /// **'רנדומלי'**
  String get mainMenuRandomTitle;

  /// תת-כותרת כרטיס אתגר רנדומלי
  ///
  /// In he, this message translates to:
  /// **'לוגו אקראי • רצף {streak} 🔥'**
  String mainMenuRandomSubtitle(int streak);

  /// תווית אתגר רנדומלי (למסך טעינת שלב)
  ///
  /// In he, this message translates to:
  /// **'אתגר רנדומלי'**
  String get mainMenuRandomChallengeLabel;

  /// כותרת כרטיס מול אחרים בגריד הבית
  ///
  /// In he, this message translates to:
  /// **'מול אחרים'**
  String get mainMenuVsOthersTitle;

  /// תת-כותרת כרטיס מול אחרים
  ///
  /// In he, this message translates to:
  /// **'3 מודים • {count} מחוברים'**
  String mainMenuVsOthersSubtitle(int count);

  /// כותרת כרטיס/תג באטל פאס
  ///
  /// In he, this message translates to:
  /// **'לוגו פאס'**
  String get mainMenuBattlePassTitle;

  /// כותרת כרטיס אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי'**
  String get mainMenuDailyChallengeTitle;

  /// שם גיבוי כשאין שם משתמש
  ///
  /// In he, this message translates to:
  /// **'שלום!'**
  String get mainMenuHelloFallback;

  /// מונה מדליות בשורת הפרופיל הישנה
  ///
  /// In he, this message translates to:
  /// **'🎖️ {earned}/{total} מדליות'**
  String mainMenuMedalsCount(int earned, int total);

  /// זמן שנותר עד לאנרגיה הבאה
  ///
  /// In he, this message translates to:
  /// **'עוד {time}'**
  String mainMenuMoreTime(String time);

  /// תווית ממשיכים בכרטיס התקדמות שלבים הישן
  ///
  /// In he, this message translates to:
  /// **'ממשיכים'**
  String get mainMenuContinuingLabel;

  /// שם עולם ומספר שלב
  ///
  /// In he, this message translates to:
  /// **'{worldName} · שלב {sub}'**
  String mainMenuWorldStepLabel(String worldName, int sub);

  /// כותרת כרטיס שחק מול אחרים הישן
  ///
  /// In he, this message translates to:
  /// **'שחק מול אחרים'**
  String get mainMenuPlayVsOthersTitle;

  /// תת-כותרת כרטיס שחק מול אחרים הישן
  ///
  /// In he, this message translates to:
  /// **'דו־קרב · מירוץ'**
  String get mainMenuDuelRaceNote;

  /// תת-כותרת כרטיס אתגר רנדומלי הישן
  ///
  /// In he, this message translates to:
  /// **'לוגו אקראי · שומר על הרצף'**
  String get mainMenuRandomNote;

  /// כותרת כרטיס מרוץ לוגואים הישן
  ///
  /// In he, this message translates to:
  /// **'מרוץ לוגואים 🏁'**
  String get mainMenuLogoRaceTitle;

  /// תת-כותרת כרטיס מרוץ לוגואים הישן
  ///
  /// In he, this message translates to:
  /// **'1 על 1 · מי שמנחש ראשון מנצח'**
  String get mainMenuLogoRaceSubtitle;

  /// כפתור שחק גנרי
  ///
  /// In he, this message translates to:
  /// **'שחק'**
  String get mainMenuPlayButton;

  /// הודעת קיבלת אנרגיה מפרסומת
  ///
  /// In he, this message translates to:
  /// **'קיבלת {amount} אנרגיה! ⚡'**
  String mainMenuEnergyRewardMessage(int amount);

  /// תת-כותרת כרטיס אתגר יומי הישן - הושלם
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי · קיבלת את הפרס - חוזר מחר'**
  String get mainMenuDailyChallengeSubtitleDone;

  /// תת-כותרת כרטיס אתגר יומי הישן - נוצל
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי · נוצל להיום, נסה מחר'**
  String get mainMenuDailyChallengeSubtitleUsedUp;

  /// תת-כותרת כרטיס אתגר יומי הישן - ברירת מחדל
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי · {count} לוגואים'**
  String mainMenuDailyChallengeSubtitleDefault(int count);

  /// תווית בוצע על כפתור אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'בוצע ✓'**
  String get mainMenuDoneCheckLabel;

  /// תווית תזכורת על כפתור אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'תזכורת'**
  String get mainMenuReminderLabel;

  /// תווית מקסימום בכרטיס באטל פאס
  ///
  /// In he, this message translates to:
  /// **'מקסימום'**
  String get mainMenuMaxLabel;

  /// תג מספר פרסים ממתינים
  ///
  /// In he, this message translates to:
  /// **'{claims} פרסים'**
  String mainMenuClaimsCount(int claims);

  /// הודעה שהפרס היומי כבר נאסף
  ///
  /// In he, this message translates to:
  /// **'כבר נאסף היום - תחזור מחר לפרס הבא'**
  String get mainMenuAlreadyClaimedToday;

  /// הודעת זכייה במארז היהלום
  ///
  /// In he, this message translates to:
  /// **'מזל טוב - זכית במארז היהלום של יום 7!'**
  String get mainMenuDiamondWonToday;

  /// הודעה שהיום הוא יום 7
  ///
  /// In he, this message translates to:
  /// **'היום היום הגדול - יום 7 ומארז היהלום!'**
  String get mainMenuDiamondTodayIsDay7;

  /// הודעה שנותר יום אחד למארז היהלום
  ///
  /// In he, this message translates to:
  /// **'עוד יום אחד - ומקבל מארז יהלום'**
  String get mainMenuDiamondOneDayLeft;

  /// הודעה שנותרו כמה ימים למארז היהלום
  ///
  /// In he, this message translates to:
  /// **'עוד {days} ימים - ומקבל מארז יהלום'**
  String mainMenuDiamondDaysLeft(int days);

  /// כותרת הפרס של היום בדיאלוג המתנות
  ///
  /// In he, this message translates to:
  /// **'הפרס של היום'**
  String get mainMenuTodaysRewardLabel;

  /// שורת תזכורת דקורטיבית
  ///
  /// In he, this message translates to:
  /// **'תזכורת מחר · 20:00'**
  String get mainMenuReminderTomorrow8pm;

  /// כותרת כרטיס פרסומת אנרגיה
  ///
  /// In he, this message translates to:
  /// **'צריך אנרגיה?'**
  String get mainMenuNeedEnergyTitle;

  /// תת-כותרת כרטיס פרסומת אנרגיה
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת - קבל {amount} אנרגיה מיידית'**
  String mainMenuWatchAdEnergySubtitle(int amount);

  /// כפתור צפה (בפרסומת)
  ///
  /// In he, this message translates to:
  /// **'צפה'**
  String get mainMenuWatchButton;

  /// כותרת כרטיס בונוס פרסומת
  ///
  /// In he, this message translates to:
  /// **'בונוס פרסומת'**
  String get mainMenuAdBonusTitle;

  /// תת-כותרת כרטיס בונוס פרסומת מטבעות
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת - קבל 15 מטבעות'**
  String get mainMenuWatchAdCoinsSubtitle;

  /// זמן עד שבונוס הפרסומת זמין שוב
  ///
  /// In he, this message translates to:
  /// **'זמין שוב בעוד {time}'**
  String mainMenuAvailableAgainIn(String time);

  /// תווית ממתין על כפתור בונוס פרסומת
  ///
  /// In he, this message translates to:
  /// **'ממתין'**
  String get mainMenuWaitingLabel;

  /// תווית בהמתנה על כפתור בונוס פרסומת (וריאציה)
  ///
  /// In he, this message translates to:
  /// **'בהמתנה'**
  String get mainMenuWaitingLabel2;

  /// טקסט שיתוף הזמנת חברים מהבית
  ///
  /// In he, this message translates to:
  /// **'בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n📱 אייפון: {ios}\n🤖 אנדרואיד/גלקסי: {android}'**
  String mainMenuInviteShareText(String ios, String android);

  /// טקסט placeholder בשדה הזנת שם
  ///
  /// In he, this message translates to:
  /// **'הקלד את שמך כאן...'**
  String get mainMenuNameHint;

  /// הודעת בדיקת זמינות שם
  ///
  /// In he, this message translates to:
  /// **'בודק זמינות...'**
  String get mainMenuCheckingAvailability;

  /// הודעת שם פנוי
  ///
  /// In he, this message translates to:
  /// **'השם פנוי'**
  String get mainMenuNameAvailable;

  /// הודעת שם תפוס
  ///
  /// In he, this message translates to:
  /// **'השם הזה כבר תפוס, נסה שם אחר'**
  String get mainMenuNameTaken;

  /// כותרת מסך הישגים
  ///
  /// In he, this message translates to:
  /// **'הישגים ומדליות'**
  String get achievementsTitle;

  /// מונה מדליות שהושגו
  ///
  /// In he, this message translates to:
  /// **'{earned} מתוך {total} מדליות'**
  String achievementsEarnedCount(int earned, int total);

  /// תיאור מסך הישגים
  ///
  /// In he, this message translates to:
  /// **'כל הישג נותן מטבעות. ההתקדמות שלכם נספרת מכאן, לא משנה כמה XP יש לאחרים.'**
  String get achievementsDescription;

  /// הודעת קבלת פרס על הישג
  ///
  /// In he, this message translates to:
  /// **'קיבלת {coins} מטבעות על \"{title}\"'**
  String achievementsClaimedMessage(int coins, String title);

  /// כותרת ברירת מחדל של מסך אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'אתגר היומי'**
  String get dailyChallengeTitle;

  /// כותרת מסך כבר השלמת
  ///
  /// In he, this message translates to:
  /// **'כבר השלמת את האתגר היומי!'**
  String get dailyChallengeAlreadyDoneTitle;

  /// תת-כותרת מסך כבר השלמת
  ///
  /// In he, this message translates to:
  /// **'לוגו חדש ואתגר חדש מחכים לך מחר'**
  String get dailyChallengeComeBackTomorrow;

  /// כותרת מסך כבר ניסית
  ///
  /// In he, this message translates to:
  /// **'כבר ניסית את האתגר היומי'**
  String get dailyChallengeUsedUpTitle;

  /// תת-כותרת מסך כבר ניסית
  ///
  /// In he, this message translates to:
  /// **'יש רק ניסיון אחד ליום - נסה שוב מחר עם אתגר חדש'**
  String get dailyChallengeUsedUpMessage;

  /// סטטיסטיקות מסך הקדמה
  ///
  /// In he, this message translates to:
  /// **'{count} לוגואים · {seconds} שניות בסך הכל'**
  String dailyChallengeIntroStats(int count, int seconds);

  /// תוכן מסך הקדמה
  ///
  /// In he, this message translates to:
  /// **'פתור את כל הלוגואים ברצף לפני שהזמן נגמר וזכה בבונוס. אין רמזים במסך הזה - זה מבחן מהירות!'**
  String get dailyChallengeIntroBody;

  /// אזהרת ניסיון יחיד ליום
  ///
  /// In he, this message translates to:
  /// **'⚠️ יש לך רק ניסיון אחד ליום - גם אם תיכשל'**
  String get dailyChallengeOneAttemptWarning;

  /// כפתור התחלת אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'מוכן? התחל! ⚡'**
  String get dailyChallengeStartButton;

  /// כותרת הצלחה
  ///
  /// In he, this message translates to:
  /// **'כל הכבוד! 🎉'**
  String get dailyChallengeSuccessTitle;

  /// זמן סיום אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'סיימת את אתגר היום ב-{seconds} שניות'**
  String dailyChallengeSuccessTime(String seconds);

  /// כותרת נגמר הזמן
  ///
  /// In he, this message translates to:
  /// **'נגמר הזמן! ⏱️'**
  String get dailyChallengeTimeUpTitle;

  /// התקדמות בעת כישלון
  ///
  /// In he, this message translates to:
  /// **'הגעת ללוגו {current} מתוך {total} - ניצלת את הניסיון היחיד של היום'**
  String dailyChallengeFailedProgress(int current, int total);

  /// הודעת נסה שוב מחר
  ///
  /// In he, this message translates to:
  /// **'נסה שוב מחר עם אתגר חדש'**
  String get dailyChallengeTryTomorrow;

  /// כפתור תזכורת שהוגדרה
  ///
  /// In he, this message translates to:
  /// **'נזכיר לך מחר!'**
  String get dailyChallengeReminderSet;

  /// כפתור הגדרת תזכורת
  ///
  /// In he, this message translates to:
  /// **'תזכיר לי מחר'**
  String get dailyChallengeRemindMe;

  /// שם עולם 19
  ///
  /// In he, this message translates to:
  /// **'דגלים חלק ג\''**
  String get worldName19;

  /// שם עולם 20
  ///
  /// In he, this message translates to:
  /// **'אלקטרוניקה ומכשירי חשמל חלק ב'**
  String get worldName20;

  /// שם עולם 21
  ///
  /// In he, this message translates to:
  /// **'כדורסל אירופי (יורוליג)'**
  String get worldName21;

  /// שם עולם 23
  ///
  /// In he, this message translates to:
  /// **'קבוצות כדורגל ישראליות'**
  String get worldName23;

  /// שם עולם 24
  ///
  /// In he, this message translates to:
  /// **'אולפני סרטים ובידור'**
  String get worldName24;

  /// שם עולם 25
  ///
  /// In he, this message translates to:
  /// **'חברות תעופה'**
  String get worldName25;

  /// שם עולם 26
  ///
  /// In he, this message translates to:
  /// **'קבוצות כדורגל אירופאיות חלק ב\''**
  String get worldName26;

  /// מחיר פתיחת רמה כברירת מחדל
  ///
  /// In he, this message translates to:
  /// **'₪2.90'**
  String get levelsUnlockPriceFallback;

  /// כותרת דיאלוג פתיחת רמה
  ///
  /// In he, this message translates to:
  /// **'רמה {world} נעולה'**
  String levelsUnlockDialogTitle(int world);

  /// תוכן דיאלוג פתיחת הרמה הבאה
  ///
  /// In he, this message translates to:
  /// **'אפשר לפתוח אותה עכשיו תמורת {price},\nאו פשוט לסיים את הרמה הקודמת.'**
  String levelsUnlockDialogBodyNext(String price);

  /// תוכן דיאלוג פתיחת רמה מרוחקת
  ///
  /// In he, this message translates to:
  /// **'פתיחת רמה עולה {price}.\nכדי להגיע לרמה {world} צריך לפתוח {needed} רמות,\nאחת אחרי השנייה - מתחילים ברמה {next}.'**
  String levelsUnlockDialogBodyFar(
    String price,
    int world,
    int needed,
    int next,
  );

  /// כפתור לא עכשיו בדיאלוג פתיחת רמה
  ///
  /// In he, this message translates to:
  /// **'לא עכשיו'**
  String get levelsNotNowButton;

  /// כפתור פתיחת רמה עם מחיר
  ///
  /// In he, this message translates to:
  /// **'פתח רמה {next}  •  {price}'**
  String levelsUnlockButton(int next, String price);

  /// הודעת שגיאה כשפתיחת רמות לא זמינה
  ///
  /// In he, this message translates to:
  /// **'פתיחת רמות אינה זמינה כרגע, נסה שוב מאוחר יותר'**
  String get levelsUnlockUnavailable;

  /// כותרת מסך בחירת רמה
  ///
  /// In he, this message translates to:
  /// **'בחר רמה'**
  String get levelsChooseLevelTitle;

  /// תת-כותרת מספר רמות פתוחות
  ///
  /// In he, this message translates to:
  /// **'{total} רמות · {unlocked} פתוחות'**
  String levelsCountSubtitle(int total, int unlocked);

  /// תווית רמת קושי
  ///
  /// In he, this message translates to:
  /// **'קושי {level}'**
  String levelsDifficultyLabel(int level);

  /// תת-כותרת רמה נעולה
  ///
  /// In he, this message translates to:
  /// **'נעול · ניתן לפתוח בתשלום'**
  String get levelsLockedSubtitle;

  /// התקדמות בתוך עולם
  ///
  /// In he, this message translates to:
  /// **'{solved} מתוך {total} שלבים'**
  String levelsSolvedOfTotal(int solved, int total);

  /// כותרת כרטיסיית הסבר מסך השלבים
  ///
  /// In he, this message translates to:
  /// **'מסך השלבים'**
  String get levelsTourTitle;

  /// תוכן כרטיסיית הסבר מסך השלבים
  ///
  /// In he, this message translates to:
  /// **'כל עולם נפתח אוטומטית ברגע שמסיימים את העולם הקודם - בלי שום פעולה נוספת.'**
  String get levelsTourBody;

  /// כפתור המשך בהסבר מסך השלבים
  ///
  /// In he, this message translates to:
  /// **'המשך ›'**
  String get levelsTourContinueButton;

  /// הנחיה ללחוץ על העולם המואר
  ///
  /// In he, this message translates to:
  /// **'לחצו על העולם המואר כדי להמשיך'**
  String get levelsTourTapHighlighted;

  /// תווית קטגוריה ומספר שלב (מסך טעינה)
  ///
  /// In he, this message translates to:
  /// **'{category} · שלב {stage}'**
  String subLevelsCategoryStageLabel(String category, int stage);

  /// הודעה בלחיצה על שלב נעול
  ///
  /// In he, this message translates to:
  /// **'המילה נעולה! פתור את הקודמות.'**
  String get subLevelsLockedMessage;

  /// הודעה בלחיצה על שלב שהושלם
  ///
  /// In he, this message translates to:
  /// **'כבר מצאת את הלוגו הזה!'**
  String get subLevelsAlreadyFoundMessage;

  /// כותרת כרטיס ההתקדמות
  ///
  /// In he, this message translates to:
  /// **'ההתקדמות שלך'**
  String get subLevelsYourProgressTitle;

  /// הודעה כשכל השלבים בעולם הושלמו
  ///
  /// In he, this message translates to:
  /// **'כל השלבים הושלמו!'**
  String get subLevelsAllCompletedMessage;

  /// הודעת השלב הבא לפתרון
  ///
  /// In he, this message translates to:
  /// **'השלב הבא: שלב {stage}'**
  String subLevelsNextStageMessage(int stage);

  /// מספר שלבים שהושלמו
  ///
  /// In he, this message translates to:
  /// **'✓ {count} הושלמו'**
  String subLevelsDoneCount(int count);

  /// מספר שלבים שנותרו
  ///
  /// In he, this message translates to:
  /// **'· נותרו {count} שלבים'**
  String subLevelsRemainingCount(int count);

  /// תווית קטגוריה ומספר עולם בכותרת
  ///
  /// In he, this message translates to:
  /// **'{category} · רמה {world}'**
  String subLevelsCategoryWorldLabel(String category, int world);

  /// התקדמות כוללת בכותרת
  ///
  /// In he, this message translates to:
  /// **'{done} מתוך {total} שלבים הושלמו'**
  String subLevelsDoneOfTotal(int done, int total);

  /// כפתור המשך לשלב הבא
  ///
  /// In he, this message translates to:
  /// **'המשך לשלב {stage}'**
  String subLevelsContinueToStage(int stage);

  /// כותרת כרטיסיית הסבר מסך השלבים הבודדים
  ///
  /// In he, this message translates to:
  /// **'שלבים'**
  String get subLevelsTourTitle;

  /// תוכן כרטיסיית הסבר מסך השלבים הבודדים
  ///
  /// In he, this message translates to:
  /// **'כל שלב נפתח אוטומטית ברגע שפותרים את השלב הקודם - בלי שום פעולה נוספת.'**
  String get subLevelsTourBody;

  /// הנחיה ללחוץ על השלב המואר
  ///
  /// In he, this message translates to:
  /// **'לחצו על השלב המואר כדי להתחיל לשחק'**
  String get subLevelsTourTapHighlighted;

  /// תווית כפתור שחק באריח הפעיל
  ///
  /// In he, this message translates to:
  /// **'שחק'**
  String get subLevelsPlayLabel;

  /// שם ברירת מחדל לשחקן שלא הגדיר שם, נשלח לטבלה הארצית
  ///
  /// In he, this message translates to:
  /// **'שחקן אנונימי'**
  String get logoLevelAnonymousPlayerFallback;

  /// טקסט בועית תקוע בהדרכה
  ///
  /// In he, this message translates to:
  /// **'אפשר לקנות רמז עם מטבעות 💡'**
  String get logoLevelStuckTipOnboarding;

  /// טקסט בועית תקוע כשיש מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'יש לך רמז! 💡'**
  String get logoLevelStuckTipHasHint;

  /// טקסט בועית תקוע כשאפשר רמז-פרסומת חינם
  ///
  /// In he, this message translates to:
  /// **'פרסומת = רמז חינם 🎬'**
  String get logoLevelStuckTipFreeAd;

  /// טקסט בועית תקוע כשאין מטבעות וגם נוצל רמז-הפרסומת
  ///
  /// In he, this message translates to:
  /// **'לחץ למנורה 💡'**
  String get logoLevelStuckTipTapLamp;

  /// כותרת מסך אין אינטרנט
  ///
  /// In he, this message translates to:
  /// **'אין חיבור לאינטרנט'**
  String get logoLevelNoInternetTitle;

  /// תוכן מסך אין אינטרנט
  ///
  /// In he, this message translates to:
  /// **'כדי לשחק צריך חיבור פעיל לאינטרנט. בדקו את ה-WiFi או הסלולר ונסו שוב.'**
  String get logoLevelNoInternetBody;

  /// כפתור ניסיון חוזר
  ///
  /// In he, this message translates to:
  /// **'נסה שוב'**
  String get logoLevelTryAgainButton;

  /// כותרת דיאלוג סיום מצב רנדומלי
  ///
  /// In he, this message translates to:
  /// **'וואו! 🎉'**
  String get logoLevelRandomCompleteTitle;

  /// תוכן דיאלוג סיום מצב רנדומלי
  ///
  /// In he, this message translates to:
  /// **'פתרת את כל הלוגואים במצב הרנדומלי!'**
  String get logoLevelRandomCompleteBody;

  /// כפתור חזרה למסך הראשי
  ///
  /// In he, this message translates to:
  /// **'חזרה למסך הראשי'**
  String get logoLevelBackToMainScreenButton;

  /// כותרת דיאלוג אודות
  ///
  /// In he, this message translates to:
  /// **'אודות האפליקציה'**
  String get logoLevelAboutTitle;

  /// תוכן דיאלוג אודות
  ///
  /// In he, this message translates to:
  /// **'כל הלוגואים המוצגים באפליקציה זו שייכים לבעליהם בהתאמה. השימוש בלוגואים למטרות זיהוי בלבד נעשה תחת עקרון \'שימוש הוגן\'. אפליקציה זו אינה קשורה, ממומנת או מאושרת על ידי החברות המוצגות.'**
  String get logoLevelAboutBody;

  /// כפתור סגירה
  ///
  /// In he, this message translates to:
  /// **'סגור'**
  String get logoLevelCloseButton;

  /// הודעה כשאין פרסומת מתוגמלת זמינה
  ///
  /// In he, this message translates to:
  /// **'אין פרסומת זמינה כרגע, נסה שוב עוד רגע'**
  String get logoLevelNoAdAvailable;

  /// כותרת דיאלוג אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'אין לך מספיק מטבעות'**
  String get logoLevelNotEnoughCoinsTitle;

  /// תוכן דיאלוג אין מספיק מטבעות
  ///
  /// In he, this message translates to:
  /// **'הרמז הזה עולה {cost} מטבעות ויש לך רק {coins}'**
  String logoLevelNotEnoughCoinsBody(int cost, int coins);

  /// כמה מטבעות חסרים
  ///
  /// In he, this message translates to:
  /// **'חסרים {amount}'**
  String logoLevelMissingCoins(int amount);

  /// כפתור מעבר לחנות המטבעות
  ///
  /// In he, this message translates to:
  /// **'לחנות המטבעות'**
  String get logoLevelGoToShopButton;

  /// מפריד "או" בין אפשרויות
  ///
  /// In he, this message translates to:
  /// **'או'**
  String get logoLevelOrDivider;

  /// כפתור צפייה בפרסומת תמורת רמז
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת 🎬'**
  String get logoLevelWatchAdButton;

  /// הסבר קצר על רמז-הפרסומת
  ///
  /// In he, this message translates to:
  /// **'חושף אות אחת בלבד - לא פותר את כל המילה'**
  String get logoLevelAdHintDescription;

  /// הודעה שרמז-הפרסומת כבר נוצל בשלב הזה
  ///
  /// In he, this message translates to:
  /// **'כבר ניצלת רמז-פרסומת בשלב הזה 🎬'**
  String get logoLevelAdHintAlreadyUsed;

  /// כותרת דיאלוג אישור קניית רמז (מתג 'אישור לפני קניית רמז' בהגדרות)
  ///
  /// In he, this message translates to:
  /// **'לקנות רמז?'**
  String get logoLevelHintConfirmTitle;

  /// תוכן דיאלוג אישור קניית רמז
  ///
  /// In he, this message translates to:
  /// **'זה יעלה לך {cost} מטבעות.'**
  String logoLevelHintConfirmBody(int cost);

  /// כפתור אישור בדיאלוג קניית רמז
  ///
  /// In he, this message translates to:
  /// **'כן, קנה'**
  String get logoLevelHintConfirmButton;

  /// כותרת תפריט בחירת רמז
  ///
  /// In he, this message translates to:
  /// **'בחר רמז'**
  String get logoLevelChooseHintTitle;

  /// כותרת אפשרות רמז-אות
  ///
  /// In he, this message translates to:
  /// **'חשוף את האות הבאה'**
  String get logoLevelRevealNextLetterTitle;

  /// הסבר אפשרות רמז-אות
  ///
  /// In he, this message translates to:
  /// **'אות אחת נוספת מתגלה מיד'**
  String get logoLevelRevealNextLetterSubtitle;

  /// כותרת אפשרות רמז-מילה
  ///
  /// In he, this message translates to:
  /// **'פתור את כל המילה'**
  String get logoLevelSolveWholeWordTitle;

  /// הסבר אפשרות רמז-מילה
  ///
  /// In he, this message translates to:
  /// **'כל האותיות מתגלות בבת אחת'**
  String get logoLevelSolveWholeWordSubtitle;

  /// כותרת אפשרות רמז-פרסומת
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת'**
  String get logoLevelWatchAdTitle;

  /// הסבר אפשרות רמז-פרסומת
  ///
  /// In he, this message translates to:
  /// **'קבל אות אחת בחינם'**
  String get logoLevelWatchAdSubtitle;

  /// הודעת שיא רצף חדש במצב רנדומלי
  ///
  /// In he, this message translates to:
  /// **'שיא רצף חדש: {streak}!'**
  String logoLevelNewStreakRecord(int streak);

  /// הודעה כשזוהה צילום מסך חוזר
  ///
  /// In he, this message translates to:
  /// **'זוהה צילום מסך נוסף - עוברים לשלב הבא'**
  String get logoLevelRepeatedScreenshotMessage;

  /// כותרת דיאלוג סיום עולם
  ///
  /// In he, this message translates to:
  /// **'כל הכבוד! 🎉'**
  String get logoLevelLevelCompleteTitle;

  /// תוכן דיאלוג סיום עולם
  ///
  /// In he, this message translates to:
  /// **'סיימת בהצלחה את רמה {level}'**
  String logoLevelLevelCompleteBody(int level);

  /// כפתור מעבר לעולם הבא
  ///
  /// In he, this message translates to:
  /// **'לרמה {level} ›'**
  String logoLevelNextLevelButton(int level);

  /// כפתור סיום (אין עולם נוסף)
  ///
  /// In he, this message translates to:
  /// **'סיום'**
  String get logoLevelFinishButton;

  /// כותרת דיאלוג תשובה נכונה
  ///
  /// In he, this message translates to:
  /// **'כל הכבוד!'**
  String get logoLevelCorrectTitle;

  /// כותרת דיאלוג תשובה שגויה
  ///
  /// In he, this message translates to:
  /// **'טעות בשם'**
  String get logoLevelWrongTitle;

  /// טיפ הדרכה על תשובה נכונה
  ///
  /// In he, this message translates to:
  /// **'ככה בדיוק משחקים! כל תשובה נכונה מזכה אתכם בנקודות ניסיון (XP) ומטבעות'**
  String get logoLevelOnboardingCorrectTip;

  /// כפתור המשך לשלב הבא
  ///
  /// In he, this message translates to:
  /// **'המשך לשלב הבא ›'**
  String get logoLevelNextStageButton;

  /// תווית רצף במצב רנדומלי בכותרת
  ///
  /// In he, this message translates to:
  /// **'🔥 רצף {streak}'**
  String logoLevelStreakHeader(int streak);

  /// תווית מצב רנדומלי בכותרת
  ///
  /// In he, this message translates to:
  /// **'אתגר רנדומלי'**
  String get logoLevelRandomChallengeHeader;

  /// תווית שבב רמז
  ///
  /// In he, this message translates to:
  /// **'רמז'**
  String get logoLevelHintChipLabel;

  /// כותרת שלב 1 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'איפה אתם נמצאים'**
  String get logoLevelTourStep1Title;

  /// תוכן שלב 1 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'כאן רואים את הקטגוריה והשלב הנוכחי - כל לוגו שפותרים מקדם אתכם לשלב הבא.'**
  String get logoLevelTourStep1Body;

  /// כותרת שלב 2 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'זהו את הלוגו'**
  String get logoLevelTourStep2Title;

  /// תוכן שלב 2 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'זה הלוגו שצריך לזהות ולכתוב את השם שלו.'**
  String get logoLevelTourStep2Body;

  /// כותרת שלב 3 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'כאן התשובה שלכם'**
  String get logoLevelTourStep3Title;

  /// תוכן שלב 3 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'כל אות שתקלידו תופיע כאן. לחצו על אות שכבר הקלדתם כדי למחוק רק אותה.'**
  String get logoLevelTourStep3Body;

  /// כותרת שלב 4 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'כאן מקלידים'**
  String get logoLevelTourStep4Title;

  /// תוכן שלב 4 בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'הקישו על האותיות כאן כדי למלא את התשובה - לפי הסדר שבו הן מופיעות במילה.'**
  String get logoLevelTourStep4Body;

  /// מונה שלבים בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'{current} מתוך {total}'**
  String logoLevelTourStepCounter(int current, int total);

  /// כפתור הבא בהדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'הבא'**
  String get logoLevelTourNextButton;

  /// הנחיה בשלב האחרון של ההדרכה בתוך המשחק
  ///
  /// In he, this message translates to:
  /// **'לחצו על אות כדי להתחיל'**
  String get logoLevelTourTapLetterToStart;

  /// תג מחיר חינם באפשרות רמז
  ///
  /// In he, this message translates to:
  /// **'חינם'**
  String get logoLevelFreeLabel;

  /// הודעה כשבקשת חברות אושרה
  ///
  /// In he, this message translates to:
  /// **'אתם חברים עכשיו!'**
  String get friendsNowFriendsMessage;

  /// טקסט שיתוף הזמנה למשחק
  ///
  /// In he, this message translates to:
  /// **'בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n{link}\n\nשנינו נקבל {bonus} מטבעות במתנה ברגע שתתקינו ✨'**
  String friendsInviteText(String link, int bonus);

  /// הודעה כשאין אפליקציית שיתוף - הטקסט הועתק
  ///
  /// In he, this message translates to:
  /// **'לא נמצאה אפליקציית שיתוף - ההודעה הועתקה, אפשר להדביק ולשלוח'**
  String get friendsShareFallbackCopiedWithPaste;

  /// הודעה כשאין אפליקציית שיתוף - הטקסט הועתק (גרסה קצרה)
  ///
  /// In he, this message translates to:
  /// **'לא נמצאה אפליקציית שיתוף - ההודעה הועתקה'**
  String get friendsShareFallbackCopied;

  /// טקסט שיתוף קוד חברים
  ///
  /// In he, this message translates to:
  /// **'בוא נהיה חברים ב\"זהה את הלוגו!\" 🎮\nהקוד שלי: {code}\n(פותחים את האפליקציה -> חברים -> \"יש לי קוד\" ומזינים אותו)\n\nעוד לא הורדת? 📱 אייפון: {iosLink}\n🤖 אנדרואיד/גלקסי: {androidLink}'**
  String friendsShareCodeText(String code, String iosLink, String androidLink);

  /// נושא שיתוף קוד חברים
  ///
  /// In he, this message translates to:
  /// **'בוא נהיה חברים!'**
  String get friendsShareCodeSubject;

  /// הודעה כשהקוד הועתק
  ///
  /// In he, this message translates to:
  /// **'הקוד הועתק!'**
  String get friendsCodeCopiedMessage;

  /// שגיאת אורך קוד
  ///
  /// In he, this message translates to:
  /// **'קוד חייב להיות בן {length} תווים'**
  String friendsCodeLengthError(int length);

  /// הודעה כשבקשת חברות נשלחה
  ///
  /// In he, this message translates to:
  /// **'בקשת חברות נשלחה! נחכה שהוא יאשר'**
  String get friendsRequestSentMessage;

  /// שגיאה כשכבר יש בקשה ממתינה
  ///
  /// In he, this message translates to:
  /// **'כבר שלחת לו בקשה - ממתין לאישור'**
  String get friendsAlreadyRequestedError;

  /// שגיאה כשכבר חברים
  ///
  /// In he, this message translates to:
  /// **'כבר חברים איתו'**
  String get friendsAlreadyFriendsError;

  /// שגיאה כשהזין את הקוד של עצמו
  ///
  /// In he, this message translates to:
  /// **'זה הקוד שלך - שלח אותו לחבר, לא להזין אותו כאן'**
  String get friendsOwnCodeError;

  /// שגיאה כשהקוד לא נמצא
  ///
  /// In he, this message translates to:
  /// **'לא נמצא קוד כזה - ודא שהקלדת נכון'**
  String get friendsCodeNotFoundError;

  /// שגיאה כשהקוד לא תקין
  ///
  /// In he, this message translates to:
  /// **'קוד לא תקין'**
  String get friendsInvalidCodeError;

  /// שגיאה גנרית עם המלצה לנסות מאוחר יותר
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש - נסה שוב מאוחר יותר'**
  String get friendsGenericErrorLater;

  /// כותרת מסך החברים
  ///
  /// In he, this message translates to:
  /// **'חברים'**
  String get friendsTopBarTitle;

  /// כותרת אזור הגיבור במסך החברים
  ///
  /// In he, this message translates to:
  /// **'שחק עם חברים'**
  String get friendsHeroTitle;

  /// תת-כותרת אזור הגיבור במסך החברים
  ///
  /// In he, this message translates to:
  /// **'הוסף חברים לפי קוד, תראה מי מחובר, והזמן אותם ישר למשחק'**
  String get friendsHeroSubtitle;

  /// כותרת כרטיס הקוד האישי
  ///
  /// In he, this message translates to:
  /// **'הקוד שלך'**
  String get friendsMyCodeTitle;

  /// הסבר כרטיס הקוד האישי
  ///
  /// In he, this message translates to:
  /// **'לחיבור עם חבר שכבר משחק - בלי פרס. להזמנת חבר חדש ומטבעות, גללו למטה 👇'**
  String get friendsMyCodeHint;

  /// כפתור שיתוף הקוד האישי
  ///
  /// In he, this message translates to:
  /// **'שתף קוד'**
  String get friendsShareCodeButton;

  /// כותרת כרטיס הוספת חבר
  ///
  /// In he, this message translates to:
  /// **'יש לך קוד של חבר?'**
  String get friendsAddFriendPrompt;

  /// כפתור הוספת חבר
  ///
  /// In he, this message translates to:
  /// **'הוסף'**
  String get friendsAddButton;

  /// כותרת רשימת בקשות חברות ממתינות
  ///
  /// In he, this message translates to:
  /// **'בקשות חברות'**
  String get friendsPendingRequestsTitle;

  /// כותרת רשימת החברים
  ///
  /// In he, this message translates to:
  /// **'החברים שלי'**
  String get friendsMyFriendsTitle;

  /// הודעה כשאין חברים ברשימה
  ///
  /// In he, this message translates to:
  /// **'עדיין אין לך חברים כאן - שתף את הקוד שלך למעלה כדי להתחיל'**
  String get friendsEmptyListMessage;

  /// תווית חבר מחובר
  ///
  /// In he, this message translates to:
  /// **'מחובר'**
  String get friendsOnlineStatus;

  /// תווית חבר לא מחובר
  ///
  /// In he, this message translates to:
  /// **'לא מחובר'**
  String get friendsOfflineStatus;

  /// כפתור הזמנת חבר למשחק
  ///
  /// In he, this message translates to:
  /// **'הזמן למשחק'**
  String get friendsInviteButtonLabel;

  /// כותרת דיאלוג אישור הסרת חבר
  ///
  /// In he, this message translates to:
  /// **'להסיר מהחברים?'**
  String get friendsRemoveConfirmTitle;

  /// תוכן דיאלוג אישור הסרת חבר
  ///
  /// In he, this message translates to:
  /// **'{name} יוסר מרשימת החברים שלך, ואתה תוסר מהרשימה שלו. אפשר להתחבר שוב בעתיד עם קוד חדש.'**
  String friendsRemoveConfirmBody(String name);

  /// כפתור הסרת חבר
  ///
  /// In he, this message translates to:
  /// **'הסר'**
  String get friendsRemoveButton;

  /// הודעה שחבר הוסר
  ///
  /// In he, this message translates to:
  /// **'{name} הוסר/ה מהחברים'**
  String friendsRemovedMessage(String name);

  /// כותרת מיני-טבלת שיאים בין חברים
  ///
  /// In he, this message translates to:
  /// **'מי מוביל בין החברים שלך'**
  String get friendsLeaderboardTitle;

  /// שם השחקן בשורת עצמו בטבלת השיאים בין חברים
  ///
  /// In he, this message translates to:
  /// **'{name} (אתה)'**
  String friendsLeaderboardYouRow(String name);

  /// כותרת כרטיס הזמנה למשחק
  ///
  /// In he, this message translates to:
  /// **'הזמנה למשחק'**
  String get friendsInviteCardTitle;

  /// תוכן כרטיס הזמנה למשחק
  ///
  /// In he, this message translates to:
  /// **'שלח לחברים קישור להורדת האפליקציה - וואטסאפ, מסרונים או כל אפליקציה אחרת. שניכם תקבלו {bonus} מטבעות אוטומטית כשהם יתקינו!'**
  String friendsInviteCardBody(int bonus);

  /// כפתור שליחת הזמנה
  ///
  /// In he, this message translates to:
  /// **'שלח הזמנה'**
  String get friendsSendInviteButton;

  /// כותרת הסבר חד פעמי למסך החברים
  ///
  /// In he, this message translates to:
  /// **'מסך החברים'**
  String get friendsExplainerTitle;

  /// כותרת נקודת הסבר - קוד אישי
  ///
  /// In he, this message translates to:
  /// **'קוד אישי לשיתוף'**
  String get friendsExplainerCodeTitle;

  /// תוכן נקודת הסבר - קוד אישי
  ///
  /// In he, this message translates to:
  /// **'שתפו את הקוד שלכם עם חברים כדי שיוכלו להוסיף אתכם.'**
  String get friendsExplainerCodeBody;

  /// כותרת נקודת הסבר - מי מחובר
  ///
  /// In he, this message translates to:
  /// **'מי מחובר עכשיו'**
  String get friendsExplainerOnlineTitle;

  /// תוכן נקודת הסבר - מי מחובר
  ///
  /// In he, this message translates to:
  /// **'נקודה ירוקה ליד חבר מראה שהוא כרגע באפליקציה.'**
  String get friendsExplainerOnlineBody;

  /// כותרת נקודת הסבר - הזמנה למשחק
  ///
  /// In he, this message translates to:
  /// **'הזמנה למשחק'**
  String get friendsExplainerInviteTitle;

  /// תוכן נקודת הסבר - הזמנה למשחק
  ///
  /// In he, this message translates to:
  /// **'לחצו על \"הזמן למשחק\" ליד כל חבר כדי להזמין אותו לדו-קרב ישיר.'**
  String get friendsExplainerInviteBody;

  /// שגיאת טעינת הטבלה הארצית
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו לטעון את הטבלה. בדקו חיבור לאינטרנט ונסו שוב.'**
  String get leaderboardLoadErrorGeneric;

  /// שגיאת טעינת הטבלה הארצית עם פרטי אבחון
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו לטעון את הטבלה.\n\nשגיאה טכנית (אבחון זמני):\n{error}'**
  String leaderboardLoadErrorWithDetail(String error);

  /// כותרת הסבר חד פעמי למסך הטבלה הארצית
  ///
  /// In he, this message translates to:
  /// **'הטבלה הארצית'**
  String get leaderboardExplainerTitle;

  /// כותרת נקודת הסבר - דירוג לפי מדליות
  ///
  /// In he, this message translates to:
  /// **'דירוג לפי מדליות'**
  String get leaderboardExplainerMedalsTitle;

  /// תוכן נקודת הסבר - דירוג לפי מדליות
  ///
  /// In he, this message translates to:
  /// **'ברירת המחדל - דירוג הוגן לפי הישגים, לא רק כמות משחקים.'**
  String get leaderboardExplainerMedalsBody;

  /// כותרת נקודת הסבר - דירוג לפי נקודות
  ///
  /// In he, this message translates to:
  /// **'אפשר גם לפי נקודות'**
  String get leaderboardExplainerPointsTitle;

  /// תוכן נקודת הסבר - דירוג לפי נקודות
  ///
  /// In he, this message translates to:
  /// **'מתג למעלה מחליף לדירוג לפי XP שנצבר.'**
  String get leaderboardExplainerPointsBody;

  /// כותרת נקודת הסבר - מיקום תמיד גלוי
  ///
  /// In he, this message translates to:
  /// **'המיקום שלכם תמיד גלוי'**
  String get leaderboardExplainerPositionTitle;

  /// תוכן נקודת הסבר - מיקום תמיד גלוי
  ///
  /// In he, this message translates to:
  /// **'גם אם אתם לא בעשירייה הראשונה - תג צף מראה איפה אתם.'**
  String get leaderboardExplainerPositionBody;

  /// כותרת מסך הטבלה הארצית
  ///
  /// In he, this message translates to:
  /// **'טבלה ארצית'**
  String get leaderboardHeaderTitle;

  /// צ'יפ קישור לליגה השבועית
  ///
  /// In he, this message translates to:
  /// **'ליגה שבועית'**
  String get leaderboardWeeklyLeagueChip;

  /// צ'יפ קישור למסך ההישגים
  ///
  /// In he, this message translates to:
  /// **'הישגים'**
  String get leaderboardAchievementsChip;

  /// תווית מצב תצוגה לפי מדליות
  ///
  /// In he, this message translates to:
  /// **'מדליות'**
  String get leaderboardMedalsModeLabel;

  /// תווית מצב תצוגה לפי נקודות
  ///
  /// In he, this message translates to:
  /// **'נקודות'**
  String get leaderboardPointsModeLabel;

  /// הודעה כשהטבלה הארצית ריקה
  ///
  /// In he, this message translates to:
  /// **'עדיין אין ניקוד בטבלה.\nהיה הראשון לפתור לוגו!'**
  String get leaderboardEmptyMessage;

  /// כותרת מפריד - המובילים לפי מדליות
  ///
  /// In he, this message translates to:
  /// **'{count} לפי מדליות'**
  String leaderboardTopByMedals(int count);

  /// כותרת מפריד - המובילים הכוללים
  ///
  /// In he, this message translates to:
  /// **'{count} המובילים'**
  String leaderboardTopOverall(int count);

  /// תווית המקום שלי (מפריד/מיני-סטטיסטיקה)
  ///
  /// In he, this message translates to:
  /// **'המקום שלך'**
  String get leaderboardYourRankDivider;

  /// תווית XP שלי
  ///
  /// In he, this message translates to:
  /// **'XP שלך'**
  String get leaderboardYourXpLabel;

  /// תווית רצף
  ///
  /// In he, this message translates to:
  /// **'רצף'**
  String get leaderboardStreakLabel;

  /// שם בתג הצף עם סימון שזה אני
  ///
  /// In he, this message translates to:
  /// **'{name}  (אתה)'**
  String leaderboardFloatingYouRow(String name);

  /// הנחיה בתג הצף
  ///
  /// In he, this message translates to:
  /// **'הקש כדי לגלול למקום שלך'**
  String get leaderboardTapToScrollHint;

  /// כותרת מסך הליגה השבועית
  ///
  /// In he, this message translates to:
  /// **'ליגה שבועית'**
  String get leagueScreenTitle;

  /// כותרת דיאלוג סיכום שבוע בליגה
  ///
  /// In he, this message translates to:
  /// **'סיכום שבוע: מקום {rank} מתוך {total}'**
  String leagueRolloverSummaryTitle(int rank, int total);

  /// נקודות שנצברו בשבוע שעבר
  ///
  /// In he, this message translates to:
  /// **'{points} נקודות בשבוע שעבר.'**
  String leaguePointsLastWeek(int points);

  /// מטבעות שהתקבלו מסיכום שבוע בליגה
  ///
  /// In he, this message translates to:
  /// **'קיבלת {coins} מטבעות.'**
  String leagueCoinsReceived(int coins);

  /// הודעת עלייה לליגה
  ///
  /// In he, this message translates to:
  /// **'עלית לליגת {tier}!'**
  String leagueTierUp(String tier);

  /// הודעת ירידה בליגה
  ///
  /// In he, this message translates to:
  /// **'ירדת לליגת {tier}. חוזרים חזקים.'**
  String leagueTierDown(String tier);

  /// הודעת שהייה באותה ליגה
  ///
  /// In he, this message translates to:
  /// **'נשארת בליגת {tier}.'**
  String leagueTierSame(String tier);

  /// כפתור אישור בדיאלוג סיכום שבוע
  ///
  /// In he, this message translates to:
  /// **'מעולה'**
  String get leagueGreatButton;

  /// הליגה השבועית מסתיימת כרגע
  ///
  /// In he, this message translates to:
  /// **'מסתיים עכשיו'**
  String get leagueEndsNow;

  /// זמן שנותר לסיום השבוע - ימים ושעות
  ///
  /// In he, this message translates to:
  /// **'נגמר בעוד {days} ימים ו-{hours} שעות'**
  String leagueEndsInDaysHours(int days, int hours);

  /// זמן שנותר לסיום השבוע - שעות בלבד
  ///
  /// In he, this message translates to:
  /// **'נגמר בעוד {hours} שעות'**
  String leagueEndsInHours(int hours);

  /// תווית שם הליגה הנוכחית
  ///
  /// In he, this message translates to:
  /// **'ליגת {tier}'**
  String leagueTierNameLabel(String tier);

  /// מיקום ונקודות שלי בליגה
  ///
  /// In he, this message translates to:
  /// **'מקום {rank} · {points} נקודות'**
  String leagueMyRankPoints(int rank, int points);

  /// נקודות שלי בליגה כשאני לא מופיע בדירוג
  ///
  /// In he, this message translates to:
  /// **'{points} נקודות'**
  String leaguePointsOnly(int points);

  /// הסבר על מנגנון הליגה השבועית
  ///
  /// In he, this message translates to:
  /// **'כל שבוע מתחילים מאפס ומתחרים מול שחקנים באותה ליגה. מקומות 1-3: 100 / 60 / 40 מטבעות, וגם עלייה ליגה. משחקים, פותרים לוגואים ומנצחים כדי לצבור נקודות.'**
  String get leagueExplanationBody;

  /// הודעה כשאין עדיין משתתפים בליגה השבוע
  ///
  /// In he, this message translates to:
  /// **'עדיין אף אחד לא צבר נקודות השבוע. תהיו הראשונים!'**
  String get leagueEmptyMessage;

  /// שם ברירת מחדל לשחקן בלי שם בטבלת הליגה
  ///
  /// In he, this message translates to:
  /// **'שחקן'**
  String get leaguePlayerFallbackName;

  /// קיצור למילה נקודות
  ///
  /// In he, this message translates to:
  /// **'נק׳'**
  String get leaguePointsAbbrev;

  /// שגיאת טעינת המשימות
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת המשימות: {error}'**
  String missionsLoadError(String error);

  /// הודעת איסוף פרס משימה
  ///
  /// In he, this message translates to:
  /// **'קיבלת +{amount} מטבעות!'**
  String missionsClaimedCoinsMessage(int amount);

  /// הודעה כשלא ניתן להחליף משימה
  ///
  /// In he, this message translates to:
  /// **'אי אפשר להחליף את המשימה הזו כרגע'**
  String get missionsRerollUnavailable;

  /// הודעת הצלחה בהחלפת משימה
  ///
  /// In he, this message translates to:
  /// **'המשימה הוחלפה: {title}'**
  String missionsRerollSuccess(String title);

  /// כותרת מסך המשימות
  ///
  /// In he, this message translates to:
  /// **'משימות'**
  String get missionsScreenTitle;

  /// שגיאה גנרית לא ידועה
  ///
  /// In he, this message translates to:
  /// **'שגיאה לא ידועה'**
  String get missionsUnknownError;

  /// כותרת הסבר חד פעמי למסך המשימות
  ///
  /// In he, this message translates to:
  /// **'מסך המשימות'**
  String get missionsExplainerTitle;

  /// כותרת נקודת הסבר - משימות יומיות ושבועיות
  ///
  /// In he, this message translates to:
  /// **'משימות יומיות ושבועיות'**
  String get missionsExplainerDailyWeeklyTitle;

  /// תוכן נקודת הסבר - משימות יומיות ושבועיות
  ///
  /// In he, this message translates to:
  /// **'כל משימה שמשלימים מזכה בפרס - מטבעות או נקודות XP.'**
  String get missionsExplainerDailyWeeklyBody;

  /// כותרת נקודת הסבר - אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי'**
  String get missionsExplainerChallengeTitle;

  /// תוכן נקודת הסבר - אתגר יומי
  ///
  /// In he, this message translates to:
  /// **'מופיע למעלה כל יום - הזדמנות חד-פעמית לפרס גדול יותר.'**
  String get missionsExplainerChallengeBody;

  /// כותרת נקודת הסבר - איפוס אוטומטי
  ///
  /// In he, this message translates to:
  /// **'מתאפסות אוטומטית'**
  String get missionsExplainerResetTitle;

  /// תוכן נקודת הסבר - איפוס אוטומטי
  ///
  /// In he, this message translates to:
  /// **'משימות חדשות מחכות בכל יום/שבוע - אין צורך לעשות כלום.'**
  String get missionsExplainerResetBody;

  /// טאב משימות שבועיות
  ///
  /// In he, this message translates to:
  /// **'שבועיות'**
  String get missionsWeeklyTab;

  /// טאב משימות יומיות
  ///
  /// In he, this message translates to:
  /// **'יומיות'**
  String get missionsDailyTab;

  /// זמן איפוס משימות שבועיות
  ///
  /// In he, this message translates to:
  /// **'מתאפס בתחילת השבוע הבא'**
  String get missionsResetsNextWeek;

  /// זמן איפוס משימות יומיות
  ///
  /// In he, this message translates to:
  /// **'מתאפס בעוד {time} שעות'**
  String missionsResetsInHours(String time);

  /// כותרת פריט האתגר היומי ברשימה
  ///
  /// In he, this message translates to:
  /// **'השלם את האתגר היומי'**
  String get missionsCompleteDailyChallengeTitle;

  /// תג משימת פרימיום
  ///
  /// In he, this message translates to:
  /// **'⭐ פרימיום'**
  String get missionsPremiumBadge;

  /// תווית משימה שנאספה
  ///
  /// In he, this message translates to:
  /// **'נאסף'**
  String get missionsClaimedLabel;

  /// כפתור איסוף פרס משימה
  ///
  /// In he, this message translates to:
  /// **'קבל פרס'**
  String get missionsClaimButton;

  /// הודעה שהפרס מוכן אך דורש פרימיום
  ///
  /// In he, this message translates to:
  /// **'הפרס מוכן - דורש לוגו פאס פרימיום לאיסוף'**
  String get missionsPremiumRequiredReady;

  /// הודעה שהמשימה דורשת פרימיום
  ///
  /// In he, this message translates to:
  /// **'דורש לוגו פאס פרימיום'**
  String get missionsPremiumRequired;

  /// כפתור צפייה בפרסומת להחלפת משימה
  ///
  /// In he, this message translates to:
  /// **'פרסומת = החלף משימה'**
  String get missionsWatchAdRerollButton;

  /// הודעה כשרכישת פרימיום לא זמינה
  ///
  /// In he, this message translates to:
  /// **'הרכישה לא זמינה כרגע - נסה שוב עוד רגע'**
  String get battlePassPurchaseUnavailable;

  /// כותרת דיאלוג שאלת שדרוג לפרימיום
  ///
  /// In he, this message translates to:
  /// **'לשדרג לפרימיום?'**
  String get battlePassUpgradeDialogTitle;

  /// תוכן דיאלוג שאלת שדרוג לפרימיום
  ///
  /// In he, this message translates to:
  /// **'תקבל את כל פרסי הפרימיום של העונה, כולל אלה שכבר פתחת, במחיר {price}.'**
  String battlePassUpgradeDialogBody(String price);

  /// כפתור אישור שדרוג לפרימיום
  ///
  /// In he, this message translates to:
  /// **'כן, לשדרג · {price}'**
  String battlePassUpgradeConfirmButton(String price);

  /// כותרת דיאלוג מכירת פרימיום
  ///
  /// In he, this message translates to:
  /// **'לוגו פאס פרימיום'**
  String get battlePassUpsellTitle;

  /// תוכן דיאלוג מכירת פרימיום - חלק ראשון
  ///
  /// In he, this message translates to:
  /// **'פותח {tiers} פרסים נוספים לאורך כל העונה - בערך {coins} מטבעות'**
  String battlePassUpsellBody(int tiers, int coins);

  /// סיומת אנרגיה בדיאלוג מכירת פרימיום
  ///
  /// In he, this message translates to:
  /// **' ו-{energy} אנרגיה'**
  String battlePassUpsellEnergySuffix(int energy);

  /// סיומת פרס בוסט בדיאלוג מכירת פרימיום
  ///
  /// In he, this message translates to:
  /// **' + בוסט רמזים חינם ל-{minutes} דקות'**
  String battlePassUpsellBoostSuffix(int minutes);

  /// סיומת תוכן דיאלוג מכירת פרימיום
  ///
  /// In he, this message translates to:
  /// **' בסך הכול, בנוסף לכל מה שכבר מקבלים בנתיב החינמי.'**
  String get battlePassUpsellBodySuffix;

  /// כפתור שדרוג עכשיו
  ///
  /// In he, this message translates to:
  /// **'שדרג עכשיו · {price}'**
  String battlePassUpgradeNowButton(String price);

  /// כפתור דחיית שדרוג
  ///
  /// In he, this message translates to:
  /// **'אולי אחר כך'**
  String get battlePassMaybeLaterButton;

  /// כותרת דיאלוג הסבר באטל פאס
  ///
  /// In he, this message translates to:
  /// **'מה זה לוגו פאס?'**
  String get battlePassInfoDialogTitle;

  /// תוכן דיאלוג הסבר באטל פאס
  ///
  /// In he, this message translates to:
  /// **'צובר נקודות ממשימות ומהאתגר היומי, ועולה דרגות לאורך העונה. כל דרגה פותחת פרס בנתיב החינמי, ומי שרוכש פרימיום מקבל פרס גדול יותר באותה דרגה. בתחילת כל חודש נפתחת עונה חדשה מ-0.'**
  String get battlePassInfoDialogBody;

  /// כפתור הבנתי בדיאלוג הסבר
  ///
  /// In he, this message translates to:
  /// **'הבנתי'**
  String get battlePassGotItButton;

  /// כותרת מסך הבאטל פאס
  ///
  /// In he, this message translates to:
  /// **'לוגו פאס'**
  String get battlePassScreenTitle;

  /// תווית מספר העונה
  ///
  /// In he, this message translates to:
  /// **'עונה {number}'**
  String battlePassSeasonNumberLabel(int number);

  /// הודעה שהעונה מסתיימת היום
  ///
  /// In he, this message translates to:
  /// **'העונה מסתיימת היום'**
  String get battlePassSeasonEndsToday;

  /// מספר הימים שנותרו לעונה
  ///
  /// In he, this message translates to:
  /// **'נותרו {days} ימים'**
  String battlePassDaysLeft(int days);

  /// תווית הדרגה האחרונה בעונה
  ///
  /// In he, this message translates to:
  /// **'הדרגה האחרונה!'**
  String get battlePassLastTierLabel;

  /// נקודות חסרות לדרגה הבאה
  ///
  /// In he, this message translates to:
  /// **'עוד {points} ⭐'**
  String battlePassPointsToNextTier(int points);

  /// תווית קטנה מתחת למספר הדרגה
  ///
  /// In he, this message translates to:
  /// **'דרגה'**
  String get battlePassTierLabel;

  /// מספר פרסים שניתן לאסוף
  ///
  /// In he, this message translates to:
  /// **'{count} פרסים לאיסוף'**
  String battlePassPendingRewards(int count);

  /// תווית שכל הפרסים נאספו
  ///
  /// In he, this message translates to:
  /// **'הכל נאסף ✓'**
  String get battlePassAllClaimed;

  /// תג עיטורי בלבד - אין נתון אמיתי מאחוריו
  ///
  /// In he, this message translates to:
  /// **'🏅 תג בסיום'**
  String get battlePassSeasonBadgeDecorative;

  /// כותרת כפתור שדרוג גדול בתחתית
  ///
  /// In he, this message translates to:
  /// **'שדרג לפרימיום · {price}'**
  String battlePassUpgradeCtaTitle(String price);

  /// תת-כותרת כפתור שדרוג כשיש פרסים שכבר הגיעו
  ///
  /// In he, this message translates to:
  /// **'פותח {locked} פרסים · כולל {reached} שכבר צברת'**
  String battlePassUpgradeCtaSubtitleWithReached(int locked, int reached);

  /// תת-כותרת כפתור שדרוג
  ///
  /// In he, this message translates to:
  /// **'פותח {locked} פרסים נוספים'**
  String battlePassUpgradeCtaSubtitle(int locked);

  /// כותרת עמודת הפרימיום
  ///
  /// In he, this message translates to:
  /// **'פרימיום'**
  String get battlePassPremiumColumnLabel;

  /// כפתור איסוף פרס בגלולה
  ///
  /// In he, this message translates to:
  /// **'אסוף'**
  String get battlePassClaimButton;

  /// תווית נתיב פרימיום בפופאפ פרס
  ///
  /// In he, this message translates to:
  /// **'נתיב פרימיום'**
  String get battlePassPopupPremiumPathLabel;

  /// תווית נתיב חינם בפופאפ פרס
  ///
  /// In he, this message translates to:
  /// **'נתיב חינם'**
  String get battlePassPopupFreePathLabel;

  /// כותרת עליונה קטנה בפופאפ פרס
  ///
  /// In he, this message translates to:
  /// **'לוגו פאס · דרגה {tier}'**
  String battlePassPopupHeaderLabel(int tier);

  /// כותרת ראשית בפופאפ פרס
  ///
  /// In he, this message translates to:
  /// **'פרס נאסף!'**
  String get battlePassPopupRewardClaimedTitle;

  /// תיאור כמות מטבעות שהתקבלה
  ///
  /// In he, this message translates to:
  /// **'{coins} מטבעות'**
  String battlePassPopupCoinsAmount(int coins);

  /// תיאור כמות אנרגיה שהתקבלה
  ///
  /// In he, this message translates to:
  /// **'{energy} אנרגיה'**
  String battlePassPopupEnergyAmount(int energy);

  /// תווית נתיב ודרגה בגלולת סיכום הפרס
  ///
  /// In he, this message translates to:
  /// **'{path} · דרגה {tier}'**
  String battlePassPopupPathTierLabel(String path, int tier);

  /// כפתור טקסט חזרה למסך הבאטל פאס
  ///
  /// In he, this message translates to:
  /// **'חזרה לפאס'**
  String get battlePassPopupBackToPassButton;

  /// תווית כשכל הדרגות בעונה נפתחו
  ///
  /// In he, this message translates to:
  /// **'כל הדרגות נפתחו!'**
  String get battlePassPopupAllTiersUnlocked;

  /// תווית התקדמות לדרגה הבאה
  ///
  /// In he, this message translates to:
  /// **'התקדמות לדרגה {tier}'**
  String battlePassPopupProgressToTier(int tier);

  /// תווית פס התקדמות מלא
  ///
  /// In he, this message translates to:
  /// **'⭐ מקסימום'**
  String get battlePassPopupMaxStars;

  /// אחוז התקדמות לדרגה הבאה
  ///
  /// In he, this message translates to:
  /// **'⭐ {percent}%'**
  String battlePassPopupPercentStars(int percent);

  /// כותרת כרטיס פיתוי שדרוג לפרימיום
  ///
  /// In he, this message translates to:
  /// **'עם פרימיום היית מקבל בדרגה הזו'**
  String get battlePassPopupPremiumTeaserTitle;

  /// סיומת מכפיל כמה יותר פרימיום נותן
  ///
  /// In he, this message translates to:
  /// **' · פי {multiplier} ממה שקיבלת'**
  String battlePassPopupPremiumMultiplier(String multiplier);

  /// כותרת כרטיס דרגה נוספת שנפתחה
  ///
  /// In he, this message translates to:
  /// **'דרגה {tier} נפתחה'**
  String battlePassPopupTierUnlockedTitle(int tier);

  /// כפתור איסוף דרגה נוספת
  ///
  /// In he, this message translates to:
  /// **'אסוף את דרגה {tier}'**
  String battlePassPopupClaimTierButton(int tier);

  /// תווית קצרה לגלולת פרס בוסט בטבלת השלבים
  ///
  /// In he, this message translates to:
  /// **'{minutes} דק\''**
  String battlePassBoostPillLabel(int minutes);

  /// כותרת פרס בוסט (רמזים חינם) בפופאפ איסוף הפרס
  ///
  /// In he, this message translates to:
  /// **'{minutes} דקות רמזים חינם'**
  String battlePassBoostRewardTitle(int minutes);

  /// תוכן התראת קידום לוגו פאס - לחיצה עליה פותחת את מסך הלוגו פאס
  ///
  /// In he, this message translates to:
  /// **'🎫 פותחים עוד ועוד פרסים לאורך כל העונה - אל תפספסו!'**
  String get promoLogoPassBody;

  /// תוכן התראת קידום חנות - לחיצה עליה פותחת את החנות
  ///
  /// In he, this message translates to:
  /// **'🛍️ מטבעות, הסרת פרסומות ועוד - בואו תראו מה יש בחנות'**
  String get promoShopBody;

  /// הודעת הצלחה במימוש קופון
  ///
  /// In he, this message translates to:
  /// **'הקוד מומש! קיבלת {coins} מטבעות'**
  String shopCouponRedeemedMessage(int coins);

  /// שגיאת קופון לא נמצא
  ///
  /// In he, this message translates to:
  /// **'קוד לא קיים - בדוק שהקלדת נכון'**
  String get shopCouponNotFound;

  /// שגיאת קופון לא פעיל
  ///
  /// In he, this message translates to:
  /// **'הקוד הזה כבר לא פעיל'**
  String get shopCouponInactive;

  /// שגיאת קופון שנוצל עד הסוף
  ///
  /// In he, this message translates to:
  /// **'הקוד הזה נוצל עד הסוף על ידי שחקנים אחרים'**
  String get shopCouponUsedUp;

  /// שגיאת קופון שכבר נוצל במכשיר הזה
  ///
  /// In he, this message translates to:
  /// **'כבר מימשת את הקוד הזה בעבר'**
  String get shopCouponAlreadyUsed;

  /// שגיאת קופון כללית עם פרטים
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {detail}'**
  String shopCouponGenericError(String detail);

  /// פרט שגיאה לא ידוע
  ///
  /// In he, this message translates to:
  /// **'לא ידועה'**
  String get shopUnknownErrorDetail;

  /// תת-כותרת פופאפ בונוס מטבעות מפרסומת
  ///
  /// In he, this message translates to:
  /// **'חוזר שוב בעוד 3 שעות'**
  String get shopAdBonusResetSubtitle;

  /// זמן לפרסומת הבאה לאנרגיה
  ///
  /// In he, this message translates to:
  /// **'אפשר לצפות בפרסומת נוספת בעוד {time}'**
  String shopNextAdAvailableIn(String time);

  /// תווית כמות מטבעות (כבר מעוצבת, למשל עם פסיקים)
  ///
  /// In he, this message translates to:
  /// **'{amount} מטבעות'**
  String shopCoinsAmountLabel(String amount);

  /// תווית כמות אנרגיה
  ///
  /// In he, this message translates to:
  /// **'{amount} אנרגיה'**
  String shopEnergyAmountLabel(String amount);

  /// תיאור בונוס רכישה ראשונה
  ///
  /// In he, this message translates to:
  /// **'בונוס רכישה ראשונה - כפול!'**
  String get shopFirstPurchaseBonusDesc;

  /// תיאור חבילת מטבעות רגילה
  ///
  /// In he, this message translates to:
  /// **'חבילת מטבעות'**
  String get shopCoinsPackDesc;

  /// תיאור חבילת מטבעות הכי משתלמת
  ///
  /// In he, this message translates to:
  /// **'חבילת מטבעות - הכי משתלם'**
  String get shopCoinsPackBestValueDesc;

  /// תיאור חבילת אנרגיה
  ///
  /// In he, this message translates to:
  /// **'חבילת אנרגיה'**
  String get shopEnergyPackDesc;

  /// שם מוצר ללא פרסומות חודשי
  ///
  /// In he, this message translates to:
  /// **'ללא פרסומות - חודשי'**
  String get shopNoAdsMonthlyName;

  /// תיאור מנוי חודשי
  ///
  /// In he, this message translates to:
  /// **'מנוי חודשי'**
  String get shopMonthlySubscriptionDesc;

  /// שם מוצר ללא פרסומות לתמיד
  ///
  /// In he, this message translates to:
  /// **'ללא פרסומות - לתמיד'**
  String get shopNoAdsLifetimeName;

  /// תיאור רכישה חד-פעמית
  ///
  /// In he, this message translates to:
  /// **'רכישה חד-פעמית'**
  String get shopOneTimePurchaseDesc;

  /// תווית הוסרו כל הפרסומות בפופאפ רכישה
  ///
  /// In he, this message translates to:
  /// **'הוסרו כל הפרסומות'**
  String get shopAllAdsRemovedLabel;

  /// תווית מטבעות קצרה
  ///
  /// In he, this message translates to:
  /// **'מטבעות'**
  String get shopCoinsLabel;

  /// תווית אנרגיה קצרה
  ///
  /// In he, this message translates to:
  /// **'אנרגיה'**
  String get shopEnergyLabel;

  /// תווית ערך כפול עם בונוס רכישה ראשונה
  ///
  /// In he, this message translates to:
  /// **'+{amount} 🎁'**
  String shopDoubleBonusValue(int amount);

  /// שגיאה בפתיחת קישור חיצוני
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לפתוח את הקישור כרגע'**
  String get shopCannotOpenLinkError;

  /// הודעה כשרכישה לא זמינה
  ///
  /// In he, this message translates to:
  /// **'הרכישה אינה זמינה כרגע, נסה שוב מאוחר יותר'**
  String get shopPurchaseUnavailable;

  /// כותרת באנר מארז פתיחה
  ///
  /// In he, this message translates to:
  /// **'מארז פתיחה ממתין לך!'**
  String get shopStarterPackWaitingTitle;

  /// סיומת אנרגיה בתוכן באנר מארז פתיחה
  ///
  /// In he, this message translates to:
  /// **' + {energy} אנרגיה'**
  String shopStarterPackEnergySuffix(int energy);

  /// זמן שנותר להצעת מארז הפתיחה
  ///
  /// In he, this message translates to:
  /// **'נשארו {time} - ל-3 שעות בלבד'**
  String shopStarterPackTimeLeft(String time);

  /// כותרת מסך החנות
  ///
  /// In he, this message translates to:
  /// **'חנות'**
  String get shopScreenTitle;

  /// כותרת קטע פעולות מהירות
  ///
  /// In he, this message translates to:
  /// **'פעולות מהירות'**
  String get shopQuickActionsSection;

  /// טקסט placeholder לשדה קוד קופון
  ///
  /// In he, this message translates to:
  /// **'הקלד קוד קופון'**
  String get shopCouponHint;

  /// כפתור מימוש קופון
  ///
  /// In he, this message translates to:
  /// **'מימוש'**
  String get shopRedeemButton;

  /// כותרת בונוס מטבעות מפרסומת
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת - קבל 15 מטבעות'**
  String get shopWatchAdGet15CoinsTitle;

  /// תת-כותרת בונוס מטבעות מפרסומת
  ///
  /// In he, this message translates to:
  /// **'זמין שוב כל 3 שעות - מטבעות חינם'**
  String get shopAdBonusAvailableSubtitle;

  /// תווית זמן לבונוס הבא
  ///
  /// In he, this message translates to:
  /// **'הבונוס הבא זמין בעוד: '**
  String get shopNextBonusAvailableInLabel;

  /// כותרת בונוס אנרגיה מפרסומת
  ///
  /// In he, this message translates to:
  /// **'צפה בפרסומת - קבל {amount} אנרגיה'**
  String shopWatchAdGetEnergyTitle(int amount);

  /// תת-כותרת בונוס אנרגיה מפרסומת
  ///
  /// In he, this message translates to:
  /// **'אין הגבלת פעמים - זמין תמיד כשהאנרגיה לא מלאה'**
  String get shopEnergyAdUnlimitedSubtitle;

  /// כותרת קטע הבוסטים הזמניים
  ///
  /// In he, this message translates to:
  /// **'בוסטים'**
  String get shopBoostSectionTitle;

  /// כותרת בוסט רמזים חינם
  ///
  /// In he, this message translates to:
  /// **'15 דקות רמזים חינם'**
  String get shopBoostHintsTitle;

  /// תת-כותרת בוסט רמזים חינם
  ///
  /// In he, this message translates to:
  /// **'עד 2 רמזי-אות חינם בכל חידה - בלי מטבעות ובלי לפגוע בפרס'**
  String get shopBoostHintsSubtitle;

  /// כותרת בוסט נקודות כפולות
  ///
  /// In he, this message translates to:
  /// **'15 דקות נקודות כפולות'**
  String get shopBoostDoubleTitle;

  /// תת-כותרת בוסט נקודות כפולות
  ///
  /// In he, this message translates to:
  /// **'כל ה-XP שתרוויחו בפתרון שלבים יוכפל'**
  String get shopBoostDoubleSubtitle;

  /// תווית בוסט פעיל כרגע עם הזמן שנותר
  ///
  /// In he, this message translates to:
  /// **'פעיל - נותרו {time}'**
  String shopBoostActiveLabel(String time);

  /// הודעה כשמנסים לקנות בוסט בזמן שכבר יש אחד פעיל
  ///
  /// In he, this message translates to:
  /// **'כבר יש לך בוסט פעיל כרגע'**
  String get shopBoostAlreadyActiveToast;

  /// הודעה כשאין מספיק מטבעות לקניית בוסט
  ///
  /// In he, this message translates to:
  /// **'אין לך מספיק מטבעות לבוסט הזה'**
  String get shopBoostNotEnoughCoinsToast;

  /// הודעת הצלחה בהפעלת בוסט רמזים חינם
  ///
  /// In he, this message translates to:
  /// **'🔥 רמזים חינם הופעלו ל-15 דקות!'**
  String get shopBoostHintsActivatedToast;

  /// הודעת הצלחה בהפעלת בוסט נקודות כפולות
  ///
  /// In he, this message translates to:
  /// **'⚡ נקודות כפולות הופעלו ל-15 דקות!'**
  String get shopBoostDoubleActivatedToast;

  /// הודעה כשניתן בוסט ניסיון חינמי חד-פעמי
  ///
  /// In he, this message translates to:
  /// **'🎁 מתנה! רמזים חינם ל-{minutes} דקות - נסו עכשיו'**
  String shopBoostFreeTrialToast(int minutes);

  /// כותרת קטע חנות המטבעות
  ///
  /// In he, this message translates to:
  /// **'חנות המטבעות'**
  String get shopCoinsSectionTitle;

  /// שם חבילת מטבעות הגדולה ביותר
  ///
  /// In he, this message translates to:
  /// **'חבילת אגדה'**
  String get shopLegendPackTitle;

  /// שם חבילת מטבעות זהב
  ///
  /// In he, this message translates to:
  /// **'חבילת זהב'**
  String get shopGoldPackTitle;

  /// תג בונוס רכישה ראשונה על חבילה
  ///
  /// In he, this message translates to:
  /// **'פעם ראשונה = כפול!'**
  String get shopFirstPurchaseDoubleBadge;

  /// שם חבילת מטבעות למתחילים
  ///
  /// In he, this message translates to:
  /// **'חבילת מתחילים'**
  String get shopBeginnerPackTitle;

  /// שם חבילת מטבעות מלכים
  ///
  /// In he, this message translates to:
  /// **'חבילת מלכים'**
  String get shopKingsPackTitle;

  /// שם חבילת מטבעות VIP
  ///
  /// In he, this message translates to:
  /// **'חבילת VIP'**
  String get shopVipPackTitle;

  /// תג החבילה הפופולרית ביותר
  ///
  /// In he, this message translates to:
  /// **'הכי פופולרי'**
  String get shopMostPopularBadge;

  /// כותרת קטע חנות האנרגיה
  ///
  /// In he, this message translates to:
  /// **'חנות האנרגיה'**
  String get shopEnergySectionTitle;

  /// שם חבילת אנרגיה קטנה
  ///
  /// In he, this message translates to:
  /// **'מטען קטן'**
  String get shopEnergySmallTitle;

  /// שם חבילת אנרגיה בינונית
  ///
  /// In he, this message translates to:
  /// **'מטען בינוני'**
  String get shopEnergyMediumTitle;

  /// שם חבילת אנרגיה גדולה
  ///
  /// In he, this message translates to:
  /// **'מטען גדול'**
  String get shopEnergyLargeTitle;

  /// שם חבילת אנרגיה ענקית
  ///
  /// In he, this message translates to:
  /// **'מטען ענק'**
  String get shopEnergyHugeTitle;

  /// כותרת קטע ללא פרסומות
  ///
  /// In he, this message translates to:
  /// **'ללא פרסומות'**
  String get shopNoAdsSectionTitle;

  /// הודעה שמצב ללא פרסומות פעיל
  ///
  /// In he, this message translates to:
  /// **'מצב ללא פרסומות פעיל! תודה על התמיכה 💜'**
  String get shopNoAdsActiveMessage;

  /// כותרת כרטיס מנוי חודשי
  ///
  /// In he, this message translates to:
  /// **'מנוי חודשי'**
  String get shopMonthlySubTitle;

  /// תת-כותרת כרטיס מנוי חודשי
  ///
  /// In he, this message translates to:
  /// **'בלי פרסומות בין שלבים, מתחדש כל חודש'**
  String get shopMonthlySubSubtitle;

  /// כותרת כרטיס מנוי לכל החיים
  ///
  /// In he, this message translates to:
  /// **'לכל החיים'**
  String get shopLifetimeTitle;

  /// תת-כותרת כרטיס מנוי לכל החיים
  ///
  /// In he, this message translates to:
  /// **'תשלום אחד - בלי פרסומות לתמיד'**
  String get shopLifetimeSubtitle;

  /// תג הכי משתלם (חבילה/מנוי)
  ///
  /// In he, this message translates to:
  /// **'הכי משתלם'**
  String get shopBestValueBadge;

  /// קישור מדיניות פרטיות
  ///
  /// In he, this message translates to:
  /// **'מדיניות פרטיות'**
  String get shopPrivacyPolicyLink;

  /// הודעה בזמן שחזור רכישות
  ///
  /// In he, this message translates to:
  /// **'בודק רכישות קודמות...'**
  String get shopCheckingPurchasesMessage;

  /// כפתור שחזור רכישות
  ///
  /// In he, this message translates to:
  /// **'שחזור רכישות'**
  String get shopRestorePurchasesButton;

  /// תג חבילה מומלצת
  ///
  /// In he, this message translates to:
  /// **'מומלץ לך'**
  String get shopRecommendedForYouBadge;

  /// כותרת באנר בונוס ניצחון טורניר בחנות
  ///
  /// In he, this message translates to:
  /// **'מבצע אלוף! +25% מטבעות בחבילות הגדולות'**
  String get shopTournamentBonusBannerTitle;

  /// זמן שנותר למבצע בונוס ניצחון הטורניר
  ///
  /// In he, this message translates to:
  /// **'נשארו {time} למבצע האלוף'**
  String shopTournamentBonusTimeLeft(String time);

  /// הערה קטנה על כרטיס חבילת מטבעות כשמבצע האלוף פעיל
  ///
  /// In he, this message translates to:
  /// **'בונוס אלוף: +25% מטבעות'**
  String get shopTournamentBonusTileNote;

  /// תג בונוס ניצחון טורניר על חבילת מטבעות
  ///
  /// In he, this message translates to:
  /// **'בונוס אלוף +25%'**
  String get shopTournamentBonusBadge;

  /// ערך מוצג בפופאפ רכישה שהושלמה עם בונוס ניצחון טורניר
  ///
  /// In he, this message translates to:
  /// **'+{amount} - בונוס אלוף!'**
  String shopTournamentBonusValue(int amount);

  /// תיאור בונוס ניצחון טורניר בפופאפ רכישה
  ///
  /// In he, this message translates to:
  /// **'בונוס אלוף - 25% יותר מטבעות!'**
  String get shopTournamentBonusDesc;

  /// תת-כותרת ברירת מחדל בפופאפ קיבלת אנרגיה
  ///
  /// In he, this message translates to:
  /// **'מספיק לשני דו־קרבים נוספים'**
  String get rewardPopupEnergyDefaultSubtitle;

  /// תווית קיבלת בפופאפ תגמול
  ///
  /// In he, this message translates to:
  /// **'קיבלת'**
  String get rewardPopupGotLabel;

  /// תווית האנרגיה שלך בפופאפ תגמול
  ///
  /// In he, this message translates to:
  /// **'האנרגיה שלך'**
  String get rewardPopupYourEnergyLabel;

  /// כפתור מעבר לדו-קרב בפופאפ אנרגיה
  ///
  /// In he, this message translates to:
  /// **'יאללה, לדו־קרב ⚔'**
  String get rewardPopupToDuelButton;

  /// קישור המשך בפופאפ תגמול
  ///
  /// In he, this message translates to:
  /// **'המשך'**
  String get rewardPopupContinueLink;

  /// תווית המטבעות שלך בפופאפ תגמול
  ///
  /// In he, this message translates to:
  /// **'המטבעות שלך'**
  String get rewardPopupYourCoinsLabel;

  /// קישור לחנות בפופאפ מטבעות
  ///
  /// In he, this message translates to:
  /// **'לחנות'**
  String get rewardPopupToShopLink;

  /// כותרת פופאפ רכישה הושלמה
  ///
  /// In he, this message translates to:
  /// **'הרכישה הושלמה!'**
  String get rewardPopupPurchaseCompleteTitle;

  /// תת-כותרת פופאפ רכישה הושלמה
  ///
  /// In he, this message translates to:
  /// **'הפריטים כבר בחשבון שלך'**
  String get rewardPopupItemsInAccountSubtitle;

  /// תווית רשימת פריטים שנוספו לחשבון
  ///
  /// In he, this message translates to:
  /// **'נוסף לחשבון'**
  String get rewardPopupAddedToAccountLabel;

  /// כפתור חזרה למשחק בפופאפ רכישה
  ///
  /// In he, this message translates to:
  /// **'מעולה, בחזרה למשחק'**
  String get rewardPopupBackToGameButton;

  /// כותרת פופאפ בקשת דירוג ראשונה
  ///
  /// In he, this message translates to:
  /// **'נהנים מהמשחק?'**
  String get reviewPromptTitle;

  /// תוכן פופאפ בקשת דירוג ראשונה
  ///
  /// In he, this message translates to:
  /// **'דירוג 5 כוכבים ⭐ עוזר לנו המון ולוקח רק כמה שניות'**
  String get reviewPromptBody;

  /// כפתור דירוג בפופאפ בקשת דירוג
  ///
  /// In he, this message translates to:
  /// **'דרגו אותנו 5 כוכבים'**
  String get reviewPromptRateButton;

  /// כפתור דחיית דירוג
  ///
  /// In he, this message translates to:
  /// **'אולי מאוחר יותר'**
  String get reviewPromptMaybeLaterButton;

  /// תווית מוד דו-קרב במסך מעקב שחקנים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'דו-קרב'**
  String get presenceAdminModeDuel;

  /// תווית מוד סדרת דו-קרב במסך מעקב שחקנים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'סדרת דו-קרב'**
  String get presenceAdminModeSuperDuel;

  /// תווית מוד מירוץ במסך מעקב שחקנים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'מירוץ'**
  String get presenceAdminModeRace;

  /// כותרת מסך מעקב שחקנים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'מעקב שחקנים אונליין'**
  String get presenceAdminTitle;

  /// תווית סה״כ במסך מעקב שחקנים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'סה״כ'**
  String get presenceAdminTotalLabel;

  /// תווית סדרה בכרטיס סיכום (אדמין)
  ///
  /// In he, this message translates to:
  /// **'סדרה'**
  String get presenceAdminSeriesLabel;

  /// זמן הרענון האחרון במסך מעקב שחקנים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'עודכן לפני {seconds} שניות · מתרענן אוטומטית כל 10 שניות'**
  String presenceAdminLastRefreshLabel(int seconds);

  /// הודעה כשאין שחקנים מחוברים (אדמין)
  ///
  /// In he, this message translates to:
  /// **'אף אחד לא מחובר כרגע (או שאין רשת) ⚠️ שים לב: שחקנים שכבר בתוך משחק דו-קרב פעיל (לא בלובי) לא נספרים - מגבלה ידועה, ראו הערה ב-presence_service.dart'**
  String get presenceAdminEmptyMessage;

  /// זמן יחסי לעדכון אחרון של שחקן (אדמין)
  ///
  /// In he, this message translates to:
  /// **'לפני {seconds}s'**
  String presenceAdminSecondsAgo(int seconds);

  /// שם משתמש דמה בתצוגה המקדימה (preview_main.dart)
  ///
  /// In he, this message translates to:
  /// **'אופק123'**
  String get previewUsername;

  /// מספר מדליות דמה בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'0 / 15 מדליות'**
  String get previewMedalsCount;

  /// תג כרטיס המשך-לשחק בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'ממשיכים מאיפה שעצרת'**
  String get previewContinueBannerLabel;

  /// תווית מספר שלב בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'שלב {n}'**
  String previewStageLabel(int n);

  /// תווית הושלם מתחת לאחוז התקדמות בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get previewCompletedLabel;

  /// כפתור המשך לשחק בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'המשך לשחק'**
  String get previewContinuePlayingButton;

  /// כותרת כרטיס אתגר יומי בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי'**
  String get previewDailyChallengeTitle;

  /// תת-כותרת כרטיס אתגר יומי בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'6 לוגואים · פרס מיוחד'**
  String get previewDailyChallengeSubtitle;

  /// תג מחוברים בכרטיס שחק מול אחרים בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'8 מחוברים'**
  String get previewConnectedCount;

  /// תת-כותרת כרטיס אתגר רנדומלי בתצוגה המקדימה
  ///
  /// In he, this message translates to:
  /// **'לוגו אקראי · שומר על הרצף'**
  String get previewRandomChallengeSubtitle;

  /// שגיאת טעינת הערות עדכון
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו לטעון את העדכונים - נסה שוב מאוחר יותר'**
  String get updateNotesLoadError;

  /// כותרת מסך הערות עדכון
  ///
  /// In he, this message translates to:
  /// **'מה חדש במשחק'**
  String get updateNotesTitle;

  /// הודעה כשאין הערות עדכון
  ///
  /// In he, this message translates to:
  /// **'אין עדיין הערות עדכון - חזרו לבדוק בקרוב'**
  String get updateNotesEmptyMessage;

  /// כותרת מסך עדכון נדרש
  ///
  /// In he, this message translates to:
  /// **'יש גרסה חדשה'**
  String get updateRequiredTitle;

  /// כפתור מעבר לחנות לעדכון
  ///
  /// In he, this message translates to:
  /// **'עדכן עכשיו'**
  String get updateRequiredUpdateNowButton;

  /// פרטי גרסה נוכחית ונדרשת
  ///
  /// In he, this message translates to:
  /// **'גרסה {current} · נדרשת {min}'**
  String updateRequiredVersionInfo(String current, String min);

  /// כותרת תכונה - סדרת דו-קרב
  ///
  /// In he, this message translates to:
  /// **'סדרת דו-קרב'**
  String get whatsNewDuelSeriesTitle;

  /// תיאור תכונה - סדרת דו-קרב
  ///
  /// In he, this message translates to:
  /// **'דו-קרב חדש: הטוב מ-3! אותו יריב, עד 3 סיבובים, ובונוס מטבעות שמן לניצחון בסדרה'**
  String get whatsNewDuelSeriesSubtitle;

  /// כותרת תכונה - רמות חדשות
  ///
  /// In he, this message translates to:
  /// **'נוספו רמות חדשות'**
  String get whatsNewNewLevelsTitle;

  /// תיאור תכונה - רמות חדשות
  ///
  /// In he, this message translates to:
  /// **'עוד שלבים ועוד לוגואים לזהות, מחכים לכם במסך השלבים'**
  String get whatsNewNewLevelsSubtitle;

  /// כותרת תכונה - רמות קושי
  ///
  /// In he, this message translates to:
  /// **'רמות קושי 1-5'**
  String get whatsNewDifficultyTitle;

  /// תיאור תכונה - רמות קושי
  ///
  /// In he, this message translates to:
  /// **'כל עולם מקבל דירוג קושי — וככל שההימור בדו-קרב גבוה יותר, כך גם רמת הלוגואים'**
  String get whatsNewDifficultySubtitle;

  /// כותרת תכונה - בונוס הזמנת חברים
  ///
  /// In he, this message translates to:
  /// **'בונוס הזמנת חברים גדול יותר'**
  String get whatsNewReferralBonusTitle;

  /// תיאור תכונה - בונוס הזמנת חברים
  ///
  /// In he, this message translates to:
  /// **'עכשיו מקבלים 75 מטבעות (במקום 30) על כל חבר שמצטרף דרך הקוד שלכם'**
  String get whatsNewReferralBonusSubtitle;

  /// תג גרסה במסך מה חדש
  ///
  /// In he, this message translates to:
  /// **'✨ גרסה {version}'**
  String whatsNewVersionBadge(String version);

  /// כותרת ראשית במסך מה חדש
  ///
  /// In he, this message translates to:
  /// **'עדכנו בשבילכם!'**
  String get whatsNewHeaderTitle;

  /// תת-כותרת במסך מה חדש
  ///
  /// In he, this message translates to:
  /// **'מה חדש בגרסה {version}?'**
  String whatsNewHeaderSubtitle(String version);

  /// תג חדש על כרטיס תכונה מודגש
  ///
  /// In he, this message translates to:
  /// **'חדש'**
  String get whatsNewNewBadge;

  /// כפתור המשך במסך מה חדש
  ///
  /// In he, this message translates to:
  /// **'בואו נתחיל'**
  String get whatsNewGetStartedButton;

  /// קישור מה חדש בתחתית מסך ההגדרות
  ///
  /// In he, this message translates to:
  /// **'מה חדש'**
  String get settingsWhatsNewLink;

  /// קישור דיווח על תקלה
  ///
  /// In he, this message translates to:
  /// **'דיווח על תקלה'**
  String get settingsReportIssueLink;

  /// קישור פרטיות בתחתית מסך ההגדרות
  ///
  /// In he, this message translates to:
  /// **'פרטיות'**
  String get settingsPrivacyLink;

  /// קישור דרגו אותנו
  ///
  /// In he, this message translates to:
  /// **'דרגו אותנו'**
  String get settingsRateUsLink;

  /// קישור מחיקת משתמש
  ///
  /// In he, this message translates to:
  /// **'מחיקת משתמש'**
  String get settingsDeleteUserLink;

  /// תווית מספר גרסה בתחתית מסך ההגדרות
  ///
  /// In he, this message translates to:
  /// **'גרסה {version}'**
  String settingsVersionLabel(String version);

  /// כותרת מסך ההגדרות
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settingsScreenTitle;

  /// כפתור שינוי שם בכרטיס הפרופיל
  ///
  /// In he, this message translates to:
  /// **'שנה שם'**
  String get settingsChangeNameButton;

  /// תווית סטטיסטיקת לוגואים שנפתרו
  ///
  /// In he, this message translates to:
  /// **'לוגואים'**
  String get settingsLogosStatLabel;

  /// תווית סטטיסטיקת ניצחונות
  ///
  /// In he, this message translates to:
  /// **'ניצחונות'**
  String get settingsWinsStatLabel;

  /// צ'יפ הפעלת רטט
  ///
  /// In he, this message translates to:
  /// **'רטט'**
  String get settingsVibrationLabel;

  /// צ'יפ הפעלת התראות
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get settingsNotificationsLabel;

  /// שורת הזמינו חברים
  ///
  /// In he, this message translates to:
  /// **'הזמינו חברים'**
  String get settingsInviteFriendsLabel;

  /// שורת וכותרת דיאלוג איך משחקים
  ///
  /// In he, this message translates to:
  /// **'איך משחקים?'**
  String get settingsHowToPlayLabel;

  /// תוכן דיאלוג איך משחקים
  ///
  /// In he, this message translates to:
  /// **'בכל שלב יופיע לוגו מטושטש או חתוך. עליכם להקליד את השם המדויק באמצעות המקלדת למטה.\n\n🗺️ רמות ושלבים: מתקדמים לפי קטגוריות - כל פתרון פותח את השלב הבא. פתרון מוצלח מזכה ב-10 XP ו-2 מטבעות (כל רמז אות מוריד 1 XP, ופתרון המילה ברמז נותן 5 XP בלבד).\n\n🎲 אתגר רנדומלי: לוגו אקראי מכל הקטגוריות, בלי חזרות! כל פתרון נכון מגדיל את הרצף 🔥 ומוסיף בונוס XP (עד +5). הרצף נשמר גם כשיוצאים - ומתאפס רק אם טועים במילה.\n\n⚔️ דו-קרב 1 על 1: שני שחקנים מקבלים את אותם הלוגואים, הראשון שמסיים - מנצח. עולה אנרגיה (מתחדשת עם הזמן).\n\n💡 רמזים: חשיפת אות - 15 מטבעות, פתרון המילה - 60 מטבעות. נגמרו המטבעות? אפשר לצפות בפרסומת ולקבל רמז חינם!'**
  String get settingsHowToPlayBody;

  /// שורת חיבור חשבון כשלא מקושר
  ///
  /// In he, this message translates to:
  /// **'חיבור חשבון'**
  String get settingsLinkAccountLabel;

  /// הסבר קטן מתחת לשורת חיבור חשבון
  ///
  /// In he, this message translates to:
  /// **'שומר את ההתקדמות שלך גם אם תחליף מכשיר'**
  String get settingsLinkAccountSub;

  /// שורת חשבון מקושר
  ///
  /// In he, this message translates to:
  /// **'מחובר - {names}'**
  String settingsLinkedAccountLabel(String names);

  /// כותרת דיאלוג אישור התנתקות
  ///
  /// In he, this message translates to:
  /// **'להתנתק מהחשבון?'**
  String get settingsSignOutConfirmTitle;

  /// תוכן דיאלוג אישור התנתקות
  ///
  /// In he, this message translates to:
  /// **'ההתקדמות הנוכחית שלך תישאר במכשיר הזה כרגיל. תוכל להתחבר שוב לאותו חשבון בכל עת.'**
  String get settingsSignOutConfirmBody;

  /// כפתור התנתקות
  ///
  /// In he, this message translates to:
  /// **'התנתק'**
  String get settingsSignOutButton;

  /// הודעה שההתנתקות הצליחה
  ///
  /// In he, this message translates to:
  /// **'התנתקת מהחשבון'**
  String get settingsSignedOutMessage;

  /// כותרת דיאלוג אישור מחיקת משתמש
  ///
  /// In he, this message translates to:
  /// **'למחוק את המשתמש?'**
  String get settingsDeleteAccountConfirmTitle;

  /// תוכן דיאלוג אישור מחיקת משתמש
  ///
  /// In he, this message translates to:
  /// **'כל ההתקדמות שלך (מטבעות, XP, שלבים, רצפים) תימחק לצמיתות ולא ניתן יהיה לשחזר אותה. הפעולה סופית.'**
  String get settingsDeleteAccountConfirmBody;

  /// כפתור מחיקה לצמיתות
  ///
  /// In he, this message translates to:
  /// **'מחק לצמיתות'**
  String get settingsDeletePermanentlyButton;

  /// הודעה שהמשתמש נמחק בהצלחה
  ///
  /// In he, this message translates to:
  /// **'המשתמש נמחק. סגור ופתח מחדש את האפליקציה כדי להתחיל מחדש.'**
  String get settingsAccountDeletedMessage;

  /// הודעה שמחיקת המשתמש נכשלה
  ///
  /// In he, this message translates to:
  /// **'המחיקה נכשלה, נסה שוב מאוחר יותר'**
  String get settingsDeleteFailedMessage;

  /// נושא מייל דיווח תקלה
  ///
  /// In he, this message translates to:
  /// **'דיווח תקלה - זהה את הלוגו!'**
  String get settingsSupportEmailSubject;

  /// תוכן מייל דיווח תקלה
  ///
  /// In he, this message translates to:
  /// **'היי!\n\nתיאור התקלה:\n\n\nמה עשיתי כשזה קרה:\n\n\n---\nהשם שלי במשחק: {username}'**
  String settingsSupportEmailBody(String username);

  /// הודעה כשאין אפליקציית מייל
  ///
  /// In he, this message translates to:
  /// **'לא נמצאה אפליקציית מייל. אפשר לכתוב לנו ידנית ל-{email}'**
  String settingsNoMailAppMessage(String email);

  /// כותרת דיאלוג שינוי שם
  ///
  /// In he, this message translates to:
  /// **'שינוי שם'**
  String get settingsChangeNameDialogTitle;

  /// כפתור שמירה בדיאלוג שינוי שם
  ///
  /// In he, this message translates to:
  /// **'שמור'**
  String get settingsSaveButton;

  /// שם טאב 'משחק' בהגדרות
  ///
  /// In he, this message translates to:
  /// **'משחק'**
  String get settingsTabGame;

  /// שם טאב 'צליל' בהגדרות
  ///
  /// In he, this message translates to:
  /// **'צליל'**
  String get settingsTabSound;

  /// שם טאב 'חשבון' בהגדרות
  ///
  /// In he, this message translates to:
  /// **'חשבון'**
  String get settingsTabAccount;

  /// שם טאב 'עזרה' בהגדרות
  ///
  /// In he, this message translates to:
  /// **'עזרה'**
  String get settingsTabHelp;

  /// משפט הסבר קטן מתחת לטאבים, כשטאב 'משחק' נבחר
  ///
  /// In he, this message translates to:
  /// **'איך המשחק מרגיש לכם'**
  String get settingsTabHintGame;

  /// משפט הסבר קטן מתחת לטאבים, כשטאב 'צליל' נבחר
  ///
  /// In he, this message translates to:
  /// **'מוזיקה, אפקטים ורטט'**
  String get settingsTabHintSound;

  /// משפט הסבר קטן מתחת לטאבים, כשטאב 'התראות' נבחר
  ///
  /// In he, this message translates to:
  /// **'על מה נעדכן אתכם'**
  String get settingsTabHintNotifications;

  /// משפט הסבר קטן מתחת לטאבים, כשטאב 'חשבון' נבחר
  ///
  /// In he, this message translates to:
  /// **'פרטיות, רכישות וחיבור'**
  String get settingsTabHintAccount;

  /// משפט הסבר קטן מתחת לטאבים, כשטאב 'עזרה' נבחר
  ///
  /// In he, this message translates to:
  /// **'תמיכה ועוד'**
  String get settingsTabHintHelp;

  /// שורת בחירת שפת המשחק בטאב משחק
  ///
  /// In he, this message translates to:
  /// **'שפת המשחק'**
  String get settingsGameLanguageLabel;

  /// מחוון עוצמת מוזיקה בטאב צליל
  ///
  /// In he, this message translates to:
  /// **'מוזיקה'**
  String get settingsMusicLabel;

  /// מחוון עוצמת אפקטים בטאב צליל
  ///
  /// In he, this message translates to:
  /// **'אפקטים'**
  String get settingsEffectsLabel;

  /// מתג אישור לפני קניית רמז בטאב משחק
  ///
  /// In he, this message translates to:
  /// **'אישור לפני קניית רמז'**
  String get settingsHintConfirmLabel;

  /// הסבר קטן מתחת למתג אישור לפני קניית רמז
  ///
  /// In he, this message translates to:
  /// **'שלא תבזבזו מטבעות בטעות'**
  String get settingsHintConfirmSub;

  /// מתג הצגת טיימר בשלבים בטאב משחק
  ///
  /// In he, this message translates to:
  /// **'הצגת טיימר בשלבים'**
  String get settingsLevelTimerLabel;

  /// מתג מעבר אוטומטי ללוגו הבא בטאב משחק
  ///
  /// In he, this message translates to:
  /// **'מעבר אוטומטי ללוגו הבא'**
  String get settingsAutoAdvanceLabel;

  /// הסבר קטן מתחת למתג מעבר אוטומטי
  ///
  /// In he, this message translates to:
  /// **'אפשר להמשיך גם ידנית בכל רגע'**
  String get settingsAutoAdvanceSub;

  /// הסבר קטן מתחת למתג הרטט
  ///
  /// In he, this message translates to:
  /// **'בתשובה נכונה ושגויה'**
  String get settingsVibrationSub;

  /// מתג-על להתראות בטאב התראות
  ///
  /// In he, this message translates to:
  /// **'כל ההתראות'**
  String get settingsNotifAllLabel;

  /// מתג תזכורות טורניר (התחלה/סיום)
  ///
  /// In he, this message translates to:
  /// **'עדכוני טורניר'**
  String get settingsNotifTournamentLabel;

  /// מתג תזכורות יומיות (איפוס/אתגר יומי)
  ///
  /// In he, this message translates to:
  /// **'תזכורות יומיות'**
  String get settingsNotifDailyLabel;

  /// מתג תזכורת אנרגיה מלאה
  ///
  /// In he, this message translates to:
  /// **'האנרגיה התמלאה'**
  String get settingsNotifEnergyLabel;

  /// כותרת שורת תצוגה מקדימה של הישגים בכרטיס הפרופיל
  ///
  /// In he, this message translates to:
  /// **'ההישגים שלי'**
  String get settingsMyAchievementsLabel;

  /// תואר שחקן - שלב התחלתי
  ///
  /// In he, this message translates to:
  /// **'מתחיל'**
  String get settingsRankBeginner;

  /// תואר שחקן - שלב מתקדם
  ///
  /// In he, this message translates to:
  /// **'מתקדם'**
  String get settingsRankIntermediate;

  /// תואר שחקן - שלב ותיק
  ///
  /// In he, this message translates to:
  /// **'ותיק'**
  String get settingsRankVeteran;

  /// תואר שחקן - שלב מתקדם ביותר
  ///
  /// In he, this message translates to:
  /// **'אלוף'**
  String get settingsRankChampion;

  /// תווית לפני הקוד האישי בבאנר הזמנת חברים
  ///
  /// In he, this message translates to:
  /// **'הקוד שלכם:'**
  String get settingsInviteCodeLabel;

  /// כותרת שורת עקבו אחרינו
  ///
  /// In he, this message translates to:
  /// **'עקבו אחרינו'**
  String get settingsFollowUsLabel;

  /// הסבר קטן מתחת לכותרת עקבו אחרינו
  ///
  /// In he, this message translates to:
  /// **'+{coins} על כל אחד'**
  String settingsFollowRewardLabel(int coins);

  /// שורת הסרת פרסומות בטאב חשבון
  ///
  /// In he, this message translates to:
  /// **'הסרת פרסומות'**
  String get settingsRemoveAdsLabel;

  /// ערך שמוצג כשהסרת הפרסומות כבר פעילה
  ///
  /// In he, this message translates to:
  /// **'פעיל'**
  String get settingsRemoveAdsOwnedLabel;

  /// שורת 'צור קשר' כללית בטאב עזרה (בנפרד מדיווח תקלה)
  ///
  /// In he, this message translates to:
  /// **'צור קשר'**
  String get settingsContactUsLabel;

  /// נושא מייל פנייה כללית (לא דיווח תקלה)
  ///
  /// In he, this message translates to:
  /// **'פנייה כללית - זהה את הלוגו!'**
  String get settingsGeneralContactSubject;

  /// תוכן מייל פנייה כללית
  ///
  /// In he, this message translates to:
  /// **'היי!\n\n\n---\nהשם שלי במשחק: {username}'**
  String settingsGeneralContactBody(String username);

  /// כותרת שלב הסיור על כפתור שחק
  ///
  /// In he, this message translates to:
  /// **'כאן מתחילים לשחק'**
  String get mainMenuTourPlayButtonTitle;

  /// תוכן שלב הסיור על כפתור שחק
  ///
  /// In he, this message translates to:
  /// **'לחצו על כפתור \"שחק\" כדי לראות את כל המודים - שלבים, תפזורת, רנדומלי, אתגר יומי ומשחק מול אחרים בזמן אמת.'**
  String get mainMenuTourPlayButtonBody;

  /// כותרת שלב הסיור על כרטיס השלבים בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'עכשיו תתחילו לשחק'**
  String get mainMenuTourLevelsCardTitle;

  /// תוכן שלב הסיור על כרטיס השלבים בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'לחצו על \"שלבים\" כדי לבחור עולם ולפתור את הלוגו הראשון שלכם!'**
  String get mainMenuTourLevelsCardBody;

  /// תג חי בכרטיס טורניר הבית
  ///
  /// In he, this message translates to:
  /// **'טורניר יומי · עכשיו'**
  String get mainMenuTournamentHeroLiveBadge;

  /// תווית סכום הקופה בכרטיס טורניר הבית
  ///
  /// In he, this message translates to:
  /// **'הקופה'**
  String get mainMenuTournamentHeroPotLabel;

  /// מספר משתתפים בכרטיס טורניר הבית
  ///
  /// In he, this message translates to:
  /// **'{count} משתתפים'**
  String mainMenuTournamentHeroParticipants(int count);

  /// כפתור הצטרפות בכרטיס טורניר הבית
  ///
  /// In he, this message translates to:
  /// **'הצטרפו ב־{fee} 🪙'**
  String mainMenuTournamentHeroJoinButton(int fee);

  /// כותרת כרטיסון אתגר יומי במסך הבית
  ///
  /// In he, this message translates to:
  /// **'אתגר יומי'**
  String get mainMenuDailyChallengeMiniTitle;

  /// כותרת כרטיסון חברים מחוברים במסך הבית
  ///
  /// In he, this message translates to:
  /// **'מחוברים'**
  String get mainMenuFriendsMiniTitle;

  /// כותרת כרטיס מובילי הטורניר היומי
  ///
  /// In he, this message translates to:
  /// **'המובילים היום'**
  String get mainMenuTopPerformersTitle;

  /// הודעה כשאין עדיין משתתפים בטורניר היום
  ///
  /// In he, this message translates to:
  /// **'אף אחד עדיין לא שיחק בטורניר היום - תהיו הראשונים!'**
  String get mainMenuTopPerformersEmpty;

  /// כותרת גיליון בחירת המודים
  ///
  /// In he, this message translates to:
  /// **'איך משחקים היום?'**
  String get mainMenuModesSheetTitle;

  /// כותרת קטע לבד בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'לבד'**
  String get mainMenuModesSheetSoloSection;

  /// כותרת כרטיס תפזורת בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'תפזורת'**
  String get mainMenuModesTafzoretTitle;

  /// מספר עולמות תפזורת בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'{count} עולמות'**
  String mainMenuModesTafzoretNote(int count);

  /// כותרת כרטיס שלבים בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'שלבים'**
  String get mainMenuModesLevelsTitle;

  /// רמה נוכחית בכרטיס שלבים בגיליון המודים
  ///
  /// In he, this message translates to:
  /// **'רמה {level}'**
  String mainMenuModesLevelsNote(int level);

  /// תווית טאב טורנירים בסרגל התחתון של מסך הבית
  ///
  /// In he, this message translates to:
  /// **'טורנירים'**
  String get mainMenuBottomNavTournaments;

  /// כותרת גיליון בחירת סוג טורניר
  ///
  /// In he, this message translates to:
  /// **'בחרו טורניר'**
  String get mainMenuTournamentChooserTitle;

  /// כותרת כרטיס האתגר הרב-יומי בגיליון בחירת טורניר
  ///
  /// In he, this message translates to:
  /// **'אתגר 3 הימים'**
  String get mainMenuTournamentChooserDailyTitle;

  /// תת-כותרת כרטיס טורניר יומי
  ///
  /// In he, this message translates to:
  /// **'הצטרפו ב-{fee} מטבעות לאירוע של 3 ימים · הקופה מתחילה כבר ב-100'**
  String mainMenuTournamentChooserDailySubtitle(int fee);

  /// כותרת כרטיס טורניר מתוזמן בגיליון בחירת טורניר
  ///
  /// In he, this message translates to:
  /// **'טורניר מתוזמן'**
  String get mainMenuTournamentChooserScheduledTitle;

  /// תת-כותרת כרטיס טורניר מתוזמן
  ///
  /// In he, this message translates to:
  /// **'כל יום ב-20:00 · הצטרפו ב-{fee} מטבעות · {count} לוגואים'**
  String mainMenuTournamentChooserScheduledSubtitle(int fee, int count);

  /// תווית כפתור הזמנת חבר בשורת הסטוריז במסך הבית
  ///
  /// In he, this message translates to:
  /// **'הזמנה'**
  String get mainMenuStoriesInviteLabel;

  /// תג מחובר על אווטאר חבר בשורת הסטוריז
  ///
  /// In he, this message translates to:
  /// **'מחובר'**
  String get mainMenuFriendOnlineStatus;

  /// תג לא מחובר על אווטאר חבר בשורת הסטוריז
  ///
  /// In he, this message translates to:
  /// **'לא מחובר'**
  String get mainMenuFriendOfflineStatus;

  /// כותרת קטע האירועים החיים במסך הבית
  ///
  /// In he, this message translates to:
  /// **'קורה עכשיו'**
  String get mainMenuHappeningNowTitle;

  /// תת-כותרת כרטיס הטורניר בקטע קורה עכשיו
  ///
  /// In he, this message translates to:
  /// **'קופה {pot} מטבעות · {count} משתתפים'**
  String mainMenuTournamentRowSubtitle(int pot, int count);

  /// תווית זמן שנותר בכרטיס אירוע
  ///
  /// In he, this message translates to:
  /// **'נשאר'**
  String get mainMenuEventRowTimeLeftLabel;

  /// כותרת כרטיס בונוס החנות בקטע קורה עכשיו
  ///
  /// In he, this message translates to:
  /// **'בונוס ניצחון בטורניר'**
  String get mainMenuShopBonusTitle;

  /// תת-כותרת כרטיס בונוס החנות
  ///
  /// In he, this message translates to:
  /// **'פי 1.25 מטבעות בכל רכישה בחנות'**
  String get mainMenuShopBonusSubtitle;

  /// כפתור המשך בכרטיס אתגר יומי בקטע קורה עכשיו
  ///
  /// In he, this message translates to:
  /// **'המשך'**
  String get mainMenuContinueButton;

  /// כותרת כרטיס הדירוג האישי במסך הבית
  ///
  /// In he, this message translates to:
  /// **'הדירוג שלך היום'**
  String get mainMenuTodayRankingTitle;

  /// תווית השורה שלך בכרטיס הדירוג האישי
  ///
  /// In he, this message translates to:
  /// **'אתה'**
  String get mainMenuTodayRankingYouLabel;

  /// הודעת מרחק XP מהשחקן שמעליך בכרטיס הדירוג האישי
  ///
  /// In he, this message translates to:
  /// **'▲ עוד {xp} XP ואתה עוקף את {name}'**
  String mainMenuTodayRankingAheadMessage(int xp, String name);

  /// הודעה כשהשחקן עדיין לא מופיע בטבלת הדירוג
  ///
  /// In he, this message translates to:
  /// **'שחקו כדי להופיע בטבלת הדירוג!'**
  String get mainMenuTodayRankingEmpty;

  /// כותרת כרטיס הזמנה כשאין עדיין חברים במסך הבית
  ///
  /// In he, this message translates to:
  /// **'עדיין אין לך חברים'**
  String get mainMenuNoFriendsTitle;

  /// תת-כותרת כרטיס הזמנה כשאין עדיין חברים
  ///
  /// In he, this message translates to:
  /// **'הזמינו חברים ותתחרו ביחד!'**
  String get mainMenuNoFriendsSubtitle;

  /// תת-כותרת כרטיס קישור מהיר לחנות במסך הבית
  ///
  /// In he, this message translates to:
  /// **'מטבעות, אנרגיה ועוד'**
  String get mainMenuShopQuickLinkSubtitle;

  /// כותרת ראשית במסך הבית (עיצוב Home v10)
  ///
  /// In he, this message translates to:
  /// **'זהה את הלוגו'**
  String get mainMenuHomeTitle;

  /// משפט קריצה מתחת לכותרת הראשית במסך הבית
  ///
  /// In he, this message translates to:
  /// **'כמה לוגואים אתם מכירים?'**
  String get mainMenuHomeTagline;

  /// כותרת קצרה לגיליון בחירת המודים (עיצוב Home v10)
  ///
  /// In he, this message translates to:
  /// **'בחרו מוד'**
  String get mainMenuModesSheetTitleShort;

  /// משפט קריצה מתחת לכותרת הגדולה במסך בחירת המודים (עיצוב מסך-מלא, לפי המוקאפ)
  ///
  /// In he, this message translates to:
  /// **'בחרו מוד ויוצאים לדרך'**
  String get mainMenuModesSheetSubtitle;

  /// תת-כותרת תא הטורנירים בתלתן של מסך הבית - החלק העברי בלבד (ללא השעון), כי צירוף שעון HH:MM:SS בתוך אותו מחרוזת עברית-RTL גרם לבעיית bidi שהסתירה/בלבלה את הספרות - השעון מוצג בנפרד ב-Directionality(ltr) משלו, אותו דפוס כמו תת-כותרת תא המשימות
  ///
  /// In he, this message translates to:
  /// **'קופה {pot} ·'**
  String mainMenuTournamentTileSubtitlePrefix(int pot);

  /// תת-כותרת תא החנות בתלתן כשבונוס ניצחון הטורניר פעיל
  ///
  /// In he, this message translates to:
  /// **'בונוס פעיל!'**
  String get mainMenuShopTileBonusActive;

  /// כותרת פס התקדמות הרמה במסך הבית
  ///
  /// In he, this message translates to:
  /// **'רמה {world} · שלב {sub}'**
  String mainMenuLevelProgressTitle(int world, int sub);

  /// תת-כותרת פס התקדמות הרמה במסך הבית
  ///
  /// In he, this message translates to:
  /// **'כל לוגו מקרב אתכם לעולם הבא'**
  String get mainMenuLevelProgressSubtitle;

  /// תג רצף כניסה יומי ליד השם בשורה העליונה
  ///
  /// In he, this message translates to:
  /// **'🔥 {days}'**
  String mainMenuStreakBadge(int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
