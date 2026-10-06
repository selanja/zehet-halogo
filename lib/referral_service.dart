// referral_service.dart
//
// 🆕 "מביאים חבר חדש למשחק - לא קשור לחברים באפליקציה, קישור עם קוד
// בתוכו, וברגע שהוא מתקין ופותח את האפליקציה שניכם מקבלים מטבעות
// אוטומטית" - בלי בקשת חברות, בלי אישור, בלי שום קשר ל-friendsList.
//
// איך זה עובד בפועל:
//  - האנדרואיד: קישור לדף נחיתה שלנו (zehe-et-halogo.web.app/i/CODE) מפנה
//    מיידית ל-Google Play עם &referrer=ref%3DCODE. Google Play שומר את זה
//    במכשיר בזמן ההתקנה, ואנחנו קוראים את זה פעם אחת בהפעלה הראשונה עם
//    Google Play Install Referrer API (חבילת android_play_install_referrer) -
//    זו הדרך הרשמית של גוגל לזיהוי הפניות, בלי צורך בשום שרת נוסף.
//  - iOS: לאפל אין API מקביל בחינם (בניגוד לאנדרואיד). הפתרון: דף הנחיתה
//    מעתיק את הקוד ל-clipboard (בלחיצת המשתמש על כפתור, כי iOS Safari
//    דורש "user gesture" אמיתי כדי לאפשר גישה ל-clipboard) לפני שהוא
//    מפנה לחנות. באפליקציה, בהפעלה הראשונה, בודקים את ה-clipboard לחיפוש
//    הסימון שלנו. זו טכניקה נפוצה ("deferred deep linking" ב-DIY, בלי
//    SDK בתשלום כמו Branch/AppsFlyer) - קצת פחות אמינה מאנדרואיד (תלויה
//    בכך שהמשתמש עבר דרך דף הנחיתה ולא ישר לחנות, ויכולה לגרום להתראת
//    פרטיות קצרה של iOS "האפליקציה הדביקה מה-Safari") אבל עובדת בפועל.
//  - הזיהוי (מי הזמין) נעשה לפי אותו קוד אישי שכבר קיים ל-friend_service.dart
//    (friendCodes/{code} -> playerId) - קוד אחד, שני שימושים בלתי-תלויים:
//    הוספת חבר בתוך האפליקציה (friend_service.dart), והפניית התקנה (כאן).
//    שימוש בזרימה הזו *לא* יוצר רשומת friendsList בכלל.
import 'dart:io' show Platform;
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_id.dart';
import 'player_sync.dart';

/// תוצאת קליטת הפניה מוצלחת (מהצד של המותקן החדש) - כדי שמסך הפתיחה
/// יוכל להציג פופאפ "קיבלת X מטבעות כי הורדת דרך ההזמנה של Y!".
class ReferralClaimResult {
  final int coins;
  final String referrerName;
  const ReferralClaimResult({required this.coins, required this.referrerName});
}

class ReferralService {
  ReferralService._();

  // 🆕 הועלה מ-30 ל-50 ואז ל-100 לפי בקשה מפורשת - "לחזק את מערכת
  // ההפניה" (חלק מדחיפה שיווקית לרכישת משתמשים חדשים).
  static const int bonusCoins = 75;
  static const String _landingBase = 'https://zehe-et-halogo.web.app/i';
  static const String _clipboardPrefix = 'ZEHE_REF:';

  static const _keyAttempts = 'referralCheckAttempts';
  static const _keyFirstCheckMs = 'referralFirstCheckMs';
  static const _keyClaimed = 'referralClaimed'; // קיבלנו בפועל בונוס הפניה

  // 🩹 באייפון הבדיקה תלויה ב-clipboard (ראו _readIosClipboardCode) - אם
  // המשתמש מעתיק משהו אחר בדיוק לפני הפתיחה הראשונה, בדיקה חד-פעמית הייתה
  // "מפספסת" לצמיתות בלי שום הזדמנות נוספת. עכשיו בודקים בכל אחת מכמה
  // ההפעלות הראשונות (לא פעם אחת בלבד), כל עוד זה עדיין בתוך חלון זמן
  // סביר מההתקנה - זה לא פוגע באנדרואיד (Install Referrer מחזיר את אותו
  // מידע בבטחה בכל פעם שנשאל, עד שגוגל מנקה אותו).
  static const int _maxAttempts = 5;
  static const Duration _attemptsWindow = Duration(days: 3);

