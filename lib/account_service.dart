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
import 'battle_pass_service.dart'; // 🆕 סנכרון סטטוס/נקודות הבאטל פאס בין מכשירים

// 🆕 conflict: החשבון (Google/Apple) שהמשתמש בחר כבר מקושר להתקדמות
// שמורה בענן (כנראה ממכשיר אחר) - לפי בקשה מפורשת ("אני רוצה שהמערכת
// תראה לו שהיה לו עוד משתמש... וזה ישאל אותו לאיזה משתמש להתחבר") -
// כבר לא דורסים אוטומטית! ה-UI צריך להציג את pendingConflict ולבקש
// מהמשתמש לבחור, ואז לקרוא ל-resolveSignInConflict.
enum LinkResult { success, cancelled, error, conflict }

/// פרטי ההתקדמות השמורה בענן לחשבון שמתנגש עם המכשיר הנוכחי - ראו
/// LinkResult.conflict למעלה.
class SignInConflict {
  final int coins;
  final int xp;
  final int maxLevel;
  final String? username;
  const SignInConflict({required this.coins, required this.xp, required this.maxLevel, this.username});
}

class AccountService {
  static CollectionReference<Map<String, dynamic>> get _players =>
      FirebaseFirestore.instance.collection('players');

  /// true רק ב-iOS/macOS - Sign in with Apple לא זמין (ולא רלוונטי) ב-Android.
  static bool get appleAvailable => Platform.isIOS || Platform.isMacOS;

  // 🆕 מצב זמני בין הרגע שמתגלה "conflict" (ראה LinkResult.conflict) לבין
  // הרגע שהמשתמש בוחר במסך איך להמשיך (resolveSignInConflict) - לא נשמר
  // ב-SharedPreferences בכוונה, זה מצב חד-פעמי של תהליך התחברות בודד.
  static User? _pendingUser;
  static String? _pendingLabel;

  // true אם שלב בהתחברות/פתרון-ההתנגשות נכשל (בלי לחשוף למשתמש את פרטי
  // השגיאה - הם נכתבים רק ל-debugPrint). ה-UI משתמש בזה כדי להבחין בין
  // "המשתמש ביטל" ל"נכשל" ולהציג הודעה ידידותית.
  static bool lastAuthFailed = false;

  /// פרטי ההתקדמות השמורה בענן שמחכה להחלטת המשתמש - null אם אין
  /// כרגע התנגשות פתוחה. ה-UI קורא לזה מיד אחרי LinkResult.conflict.
  static SignInConflict? pendingConflict;

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

  /// 🆕 "פשוט אני רוצה שיהיה רשום Apple עם וי ירוק ומתחת Google, אם גוגל
  /// מחובר וי ירוק אם אפל וי ירוק" - אילו ספקים (google.com/apple.com)
  /// מקושרים כרגע למשתמש המחובר, לפי providerData האמיתי של Firebase
  /// Auth (לא לפי ניחוש מהאימייל - כך שגם אימייל-ריליי מוזר של אפל
  /// ("Hide My Email") לא משפיע על הזיהוי). ריק אם לא מקושר בכלל.
  static Set<String> get linkedProviderIds {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const {};
    return user.providerData.map((p) => p.providerId).toSet();
  }

  static Future<void> _saveLinkState({required String uid, required String label}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linkedUid', uid);
    await prefs.setString('linkedLabel', label);
  }

  // ========================================================================
  // התחברות עם Google
  // ========================================================================
  // 🩹 תוקן: "לחצתי המשך אחרי גוגל ונהיה תקוע חושב לנצח, לא עוצר" - גם
  // אחרי תיקון ה-URL scheme וה-GoogleService-Info.plist ב-iOS (build חדש
  // הותקן ועדיין קרה), כלומר יש עוד סיבה שלא הצלחתי לאתר בלי לוג ממכשיר
  // אמיתי. כל שלב עטוף עכשיו ב-timeout (עם debugPrint לפני/אחרי) - כך
  // שבמקום תקיעה אינסופית, אחרי 20 שניות זה ייכשל עם שגיאה ברורה, וה-
  // debugPrint-ים (נראים ב-Console.app במק, מסוננים לפי "Runner") יראו
  // בדיוק על איזו שורה זה נעצר בפעם הבאה שזה קורה.
  static const _stepTimeout = Duration(seconds: 20);

