// locale_controller.dart
//
// שליטה גלובלית בשפת האפליקציה (עברית/אנגלית) - כולל תוכן השלבים.
// 🩹 בריצה ראשונה (אין העדפה שמורה) ברירת המחדל היא תמיד עברית - לפי
// בקשה מפורשת, לא נבחרת יותר שפת המכשיר ("נראה לי מוזר שחלק עברית חלק
// אנגלית" - למשל מדריך ההדרכה שעדיין לא תורגם במלואו, מול מסכים
// שכבר כן). אפשר לשנות בכל רגע ממסך ההגדרות, וההעדפה נשמרת
// ב-SharedPreferences לפתיחות הבאות.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'appLocale'; // 'he' | 'en'
  static const supportedLocales = [Locale('he'), Locale('en')];

  Locale _locale = const Locale('he');
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'he' || saved == 'en') {
      _locale = Locale(saved!);
    }
    // אין else - ללא העדפה שמורה נשאר _locale כברירת המחדל שלו (Locale('he') למעלה).
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  bool get isHebrew => _locale.languageCode == 'he';
}

final localeController = LocaleController();
