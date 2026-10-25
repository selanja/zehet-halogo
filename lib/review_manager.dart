// review_manager.dart
// ⭐ מציג פופאפ סגול "נהנים מהמשחק?" עם 5 כוכבים בפעם הראשונה שהשחקן
// לוחץ על כפתור "בית" (חזרה לתפריט הראשי) מתוך מסך משחק - זה הרגע
// שבו סביר שהוא כבר טעם קצת מהמשחק. מוצג פעם אחת בלבד לכל התקנה.
// הפונקציה handleHomeButtonTap משותפת בין logo_level_screen.dart
// ו-sub_levels_screen.dart, כך ששני מסכי ה"בית" מציגים בדיוק אותו דבר
// בלי כפילות קוד.
//
// לחיצה על "דרגו אותנו" פותחת את חלון הדירוג המובנה של החנות (App
// Store באייפון, Google Play באנדרואיד) בלי לצאת מהאפליקציה, דרך
// חבילת in_app_review.
// ⚠️ מגבלה של גוגל ואפל (לא שלנו): אי אפשר לדעת אם המשתמש באמת דירג -
// לכן פשוט פותחים את החלון ולא בודקים תוצאה.
//
// דורש הוספה ל-pubspec.yaml:
//   dependencies:
//     in_app_review: ^2.0.9
// ואז: flutter pub get
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'audio_manager.dart';
import 'l10n/app_localizations.dart';

class ReviewManager {
  static const String _askedKey = 'firstTimeRatingPromptShown';

  /// true אם עוד לא הצגנו את הפופאפ הזה אף פעם למכשיר הזה.
  static Future<bool> shouldShowFirstTimePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_askedKey) ?? false);
  }

  /// מסמן שהפופאפ כבר הוצג - נקרא מיד לפני שמציגים אותו, כדי שלא יופיע
  /// שוב גם אם המשתמש יסגור את האפליקציה באמצע.
  static Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }

  /// פותח את דף הדירוג בחנות.
  // 🐛 תוקן: requestReview() לא באמת "מבטיח" שום דבר - זו פונקציה
  // שנשלטת לגמרי על ידי גוגל/אפל ומוגבלת במכסה (quota) קבועה מראש
  // (בגוגל פליי בערך פעם-פעמיים בשנה למכשיר, ולפעמים אף פעם לא על
  // אפליקציה חדשה/לא מפורסמת עדיין) - לכן היא "לא עשתה כלום" בבדיקה.
  // openStoreListing לעומת זאת פותח ישירות את דף האפליקציה בחנות
  // (Play Store/App Store) עם כפתור הדירוג עליו - זה עובד תמיד, בלי
  // מכסה, ולכן זו הבחירה הנכונה כאן כשאנחנו יוזמים את הבקשה בעצמנו.
  static Future<void> requestNativeReview() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      await inAppReview.openStoreListing(
        appStoreId: "6797976197", // מזהה האפליקציה ב-App Store (מהקישור ששלחת)
        // ב-Android, אם לא מעבירים microsoftStoreId/appStoreId, החבילה
        // פותחת אוטומטית את חנות Google Play לפי ה-package name של
        // האפליקציה עצמה - אין צורך להעביר אותו ידנית.
      );
    } catch (_) {
      // נכשל בשקט (למשל בסימולטור) - לא קורסים בגלל זה
    }
  }

  /// הפונקציה שנקראת מכפתור "בית" - בודקת אם צריך להציג, מציגה אם כן,
  /// וממתינה שהדיאלוג ייסגר (בכל דרך) לפני שהמסך הקורא ממשיך לניווט
  /// חזרה לתפריט הראשי.
  static Future<void> handleHomeButtonTap(BuildContext context) async {
    final bool shouldShow = await shouldShowFirstTimePrompt();
    if (!shouldShow || !context.mounted) return;
    await markPromptShown();
    if (!context.mounted) return;
    await _showFirstTimeRatingPopup(context);
  }

  static Future<void> _showFirstTimeRatingPopup(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.4), const Color(0xFFB07CFF).withValues(alpha: 0.35)]),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Color(0xFF2E1065)],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFB24D).withValues(alpha: 0.5), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.emoji_emotions_rounded, color: Color(0xFF2A1740), size: 34),
                ),
                const SizedBox(height: 18),
                Text(loc.reviewPromptTitle, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  loc.reviewPromptBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(Icons.star_rounded, color: Color(0xFFFFD86B), size: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      AudioManager.playClick();
                      Navigator.pop(context);
                      requestNativeReview();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF8A3C)]),
                      ),
                      child: Text(
                        loc.reviewPromptRateButton,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    AudioManager.playClick();
                    Navigator.pop(context);
                  },
                  child: Text(loc.reviewPromptMaybeLaterButton, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}