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
import 'ads_manager.dart'; // 🆕 מונה "גלישה בלי לשחק"
import 'duel_service.dart'; // 🆕 עיצוב מחדש - מספר ניצחונות לכרטיס הפרופיל
import 'notification_manager.dart'; // 🆕 מתג "התראות" - שולט על תזכורת בונוס המטבעות
import 'push_notification_service.dart'; // 🩹 אותה הרשאת מערכת כמו Local Notifications - ראו ההסבר ליד onTap של המתג
import 'review_manager.dart'; // 🆕 "דרג אותנו" - פותח את דף האפליקציה בחנות
import 'account_service.dart'; // 🆕 קישור חשבון Google/Apple + מחיקת משתמש
import 'account_link_prompt.dart'; // 🆕 אותו דיאלוג קישור חשבון שמוצג גם מהבית
import 'app_notification.dart';
import 'update_notes_screen.dart'; // 🆕 "מה חדש במשחק" - הערות עדכון מ-Firestore
import 'package:package_info_plus/package_info_plus.dart'; // 🩹 מספר הגרסה בתחתית המסך נשלף אמיתי, לא מוקלד ידנית (היה נתקע ישן בכל עדכון)
import 'friend_service.dart'; // 🆕 הקוד האישי - לבניית קישור ההזמנה האמיתי
import 'referral_service.dart'; // 🩹 קישור ההזמנה האמיתי (עם הקוד מוטמע) + סכום הבונוס האמיתי

class SettingsScreen extends StatefulWidget {
  final String username;
  const SettingsScreen({super.key, required this.username});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _supportEmail = "zehet.halogo@gmail.com";
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

