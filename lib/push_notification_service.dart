// push_notification_service.dart
//
// שכבת ה-Push הבסיסית שכל שאר המערכת (שידורים ידניים + התראות אוטומטיות)
// נשענת עליה: מבקש הרשאה, שומר את ה-FCM token של כל מכשיר ב-Firestore
// (כדי שאפשר יהיה לשלוח אליו הודעות ממוקדות), ומטפל בהודעות שמגיעות.
//
//   flutter pub add firebase_messaging
//
// לאחר שזה מותקן, יש שני "ערוצים" לשלוח דרכם התראות:
//
// 1) שידורים ידניים - Firebase Console -> Engage -> Messaging -> New
//    campaign. אין צורך בקוד נוסף בכלל - כותבים כותרת+טקסט בעברית,
//    בוחרים קהל (הכל / סינון לפי פרמטרים), ולוחצים שלח. זה הכי מהיר
//    לניסויים ("יש עדכון חדש למשחק! בואו לבדוק 🔥").
//
// 2) התראות אוטומטיות מבוססות-אירוע - דורשות Cloud Function (ראה
//    cloud_functions_notifications_snippet.js שנשלח בנפרד) - למשל
//    "מישהו עקף אותך בטבלת הדירוג" מופעל אוטומטית כשמשהו משתנה
//    ב-Firestore, לא ידני.

