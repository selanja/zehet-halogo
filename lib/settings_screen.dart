// settings_screen.dart
//
// 🆕 עוצב מחדש לגמרי לפי מוקאפ HTML שנשלח במפורש (Settings.html) - מבנה
// טאבים (משחק/צליל/התראות/חשבון/עזרה) במקום רשימה שטוחה אחת. לפי בקשה
// מפורשת: "תעשה אותו באפליקציה + תוסיף את כל הפונקציות שיש שמה, אם יש
// לך משהו שאתה אומר שלא צריך/להוסיף תעשה ותעדכן" - חלק מהשורות
// במוקאפ קיבלו גיבוי אמיתי חדש (ראו ההערות ליד כל אחת), וכמה שורות
// הושמטו בכוונה כי אין להן שום דבר אמיתי מאחוריהן באפליקציה הזו:
//   - "הקראת שם הלוגו" (TTS) - דורש ספריית טקסט-לדיבור חדשה שלא קיימת
//     בפרויקט בכלל (לא flutter_tts ולא שום דבר דומה) - תוסף משמעותי,
//     לא רק מתג. לא הוספתי.
//   - "פחות אנימציות" - נבדק: אין אנימציית-רקע מרכזית אחת שאפשר לכבות
//     (AuroraBackground במסך הבית הוא סטטי לגמרי; TheFloatingMarks כבר
//     מת/לא בשימוש) - התנועה האמיתית מפוזרת בעשרות AnimationController
//     עצמאיים בכל האפליקציה. מתג "אמיתי" היה דורש לגעת בכל אחד מהם בנפרד.
//   - "הופעה בטבלה הארצית" / "הצגת סטטוס מחובר לחברים" / "קבלת בקשות
//     חברות" - כל אחד מהם דורש שינוי בלוגיקת שרת/Firestore משותפת
//     (LeaderboardService.submitScore, FriendService.touchPresence,
//     FriendService.sendFriendRequest) שמשפיעה על איך שחקנים *אחרים*
//     רואים אותך - לא רק UI מקומי. לא רציתי לשנות התנהגות משותפת כזו
//     בלי לוודא קודם שזה באמת מה שרצית.
//   - "חבר הזמין אותי לדו-קרב" ו"מבצעים בחנות" בטאב התראות - הראשונה
//     נשלחת מ-Cloud Function בשרת (functions/index.js), לא מהאפליקציה -
//     מתג מקומי לא היה משפיע עליה בפועל. השנייה לא קיימת כתכונה בכלל
//     (אין שום קוד ששולח התראת "מבצע בחנות").
//   - "תנאי שימוש" כקישור נפרד מ"פרטיות" - כבר הוסר בעבר במפורש
//     מ-shop_screen.dart כי "הצביע על placeholder שלא מחובר לשום דבר
//     אמיתי" (ראו ההערה שם) - לא רציתי להחזיר קישור מת.
//   - "ID #48213" ליד השם ו-"X/100 XP לרמה הבאה" - אין מערכת רמות-מ-XP
//     באפליקציה הזו בכלל (XP מוצג כמספר גולמי בלבד), ו"רמה" כבר תפוס
//     לגמרי למשמעות אחרת (עולם/שלב במצב "שלבים") - להמציא מערכת רמות
//     שנייה הייתה רק מבלבלת. גם אין שום "מזהה שחקן" קצר קיים - הקוד
//     האישי (6 תווים, ל-FriendService) כבר מוצג בבאנר ההזמנה ממש מתחת.
//
// כל מה שכן נשאר/נוסף - אמיתי לגמרי: סליידרים/רטט (AudioManager),
// התראות מפורקות לפי סוג (NotificationManager, כולל 3 מתגים חדשים
// שבאמת שולטים על תזמון ההתראות המתאימות ב-notification_service.dart),
// "אישור לפני קניית רמז"/"הצגת טיימר בשלבים"/"מעבר אוטומטי ללוגו הבא"
// (GameSettings, 3 מתגים חדשים שבאמת פועלים בתוך logo_level_screen.dart -
// דיאלוג אישור לפני שהמטבעות יורדות, טיימר אמיתי בכותרת, וכפתור "לשלב
// הבא" שבאמת סופר לאחור ומתקדם לבד), הסרת פרסומות/שחזור
// רכישות (IapManager, אותם מוצרים אמיתיים כמו בחנות), תצוגת הישגים
// מקדימה (AchievementsService), קוד הזמנה/בונוס אמיתיים (FriendService/
// ReferralService), ועקבו-אחרינו עם התגמול האמיתי (social_follow_popup.dart).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'app_background.dart';
import 'app_icons.dart';
import 'audio_manager.dart';
import 'leaderboard.dart';
import 'device_id.dart';
import 'ads_manager.dart'; // 🆕 מונה "גלישה בלי לשחק"
import 'duel_service.dart'; // 🆕 עיצוב מחדש - מספר ניצחונות לכרטיס הפרופיל
import 'notification_manager.dart'; // 🆕 מתגי התראות (כולל 3 תת-מתגים חדשים לפי סוג)
import 'push_notification_service.dart'; // 🩹 אותה הרשאת מערכת כמו Local Notifications - ראו ההסבר ליד onTap של המתג
import 'review_manager.dart'; // 🆕 "דרג אותנו" - פותח את דף האפליקציה בחנות
import 'account_service.dart'; // 🆕 קישור חשבון Google/Apple + מחיקת משתמש
import 'account_link_prompt.dart'; // 🆕 אותו דיאלוג קישור חשבון שמוצג גם מהבית
import 'app_notification.dart';
import 'update_notes_screen.dart'; // 🆕 "מה חדש במשחק" - הערות עדכון מ-Firestore
import 'package:package_info_plus/package_info_plus.dart'; // 🩹 מספר הגרסה בתחתית המסך נשלף אמיתי, לא מוקלד ידנית (היה נתקע ישן בכל עדכון)
import 'friend_service.dart'; // 🆕 הקוד האישי - לבניית קישור ההזמנה האמיתי + באנר הקוד
import 'referral_service.dart'; // 🩹 קישור ההזמנה האמיתי (עם הקוד מוטמע) + סכום הבונוס האמיתי
import 'locale_controller.dart'; // 🆕 שורת "שפת המשחק" - עברית/אנגלית לכל האפליקציה
import 'social_follow_popup.dart'; // 🆕 קישורי אינסטגרם/טיקטוק + התגמול האמיתי
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון משותף - "הגדרות" הוא עכשיו אחד מ-5 הטאבים הקבועים
import 'game_settings.dart'; // 🆕 "אישור לפני קניית רמז" - מתג חדש אמיתי
import 'achievements_service.dart'; // 🆕 תצוגת הישגים מקדימה בכרטיס הפרופיל
import 'achievements_screen.dart';
import 'iap_manager.dart'; // 🆕 הסרת פרסומות / שחזור רכישות - אותם מוצרים אמיתיים כמו בחנות
import 'l10n/app_localizations.dart';

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

  int _xp = 0;
  int _streak = 0;
  int _logosSolved = 0; // 🆕 קירוב אמיתי ("maxLevel" - השלב הגבוה ביותר שנפתח במסע, עולה בדיוק פעם אחת לכל לוגו שנפתר בקמפיין)
  int? _wins; // null = עדיין טוען מ-Firestore
  String? _linkedLabel; // 🆕 null = לא מקושר לחשבון Google/Apple (ראו account_service.dart)

  // 🆕 תצוגת הישגים מקדימה (AchievementsService, אמיתי) - 4 הישגים
  // ראשונים מתוך הרשימה האמיתית, עם מצב "הושג/נעול" אמיתי לכל אחד.
  int _medalsEarned = 0;
  List<bool> _previewEarnedFlags = const [false, false, false, false];

  // 🆕 קוד ההזמנה האישי האמיתי (FriendService.myCode) - מוצג בבאנר
  // "הזמינו חברים" במקום הקוד הבדוי שהיה במוקאפ.
  String _friendCode = '';

  // 🆕 הטאב הנבחר - "משחק"/"צליל"/"התראות"/"חשבון"/"עזרה", לפי המוקאפ.
  String _tab = 'game';

  // 🩹 תוקן: היה טקסט קבוע "גרסה 1.2.0" שנתקע ישן בכל עדכון (שכחנו
  // לעדכן אותו ידנית בגרסה האחרונה) - עכשיו נשלף אמיתי מ-PackageInfo.
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
    _loadVersion();
    _loadAchievementsPreview();
    _loadFriendCode();
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

  Future<void> _loadAchievementsPreview() async {
    final earned = await AchievementsService.earnedCount();
    final previewDefs = AchievementsService.all.take(4).toList();
    final flags = <bool>[];
    for (final a in previewDefs) {
      flags.add(await AchievementsService.progress(a.counter) >= a.goal);
    }
    if (!mounted) return;
    setState(() {
      _medalsEarned = earned;
      _previewEarnedFlags = flags;
    });
  }

  Future<void> _loadFriendCode() async {
    try {
      final code = await FriendService.myCode();
      if (mounted) setState(() => _friendCode = code);
    } catch (_) {}
  }

  // 🆕 "תואר" שחקן נגזר מהתקדמות אמיתית (maxLevel) - לא מערכת חדשה,
  // רק תיוג תיאורי לכמה לוגואים נפתרו עד כה (לא קשור ל"רמה/עולם" של
  // מצב שלבים, כדי לא ליצור בלבול מול המונח הקיים).
  String _rankTitle(AppLocalizations loc) {
    if (_logosSolved >= 301) return loc.settingsRankChampion;
    if (_logosSolved >= 101) return loc.settingsRankVeteran;
    if (_logosSolved >= 21) return loc.settingsRankIntermediate;
    return loc.settingsRankBeginner;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                // 🩹 תוקן לפי בקשה מפורשת ("המניו למטה... מופיעים מאחוריו
                // דברים") - ריפוד 128 קבוע לא כלל את MediaQuery.padding.bottom
                // (אזור הבטוח התחתון), בדיוק אותו באג שתוקן גם ב-
                // missions_screen.dart/shop_screen.dart.
                padding: EdgeInsets.fromLTRB(18, 10, 18, 128 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(loc),
                    const SizedBox(height: 16),
                    _buildProfileCard(loc),
                    const SizedBox(height: 12),
                    _buildInviteBanner(loc),
                    const SizedBox(height: 10),
                    _buildFollowRow(loc),
                    const SizedBox(height: 18),
                    _buildTabsRow(loc),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(_tabHint(loc), style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    _buildRowsCard(loc),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _version.isEmpty ? loc.settingsScreenTitle : "${loc.appLoadingTitle} · ${loc.settingsVersionLabel(_version)}",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppTab.settings),
          ],
        ),
      ),
    );
  }

  // 🩹 תוקן לפי המוקאפ: כפתור הסגירה עבר לצד ימין (ראשון ב-Row תחת RTL),
  // עם מרווח בלתי-נראה משמאל לאיזון סימטרי - בדיוק כמו ב-Settings.html.
  Widget _buildHeader(AppLocalizations loc) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
        Expanded(
          child: Center(
            child: Text(loc.settingsScreenTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }

  // 🎨 כרטיס פרופיל - אווטאר+שם/כפתור שינוי שם, תגית תואר (נגזר
  // מהתקדמות אמיתית), XP גולמי אמיתי (בלי "רמה" בדויה - ראו ההסבר בראש
  // הקובץ), קו מפריד, 3 סטטיסטיקות (רצף/לוגואים/ניצחונות - כולן היו
  // כבר קיימות), וקו מפריד נוסף + שורת תצוגת הישגים מקדימה אמיתית.
  Widget _buildProfileCard(AppLocalizations loc) {
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
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  // 🩹 מתיישר לפי ה-Directionality האמיתית של המסך (עכשיו
                  // מגיעה מהלוקאל של האפליקציה, לא קבועה) - CrossAxisAlignment.start
                  // מיישר צמוד לאווטאר (ימין ב-RTL, שמאל ב-LTR) בכל מקרה.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username, textDirection: TextDirection.ltr, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFA78BFA).withValues(alpha: 0.2)),
                          child: Text(_rankTitle(loc), style: const TextStyle(color: Color(0xFFDDD6FE), fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Directionality(textDirection: TextDirection.ltr, child: Text("$_xp XP", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showChangeNameDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    child: Text(loc.settingsChangeNameButton, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900)),
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
              children: [
                Expanded(child: _profileStat(emoji: '🔥', value: '$_streak', label: loc.leaderboardStreakLabel, color: const Color(0xFFFDBA74))),
                Expanded(child: _profileStat(emoji: '🧩', value: '$_logosSolved', label: loc.settingsLogosStatLabel, color: const Color(0xFFA5F3FC))),
                Expanded(child: _profileStat(emoji: '🏆', value: _wins == null ? '—' : '$_wins', label: loc.settingsWinsStatLabel, color: const Color(0xFFFFD86B))),
              ],
            ),
          ),
          _buildAchievementsPreview(loc),
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
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 🆕 תצוגה מקדימה של 4 הישגים ראשונים (מתוך AchievementsService.all
  // האמיתית) - "הושג" מגיע מ-AchievementsService.progress אמיתי, לא
  // משוער. לוחצים כדי לעבור למסך ההישגים המלא (כבר קיים, achievements_screen.dart).
  Widget _buildAchievementsPreview(AppLocalizations loc) {
    final previewDefs = AchievementsService.all.take(4).toList();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.settingsMyAchievementsLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('$_medalsEarned/${AchievementsService.all.length}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                      Icon(Icons.chevron_left_rounded, color: const Color(0xFFFFD86B).withValues(alpha: 0.8), size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(previewDefs.length, (i) {
              final earned = i < _previewEarnedFlags.length && _previewEarnedFlags[i];
              return Expanded(child: _achievementBadge(previewDefs[i], earned));
            }),
          ),
        ],
      ),
    );
  }

  Widget _achievementBadge(AchievementDef a, bool earned) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: earned ? const LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: earned ? null : Colors.white.withValues(alpha: 0.05),
            border: earned ? null : Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.4),
            boxShadow: earned ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 3))] : null,
          ),
          child: Opacity(opacity: earned ? 1 : 0.4, child: Text(a.medal, style: const TextStyle(fontSize: 19))),
        ),
        const SizedBox(height: 4),
        Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: earned ? 0.8 : 0.35), fontSize: 9.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 🆕 באנר "הזמינו חברים" - הועלה מתוך רשימת ההגדרות לבאנר בולט בראש
  // המסך, לפי המוקאפ. מציג את הקוד האישי האמיתי (FriendService.myCode)
  // והבונוס האמיתי (ReferralService.bonusCoins) - לא נתונים בדויים.
  Widget _buildInviteBanner(AppLocalizations loc) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _inviteFriends,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: const Color(0xFF065F46).withValues(alpha: 0.6), offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: Colors.white.withValues(alpha: 0.22)),
                child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.settingsInviteFriendsLabel, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(loc.settingsInviteCodeLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(_friendCode.isEmpty ? '···' : _friendCode, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('+${ReferralService.bonusCoins}', style: const TextStyle(color: Color(0xFF047857), fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 3),
                    const CoinIcon(size: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 שורת "עקבו אחרינו" - פותחת את אותו פופאפ אמיתי שכבר מטפל בכל
  // לוגיקת התביעה (cooldown/כבר נתבע וכו', ראו social_follow_popup.dart)
  // - לא נתיב ישיר לקישורים, כדי לא לעקוף את מנגנון התגמול האמיתי.
  Widget _buildFollowRow(AppLocalizations loc) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showSocialFollowPopup(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white.withValues(alpha: 0.06), border: Border.all(color: Colors.white.withValues(alpha: 0.09))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.settingsFollowUsLabel, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
                    Text(loc.settingsFollowRewardLabel(socialFollowCoinReward), style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _socialChip('Instagram', const [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)]),
              const SizedBox(width: 6),
              _socialChip('TikTok', const [Color(0xFF111111), Color(0xFF000000)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialChip(String label, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: LinearGradient(colors: gradient)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5)),
    );
  }

  // ===================== טאבים =====================

  static const List<_TabDef> _tabs = [
    _TabDef('game', Icons.sports_esports_rounded, Color(0xFF38BDF8)),
    _TabDef('sound', Icons.volume_up_rounded, Color(0xFFA78BFA)),
    _TabDef('notif', Icons.notifications_rounded, Color(0xFFFB7185)),
    _TabDef('account', Icons.person_rounded, Color(0xFF34D399)),
    _TabDef('help', Icons.chat_bubble_rounded, Color(0xFFFBBF24)),
  ];

  String _tabLabel(AppLocalizations loc, String id) {
    switch (id) {
      case 'game':
        return loc.settingsTabGame;
      case 'sound':
        return loc.settingsTabSound;
      case 'notif':
        return loc.settingsNotificationsLabel;
      case 'account':
        return loc.settingsTabAccount;
      default:
        return loc.settingsTabHelp;
    }
  }

  String _tabHint(AppLocalizations loc) {
    switch (_tab) {
      case 'game':
        return loc.settingsTabHintGame;
      case 'sound':
        return loc.settingsTabHintSound;
      case 'notif':
        return loc.settingsTabHintNotifications;
      case 'account':
        return loc.settingsTabHintAccount;
      default:
        return loc.settingsTabHintHelp;
    }
  }

  Widget _buildTabsRow(AppLocalizations loc) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final t = _tabs[i];
          final active = t.id == _tab;
          return Material(
            color: active ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                AudioManager.playClick();
                setState(() => _tab = t.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: active ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.1))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 15, color: active ? const Color(0xFF2A1740) : t.color.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(_tabLabel(loc, t.id), style: TextStyle(color: active ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.75), fontSize: 13.5, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== שורות (לפי טאב) =====================

  Widget _buildRowsCard(AppLocalizations loc) {
    final rows = _buildRowsForTab(loc);
    final children = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) children.add(_divider());
      children.add(rows[i]);
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06), border: Border.all(color: Colors.white.withValues(alpha: 0.09))),
      child: Column(children: children),
    );
  }

  List<Widget> _buildRowsForTab(AppLocalizations loc) {
    switch (_tab) {
      case 'game':
        return _gameRows(loc);
      case 'sound':
        return _soundRows(loc);
      case 'notif':
        return _notifRows(loc);
      case 'account':
        return _accountRows(loc);
      default:
        return _helpRows(loc);
    }
  }

  // --- משחק ---
  // 🩹 "פחות אנימציות" הושמט בכוונה - ראו ההסבר המפורט בראש הקובץ.
  // "הצגת טיימר בשלבים"/"מעבר אוטומטי ללוגו הבא" כן נוספו (ראו למטה).
  List<Widget> _gameRows(AppLocalizations loc) {
    return [
      _segRow(
        icon: Icons.language_rounded,
        tint: const Color(0xFF38BDF8),
        label: loc.settingsGameLanguageLabel,
        options: [loc.languageHebrew, loc.languageEnglish],
        selected: localeController.isHebrew ? loc.languageHebrew : loc.languageEnglish,
        onSelect: (opt) {
          AudioManager.playClick();
          localeController.setLocale(opt == loc.languageHebrew ? const Locale('he') : const Locale('en'));
          setState(() {});
        },
      ),
      _toggleRow(
        icon: Icons.verified_rounded,
        tint: const Color(0xFFFFD86B),
        label: loc.settingsHintConfirmLabel,
        sub: loc.settingsHintConfirmSub,
        value: GameSettings.hintConfirmEnabled,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          GameSettings.setHintConfirmEnabled(v);
        },
      ),
      // 🆕 נוספו בחזרה לפי בקשה מפורשת ("באזור של המשחק אין מספיק
      // דברים") - שניהם עכשיו אמיתיים לגמרי (לא רק מתג): הטיימר סופר
      // שניות אמיתיות בכותרת logo_level_screen.dart, והמעבר האוטומטי
      // באמת מתקדם לבד בדיאלוג התוצאה (ראו _AutoAdvanceButton שם).
      _toggleRow(
        icon: Icons.timer_outlined,
        tint: const Color(0xFF7DD3FC),
        label: loc.settingsLevelTimerLabel,
        value: GameSettings.levelTimerEnabled,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          GameSettings.setLevelTimerEnabled(v);
        },
      ),
      _toggleRow(
        icon: Icons.skip_next_rounded,
        tint: const Color(0xFF6EE7B7),
        label: loc.settingsAutoAdvanceLabel,
        sub: loc.settingsAutoAdvanceSub,
        value: GameSettings.autoAdvanceEnabled,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          GameSettings.setAutoAdvanceEnabled(v);
        },
      ),
    ];
  }

  // --- צליל ---
  List<Widget> _soundRows(AppLocalizations loc) {
    return [
      _sliderRow(
        icon: Icons.music_note_rounded,
        tint: const Color(0xFFA78BFA),
        label: loc.settingsMusicLabel,
        value: AudioManager.musicVolume,
        onChanged: (v) {
          setState(() {});
          AudioManager.setMusicVolume(v);
        },
      ),
      _sliderRow(
        icon: Icons.graphic_eq_rounded,
        tint: const Color(0xFF38BDF8),
        label: loc.settingsEffectsLabel,
        value: AudioManager.sfxVolume,
        onChanged: (v) {
          setState(() {});
          AudioManager.setSfxVolume(v);
        },
      ),
      _toggleRow(
        icon: Icons.vibration_rounded,
        tint: const Color(0xFFFB923C),
        label: loc.settingsVibrationLabel,
        sub: loc.settingsVibrationSub,
        value: AudioManager.hapticsEnabled,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          AudioManager.setHapticsEnabled(v);
        },
      ),
    ];
  }

  // --- התראות ---
  // 🩹 "חבר הזמין אותי לדו-קרב" ו"מבצעים בחנות" הושמטו בכוונה - ראו
  // ההסבר המפורט בראש הקובץ (פוש מהשרת / תכונה שלא קיימת בכלל).
  List<Widget> _notifRows(AppLocalizations loc) {
    final masterOn = NotificationManager.notificationsEnabled;
    return [
      _toggleRow(
        icon: Icons.notifications_active_rounded,
        tint: const Color(0xFFFB7185),
        label: loc.settingsNotifAllLabel,
        value: masterOn,
        onChanged: (v) async {
          AudioManager.playClick();
          setState(() {});
          await NotificationManager.setNotificationsEnabled(v);
          // 🩹 שתי מערכות נפרדות (Local Notifications + FCM/Push) חולקות
          // את אותה הרשאת מערכת - ראו ההסבר ב-push_notification_service.dart.
          // חייבים לבקש משתיהן כאן, לא רק מ-NotificationManager, אחרת
          // ה-FCM token אף פעם לא יישמר למשתמש שהפעיל את המתג.
          if (v) PushNotificationService.requestPermissionAndRegister();
          if (mounted) setState(() {});
        },
      ),
      _toggleRow(
        icon: Icons.emoji_events_rounded,
        tint: const Color(0xFFFFD86B),
        label: loc.settingsNotifTournamentLabel,
        value: NotificationManager.tournamentNotificationsEnabled,
        enabled: masterOn,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          NotificationManager.setTournamentNotificationsEnabled(v);
        },
      ),
      _toggleRow(
        icon: Icons.event_note_rounded,
        tint: const Color(0xFF38BDF8),
        label: loc.settingsNotifDailyLabel,
        value: NotificationManager.dailyNotificationsEnabled,
        enabled: masterOn,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          NotificationManager.setDailyNotificationsEnabled(v);
        },
      ),
      _toggleRow(
        icon: Icons.bolt_rounded,
        tint: const Color(0xFF7DD3FC),
        label: loc.settingsNotifEnergyLabel,
        value: NotificationManager.energyNotificationsEnabled,
        enabled: masterOn,
        onChanged: (v) {
          AudioManager.playClick();
          setState(() {});
          NotificationManager.setEnergyNotificationsEnabled(v);
        },
      ),
    ];
  }

  // --- חשבון ---
  // 🩹 "הופעה בטבלה הארצית"/"הצגת סטטוס מחובר"/"קבלת בקשות חברות"
  // הושמטו בכוונה - ראו ההסבר המפורט בראש הקובץ.
  List<Widget> _accountRows(AppLocalizations loc) {
    return [
      _buildAccountLinkRow(loc),
      _buildRemoveAdsRow(loc),
      _linkRow(
        icon: Icons.restore_rounded,
        tint: Colors.white,
        label: loc.shopRestorePurchasesButton,
        onTap: () async {
          AudioManager.playClick();
          await IapManager.restorePurchases();
          if (mounted) AppNotification.show(context, loc.shopCheckingPurchasesMessage, type: AppNotificationType.info);
        },
      ),
      _linkRow(
        icon: Icons.delete_forever_rounded,
        tint: const Color(0xFFFB7185),
        labelColor: const Color(0xFFFDA4AF),
        label: loc.settingsDeleteUserLink,
        onTap: _confirmDeleteAccount,
      ),
    ];
  }

  // 🆕 "הסרת פרסומות" - אותם 2 מוצרים אמיתיים כמו בחנות
  // (IapManager.noAdsMonthlyId/noAdsLifetimeId). אם כבר פעיל (IapManager.noAds)
  // מציג סטטוס "פעיל" בלבד; אחרת מציג את שני המחירים האמיתיים ופותח
  // רכישה בלחיצה - אותו נתיב בדיוק כמו shop_screen.dart.
  Widget _buildRemoveAdsRow(AppLocalizations loc) {
    if (IapManager.noAds) {
      return _linkRow(
        icon: Icons.block_rounded,
        tint: const Color(0xFFFB923C),
        label: loc.settingsRemoveAdsLabel,
        value: loc.settingsRemoveAdsOwnedLabel,
        valueColor: const Color(0xFF6EE7B7),
        onTap: () {},
      );
    }
    final price = IapManager.product(IapManager.noAdsLifetimeId)?.price ?? "₪40.00";
    return _linkRow(
      icon: Icons.block_rounded,
      tint: const Color(0xFFFB923C),
      label: loc.settingsRemoveAdsLabel,
      value: price,
      valueColor: const Color(0xFFFFD86B),
      onTap: () async {
        AudioManager.playClick();
        final started = await IapManager.buy(IapManager.noAdsLifetimeId);
        if (!started && mounted) AppNotification.show(context, loc.shopPurchaseUnavailable, type: AppNotificationType.error);
      },
    );
  }

  // --- עזרה ---
  List<Widget> _helpRows(AppLocalizations loc) {
    return [
      _linkRow(icon: Icons.help_rounded, tint: const Color(0xFFA78BFA), label: loc.settingsHowToPlayLabel, onTap: () => _showInfoDialog(loc.settingsHowToPlayLabel, loc.settingsHowToPlayBody)),
      _linkRow(
        icon: Icons.auto_awesome_rounded,
        tint: const Color(0xFFF472B6),
        label: loc.settingsWhatsNewLink,
        value: _version.isEmpty ? null : _version,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateNotesScreen())),
      ),
      _linkRow(icon: Icons.star_rounded, tint: const Color(0xFFFFD86B), label: loc.settingsRateUsLink, onTap: () => ReviewManager.requestNativeReview()),
      _linkRow(icon: Icons.bug_report_rounded, tint: const Color(0xFFFB7185), label: loc.settingsReportIssueLink, onTap: _contactSupport),
      _linkRow(icon: Icons.mail_rounded, tint: const Color(0xFF38BDF8), label: loc.settingsContactUsLabel, onTap: _contactUs),
      _linkRow(icon: Icons.lock_rounded, tint: Colors.white, label: loc.settingsPrivacyLink, onTap: () => _openLink("https://sites.google.com/view/zehet-halogo-privacy")),
    ];
  }

  // ===================== מרכיבי שורה גנריים =====================

  Widget _divider() => Container(height: 1, color: Colors.white.withValues(alpha: 0.06));

  Widget _rowIcon(IconData icon, Color tint) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: tint.withValues(alpha: 0.2)),
    child: Icon(icon, color: tint, size: 16),
  );

  Widget _toggleRow({
    required IconData icon,
    required Color tint,
    required String label,
    String? sub,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        child: Row(
          children: [
            _rowIcon(icon, tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (sub != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF34D399),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required Color tint,
    required String label,
    Color? labelColor,
    String? sub,
    String? value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Row(
            children: [
              _rowIcon(icon, tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: labelColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    if (sub != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              if (value != null) ...[
                Text(value, textDirection: TextDirection.ltr, style: TextStyle(color: valueColor ?? Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.28), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow({required IconData icon, required Color tint, required String label, required double value, required ValueChanged<double> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rowIcon(icon, tint),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
              Directionality(textDirection: TextDirection.ltr, child: Text('${(value * 100).round()}%', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, fontWeight: FontWeight.w800))),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 5, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9), overlayShape: const RoundSliderOverlayShape(overlayRadius: 15)),
            child: Slider(value: value, activeColor: const Color(0xFFFFB24D), inactiveColor: Colors.white.withValues(alpha: 0.12), thumbColor: Colors.white, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _segRow({
    required IconData icon,
    required Color tint,
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [_rowIcon(icon, tint), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black.withValues(alpha: 0.25)),
            child: Row(
              children: options.map((o) {
                final active = o == selected;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => onSelect(o),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: active ? const Color(0xFFFFD86B) : Colors.transparent),
                        alignment: Alignment.center,
                        child: Text(o, style: TextStyle(color: active ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.65), fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // 🆕 שורת "חשבון" - אם לא מקושר: כפתור "חבר חשבון" שפותח את אותו
  // דיאלוג המוצג גם מהבית (account_link_prompt.dart). אם כבר מקושר:
  // מציג איזה ספק מחובר (Google/Apple) עם וי ירוק - לוחצים כדי להתנתק.
  Widget _buildAccountLinkRow(AppLocalizations loc) {
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
      return _linkRow(
        icon: Icons.link_rounded,
        tint: const Color(0xFFA78BFA),
        label: loc.settingsLinkedAccountLabel(names.join(' · ')),
        value: '✓',
        valueColor: const Color(0xFF3DDC84),
        onTap: _confirmSignOutLinked,
      );
    }
    return _linkRow(
      icon: Icons.link_rounded,
      tint: const Color(0xFFA78BFA),
      label: loc.settingsLinkAccountLabel,
      sub: loc.settingsLinkAccountSub,
      onTap: () async {
        await AccountLinkPrompt.show(context);
        if (mounted) await _loadProfileStats(); // מרענן את השורה אחרי קישור מוצלח
      },
    );
  }

  // 🆕 "שיהיה אופציה להתנתק מהחשבון שהתחברתי אליו" - לוחצים על שורת
  // "מחובר: ..." בהגדרות כדי להתנתק (לא למחוק כלום, ראו AccountService.signOutLinked).
  Future<void> _confirmSignOutLinked() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        title: Text(loc.settingsSignOutConfirmTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          loc.settingsSignOutConfirmBody,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.duelLobbyCancelButton, style: const TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.settingsSignOutButton, style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AccountService.signOutLinked();
    if (!mounted) return;
    await _loadProfileStats();
    if (mounted) AppNotification.show(context, loc.settingsSignedOutMessage, type: AppNotificationType.success);
  }

  // 🆕 "מחק משתמש" - אישור מפורש (פעולה סופית ובלתי הפיכה) לפני מחיקה
  // בפועל. עובד גם למי שלא מקושר לחשבון (מוחק רק את ההתקדמות המקומית),
  // וגם למקושר (מוחק גם את חשבון ה-Google/Apple המקושר) - ראו
  // account_service.dart.
  Future<void> _confirmDeleteAccount() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        title: Text(loc.settingsDeleteAccountConfirmTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          loc.settingsDeleteAccountConfirmBody,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.duelLobbyCancelButton, style: const TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.settingsDeletePermanentlyButton, style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w900))),
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
          content: Text(
            loc.settingsAccountDeletedMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.battlePassGotItButton, style: const TextStyle(color: Color(0xFFFFD86B))))],
        ),
      );
    } else {
      AppNotification.show(context, loc.settingsDeleteFailedMessage, type: AppNotificationType.error);
    }
  }

  void _showInfoDialog(String title, String content) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(child: Text(content, style: const TextStyle(color: Colors.white70))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.logoLevelCloseButton, style: const TextStyle(color: Color(0xFFFFD86B))))],
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
    final loc = AppLocalizations.of(context)!;
    String? code;
    try {
      code = await FriendService.myCode();
    } catch (_) {}
    final String link = code != null ? ReferralService.shareLink(code) : _androidStoreLink;
    final String text = loc.friendsInviteText(link, ReferralService.bonusCoins);
    try {
      // 🐛 תוקן: "באייפון שיתוף כותב שאי אפשר לשתף" - חסר sharePositionOrigin
      // (נקודת העיגון של ה-popover ב-iOS, ראו share_helper.dart להסבר המלא).
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(text, subject: loc.appLoadingTitle, sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null);
    } catch (_) {
      if (mounted) {
        AppNotification.show(context, loc.friendChallengeNoShareAppFallback(text), duration: const Duration(seconds: 5));
      }
    }
  }

  // "דיווח על תקלה" - נושא/תוכן מכוונים לתיאור באג.
  Future<void> _contactSupport() async {
    final loc = AppLocalizations.of(context)!;
    final String subject = loc.settingsSupportEmailSubject;
    final String body = loc.settingsSupportEmailBody(_username);
    await _sendMail(subject, body);
  }

  // 🆕 "צור קשר" - אותו נתיב מייל בדיוק (mailto), אבל נושא/תוכן כלליים
  // (לא "דיווח תקלה") - לפי המוקאפ שמבדיל בין שתי שורות נפרדות.
  Future<void> _contactUs() async {
    final loc = AppLocalizations.of(context)!;
    final String subject = loc.settingsGeneralContactSubject;
    final String body = loc.settingsGeneralContactBody(_username);
    await _sendMail(subject, body);
  }

  Future<void> _sendMail(String subject, String body) async {
    final Uri uri = Uri.parse("mailto:$_supportEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) _showMailError();
    } catch (_) {
      if (mounted) _showMailError();
    }
  }

  void _showMailError() {
    AppNotification.show(context, AppLocalizations.of(context)!.settingsNoMailAppMessage(_supportEmail), duration: const Duration(seconds: 4));
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

class _TabDef {
  final String id;
  final IconData icon;
  final Color color;
  const _TabDef(this.id, this.icon, this.color);
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
    final loc = AppLocalizations.of(context)!;
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
              Text(loc.settingsChangeNameDialogTitle, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(loc.mainMenuNameEntrySubtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),
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
                          onChanged: _onChanged,
                          onSubmitted: (_) => _onConfirm(),
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(counterText: "", border: InputBorder.none, hintText: loc.mainMenuNameHint, hintStyle: const TextStyle(color: Colors.white30, fontSize: 15)),
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
                            : Text(loc.settingsSaveButton, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Text(loc.duelLobbyCancelButton, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    final loc = AppLocalizations.of(context)!;
    switch (_status) {
      case _NameCheckStatus.idle:
        return const SizedBox(height: 1);
      case _NameCheckStatus.checking:
        return _statusRow(
          icon: const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD86B))),
          text: loc.mainMenuCheckingAvailability,
          textColor: Colors.white.withValues(alpha: 0.55),
          borderColor: Colors.white.withValues(alpha: 0.14),
          bgColor: Colors.white.withValues(alpha: 0.05),
        );
      case _NameCheckStatus.available:
        return _statusRow(
          icon: const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF6EE7B7)),
          text: loc.mainMenuNameAvailable,
          textColor: const Color(0xFFA7F3D0),
          borderColor: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
          bgColor: const Color(0xFF34D399).withValues(alpha: 0.1),
        );
      case _NameCheckStatus.taken:
        return _statusRow(
          icon: const Icon(Icons.cancel_rounded, size: 15, color: Color(0xFFFB7185)),
          text: loc.mainMenuNameTaken,
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
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800))),
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
