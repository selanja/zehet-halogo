// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get settingsLanguageLabel => 'שפה';

  @override
  String get languageChoiceTitle => 'בחרו שפה';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageEnglish => 'אנגלית';

  @override
  String get accountConflictTitle => 'מצאנו לך חשבון קיים';

  @override
  String get accountConflictMessage =>
      'לחשבון הזה כבר יש התקדמות שמורה ממכשיר אחר. לאיזו התקדמות תרצה להתחבר?';

  @override
  String get accountConflictCloudProgressTitle => 'ההתקדמות השמורה בחשבון';

  @override
  String get accountConflictLocalProgressTitle => 'ההתקדמות הנוכחית במכשיר הזה';

  @override
  String get accountConflictUseCloudButton => 'התחבר עם ההתקדמות השמורה';

  @override
  String get accountConflictUseLocalButton => 'השאר את ההתקדמות הנוכחית שלי';

  @override
  String get accountConflictWarning =>
      'שים לב: האפשרות שלא תבחר תימחק ולא תהיה ניתנת לשחזור.';

  @override
  String get accountConflictCancelButton => 'ביטול';

  @override
  String accountConflictLevelLabel(int level) {
    return 'רמה $level';
  }

  @override
  String get accountLinkTitle => 'שמור את ההתקדמות שלך';

  @override
  String get accountLinkMessage =>
      'חבר חשבון Google או Apple - כך אם תחליף טלפון, כל המטבעות וההתקדמות שלך יישמרו ויחכו לך.';

  @override
  String get accountLinkCancelButton => 'ביטול';

  @override
  String get accountLinkContinueWithGoogle => 'המשך עם Google';

  @override
  String get accountLinkContinueWithApple => 'המשך עם Apple';

  @override
  String get accountLinkLaterButton => 'אחר כך';

  @override
  String get accountLinkDontShowAgain => 'אל תזכיר לי שוב';

  @override
  String get accountLinkSuccessMessage =>
      'החשבון קושר בהצלחה! ההתקדמות שלך שמורה';

  @override
  String get accountLinkFailedMessage => 'החיבור נכשל, נסה שוב מאוחר יותר';

  @override
  String get notEnoughCoinsTitle => 'אין לך מספיק מטבעות';

  @override
  String notEnoughCoinsMessage(int cost, int coins) {
    return 'זה עולה $cost מטבעות ויש לך רק $coins';
  }

  @override
  String notEnoughCoinsMissing(int amount) {
    return 'חסרים $amount';
  }

  @override
  String get notEnoughCoinsShopButton => 'לחנות המטבעות';

  @override
  String get notEnoughCoinsCancelButton => 'ביטול';

  @override
  String get onboardingGiftHeader => 'סיימתם את ההדרכה';

  @override
  String get onboardingGiftTitle => 'פרס נאסף!';

  @override
  String get onboardingGiftSubtitle =>
      'מגיע לכם על הרמה הראשונה - אתם מוכנים להמשיך בעצמכם!';

  @override
  String onboardingGiftRewardCoinsEnergy(int coins, int energy) {
    return '$coins מטבעות + $energy אנרגיה';
  }

  @override
  String onboardingGiftRewardCoinsOnly(int coins) {
    return '$coins מטבעות';
  }

  @override
  String get onboardingGiftRewardLabel => 'מתנת השלמת ההדרכה';

  @override
  String get onboardingGiftContinueButton => 'המשיכו לשחק ›';

  @override
  String outOfResourceTimeHours(String time) {
    return '$time שעות';
  }

  @override
  String outOfResourceTimeMinutes(String time) {
    return '$time דקות';
  }

  @override
  String outOfResourceAdCoinsCooldownMsg(String time) {
    return 'אפשר לקבל מטבעות מפרסומת שוב בעוד $time';
  }

  @override
  String get outOfResourceNoAdAvailable =>
      'אין פרסומת זמינה כרגע, נסה שוב עוד רגע';

  @override
  String outOfResourceAdEnergyCooldownMsg(String time) {
    return 'אפשר לצפות בפרסומת נוספת בעוד $time';
  }

  @override
  String outOfResourceCoinsRewardSubtitle(int hours) {
    return 'חוזר שוב בעוד $hours שעות';
  }

  @override
  String outOfResourceWatchAdCoins(int amount) {
    return 'צפה בפרסומת (+$amount מטבעות) 🎬';
  }

  @override
  String outOfResourceWatchAdEnergy(int amount) {
    return 'צפה בפרסומת (+$amount אנרגיה) 🎬';
  }

  @override
  String get outOfResourceBuyCoinsButton => 'קנה מטבעות בחנות 🪙';

  @override
  String get outOfResourceBuyEnergyButton => 'קנה אנרגיה בחנות ⚡';

  @override
  String get explainerGotItButton => 'הבנתי!';

  @override
  String get duelLobbyBarTitleSearching => 'מחפש יריב';

  @override
  String duelLobbyBarSubtitleSearching(int stake, int logos) {
    return 'דו־קרב על $stake מטבעות · $logos לוגואים';
  }

  @override
  String get duelLobbyBarTitleDefault => 'דו־קרב 1 על 1';

  @override
  String get duelLobbyBarSubtitleChoosing => 'בחר על מה משחקים';

  @override
  String get duelLobbyBannedTitle => 'חסום זמנית מדו-קרב';

  @override
  String duelLobbyBannedMessage(String time) {
    return 'עזבת דו-קרב באמצע המשחק יותר מפעם אחת - זו לא הוגן כלפי היריבים שממתינים לתשובה. תוכל לשחק דו-קרב שוב בעוד $time.';
  }

  @override
  String get duelLobbyBannedTimeFewMoments => 'כמה רגעים';

  @override
  String duelLobbyBannedTimeHoursMinutes(int hours, int minutes) {
    return '$hours שעות ו-$minutes דקות';
  }

  @override
  String duelLobbyBannedTimeMinutes(int minutes) {
    return '$minutes דקות';
  }

  @override
  String get duelLobbyBackButton => 'חזרה';

  @override
  String get duelLobbyClearBanDebugButton => 'נקה חסימה (דיבאג)';

  @override
  String get duelLobbyStakeSheetTitle => 'על מה משחקים?';

  @override
  String duelLobbyEnergyInfoRow(int cost, int energy) {
    return 'כל דו-קרב עולה $cost אנרגיה · יש לך $energy';
  }

  @override
  String get duelLobbyCancelButton => 'ביטול';

  @override
  String duelLobbyStakeSubtitle(int logos, int prize) {
    return '$logos לוגואים · המנצח לוקח $prize';
  }

  @override
  String get duelLobbyMostPopularBadge => 'הכי פופולרי';

  @override
  String duelLobbyStakeCoinsLabel(int stake) {
    return '$stake מטבעות';
  }

  @override
  String get duelLobbyBadgeBlitz => 'בזק ⚡';

  @override
  String get duelLobbyBadgeWarmup => 'חימום';

  @override
  String get duelLobbyBadgeExperienced => 'מנוסים';

  @override
  String get duelLobbyBadgeMax => 'מקסימלי';

  @override
  String get duelLobbyBadgePro => 'מקצועי';

  @override
  String get duelLobbyReadyLabel => 'מוכן ✓';

  @override
  String get duelLobbySearchingLabel => 'מחפש…';

  @override
  String get duelLobbyConnectingLabel => 'מתחבר…';

  @override
  String duelLobbySearchingElapsed(String time) {
    return 'מחפש יריב… $time';
  }

  @override
  String get duelLobbyConditionsTitle => 'תנאי הדו־קרב';

  @override
  String get duelLobbyStatStake => 'הימור';

  @override
  String get duelLobbyStatLogos => 'לוגואים';

  @override
  String get duelLobbyStatWinner => 'למנצח';

  @override
  String get duelLobbyNotEnoughEnergyTitle => 'נגמרה האנרגיה ⚡';

  @override
  String duelLobbyNotEnoughEnergyMessage(int cost, int max, int minutes) {
    return 'כל דו-קרב עולה $cost אנרגיות מתוך $max. אנרגיה מתמלאת אוטומטית כל $minutes דקות.';
  }

  @override
  String duelLobbyWatchAdEnergyButton(int amount) {
    return 'צפה בפרסומת (+$amount אנרגיה) 🎬';
  }

  @override
  String get duelLobbyBuyEnergyButton => 'קנה בחנות ⚡';

  @override
  String get duelLobbyNotEnoughCoinsTitle => 'אין מספיק מטבעות';

  @override
  String duelLobbyNotEnoughCoinsMessage(int stake, int coins) {
    return 'דמי כניסה לדו-קרב: החל מ-$stake מטבעות (יש לך $coins). המנצח לוקח את כל הקופה!';
  }

  @override
  String get duelLobbyFoundTitleFallback => 'נמצא יריב! ⚔️';

  @override
  String get duelLobbyOpponentFallbackName => 'יריב';

  @override
  String get duelLobbyOpponentFallbackNameWithThe => 'היריב';

  @override
  String get duelLobbyFoundBadge => 'נמצא יריב!';

  @override
  String get duelLobbyYouLabel => 'אתה';

  @override
  String get duelLobbyOpponentLabel => 'היריב';

  @override
  String get duelLobbyStartingIn => 'הדו־קרב מתחיל בעוד';

  @override
  String get duelLobbyCancelDuelButton => 'ביטול הדו־קרב';

  @override
  String get duelLobbyRankLabel => 'מקום';

  @override
  String get duelLobbyWinsLabel => 'ניצחונות';

  @override
  String get duelLobbyH2hTitle => 'מאזן ראש בראש';

  @override
  String duelLobbyH2hYouWins(int wins) {
    return 'אתה $wins ניצחונות';
  }

  @override
  String duelLobbyH2hOpponentScore(String name, int wins) {
    return '$name $wins';
  }

  @override
  String get duelLobbyNoPlayersTitle => 'אין כרגע שחקנים מחוברים 🙁';

  @override
  String get duelLobbyNoPlayersMessage =>
      'נסה שוב בעוד כמה דקות, או שתף חברים כדי לשחק ביחד';

  @override
  String get duelLobbyRetryButton => 'נסה שוב';

  @override
  String get duelLobbyErrorTitle => 'משהו השתבש';

  @override
  String get duelLobbyStakeErrorMessage =>
      'משהו השתבש, האנרגיה הוחזרה. נסה שוב.';

  @override
  String duelLobbyAdCooldownMsg(String time) {
    return 'אפשר לצפות בפרסומת נוספת בעוד $time';
  }

  @override
  String get duelLobbyNoAdAvailable => 'אין פרסומת זמינה כרגע, נסה שוב עוד רגע';

  @override
  String get duelLobbyOpponentCancelledMessage =>
      'היריב ביטל את הדו-קרב לפני שהתחיל';

  @override
  String get duelLobbySearchingTip1 =>
      'טיפ: כל אחד עונה בקצב שלו - מי שמסיים ראשון את 10 הלוגואים מנצח';

  @override
  String get duelLobbySearchingTip2 =>
      'טיפ: אפשר לקנות רמז זול במיוחד בתוך הדו-קרב אם נתקעים';

  @override
  String get duelLobbySearchingTip3 =>
      'טיפ: המנצח לוקח את כל קופת המטבעות של שני השחקנים';

  @override
  String get duelLobbySearchingTip4 =>
      'טיפ: אין אינטרנט טוב ליריב? הוא יחזור לתור אחרי שנייה';

  @override
  String get duelLobbySearchingTip5 =>
      'טיפ: תרגלו במצב הרגיל כדי להכיר יותר לוגואים לפני דו-קרב';

  @override
  String get logoRaceSearchingTip1 =>
      'טיפ: הלוגו מתחיל מכוסה כמעט לגמרי - ככל שהעיגול נפתח יותר, קל יותר לנחש';

  @override
  String get logoRaceSearchingTip2 =>
      'טיפ: מי שמקליד ראשון את התשובה המלאה הנכונה - זוכה בסיבוב';

  @override
  String get logoRaceSearchingTip3 =>
      'טיפ: אפשר לראות בזמן אמת גם את הניחושים השגויים של היריב בצ\'אט';

  @override
  String get logoRaceSearchingTip4 =>
      'טיפ: המנצח לוקח את כל קופת המטבעות של שני השחקנים';

  @override
  String get logoRaceSearchingTip5 =>
      'טיפ: ככל שרמת ההימור גבוהה יותר - יש יותר לוגואים במרוץ';

  @override
  String get logoRaceNotEnoughEnergyTitle => 'אין מספיק אנרגיה';

  @override
  String logoRaceNotEnoughEnergyMessage(int cost, int max, int minutes) {
    return 'למרוץ נדרשות $cost אנרגיות מתוך $max. אנרגיה מתמלאת אוטומטית כל $minutes דקות.';
  }

  @override
  String logoRaceNotEnoughCoinsMessage(int stake, int coins) {
    return 'דמי כניסה למרוץ: החל מ-$stake מטבעות (יש לך $coins). המנצח לוקח את כל הקופה!';
  }

  @override
  String get logoRaceConnectErrorTitle => 'לא הצלחנו להתחבר';

  @override
  String get logoRaceConnectErrorMessage => 'בדוק את החיבור לאינטרנט ונסה שוב';

  @override
  String get logoRaceNoOpponentTitle => 'אין כרגע יריב זמין';

  @override
  String get logoRaceNoOpponentMessage =>
      'האנרגיה הוחזרה אליך - נסה שוב עוד רגע';

  @override
  String logoRaceWaitingReconnect(String name) {
    return 'ממתין לחיבור מחדש של $name';
  }

  @override
  String logoRaceReconnectTimeoutWarning(int seconds) {
    return 'אם לא יתחבר תוך $seconds שניות, זה ייחשב ניצחון טכני';
  }

  @override
  String get logoRaceDecidingTechnicalWin => 'קובעים ניצחון טכני...';

  @override
  String logoRaceBarSubtitleSearching(int stake, int logos) {
    return 'מרוץ על $stake מטבעות · $logos לוגואים';
  }

  @override
  String get logoRaceBarTitleDefault => 'מרוץ לוגואים 🏁';

  @override
  String get logoRaceBarTitleResults => 'תוצאות המרוץ 🏁';

  @override
  String get logoRaceStakeSheetSubtitle => 'ההימור נלקח משני השחקנים';

  @override
  String get logoRaceInfoRow =>
      'כל לוגו מוסתר כמעט לגמרי - מי שמנחש נכון ראשון בצ\'אט זוכה בסיבוב.';

  @override
  String get logoRacePlayButton => 'שחק';

  @override
  String get logoRaceConditionsTitle => 'תנאי המרוץ';

  @override
  String get logoRaceStartingIn => 'המרוץ מתחיל בעוד';

  @override
  String logoRaceYouScoreLabel(int score) {
    return 'אתה: $score';
  }

  @override
  String logoRaceLogoCounter(int current, int total) {
    return 'לוגו $current/$total';
  }

  @override
  String logoRaceOpponentScoreLabel(String name, int score) {
    return '$name: $score';
  }

  @override
  String get logoRaceRoundNoneGuessed => 'הזמן נגמר - אף אחד לא ניחש';

  @override
  String get logoRaceRoundYouWon => 'ניחשת נכון! עובר ללוגו הבא...';

  @override
  String logoRaceRoundOpponentWon(String name) {
    return '$name ניחש/ה נכון! עובר ללוגו הבא...';
  }

  @override
  String get logoRaceRemoveLetterButton => 'הסר אות';

  @override
  String get logoRaceWinTitle => 'ניצחת!';

  @override
  String get logoRaceDrawTitle => 'תיקו!';

  @override
  String get logoRaceLossTitle => 'היריב ניצח';

  @override
  String logoRaceResultBadge(int stake) {
    return '🏁 מרוץ · על $stake מטבעות';
  }

  @override
  String logoRaceScoreSummary(int score, int total) {
    return '$score מתוך $total לוגואים';
  }

  @override
  String get logoRacePrizeLabel => 'הפרס שלך';

  @override
  String get logoRacePrizeCoinsLabel => 'מטבעות';

  @override
  String get logoRacePlayAgainButton => 'מרוץ נוסף 🏁';

  @override
  String get logoRaceShareButton => 'שיתוף';

  @override
  String logoRaceShareTextWin(int score, int total) {
    return 'ניצחתי במרוץ לוגואים במשחק \"זהה את הלוגו!\" 🏁 $score/$total לוגואים. בואו תנסו לנצח אותי! 🎮';
  }

  @override
  String get logoRaceShareTextLose =>
      'שיחקתי מרוץ לוגואים במשחק \"זהה את הלוגו!\" - בואו תתמודדו איתי! 🏁';

  @override
  String get logoRaceBackToMenuButton => 'חזרה לתפריט';

  @override
  String get logoRaceExitConfirmTitle => 'לצאת מהמרוץ?';

  @override
  String logoRaceExitConfirmMessage(int stake1, int stake2) {
    return 'אם תצא עכשיו היריב יוכרז מנצח ויקבל את כל הקופה ($stake1 שהימרת + $stake2 שלו) - המטבעות שכבר שילמת לא יוחזרו.';
  }

  @override
  String get logoRaceExitEarlyWarning => 'זו עזיבה מוקדמת - תקבל רק אזהרה';

  @override
  String get logoRaceExitForfeitWarning => 'עזיבה בשלב הזה נחשבת פרישה';

  @override
  String logoRaceExitBanThreshold(int count) {
    return '($count אזהרות = חסימה זמנית).';
  }

  @override
  String get logoRaceStayButton => 'להישאר';

  @override
  String get logoRaceLeaveAnywayButton => 'צא בכל זאת';

  @override
  String get logoRaceGoLabel => 'צאו!';

  @override
  String duelRoomSeriesRoundBadge(int round) {
    return '🏆 סיבוב $round/3 בסדרה';
  }

  @override
  String get duelRoomRoundWinTitle => 'ניצחת בסיבוב!';

  @override
  String get duelRoomRoundDrawTitle => 'תיקו בסיבוב';

  @override
  String get duelRoomRoundLossTitle => 'היריב ניצח בסיבוב';

  @override
  String duelRoomSeriesScoreLine(int myWins, int oppWins, String oppName) {
    return 'הסדרה: $myWins - $oppWins מול $oppName';
  }

  @override
  String get duelRoomMovingToNextRound => 'עוברים לסיבוב הבא...';

  @override
  String get duelRoomChooseHintTitle => 'בחר רמז';

  @override
  String get duelRoomRevealLetterTitle => 'חשוף אות';

  @override
  String get duelRoomRevealLetterSubtitle => 'אות אחת נוספת מתגלה מיד';

  @override
  String get duelRoomSolveWordTitle => 'פתור את כל המילה';

  @override
  String get duelRoomSolveWordSubtitle => 'כל האותיות מתגלות בבת אחת';

  @override
  String get duelRoomHintsNotAvailable =>
      'רמזים לא זמינים בהימור הזה - זמינים רק מ-100 מטבעות ומעלה';

  @override
  String duelRoomSeriesBadge(int stake) {
    return '🏆 סדרת דו־קרב · על $stake מטבעות';
  }

  @override
  String duelRoomDuelBadge(int stake) {
    return '⚔️ דו־קרב · על $stake מטבעות';
  }

  @override
  String get duelRoomWinTitle => 'ניצחת!';

  @override
  String get duelRoomDrawTitle => 'תיקו!';

  @override
  String get duelRoomLossTitle => 'היריב ניצח';

  @override
  String duelRoomSeriesDrawScore(int myWins, int oppWins) {
    return 'תיקו בסדרה · $myWins-$oppWins';
  }

  @override
  String duelRoomSeriesWinScore(int myWins, int oppWins) {
    return 'ניצחת את הסדרה $myWins-$oppWins';
  }

  @override
  String duelRoomSeriesLossScore(int myWins, int oppWins) {
    return 'הפסדת את הסדרה $myWins-$oppWins';
  }

  @override
  String duelRoomScoreTimeSummary(int score, int total, String elapsed) {
    return '$score מתוך $total לוגואים · $elapsed דקות';
  }

  @override
  String duelRoomWaitingForRematch(String name) {
    return 'ממתין ל-$name... ⏳';
  }

  @override
  String duelRoomRematchButton(String name) {
    return 'שחק שוב מול $name 🔁';
  }

  @override
  String get duelRoomPlayAgainButton => 'דו-קרב נוסף ⚔️';

  @override
  String duelRoomShareTextWin(int score, int total, String elapsed) {
    return 'ניצחתי בדו-קרב במשחק \"זהה את הלוגו!\" 🏆 $score/$total לוגואים ב-$elapsed דקות. בואו תנסו לנצח אותי! 🎮';
  }

  @override
  String get duelRoomShareTextLose =>
      'שיחקתי דו-קרב במשחק \"זהה את הלוגו!\" - בואו תתמודדו איתי! ⚔️';

  @override
  String get duelRoomExitConfirmTitle => 'לצאת מהדו-קרב?';

  @override
  String duelRoomExitConfirmMessage(int stake1, int stake2) {
    return 'אם תצא עכשיו היריב יוכרז מנצח ויקבל את כל הקופה ($stake1 שהימרת + $stake2 שלו) - המטבעות והאנרגיה שכבר שילמת לא יוחזרו.';
  }

  @override
  String duelRoomExitBanThreshold(int count) {
    return '($count אזהרות = חסימה זמנית מדו-קרב).';
  }

  @override
  String get duelRoomPreparingNextRound => 'מתכוננים לסיבוב הבא...';

  @override
  String get duelRoomOpponentFoundTitle => 'היריב נמצא!';

  @override
  String get duelRoomGoLabel => 'קדימה!';

  @override
  String duelRoomLogoCounter(int current, int total) {
    return 'לוגו $current מתוך $total';
  }

  @override
  String get duelRoomCorrectAnswerBanner => 'תשובה נכונה!';

  @override
  String get duelRoomTimeUpBanner => 'הזמן נגמר!';

  @override
  String get duelRoomHintChipLabel => 'רמז';

  @override
  String duelRoomFinishedAllLogos(int total) {
    return 'סיימת את כל $total הלוגואים! 🎉';
  }

  @override
  String duelRoomWaitingForOpponentToFinish(String name) {
    return 'מחכים ש-$name יסיים גם...';
  }

  @override
  String duelRoomHeaderBadge(int stake) {
    return 'דו־קרב · על $stake מטבעות';
  }

  @override
  String duelRoomOpponentAnsweredBanner(String name) {
    return '$name ענה/תה נכון!';
  }

  @override
  String duelRoomSeriesRoundHeader(int round, int myWins, int oppWins) {
    return 'סדרה · סיבוב $round/3 · $myWins-$oppWins';
  }

  @override
  String duelRoomYouLeadBy(String amount) {
    return 'אתה מוביל ב-$amount';
  }

  @override
  String duelRoomOpponentLeadBy(String name, String amount) {
    return '$name מוביל ב-$amount';
  }

  @override
  String get duelRoomCorrectAnswersSingular => 'תשובה נכונה אחת';

  @override
  String duelRoomCorrectAnswersPlural(int count) {
    return '$count תשובות נכונות';
  }

  @override
  String get duelSeasonLbTitle => 'טבלת עונת הדו-קרבים';

  @override
  String get duelSeasonLbEmptyTitle => 'עדיין אין ניצחונות החודש';

  @override
  String get duelSeasonLbEmptyMessage =>
      'תהיה הראשון לנצח דו-קרב החודש ולפתוח את הטבלה!';

  @override
  String get duelSeasonLbOthersSection => 'שאר המובילים';

  @override
  String get duelSeasonLbYourPlaceSection => 'המקום שלך';

  @override
  String get duelSeasonLbPlayerFallbackName => 'שחקן';

  @override
  String duelSeasonLbYouSuffix(String name) {
    return '$name (אתה)';
  }

  @override
  String get playVsPersonSeriesTitle => 'סדרת דו-קרב';

  @override
  String get playVsPersonSeriesSubtitle =>
      'הטוב מ-3 מול אותו יריב · בונוס מטבעות על ניצחון בסדרה';

  @override
  String get playVsPersonNewBadge => 'חדש';

  @override
  String get playVsPersonDuelTitle => 'דו־קרב';

  @override
  String get playVsPersonDuelSubtitle => '1 על 1 · מי שפותר יותר לוגואים מנצח';

  @override
  String get playVsPersonRaceTitle => 'מירוץ';

  @override
  String get playVsPersonRaceSubtitle =>
      '1 על 1 · מי שמנחש ראשון בכל לוגו מנצח';

  @override
  String playVsPersonLogosRangeSingle(int count) {
    return '$count לוגואים';
  }

  @override
  String playVsPersonLogosRange(int min, int max) {
    return '$min–$max לוגואים';
  }

  @override
  String get playVsPersonSeasonBoardButton => 'טבלת העונה';

  @override
  String get playVsPersonInviteFriendButton => 'קרא לחבר';

  @override
  String get playVsPersonIntroTitle => '3 דרכים לשחק נגד אחרים';

  @override
  String get playVsPersonSeriesIntroDesc =>
      'הטוב מ-3 מול אותו יריב - בונוס מטבעות על ניצחון בסדרה';

  @override
  String get playVsPersonDuelIntroTitle => 'דו-קרב';

  @override
  String get playVsPersonDuelIntroDesc =>
      'עימות 1 על 1 - מי שפותר יותר לוגואים מנצח';

  @override
  String get playVsPersonRaceIntroDesc =>
      'עימות 1 על 1 - מי שמנחש ראשון בכל לוגו מנצח';

  @override
  String get playVsPersonIntroGotItButton => 'הבנתי, בואו נבחר!';

  @override
  String get playVsPersonInviteDirectlyTitle => 'הזמן חבר ישירות';

  @override
  String get playVsPersonFriendOffline => 'לא מחובר';

  @override
  String get playVsPersonChooseModeTitle => 'בחר מוד';

  @override
  String playVsPersonConnectedCount(int count) {
    return '$count מחוברים';
  }

  @override
  String get playVsPersonPlayingLabel => 'משחקים';

  @override
  String get playVsPersonChooseButton => 'בחר';

  @override
  String get friendChallengeModeDuel => 'דו-קרב';

  @override
  String get friendChallengeModeRace => 'מרוץ';

  @override
  String get friendChallengeCreateInviteFailed =>
      'לא הצלחנו ליצור קוד הזמנה - נסה שוב';

  @override
  String get friendChallengeCodeCopied => 'הקוד הועתק! שלח אותו לחבר';

  @override
  String friendChallengeShareText(String mode, String code) {
    return 'בוא נשחק $mode ב\"זהה את הלוגו!\" 🔗 הקוד שלי: $code';
  }

  @override
  String friendChallengeShareSubject(String mode) {
    return 'אתגר $mode';
  }

  @override
  String friendChallengeNoShareAppFallback(String text) {
    return 'לא נמצאה אפליקציית שיתוף. אפשר להעתיק ולשלוח ידנית:\n$text';
  }

  @override
  String friendChallengeCodeLengthError(int length) {
    return 'קוד חייב להיות בן $length תווים';
  }

  @override
  String get friendChallengeCodeNotFoundDetailed =>
      'לא נמצא קוד כזה - ודא שהקלדת נכון';

  @override
  String get friendChallengeOwnCodeDetailed =>
      'זה הקוד שלך - שלח אותו לחבר, לא להזין אותו כאן';

  @override
  String get friendChallengeCodeAlreadyUsed => 'מישהו כבר הצטרף לקוד הזה';

  @override
  String get friendChallengeCodeExpired => 'הקוד הזה כבר פג תוקף';

  @override
  String friendChallengeNotEnoughCoinsForStake(int stake) {
    return 'אין לך מספיק מטבעות להימור הזה ($stake)';
  }

  @override
  String get friendChallengeCodeNotFound => 'לא נמצא קוד כזה';

  @override
  String get friendChallengeOwnCode => 'זה הקוד שלך';

  @override
  String get friendChallengeGenericError => 'משהו השתבש - נסה שוב';

  @override
  String get friendChallengeWaitingTitle => 'ממתין לחבר';

  @override
  String get friendChallengeJoinWithCodeTitle => 'הצטרפות עם קוד';

  @override
  String get friendChallengeDefaultTitle => 'אתגר חבר';

  @override
  String friendChallengeBannedMessage(String time) {
    return 'עזבת דו-קרב באמצע המשחק יותר מפעם אחת. תוכל לשחק דו-קרב שוב בעוד $time.';
  }

  @override
  String friendChallengeNotEnoughEnergyMessage(
    String mode,
    int cost,
    int minutes,
  ) {
    return 'כל $mode עולה $cost אנרגיות. אנרגיה מתמלאת אוטומטית כל $minutes דקות.';
  }

  @override
  String friendChallengeNotEnoughCoinsMessage(int stake, String mode) {
    return 'צריך לפחות $stake מטבעות כדי להתחיל $mode.';
  }

  @override
  String friendChallengeDirectInviteTitle(String friendName, String mode) {
    return 'הזמנת $friendName ל$mode';
  }

  @override
  String friendChallengeGenericInviteTitle(String mode) {
    return 'אתגר חבר ל$mode';
  }

  @override
  String friendChallengeDirectInviteSubtitle(String friendName) {
    return 'בחר על מה משחקים - $friendName יקבל הזמנה מיידית.';
  }

  @override
  String get friendChallengeGenericInviteSubtitle =>
      'בחר על מה משחקים, ואז צור קוד לשלוח לחבר - או הזן קוד שכבר קיבלת.';

  @override
  String get friendChallengeSendInviteButton => 'שלח הזמנה 🎟️';

  @override
  String get friendChallengeCreateCodeButton => 'צור קוד לחבר 🎟️';

  @override
  String get friendChallengeOrDivider => 'או';

  @override
  String get friendChallengeHaveCodeQuestion => 'יש לך קוד מחבר?';

  @override
  String get friendChallengeJoinWithCodeButton => 'הצטרף עם קוד ⌨️';

  @override
  String get friendChallengeFriendFallback => 'חבר';

  @override
  String get friendChallengeTheFriendFallback => 'החבר';

  @override
  String get friendChallengeYourCodeLabel => 'הקוד שלך';

  @override
  String get friendChallengeShareCodeButton => 'שתף קוד';

  @override
  String friendChallengeWaitingForFriendToEnter(
    String friendName,
    String time,
  ) {
    return 'ממתין ש$friendName יזין את הקוד… $time';
  }

  @override
  String get friendChallengeWaitingEllipsis => 'ממתין…';

  @override
  String friendChallengeConditionsTitle(String mode) {
    return 'תנאי ה$mode';
  }

  @override
  String friendChallengeInviteFromName(String name) {
    return 'אתגר מ-$name';
  }

  @override
  String friendChallengeJoinModeButton(String mode, String emoji) {
    return 'הצטרף ל$mode $emoji';
  }

  @override
  String friendChallengeDeclinedTitle(String name) {
    return '$name דחה את ההזמנה';
  }

  @override
  String get friendChallengeDeclinedMessage =>
      'אפשר לנסות שוב מאוחר יותר, או להזמין חבר אחר.';

  @override
  String get friendChallengeExpiredTitle => 'הקוד פג תוקף';

  @override
  String get friendChallengeExpiredMessage =>
      'החבר לא הספיק להצטרף בזמן. אפשר ליצור קוד חדש.';

  @override
  String get friendChallengeNewCodeButton => 'צור קוד חדש';

  @override
  String get friendChallengeWaitingTip1 =>
      'טיפ: שלח לחבר את הקוד בוואטסאפ - הוא יקליד אותו במסך \"יש לי קוד\"';

  @override
  String get friendChallengeWaitingTip2 =>
      'טיפ: הקוד בתוקף ל-15 דקות - אם הוא פג, פשוט תיצור קוד חדש';

  @override
  String get friendChallengeWaitingTip3 =>
      'טיפ: שני השחקנים מקבלים בדיוק אותם לוגואים - הראשון שמסיים מנצח';

  @override
  String get friendChallengeWaitingTip4 =>
      'טיפ: אפשר לקנות רמז זול בתוך הדו-קרב אם נתקעים על לוגו';

  @override
  String get levelLoadingTitle => 'מכינים את השלב…';

  @override
  String get levelLoadingDidYouKnow => 'ידעת?';

  @override
  String get levelLoadingTip1 =>
      'רצף של 5 תשובות נכונות מכפיל את ה-XP שתקבלו בשלב הבא';

  @override
  String get levelLoadingTip2 =>
      'נגמרו המטבעות? אפשר לצפות בפרסומת ולקבל רמז אות אחת בחינם';

  @override
  String get levelLoadingTip3 =>
      'פתרון עצמאי (בלי רמזים) מזכה תמיד ביותר XP מפתרון עם רמז';

  @override
  String get levelLoadingTip4 =>
      'במצב אתגר רנדומלי הרצף נשמר גם כשיוצאים - הוא מתאפס רק אם טועים במילה';

  @override
  String get levelLoadingTip5 =>
      'כל רמז-אות שמשתמשים בו מוריד נקודת XP אחת מהפרס על פתרון השלב';

  @override
  String get levelLoadingTip6 =>
      'אפשר להזמין חברים למשחק ולהתחרות יחד על המקום הראשון בטבלה הארצית';

  @override
  String get appBottomNavShop => 'חנות';

  @override
  String get appBottomNavLeaderboard => 'מובילים';

  @override
  String get appBottomNavMissions => 'משימות';

  @override
  String get appBottomNavFriends => 'חברים';

  @override
  String get appBottomNavPlay => 'שחק';

  @override
  String get appBottomNavHome => 'בית';

  @override
  String get appLoadingTitle => 'זהה את הלוגו!';

  @override
  String get appLoadingTitlePrefix => 'זהה את';

  @override
  String get appLoadingTitleMain => 'הלוגו!';

  @override
  String get appLoadingTagline => 'אלפי לוגואים מחכים לך. כמה תזהה?';

  @override
  String get appLoadingTipLabel => 'טיפ';

  @override
  String get appLoadingTip1 => 'רצף ימים מכפיל את המתנה היומית';

  @override
  String get appLoadingTip2 => 'תקועים? רמז חושף אות אחת מהתשובה';

  @override
  String get appLoadingTip3 => 'בדו־קרב המנצח לוקח את כל הקופה';

  @override
  String get appLoadingTip4 => 'השלימו משימות כדי לעלות בלוגו פאס';

  @override
  String get mainCheckingVersion => 'בודקים גרסה...';

  @override
  String get mainConnectingToServer => 'מתחברים לשרת...';

  @override
  String get mainCheckingActiveGame => 'בודקים משחק פעיל...';

  @override
  String get mainAlmostReady => 'כמעט מוכנים...';

  @override
  String get mainReady => 'מוכנים';

  @override
  String get mainScreenshotWarning =>
      'שים לב: צילומי מסך מהמשחק אסורים לשיתוף מחוץ לאפליקציה';

  @override
  String mainReferralDownloadedSubtitle(String name) {
    return 'כי הורדת את המשחק דרך ההזמנה של $name! 🎉';
  }

  @override
  String get mainReferralFriendJoinedSubtitle =>
      'חבר הצטרף למשחק דרך ההזמנה שלך! 🎉';

  @override
  String mainInviteFromName(String name) {
    return '$name מזמין אותך!';
  }

  @override
  String get mainNoHeadToHeadYet => 'עדיין לא שיחקתם דו-קרב אחד נגד השני';

  @override
  String get mainInvitedToRace => 'מוזמן למרוץ לוגואים 1 על 1';

  @override
  String mainHeadToHeadBalance(int mine, int theirs, String side) {
    return 'מאזן ביניכם: $mine — $theirs $side';
  }

  @override
  String get mainTie => 'תיקו';

  @override
  String get mainInYourFavor => 'לטובתך';

  @override
  String get mainInTheirFavor => 'לטובתו';

  @override
  String get mainAcceptDuelChallenge => 'מקבל את האתגר ⚔';

  @override
  String get mainAcceptRaceChallenge => 'מקבל את האתגר 🏁';

  @override
  String mainAcceptCostWithEnergy(int cost, int energy) {
    return 'עולה $cost ⚡ · יש לך $energy';
  }

  @override
  String mainAcceptCost(int cost) {
    return 'עולה $cost ⚡';
  }

  @override
  String get mainDeclineButton => 'דחה';

  @override
  String get mainInviteBadge => '⚔ הזמנה לדו־קרב';

  @override
  String get worldName1 => 'חברות חלק א';

  @override
  String get worldName2 => 'דגלים חלק א';

  @override
  String get worldName3 => 'אפליקציות';

  @override
  String get worldName4 => 'רכבים';

  @override
  String get worldName5 => 'סופרים';

  @override
  String get worldName6 => 'רשתות מוכרות';

  @override
  String get worldName7 => 'חטיפים וממתקים';

  @override
  String get worldName8 => 'קבוצות כדורגל';

  @override
  String get worldName9 => 'ערים בישראל';

  @override
  String get worldName10 => 'דגלים חלק ב';

  @override
  String get worldName11 => 'בנקים וביטוח';

  @override
  String get worldName12 => 'חברות חלק ב';

  @override
  String get worldName13 => 'משחקים מוכרים';

  @override
  String get worldName14 => 'קבוצות NBA';

  @override
  String get worldName15 => 'יחידות בצה\"ל וכוחות הביטחון';

  @override
  String get worldName16 => 'רכבים חלק ב';

  @override
  String get worldName17 => 'אלקטרוניקה ומכשירי חשמל';

  @override
  String get worldName18 => 'תקשורת וחדשות ישראליות';

  @override
  String get worldName22 => 'קבוצות NFL';

  @override
  String get worldNameDefault => 'כללי';

  @override
  String get mainMenuCollected15Coins => 'קיבלת 15 מטבעות!';

  @override
  String get mainMenuCloseButton => 'סגור';

  @override
  String mainMenuStreakDayTitle(int day) {
    return 'יום $day ברצף!';
  }

  @override
  String get mainMenuComeBackTomorrow => 'תחזור מחר לפרס גדול יותר';

  @override
  String get mainMenuEnergyLabel => 'אנרגיה ';

  @override
  String get mainMenuCoinsLabel => 'מטבעות ';

  @override
  String get mainMenuCollectButton => 'אסוף';

  @override
  String get mainMenuWelcomeTitle => 'ברוכים הבאים!';

  @override
  String get mainMenuWelcomeSubtitle =>
      'התחבר כדי שההתקדמות שלך תישמר גם אם תחליף מכשיר, או פשוט שחק';

  @override
  String get mainMenuPlayAsGuest => 'שחק כאורח';

  @override
  String get mainMenuTermsNotice =>
      'בהמשך אתם מאשרים את תנאי השימוש ומדיניות הפרטיות';

  @override
  String get mainMenuSignInFailed => 'ההתחברות נכשלה, נסה שוב מאוחר יותר';

  @override
  String get mainMenuGoogleSignInFailed =>
      'ההתחברות עם Google נכשלה - אפשר לנסות שוב או לשחק כאורח בינתיים';

  @override
  String get mainMenuAppleSignInFailed =>
      'ההתחברות עם Apple נכשלה - אפשר לנסות שוב או לשחק כאורח בינתיים';

  @override
  String get mainMenuNameEntrySubtitle => 'איך נקרא לך בטבלה הארצית?';

  @override
  String get mainMenuLetsStartButton => 'בואו נתחיל ›';

  @override
  String get mainMenuSkipButton => 'דלג';

  @override
  String get mainMenuTourWelcomeTitle => 'ברוכים הבאים ל\"זהה את הלוגו!\" 🎉';

  @override
  String get mainMenuTourWelcomeBody =>
      'בואו נראה לכם בקצרה איך המשחק עובד - זה ייקח רק חצי דקה, ואפשר לדלג בכל שלב.';

  @override
  String get mainMenuTourStep1Title => 'שחק מול אחרים';

  @override
  String get mainMenuTourStep1Body =>
      'דו-קרב, מירוץ וסדרת דו-קרב נגד שחקנים אמיתיים בזמן אמת.';

  @override
  String get mainMenuTourStep2Title => 'אתגר רנדומלי';

  @override
  String get mainMenuTourStep2Body =>
      'לוגו רנדומלי בכל פעם - פותר נכון שומר על הרצף (🔥) שרואים כאן.';

  @override
  String get mainMenuTourStep3Title => 'כאן מתחילים לשחק';

  @override
  String get mainMenuTourStep3Body =>
      'כפתור \"שחקו את רמה X\" לוקח אתכם למסך השלבים, שם בוחרים את העולם והלוגו הבא לשחק בו. לחצו על הכפתור המואר כדי להתחיל!';

  @override
  String mainMenuTourProgress(int step, int count) {
    return '$step מתוך $count';
  }

  @override
  String get mainMenuTourTapHighlighted => 'לחצו על הכרטיס המואר למעלה';

  @override
  String get mainMenuTourNextButton => 'הבא';

  @override
  String mainMenuLevelPill(int world, int sub, int count) {
    return 'רמה $world • לוגו $sub מתוך $count';
  }

  @override
  String get mainMenuNextLogoTeaser => 'מוכנים לזהות את הלוגו הבא?';

  @override
  String mainMenuPlayLevelButton(int world) {
    return 'שחקו את רמה $world';
  }

  @override
  String get mainMenuDailyRewardClaimed => 'קיבלת את הפרס - חוזר מחר';

  @override
  String get mainMenuDailyUsedUp => 'נוצל להיום, נסה מחר';

  @override
  String mainMenuBpSubtitleWithClaims(int tier, int claims) {
    return 'דרגה $tier • $claims פרסים מחכים';
  }

  @override
  String mainMenuBpTier(int tier) {
    return 'דרגה $tier';
  }

  @override
  String get mainMenuRandomTitle => 'רנדומלי';

  @override
  String mainMenuRandomSubtitle(int streak) {
    return 'לוגו אקראי • רצף $streak 🔥';
  }

  @override
  String get mainMenuRandomChallengeLabel => 'אתגר רנדומלי';

  @override
  String get mainMenuVsOthersTitle => 'מול אחרים';

  @override
  String mainMenuVsOthersSubtitle(int count) {
    return '3 מודים • $count מחוברים';
  }

  @override
  String get mainMenuBattlePassTitle => 'לוגו פאס';

  @override
  String get mainMenuDailyChallengeTitle => 'אתגר יומי';

  @override
  String get mainMenuHelloFallback => 'שלום!';

  @override
  String mainMenuMedalsCount(int earned, int total) {
    return '🎖️ $earned/$total מדליות';
  }

  @override
  String mainMenuMoreTime(String time) {
    return 'עוד $time';
  }

  @override
  String get mainMenuContinuingLabel => 'ממשיכים';

  @override
  String mainMenuWorldStepLabel(String worldName, int sub) {
    return '$worldName · שלב $sub';
  }

  @override
  String get mainMenuPlayVsOthersTitle => 'שחק מול אחרים';

  @override
  String get mainMenuDuelRaceNote => 'דו־קרב · מירוץ';

  @override
  String get mainMenuRandomNote => 'לוגו אקראי · שומר על הרצף';

  @override
  String get mainMenuLogoRaceTitle => 'מרוץ לוגואים 🏁';

  @override
  String get mainMenuLogoRaceSubtitle => '1 על 1 · מי שמנחש ראשון מנצח';

  @override
  String get mainMenuPlayButton => 'שחק';

  @override
  String mainMenuEnergyRewardMessage(int amount) {
    return 'קיבלת $amount אנרגיה! ⚡';
  }

  @override
  String get mainMenuDailyChallengeSubtitleDone =>
      'אתגר יומי · קיבלת את הפרס - חוזר מחר';

  @override
  String get mainMenuDailyChallengeSubtitleUsedUp =>
      'אתגר יומי · נוצל להיום, נסה מחר';

  @override
  String mainMenuDailyChallengeSubtitleDefault(int count) {
    return 'אתגר יומי · $count לוגואים';
  }

  @override
  String get mainMenuDoneCheckLabel => 'בוצע ✓';

  @override
  String get mainMenuReminderLabel => 'תזכורת';

  @override
  String get mainMenuMaxLabel => 'מקסימום';

  @override
  String mainMenuClaimsCount(int claims) {
    return '$claims פרסים';
  }

  @override
  String get mainMenuAlreadyClaimedToday =>
      'כבר נאסף היום - תחזור מחר לפרס הבא';

  @override
  String get mainMenuDiamondWonToday => 'מזל טוב - זכית במארז היהלום של יום 7!';

  @override
  String get mainMenuDiamondTodayIsDay7 =>
      'היום היום הגדול - יום 7 ומארז היהלום!';

  @override
  String get mainMenuDiamondOneDayLeft => 'עוד יום אחד - ומקבל מארז יהלום';

  @override
  String mainMenuDiamondDaysLeft(int days) {
    return 'עוד $days ימים - ומקבל מארז יהלום';
  }

  @override
  String get mainMenuTodaysRewardLabel => 'הפרס של היום';

  @override
  String get mainMenuReminderTomorrow8pm => 'תזכורת מחר · 20:00';

  @override
  String get mainMenuNeedEnergyTitle => 'צריך אנרגיה?';

  @override
  String mainMenuWatchAdEnergySubtitle(int amount) {
    return 'צפה בפרסומת - קבל $amount אנרגיה מיידית';
  }

  @override
  String get mainMenuWatchButton => 'צפה';

  @override
  String get mainMenuAdBonusTitle => 'בונוס פרסומת';

  @override
  String get mainMenuWatchAdCoinsSubtitle => 'צפה בפרסומת - קבל 15 מטבעות';

  @override
  String mainMenuAvailableAgainIn(String time) {
    return 'זמין שוב בעוד $time';
  }

  @override
  String get mainMenuWaitingLabel => 'ממתין';

  @override
  String get mainMenuWaitingLabel2 => 'בהמתנה';

  @override
  String mainMenuInviteShareText(String ios, String android) {
    return 'בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n📱 אייפון: $ios\n🤖 אנדרואיד/גלקסי: $android';
  }

  @override
  String get mainMenuNameHint => 'הקלד את שמך כאן...';

  @override
  String get mainMenuCheckingAvailability => 'בודק זמינות...';

  @override
  String get mainMenuNameAvailable => 'השם פנוי';

  @override
  String get mainMenuNameTaken => 'השם הזה כבר תפוס, נסה שם אחר';

  @override
  String get achievementsTitle => 'הישגים ומדליות';

  @override
  String achievementsEarnedCount(int earned, int total) {
    return '$earned מתוך $total מדליות';
  }

  @override
  String get achievementsDescription =>
      'כל הישג נותן מטבעות. ההתקדמות שלכם נספרת מכאן, לא משנה כמה XP יש לאחרים.';

  @override
  String achievementsClaimedMessage(int coins, String title) {
    return 'קיבלת $coins מטבעות על \"$title\"';
  }

  @override
  String get dailyChallengeTitle => 'אתגר היומי';

  @override
  String get dailyChallengeAlreadyDoneTitle => 'כבר השלמת את האתגר היומי!';

  @override
  String get dailyChallengeComeBackTomorrow =>
      'לוגו חדש ואתגר חדש מחכים לך מחר';

  @override
  String get dailyChallengeUsedUpTitle => 'כבר ניסית את האתגר היומי';

  @override
  String get dailyChallengeUsedUpMessage =>
      'יש רק ניסיון אחד ליום - נסה שוב מחר עם אתגר חדש';

  @override
  String dailyChallengeIntroStats(int count, int seconds) {
    return '$count לוגואים · $seconds שניות בסך הכל';
  }

  @override
  String get dailyChallengeIntroBody =>
      'פתור את כל הלוגואים ברצף לפני שהזמן נגמר וזכה בבונוס. אין רמזים במסך הזה - זה מבחן מהירות!';

  @override
  String get dailyChallengeOneAttemptWarning =>
      '⚠️ יש לך רק ניסיון אחד ליום - גם אם תיכשל';

  @override
  String get dailyChallengeStartButton => 'מוכן? התחל! ⚡';

  @override
  String get dailyChallengeSuccessTitle => 'כל הכבוד! 🎉';

  @override
  String dailyChallengeSuccessTime(String seconds) {
    return 'סיימת את אתגר היום ב-$seconds שניות';
  }

  @override
  String get dailyChallengeTimeUpTitle => 'נגמר הזמן! ⏱️';

  @override
  String dailyChallengeFailedProgress(int current, int total) {
    return 'הגעת ללוגו $current מתוך $total - ניצלת את הניסיון היחיד של היום';
  }

  @override
  String get dailyChallengeTryTomorrow => 'נסה שוב מחר עם אתגר חדש';

  @override
  String get dailyChallengeReminderSet => 'נזכיר לך מחר!';

  @override
  String get dailyChallengeRemindMe => 'תזכיר לי מחר';

  @override
  String get worldName19 => 'דגלים חלק ג\'';

  @override
  String get worldName20 => 'אלקטרוניקה ומכשירי חשמל חלק ב';

  @override
  String get worldName21 => 'כדורסל אירופי (יורוליג)';

  @override
  String get worldName23 => 'קבוצות כדורגל ישראליות';

  @override
  String get worldName24 => 'אולפני סרטים ובידור';

  @override
  String get worldName25 => 'חברות תעופה';

  @override
  String get worldName26 => 'קבוצות כדורגל אירופאיות חלק ב\'';

  @override
  String get levelsUnlockPriceFallback => '₪2.90';

  @override
  String levelsUnlockDialogTitle(int world) {
    return 'רמה $world נעולה';
  }

  @override
  String levelsUnlockDialogBodyNext(String price) {
    return 'אפשר לפתוח אותה עכשיו תמורת $price,\nאו פשוט לסיים את הרמה הקודמת.';
  }

  @override
  String levelsUnlockDialogBodyFar(
    String price,
    int world,
    int needed,
    int next,
  ) {
    return 'פתיחת רמה עולה $price.\nכדי להגיע לרמה $world צריך לפתוח $needed רמות,\nאחת אחרי השנייה - מתחילים ברמה $next.';
  }

  @override
  String get levelsNotNowButton => 'לא עכשיו';

  @override
  String levelsUnlockButton(int next, String price) {
    return 'פתח רמה $next  •  $price';
  }

  @override
  String get levelsUnlockUnavailable =>
      'פתיחת רמות אינה זמינה כרגע, נסה שוב מאוחר יותר';

  @override
  String get levelsChooseLevelTitle => 'בחר רמה';

  @override
  String levelsCountSubtitle(int total, int unlocked) {
    return '$total רמות · $unlocked פתוחות';
  }

  @override
  String levelsDifficultyLabel(int level) {
    return 'קושי $level';
  }

  @override
  String get levelsLockedSubtitle => 'נעול · ניתן לפתוח בתשלום';

  @override
  String levelsSolvedOfTotal(int solved, int total) {
    return '$solved מתוך $total שלבים';
  }

  @override
  String get levelsTourTitle => 'מסך השלבים';

  @override
  String get levelsTourBody =>
      'כל עולם נפתח אוטומטית ברגע שמסיימים את העולם הקודם - בלי שום פעולה נוספת.';

  @override
  String get levelsTourContinueButton => 'המשך ›';

  @override
  String get levelsTourTapHighlighted => 'לחצו על העולם המואר כדי להמשיך';

  @override
  String subLevelsCategoryStageLabel(String category, int stage) {
    return '$category · שלב $stage';
  }

  @override
  String get subLevelsLockedMessage => 'המילה נעולה! פתור את הקודמות.';

  @override
  String get subLevelsAlreadyFoundMessage => 'כבר מצאת את הלוגו הזה!';

  @override
  String get subLevelsYourProgressTitle => 'ההתקדמות שלך';

  @override
  String get subLevelsAllCompletedMessage => 'כל השלבים הושלמו!';

  @override
  String subLevelsNextStageMessage(int stage) {
    return 'השלב הבא: שלב $stage';
  }

  @override
  String subLevelsDoneCount(int count) {
    return '✓ $count הושלמו';
  }

  @override
  String subLevelsRemainingCount(int count) {
    return '· נותרו $count שלבים';
  }

  @override
  String subLevelsCategoryWorldLabel(String category, int world) {
    return '$category · רמה $world';
  }

  @override
  String subLevelsDoneOfTotal(int done, int total) {
    return '$done מתוך $total שלבים הושלמו';
  }

  @override
  String subLevelsContinueToStage(int stage) {
    return 'המשך לשלב $stage';
  }

  @override
  String get subLevelsTourTitle => 'שלבים';

  @override
  String get subLevelsTourBody =>
      'כל שלב נפתח אוטומטית ברגע שפותרים את השלב הקודם - בלי שום פעולה נוספת.';

  @override
  String get subLevelsTourTapHighlighted =>
      'לחצו על השלב המואר כדי להתחיל לשחק';

  @override
  String get subLevelsPlayLabel => 'שחק';

  @override
  String get logoLevelAnonymousPlayerFallback => 'שחקן אנונימי';

  @override
  String get logoLevelStuckTipOnboarding => 'אפשר לקנות רמז עם מטבעות 💡';

  @override
  String get logoLevelStuckTipHasHint => 'יש לך רמז! 💡';

  @override
  String get logoLevelStuckTipFreeAd => 'פרסומת = רמז חינם 🎬';

  @override
  String get logoLevelStuckTipTapLamp => 'לחץ למנורה 💡';

  @override
  String get logoLevelNoInternetTitle => 'אין חיבור לאינטרנט';

  @override
  String get logoLevelNoInternetBody =>
      'כדי לשחק צריך חיבור פעיל לאינטרנט. בדקו את ה-WiFi או הסלולר ונסו שוב.';

  @override
  String get logoLevelTryAgainButton => 'נסה שוב';

  @override
  String get logoLevelRandomCompleteTitle => 'וואו! 🎉';

  @override
  String get logoLevelRandomCompleteBody =>
      'פתרת את כל הלוגואים במצב הרנדומלי!';

  @override
  String get logoLevelBackToMainScreenButton => 'חזרה למסך הראשי';

  @override
  String get logoLevelAboutTitle => 'אודות האפליקציה';

  @override
  String get logoLevelAboutBody =>
      'כל הלוגואים המוצגים באפליקציה זו שייכים לבעליהם בהתאמה. השימוש בלוגואים למטרות זיהוי בלבד נעשה תחת עקרון \'שימוש הוגן\'. אפליקציה זו אינה קשורה, ממומנת או מאושרת על ידי החברות המוצגות.';

  @override
  String get logoLevelCloseButton => 'סגור';

  @override
  String get logoLevelNoAdAvailable => 'אין פרסומת זמינה כרגע, נסה שוב עוד רגע';

  @override
  String get logoLevelNotEnoughCoinsTitle => 'אין לך מספיק מטבעות';

  @override
  String logoLevelNotEnoughCoinsBody(int cost, int coins) {
    return 'הרמז הזה עולה $cost מטבעות ויש לך רק $coins';
  }

  @override
  String logoLevelMissingCoins(int amount) {
    return 'חסרים $amount';
  }

  @override
  String get logoLevelGoToShopButton => 'לחנות המטבעות';

  @override
  String get logoLevelOrDivider => 'או';

  @override
  String get logoLevelWatchAdButton => 'צפה בפרסומת 🎬';

  @override
  String get logoLevelAdHintDescription =>
      'חושף אות אחת בלבד - לא פותר את כל המילה';

  @override
  String get logoLevelAdHintAlreadyUsed => 'כבר ניצלת רמז-פרסומת בשלב הזה 🎬';

  @override
  String get logoLevelHintConfirmTitle => 'לקנות רמז?';

  @override
  String logoLevelHintConfirmBody(int cost) {
    return 'זה יעלה לך $cost מטבעות.';
  }

  @override
  String get logoLevelHintConfirmButton => 'כן, קנה';

  @override
  String get logoLevelChooseHintTitle => 'בחר רמז';

  @override
  String get logoLevelRevealNextLetterTitle => 'חשוף את האות הבאה';

  @override
  String get logoLevelRevealNextLetterSubtitle => 'אות אחת נוספת מתגלה מיד';

  @override
  String get logoLevelSolveWholeWordTitle => 'פתור את כל המילה';

  @override
  String get logoLevelSolveWholeWordSubtitle => 'כל האותיות מתגלות בבת אחת';

  @override
  String get logoLevelWatchAdTitle => 'צפה בפרסומת';

  @override
  String get logoLevelWatchAdSubtitle => 'קבל אות אחת בחינם';

  @override
  String logoLevelNewStreakRecord(int streak) {
    return 'שיא רצף חדש: $streak!';
  }

  @override
  String get logoLevelRepeatedScreenshotMessage =>
      'זוהה צילום מסך נוסף - עוברים לשלב הבא';

  @override
  String get logoLevelLevelCompleteTitle => 'כל הכבוד! 🎉';

  @override
  String logoLevelLevelCompleteBody(int level) {
    return 'סיימת בהצלחה את רמה $level';
  }

  @override
  String logoLevelNextLevelButton(int level) {
    return 'לרמה $level ›';
  }

  @override
  String get logoLevelFinishButton => 'סיום';

  @override
  String get logoLevelCorrectTitle => 'כל הכבוד!';

  @override
  String get logoLevelWrongTitle => 'טעות בשם';

  @override
  String get logoLevelOnboardingCorrectTip =>
      'ככה בדיוק משחקים! כל תשובה נכונה מזכה אתכם בנקודות ניסיון (XP) ומטבעות';

  @override
  String get logoLevelNextStageButton => 'המשך לשלב הבא ›';

  @override
  String logoLevelStreakHeader(int streak) {
    return '🔥 רצף $streak';
  }

  @override
  String get logoLevelRandomChallengeHeader => 'אתגר רנדומלי';

  @override
  String get logoLevelHintChipLabel => 'רמז';

  @override
  String get logoLevelTourStep1Title => 'איפה אתם נמצאים';

  @override
  String get logoLevelTourStep1Body =>
      'כאן רואים את הקטגוריה והשלב הנוכחי - כל לוגו שפותרים מקדם אתכם לשלב הבא.';

  @override
  String get logoLevelTourStep2Title => 'זהו את הלוגו';

  @override
  String get logoLevelTourStep2Body =>
      'זה הלוגו שצריך לזהות ולכתוב את השם שלו.';

  @override
  String get logoLevelTourStep3Title => 'כאן התשובה שלכם';

  @override
  String get logoLevelTourStep3Body =>
      'כל אות שתקלידו תופיע כאן. לחצו על אות שכבר הקלדתם כדי למחוק רק אותה.';

  @override
  String get logoLevelTourStep4Title => 'כאן מקלידים';

  @override
  String get logoLevelTourStep4Body =>
      'הקישו על האותיות כאן כדי למלא את התשובה - לפי הסדר שבו הן מופיעות במילה.';

  @override
  String logoLevelTourStepCounter(int current, int total) {
    return '$current מתוך $total';
  }

  @override
  String get logoLevelTourNextButton => 'הבא';

  @override
  String get logoLevelTourTapLetterToStart => 'לחצו על אות כדי להתחיל';

  @override
  String get logoLevelFreeLabel => 'חינם';

  @override
  String get friendsNowFriendsMessage => 'אתם חברים עכשיו!';

  @override
  String friendsInviteText(String link, int bonus) {
    return 'בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n$link\n\nשנינו נקבל $bonus מטבעות במתנה ברגע שתתקינו ✨';
  }

  @override
  String get friendsShareFallbackCopiedWithPaste =>
      'לא נמצאה אפליקציית שיתוף - ההודעה הועתקה, אפשר להדביק ולשלוח';

  @override
  String get friendsShareFallbackCopied =>
      'לא נמצאה אפליקציית שיתוף - ההודעה הועתקה';

  @override
  String friendsShareCodeText(String code, String iosLink, String androidLink) {
    return 'בוא נהיה חברים ב\"זהה את הלוגו!\" 🎮\nהקוד שלי: $code\n(פותחים את האפליקציה -> חברים -> \"יש לי קוד\" ומזינים אותו)\n\nעוד לא הורדת? 📱 אייפון: $iosLink\n🤖 אנדרואיד/גלקסי: $androidLink';
  }

  @override
  String get friendsShareCodeSubject => 'בוא נהיה חברים!';

  @override
  String get friendsCodeCopiedMessage => 'הקוד הועתק!';

  @override
  String friendsCodeLengthError(int length) {
    return 'קוד חייב להיות בן $length תווים';
  }

  @override
  String get friendsRequestSentMessage => 'בקשת חברות נשלחה! נחכה שהוא יאשר';

  @override
  String get friendsAlreadyRequestedError => 'כבר שלחת לו בקשה - ממתין לאישור';

  @override
  String get friendsAlreadyFriendsError => 'כבר חברים איתו';

  @override
  String get friendsOwnCodeError =>
      'זה הקוד שלך - שלח אותו לחבר, לא להזין אותו כאן';

  @override
  String get friendsCodeNotFoundError => 'לא נמצא קוד כזה - ודא שהקלדת נכון';

  @override
  String get friendsInvalidCodeError => 'קוד לא תקין';

  @override
  String get friendsGenericErrorLater => 'משהו השתבש - נסה שוב מאוחר יותר';

  @override
  String get friendsTopBarTitle => 'חברים';

  @override
  String get friendsHeroTitle => 'שחק עם חברים';

  @override
  String get friendsHeroSubtitle =>
      'הוסף חברים לפי קוד, תראה מי מחובר, והזמן אותם ישר למשחק';

  @override
  String get friendsMyCodeTitle => 'הקוד שלך';

  @override
  String get friendsMyCodeHint =>
      'לחיבור עם חבר שכבר משחק - בלי פרס. להזמנת חבר חדש ומטבעות, גללו למטה 👇';

  @override
  String get friendsShareCodeButton => 'שתף קוד';

  @override
  String get friendsAddFriendPrompt => 'יש לך קוד של חבר?';

  @override
  String get friendsAddButton => 'הוסף';

  @override
  String get friendsPendingRequestsTitle => 'בקשות חברות';

  @override
  String get friendsMyFriendsTitle => 'החברים שלי';

  @override
  String get friendsEmptyListMessage =>
      'עדיין אין לך חברים כאן - שתף את הקוד שלך למעלה כדי להתחיל';

  @override
  String get friendsOnlineStatus => 'מחובר';

  @override
  String get friendsOfflineStatus => 'לא מחובר';

  @override
  String get friendsInviteButtonLabel => 'הזמן למשחק';

  @override
  String get friendsRemoveConfirmTitle => 'להסיר מהחברים?';

  @override
  String friendsRemoveConfirmBody(String name) {
    return '$name יוסר מרשימת החברים שלך, ואתה תוסר מהרשימה שלו. אפשר להתחבר שוב בעתיד עם קוד חדש.';
  }

  @override
  String get friendsRemoveButton => 'הסר';

  @override
  String friendsRemovedMessage(String name) {
    return '$name הוסר/ה מהחברים';
  }

  @override
  String get friendsLeaderboardTitle => 'מי מוביל בין החברים שלך';

  @override
  String friendsLeaderboardYouRow(String name) {
    return '$name (אתה)';
  }

  @override
  String get friendsInviteCardTitle => 'הזמנה למשחק';

  @override
  String friendsInviteCardBody(int bonus) {
    return 'שלח לחברים קישור להורדת האפליקציה - וואטסאפ, מסרונים או כל אפליקציה אחרת. שניכם תקבלו $bonus מטבעות אוטומטית כשהם יתקינו!';
  }

  @override
  String get friendsSendInviteButton => 'שלח הזמנה';

  @override
  String get friendsExplainerTitle => 'מסך החברים';

  @override
  String get friendsExplainerCodeTitle => 'קוד אישי לשיתוף';

  @override
  String get friendsExplainerCodeBody =>
      'שתפו את הקוד שלכם עם חברים כדי שיוכלו להוסיף אתכם.';

  @override
  String get friendsExplainerOnlineTitle => 'מי מחובר עכשיו';

  @override
  String get friendsExplainerOnlineBody =>
      'נקודה ירוקה ליד חבר מראה שהוא כרגע באפליקציה.';

  @override
  String get friendsExplainerInviteTitle => 'הזמנה למשחק';

  @override
  String get friendsExplainerInviteBody =>
      'לחצו על \"הזמן למשחק\" ליד כל חבר כדי להזמין אותו לדו-קרב ישיר.';

  @override
  String get leaderboardLoadErrorGeneric =>
      'לא הצלחנו לטעון את הטבלה. בדקו חיבור לאינטרנט ונסו שוב.';

  @override
  String leaderboardLoadErrorWithDetail(String error) {
    return 'לא הצלחנו לטעון את הטבלה.\n\nשגיאה טכנית (אבחון זמני):\n$error';
  }

  @override
  String get leaderboardExplainerTitle => 'הטבלה הארצית';

  @override
  String get leaderboardExplainerMedalsTitle => 'דירוג לפי מדליות';

  @override
  String get leaderboardExplainerMedalsBody =>
      'ברירת המחדל - דירוג הוגן לפי הישגים, לא רק כמות משחקים.';

  @override
  String get leaderboardExplainerPointsTitle => 'אפשר גם לפי נקודות';

  @override
  String get leaderboardExplainerPointsBody =>
      'מתג למעלה מחליף לדירוג לפי XP שנצבר.';

  @override
  String get leaderboardExplainerPositionTitle => 'המיקום שלכם תמיד גלוי';

  @override
  String get leaderboardExplainerPositionBody =>
      'גם אם אתם לא בעשירייה הראשונה - תג צף מראה איפה אתם.';

  @override
  String get leaderboardHeaderTitle => 'טבלה ארצית';

  @override
  String get leaderboardWeeklyLeagueChip => 'ליגה שבועית';

  @override
  String get leaderboardAchievementsChip => 'הישגים';

  @override
  String get leaderboardMedalsModeLabel => 'מדליות';

  @override
  String get leaderboardPointsModeLabel => 'נקודות';

  @override
  String get leaderboardEmptyMessage =>
      'עדיין אין ניקוד בטבלה.\nהיה הראשון לפתור לוגו!';

  @override
  String leaderboardTopByMedals(int count) {
    return '$count לפי מדליות';
  }

  @override
  String leaderboardTopOverall(int count) {
    return '$count המובילים';
  }

  @override
  String get leaderboardYourRankDivider => 'המקום שלך';

  @override
  String get leaderboardYourXpLabel => 'XP שלך';

  @override
  String get leaderboardStreakLabel => 'רצף';

  @override
  String leaderboardFloatingYouRow(String name) {
    return '$name  (אתה)';
  }

  @override
  String get leaderboardTapToScrollHint => 'הקש כדי לגלול למקום שלך';

  @override
  String get leagueScreenTitle => 'ליגה שבועית';

  @override
  String leagueRolloverSummaryTitle(int rank, int total) {
    return 'סיכום שבוע: מקום $rank מתוך $total';
  }

  @override
  String leaguePointsLastWeek(int points) {
    return '$points נקודות בשבוע שעבר.';
  }

  @override
  String leagueCoinsReceived(int coins) {
    return 'קיבלת $coins מטבעות.';
  }

  @override
  String leagueTierUp(String tier) {
    return 'עלית לליגת $tier!';
  }

  @override
  String leagueTierDown(String tier) {
    return 'ירדת לליגת $tier. חוזרים חזקים.';
  }

  @override
  String leagueTierSame(String tier) {
    return 'נשארת בליגת $tier.';
  }

  @override
  String get leagueGreatButton => 'מעולה';

  @override
  String get leagueEndsNow => 'מסתיים עכשיו';

  @override
  String leagueEndsInDaysHours(int days, int hours) {
    return 'נגמר בעוד $days ימים ו-$hours שעות';
  }

  @override
  String leagueEndsInHours(int hours) {
    return 'נגמר בעוד $hours שעות';
  }

  @override
  String leagueTierNameLabel(String tier) {
    return 'ליגת $tier';
  }

  @override
  String leagueMyRankPoints(int rank, int points) {
    return 'מקום $rank · $points נקודות';
  }

  @override
  String leaguePointsOnly(int points) {
    return '$points נקודות';
  }

  @override
  String get leagueExplanationBody =>
      'כל שבוע מתחילים מאפס ומתחרים מול שחקנים באותה ליגה. מקומות 1-3: 100 / 60 / 40 מטבעות, וגם עלייה ליגה. משחקים, פותרים לוגואים ומנצחים כדי לצבור נקודות.';

  @override
  String get leagueEmptyMessage =>
      'עדיין אף אחד לא צבר נקודות השבוע. תהיו הראשונים!';

  @override
  String get leaguePlayerFallbackName => 'שחקן';

  @override
  String get leaguePointsAbbrev => 'נק׳';

  @override
  String missionsLoadError(String error) {
    return 'שגיאה בטעינת המשימות: $error';
  }

  @override
  String missionsClaimedCoinsMessage(int amount) {
    return 'קיבלת +$amount מטבעות!';
  }

  @override
  String get missionsRerollUnavailable => 'אי אפשר להחליף את המשימה הזו כרגע';

  @override
  String missionsRerollSuccess(String title) {
    return 'המשימה הוחלפה: $title';
  }

  @override
  String get missionsScreenTitle => 'משימות';

  @override
  String get missionsUnknownError => 'שגיאה לא ידועה';

  @override
  String get missionsExplainerTitle => 'מסך המשימות';

  @override
  String get missionsExplainerDailyWeeklyTitle => 'משימות יומיות ושבועיות';

  @override
  String get missionsExplainerDailyWeeklyBody =>
      'כל משימה שמשלימים מזכה בפרס - מטבעות או נקודות XP.';

  @override
  String get missionsExplainerChallengeTitle => 'אתגר יומי';

  @override
  String get missionsExplainerChallengeBody =>
      'מופיע למעלה כל יום - הזדמנות חד-פעמית לפרס גדול יותר.';

  @override
  String get missionsExplainerResetTitle => 'מתאפסות אוטומטית';

  @override
  String get missionsExplainerResetBody =>
      'משימות חדשות מחכות בכל יום/שבוע - אין צורך לעשות כלום.';

  @override
  String get missionsWeeklyTab => 'שבועיות';

  @override
  String get missionsDailyTab => 'יומיות';

  @override
  String get missionsResetsNextWeek => 'מתאפס בתחילת השבוע הבא';

  @override
  String missionsResetsInHours(String time) {
    return 'מתאפס בעוד $time שעות';
  }

  @override
  String get missionsCompleteDailyChallengeTitle => 'השלם את האתגר היומי';

  @override
  String get missionsPremiumBadge => '⭐ פרימיום';

  @override
  String get missionsClaimedLabel => 'נאסף';

  @override
  String get missionsClaimButton => 'קבל פרס';

  @override
  String get missionsPremiumRequiredReady =>
      'הפרס מוכן - דורש לוגו פאס פרימיום לאיסוף';

  @override
  String get missionsPremiumRequired => 'דורש לוגו פאס פרימיום';

  @override
  String get missionsWatchAdRerollButton => 'פרסומת = החלף משימה';

  @override
  String get battlePassPurchaseUnavailable =>
      'הרכישה לא זמינה כרגע - נסה שוב עוד רגע';

  @override
  String get battlePassUpgradeDialogTitle => 'לשדרג לפרימיום?';

  @override
  String battlePassUpgradeDialogBody(String price) {
    return 'תקבל את כל פרסי הפרימיום של העונה, כולל אלה שכבר פתחת, במחיר $price.';
  }

  @override
  String battlePassUpgradeConfirmButton(String price) {
    return 'כן, לשדרג · $price';
  }

  @override
  String get battlePassUpsellTitle => 'לוגו פאס פרימיום';

  @override
  String battlePassUpsellBody(int tiers, int coins) {
    return 'פותח $tiers פרסים נוספים לאורך כל העונה - בערך $coins מטבעות';
  }

  @override
  String battlePassUpsellEnergySuffix(int energy) {
    return ' ו-$energy אנרגיה';
  }

  @override
  String battlePassUpsellBoostSuffix(int minutes) {
    return ' + בוסט רמזים חינם ל-$minutes דקות';
  }

  @override
  String get battlePassUpsellBodySuffix =>
      ' בסך הכול, בנוסף לכל מה שכבר מקבלים בנתיב החינמי.';

  @override
  String battlePassUpgradeNowButton(String price) {
    return 'שדרג עכשיו · $price';
  }

  @override
  String get battlePassMaybeLaterButton => 'אולי אחר כך';

  @override
  String get battlePassInfoDialogTitle => 'מה זה לוגו פאס?';

  @override
  String get battlePassInfoDialogBody =>
      'צובר נקודות ממשימות ומהאתגר היומי, ועולה דרגות לאורך העונה. כל דרגה פותחת פרס בנתיב החינמי, ומי שרוכש פרימיום מקבל פרס גדול יותר באותה דרגה. בתחילת כל חודש נפתחת עונה חדשה מ-0.';

  @override
  String get battlePassGotItButton => 'הבנתי';

  @override
  String get battlePassScreenTitle => 'לוגו פאס';

  @override
  String battlePassSeasonNumberLabel(int number) {
    return 'עונה $number';
  }

  @override
  String get battlePassSeasonEndsToday => 'העונה מסתיימת היום';

  @override
  String battlePassDaysLeft(int days) {
    return 'נותרו $days ימים';
  }

  @override
  String get battlePassLastTierLabel => 'הדרגה האחרונה!';

  @override
  String battlePassPointsToNextTier(int points) {
    return 'עוד $points ⭐';
  }

  @override
  String get battlePassTierLabel => 'דרגה';

  @override
  String battlePassPendingRewards(int count) {
    return '$count פרסים לאיסוף';
  }

  @override
  String get battlePassAllClaimed => 'הכל נאסף ✓';

  @override
  String get battlePassSeasonBadgeDecorative => '🏅 תג בסיום';

  @override
  String battlePassUpgradeCtaTitle(String price) {
    return 'שדרג לפרימיום · $price';
  }

  @override
  String battlePassUpgradeCtaSubtitleWithReached(int locked, int reached) {
    return 'פותח $locked פרסים · כולל $reached שכבר צברת';
  }

  @override
  String battlePassUpgradeCtaSubtitle(int locked) {
    return 'פותח $locked פרסים נוספים';
  }

  @override
  String get battlePassPremiumColumnLabel => 'פרימיום';

  @override
  String get battlePassClaimButton => 'אסוף';

  @override
  String get battlePassPopupPremiumPathLabel => 'נתיב פרימיום';

  @override
  String get battlePassPopupFreePathLabel => 'נתיב חינם';

  @override
  String battlePassPopupHeaderLabel(int tier) {
    return 'לוגו פאס · דרגה $tier';
  }

  @override
  String get battlePassPopupRewardClaimedTitle => 'פרס נאסף!';

  @override
  String battlePassPopupCoinsAmount(int coins) {
    return '$coins מטבעות';
  }

  @override
  String battlePassPopupEnergyAmount(int energy) {
    return '$energy אנרגיה';
  }

  @override
  String battlePassPopupPathTierLabel(String path, int tier) {
    return '$path · דרגה $tier';
  }

  @override
  String get battlePassPopupBackToPassButton => 'חזרה לפאס';

  @override
  String get battlePassPopupAllTiersUnlocked => 'כל הדרגות נפתחו!';

  @override
  String battlePassPopupProgressToTier(int tier) {
    return 'התקדמות לדרגה $tier';
  }

  @override
  String get battlePassPopupMaxStars => '⭐ מקסימום';

  @override
  String battlePassPopupPercentStars(int percent) {
    return '⭐ $percent%';
  }

  @override
  String get battlePassPopupPremiumTeaserTitle =>
      'עם פרימיום היית מקבל בדרגה הזו';

  @override
  String battlePassPopupPremiumMultiplier(String multiplier) {
    return ' · פי $multiplier ממה שקיבלת';
  }

  @override
  String battlePassPopupTierUnlockedTitle(int tier) {
    return 'דרגה $tier נפתחה';
  }

  @override
  String battlePassPopupClaimTierButton(int tier) {
    return 'אסוף את דרגה $tier';
  }

  @override
  String battlePassBoostPillLabel(int minutes) {
    return '$minutes דק\'';
  }

  @override
  String battlePassBoostRewardTitle(int minutes) {
    return '$minutes דקות רמזים חינם';
  }

  @override
  String get promoLogoPassBody =>
      '🎫 פותחים עוד ועוד פרסים לאורך כל העונה - אל תפספסו!';

  @override
  String get promoShopBody =>
      '🛍️ מטבעות, הסרת פרסומות ועוד - בואו תראו מה יש בחנות';

  @override
  String shopCouponRedeemedMessage(int coins) {
    return 'הקוד מומש! קיבלת $coins מטבעות';
  }

  @override
  String get shopCouponNotFound => 'קוד לא קיים - בדוק שהקלדת נכון';

  @override
  String get shopCouponInactive => 'הקוד הזה כבר לא פעיל';

  @override
  String get shopCouponUsedUp => 'הקוד הזה נוצל עד הסוף על ידי שחקנים אחרים';

  @override
  String get shopCouponAlreadyUsed => 'כבר מימשת את הקוד הזה בעבר';

  @override
  String shopCouponGenericError(String detail) {
    return 'שגיאה: $detail';
  }

  @override
  String get shopUnknownErrorDetail => 'לא ידועה';

  @override
  String get shopAdBonusResetSubtitle => 'חוזר שוב בעוד 3 שעות';

  @override
  String shopNextAdAvailableIn(String time) {
    return 'אפשר לצפות בפרסומת נוספת בעוד $time';
  }

  @override
  String shopCoinsAmountLabel(String amount) {
    return '$amount מטבעות';
  }

  @override
  String shopEnergyAmountLabel(String amount) {
    return '$amount אנרגיה';
  }

  @override
  String get shopFirstPurchaseBonusDesc => 'בונוס רכישה ראשונה - כפול!';

  @override
  String get shopCoinsPackDesc => 'חבילת מטבעות';

  @override
  String get shopCoinsPackBestValueDesc => 'חבילת מטבעות - הכי משתלם';

  @override
  String get shopEnergyPackDesc => 'חבילת אנרגיה';

  @override
  String get shopNoAdsMonthlyName => 'ללא פרסומות - חודשי';

  @override
  String get shopMonthlySubscriptionDesc => 'מנוי חודשי';

  @override
  String get shopNoAdsLifetimeName => 'ללא פרסומות - לתמיד';

  @override
  String get shopOneTimePurchaseDesc => 'רכישה חד-פעמית';

  @override
  String get shopAllAdsRemovedLabel => 'הוסרו כל הפרסומות';

  @override
  String get shopCoinsLabel => 'מטבעות';

  @override
  String get shopEnergyLabel => 'אנרגיה';

  @override
  String shopDoubleBonusValue(int amount) {
    return '+$amount 🎁';
  }

  @override
  String get shopCannotOpenLinkError => 'לא ניתן לפתוח את הקישור כרגע';

  @override
  String get shopPurchaseUnavailable =>
      'הרכישה אינה זמינה כרגע, נסה שוב מאוחר יותר';

  @override
  String get shopStarterPackWaitingTitle => 'מארז פתיחה ממתין לך!';

  @override
  String shopStarterPackEnergySuffix(int energy) {
    return ' + $energy אנרגיה';
  }

  @override
  String shopStarterPackTimeLeft(String time) {
    return 'נשארו $time - ל-3 שעות בלבד';
  }

  @override
  String get shopScreenTitle => 'חנות';

  @override
  String get shopQuickActionsSection => 'פעולות מהירות';

  @override
  String get shopCouponHint => 'הקלד קוד קופון';

  @override
  String get shopRedeemButton => 'מימוש';

  @override
  String get shopWatchAdGet15CoinsTitle => 'צפה בפרסומת - קבל 15 מטבעות';

  @override
  String get shopAdBonusAvailableSubtitle => 'זמין שוב כל 3 שעות - מטבעות חינם';

  @override
  String get shopNextBonusAvailableInLabel => 'הבונוס הבא זמין בעוד: ';

  @override
  String shopWatchAdGetEnergyTitle(int amount) {
    return 'צפה בפרסומת - קבל $amount אנרגיה';
  }

  @override
  String get shopEnergyAdUnlimitedSubtitle =>
      'אין הגבלת פעמים - זמין תמיד כשהאנרגיה לא מלאה';

  @override
  String get shopBoostSectionTitle => 'בוסטים';

  @override
  String get shopBoostHintsTitle => '15 דקות רמזים חינם';

  @override
  String get shopBoostHintsSubtitle =>
      'עד 2 רמזי-אות חינם בכל חידה - בלי מטבעות ובלי לפגוע בפרס';

  @override
  String get shopBoostDoubleTitle => '15 דקות נקודות כפולות';

  @override
  String get shopBoostDoubleSubtitle => 'כל ה-XP שתרוויחו בפתרון שלבים יוכפל';

  @override
  String shopBoostActiveLabel(String time) {
    return 'פעיל - נותרו $time';
  }

  @override
  String get shopBoostAlreadyActiveToast => 'כבר יש לך בוסט פעיל כרגע';

  @override
  String get shopBoostNotEnoughCoinsToast => 'אין לך מספיק מטבעות לבוסט הזה';

  @override
  String get shopBoostHintsActivatedToast => '🔥 רמזים חינם הופעלו ל-15 דקות!';

  @override
  String get shopBoostDoubleActivatedToast =>
      '⚡ נקודות כפולות הופעלו ל-15 דקות!';

  @override
  String shopBoostFreeTrialToast(int minutes) {
    return '🎁 מתנה! רמזים חינם ל-$minutes דקות - נסו עכשיו';
  }

  @override
  String get shopCoinsSectionTitle => 'חנות המטבעות';

  @override
  String get shopLegendPackTitle => 'חבילת אגדה';

  @override
  String get shopGoldPackTitle => 'חבילת זהב';

  @override
  String get shopFirstPurchaseDoubleBadge => 'פעם ראשונה = כפול!';

  @override
  String get shopBeginnerPackTitle => 'חבילת מתחילים';

  @override
  String get shopKingsPackTitle => 'חבילת מלכים';

  @override
  String get shopVipPackTitle => 'חבילת VIP';

  @override
  String get shopMostPopularBadge => 'הכי פופולרי';

  @override
  String get shopEnergySectionTitle => 'חנות האנרגיה';

  @override
  String get shopEnergySmallTitle => 'מטען קטן';

  @override
  String get shopEnergyMediumTitle => 'מטען בינוני';

  @override
  String get shopEnergyLargeTitle => 'מטען גדול';

  @override
  String get shopEnergyHugeTitle => 'מטען ענק';

  @override
  String get shopNoAdsSectionTitle => 'ללא פרסומות';

  @override
  String get shopNoAdsActiveMessage =>
      'מצב ללא פרסומות פעיל! תודה על התמיכה 💜';

  @override
  String get shopMonthlySubTitle => 'מנוי חודשי';

  @override
  String get shopMonthlySubSubtitle => 'בלי פרסומות בין שלבים, מתחדש כל חודש';

  @override
  String get shopLifetimeTitle => 'לכל החיים';

  @override
  String get shopLifetimeSubtitle => 'תשלום אחד - בלי פרסומות לתמיד';

  @override
  String get shopBestValueBadge => 'הכי משתלם';

  @override
  String get shopPrivacyPolicyLink => 'מדיניות פרטיות';

  @override
  String get shopCheckingPurchasesMessage => 'בודק רכישות קודמות...';

  @override
  String get shopRestorePurchasesButton => 'שחזור רכישות';

  @override
  String get shopRecommendedForYouBadge => 'מומלץ לך';

  @override
  String get shopTournamentBonusBannerTitle =>
      'מבצע אלוף! +25% מטבעות בחבילות הגדולות';

  @override
  String shopTournamentBonusTimeLeft(String time) {
    return 'נשארו $time למבצע האלוף';
  }

  @override
  String get shopTournamentBonusTileNote => 'בונוס אלוף: +25% מטבעות';

  @override
  String get shopTournamentBonusBadge => 'בונוס אלוף +25%';

  @override
  String shopTournamentBonusValue(int amount) {
    return '+$amount - בונוס אלוף!';
  }

  @override
  String get shopTournamentBonusDesc => 'בונוס אלוף - 25% יותר מטבעות!';

  @override
  String get rewardPopupEnergyDefaultSubtitle => 'מספיק לשני דו־קרבים נוספים';

  @override
  String get rewardPopupGotLabel => 'קיבלת';

  @override
  String get rewardPopupYourEnergyLabel => 'האנרגיה שלך';

  @override
  String get rewardPopupToDuelButton => 'יאללה, לדו־קרב ⚔';

  @override
  String get rewardPopupContinueLink => 'המשך';

  @override
  String get rewardPopupYourCoinsLabel => 'המטבעות שלך';

  @override
  String get rewardPopupToShopLink => 'לחנות';

  @override
  String get rewardPopupPurchaseCompleteTitle => 'הרכישה הושלמה!';

  @override
  String get rewardPopupItemsInAccountSubtitle => 'הפריטים כבר בחשבון שלך';

  @override
  String get rewardPopupAddedToAccountLabel => 'נוסף לחשבון';

  @override
  String get rewardPopupBackToGameButton => 'מעולה, בחזרה למשחק';

  @override
  String get reviewPromptTitle => 'נהנים מהמשחק?';

  @override
  String get reviewPromptBody =>
      'דירוג 5 כוכבים ⭐ עוזר לנו המון ולוקח רק כמה שניות';

  @override
  String get reviewPromptRateButton => 'דרגו אותנו 5 כוכבים';

  @override
  String get reviewPromptMaybeLaterButton => 'אולי מאוחר יותר';

  @override
  String get presenceAdminModeDuel => 'דו-קרב';

  @override
  String get presenceAdminModeSuperDuel => 'סדרת דו-קרב';

  @override
  String get presenceAdminModeRace => 'מירוץ';

  @override
  String get presenceAdminTitle => 'מעקב שחקנים אונליין';

  @override
  String get presenceAdminTotalLabel => 'סה״כ';

  @override
  String get presenceAdminSeriesLabel => 'סדרה';

  @override
  String presenceAdminLastRefreshLabel(int seconds) {
    return 'עודכן לפני $seconds שניות · מתרענן אוטומטית כל 10 שניות';
  }

  @override
  String get presenceAdminEmptyMessage =>
      'אף אחד לא מחובר כרגע (או שאין רשת) ⚠️ שים לב: שחקנים שכבר בתוך משחק דו-קרב פעיל (לא בלובי) לא נספרים - מגבלה ידועה, ראו הערה ב-presence_service.dart';

  @override
  String presenceAdminSecondsAgo(int seconds) {
    return 'לפני ${seconds}s';
  }

  @override
  String get previewUsername => 'אופק123';

  @override
  String get previewMedalsCount => '0 / 15 מדליות';

  @override
  String get previewContinueBannerLabel => 'ממשיכים מאיפה שעצרת';

  @override
  String previewStageLabel(int n) {
    return 'שלב $n';
  }

  @override
  String get previewCompletedLabel => 'הושלם';

  @override
  String get previewContinuePlayingButton => 'המשך לשחק';

  @override
  String get previewDailyChallengeTitle => 'אתגר יומי';

  @override
  String get previewDailyChallengeSubtitle => '6 לוגואים · פרס מיוחד';

  @override
  String get previewConnectedCount => '8 מחוברים';

  @override
  String get previewRandomChallengeSubtitle => 'לוגו אקראי · שומר על הרצף';

  @override
  String get updateNotesLoadError =>
      'לא הצלחנו לטעון את העדכונים - נסה שוב מאוחר יותר';

  @override
  String get updateNotesTitle => 'מה חדש במשחק';

  @override
  String get updateNotesEmptyMessage =>
      'אין עדיין הערות עדכון - חזרו לבדוק בקרוב';

  @override
  String get updateRequiredTitle => 'יש גרסה חדשה';

  @override
  String get updateRequiredUpdateNowButton => 'עדכן עכשיו';

  @override
  String updateRequiredVersionInfo(String current, String min) {
    return 'גרסה $current · נדרשת $min';
  }

  @override
  String get whatsNewDuelSeriesTitle => 'סדרת דו-קרב';

  @override
  String get whatsNewDuelSeriesSubtitle =>
      'דו-קרב חדש: הטוב מ-3! אותו יריב, עד 3 סיבובים, ובונוס מטבעות שמן לניצחון בסדרה';

  @override
  String get whatsNewNewLevelsTitle => 'נוספו רמות חדשות';

  @override
  String get whatsNewNewLevelsSubtitle =>
      'עוד שלבים ועוד לוגואים לזהות, מחכים לכם במסך השלבים';

  @override
  String get whatsNewDifficultyTitle => 'רמות קושי 1-5';

  @override
  String get whatsNewDifficultySubtitle =>
      'כל עולם מקבל דירוג קושי — וככל שההימור בדו-קרב גבוה יותר, כך גם רמת הלוגואים';

  @override
  String get whatsNewReferralBonusTitle => 'בונוס הזמנת חברים גדול יותר';

  @override
  String get whatsNewReferralBonusSubtitle =>
      'עכשיו מקבלים 75 מטבעות (במקום 30) על כל חבר שמצטרף דרך הקוד שלכם';

  @override
  String whatsNewVersionBadge(String version) {
    return '✨ גרסה $version';
  }

  @override
  String get whatsNewHeaderTitle => 'עדכנו בשבילכם!';

  @override
  String whatsNewHeaderSubtitle(String version) {
    return 'מה חדש בגרסה $version?';
  }

  @override
  String get whatsNewNewBadge => 'חדש';

  @override
  String get whatsNewGetStartedButton => 'בואו נתחיל';

  @override
  String get settingsWhatsNewLink => 'מה חדש';

  @override
  String get settingsReportIssueLink => 'דיווח על תקלה';

  @override
  String get settingsPrivacyLink => 'פרטיות';

  @override
  String get settingsRateUsLink => 'דרגו אותנו';

  @override
  String get settingsDeleteUserLink => 'מחיקת משתמש';

  @override
  String settingsVersionLabel(String version) {
    return 'גרסה $version';
  }

  @override
  String get settingsScreenTitle => 'הגדרות';

  @override
  String get settingsChangeNameButton => 'שנה שם';

  @override
  String get settingsLogosStatLabel => 'לוגואים';

  @override
  String get settingsWinsStatLabel => 'ניצחונות';

  @override
  String get settingsVibrationLabel => 'רטט';

  @override
  String get settingsNotificationsLabel => 'התראות';

  @override
  String get settingsInviteFriendsLabel => 'הזמינו חברים';

  @override
  String get settingsHowToPlayLabel => 'איך משחקים?';

  @override
  String get settingsHowToPlayBody =>
      'בכל שלב יופיע לוגו מטושטש או חתוך. עליכם להקליד את השם המדויק באמצעות המקלדת למטה.\n\n🗺️ רמות ושלבים: מתקדמים לפי קטגוריות - כל פתרון פותח את השלב הבא. פתרון מוצלח מזכה ב-10 XP ו-2 מטבעות (כל רמז אות מוריד 1 XP, ופתרון המילה ברמז נותן 5 XP בלבד).\n\n🎲 אתגר רנדומלי: לוגו אקראי מכל הקטגוריות, בלי חזרות! כל פתרון נכון מגדיל את הרצף 🔥 ומוסיף בונוס XP (עד +5). הרצף נשמר גם כשיוצאים - ומתאפס רק אם טועים במילה.\n\n⚔️ דו-קרב 1 על 1: שני שחקנים מקבלים את אותם הלוגואים, הראשון שמסיים - מנצח. עולה אנרגיה (מתחדשת עם הזמן).\n\n💡 רמזים: חשיפת אות - 15 מטבעות, פתרון המילה - 60 מטבעות. נגמרו המטבעות? אפשר לצפות בפרסומת ולקבל רמז חינם!';

  @override
  String get settingsLinkAccountLabel => 'חיבור חשבון';

  @override
  String get settingsLinkAccountSub => 'שומר את ההתקדמות שלך גם אם תחליף מכשיר';

  @override
  String settingsLinkedAccountLabel(String names) {
    return 'מחובר - $names';
  }

  @override
  String get settingsSignOutConfirmTitle => 'להתנתק מהחשבון?';

  @override
  String get settingsSignOutConfirmBody =>
      'ההתקדמות הנוכחית שלך תישאר במכשיר הזה כרגיל. תוכל להתחבר שוב לאותו חשבון בכל עת.';

  @override
  String get settingsSignOutButton => 'התנתק';

  @override
  String get settingsSignedOutMessage => 'התנתקת מהחשבון';

  @override
  String get settingsDeleteAccountConfirmTitle => 'למחוק את המשתמש?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'כל ההתקדמות שלך (מטבעות, XP, שלבים, רצפים) תימחק לצמיתות ולא ניתן יהיה לשחזר אותה. הפעולה סופית.';

  @override
  String get settingsDeletePermanentlyButton => 'מחק לצמיתות';

  @override
  String get settingsAccountDeletedMessage =>
      'המשתמש נמחק. סגור ופתח מחדש את האפליקציה כדי להתחיל מחדש.';

  @override
  String get settingsDeleteFailedMessage => 'המחיקה נכשלה, נסה שוב מאוחר יותר';

  @override
  String get settingsSupportEmailSubject => 'דיווח תקלה - זהה את הלוגו!';

  @override
  String settingsSupportEmailBody(String username) {
    return 'היי!\n\nתיאור התקלה:\n\n\nמה עשיתי כשזה קרה:\n\n\n---\nהשם שלי במשחק: $username';
  }

  @override
  String settingsNoMailAppMessage(String email) {
    return 'לא נמצאה אפליקציית מייל. אפשר לכתוב לנו ידנית ל-$email';
  }

  @override
  String get settingsChangeNameDialogTitle => 'שינוי שם';

  @override
  String get settingsSaveButton => 'שמור';

  @override
  String get settingsTabGame => 'משחק';

  @override
  String get settingsTabSound => 'צליל';

  @override
  String get settingsTabAccount => 'חשבון';

  @override
  String get settingsTabHelp => 'עזרה';

  @override
  String get settingsTabHintGame => 'איך המשחק מרגיש לכם';

  @override
  String get settingsTabHintSound => 'מוזיקה, אפקטים ורטט';

  @override
  String get settingsTabHintNotifications => 'על מה נעדכן אתכם';

  @override
  String get settingsTabHintAccount => 'פרטיות, רכישות וחיבור';

  @override
  String get settingsTabHintHelp => 'תמיכה ועוד';

  @override
  String get settingsGameLanguageLabel => 'שפת המשחק';

  @override
  String get settingsMusicLabel => 'מוזיקה';

  @override
  String get settingsEffectsLabel => 'אפקטים';

  @override
  String get settingsHintConfirmLabel => 'אישור לפני קניית רמז';

  @override
  String get settingsHintConfirmSub => 'שלא תבזבזו מטבעות בטעות';

  @override
  String get settingsLevelTimerLabel => 'הצגת טיימר בשלבים';

  @override
  String get settingsAutoAdvanceLabel => 'מעבר אוטומטי ללוגו הבא';

  @override
  String get settingsAutoAdvanceSub => 'אפשר להמשיך גם ידנית בכל רגע';

  @override
  String get settingsVibrationSub => 'בתשובה נכונה ושגויה';

  @override
  String get settingsNotifAllLabel => 'כל ההתראות';

  @override
  String get settingsNotifTournamentLabel => 'עדכוני טורניר';

  @override
  String get settingsNotifDailyLabel => 'תזכורות יומיות';

  @override
  String get settingsNotifEnergyLabel => 'האנרגיה התמלאה';

  @override
  String get settingsMyAchievementsLabel => 'ההישגים שלי';

  @override
  String get settingsRankBeginner => 'מתחיל';

  @override
  String get settingsRankIntermediate => 'מתקדם';

  @override
  String get settingsRankVeteran => 'ותיק';

  @override
  String get settingsRankChampion => 'אלוף';

  @override
  String get settingsInviteCodeLabel => 'הקוד שלכם:';

  @override
  String get settingsFollowUsLabel => 'עקבו אחרינו';

  @override
  String settingsFollowRewardLabel(int coins) {
    return '+$coins על כל אחד';
  }

  @override
  String get settingsRemoveAdsLabel => 'הסרת פרסומות';

  @override
  String get settingsRemoveAdsOwnedLabel => 'פעיל';

  @override
  String get settingsContactUsLabel => 'צור קשר';

  @override
  String get settingsGeneralContactSubject => 'פנייה כללית - זהה את הלוגו!';

  @override
  String settingsGeneralContactBody(String username) {
    return 'היי!\n\n\n---\nהשם שלי במשחק: $username';
  }

  @override
  String get mainMenuTourPlayButtonTitle => 'כאן מתחילים לשחק';

  @override
  String get mainMenuTourPlayButtonBody =>
      'לחצו על כפתור \"שחק\" כדי לראות את כל המודים - שלבים, תפזורת, רנדומלי, אתגר יומי ומשחק מול אחרים בזמן אמת.';

  @override
  String get mainMenuTourLevelsCardTitle => 'עכשיו תתחילו לשחק';

  @override
  String get mainMenuTourLevelsCardBody =>
      'לחצו על \"שלבים\" כדי לבחור עולם ולפתור את הלוגו הראשון שלכם!';

  @override
  String get mainMenuTournamentHeroLiveBadge => 'טורניר יומי · עכשיו';

  @override
  String get mainMenuTournamentHeroPotLabel => 'הקופה';

  @override
  String mainMenuTournamentHeroParticipants(int count) {
    return '$count משתתפים';
  }

  @override
  String mainMenuTournamentHeroJoinButton(int fee) {
    return 'הצטרפו ב־$fee 🪙';
  }

  @override
  String get mainMenuDailyChallengeMiniTitle => 'אתגר יומי';

  @override
  String get mainMenuFriendsMiniTitle => 'מחוברים';

  @override
  String get mainMenuTopPerformersTitle => 'המובילים היום';

  @override
  String get mainMenuTopPerformersEmpty =>
      'אף אחד עדיין לא שיחק בטורניר היום - תהיו הראשונים!';

  @override
  String get mainMenuModesSheetTitle => 'איך משחקים היום?';

  @override
  String get mainMenuModesSheetSoloSection => 'לבד';

  @override
  String get mainMenuModesTafzoretTitle => 'תפזורת';

  @override
  String mainMenuModesTafzoretNote(int count) {
    return '$count עולמות';
  }

  @override
  String get mainMenuModesLevelsTitle => 'שלבים';

  @override
  String mainMenuModesLevelsNote(int level) {
    return 'רמה $level';
  }

  @override
  String get mainMenuBottomNavTournaments => 'טורנירים';

  @override
  String get mainMenuTournamentChooserTitle => 'בחרו טורניר';

  @override
  String get mainMenuTournamentChooserDailyTitle => 'אתגר 3 הימים';

  @override
  String mainMenuTournamentChooserDailySubtitle(int fee) {
    return 'הצטרפו ב-$fee מטבעות לאירוע של 3 ימים · הקופה מתחילה כבר ב-100';
  }

  @override
  String get mainMenuTournamentChooserScheduledTitle => 'טורניר מתוזמן';

  @override
  String mainMenuTournamentChooserScheduledSubtitle(int fee, int count) {
    return 'כל יום ב-20:00 · הצטרפו ב-$fee מטבעות · $count לוגואים';
  }

  @override
  String get mainMenuStoriesInviteLabel => 'הזמנה';

  @override
  String get mainMenuFriendOnlineStatus => 'מחובר';

  @override
  String get mainMenuFriendOfflineStatus => 'לא מחובר';

  @override
  String get mainMenuHappeningNowTitle => 'קורה עכשיו';

  @override
  String mainMenuTournamentRowSubtitle(int pot, int count) {
    return 'קופה $pot מטבעות · $count משתתפים';
  }

  @override
  String get mainMenuEventRowTimeLeftLabel => 'נשאר';

  @override
  String get mainMenuShopBonusTitle => 'בונוס ניצחון בטורניר';

  @override
  String get mainMenuShopBonusSubtitle => 'פי 1.25 מטבעות בכל רכישה בחנות';

  @override
  String get mainMenuContinueButton => 'המשך';

  @override
  String get mainMenuTodayRankingTitle => 'הדירוג שלך היום';

  @override
  String get mainMenuTodayRankingYouLabel => 'אתה';

  @override
  String mainMenuTodayRankingAheadMessage(int xp, String name) {
    return '▲ עוד $xp XP ואתה עוקף את $name';
  }

  @override
  String get mainMenuTodayRankingEmpty => 'שחקו כדי להופיע בטבלת הדירוג!';

  @override
  String get mainMenuNoFriendsTitle => 'עדיין אין לך חברים';

  @override
  String get mainMenuNoFriendsSubtitle => 'הזמינו חברים ותתחרו ביחד!';

  @override
  String get mainMenuShopQuickLinkSubtitle => 'מטבעות, אנרגיה ועוד';

  @override
  String get mainMenuHomeTitle => 'זהה את הלוגו';

  @override
  String get mainMenuHomeTagline => 'כמה לוגואים אתם מכירים?';

  @override
  String get mainMenuModesSheetTitleShort => 'בחרו מוד';

  @override
  String get mainMenuModesSheetSubtitle => 'בחרו מוד ויוצאים לדרך';

  @override
  String mainMenuTournamentTileSubtitlePrefix(int pot) {
    return 'קופה $pot ·';
  }

  @override
  String get mainMenuShopTileBonusActive => 'בונוס פעיל!';

  @override
  String mainMenuLevelProgressTitle(int world, int sub) {
    return 'רמה $world · שלב $sub';
  }

  @override
  String get mainMenuLevelProgressSubtitle => 'כל לוגו מקרב אתכם לעולם הבא';

  @override
  String mainMenuStreakBadge(int days) {
    return '🔥 $days';
  }
}
