// account_service.dart
//
// 🆕 קישור חשבון (Google / Apple) - "לדעתי לחבר את המשתמשים לגוגל או
// משהו כדי שאם נניח אם מחליפים טלפון או משהו הכול נשמר, ואם הם רוצים
// למחוק את המשתמש שלהם הם עושים בהגדרות מחק משתמש".
//
// ==========================================================================
// איך זה עובד (בקצרה):
// ==========================================================================
// עד עכשיו כל שחקן זוהה רק לפי deviceId (device_id.dart) - מזהה שנשמר
// מקומית במכשיר, וההתקדמות שלו מסתנכרנת ל-Firestore תחת players/{deviceId}
// (ראה player_sync.dart). הבעיה: אם מחליפים מכשיר - נוצר deviceId חדש,
// וההתקדמות "נעלמת" (בפועל היא עדיין קיימת ב-players/{deviceId} הישן,
// אבל שום דבר לא מקשר את המכשיר החדש אליה).
//
// הפתרון כאן: מוסיפים התחברות עם Google/Apple (Firebase Auth). אחרי
// חיבור מוצלח:
//   - אם זו הפעם הראשונה שהחשבון הזה מקושר (אין עדיין players/{uid}) -
//     ההתקדמות הנוכחית של המכשיר מועתקת לשם, וה-uid הזה נשמר מקומית
//     כ"מקושר" (linkedUid).
//   - אם החשבון הזה כבר קושר בעבר (players/{uid} כבר קיים, למשל ממכשיר
//     אחר) - ההתקדמות מהענן היא זו שנטענת למכשיר הנוכחי - בדיוק ה"הכול
//     נשמר" שהתבקש.
// ההתקדמות המקומית של המכשיר **לעולם לא נמחקת** בתהליך הזה, לפי בקשה
// מפורשת - players/{deviceId} הישן נשאר קיים ב-Firestore גם אחרי קישור.
//
// אחרי קישור, PlayerSyncService (player_sync.dart) עובר להשתמש ב-effectiveId()
// (uid מקושר אם קיים, אחרת deviceId כרגיל) לכל קריאה ל-Firestore.
//
// ==========================================================================
// ⚠️ הגדרה ידנית נדרשת - קוד Dart בלבד לא מספיק, אלה שלבים מחוץ לקוד:
// ==========================================================================
// 1. Firebase Console -> Authentication -> Sign-in method -> להפעיל את
//    ה-providers "Google" ו-"Apple".
// 2. Android (Google Sign-In): להוסיף את טביעת האצבע SHA-1 (ומומלץ גם
//    SHA-256) של חתימת האפליקציה ב-Firebase Console (Project settings ->
//    Your apps -> Android app), ואז להוריד מחדש google-services.json
//    מעודכן ולהחליף את הקובץ הקיים בפרויקט.
// 3. iOS (Google Sign-In): להוסיף ב-Xcode ל-Info.plist בלוק CFBundleURLTypes
//    עם ה-REVERSED_CLIENT_ID מתוך GoogleService-Info.plist - לפי התיעוד
//    הרשמי של חבילת google_sign_in.
// 4. iOS (Sign in with Apple): ב-Xcode -> Signing & Capabilities -> "+
//    Capability" -> להוסיף "Sign in with Apple". חובה - בלי זה ההתחברות
//    עם אפל נכשלת. Android לא תומך ב-Sign in with Apple בכלל - הכפתור
//    מוצג רק ב-iOS/macOS (ראו appleAvailable למטה).
// 5. להוסיף ל-pubspec.yaml (dependencies), ואז flutter pub get:
//      firebase_auth: ^5.3.1
//      google_sign_in: ^6.2.2
//      sign_in_with_apple: ^6.1.4
//      crypto: ^3.0.5
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'device_id.dart';
import 'duel_service.dart'; // 🆕 currentSeasonId() - למחיקת רשומת טבלת השיאים העונתית של הדו-קרב

enum LinkResult { success, cancelled, error }

class AccountService {
  static CollectionReference<Map<String, dynamic>> get _players =>
      FirebaseFirestore.instance.collection('players');

  /// true רק ב-iOS/macOS - Sign in with Apple לא זמין (ולא רלוונטי) ב-Android.
  static bool get appleAvailable => Platform.isIOS || Platform.isMacOS;

