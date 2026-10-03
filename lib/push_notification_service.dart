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
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _saveTokenToFirestore();

    _messaging.onTokenRefresh.listen((_) => _saveTokenToFirestore());

    FirebaseMessaging.onMessage.listen((message) {
      // כאן אפשר להוסיף בעתיד: הצגת SnackBar/דיאלוג בתוך האפליקציה
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // כאן אפשר להוסיף בעתיד: ניווט למסך ספציפי לפי message.data
    });
  }

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
      // 🐛 תוקן: _getTokenSafely כבר כותב את הסיבה המדויקת לכישלון
      // (APNs timeout / getToken() null / EXCEPTION) כרגע לפני שהיא
      // מחזירה null - כתיבה גנרית נוספת כאן רק דרסה את הסיבה האמיתית
      // ב-pushDebug (שדה יחיד, נדרס בכל כתיבה) ולא השאירה שום מידע
      // שימושי לאבחון מרחוק.
      return;
    }
    await FirebaseFirestore.instance.collection('players').doc(deviceId).set(
      {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await debugWrite('SUCCESS: token saved (len=${token.length})');
  }

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