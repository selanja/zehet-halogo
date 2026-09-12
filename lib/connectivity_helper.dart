// connectivity_helper.dart
// בדיקת חיבור אינטרנט אמיתי - לא רק "מחובר לרשת WiFi" אלא שיש בפועל
// גישה לאינטרנט. משתמש ב-dart:io שכבר קיים בפלוטר, בלי חבילה נוספת.
import 'dart:io';

class ConnectivityHelper {
  /// מחזיר true אם יש גישה אמיתית לאינטרנט (טיים-אאוט 5 שניות)
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