  /// המזהה המקושר (Firebase Auth UID) אם קיים, אחרת null.
  static Future<String?> get linkedUid async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('linkedUid');
  }

  /// true אם המכשיר הזה מקושר לחשבון Google/Apple כרגע.
  static Future<bool> get isLinked async => (await linkedUid) != null;

  /// המזהה בו יש להשתמש בפועל מול Firestore - ה-uid המקושר אם קיים,
  /// אחרת deviceId רגיל. player_sync.dart משתמש בזה במקום ב-deviceId ישירות.
  static Future<String> effectiveId() async {
    final uid = await linkedUid;
    if (uid != null && uid.isNotEmpty) return uid;
    return DeviceId.get();
  }

  /// תווית להצגה במסך ההגדרות (מייל / "Apple ID"), null אם לא מקושר.
  static Future<String?> get linkedLabel async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('linkedLabel');
  }

  static Future<void> _saveLinkState({required String uid, required String label}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linkedUid', uid);
    await prefs.setString('linkedLabel', label);
  }

  // ========================================================================
  // התחברות עם Google
  // ========================================================================
  static Future<LinkResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return LinkResult.cancelled; // המשתמש ביטל את חלון הבחירה
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return LinkResult.error;
      await _afterSignIn(user, label: user.email ?? googleUser.email);
      return LinkResult.success;
    } catch (e) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      return LinkResult.error;
    }
  }

  // ========================================================================
  // התחברות עם Apple (iOS/macOS בלבד - ראו appleAvailable)
  // ========================================================================
  static Future<LinkResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCred.identityToken,
        rawNonce: rawNonce,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCred.user;
      if (user == null) return LinkResult.error;
      // 🆕 אפל מחזירה מייל/שם רק בהתחברות הראשונה אי-פעם לאפליקציה הזו -
      // בפעמים הבאות appleCred.email יהיה null, ולכן מעדיפים את user.email
      // (מ-Firebase Auth, כבר נשמר מהפעם הראשונה) כשקיים.
      final label = user.email ?? appleCred.email ?? "Apple ID";
      await _afterSignIn(user, label: label);
      return LinkResult.success;
    } catch (e) {
      debugPrint('APPLE SIGN-IN ERROR: $e');
      return LinkResult.error;
    }
  }

  // ========================================================================
  // אחרי התחברות מוצלחת (משותף ל-Google/Apple) - ראו הסבר מלא בראש הקובץ.
  // ========================================================================
  static Future<void> _afterSignIn(User user, {required String label}) async {
    final deviceId = await DeviceId.get();
    final cloudDoc = await _players.doc(user.uid).get();
    final prefs = await SharedPreferences.getInstance();

    if (cloudDoc.exists) {
      // 🆕 החשבון הזה כבר קושר בעבר (כנראה במכשיר אחר) - ההתקדמות מהענן
      // היא זו ש"זוכה" ונטענת למכשיר הזה. ההתקדמות המקומית הקודמת של
      // המכשיר הזה נשארת קיימת ב-players/{deviceId} - רק מפסיקים
      // להשתמש בה מעכשיו לטובת ההתקדמות המקושרת.
      final data = cloudDoc.data() ?? {};
      await prefs.setInt('coins', (data['coins'] as num?)?.toInt() ?? 15);
      await prefs.setInt('xp', (data['xp'] as num?)?.toInt() ?? 0);
      await prefs.setInt('maxLevel', (data['maxLevel'] as num?)?.toInt() ?? 1);
      final savedUsername = data['username'] as String?;
      if (savedUsername != null && savedUsername.isNotEmpty) {
        await prefs.setString('username', savedUsername);
      }
    } else {
      // 🆕 חיבור ראשון לחשבון הזה - ההתקדמות הנוכחית של המכשיר (שכבר
      // קיימת גם ב-players/{deviceId}) מועתקת ל-players/{uid} החדש.
      final coins = prefs.getInt('coins') ?? 15;
      final xp = prefs.getInt('xp') ?? 0;
      final maxLevel = prefs.getInt('maxLevel') ?? 1;
      final username = prefs.getString('username');
      await _players.doc(user.uid).set({
        'coins': coins,
        'xp': xp,
        'maxLevel': maxLevel,
        if (username != null) 'username': username,
        'linkedFromDeviceId': deviceId,
        'authLabel': label,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _saveLinkState(uid: user.uid, label: label);
  }

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

  // 🆕 "מחיקת משתמש אמורה למחוק הכול גם מהלידר בורד" - מוחקת את כל
  // המסמכים הידועים של השחקן הזה (players + טבלת השיאים + נתוני
  // דו-קרב) לפי מזהה נתון (deviceId או uid). כל מחיקה עטופה ב-catchError
  // בנפרד כדי שכשל במסמך אחד (למשל כי הוא לא קיים מלכתחילה) לא יעצור
  // את מחיקת השאר.
  //
  // ⚠️ לא נמחק: duelH2H (היסטוריית ראש-בראש בין שני שחקנים - המפתח שם
  // הוא צירוף של שני מזהי מכשיר, "pairKey", ואין דרך יעילה לשלוף את כל
  // המסמכים שבהם שחקן מסוים מעורב בלי לסרוק את כל האוסף) - זה מסמך
  // סטטיסטי משותף עם שחקן אחר, לא מכיל שם/מידע מזהה של השחקן שנמחק בעצמו.
  // גם לא נמחקת (מאותה סיבה): הרשומה שלו ב-friendsList של חברים אחרים -
  // היא פשוט תפסיק להתעדכן (שם/סטטוס "מחובר" יישארו קפואים), אבל לא
  // תיעלם אצל החבר. זו מגבלה ידועה, לא באג.
  static Future<void> _deleteAllPlayerData(String id) async {
    // 🆕 "חברים" (friend_service.dart) - קודם קוראים את הקוד/הרשימה
    // *לפני* מחיקת המסמך הראשי, כי אחרי המחיקה אין יותר איך לדעת מה
    // היה שם. מוחקים את מיפוי הקוד (friendCodes/{code}) ואת רשימת
    // החברים של השחקן הזה עצמו (players/{id}/friendsList/*).
    try {
      final playerSnap = await _players.doc(id).get();
      final friendCode = playerSnap.data()?['friendCode'] as String?;
      if (friendCode != null && friendCode.isNotEmpty) {
        await FirebaseFirestore.instance.collection('friendCodes').doc(friendCode).delete().catchError((_) {});
      }
      final friendsSnap = await _players.doc(id).collection('friendsList').get();
      for (final doc in friendsSnap.docs) {
        await doc.reference.delete().catchError((_) {});
      }
    } catch (_) {}

    await _players.doc(id).delete().catchError((_) {});
    // 🏆 טבלת השיאים הראשית (leaderboard.dart) - זה בדיוק "הלידר בורד"
    await FirebaseFirestore.instance.collection('leaderboard').doc(id).delete().catchError((_) {});
    // ⚔️ נתוני דו-קרב (duel_service.dart) - מספר ניצחונות, חסימה זמנית,
    // טבלת עונה נוכחית, ותור המתנה (אם נתקע שם באמצע חיפוש יריב).
    await FirebaseFirestore.instance.collection('duelStats').doc(id).delete().catchError((_) {});
    await FirebaseFirestore.instance.collection('duelPenalties').doc(id).delete().catchError((_) {});
    await FirebaseFirestore.instance.collection('duelQueue').doc(id).delete().catchError((_) {});
    await FirebaseFirestore.instance
        .collection('duelSeasonStats')
        .doc('${DuelService.currentSeasonId()}_$id')
        .delete()
        .catchError((_) {});
  }

  // ========================================================================
  // מחיקת משתמש (הגדרות -> "מחק משתמש"). עובד גם למי שלא מקושר (מוחק רק
  // לפי deviceId), וגם למקושר (מוחק גם לפי uid, ואת חשבון ה-Firebase Auth
  // עצמו).
  // ========================================================================
  static Future<bool> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('linkedUid');
      final deviceId = await DeviceId.get();

      // מוחקים גם לפי deviceId וגם לפי uid (אם קיים) - כדי לא להשאיר
      // שריד שאפשר "לשחזר" ממנו בטעות בעתיד, כולל מהלידר בורד.
      await _deleteAllPlayerData(deviceId);
      if (uid != null) {
        await _deleteAllPlayerData(uid);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // 🆕 Firebase דורש התחברות "טרייה" לפני מחיקת חשבון, מטעמי
            // אבטחה - מתחברים שוב באותו ספק ואז מנסים למחוק שוב פעם אחת.
            final providerId = user.providerData.isNotEmpty ? user.providerData.first.providerId : null;
            final result = providerId == 'apple.com' ? await signInWithApple() : await signInWithGoogle();
            if (result == LinkResult.success) {
              await FirebaseAuth.instance.currentUser?.delete();
            }
          } else {
            rethrow;
          }
        }
      }

      // איפוס מקומי מלא - בדיוק כמו איפוס-מרחוק (player_sync.dart), רק
      // שכאן זה ביוזמת השחקן עצמו דרך ההגדרות.
      await prefs.setInt('coins', 15);
      await prefs.setInt('xp', 0);
      await prefs.setInt('maxLevel', 1);
      await prefs.remove('bestRandomStreak');
      await prefs.remove('randomStreak');
      await prefs.remove('currentRandomPuzzleId');
      await prefs.remove('linkedUid');
      await prefs.remove('linkedLabel');
      await prefs.remove('username');
      await prefs.remove('friendCode'); // 🆕 קוד החברים נמחק גם הוא - ראו friend_service.dart

      return true;
    } catch (e) {
      debugPrint('DELETE ACCOUNT ERROR: $e');
      return false;
    }
  }
}