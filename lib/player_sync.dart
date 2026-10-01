// player_sync.dart
// מסנכרן את ההתקדמות של השחקן (מטבעות, נקודות, שלב מקסימלי) לענן
// (Firestore), בנוסף לשמירה המקומית הרגילה שכבר קיימת.
//
// המטרה: כרגע ההתקדמות שמורה רק על המכשיר של השחקן (SharedPreferences),
// ולכן אין שום דרך לאפס למישהו ספציפי את המשחק מרחוק. אחרי שהקובץ הזה
// ייכנס לעדכון, לכל שחקן יהיה גם עותק של ההתקדמות שלו ב-Firestore
// (אוסף "players", לפי מזהה "אפקטיבי" - ראו account_service.dart:
// deviceId רגיל כברירת מחדל, או uid של חשבון Google/Apple מקושר אם
// השחקן קישר חשבון) - וזה פותח אפשרות לאפס שחקן ספציפי מרחוק (ראה
// הסבר למטה), וגם שומר את ההתקדמות בין מכשירים למי שמקשר חשבון.
//
// שימוש רגיל (כבר מחובר בקובץ logo_level_screen.dart):
//   PlayerSyncService.syncCurrentProgress();
// קריאה לא חוסמת (fire-and-forget) - לא מעכבת את המשחק ולא זורקת שגיאה
// החוצה, גם אם אין אינטרנט.
//
// ================================================================
// איך מאפסים שחקן ספציפי מרחוק (אחרי שהעדכון הזה כבר בידי השחקנים):
// ================================================================
// 1. נכנסים למסוף Firebase (console.firebase.google.com) -> הפרויקט
//    zehe-et-halogo -> Firestore Database -> אוסף "players".
// 2. מוצאים את המסמך של השחקן המבוקש (אפשר לזהות לפי שדה "username",
//    או להצליב עם ה-deviceId שמוצג לצידו בטבלת השיאים).
// 3. פותחים את המסמך ומוסיפים/משנים שדה בשם resetRequested לערך true
//    (Boolean).
// 4. בפעם הבאה שהשחקן פותח את המשחק, ההתקדמות שלו (מטבעות/נקודות/
//    שלב מקסימלי/רצפים) תתאפס אוטומטית חזרה להתחלה, והדגל יורד לבד
//    כדי שזה לא יקרה שוב.
//
// ================================================================
// איך רק מורידים/קובעים מטבעות לשחקן ספציפי (בלי לגעת בנקודות/התקדמות):
// ================================================================
// באותו מסמך שלו באוסף "players", מוסיפים שדה בשם setCoinsTo עם המספר
// הרצוי (למשל 15 או 0) - Number, לא טקסט. בפעם הבאה שהשחקן פותח את
// המשחק, המטבעות שלו יתעדכנו למספר הזה (ורק המטבעות - הנקודות והשלב
// שלו לא ישתנו), והשדה יימחק לבד כדי שזה לא יקרה שוב בכל פתיחה.
//
// ================================================================
// חשוב: השינוי חי (Real-time) - לא צריך לחכות שהשחקן ייצא ויכנס!
// ================================================================
// האפליקציה מאזינה למסמך שלו כל עוד היא פתוחה (startListening, מופעל
// פעם אחת ב-main.dart). ברגע שאתה שומר שינוי בקונסולה של Firebase, הוא
// מגיע מיד למכשיר של השחקן ומתעדכן על המסך שלו תוך שנייה-שתיים, גם אם
// הוא נמצא ממש באמצע שלב. זה פותר בדיוק את הבעיה שבה שחקן ממשיך
// להשתמש במטבעות הישנים לפני שהאיפוס "תפס".
//
// 🩺 הוספנו DebugLog.add(...) בכמה נקודות מפתח - כלי אבחון זמני לאיתור
// תקיעה/קריסה באייפון. ראו debug_log.dart. אפשר להסיר אחרי שהבאג נמצא.
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart'; // 🆕 מזהה "אפקטיבי" - uid מקושר (Google/Apple) אם קיים, אחרת deviceId כרגיל
import 'debug_log.dart';
import 'device_id.dart'; // 🆕 לדיווח לטבלת השיאים (leaderboard.dart) - אותו deviceId גולמי שכבר נהוג שם, לא ה-id "האפקטיבי"
import 'leaderboard.dart'; // 🆕 ראו הערה ליד syncCurrentProgress - כל שינוי XP מדווח גם לטבלת השיאים, לא רק ל-players

