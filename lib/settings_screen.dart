// settings_screen.dart
//
// מסך "הגדרות" ייעודי - הועבר לכאן מתוך דיאלוג ההגדרות הישן שהיה במסך
// הבית (עוצמת מוזיקה/אפקטים, שינוי שם), בעקבות המעבר לתפריט תחתון עם
// 5 טאבים (חנות/מובילים/שחק/משימות/הגדרות). גם "הזמינו חברים" ו"איך
// משחקים" - שהיו כרטיסים נפרדים במסך הבית - עברו לכאן, כי במבנה
// החדש אין להם "בית" אחר על מסך הבית המצומצם.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'app_background.dart';
import 'audio_manager.dart';
import 'leaderboard.dart';
import 'device_id.dart';
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון משותף - גם כאן, לא רק במסך הבית
import 'ads_manager.dart'; // 🆕 מונה "גלישה בלי לשחק"
import 'duel_service.dart'; // 🆕 עיצוב מחדש - מספר ניצחונות לכרטיס הפרופיל
import 'notification_manager.dart'; // 🆕 מתג "התראות" - שולט על תזכורת בונוס המטבעות
import 'review_manager.dart'; // 🆕 "דרג אותנו" - פותח את דף האפליקציה בחנות
import 'account_service.dart'; // 🆕 קישור חשבון Google/Apple + מחיקת משתמש
import 'account_link_prompt.dart'; // 🆕 אותו דיאלוג קישור חשבון שמוצג גם מהבית
import 'app_notification.dart';
import 'update_notes_screen.dart'; // 🆕 "מה חדש במשחק" - הערות עדכון מ-Firestore
import 'package:package_info_plus/package_info_plus.dart'; // 🩹 מספר הגרסה בתחתית המסך נשלף אמיתי, לא מוקלד ידנית (היה נתקע ישן בכל עדכון)

class SettingsScreen extends StatefulWidget {
  final String username;
  const SettingsScreen({super.key, required this.username});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _supportEmail = "zehet.halogo@gmail.com";
  static const String _iosStoreLink = "https://apps.apple.com/au/app/%D7%96%D7%94%D7%94-%D7%90%D7%AA-%D7%94%D7%9C%D7%95%D7%92%D7%95/id6797976197";
  static const String _androidStoreLink = "https://play.google.com/store/apps/details?id=com.ofeksela.zehethalogo&hl=he";

  // 🆕 שם השחקן מנוהל כאן מקומית (ולא רק דרך widget.username) כדי
  // שהמסך יעדכן את עצמו מיד אחרי שינוי שם מוצלח, בלי תלות במסך שקרא לו.
  late String _username = widget.username;

  // 🆕 עיצוב מחדש - "הגדרות" הפך למסך "פרופיל והגדרות" ממוזג (לפי המוקאפ,
  // מסך 11), עם כרטיס פרופיל (אווטאר + סטטיסטיקות) בראש המסך, מעל כל
  // ההגדרות הקיימות שנשארו בדיוק כמו שהיו.
  int _xp = 0;
  int _streak = 0;
  int _logosSolved = 0; // 🆕 קירוב אמיתי ("maxLevel" - השלב הגבוה ביותר שנפתח במסע, עולה בדיוק פעם אחת לכל לוגו שנפתר בקמפיין)
  int? _wins; // null = עדיין טוען מ-Firestore
  String? _linkedLabel; // 🆕 null = לא מקושר לחשבון Google/Apple (ראו account_service.dart)