  /// קישור לשיתוף - עמוד נחיתה אחד שמתאים את עצמו לאנדרואיד/אייפון,
  /// עם הקוד האישי מוטמע בתוכו.
  static String shareLink(String code) => '$_landingBase/$code';

  /// נקרא ב-main.dart (AppLifecycleManager) פעם בכל הפעלה - לא חוסם את
  /// מסך הפתיחה. מחזיר תוצאה רק אם *עכשיו* נקלטה הפניה בהצלחה (כדי
  /// שהמסך הקורא יציג פופאפ "קיבלת X מטבעות!") - null בכל מקרה אחר.
  static Future<ReferralClaimResult?> checkForReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyClaimed) == true) return null;

      final attempts = prefs.getInt(_keyAttempts) ?? 0;
      final firstCheckMs = prefs.getInt(_keyFirstCheckMs);
      final withinWindow = firstCheckMs == null || DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(firstCheckMs)) < _attemptsWindow;
      if (attempts >= _maxAttempts || !withinWindow) return null;

      await prefs.setInt(_keyAttempts, attempts + 1);
      if (firstCheckMs == null) await prefs.setInt(_keyFirstCheckMs, DateTime.now().millisecondsSinceEpoch);

      String? code;
      if (Platform.isAndroid) {
        code = await _readAndroidReferrerCode();
      } else if (Platform.isIOS) {
        code = await _readIosClipboardCode();
      }
      if (code == null || code.isEmpty) return null;
      return await _claim(code);
    } catch (e) {
      debugPrint('REFERRAL CHECK ERROR: $e');
      return null;
    }
  }

  static Future<String?> _readAndroidReferrerCode() async {
    try {
      final details = await AndroidPlayInstallReferrer.installReferrer;
      final raw = details.installReferrer; // לדוגמה "ref=ABC123"
      if (raw == null) return null;
      final match = RegExp(r'ref=([A-Za-z0-9]{4,10})').firstMatch(raw);
      return match?.group(1);
    } catch (_) {
      return null; // אין Google Play Services / לא הותקן דרך Play בכלל - תקין ולא שגיאה אמיתית
    }
  }

  static Future<String?> _readIosClipboardCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || !text.startsWith(_clipboardPrefix)) return null;
      final code = text.substring(_clipboardPrefix.length).trim();
      return RegExp(r'^[A-Za-z0-9]{4,10}$').hasMatch(code) ? code : null;
    } catch (_) {
      return null;
    }
  }

  static Future<ReferralClaimResult?> _claim(String code) async {
    final db = FirebaseFirestore.instance;
    final myId = await DeviceId.get();
    try {
      final codeDoc = await db.collection('friendCodes').doc(code.toUpperCase()).get();
      final referrerId = codeDoc.data()?['playerId'] as String?;
      if (referrerId == null || referrerId.isEmpty || referrerId == myId) return null;
      // 🆕 שם המזמין - כדי שהפופאפ אצל המותקן החדש יוכל להציג "כי הורדת
      // דרך ההזמנה של X!" (בלי זה - "חבר" גנרי בלבד).
      final referrerDoc = await db.collection('players').doc(referrerId).get();
      final referrerName = (referrerDoc.data()?['username'] as String?)?.trim();

      // בונוס לי (המותקן החדש) - מקומי מיד.
      final prefs = await SharedPreferences.getInstance();
      final coins = (prefs.getInt('coins') ?? 15) + bonusCoins;
      await prefs.setInt('coins', coins);
      await prefs.setBool(_keyClaimed, true);
      PlayerSyncService.syncCurrentProgress();

      // בונוס למי שהזמין - פקודה מרוחקת שהוא כבר מאזין לה (בדיוק כמו
      // friend_service.dart.acceptFriendRequest), בלי לגעת ב-friendsList.
      await db.collection('players').doc(referrerId).set({
        'pendingBonusCoins': FieldValue.increment(bonusCoins),
      }, SetOptions(merge: true));

      debugPrint('REFERRAL CLAIMED: code=$code referrer=$referrerId bonus=$bonusCoins');
      return ReferralClaimResult(coins: bonusCoins, referrerName: (referrerName != null && referrerName.isNotEmpty) ? referrerName : 'חבר');
    } catch (e) {
      debugPrint('REFERRAL CLAIM ERROR: $e');
      return null;
    }
  }
}