class CoinsSignal extends ChangeNotifier {
  int? _value;
  int? get value => _value;
  void emit(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

/// 🆕 "בונוס חבר/הפניה נחת" - שונה מ-CoinsSignal (שרק מודיע על הסכום
/// הכולל החדש): כאן מודיעים כמה *התווסף עכשיו* ולמה, כדי ש-main.dart
/// יוכל להציג פופאפ יפה ("קיבלת 30 מטבעות!") במקום רק לרענן מספר בשקט.
class BonusSignal extends ChangeNotifier {
  int? _amount;
  int? get amount => _amount;
  void emit(int amount) {
    _amount = amount;
    notifyListeners();
  }
}

class PlayerSyncService {
  static CollectionReference<Map<String, dynamic>> get _players =>
      FirebaseFirestore.instance.collection('players');

  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// מתעדכן בכל פעם שמישהו קובע setCoinsTo מרחוק (או אחרי איפוס מלא -
  /// אז הערך יהיה 15). כל מסך שרוצה לדעת על שינוי מטבעות מיידי (למשל
  /// מסך המשחק, כדי לעדכן את התצוגה גם באמצע שלב) יכול להאזין לזה עם
  /// addListener. הערך עצמו כבר נשמר גם ב-SharedPreferences.
  //
  // בכוונה לא ValueNotifier<int?> רגיל: ValueNotifier לא מודיע למאזינים
  // אם קובעים בו פעמיים ברצף בדיוק אותו ערך (למשל שני עדכונים ל-15) -
  // המחלקה הקטנה הזו כן מודיעה בכל פעם, כדי שעדכון לא "יבלע" בשקט.
  static final CoinsSignal remoteCoinsUpdate = CoinsSignal();
  // 🆕 "חבר הצטרף/הותקן דרך הזמנה שלך" - ראו BonusSignal. main.dart מאזין
  // לזה כדי להציג פופאפ "קיבלת X מטבעות!" (ראו friend_service.dart +
  // referral_service.dart, ששניהם עוברים דרך pendingBonusCoins).
  static final BonusSignal referralBonusReceived = BonusSignal();

  /// "מהבהב" (משתנה ל-true) בכל פעם שמתבצע איפוס מלא מרחוק - מסכים
  /// שמציגים גם XP/שלב יכולים להאזין לזה כדי לרענן את התצוגה שלהם.
  static final ValueNotifier<bool> remoteResetSignal = ValueNotifier<bool>(false);

  /// מתחיל להאזין בזמן אמת לשינויים במסמך של השחקן הזה ב-Firestore.
  /// יש לקרוא לזה פעם אחת כשהאפליקציה עולה (ב-AppLifecycleManager
  /// ב-main.dart) ולהשאיר פתוח לאורך כל חיי האפליקציה - זה מה שגורם
  /// לאיפוס/עדכון מטבעות "לתפוס" מיד, גם אם השחקן כבר בתוך משחק.
  static Future<void> startListening() async {
    try {
      DebugLog.add("PlayerSync.startListening: cancelling old sub");
      await _sub?.cancel();
      // 🆕 uid מקושר (Google/Apple) אם קיים, אחרת deviceId כרגיל - ראו account_service.dart
      final deviceId = await AccountService.effectiveId();
      DebugLog.add("PlayerSync.startListening: id=$deviceId, attaching listener");
      _sub = _players.doc(deviceId).snapshots().listen((doc) async {
        DebugLog.add("PlayerSync: snapshot received (hasPendingWrites=${doc.metadata.hasPendingWrites}, fromCache=${doc.metadata.isFromCache})");
        final data = doc.data();
        if (data == null) return;
        await _applyRemoteCommands(data, deviceId);
      });
      DebugLog.add("PlayerSync.startListening: listener attached OK");
    } catch (e) {
      DebugLog.add("PlayerSync.startListening ERROR: $e");
      debugPrint("PLAYER LISTEN ERROR: $e");
    }
  }

  static Future<void> stopListening() async {
    await _sub?.cancel();
    _sub = null;
  }

  static Future<void> _applyRemoteCommands(Map<String, dynamic> data, String deviceId) async {
    try {
      if (data['resetRequested'] == true) {
        DebugLog.add("PlayerSync: resetRequested==true -> applying reset + writing back");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('coins', 15);
        await prefs.setInt('xp', 0);
        await prefs.setInt('maxLevel', 1);
        await prefs.remove('bestRandomStreak');
        await prefs.remove('randomStreak');
        await prefs.remove('currentRandomPuzzleId');

        await _players.doc(deviceId).set({
          "resetRequested": false,
          "setCoinsTo": FieldValue.delete(),
          "coins": 15,
          "xp": 0,
          "maxLevel": 1,
          "resetAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        remoteCoinsUpdate.emit(15);
        remoteResetSignal.value = !remoteResetSignal.value;
        debugPrint("PLAYER RESET (LIVE): בוצע איפוס מרחוק מיידית ✅");
        DebugLog.add("PlayerSync: reset write done");
        return;
      }

      final newCoins = _parseCoins(data['setCoinsTo']);
      if (newCoins != null) {
        DebugLog.add("PlayerSync: setCoinsTo=$newCoins -> applying + writing back");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('coins', newCoins);

        await _players.doc(deviceId).set({
          "setCoinsTo": FieldValue.delete(),
          "coins": newCoins,
          "resetAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        remoteCoinsUpdate.emit(newCoins);
        debugPrint("PLAYER COINS UPDATE (LIVE): המטבעות עודכנו ל-$newCoins מיידית ✅");
        DebugLog.add("PlayerSync: setCoinsTo write done");
      }

      // 🆕 "מביאים חבר למשחק" - בונוס מטבעות ממתין (ראו
      // friend_service.dart.acceptFriendRequest) - הצד ששלח את בקשת
      // החברות מקבל אותו כאן, בפעם הראשונה שהאפליקציה שלו פתוחה אחרי
      // שהחבר אישר. מפחיתים ב-Firestore בדיוק את הסכום שיושם (לא מוחקים
      // סתם) כדי לא "לבלוע" בונוס נוסף שהתווסף בדיוק באותו רגע.
      final pendingBonus = _parseCoins(data['pendingBonusCoins']);
      if (pendingBonus != null && pendingBonus > 0) {
        DebugLog.add("PlayerSync: pendingBonusCoins=$pendingBonus -> applying");
        final prefs = await SharedPreferences.getInstance();
        final newTotal = (prefs.getInt('coins') ?? 15) + pendingBonus;
        await prefs.setInt('coins', newTotal);
        await _players.doc(deviceId).set({
          "pendingBonusCoins": FieldValue.increment(-pendingBonus),
        }, SetOptions(merge: true));
        remoteCoinsUpdate.emit(newTotal);
        referralBonusReceived.emit(pendingBonus);
        DebugLog.add("PlayerSync: pendingBonusCoins applied, new total=$newTotal");
      }
    } catch (e) {
      DebugLog.add("PlayerSync._applyRemoteCommands ERROR: $e");
      debugPrint("PLAYER REMOTE COMMAND ERROR: $e");
    }
  }

  // הופך את הערך שהוזן בקונסולה של Firebase למספר, גם אם הוקלד כטקסט
  // בטעות (למשל "15" עם מרכאות במקום 15 בלי מרכאות) - כדי שזה יעבוד
  // גם אם לא נבחר סוג השדה "Number" בדיוק.
  static int? _parseCoins(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  /// שולח התקדמות נתונה לענן. לא חוסם ולא זורק שגיאה החוצה - אם אין
  /// אינטרנט זה פשוט נכשל בשקט, וההתקדמות תסתנכרן בפעם הבאה שיהיה חיבור.
  static Future<void> syncToCloud({
    required int coins,
    required int xp,
    required int maxLevel,
    String? username,
  }) async {
    try {
      // 🆕 uid מקושר (Google/Apple) אם קיים, אחרת deviceId כרגיל - ראו account_service.dart
      final deviceId = await AccountService.effectiveId();
      await _players.doc(deviceId).set({
        "coins": coins,
        "xp": xp,
        "maxLevel": maxLevel,
        "username": ?username,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("PLAYER SYNC ERROR: $e");
    }
  }

  /// קורא את ההתקדמות המקומית הנוכחית מ-SharedPreferences ושולח אותה
  /// לענן. נוח לקרוא לזה מכל מקום בלי להעביר פרמטרים בעצמך.
  //
  // 🩹 תוקן לפי בקשה מפורשת ("כל ניצחון נותן גם XP לטבלה"): עד עכשיו זה
  // רק עדכן את אוסף "players" (סנכרון בין מכשירים/איפוס מרחוק) - *לא*
  // את אוסף "leaderboard" שהטבלה הארצית בפועל ממוינת לפיו (ראו
  // leaderboard.dart.fetchLeaderboard, orderBy('xp')). המקום היחיד
  // שדיווח לטבלה הארצית היה logo_level_screen.dart בלבד, אז XP שהתקבל
  // מניצחון בדו-קרב/מירוץ/אתגר יומי (שכולם כבר קוראים לפונקציה הזו אחרי
  // שמעדכנים xp מקומית) לא היה מופיע בטבלה עד שהשחקן גם פתר שלב רגיל
  // במצב יחיד. עכשיו כל קריאה לפונקציה הזו (כלומר כל שינוי התקדמות) גם
  // מדווחת לטבלה הארצית - מקום מרכזי אחד, בלי לפזר קריאות submitScore
  // בכל קובץ ניצחון בנפרד.
  static Future<void> syncCurrentProgress() async {
    try {
      DebugLog.add("PlayerSync.syncCurrentProgress START");
      final prefs = await SharedPreferences.getInstance();
      final coins = prefs.getInt('coins') ?? 15;
      final xp = prefs.getInt('xp') ?? 0;
      final maxLevel = prefs.getInt('maxLevel') ?? 1;
      final username = prefs.getString('username');
      final bestStreak = prefs.getInt('bestRandomStreak') ?? 0;
      await syncToCloud(coins: coins, xp: xp, maxLevel: maxLevel, username: username);
      if (username != null && username.isNotEmpty) {
        final deviceId = await DeviceId.get();
        await LeaderboardService.submitScore(username, xp, streak: bestStreak, deviceId: deviceId);
      }
      DebugLog.add("PlayerSync.syncCurrentProgress END");
    } catch (e) {
      DebugLog.add("PlayerSync.syncCurrentProgress ERROR: $e");
      debugPrint("PLAYER SYNC ERROR: $e");
    }
  }

  /// בדיקה חד-פעמית (לא זמן-אמת) לאיפוס/עדכון מטבעות ממתין - משמשת
  /// כרשת ביטחון נוספת בפתיחת מסך המשחק, בנוסף להאזנה החיה למעלה
  /// (startListening) שכבר אמורה לתפוס את זה מיד. מחזיר true אם בוצע
  /// שינוי כלשהו בפועל.
  static Future<bool> checkForRemoteReset() async {
    try {
      DebugLog.add("PlayerSync.checkForRemoteReset START");
      // 🆕 uid מקושר (Google/Apple) אם קיים, אחרת deviceId כרגיל - ראו account_service.dart
      final deviceId = await AccountService.effectiveId();
      final doc = await _players.doc(deviceId).get();
      final data = doc.data();
      if (data == null) {
        DebugLog.add("PlayerSync.checkForRemoteReset: no data");
        return false;
      }
      final pendingBonus = _parseCoins(data['pendingBonusCoins']);
      if (data['resetRequested'] != true && _parseCoins(data['setCoinsTo']) == null && (pendingBonus == null || pendingBonus <= 0)) {
        DebugLog.add("PlayerSync.checkForRemoteReset: nothing pending");
        return false;
      }
      await _applyRemoteCommands(data, deviceId);
      DebugLog.add("PlayerSync.checkForRemoteReset END (applied)");
      return true;
    } catch (e) {
      DebugLog.add("PlayerSync.checkForRemoteReset ERROR: $e");
      debugPrint("PLAYER RESET CHECK ERROR: $e");
      return false;
    }
  }
}