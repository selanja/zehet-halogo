// account_link_prompt.dart
//
// 🆕 דיאלוג "שמור את ההתקדמות שלך" - "אני לא רוצש זה ימחק לשחקנים
// ששיחקו עכשיו את המשתמש, מבחינתי שהם נכנסים לאפליקציה זה יקפוץ להם
// שהם צריכים לחבר את החשבון". מוצג (לא חוסם, אפשר לסגור בקלות) לשחקן
// שעדיין לא קישר חשבון - כדי שידע שההתקדמות שלו לא תישמר אוטומטית אם
// יחליף מכשיר, אלא אם יקשר חשבון. לא מוחק ולא נוגע בשום התקדמות בעצמו -
// כל הלוגיקה האמיתית ב-account_service.dart.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart';
import 'account_conflict_dialog.dart';
import 'app_notification.dart';

class AccountLinkPrompt {
  /// מציג את הדיאלוג רק אם: (א) המכשיר עדיין לא מקושר, ו-(ב) השחקן לא
  /// ביקש בעבר "אל תזכיר לי שוב". קריאה בטוחה מכל מקום - לא זורקת שגיאה.
  static Future<void> maybeShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('linkedUid') != null) return;
      if (prefs.getBool('hideLinkAccountPrompt') == true) return;
      if (!context.mounted) return;
      await show(context);
    } catch (_) {}
  }

  /// מציג את אותו דיאלוג תמיד, בלי לבדוק "אל תזכיר לי שוב" - לפעולה
  /// יזומה מפורשת (למשל כפתור "חבר חשבון" במסך ההגדרות).
  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _AccountLinkDialog(),
    );
  }
}

class _AccountLinkDialog extends StatefulWidget {
  const _AccountLinkDialog();

  @override
  State<_AccountLinkDialog> createState() => _AccountLinkDialogState();
}

class _AccountLinkDialogState extends State<_AccountLinkDialog> {
  bool _loading = false;

  Future<void> _handle(Future<LinkResult> Function() signIn) async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await signIn();
    if (!mounted) return;
    // 🆕 נמצאה התקדמות שמורה קיימת לחשבון הזה - שואלים את המשתמש לאיזו
    // התקדמות להתחבר (ראו account_conflict_dialog.dart), במקום לדרוס
    // אוטומטית כמו קודם.
    if (result == LinkResult.conflict) {
      final linked = await showAccountConflictDialog(context);
      if (!mounted) return;
      setState(() => _loading = false);
      if (linked) {
        Navigator.of(context).pop();
        AppNotification.show(context, "החשבון קושר בהצלחה! ההתקדמות שלך שמורה", type: AppNotificationType.success);
      }
      return;
    }
    setState(() => _loading = false);
    if (result == LinkResult.success) {
      Navigator.of(context).pop();
      AppNotification.show(context, "החשבון קושר בהצלחה! ההתקדמות שלך שמורה", type: AppNotificationType.success);
    } else if (result == LinkResult.error) {
      AppNotification.show(context, "החיבור נכשל, נסה שוב מאוחר יותר", type: AppNotificationType.error);
    }
  }

  Future<void> _dontShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideLinkAccountPrompt', true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A2668), Color(0xFF1D0E3C)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
              ),
              child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF0C2A3D), size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              "שמור את ההתקדמות שלך",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white, fontSize: 18.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "חבר חשבון Google או Apple - כך אם תחליף טלפון, כל המטבעות וההתקדמות שלך יישמרו ויחכו לך.",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: CircularProgressIndicator(color: Color(0xFFFFD86B)))
            else ...[
              _providerButton(
                label: "המשך עם Google",
                icon: Icons.g_mobiledata_rounded,
                colors: const [Color(0xFFFFFFFF), Color(0xFFE8E8E8)],
                textColor: const Color(0xFF2A1740),
                onTap: () => _handle(AccountService.signInWithGoogle),
              ),
              if (AccountService.appleAvailable) ...[
                const SizedBox(height: 10),
                _providerButton(
                  label: "המשך עם Apple",
                  icon: Icons.apple_rounded,
                  colors: const [Color(0xFF2A2A2A), Color(0xFF000000)],
                  textColor: Colors.white,
                  onTap: () => _handle(AccountService.signInWithApple),
                ),
              ],
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text("אחר כך", style: TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: _loading ? null : _dontShowAgain,
              child: Text("אל תזכיר לי שוב", style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}