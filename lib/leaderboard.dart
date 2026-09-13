// leaderboard.dart — גרסת Firebase Firestore (החליף את הגרסה הישנה
// שהתבססה על Google Sheets + Apps Script, שהייתה איטית בגלל "cold start"
// של הסקריפט בכל בקשה).
//
// שומר על אותם שמות בדיוק (LeaderboardService, fetchLeaderboard,
// submitScore) - כך ש-leaderboard_screen.dart לא צריך שום שינוי.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardService {
  static final CollectionReference<Map<String, dynamic>> _players =
      FirebaseFirestore.instance.collection('leaderboard');

  // 🆕 אבחון זמני - שומר את השגיאה האמיתית מ-Firestore (permission-denied,
  // unavailable וכו') כדי שמסך הטבלה יוכל להציג אותה במקום ההודעה
  // הגנרית "בדקו חיבור לאינטרנט" שמופיעה גם כשהבעיה לא קשורה לאינטרנט
  // בכלל. להסיר אחרי שהתקלה נמצאת ותוקנה.
  static String? lastError;

  // כתובת הגיליון הישן - נשארת כאן רק כדי שההעברה החד-פעמית של הנתונים
  // הקיימים תוכל לקרוא ממנה. אפשר למחוק את השורה הזו אחרי שההעברה בוצעה
  // ווידאת שכל השחקנים מופיעים ב-Firestore.
  static const String _oldScriptUrl =
      "https://script.google.com/macros/s/AKfycbyw3EId0I1LVeKaUhWkchtdbzKVjyXlH-DpEclvMJTKIYAjF0bTMcKemIOkQice2XsLhw/exec";

  /// שולף את טבלת השיאים, ממוינת לפי XP יורד. מוגבל ל-200 השורות
  /// המובילות - הרבה יותר מהר מלטעון גיליון Google שלם בכל פעם.
  static Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final snapshot = await _players
          .orderBy('xp', descending: true)
          .limit(200)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "name": (data["name"] ?? "").toString(),
          "xp": data["xp"] ?? 0,
          "streak": data["streak"] ?? 0,
          // מזהה המכשיר הוא גם ה-document ID באוסף - כך שליחת ניקוד
          // חדש לאותו מכשיר תמיד מעדכנת את אותה שורה ולא יוצרת כפולה
          "deviceId": doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint("LEADERBOARD ERROR: $e");
      lastError = e.toString();
      return [];
    }
  }

  /// 🆕 טבלת "שיאי רצף" - ממוינת לפי שדה ה-streak יורד (במקום xp). זהו
  /// שדה ה-bestRandomStreak שנשלח מהמכשיר, כלומר השיא הכי גבוה אי-פעם -
  /// לא הרצף הנוכחי (שיכול להתאפס). מוגבל גם הוא ל-200 שורות.
  static Future<List<Map<String, dynamic>>> fetchLeaderboardByStreak() async {
    try {
      final snapshot = await _players
          .orderBy('streak', descending: true)
          .limit(200)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "name": (data["name"] ?? "").toString(),
          "xp": data["xp"] ?? 0,
          "streak": data["streak"] ?? 0,
          "deviceId": doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint("LEADERBOARD STREAK ERROR: $e");
      lastError = e.toString();
      return [];
    }
  }

  /// שומר/מעדכן את הניקוד של המכשיר הזה. שימוש ב-deviceId כמזהה המסמך
  /// עצמו הופך את הפעולה לעדכון מיידי (לא צריך לחפש שורה קיימת כמו
  /// שהיה נחוץ בגיליון Google).
  static Future<void> submitScore(String name, int xp, {int streak = 0, required String deviceId}) async {
    try {
      await _players.doc(deviceId).set({
        "name": name,
        "xp": xp,
        "streak": streak,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("SUBMIT SCORE OK");
    } catch (e) {
      debugPrint("SUBMIT SCORE ERROR: $e");
    }
  }

  /// בודק אם השם הזה כבר תפוס על ידי מכשיר אחר (השוואה מדויקת, אחרי
  /// חיתוך רווחים). מתעלם ממכשיר עצמו (excludeDeviceId) כדי שאפשר יהיה
  /// "לשמור" את השם הנוכחי שלך בלי שהוא ידווח כתפוס על ידי עצמך.
  static Future<bool> isNameTaken(String name, {String? excludeDeviceId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    try {
      final snapshot = await _players.where('name', isEqualTo: trimmed).limit(5).get();
      return snapshot.docs.any((doc) => doc.id != excludeDeviceId);
    } catch (e) {
      debugPrint("NAME CHECK ERROR: $e");
      // ⚠️ בכשל רשת - לא חוסמים שמירה (עדיף לאפשר שם כפול נדיר מלנעול
      // שחקן לגמרי בגלל בעיית תקשורת זמנית).
      return false;
    }
  }

  // ================================================================
  // 🔁 העברה חד-פעמית מהגיליון הישן ל-Firestore
  // ================================================================
  //
  // רץ פעם אחת בלבד לכל הפרויקט (לא לכל מכשיר!) - נשען על מסמך דגל
  // משותף ב-Firestore (meta/migrationStatus). המכשיר הראשון שנפתח אחרי
  // העדכון "תופס" את המשימה, מעביר את כל השחקנים הקיימים, ומסמן שסיים.
  // כל שאר המכשירים רואים שכבר בוצע ומדלגים מיידית.
  //
  // בטוח להרצה חוזרת: submitScore משתמש ב-deviceId כמזהה מסמך, אז גם
  // אם זה ירוץ פעמיים בטעות זה רק ידרוס את אותן שורות עם אותם נתונים.
  static Future<void> migrateFromSheetsIfNeeded() async {
    // בדיקה מקומית מהירה קודם - חוסכת קריאת Firestore מיותרת בכל פתיחת
    // אפליקציה אחרי שהמכשיר הזה כבר בדק פעם אחת שההעברה בוצעה.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sheetsToFirestoreMigrationChecked') == true) return;

    final metaDoc = FirebaseFirestore.instance.collection('meta').doc('migrationStatus');
    try {
      final snap = await metaDoc.get();
      if (snap.exists && snap.data()?['done'] == true) {
        await prefs.setBool('sheetsToFirestoreMigrationChecked', true);
        return; // כבר בוצע - אין מה לעשות
      }

      // "נועלים" מיד כדי לצמצם את הסיכוי ששני מכשירים ירוצו את זה בו-זמנית
      await metaDoc.set({'done': true, 'startedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      final response = await http.get(Uri.parse(_oldScriptUrl));
      if (response.statusCode != 200) {
        debugPrint("MIGRATION: לא הצליח לטעון את הגיליון הישן (${response.statusCode})");
        return;
      }

      final List<dynamic> oldData = jsonDecode(response.body);
      int migrated = 0;
      for (final e in oldData) {
        final name = (e["name"] ?? "").toString();
        final xp = e["xp"] ?? 0;
        final streak = e["streak"] ?? 0;
        final deviceId = (e["deviceId"] ?? "").toString();
        if (deviceId.isEmpty) continue; // בלי deviceId אין לאן לשמור בלי ליצור כפילות
        await _players.doc(deviceId).set({
          "name": name,
          "xp": xp,
          "streak": streak,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        migrated++;
      }

      await metaDoc.set({'done': true, 'migratedCount': migrated, 'finishedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      debugPrint("MIGRATION: הועברו $migrated שחקנים מהגיליון הישן ל-Firestore ✅");

      // גם מסמנים מקומית שהמכשיר הזה כבר ביצע את ההעברה - נחסך קריאה מיותרת ל-Firestore בכל פתיחה עתידית
      await prefs.setBool('sheetsToFirestoreMigrationChecked', true);
    } catch (e) {
      debugPrint("MIGRATION ERROR: $e");
    }
  }
}