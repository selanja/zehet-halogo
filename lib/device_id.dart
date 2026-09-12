// device_id.dart
// מזהה אנונימי וייחודי לכל התקנה של המשחק, נוצר פעם אחת ונשמר לצמיתות
// במכשיר. משמש כדי להבחין בין שחקנים בטבלת השיאים - כולל שחקנים
// עם אותו שם משתמש בדיוק - בלי לדרוש התחברות עם חשבון גוגל ובלי
// לאסוף שום מידע מזהה אמיתי.
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static String? _cached;

  /// מחזיר את מזהה המכשיר; יוצר אחד חדש בפעם הראשונה בלבד.
  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('deviceId');
    if (id == null || id.isEmpty) {
      id = _generate();
      await prefs.setString('deviceId', id);
    }
    _cached = id;
    return id;
  }

  static String _generate() {
    final rand = Random.secure();
    final timePart = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(12, (_) => rand.nextInt(36).toRadixString(36)).join();
    return '$timePart$randomPart';
  }
}
