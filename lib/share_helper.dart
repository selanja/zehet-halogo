// share_helper.dart
//
// 🐛 תוקן: "באייפון שיתוף כותב שאי אפשר לשתף ועושה רק העתק להודעה" - כל
// קריאות ה-Share.share() באפליקציה קראו לפונקציה בלי sharePositionOrigin.
// ב-iOS, תפריט השיתוף הוא popover שחייב "נקודת עיגון" על המסך כדי לדעת
// מאיפה לצאת - בלעדיה הקריאה יכולה להיכשל (זורקת שגיאה, נתפסת ע"י ה-
// catch הקיים, ומציגה את הודעת הגיבוי "לא נמצאה אפליקציית שיתוף... אפשר
// להעתיק ולשלוח ידנית" - בדיוק התסמין שדווח). באנדרואיד זה פרמטר שקוף
// לגמרי שלא משנה שום דבר - בטוח להוסיף אותו בכל מקום, לא רק בשביל iOS.
//
// שימוש: shareText(context, text, subject: "...") במקום Share.share(...)
// ישירות - מחשב את מיקום הכפתור שנלחץ (context הנוכחי) ומעביר אותו הלאה.
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'app_notification.dart';

Future<void> shareText(BuildContext context, String text, {String? subject}) async {
  try {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
    await Share.share(text, subject: subject, sharePositionOrigin: origin);
  } catch (_) {
    if (context.mounted) {
      AppNotification.show(context, "לא נמצאה אפליקציית שיתוף. אפשר להעתיק ולשלוח ידנית:\n$text", duration: const Duration(seconds: 5));
    }
  }
}