  // 🩹 תוקן: היה טקסט קבוע "גרסה 1.2.0" שנתקע ישן בכל עדכון (שכחנו
  // לעדכן אותו ידנית בגרסה האחרונה) - עכשיו נשלף אמיתי מ-PackageInfo.
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {}
  }

  Future<void> _loadProfileStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _xp = prefs.getInt('xp') ?? 0;
      _streak = prefs.getInt('bestRandomStreak') ?? 0;
      _logosSolved = prefs.getInt('maxLevel') ?? 1;
    });
    final deviceId = await DeviceId.get();
    final wins = await DuelService.getWins(deviceId);
    final linkedLabel = await AccountService.linkedLabel;
    if (!mounted) return;
    setState(() {
      _wins = wins;
      _linkedLabel = linkedLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🆕 עיצוב מחדש - "הפרופיל שלי" הפך לכרטיס-על יחיד (כותרת +
                // צ'ברון חזרה + תת-כרטיס פרופיל בפנים), בדיוק כמו במוקאפ
                // (מסך 11 · פרופיל והגדרות) - במקום סרגל עליון נפרד וכרטיס
                // פרופיל נפרד מתחתיו.
                _buildProfileHero(),
                const SizedBox(height: 14),
                _buildStatsRow(),
                const SizedBox(height: 22),
                _sectionLabel("סאונד"),
                const SizedBox(height: 10),
                // 🆕 עיצוב מחדש - שני המחוונים (מוזיקה/צלילים) עברו לכרטיס
                // בודד משותף (בדיוק כמו במוקאפ), במקום שני כרטיסים נפרדים.
                _buildSoundCard(),
                const SizedBox(height: 10),
                _toggleRow(
                  label: "רטט",
                  value: AudioManager.hapticsEnabled,
                  onChanged: (v) {
                    setState(() {});
                    AudioManager.setHapticsEnabled(v);
                  },
                ),
                const SizedBox(height: 10),
                _toggleRow(
                  label: "התראות",
                  value: NotificationManager.notificationsEnabled,
                  onChanged: (v) {
                    setState(() {});
                    NotificationManager.setNotificationsEnabled(v);
                  },
                ),
                const SizedBox(height: 22),
                _sectionLabel("עזרה ושיתוף"),
                const SizedBox(height: 10),
                _settingsRow(icon: "🤝", text: "הזמינו חברים", color: const Color(0xFFA7F3D0), onTap: _inviteFriends),
                const SizedBox(height: 10),
                _settingsRow(
                  icon: "❓",
                  text: "איך משחקים?",
                  color: const Color(0xFF93C5FD),
                  onTap: () => _showInfoDialog(
                    "איך משחקים?",
                    "בכל שלב יופיע לוגו מטושטש או חתוך. עליכם להקליד את השם המדויק באמצעות המקלדת למטה.\n\n"
                    "🗺️ רמות ושלבים: מתקדמים לפי קטגוריות - כל פתרון פותח את השלב הבא. פתרון מוצלח מזכה ב-10 XP ו-2 מטבעות (כל רמז אות מוריד 1 XP, ופתרון המילה ברמז נותן 5 XP בלבד).\n\n"
                    "🎲 אתגר רנדומלי: לוגו אקראי מכל הקטגוריות, בלי חזרות! כל פתרון נכון מגדיל את הרצף 🔥 ומוסיף בונוס XP (עד +5). הרצף נשמר גם כשיוצאים - ומתאפס רק אם טועים במילה.\n\n"
                    "⚔️ דו-קרב 1 על 1: שני שחקנים מקבלים את אותם הלוגואים, הראשון שמסיים - מנצח. עולה אנרגיה (מתחדשת עם הזמן).\n\n"
                    "💡 רמזים: חשיפת אות - 15 מטבעות, פתרון המילה - 60 מטבעות. נגמרו המטבעות? אפשר לצפות בפרסומת ולקבל רמז חינם!",
                  ),
                ),
                const SizedBox(height: 10),
                _iconSettingsRow(
                  icon: Icons.campaign_rounded,
                  text: "מה חדש במשחק",
                  color: const Color(0xFFFFD86B),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateNotesScreen())),
                ),
                const SizedBox(height: 22),
                // 🆕 "חשבון" - קישור ל-Google/Apple כדי שההתקדמות תישמר
                // גם אם מחליפים מכשיר, ומחיקת משתמש - לפי בקשה מפורשת.
                _sectionLabel("חשבון"),
                const SizedBox(height: 10),
                _buildAccountRow(),
                const SizedBox(height: 10),
                _iconSettingsRow(
                  icon: Icons.delete_forever_rounded,
                  text: "מחק משתמש",
                  color: const Color(0xFFFF6B6B),
                  onTap: _confirmDeleteAccount,
                ),
                const SizedBox(height: 22),
                // ===== 🆕 "דיווח על תקלה" - שורה בולטת בתחתית, בדיוק כמו
                // במוקאפ (עיצוב זהה לשורות למעלה, אבל בפני עצמה תחת רווח
                // גדול יותר - כדי שתבלוט כפעולה "אחרונה"/נפרדת). =====
                _settingsRow(icon: "🐞", text: "דיווח על תקלה", color: const Color(0xFFFDA4AF), onTap: _contactSupport),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    TextButton(
                      onPressed: () => _openLink("https://sites.google.com/view/zehet-halogo-privacy"),
                      child: Text("פרטיות", style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5)),
                    ),
                    Text("·", style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12.5)),
                    TextButton(
                      onPressed: () => ReviewManager.requestNativeReview(),
                      child: Text("דרג אותנו", style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5)),
                    ),
                  ],
                ),
                Center(
                  child: Text(_version.isEmpty ? "© כל הזכויות שמורות" : "גרסה $_version · © כל הזכויות שמורות", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
        // 🆕 "הגדרות" הפך למסך משני שנפתח מאייקון גלגל-שיניים בבית (לא
        // עוד טאב עצמאי בסרגל) - current: home כאן רק כדי שהתנהגות
        // הניווט (push/pushReplacement) תישאר תקינה, לא בגלל שזה באמת
        // מסך הבית.
        AppBottomNav(current: AppTab.home),
          ],
        ),
      ),
    );
  }

  // 🆕 עיצוב מחדש - "כרטיס-על" יחיד שמאחד את מה שהיה קודם סרגל עליון +
  // כרטיס פרופיל נפרד: כותרת "הפרופיל שלי" + כפתור חזרה עגול בפנים,
  // ומתחתיה תת-כרטיס עם אווטאר/שם/XP וכפתור "שנה שם" - בדיוק לפי
  // המוקאפ (מסך 11 · פרופיל והגדרות).
  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF4A3583), Color(0xFF241154)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _RoundIconButton(icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pop(context)),
              const Expanded(
                child: Center(
                  child: Text("הפרופיל שלי", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.07)),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)])),
                  alignment: Alignment.center,
                  child: Text(
                    _username.trim().isNotEmpty ? _username.trim().substring(0, 1) : '?',
                    style: const TextStyle(color: Color(0xFF2A1740), fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_username, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text("$_xp XP", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _showChangeNameDialog,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text("שנה שם", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 עיצוב מחדש - שלוש "גלולות" סטטיסטיקה בשורה נפרדת מתחת לכרטיס-העל
  // (רצף/לוגואים שנפתרו/ניצחונות), בדיוק כמו במוקאפ - במקום שתי
  // סטטיסטיקות בתוך כרטיס הפרופיל עצמו.
  Widget _buildStatsRow() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(child: _profileStat(emoji: '🔥', value: '$_streak', label: 'רצף', color: const Color(0xFF5B3350))),
        const SizedBox(width: 8),
        Expanded(child: _profileStat(emoji: '🧩', value: '$_logosSolved', label: 'לוגואים', color: const Color(0xFF223B66))),
        const SizedBox(width: 8),
        Expanded(child: _profileStat(emoji: '🏆', value: _wins == null ? '—' : '$_wins', label: 'ניצחונות', color: const Color(0xFF4A2E5C))),
      ],
    );
  }

  Widget _profileStat({required String emoji, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text('$label $emoji', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w800));
  }

  // 🆕 עיצוב מחדש - שני המחוונים (מוזיקה/צלילים) בכרטיס בודד משותף,
  // בדיוק כמו במוקאפ (מסך 11), במקום שני כרטיסים נפרדים.
  Widget _buildSoundCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.09)), color: Colors.white.withValues(alpha: 0.05)),
      child: Column(
        children: [
          _soundSliderRow(
            label: "מוזיקה 🎵",
            value: AudioManager.musicVolume,
            activeColor: const Color(0xFFFFD86B),
            onChanged: (v) {
              setState(() {});
              AudioManager.setMusicVolume(v);
            },
          ),
          const SizedBox(height: 6),
          _soundSliderRow(
            label: "צלילים 🔊",
            value: AudioManager.sfxVolume,
            activeColor: const Color(0xFF7DD3FC),
            onChanged: (v) {
              setState(() {});
              AudioManager.setSfxVolume(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _soundSliderRow({required String label, required double value, required Color activeColor, required ValueChanged<double> onChanged}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(label, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
            Text("${(value * 100).round()}%", style: TextStyle(color: activeColor, fontSize: 12.5, fontWeight: FontWeight.w900)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 5),
          child: Slider(value: value, activeColor: activeColor, inactiveColor: Colors.white.withValues(alpha: 0.14), onChanged: onChanged),
        ),
      ],
    );
  }

  // 🆕 מתגי "רטט"/"התראות" - שורה בודדת עם Switch, בדיוק כמו במוקאפ.
  Widget _toggleRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.09)), color: Colors.white.withValues(alpha: 0.05)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(label, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
          Switch(value: value, activeThumbColor: const Color(0xFF34D399), onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _settingsRow({required String icon, required String text, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.5)), color: color.withValues(alpha: 0.1)),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(child: Text(text, textDirection: TextDirection.rtl, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w800))),
              Icon(Icons.chevron_left_rounded, color: color.withValues(alpha: 0.6), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 גרסה של _settingsRow עם אייקון וקטורי צבעוני (Icon) במקום אימוג'י -
  // לשורות חדשות שנוספו עכשיו (לא לשורות הישנות למעלה, שנשארות כמו שהן) -
  // כדי להימנע מבעיית אמינות אימוג'י מתועדת (ראו app_icons.dart).
  Widget _iconSettingsRow({required IconData icon, required String text, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.5)), color: color.withValues(alpha: 0.1)),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 10),
              Expanded(child: Text(text, textDirection: TextDirection.rtl, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w800))),
              Icon(Icons.chevron_left_rounded, color: color.withValues(alpha: 0.6), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 שורת "חשבון" - אם לא מקושר: כפתור "חבר חשבון" שפותח את אותו
  // דיאלוג המוצג גם מהבית (account_link_prompt.dart). אם כבר מקושר:
  // שורת מידע (לא לחיצה) שמציגה את המייל/Apple ID המקושר.
  Widget _buildAccountRow() {
    final label = _linkedLabel;
    if (label != null) {
      // 🩹 תוקן: "לא רוצה שיהיה רשום את האימייל (במיוחד אימייל-ריליי
      // מוזר וארוך של 'Hide My Email' באפל) - פשוט Apple עם וי ירוק
      // ומתחת Google, כל אחד עם וי ירוק רק אם הוא מחובר בפועל". הבדיקה
      // היא לפי providerData האמיתי של Firebase Auth (AccountService.
      // linkedProviderIds), לא לפי ניחוש מהאימייל.
      final providers = AccountService.linkedProviderIds;
      final appleLinked = providers.contains('apple.com');
      final googleLinked = providers.contains('google.com');
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _confirmSignOutLinked,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.4)),
              color: const Color(0xFF7DD3FC).withValues(alpha: 0.08),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _providerStatusRow(icon: Icons.apple_rounded, label: "Apple", connected: appleLinked),
                const SizedBox(height: 8),
                _providerStatusRow(icon: Icons.g_mobiledata_rounded, label: "Google", connected: googleLinked),
              ],
            ),
          ),
        ),
      );
    }
    return _iconSettingsRow(
      icon: Icons.link_rounded,
      text: "חבר חשבון (שומר את ההתקדמות)",
      color: const Color(0xFF7DD3FC),
      onTap: () async {
        await AccountLinkPrompt.show(context);
        if (mounted) await _loadProfileStats(); // מרענן את השורה אחרי קישור מוצלח
      },
    );
  }

  Widget _providerStatusRow({required IconData icon, required String label, required bool connected}) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        Icon(
          connected ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
          color: connected ? const Color(0xFF3DDC84) : Colors.white.withValues(alpha: 0.25),
          size: 17,
        ),
      ],
    );
  }

  // 🆕 "שיהיה אופציה להתנתק מהחשבון שהתחברתי אליו" - לוחצים על שורת
  // "מחובר: ..." בהגדרות כדי להתנתק (לא למחוק כלום, ראו AccountService.signOutLinked).
  Future<void> _confirmSignOutLinked() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        title: const Text("להתנתק מהחשבון?", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white)),
        content: const Text(
          "ההתקדמות הנוכחית שלך תישאר במכשיר הזה כרגיל. תוכל להתחבר שוב לאותו חשבון בכל עת.",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ביטול", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("התנתק", style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AccountService.signOutLinked();
    if (!mounted) return;
    await _loadProfileStats();
    if (mounted) AppNotification.show(context, "התנתקת מהחשבון", type: AppNotificationType.success);
  }

  // 🆕 "מחק משתמש" - אישור מפורש (פעולה סופית ובלתי הפיכה) לפני מחיקה
  // בפועל. עובד גם למי שלא מקושר לחשבון (מוחק רק את ההתקדמות המקומית),
  // וגם למקושר (מוחק גם את חשבון ה-Google/Apple המקושר) - ראו
  // account_service.dart.
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        title: const Text("למחוק את המשתמש?", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white)),
        content: const Text(
          "כל ההתקדמות שלך (מטבעות, XP, שלבים, רצפים) תימחק לצמיתות ולא ניתן יהיה לשחזר אותה. הפעולה סופית.",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ביטול", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("מחק לצמיתות", style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await AccountService.deleteAccount();
    if (!mounted) return;
    if (ok) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF241a4f),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
          content: const Text(
            "המשתמש נמחק. סגור ופתח מחדש את האפליקציה כדי להתחיל מחדש.",
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("הבנתי", style: TextStyle(color: Color(0xFFFFD86B))))],
        ),
      );
    } else {
      AppNotification.show(context, "המחיקה נכשלה, נסה שוב מאוחר יותר", type: AppNotificationType.error);
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        title: Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(child: Text(content, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white70))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("סגור", style: TextStyle(color: Color(0xFFFFD86B))))],
      ),
    );
  }

  Future<void> _inviteFriends() async {
    final String text =
        "בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n"
        "📱 אייפון: $_iosStoreLink\n"
        "🤖 אנדרואיד/גלקסי: $_androidStoreLink";
    try {
      // 🐛 תוקן: "באייפון שיתוף כותב שאי אפשר לשתף" - חסר sharePositionOrigin
      // (נקודת העיגון של ה-popover ב-iOS, ראו share_helper.dart להסבר המלא).
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(text, subject: "זהה את הלוגו!", sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null);
    } catch (_) {
      if (mounted) {
        AppNotification.show(context, "לא נמצאה אפליקציית שיתוף. אפשר להעתיק ולשלוח ידנית:\n$text", duration: const Duration(seconds: 5));
      }
    }
  }

  Future<void> _contactSupport() async {
    const String subject = "דיווח תקלה - זהה את הלוגו!";
    final String body = "היי!\n\nתיאור התקלה:\n\n\nמה עשיתי כשזה קרה:\n\n\n---\nהשם שלי במשחק: $_username";
    final Uri uri = Uri.parse("mailto:$_supportEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) _showMailError();
    } catch (_) {
      if (mounted) _showMailError();
    }
  }

  void _showMailError() {
    AppNotification.show(context, "לא נמצאה אפליקציית מייל. אפשר לכתוב לנו ידנית ל-$_supportEmail", duration: const Duration(seconds: 4));
  }

  // ✏️ שינוי שם - עצמאי לגמרי (לא תלוי במסך אחר) כדי שאפשר יהיה לפתוח
  // את מסך ההגדרות מכל טאב בסרגל התחתון, לא רק מהמסך הראשי. אותה בדיקת
  // זמינות אמיתית מול Firestore (LeaderboardService.isNameTaken) כמו
  // במסך ה"ברוכים הבאים!" הראשוני.
  void _showChangeNameDialog() {
    showDialog(
      context: context,
      builder: (context) => _ChangeNameDialog(
        currentName: _username,
        onSaved: (name) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', name);
          if (!mounted) return;
          setState(() => _username = name);
        },
      ),
    );
  }
}

