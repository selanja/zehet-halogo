// friend_service.dart
//
// 🆕 מערכת "חברים" אמיתית - "כל העניין זה שלכל אחד יהיה מזהה משל עצמו
// וככה הוא מוסיף חברים גם לאפליקציה וגם לאזור הזה באפליקציה, ואז שהוא
// לוחץ על החבר הוא יכול להזמין אותו למשחק והוא יכול לראות אם הוא מחובר".
//
// איך זה עובד:
// - לכל שחקן יש "קוד חברים" קבוע (6 תווים, בדיוק כמו קודי הדו-קרב
//   הקיימים ב-duel_service.dart - אותו אורך, אותו charset בלי 0/O/1/I
//   כדי שלא יתבלבלו כשמעתיקים/מקלידים).
// - מזהה השחקן עצמו הוא effectiveId (ראו account_service.dart) - deviceId
//   רגיל, או uid מקושר אם קושר חשבון Google/Apple.
// - הוספת חבר לפי קוד היא הדדית - שני הצדדים מקבלים רשומה אצל השני
//   (players/{myId}/friendsList/{friendId} וגם ההפך).
// - "מחובר/לא מחובר" מבוסס על lastActiveAt - שדה שמתעדכן מעת לעת כל עוד
//   האפליקציה פתוחה (ראו touchPresence, נקרא מ-main.dart). שחקן נחשב
//   "מחובר" אם lastActiveAt שלו התעדכן ב-3 הדקות האחרונות.
// - "הזמן למשחק" לחבר ספציפי - לא רק קוד לשיתוף חופשי: נכתב ישירות
//   לשדה incomingInvite במסמך של החבר, וה-listener החי שלו (ב-
//   main.dart, כל עוד האפליקציה שלו פתוחה) מציג לו באנר הזמנה מיידי.
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart';

enum AddFriendResult { success, invalidCode, notFound, ownCode, alreadyFriends, error }

class FriendInfo {
  final String id;
  final String name;
  final bool online;
  final int xp; // 🆕 ל"מי מוביל בין החברים שלך" (friends_screen.dart) - אותו שדה xp שכבר מסונכרן ל-Firestore לצורך טבלת השיאים הרגילה (leaderboard.dart)
  const FriendInfo({required this.id, required this.name, required this.online, this.xp = 0});
}

class FriendService {
  static CollectionReference<Map<String, dynamic>> get _players =>
      FirebaseFirestore.instance.collection('players');
  static CollectionReference<Map<String, dynamic>> get _codes =>
      FirebaseFirestore.instance.collection('friendCodes');

  static const int codeLength = 6;
  // בכוונה בלי 0/O ו-1/I - בדיוק כמו קודי הדו-קרב (duel_service.dart),
  // כדי שלא יתבלבלו כשמעתיקים/מקלידים.
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const Duration onlineWindow = Duration(minutes: 3);

  /// מזהה קבוע של השחקן הזה - deviceId רגיל, או uid מקושר אם יש (ראו
  /// account_service.dart).
  static Future<String> myId() => AccountService.effectiveId();

  static String _generateCode() {
    final rnd = Random();
    return List.generate(codeLength, (_) => _codeChars[rnd.nextInt(_codeChars.length)]).join();
  }

  /// קוד החברים הקבוע של השחקן הזה - נוצר פעם אחת בלבד ונשמר לצמיתות
  /// (מקומית + ב-Firestore), כדי שאפשר לשתף אותו לחברים.
  static Future<String> myCode() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('friendCode');
    if (cached != null && cached.isNotEmpty) return cached;

