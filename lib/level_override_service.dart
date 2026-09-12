// level_override_service.dart
//
// 🆕 "אדמין פאנל" קליל לתיקון שלבים בלי לפרסם גרסה חדשה לחנויות. כל 458
// השלבים עדיין קבועים בקוד (gameLevels ב-logo_level_screen.dart) - אבל
// אם התגלתה טעות (תשובה שגויה, מקלדת עם אותיות לא נכונות, תמונת לוגו
// שבורה) אפשר "לתקן" שלב ספציפי ע"י הוספת מסמך לאוסף "levelOverrides"
// ב-Firestore, בלי לגעת בקוד בכלל ובלי לחכות לאישור חנות האפליקציות.
//
// איך מתקנים שלב (הכי פשוט - ישירות מ-Firebase Console, בדיוק כמו
// שכבר עובד עם אוסף "coupons" - ראו coupon_service.dart):
// Firestore Database -> אוסף "levelOverrides" -> מסמך חדש שה-ID שלו
// הוא *מספר השלב* בתור טקסט (למשל "217"), עם השדות הבאים (כולם
// אופציונליים - ממלאים רק מה שצריך לתקן, ומשאירים את השאר ריק):
//   answer    (טקסט)   - התשובה הנכונה החדשה (למשל "קוקה קולה")
//   keyboard  (מערך טקסטים) - 14 האותיות שמוצגות במקלדת השלב
//   imageUrl  (טקסט)   - קישור ישיר לתמונה חדשה (https://...) שתוצג
//                         *במקום* תמונת ה-assets המקורית של השלב. שימושי
//                         כשהתמונה המקורית שבורה/לא נטענת - אין צורך
//                         להעלות אותה כ-asset בקוד, מספיק לארח אותה
//                         איפשהו (למשל Firebase Storage / Hosting) ולהדביק
//                         את הקישור כאן.
//   active    (בוליאני, ברירת מחדל true) - אפשר לכבות תיקון זמנית בלי למחוק
//
// 🔁 סנכרון מ-Google Sheets (אופציונלי, לניהול נוח יותר של הרבה תיקונים
// יחד): יש סקריפט Python נפרד (sync_level_overrides_from_sheet.py) שעובד
// בדיוק כמו sync_coupons_from_sheet.py הקיים - עורכים גיליון, מריצים
// סקריפט, השינויים עולים ל-Firestore.
//
// 🚀 ביצועים/אופליין: כל הרשימה נטענת *פעם אחת* כשהמכשיר נכנס למשחק
// (preload, לא חוסם את תחילת המשחק) ונשמרת בזיכרון + מטמון מקומי
// (SharedPreferences) - כך שגם בפעם הבאה שהמכשיר נכנס למשחק בלי אינטרנט
// זמין, הוא עדיין רואה את התיקונים האחרונים שהצליח להוריד בעבר. כשל
// בטעינה (אין אינטרנט וגם אין מטמון) פשוט אומר "אין תיקונים" - השלבים
// מוצגים בדיוק כמו שהם מוגדרים בקוד, בדיוק כמו לפני שהתכונה הזו נוספה.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelOverrideService {
  static const _collection = 'levelOverrides';
  static const _cacheKey = 'levelOverridesCacheV1';

  static Map<int, Map<String, dynamic>> _overrides = {};
  static bool _loaded = false;
  static Future<void>? _preloadFuture;

  /// טוען את כל התיקונים הפעילים פעם אחת (בטוח לקרוא כמה פעמים - הקריאות
  /// הנוספות פשוט מחזירות את אותו Future שכבר רץ). לא חוסם כלום - קוראים
  /// לזה "ברקע" מ-initState של מסך השלב, והתצוגה מתעדכנת (setState) אחרי
  /// שהטעינה מסתיימת, אם היא לא הספיקה להסתיים לפני שהשלב כבר הוצג.
  static Future<void> preload() {
    return _preloadFuture ??= _doPreload();
  }

  static Future<void> _doPreload() async {
    try {
      final snap = await FirebaseFirestore.instance.collection(_collection).get();
      final parsed = <int, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        final levelId = int.tryParse(doc.id);
        if (levelId == null) continue;
        final d = doc.data();
        if (d['active'] == false) continue;
        parsed[levelId] = d;
      }
      _overrides = parsed;
      _loaded = true;
      _saveCache(parsed);
    } catch (e) {
      debugPrint("LEVEL OVERRIDE LOAD ERROR: $e");
      // אין אינטרנט/שגיאת Firestore - ננסה מהמטמון המקומי (תיקונים
      // מהפעם האחרונה שהמכשיר הזה הצליח להתחבר) לפני שמוותרים לגמרי.
      await _loadFromCache();
    }
  }

  static Future<void> _saveCache(Map<int, Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodable = data.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_cacheKey, jsonEncode(encodable));
    } catch (_) {}
  }

  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _overrides = decoded.map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, dynamic>()));
      _loaded = true;
    } catch (_) {}
  }

  /// התיקון (אם יש) עבור שלב ספציפי - null אם אין תיקון פעיל לשלב הזה,
  /// או אם הטעינה עדיין לא הסתיימה.
  static Map<String, dynamic>? overrideFor(int levelId) => _overrides[levelId];

  static bool get isLoaded => _loaded;
}