import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// קוראים לזה פעם אחת ב-main.dart, אחרי Firebase.initializeApp()
  static Future<void> init() async {
    // מבקש הרשאה מהמשתמש (חובה באייפון, גם באנדרואיד 13+ יש בקשת הרשאה
    // מפורשת - במכשירים ישנים יותר זה כבר מאושר אוטומטית)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // המשתמש סירב - לא קורסים, פשוט לא נוכל לשלוח לו התראות.
      // אפשר בעתיד להראות מסך הסבר ולהפנות אותו להגדרות המכשיר.
      return;
    }

    await _saveTokenToFirestore();

    // אם ה-token מתחדש (קורה מדי פעם, למשל אחרי החלפת מכשיר/אפליקציה
    // חדשה) - שומרים את הגרסה המעודכנת אוטומטית
    _messaging.onTokenRefresh.listen((_) => _saveTokenToFirestore());

    // הודעה שמגיעה כשהאפליקציה **פתוחה וברקע הקדמי** (foreground) -
    // FCM לא מציג באנר אוטומטית במצב הזה, צריך לטפל בזה ידנית אם
    // רוצים גם כן להראות משהו למשתמש (למשל SnackBar). אפשר להשאיר ריק
    // בינתיים אם מספיק שההתראה תופיע כשהאפליקציה סגורה/ברקע.
    FirebaseMessaging.onMessage.listen((message) {
      // כאן אפשר להוסיף בעתיד: הצגת SnackBar/דיאלוג בתוך האפליקציה
    });

    // מטפל בלחיצה על ההתראה כשהאפליקציה הייתה סגורה/ברקע
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // כאן אפשר להוסיף בעתיד: ניווט למסך ספציפי לפי message.data
      // (למשל אם ההתראה על דו-קרב ממתין - לפתוח ישר את הלובי)
    });
  }

  // 🐛 תוקן: זה נקרא כבר ב-main() לפני runApp() - כלומר לפני שהמשתמש
  // בכלל ראה את מסך "בחר שם", אצל כל התקנה חדשה. set(merge) על מכשיר
  // כזה יצר מסמך players "רפאים" עם רק fcmToken/fcmTokenUpdatedAt (בלי
  // username/xp/coins בכלל) - זה בדיוק אותו באג שכבר תוקן ב-touchPresence
  // (friend_service.dart) עבור lastActiveAt, רק במקור אחר. עכשיו לא
  // כותבים בלי שם משתמש קיים - וכדי שהטוקן לא "יאבד" לצמיתות למשתמשים
  // שעדיין לא בחרו שם, main_menu_screen.dart קורא ל-retrySaveTokenIfNeeded
  // ברגע שהם סוף סוף שומרים שם בפעם הראשונה.
  static Future<void> retrySaveTokenIfNeeded() => _saveTokenToFirestore();

  static Future<void> _saveTokenToFirestore() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString('username') ?? '').trim().isEmpty) return;
    // 🐛 DEBUG TEMP - אבחון באג אמיתי (iOS: fcmToken אף פעם לא נשמר,
    // גם אחרי שהמשתמש אישר הרשאה, ולא ניתן לחבר Xcode/Mac לבדיקה).
    // כותבים שלבי התקדמות לשדה pushDebug על מסמך השחקן עצמו (שדה יחיד,
    // נדרס בכל פעם - לא יוצר מסמכים/כתיבות נוספות מעבר למה שכבר קורה
    // באופן קבוע על המסמך הזה) כדי שאפשר יהיה לראות מרחוק (Firebase
    // Console) בדיוק איפה זה נתקע, בלי שום גישה פיזית למכשיר/Mac.
    final deviceId = await AccountService.effectiveId();
    Future<void> debugWrite(String status) async {
      try {
        await FirebaseFirestore.instance.collection('players').doc(deviceId).set(
          {'pushDebug': '$status @ ${DateTime.now().toIso8601String()}'},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }

    await debugWrite('START');
    final token = await _getTokenSafely(debugWrite);
    if (token == null) {
      await debugWrite('FAILED: token is null');
      return;
    }
    // 🐛 תוקן: היה נשמר תמיד תחת DeviceId.get() (מזהה המכשיר הגולמי) -
    // אבל כל שאר המערכת (friend_service.dart, player_sync.dart) עברה
    // להשתמש ב-AccountService.effectiveId() כמזהה המסמך "האמיתי" של
    // השחקן (הופך ל-uid המקושר אחרי קישור חשבון Google/Apple). שחקן
    // עם חשבון מקושר היה מקבל את ה-fcmToken כתוב על players/{deviceId}
    // הישן שאף אחד כבר לא קורא ממנו - כל פוש ממוקד (לפי מסמך השחקן
    // הפעיל) פשוט לא היה מוצא טוקן ולא מגיע אליו.
    await FirebaseFirestore.instance.collection('players').doc(deviceId).set(
      {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await debugWrite('SUCCESS: token saved (len=${token.length})');
  }

  // 🐛 תוקן באג אמיתי שהתגלה בבדיקה בפועל: המשתמש אישר "אפשר התראות"
  // ב-iOS, אבל Firestore נשאר בלי fcmToken בכלל - לנצח, גם דקות רבות
  // אחר כך. הסיבה: ב-iOS, getToken() של FCM תלוי בכך שה-APNs token
  // (שמגיע מ-Apple, לא מ-Google) כבר התקבל ברקע ע"י הקוד הנייטיבי.
  // מיד אחרי requestPermission() הוא כמעט תמיד עוד לא הגיע - והקריאה
  // ל-getToken() פשוט נכשלת בשקט (מחזירה null או זורקת), בלי שום ניסיון
  // חוזר אוטומטי (onTokenRefresh לא תמיד "מציל" את זה - הוא מיועד
  // לרענון טוקן קיים, לא בהכרח רץ שוב אם הקריאה הראשונה נכשלה לגמרי).
  // התיקון: ב-iOS, קודם ממתינים בפועל שה-APNs token יגיע (עד 10 ניסיונות,
  // שנייה בין כל ניסיון) ורק אז קוראים ל-getToken().
  static Future<String?> _getTokenSafely([Future<void> Function(String)? debugWrite]) async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await debugWrite?.call('checking APNs token');
        String? apnsToken = await _messaging.getAPNSToken();
        var attempts = 0;
        while (apnsToken == null && attempts < 30) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _messaging.getAPNSToken();
          attempts++;
          if (attempts % 5 == 0) await debugWrite?.call('still waiting for APNs, attempt $attempts');
        }
        if (apnsToken == null) {
          await debugWrite?.call('APNs token NEVER arrived after 30s');
          return null;
        }
        await debugWrite?.call('APNs token OK (len=${apnsToken.length}), calling getToken()');
      }
      final fcmToken = await _messaging.getToken();
      await debugWrite?.call(fcmToken == null ? 'getToken() returned null' : 'getToken() OK');
      return fcmToken;
    } catch (e) {
      await debugWrite?.call('EXCEPTION: $e');
      return null;
    }
  }
}