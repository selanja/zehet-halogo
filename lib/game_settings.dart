// game_settings.dart
//
// 🆕 העדפות משחק קטנות, לא קשורות לסאונד/התראות (שכבר יש להן את
// AudioManager/NotificationManager משלהן) - נוסף למסך "הגדרות" החדש
// (טאב "משחק", לפי מוקאפ Settings.html שסופק במפורש). אותו דפוס בדיוק
// כמו AudioManager.hapticsEnabled: שדה סטטי + loadSettings() + setter
// ששומר ל-SharedPreferences.
import 'package:shared_preferences/shared_preferences.dart';

class GameSettings {
  GameSettings._();

  // "אישור לפני קניית רמז" - ברירת מחדל דלוקה (true), כדי להגן מראש על
  // מטבעות שמשתמשים חדשים לא התכוונו לבזבז (בדיוק התיאור במוקאפ: "שלא
  // תבזבזו מטבעות בטעות") - לא היה שום גיין כזה קודם, הרמז נחשף מיד
  // עם לחיצה.
  static bool hintConfirmEnabled = true;

  // "הצגת טיימר בשלבים" - כבוי כברירת מחדל (תוספת אופציונלית, לא כולם
  // רוצים לחוש "נמדדים" בכל חידה) - מציג שניות שחלפו על החידה הנוכחית
  // בכותרת logo_level_screen.dart (ראו _restartLevelTimer שם).
  static bool levelTimerEnabled = false;

  // "מעבר אוטומטי ללוגו הבא" - כבוי כברירת מחדל (שינוי ניווט אוטומטי
  // צריך להיות opt-in) - כשדלוק, כפתור "לשלב הבא" בדיאלוג התוצאה סופר
  // לאחור ומתקדם לבד (ראו _AutoAdvanceButton ב-logo_level_screen.dart).
  static bool autoAdvanceEnabled = false;

  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hintConfirmEnabled = prefs.getBool('hintConfirmEnabled') ?? true;
      levelTimerEnabled = prefs.getBool('levelTimerEnabled') ?? false;
      autoAdvanceEnabled = prefs.getBool('autoAdvanceEnabled') ?? false;
    } catch (_) {}
  }

  static Future<void> setHintConfirmEnabled(bool value) async {
    hintConfirmEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hintConfirmEnabled', value);
    } catch (_) {}
  }

  static Future<void> setLevelTimerEnabled(bool value) async {
    levelTimerEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('levelTimerEnabled', value);
    } catch (_) {}
  }

  static Future<void> setAutoAdvanceEnabled(bool value) async {
    autoAdvanceEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoAdvanceEnabled', value);
    } catch (_) {}
  }
}
