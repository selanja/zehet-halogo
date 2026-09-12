// screenshot_protection.dart
//
// הגנה על צילומי מסך והקלטות. מבוסס על החבילה screen_protector
// (flutter pub add screen_protector) - החבילה היחידה שתומכת גם באנדרואיד
// וגם באייפון, כל אחד ברמת ההגנה המקסימלית שהמערכת שלו בכלל מאפשרת:
//
//  אנדרואיד: חסימה אמיתית (FLAG_SECURE) - צילום מסך/הקלטה יוצאים שחורים
//             לגמרי, וגם התצוגה המקדימה ב"אפליקציות פתוחות" תהיה ריקה.
//  iOS:       אי אפשר לחסום צילום מסך בפועל (מגבלת אפל, לא של הקוד שלנו) -
//             אבל מטשטשים את המסך אוטומטית כשיש הקלטת מסך פעילה או
//             כשעוברים בין אפליקציות (App Switcher), כדי למנוע לפחות
//             הצצה שם. בלי שום הודעה/callback - רק טשטוש שקט.
//
// שימוש מומלץ: קוראים ל-ScreenshotProtection.enable() פעם אחת ב-main.dart
// (ברמת האפליקציה כולה) - כי כמעט כל מסך במשחק מציג לוגואים בסופו של
// דבר. אם רוצים לאפשר צילומי מסך במסכים ספציפיים (למשל מסך ההגדרות
// או החנות) - קוראים ל-disable() ב-initState של אותו מסך ו-enable()
// שוב ב-dispose שלו כדי לחזור להגנה כשחוזרים למשחק.

import 'package:screen_protector/screen_protector.dart';

class ScreenshotProtection {
  ScreenshotProtection._();

  /// מפעיל את ההגנה - קוראים לזה פעם אחת בהתחלת האפליקציה
  static Future<void> enable() async {
    // אנדרואיד: חוסם צילום מסך/הקלטה לגמרי (FLAG_SECURE)
    // iOS: לא חוסם (לא ניתן), זו קריאה תמימה שלא עושה כלום שם
    await ScreenProtector.preventScreenshotOn();

    // iOS בלבד: מטשטש את המסך אוטומטית כשהאפליקציה עוברת לרקע (App
    // Switcher) וגם כשיש הקלטת מסך פעילה - מונע הצצה גם בלי אפשרות
    // לחסום צילום ישיר
    await ScreenProtector.protectDataLeakageOn();
  }

  /// מבטל את ההגנה - שימושי במסכים שבהם כן רוצים לאפשר צילום מסך
  /// (למשל מסך הישגים "תשתפו את הניצחון שלכם" עם כפתור שיתוף)
  static Future<void> disable() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
  }
}