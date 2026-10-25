// account_conflict_dialog.dart
//
// 🆕 דיאלוג "מצאנו לך חשבון קיים" - לפי בקשה מפורשת: "כשאדם שיחק
// באפליקציה והוא רוצה להתחבר עם הגוגל וכבר יש לו משתמש, אני רוצה
// שהמערכת תראה לו שהיה לו עוד משתמש, שיהיה רשום את הניקוד, איזה רמה
// והכול, וזה ישאל אותו לאיזה משתמש להתחבר".
//
// מוצג מיד אחרי AccountService.signInWithGoogle()/signInWithApple()
// מחזיר LinkResult.conflict - כלומר לחשבון שנבחר כבר יש התקדמות שמורה
// בענן (ממכשיר אחר), ולפני התיקון הזה היא הייתה נדרסת אוטומטית בלי
// שום שאלה. מציג את שתי ההתקדמויות זו לצד זו ונותן למשתמש לבחור.
//
// ⚠️ אין כאן תמיכה ב"כמה פרופילים תחת אותו חשבון" - הבחירה היא רק איזו
// משתי ההתקדמויות הקיימות נשארת (בדיוק כמו כל משחק סלולרי אחר: חשבון
// Google/Apple אחד = התקדמות שמורה אחת). הצד שלא נבחר פשוט נדרס.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart';
import 'app_icons.dart';
import 'l10n/app_localizations.dart';

/// מציג את הדיאלוג ומחזיר true אם המשתמש בחר (בכל אחת מהאפשרויות) ו-
/// ההתחברות הושלמה בפועל, false אם ביטל.
Future<bool> showAccountConflictDialog(BuildContext context) async {
  final conflict = AccountService.pendingConflict;
  if (conflict == null) return false;

  final prefs = await SharedPreferences.getInstance();
  final localCoins = prefs.getInt('coins') ?? 15;
  final localXp = prefs.getInt('xp') ?? 0;
  final localMaxLevel = prefs.getInt('maxLevel') ?? 1;

  if (!context.mounted) return false;
  final choice = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AccountConflictDialog(
      cloudCoins: conflict.coins,
      cloudXp: conflict.xp,
      cloudMaxLevel: conflict.maxLevel,
      localCoins: localCoins,
      localXp: localXp,
      localMaxLevel: localMaxLevel,
    ),
  );

  if (choice == null) {
    await AccountService.cancelSignInConflict();
    return false;
  }
  return AccountService.resolveSignInConflict(useCloudProgress: choice);
}

class _AccountConflictDialog extends StatelessWidget {
  final int cloudCoins, cloudXp, cloudMaxLevel;
  final int localCoins, localXp, localMaxLevel;
  const _AccountConflictDialog({
    required this.cloudCoins,
    required this.cloudXp,
    required this.cloudMaxLevel,
    required this.localCoins,
    required this.localXp,
    required this.localMaxLevel,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A2668), Color(0xFF1D0E3C)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF9A3C)]),
              ),
              child: const Icon(Icons.person_search_rounded, color: Color(0xFF40170F), size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              loc.accountConflictTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              loc.accountConflictMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
            ),
            const SizedBox(height: 18),
            _progressCard(
              title: loc.accountConflictCloudProgressTitle,
              coins: cloudCoins,
              xp: cloudXp,
              maxLevel: cloudMaxLevel,
              accent: const Color(0xFFFFD86B),
              loc: loc,
            ),
            const SizedBox(height: 10),
            _progressCard(
              title: loc.accountConflictLocalProgressTitle,
              coins: localCoins,
              xp: localXp,
              maxLevel: localMaxLevel,
              accent: const Color(0xFF7DD3FC),
              loc: loc,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD86B),
                  foregroundColor: const Color(0xFF40170F),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(loc.accountConflictUseCloudButton, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(loc.accountConflictUseLocalButton, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.accountConflictWarning,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(loc.accountConflictCancelButton, style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard({required String title, required int coins, required int xp, required int maxLevel, required Color accent, required AppLocalizations loc}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: accent, fontSize: 11.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statChip(icon: const CoinIcon(size: 15), label: "$coins"),
              _statChip(icon: const Icon(Icons.star_rounded, color: Color(0xFFFFD86B), size: 16), label: "$xp XP"),
              _statChip(icon: const Icon(Icons.flag_rounded, color: Color(0xFF7DD3FC), size: 16), label: loc.accountConflictLevelLabel(maxLevel)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({required Widget icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
