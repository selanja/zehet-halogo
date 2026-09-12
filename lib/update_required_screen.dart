// update_required_screen.dart
// מסך חסימה מלא שמוצג כשהגרסה המותקנת נמוכה מ-minVersion שהוגדר מרחוק
// ב-Firestore (ראה update_checker.dart). המשתמש לא יכול לעקוף את המסך -
// אין כפתור "חזור"/"דלג", וגם לחיצת "אחורה" בטלפון לא סוגרת אותו
// (בזכות ה-PopScope עם canPop: false).
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'app_background.dart'; // 🆕 עיצוב מחדש - אותו רקע גרדיאנט משותף כמו כל שאר האפליקציה

class UpdateRequiredScreen extends StatelessWidget {
  final String message;
  final String storeUrlAndroid;
  final String storeUrlIos;
  // 🆕 עיצוב מחדש - "גרסה X · נדרשת Y" בתחתית (לפי המוקאפ, מסך 13) -
  // אופציונליים כדי לא לשבור קריאות ישנות שעדיין לא מעבירות אותם.
  final String currentVersion;
  final String minVersion;

  const UpdateRequiredScreen({
    super.key,
    required this.message,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
    this.currentVersion = '',
    this.minVersion = '',
  });

  String get _storeUrl {
    try {
      if (Platform.isIOS) return storeUrlIos;
      return storeUrlAndroid;
    } catch (_) {
      return storeUrlAndroid;
    }
  }

  Future<void> _openStore() async {
    final url = _storeUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🆕 עיצוב מחדש - ריבוע גרדיאנט תכלת עם חץ למעלה, במקום
                    // עיגול צהוב, לפי המוקאפ (מסך 13 · עדכון נדרש).
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                        boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), blurRadius: 32)],
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF0C2A3D),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "יש גרסה חדשה",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _openStore,
                            child: const Center(
                              child: Text(
                                "עדכן עכשיו",
                                style: TextStyle(color: Color(0xFF0C2A3D), fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (currentVersion.isNotEmpty && minVersion.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        "גרסה $currentVersion · נדרשת $minVersion",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}