  // 🎨 עוצב מחדש לפי מוקאפ HTML שנשלח במפורש ("אני רוצה שההגדרות יראו
  // ככה בדיוק") - כרטיס פרופיל אחד (גרדיאנט סגול + אווטאר/שם/XP/כפתור
  // שינוי שם + 3 סטטיסטיקות בפנים), כרטיס סאונד (מחוונים + צ'יפים לרטט/
  // התראות), כרטיס רשימה מאוחד (חברים/איך משחקים/חשבון), וקישורי
  // פוטר פשוטים (מה חדש/תקלה/פרטיות/דירוג + מחיקת משתמש/גרסה). כל
  // הלוגיקה מתחת (דיאלוגים/handlers) נשארה זהה - רק העיצוב/הפריסה השתנו.
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildSoundCard(),
                const SizedBox(height: 14),
                _buildListCard(),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _footerLink("מה חדש", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateNotesScreen()))),
                    _footerLink("דיווח על תקלה", _contactSupport),
                    _footerLink("פרטיות", () => _openLink("https://sites.google.com/view/zehet-halogo-privacy")),
                    _footerLink("דרגו אותנו", () => ReviewManager.requestNativeReview()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    GestureDetector(
                      onTap: _confirmDeleteAccount,
                      child: const Text("מחיקת משתמש", textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xBFFB7185), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 20),
                    Text(_version.isEmpty ? "" : "גרסה $_version", style: TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        const SizedBox(width: 40),
        const Expanded(
          child: Center(
            child: Text("הגדרות", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ),
        ),
        _RoundIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5, fontWeight: FontWeight.w700)),
    );
  }

  // 🎨 כרטיס פרופיל יחיד לפי המוקאפ: גרדיאנט סגול, אווטאר עגול (טבעת
  // לבנה + תג עריכה ✏️) + שם/XP + כפתור "שנה שם", קו מפריד, ומתחתיו
  // 3 סטטיסטיקות (רצף/לוגואים/ניצחונות) - הכול בתוך כרטיס אחד.
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(colors: [Color(0xFF6B3FD6), Color(0xFF4E25A8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF14083C).withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        alignment: Alignment.center,
                        child: Text(
                          _username.trim().isNotEmpty ? _username.trim().substring(0, 1) : '?',
                          style: const TextStyle(color: Color(0xFF2A1740), fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2A1740), border: Border.all(color: Colors.white, width: 2)),
                        alignment: Alignment.center,
                        child: const Text('✏️', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  // 🐛 תוקן לפי בקשה מפורשת: "שהשם יהיה צמוד ללוגו שלו" -
                  // CrossAxisAlignment.start התיישר לפי ה-Directionality
                  // האמיתית של המסך (LTR בפועל, ראו התיקון המקביל בשורת
                  // הסטטיסטיקות למעלה) - כלומר לשמאל, רחוק מהאווטאר
                  // שיושב מימין (ה-Row כולו RTL). .end מיישר לימין, צמוד
                  // לאווטאר, כמו שצריך.
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_username, textDirection: TextDirection.ltr, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text("$_xp XP", textDirection: TextDirection.ltr, textAlign: TextAlign.right, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showChangeNameDialog,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    child: Text("שנה שם", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2)))),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _profileStat(emoji: '🔥', value: '$_streak', label: 'רצף', color: const Color(0xFFFDBA74))),
                Expanded(child: _profileStat(emoji: '🧩', value: '$_logosSolved', label: 'לוגואים', color: const Color(0xFFA5F3FC))),
                Expanded(child: _profileStat(emoji: '🏆', value: _wins == null ? '—' : '$_wins', label: 'ניצחונות', color: const Color(0xFFFFD86B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStat({required String emoji, required String value, required String label, required Color color}) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 🎨 כרטיס סאונד לפי המוקאפ: שורת 2 מחוונים (אייקון בלבד, בלי טקסט/
  // אחוז נפרד - בדיוק כמו ב-HTML), ומתחתיה שורת 2 צ'יפים לרטט/התראות
  // (לא Switch) - "דלוק" = רקע/מסגרת כתומים וטקסט זהב, "כבוי" = אפור עמום.
  Widget _buildSoundCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06)),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _soundSlider(
                  icon: "🎵",
                  value: AudioManager.musicVolume,
                  onChanged: (v) {
                    setState(() {});
                    AudioManager.setMusicVolume(v);
                  },
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _soundSlider(
                  icon: "🔊",
                  value: AudioManager.sfxVolume,
                  onChanged: (v) {
                    setState(() {});
                    AudioManager.setSfxVolume(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _toggleChip(
                  icon: "📳",
                  label: "רטט",
                  value: AudioManager.hapticsEnabled,
                  onTap: () {
                    setState(() {});
                    AudioManager.setHapticsEnabled(!AudioManager.hapticsEnabled);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggleChip(
                  icon: "🔔",
                  label: "התראות",
                  value: NotificationManager.notificationsEnabled,
                  onTap: () {
                    final turningOn = !NotificationManager.notificationsEnabled;
                    setState(() {});
                    NotificationManager.setNotificationsEnabled(turningOn);
                    // 🩹 שתי מערכות נפרדות (Local Notifications + FCM/Push)
                    // חולקות את אותה הרשאת מערכת - ראו ההסבר ב-
                    // push_notification_service.dart. חייבים לבקש משתיהן
                    // כאן, לא רק מ-NotificationManager, אחרת ה-FCM token
                    // אף פעם לא יישמר למשתמש שהפעיל את המתג.
                    if (turningOn) PushNotificationService.requestPermissionAndRegister();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _soundSlider({required String icon, required double value, required ValueChanged<double> onChanged}) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(icon, style: const TextStyle(fontSize: 17)),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(value: value, activeColor: const Color(0xFFFFB24D), inactiveColor: Colors.white.withValues(alpha: 0.1), thumbColor: Colors.white, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _toggleChip({required String icon, required String label, required bool value, required VoidCallback onTap}) {
    return Material(
      color: value ? const Color(0xFFFFB24D).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: value ? const Color(0xFFFFB24D).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 7),
              Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: value ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.55), fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // 🎨 כרטיס רשימה מאוחד לפי המוקאפ: שורות מחוברות (ללא רווח ביניהן),
  // קו מפריד דק, אייקון אימוג'י + טקסט + (אופציונלי) תגית פרס זהובה +
  // שברון. מחליף את _settingsRow/_iconSettingsRow הישנים (כרטיסיות
  // נפרדות עם מסגרת צבעונית) שלא תואמים יותר לעיצוב.
  Widget _buildListCard() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06)),
      child: Column(
        children: [
          _listRow(icon: "🤝", label: "הזמינו חברים", reward: "+${ReferralService.bonusCoins}", onTap: _inviteFriends),
          _divider(),
          _listRow(
            icon: "❓",
            label: "איך משחקים?",
            onTap: () => _showInfoDialog(
              "איך משחקים?",
              "בכל שלב יופיע לוגו מטושטש או חתוך. עליכם להקליד את השם המדויק באמצעות המקלדת למטה.\n\n"
              "🗺️ רמות ושלבים: מתקדמים לפי קטגוריות - כל פתרון פותח את השלב הבא. פתרון מוצלח מזכה ב-10 XP ו-2 מטבעות (כל רמז אות מוריד 1 XP, ופתרון המילה ברמז נותן 5 XP בלבד).\n\n"
              "🎲 אתגר רנדומלי: לוגו אקראי מכל הקטגוריות, בלי חזרות! כל פתרון נכון מגדיל את הרצף 🔥 ומוסיף בונוס XP (עד +5). הרצף נשמר גם כשיוצאים - ומתאפס רק אם טועים במילה.\n\n"
              "⚔️ דו-קרב 1 על 1: שני שחקנים מקבלים את אותם הלוגואים, הראשון שמסיים - מנצח. עולה אנרגיה (מתחדשת עם הזמן).\n\n"
              "💡 רמזים: חשיפת אות - 15 מטבעות, פתרון המילה - 60 מטבעות. נגמרו המטבעות? אפשר לצפות בפרסומת ולקבל רמז חינם!",
            ),
          ),
          _divider(),
          _buildAccountListRow(),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: Colors.white.withValues(alpha: 0.06));

  Widget _listRow({required String icon, required String label, String? reward, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(width: 24, child: Center(child: Text(icon, style: const TextStyle(fontSize: 18)))),
              const SizedBox(width: 13),
              Expanded(child: Text(label, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700))),
              if (reward != null) ...[
                Text(reward, textDirection: TextDirection.ltr, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.28), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 שורת "חשבון" - אם לא מקושר: כפתור "חבר חשבון" שפותח את אותו
  // דיאלוג המוצג גם מהבית (account_link_prompt.dart). אם כבר מקושר:
  // מציג איזה ספק מחובר (Google/Apple) עם וי ירוק - לוחצים כדי להתנתק.
  Widget _buildAccountListRow() {
    final label = _linkedLabel;
    if (label != null) {
      // 🩹 תוקן: "לא רוצה שיהיה רשום את האימייל... פשוט Apple עם וי
      // ירוק ומתחת Google, כל אחד עם וי ירוק רק אם הוא מחובר בפועל".
      // הבדיקה היא לפי providerData האמיתי של Firebase Auth
      // (AccountService.linkedProviderIds), לא לפי ניחוש מהאימייל.
      final providers = AccountService.linkedProviderIds;
      final names = [
        if (providers.contains('apple.com')) 'Apple',
        if (providers.contains('google.com')) 'Google',
      ];
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _confirmSignOutLinked,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const SizedBox(width: 24, child: Center(child: Text("🔗", style: TextStyle(fontSize: 18)))),
                const SizedBox(width: 13),
                Expanded(child: Text("מחובר - ${names.join(' · ')}", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700))),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF3DDC84), size: 18),
              ],
            ),
          ),
        ),
      );
    }
    return _listRow(
      icon: "🔗",
      label: "חיבור חשבון",
      onTap: () async {
        await AccountLinkPrompt.show(context);
        if (mounted) await _loadProfileStats(); // מרענן את השורה אחרי קישור מוצלח
      },
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

  // 🐛 תוקן לפי בקשה מפורשת: "זה רושם +50 זה אמור להיות... עם הקישור
  // המיוחד שכולל את הקוד ככה שברגע שחבר נכנס הוא מקבל את המטבעות" -
  // קודם זה שלח קישור רגיל לחנות (בלי קוד מוטמע), כך ששום צד לא קיבל
  // מטבעות בפועל בהתקנה - בדיוק כמו "שתף קוד" ב-friends_screen.dart
  // לפני התיקון שם. עכשיו זה שולח את אותו קישור הזמנה אמיתי
  // (ReferralService.shareLink עם הקוד האישי מוטמע) שמזכה את שני
  // הצדדים אוטומטית כשהחבר מתקין ופותח את האפליקציה בפעם הראשונה.
  Future<void> _inviteFriends() async {
    String? code;
    try {
      code = await FriendService.myCode();
    } catch (_) {}
    final String link = code != null ? ReferralService.shareLink(code) : _androidStoreLink;
    final String text =
        "בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n"
        "$link\n\n"
        "שנינו נקבל ${ReferralService.bonusCoins} מטבעות במתנה ברגע שתתקינו ✨";
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