enum _NameCheckStatus { idle, checking, available, taken }

// דיאלוג "שינוי שם" - שדה קלט + בדיקת זמינות אמיתית מול Firestore
// (debounce) + כפתור שמירה. גרסה מצומצמת/עצמאית של אותה לוגיקה בדיוק
// שקיימת ב-main_menu_screen.dart (_NameEntryCard) - כפולה בכוונה, כדי
// שמסך ההגדרות לא יהיה תלוי במסך אחר כדי לפעול.
class _ChangeNameDialog extends StatefulWidget {
  final String currentName;
  final Future<void> Function(String name) onSaved;
  const _ChangeNameDialog({required this.currentName, required this.onSaved});

  @override
  State<_ChangeNameDialog> createState() => _ChangeNameDialogState();
}

class _ChangeNameDialogState extends State<_ChangeNameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.currentName);
  Timer? _debounce;
  _NameCheckStatus _status = _NameCheckStatus.available; // השם הנוכחי כבר "פנוי" מבחינתנו
  bool _saving = false;
  String? _myDeviceId;

  @override
  void initState() {
    super.initState();
    AdsManager.recordBrowseNavigation(); // 🆕 "גלישה בלי לשחק"
    DeviceId.get().then((id) => _myDeviceId = id);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _status = _NameCheckStatus.idle);
      return;
    }
    if (trimmed == widget.currentName.trim()) {
      setState(() => _status = _NameCheckStatus.available);
      return;
    }
    setState(() => _status = _NameCheckStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final taken = await LeaderboardService.isNameTaken(trimmed, excludeDeviceId: _myDeviceId);
      if (!mounted) return;
      if (_controller.text.trim() != trimmed) return;
      setState(() => _status = taken ? _NameCheckStatus.taken : _NameCheckStatus.available);
    });
  }

  Future<void> _onConfirm() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _status == _NameCheckStatus.taken || _status == _NameCheckStatus.checking || _saving) return;
    setState(() => _saving = true);
    final taken = await LeaderboardService.isNameTaken(name, excludeDeviceId: _myDeviceId);
    if (!mounted) return;
    if (taken) {
      setState(() {
        _status = _NameCheckStatus.taken;
        _saving = false;
      });
      return;
    }
    await widget.onSaved(name);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.4), const Color(0xFFFFD86B).withValues(alpha: 0.18)]),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("שינוי שם", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text("איך נקרא לך בטבלה הארצית?", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(1.6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.15)]),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(21), color: const Color(0xFF170F38).withValues(alpha: 0.9)),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLength: 12,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          onChanged: _onChanged,
                          onSubmitted: (_) => _onConfirm(),
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(counterText: "", border: InputBorder.none, hintText: "הקלד את שמך כאן...", hintStyle: TextStyle(color: Colors.white30, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusPill(),
              const SizedBox(height: 18),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onConfirm,
                  borderRadius: BorderRadius.circular(21),
                  child: Opacity(
                    opacity: (_status == _NameCheckStatus.taken || _controller.text.trim().isEmpty) ? 0.45 : 1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2A1740)))
                            : const Text("שמור", style: TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    switch (_status) {
      case _NameCheckStatus.idle:
        return const SizedBox(height: 1);
      case _NameCheckStatus.checking:
        return _statusRow(
          icon: const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD86B))),
          text: "בודק זמינות...",
          textColor: Colors.white.withValues(alpha: 0.55),
          borderColor: Colors.white.withValues(alpha: 0.14),
          bgColor: Colors.white.withValues(alpha: 0.05),
        );
      case _NameCheckStatus.available:
        return _statusRow(
          icon: const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF6EE7B7)),
          text: "השם פנוי",
          textColor: const Color(0xFFA7F3D0),
          borderColor: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
          bgColor: const Color(0xFF34D399).withValues(alpha: 0.1),
        );
      case _NameCheckStatus.taken:
        return _statusRow(
          icon: const Icon(Icons.cancel_rounded, size: 15, color: Color(0xFFFB7185)),
          text: "השם הזה כבר תפוס, נסה שם אחר",
          textColor: const Color(0xFFFFC9D1),
          borderColor: const Color(0xFFFB7185).withValues(alpha: 0.4),
          bgColor: const Color(0xFFFB7185).withValues(alpha: 0.1),
        );
    }
  }

  Widget _statusRow({required Widget icon, required String text, required Color textColor, required Color borderColor, required Color bgColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor), color: bgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, color: Colors.white, size: 19))),
    );
  }
}