    final id = await myId();
    // אם כבר קיים קוד לשחקן הזה ב-Firestore (למשל שוחזר ממכשיר אחר אחרי
    // קישור חשבון Google/Apple) - נשתמש בו, לא ניצור קוד כפול.
    try {
      final playerDoc = await _players.doc(id).get();
      final existingCode = playerDoc.data()?['friendCode'] as String?;
      if (existingCode != null && existingCode.isNotEmpty) {
        await prefs.setString('friendCode', existingCode);
        return existingCode;
      }
    } catch (_) {}

    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      final ref = _codes.doc(code);
      try {
        final existingCodeDoc = await ref.get();
        if (existingCodeDoc.exists) continue; // התנגשות נדירה - ננסה קוד אחר
        await ref.set({'playerId': id, 'createdAt': FieldValue.serverTimestamp()});
        await _players.doc(id).set({'friendCode': code}, SetOptions(merge: true));
        await prefs.setString('friendCode', code);
        return code;
      } catch (_) {
        // ננסה שוב עם קוד חדש
      }
    }
    throw Exception('לא הצלחנו ליצור קוד חברים');
  }

  /// מוסיף חבר לפי הקוד שלו - הדדי (גם אני נוסף אצלו, גם הוא אצלי).
  static Future<AddFriendResult> addFriendByCode(String rawCode, {required String myName}) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != codeLength) return AddFriendResult.invalidCode;
    try {
      final myIdVal = await myId();
      final codeDoc = await _codes.doc(code).get();
      final friendId = codeDoc.data()?['playerId'] as String?;
      if (friendId == null || friendId.isEmpty) return AddFriendResult.notFound;
      if (friendId == myIdVal) return AddFriendResult.ownCode;

      final already = await _players.doc(myIdVal).collection('friendsList').doc(friendId).get();
      if (already.exists) return AddFriendResult.alreadyFriends;

      final friendPlayerDoc = await _players.doc(friendId).get();
      final friendName = (friendPlayerDoc.data()?['username'] as String?) ?? 'שחקן';

      await _players.doc(myIdVal).collection('friendsList').doc(friendId).set({
        'name': friendName,
        'addedAt': FieldValue.serverTimestamp(),
      });
      await _players.doc(friendId).collection('friendsList').doc(myIdVal).set({
        'name': myName,
        'addedAt': FieldValue.serverTimestamp(),
      });
      return AddFriendResult.success;
    } catch (e) {
      debugPrint('ADD FRIEND ERROR: $e');
      return AddFriendResult.error;
    }
  }

  /// רשימת החברים של השחקן הזה - שם עדכני + מצב "מחובר" (פעיל ב-3
  /// הדקות האחרונות, ראו touchPresence).
  static Future<List<FriendInfo>> fetchFriends() async {
    try {
      final myIdVal = await myId();
      final snap = await _players.doc(myIdVal).collection('friendsList').orderBy('addedAt', descending: true).get();
      final results = <FriendInfo>[];
      for (final doc in snap.docs) {
        final friendId = doc.id;
        String name = (doc.data()['name'] as String?) ?? 'שחקן';
        bool online = false;
        int xp = 0;
        try {
          final playerDoc = await _players.doc(friendId).get();
          final data = playerDoc.data();
          if (data != null) {
            final liveName = data['username'] as String?;
            if (liveName != null && liveName.isNotEmpty) name = liveName;
            final lastActive = data['lastActiveAt'];
            if (lastActive is Timestamp) {
              online = DateTime.now().difference(lastActive.toDate()) < onlineWindow;
            }
            xp = (data['xp'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {
          // אם לא הצלחנו לרענן פרטים חיים - נציג את השם השמור, בלי "מחובר"/xp
        }
        results.add(FriendInfo(id: friendId, name: name, online: online, xp: xp));
      }
      return results;
    } catch (e) {
      debugPrint('FETCH FRIENDS ERROR: $e');
      return [];
    }
  }

  /// "פעימת נוכחות" - קוראים לזה מעת לעת כל עוד האפליקציה פעילה (ראו
  /// main.dart), כדי שחברים יראו שאתה "מחובר". כשל שקט אם אין אינטרנט.
  static Future<void> touchPresence() async {
    try {
      final id = await myId();
      await _players.doc(id).set({'lastActiveAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// שולח הזמנה ישירה לחבר ספציפי - נכתב לשדה incomingInvite במסמך שלו,
  /// כדי שאם האפליקציה שלו פתוחה הוא יראה באנר הזמנה מיידי (ראו
  /// watchIncomingInvite + main.dart). הקוד עצמו נוצר כבר קודם דרך
  /// DuelService.createInvite הרגיל - הפונקציה הזו רק "מודיעה" עליו.
  static Future<void> notifyFriendOfInvite({
    required String friendId,
    required String fromId,
    required String fromName,
    required String code,
    required int stake,
  }) async {
    try {
      await _players.doc(friendId).set({
        'incomingInvite': {
          'fromId': fromId,
          'fromName': fromName,
          'code': code,
          'stake': stake,
          'sentAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NOTIFY FRIEND ERROR: $e');
    }
  }

  /// מאזין בזמן אמת להזמנות דו-קרב נכנסות מחברים - ראו main.dart
  /// (AppLifecycleManager), נשאר פתוח כל עוד האפליקציה חיה.
  static Stream<Map<String, dynamic>?> watchIncomingInvite(String myIdVal) {
    return _players.doc(myIdVal).snapshots().map((s) {
      final data = s.data();
      final invite = data?['incomingInvite'];
      return invite is Map<String, dynamic> ? invite : null;
    });
  }

  /// מנקה הזמנה נכנסת אחרי שהוצגה למשתמש וטופלה (התקבלה/נדחתה), כדי
  /// שלא תופיע שוב בכל פעם שהמסמך משתנה מסיבה אחרת.
  static Future<void> clearIncomingInvite(String myIdVal) async {
    try {
      await _players.doc(myIdVal).set({'incomingInvite': FieldValue.delete()}, SetOptions(merge: true));
    } catch (_) {}
  }
}