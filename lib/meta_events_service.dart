// meta_events_service.dart
//
// 🆕 מעקב פרסומות Meta (פייסבוק/אינסטגרם) - כדי שקמפיינים ב-Meta Ads
// Manager יוכלו למדוד המרות אמיתיות (התקנה → הרשמה → רכישה), לא רק
// קליקים, ולבצע אופטימיזציה אוטומטית של הקמפיין לפי זה (Meta מראה את
// הפרסומת ליותר אנשים "דומים" למי שבאמת שילם, לא רק למי שהתקין).
//
// ⚠️ דורש הוספה ל-pubspec.yaml:
//   dependencies:
//     facebook_app_events: ^0.19.2   (או הגרסה העדכנית ביותר)
//
// ⚠️ בנוסף, ובניגוד לרוב הקבצים האחרים ששלחתי - זה דורש גם הגדרה
// חד-פעמית *מחוץ לקוד* שאני לא יכול לבצע מכאן (בדיוק כמו ה-APNs Key
// שהוסבר בעבר עבור Push ל-iOS). בלי השלבים האלה, כל הקריאות כאן פשוט
// לא יעשו כלום בפועל (הכל עטוף ב-try/catch כדי שזה לא יקריס את המשחק):
//
//   1. ליצור אפליקציה ב-Meta for Developers (developers.facebook.com/apps)
//      ולקבל משם App ID + Client Token.
//
//   2. Android (android/app/src/main/AndroidManifest.xml), בתוך התג
//      <application> הקיים:
//        <meta-data android:name="com.facebook.sdk.ApplicationId"
//                    android:value="@string/facebook_app_id"/>
//        <meta-data android:name="com.facebook.sdk.ClientToken"
//                    android:value="@string/facebook_client_token"/>
//      וליצור קובץ android/app/src/main/res/values/facebook.xml חדש:
//        <?xml version="1.0" encoding="utf-8"?>
//        <resources>
//            <string name="facebook_app_id">ה-App ID שקיבלת</string>
//            <string name="facebook_client_token">ה-Client Token שקיבלת</string>
//        </resources>
//
//   3. iOS (ios/Runner/Info.plist):
//        <key>FacebookAppID</key><string>ה-App ID שקיבלת</string>
//        <key>FacebookClientToken</key><string>ה-Client Token שקיבלת</string>
//        <key>FacebookDisplayName</key><string>זהה את הלוגו!</string>
//      וגם CFBundleURLTypes עם fbהמזהה-שלך, ו-LSApplicationQueriesSchemes
//      עם fbapi/fbauth2/fbshareextension - הפרטים המדויקים משתנים בין
//      גרסאות ה-package, ראו את התיעוד הרשמי של facebook_app_events
//      ב-pub.dev בזמן שתתקין אותו.
//
//   4. באייפון, בגלל ATT (ראו main.dart - _requestTrackingIfNeeded),
//      Meta לא תוכל לייחס רכישות למשתמש ספציפי בלי אישור המשתמש למעקב -
//      זה כבר מטופל אוטומטית כי אותה בקשת הרשאה כבר קיימת ומשותפת
//      לכל מערכות המעקב (גם AdMob וגם Meta).

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class MetaEventsService {
  MetaEventsService._();

  static final FacebookAppEvents _events = FacebookAppEvents();
  static bool _initialized = false;

  /// לקרוא פעם אחת ב-main.dart (אחרי Firebase.initializeApp(), לא לפני -
  /// אין תלות ישירה, אבל זה השומר על סדר עקבי עם שאר האתחולים). מדליק
  /// את המעקב האוטומטי הבסיסי (פתיחת אפליקציה, פתיחה ראשונה) - זה כבר
  /// מספיק כדי שקמפיין Meta ימדוד "התקנות" בפועל, גם בלי שום אירוע
  /// מותאם נוסף למטה.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _events.setAutoLogAppEventsEnabled(true);
      // מאפשר ל-Meta לשייך את האירועים למשתמש ספציפי (לצורך אופטימיזציה
      // של הקמפיין) - כפוף עדיין להסכמת ATT באייפון, ראו הערה 4 למעלה.
      // 🩹 תוקן: setAdvertiserTracking הוחלף (deprecated) ב-facebook_app_events -
      // setAdvertiserIdCollectionEnabled הוא התחליף הרשמי (לפי הצעת ה-analyzer
      // עצמו). התנהגות זהה מבחינתנו - עדיין כפוף להסכמת ATT באייפון.
      await _events.setAdvertiserIdCollectionEnabled(true);
    } catch (e) {
      debugPrint('שגיאת אתחול Meta Events: $e');
    }
  }

  /// אירוע רכישה - הכי חשוב לאופטימיזציה של הקמפיין: Meta לומדת מזה
  /// אילו משתמשים משלמים ובאיזה סכום, ומראה את הפרסומת ליותר אנשים
  /// "דומים" להם. לקרוא מיד אחרי כל רכישה מוצלחת (ראו iap_manager.dart).
  static Future<void> logPurchase({
    required double amount,
    required String currency,
    required String productId,
  }) async {
    try {
      await _events.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {'product_id': productId},
      );
    } catch (e) {
      debugPrint('שגיאת Meta logPurchase: $e');
    }
  }

  /// אירוע "השלמת הרשמה" - נקרא פעם אחת כשמשתמש חדש שומר שם לראשונה
  /// (מסך "ברוכים הבאים"). איתות מוקדם וחשוב ל-Meta שהמשתמש הזה "נכנס
  /// למשחק בפועל" ולא רק פתח והלך - עוזר לקמפיין לאתר משתמשי איכות.
  static Future<void> logCompletedRegistration() async {
    try {
      await _events.logEvent(name: 'fb_mobile_complete_registration');
    } catch (e) {
      debugPrint('שגיאת Meta logCompletedRegistration: $e');
    }
  }

  /// אירוע מותאם כללי - לכל מדד נוסף שתרצה למדוד בעתיד (למשל דו-קרב
  /// ראשון, הגעה לרמה מסוימת, וכו') בלי צורך להוסיף עוד פונקציה ייעודית.
  static Future<void> logCustomEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _events.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('שגיאת Meta logCustomEvent($name): $e');
    }
  }
}