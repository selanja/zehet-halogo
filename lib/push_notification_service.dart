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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  static Future<void> _saveTokenToFirestore() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    // 🐛 תוקן: היה נשמר תמיד תחת DeviceId.get() (מזהה המכשיר הגולמי) -
    // אבל כל שאר המערכת (friend_service.dart, player_sync.dart) עברה
    // להשתמש ב-AccountService.effectiveId() כמזהה המסמך "האמיתי" של
    // השחקן (הופך ל-uid המקושר אחרי קישור חשבון Google/Apple). שחקן
    // עם חשבון מקושר היה מקבל את ה-fcmToken כתוב על players/{deviceId}
    // הישן שאף אחד כבר לא קורא ממנו - כל פוש ממוקד (לפי מסמך השחקן
    // הפעיל) פשוט לא היה מוצא טוקן ולא מגיע אליו.
    final deviceId = await AccountService.effectiveId();
    await FirebaseFirestore.instance.collection('players').doc(deviceId).set(
      {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}