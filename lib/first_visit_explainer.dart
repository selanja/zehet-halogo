// first_visit_explainer.dart
//
// 🆕 "הסבר במשימות, בחברים, במובילים ובהכול - שיופיע רק ברגע שלוחצים על
// הדף הזה בפעם הראשונה וזהו" - מנגנון גנרי משותף (לא קשור לסיור במסך
// הבית/להדרכה בתוך המשחק - אלה שרשרת נפרדת, ראו onboarding_service.dart)
// שכל מסך יכול להשתמש בו בנפרד: דגל SharedPreferences ייחודי למסך
// ("seenExplainer_<key>"), ועיצוב כרטיסיה אחידה (אותה שפה עיצובית כמו
// _buildOnboardingIntroOverlay ב-play_vs_person_mode_screen.dart).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_manager.dart';
import 'l10n/app_localizations.dart';

class FirstVisitExplainer {
  FirstVisitExplainer._();

  // 🩹 תוקן לפי בקשה מפורשת: "אם הבנאדם כבר שיחק במשחק ועכשיו עושה
  // עדכון... שלא יהיה לו מדריך" - *אבל* "משתמש חדש" (אורח עם שם חדש)
  // כן אמור לקבל אותו תמיד (ראו _saveWelcomeName ב-main_menu_screen.dart).
  // הבעיה: maxLevel/xp הם גלובליים למכשיר, לא לכל "שם" בנפרד - בדיקה
  // לפי "האם יש בכלל התקדמות על המכשיר" הייתה שוברת בדיוק את "משתמש
  // חדש תמיד מקבל הדרכה" (מכשיר/אמולטור שכבר שימש לבדיקות "נראה" כאילו
  // יש לו תמיד התקדמות, גם למשתמש חדש לגמרי). הפתרון הנכון: הגירה
  // *חד-פעמית* ממש - נבדקת פעם אחת בלבד לכל התקנה, ברגע שהעדכון הזה
  // (עם ההדרכות החדשות) עולה לראשונה: אם כבר הייתה התקדמות אמיתית
  // *באותו רגע*, כל ההסברים מסומנים כ"כבר נראו" פעם אחת. אחרי ההגירה
  // החד-פעמית הזו, כל "משתמש חדש" עתידי (_saveWelcomeName) חוזר לאפס
  // את הדגלים ועובד כרגיל - בלי שהגלובליות של maxLevel תפריע יותר.
  static Future<void> migrateExistingPlayersOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('onboardingMigrationDone') ?? false) return;
    await prefs.setBool('onboardingMigrationDone', true);
    final hasRealProgress = prefs.containsKey('maxLevel') || (prefs.getInt('xp') ?? 0) > 0;
    if (!hasRealProgress) return;
    for (final key in ['missions', 'friends', 'leaderboard', 'soloLevel', 'playVsPerson', 'levels', 'subLevels']) {
      await prefs.setBool('seenExplainer_$key', true);
    }
  }

  static Future<bool> shouldShow(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('seenExplainer_$screenKey') ?? false);
  }

  static Future<void> markSeen(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenExplainer_$screenKey', true);
  }
}

/// נקודה אחת בהסבר (אימוג'י + כותרת קצרה + תיאור).
class ExplainerPoint {
  final String emoji;
  final String title;
  final String desc;
  const ExplainerPoint(this.emoji, this.title, this.desc);
}

/// כרטיסיית הסבר מלאה-מסך (הדהוי כהה + כרטיס לבן ממורכז) - מוסיפים
/// כ-child אחרון בתוך ה-Stack הראשי של כל מסך (אחרי AppBottomNav).
Widget buildFirstVisitOverlay({
  required BuildContext context,
  required String title,
  required List<ExplainerPoint> points,
  required VoidCallback onDismiss,
  String? buttonLabel,
}) {
  buttonLabel ??= AppLocalizations.of(context)!.explainerGotItButton;
  return Positioned.fill(
    child: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < points.length; i++) ...[
                    _explainerRow(points[i]),
                    if (i < points.length - 1) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        AudioManager.playClick();
                        onDismiss();
                      },
                      child: Text(buttonLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _explainerRow(ExplainerPoint p) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(p.emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 14.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(p.desc, style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
          ],
        ),
      ),
    ],
  );
}