  static Future<LinkResult> signInWithGoogle() async {
    lastAuthFailed = false;
    try {
      debugPrint('GOOGLE SIGN-IN: starting GoogleSignIn().signIn()');
      final googleUser = await GoogleSignIn().signIn().timeout(_stepTimeout);
      debugPrint('GOOGLE SIGN-IN: signIn() returned (user=${googleUser?.email})');
      if (googleUser == null) return LinkResult.cancelled; // המשתמש ביטל את חלון הבחירה
      final googleAuth = await googleUser.authentication.timeout(_stepTimeout);
      debugPrint('GOOGLE SIGN-IN: got authentication tokens');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential).timeout(_stepTimeout);
      debugPrint('GOOGLE SIGN-IN: signInWithCredential() returned (uid=${userCred.user?.uid})');
      final user = userCred.user;
      if (user == null) return LinkResult.error;
      final result = await _afterSignIn(user, label: user.email ?? googleUser.email);
      debugPrint('GOOGLE SIGN-IN: _afterSignIn() returned $result');
      return result;
    } catch (e) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      lastAuthFailed = true;
      return LinkResult.error;
    }
  }

  // ========================================================================
  // התחברות עם Apple (iOS/macOS בלבד - ראו appleAvailable)
  // ========================================================================
  static Future<LinkResult> signInWithApple() async {
    lastAuthFailed = false;
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);
      debugPrint('APPLE SIGN-IN: starting getAppleIDCredential()');
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      ).timeout(_stepTimeout);
      debugPrint('APPLE SIGN-IN: getAppleIDCredential() returned');
      // 🩹 תוקן: "[firebase_auth/invalid-credential] Invalid OAuth response
      // from apple.com" - למרות ש-idToken היה תקין, מגרסאות מסוימות של
      // firebase_auth (SDK v9 המודולרי) ואילך Firebase דורש גם את
      // authorizationCode של אפל (מועבר כ-accessToken) כדי לאמת את
      // האישור - בלעדיו הוא נחשב "לא שלם" ונדחה עם השגיאה הזו בדיוק,
      // גם כשה-idToken עצמו תקין לגמרי בפני עצמו.
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
        rawNonce: rawNonce,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(oauthCredential).timeout(_stepTimeout);
      debugPrint('APPLE SIGN-IN: signInWithCredential() returned (uid=${userCred.user?.uid})');
      final user = userCred.user;
      if (user == null) return LinkResult.error;
      // 🆕 אפל מחזירה מייל/שם רק בהתחברות הראשונה אי-פעם לאפליקציה הזו -
      // בפעמים הבאות appleCred.email יהיה null, ולכן מעדיפים את user.email
      // (מ-Firebase Auth, כבר נשמר מהפעם הראשונה) כשקיים.
      final label = user.email ?? appleCred.email ?? "Apple ID";
      return await _afterSignIn(user, label: label);
    } catch (e) {
      debugPrint('APPLE SIGN-IN ERROR: $e');
      lastAuthFailed = true;
      return LinkResult.error;
    }
  }

  // ========================================================================
  // אחרי התחברות מוצלחת (משותף ל-Google/Apple).
  // 🐛 תוקן: לפי בקשה מפורשת ("אני רוצה שהמערכת תראה לו שהיה לו עוד
  // משתמש... וזה ישאל אותו לאיזה משתמש להתחבר") - בעבר, אם לחשבון הזה
  // כבר הייתה התקדמות שמורה בענן (ממכשיר אחר), היא הייתה *דורסת אוטומטית
  // ובלי שום שאלה* את ההתקדמות של המכשיר הנוכחי. עכשיו: רק מזהים שיש
  // התנגשות ומחזירים LinkResult.conflict + pendingConflict עם הפרטים -
  // ה-UI הוא זה שמציג דיאלוג ושואל, ורק אז קורא ל-resolveSignInConflict
  // כדי לבצע את הבחירה בפועל (ראו שם). אין תמיכה במספר "פרופילים" תחת
  // אותו חשבון - כל חשבון Google/Apple מקושר תמיד להתקדמות שחקן אחת
  // בלבד (בדיוק כמו שכל משחק סלולרי אחר עובד) - הבחירה כאן היא רק
  // "איזו משתי ההתקדמויות הקיימות תישאר", לא יצירת פרופיל נוסף.
  // ========================================================================
  static Future<LinkResult> _afterSignIn(User user, {required String label}) async {
    debugPrint('GOOGLE SIGN-IN: _afterSignIn - reading players/${user.uid}');
    final cloudDoc = await _players.doc(user.uid).get().timeout(_stepTimeout);
    debugPrint('GOOGLE SIGN-IN: _afterSignIn - players/${user.uid} exists=${cloudDoc.exists}');

    if (cloudDoc.exists) {
      final data = cloudDoc.data() ?? {};
      pendingConflict = SignInConflict(
        coins: (data['coins'] as num?)?.toInt() ?? 0,
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        maxLevel: (data['maxLevel'] as num?)?.toInt() ?? 1,
        username: data['username'] as String?,
      );
      _pendingUser = user;
      _pendingLabel = label;
      return LinkResult.conflict;
    }

    await _linkFresh(user, label: label);
    return LinkResult.success;
  }

  // 🆕 חיבור ראשון לחשבון הזה (אין עדיין players/{uid}) - ההתקדמות
  // הנוכחית של המכשיר (שכבר קיימת גם ב-players/{deviceId}) מועתקת
  // ל-players/{uid} החדש. אין כאן שום התנגשות לפתור.
  static Future<void> _linkFresh(User user, {required String label}) async {
    final deviceId = await DeviceId.get();
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('coins') ?? 15;
    final xp = prefs.getInt('xp') ?? 0;
    final maxLevel = prefs.getInt('maxLevel') ?? 1;
    final username = prefs.getString('username');
    debugPrint('GOOGLE SIGN-IN: _linkFresh - writing players/${user.uid}');
    await _players.doc(user.uid).set({
      'coins': coins,
      'xp': xp,
      'maxLevel': maxLevel,
      if (username != null) 'username': username,
      'linkedFromDeviceId': deviceId,
      'authLabel': label,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(_stepTimeout);
    debugPrint('GOOGLE SIGN-IN: _linkFresh - write done');

    await _saveLinkState(uid: user.uid, label: label);
    // 🆕 סנכרון הבאטל פאס - ראו ההסבר המלא ב-battle_pass_service.dart.
    // כאן המכשיר הוא ה"נכון" (או שזה חיבור ראשון, או שהמשתמש בחר במפורש
    // להשאיר את ההתקדמות המקומית) - דוחפים אותה לענן, דורסים כל מה
    // שהיה שם קודם (למשל ממכשיר אחר עם אותו חשבון).
    BattlePassService.syncToCloud();
  }

  // ========================================================================
  // נקרא אחרי שהמשתמש ענה בדיאלוג (ראו pendingConflict) על השאלה "לאיזו
  // התקדמות להתחבר". useCloudProgress=true טוען את הענן למכשיר; false
  // משאיר את המכשיר כמו שהוא, ודורס איתו את מה שהיה שמור בענן (כלומר
  // מרגע זה ההתקדמות של המכשיר הזה היא "הנכונה" לחשבון הזה).
  // ========================================================================
  // 🩹 תוקן: זו הייתה בדיוק סיבת התקיעה "לנצח" אחרי בחירה בדיאלוג
  // ההתנגשות - בניגוד ל-signInWithGoogle/signInWithApple, לפונקציה הזו
  // לא היה בכלל try/catch או timeout. אם כתיבת ה-Firestore (ב-_linkFresh
  // או ב-pullFromCloudIfNeeded) נתקעה מכל סיבה (רשת/permission) - ה-await
  // כאן פשוט לא היה חוזר לעולם, וה-UI שקורא לזה (showAccountConflictDialog)
  // נשאר תקוע במסך הטעינה בלי שום שגיאה.
  static Future<bool> resolveSignInConflict({required bool useCloudProgress}) async {
    final user = _pendingUser;
    final label = _pendingLabel;
    if (user == null || label == null) return false;

    try {
      if (useCloudProgress) {
        final data = pendingConflict;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('coins', data?.coins ?? 15);
        await prefs.setInt('xp', data?.xp ?? 0);
        await prefs.setInt('maxLevel', data?.maxLevel ?? 1);
        final savedUsername = data?.username;
        if (savedUsername != null && savedUsername.isNotEmpty) {
          await prefs.setString('username', savedUsername);
        }
        await _saveLinkState(uid: user.uid, label: label);
        // 🆕 force:true - המשתמש בחר במפורש "התחבר עם ההתקדמות השמורה",
        // אז דורסים כל התקדמות באטל פאס מקומית שהייתה למכשיר הזה לעונה
        // הנוכחית (ראו ההסבר המלא ב-battle_pass_service.dart.pullFromCloudIfNeeded).
        await BattlePassService.pullFromCloudIfNeeded(force: true).timeout(_stepTimeout);
      } else {
        await _linkFresh(user, label: label);
      }
    } catch (e) {
      debugPrint('RESOLVE SIGN-IN CONFLICT ERROR: $e');
      lastAuthFailed = true;
      return false;
    }

    pendingConflict = null;
    _pendingUser = null;
    _pendingLabel = null;
    return true;
  }

  /// המשתמש סגר/ביטל את דיאלוג ההתנגשות בלי לבחור - מנקים את המצב הזמני
  /// ומתנתקים מ-Firebase Auth (כדי שניסיון התחברות הבא יציג שוב את בורר
  /// החשבונות, במקום להשתמש בשקט בחשבון שכבר "נבחר" בפועל אבל לא אומץ).
  static Future<void> cancelSignInConflict() async {
    pendingConflict = null;
    _pendingUser = null;
    _pendingLabel = null;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // ========================================================================
  // 🆕 "שיהיה אופציה להתנתק מהחשבון שהתחברתי אליו" - מתנתק מהחשבון
  // Google/Apple המקושר, בלי למחוק שום דבר: ההתקדמות שכרגע על המכשיר
  // (שהיא ההתקדמות שהייתה מסונכרנת מהחשבון עד הרגע הזה) נשארת בדיוק
  // כמו שהיא, רק שמעכשיו effectiveId() חוזר להשתמש ב-deviceId הרגיל
  // במקום ב-uid המקושר - בדיוק כמו לפני שקישרו חשבון בכלל.
  // ========================================================================
  static Future<void> signOutLinked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('linkedUid');
    await prefs.remove('linkedLabel');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
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
      // 🩹 תוקן: "שזה ימחק ממש את כל השורה שלא ישאר ממנה זכר" - תת-אוסף
      // friendRequests/* (בקשות חברות ממתינות *אליו*, ראו friend_service.dart)
      // לא נמחק בכלל קודם - היה נשאר לנצח גם אחרי מחיקת המשתמש.
      final requestsSnap = await _players.doc(id).collection('friendRequests').get();
      for (final doc in requestsSnap.docs) {
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
    // 🩹 תוקן: תור ההמתנה של מצב מירוץ (logo_race_service.dart) - אותה
    // בעיה בדיוק כמו duelQueue למעלה, פשוט נשכח קודם.
    await FirebaseFirestore.instance.collection('logoRaceQueue').doc(id).delete().catchError((_) {});
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