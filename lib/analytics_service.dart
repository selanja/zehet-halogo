// analytics_service.dart
//
// 📊 Firebase Analytics - בעיקר בשביל Google Ads (UAC/App campaigns):
// בלי זה, קמפיין Google Ads "עיוור" לאיכות המשתמשים שהוא מביא - הוא
// יכול לייעל את עצמו רק לפי מספר ההתקנות, לא לפי מי שבאמת נרשם/שילם.
// עם Firebase Analytics מקושר לחשבון Google Ads (נעשה מחוץ לקוד, בקונסולת
// Firebase -> Integrations -> Google Ads), הקמפיין לומד להביא יותר
// משתמשים "דומים" למי שבאמת משלם - בדיוק כמו MetaEventsService שכבר
// עושה את זה בשביל Meta Ads.
//
// ⚠️ בניגוד ל-Meta, אין כאן שום הגדרה חיצונית נדרשת - firebase_core כבר
// מאותחל (GoogleService-Info.plist/google-services.json כבר קיימים),
// אז Firebase Analytics עובד "מהקופסה" ברגע שהחבילה מותקנת. איסוף
// אוטומטי (פתיחות אפליקציה וכו') כבר פעיל לבד - האירועים כאן הם רק
// תוספת למדדים החשובים ביותר (רכישה/הרשמה), בדיוק כמו ב-Meta.
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// אירוע רכישה - הכי חשוב לאופטימיזציה של קמפיין Google Ads. לקרוא
  /// מיד אחרי כל רכישה מוצלחת (ראו iap_manager.dart, לצד MetaEventsService.logPurchase).
  static Future<void> logPurchase({
    required double amount,
    required String currency,
    required String productId,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: amount,
        parameters: {'product_id': productId},
      );
    } catch (e) {
      debugPrint('שגיאת Analytics logPurchase: $e');
    }
  }

  /// אירוע "השלמת הרשמה" - נקרא פעם אחת כשמשתמש חדש שומר שם לראשונה
  /// (בדיוק כמו MetaEventsService.logCompletedRegistration).
  static Future<void> logCompletedRegistration() async {
    try {
      await _analytics.logSignUp(signUpMethod: 'username');
    } catch (e) {
      debugPrint('שגיאת Analytics logCompletedRegistration: $e');
    }
  }
}
