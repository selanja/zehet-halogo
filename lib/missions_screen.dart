// missions_screen.dart
//
// מסך "משימות" ייעודי - שלושה חלקים: אתגר היום (מיוחד, פרס גדול חד-פעמי),
// משימות יומיות ומשימות שבועיות (עם בר התקדמות + כפתור איסוף פרס לכל
// אחת). כל הנתונים מגיעים מ-MissionsService (SharedPreferences מקומי,
// בלי צורך בשרת) - עיצוב תואם לשאר מסכי המשחק (רקע סגול-כהה, כרטיסים
// מוזגגים, מבטאי זהב/ורוד).

import 'package:flutter/material.dart';
import 'app_background.dart';
import 'missions_service.dart';
import 'daily_challenge_screen.dart';
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון משותף - גם כאן, לא רק במסך הבית
import 'ads_manager.dart'; // 🆕 פרסומת מתוגמלת - להחלפת משימה
import 'app_icons.dart'; // 🆕 CoinIcon - אימוג'י מטבע במקום אייקון וקטורי
import 'battle_pass_service.dart'; // 🆕 סטטוס פרימיום - למשימות premiumOnly
import 'battle_pass_screen.dart'; // 🆕 ניווט "שדרג לפרימיום" ממשימה נעולה
import 'main_menu_screen.dart'; // 🩹 MainMenuScreen.onReturnedHome - לרענון מיידי של המטבעות במסך הבית (ראו _claim)
import 'app_notification.dart';
import 'first_visit_explainer.dart'; // 🆕 הסבר חד-פעמי בכניסה הראשונה למסך

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  bool _loading = true;
  // 🆕 אם משהו נכשל בטעינה (חריגה לא צפויה) - מציגים מסך שגיאה עם כפתור
  // "נסה שוב" במקום "טעינה אינסופית" שקטה (התקלה שדווחה: "לא עולה, פשוט טוען").
  String? _error;
  List<MissionProgress> _daily = [];
  List<MissionProgress> _weekly = [];
  DailyChallenge? _challenge;
  // 🆕 האם באטל פאס פרימיום פעיל לעונה הנוכחית - קובע אם משימות
  // premiumOnly נעולות (ראו _missionCard/_buildPremiumLockedFooter).
  bool _premium = false;
  // 🆕 עיצוב מחדש - יומיות/שבועיות עברו לשני טאבים (לא שתי רשימות
  // מוערמות זו מתחת לזו), בדיוק כמו המוקאפ (מסך 08 · משימות).
  bool _showWeekly = false;

  // 🆕 הסבר חד-פעמי - ראו first_visit_explainer.dart.
  bool _showExplainer = false;

  @override
  void initState() {
    super.initState();
    AdsManager.recordBrowseNavigation(); // 🆕 "גלישה בלי לשחק"
    _load();
    FirstVisitExplainer.shouldShow('missions').then((show) {
      if (show && mounted) setState(() => _showExplainer = true);
    });
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        MissionsService.getDailyMissions(),
        MissionsService.getWeeklyMissions(),
        MissionsService.getDailyChallenge(),
        BattlePassService.isPremiumUnlocked(),
      ]);
      if (!mounted) return;
      setState(() {
        _daily = results[0] as List<MissionProgress>;
        _weekly = results[1] as List<MissionProgress>;
        _challenge = results[2] as DailyChallenge;
        _premium = results[3] as bool;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "שגיאה בטעינת המשימות: $e";
        _loading = false;
      });
    }
  }

  Future<void> _claim(MissionProgress m, bool weekly) async {
    final reward = await MissionsService.claim(m.def.id, weekly: weekly);
    if (reward == null || !mounted) return;
    AppNotification.show(context, 'קיבלת +$reward מטבעות!', type: AppNotificationType.success);
    // 🩹 באג שתוקן: איסוף פרס משימה לא עדכן את המטבעות במסך הבית מיידית
    // (בדיוק אותו באג ואותו תיקון כמו ב-battle_pass_screen.dart._claim).
    MainMenuScreen.onReturnedHome?.call();
    _load();
  }

  // 🆕 צפייה בפרסומת כדי להחליף משימה שלא בא לך לעשות במשימה אחרת
  // מהמאגר. אפשר להחליף כל משימה שעדיין לא נאספה (גם כזו שכבר בהתקדמות).
  Future<void> _rerollMission(MissionProgress m, bool weekly) async {
    if (!AdsManager.isRewardedReady) {
      AppNotification.show(context, "אין פרסומת זמינה כרגע, נסה שוב עוד רגע", type: AppNotificationType.warning);
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      final newDef = await MissionsService.rerollMission(m.def.id, weekly: weekly);
      if (!mounted) return;
      if (newDef == null) {
        AppNotification.show(context, "אי אפשר להחליף את המשימה הזו כרגע", type: AppNotificationType.error);
        return;
      }
      AppNotification.show(context, 'המשימה הוחלפה: ${newDef.title}', type: AppNotificationType.success);
      _load();
    });
  }

  Future<void> _playChallenge() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyChallengeScreen()));
    _load();
  }

  // זמן שנותר עד לאיפוס היום הבא (חצות) - טקסט קטן שמסביר מתי המשימות
  // היומיות יתחלפו.
  String get _resetInTodayText {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    return '${diff.inHours}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}';
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B)))
                  : _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          color: const Color(0xFFFFD86B),
                          backgroundColor: const Color(0xFF241a4f),
                          onRefresh: _load,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 128),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 08 · משימות):
                                // כותרת+תג+טאבים+שורת "מתאפס בעוד" יושבים כולם בתוך
                                // פאנל ירוק-גרדיאנט אחד, ומתחתיו (על הרקע הרגיל)
                                // רשימת כרטיסי המשימות - בלי כרטיס "אתגר היום" ענק
                                // ונפרד; האתגר היומי מופיע כפריט רגיל ברשימה היומית.
                                _buildGreenHeaderPanel(),
                                const SizedBox(height: 14),
                                // 🩹 תוקן (שגיאת קומפילציה אמיתית מ-flutter analyze):
                                // _weekly הוא List<MissionProgress> ו-_dailyWithChallenge
                                // הוא List<Widget> - ה-ternary בין השניים יצר
                                // List<Object>, וזה נכשל כשניסינו להעביר item בתור
                                // Widget ל-Padding. עכשיו שני הענפים הופכים ל-
                                // List<Widget> באופן מפורש לפני המיפוי.
                                ...(_showWeekly ? _weekly.map((m) => _missionCard(m, weekly: true)).toList() : _dailyWithChallenge)
                                    .map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: item)),
                              ],
                            ),
                          ),
                        ),
            ),
            const AppBottomNav(current: AppTab.missions),
            if (_showExplainer)
              buildFirstVisitOverlay(
                title: 'מסך המשימות',
                points: const [
                  ExplainerPoint('📅', 'משימות יומיות ושבועיות', 'כל משימה שמשלימים מזכה בפרס - מטבעות או נקודות XP.'),
                  ExplainerPoint('🎯', 'אתגר יומי', 'מופיע למעלה כל יום - הזדמנות חד-פעמית לפרס גדול יותר.'),
                  ExplainerPoint('🔄', 'מתאפסות אוטומטית', 'משימות חדשות מחכות בכל יום/שבוע - אין צורך לעשות כלום.'),
                ],
                onDismiss: () {
                  FirstVisitExplainer.markSeen('missions');
                  setState(() => _showExplainer = false);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🩹 תוקן (שגיאת קומפילציה אמיתית מ-flutter analyze): קריאה
            // ל-_buildTopBar() שכבר לא קיימת (הוחלפה ב-_buildGreenHeaderPanel
            // בעיצוב מחדש) - הוחלפה כאן בכפתור חזרה פשוט, כי מסך השגיאה לא
            // צריך את כל הפאנל הירוק המלא (טאבים/סטטיסטיקות).
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _GlassRoundIconButton(icon: Icons.arrow_forward_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
                const Expanded(
                  child: Text('משימות', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 40),
            Icon(Icons.error_outline_rounded, color: Colors.white.withValues(alpha: 0.4), size: 44),
            const SizedBox(height: 14),
            Text(_error ?? "שגיאה לא ידועה", textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD86B), foregroundColor: const Color(0xFF2A1740)),
              child: const Text("נסה שוב", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 עיצוב מחדש - בדיוק כמו במוקאפ (מסך 08 · משימות): כותרת+תג+טאבים+
  // שורת "מתאפס בעוד" יושבים כולם יחד בתוך פאנל ירוק-גרדיאנט אחד (לא
  // שורות נפרדות על הרקע הכללי).
  Widget _buildGreenHeaderPanel() {
    final totalClaimed = _daily.where((m) => m.claimed).length + _weekly.where((m) => m.claimed).length;
    final totalCount = _daily.length + _weekly.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF163B2E), Color(0xFF241A4F)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.1)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$totalClaimed/$totalCount', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: Color(0xFF6EE7B7), size: 14),
                  ],
                ),
              ),
              const Expanded(
                child: Text('משימות', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              ),
              _GlassRoundIconButton(icon: Icons.arrow_forward_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.18)),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _tabButton('שבועיות', selected: _showWeekly, onTap: () => setState(() => _showWeekly = true))),
                Expanded(child: _tabButton('יומיות', selected: !_showWeekly, onTap: () => setState(() => _showWeekly = false))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.06)),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  '${(_showWeekly ? _weekly : _daily).where((m) => m.isComplete).length}/${(_showWeekly ? _weekly : _daily).length}',
                  style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  _showWeekly ? 'מתאפס בתחילת השבוע הבא' : 'מתאפס בעוד $_resetInTodayText שעות',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.5), size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, {required bool selected, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: selected ? const LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF34D399)]) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: selected ? const Color(0xFF08281C) : Colors.white.withValues(alpha: 0.55), fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  // 🆕 רשימת המשימות היומיות המוצגות בפועל - עם "אתגר היום" בתור פריט
  // רגיל ראשון ברשימה (לא כרטיס-ענק נפרד), בדיוק כמו במוקאפ ("השלם את
  // האתגר היומי" מופיע שם כמשימה לכל דבר, עם אייקון קוביה).
  List<Widget> get _dailyWithChallenge {
    final challenge = _challenge;
    return [
      if (challenge != null) _challengeListItem(challenge),
      ..._daily.map((m) => _missionCard(m, weekly: false)),
    ];
  }

  // 🆕 "אתגר היום" - עוצב עכשיו כמו כל שאר כרטיסי המשימות (לא כרטיס-CTA
  // ענק בגרדיאנט כתום נפרד) - אייקון קוביה, "0/1"/"1/1", ותג מטבעות.
  // לחיצה על הכרטיס (כשלא נוצל/הושלם) פותחת את מסך האתגר עצמו במקום
  // "לתבוע" פרס ישירות - כי זו משימה עם מיני-משחק אמיתי בפנים, לא ספירה
  // אוטומטית כמו שאר המשימות.
  Widget _challengeListItem(DailyChallenge challenge) {
    final done = challenge.completed;
    final usedUp = !done && challenge.attempted;
    final complete = done;
    return Opacity(
      opacity: usedUp ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: (done || usedUp) ? null : _playChallenge,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (complete ? const Color(0xFF34D399) : Colors.white).withValues(alpha: complete ? 0.5 : 0.12), width: 1.3),
              color: complete ? const Color(0xFF34D399).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF38BDF8).withValues(alpha: complete ? 0.25 : 0.35)),
                  alignment: Alignment.center,
                  child: complete ? const Icon(Icons.check_rounded, color: Color(0xFF6EE7B7), size: 20) : const Icon(Icons.casino_rounded, color: Color(0xFF7DD3FC), size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('השלם את האתגר היומי', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      // 🆕 שורת תגים: מטבעות + כוכבי באטל פאס (שני תגים
                      // נפרדים, כי בפועל אלה שני משאבים שונים - מטבעות
                      // נכנסים לארנק, כוכבים מתקדמים בבאטל פאס - ראו
                      // MissionsService.completeDailyChallenge: הפרס
                      // מוסיף גם מטבעות וגם BattlePassService.addPoints
                      // עם אותו הסכום של dailyChallengeXpReward).
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFFD86B).withValues(alpha: 0.16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('+${MissionsService.dailyChallengeCoinReward}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 12, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 3),
                                const CoinIcon(size: 13),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFC084FC).withValues(alpha: 0.18)),
                            child: Text('+${MissionsService.dailyChallengeXpReward} ⭐', style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(done ? '1/1' : (usedUp ? '✗' : '0/1'), style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 עיצוב מחדש - אייקון-עיגול צבעוני לפי סוג המשימה + "X/Y" צמוד לצד
  // שמאל (לא ליד פס ההתקדמות) - בדיוק כמו כרטיסי המשימות במוקאפ (מסך
  // 08 · משימות). כרטיס שכבר נאסף מקבל עיגול "✓" ירוק במקום אייקון הסוג.
  // 🩹 תוקן: היו אימוג'י (🧩💡🎮⚔️) - אותה בעיית תאימות מתועדת כמו אימוג'י
  // המטבע/אנרגיה (ראו app_icons.dart) - הוחלפו לאייקונים וקטוריים אמינים.
  IconData _missionIcon(MissionEvent event) {
    switch (event) {
      case MissionEvent.logoSolved:
        return Icons.extension_rounded;
      case MissionEvent.hintUsed:
        return Icons.lightbulb_rounded;
      case MissionEvent.duelPlayed:
        return Icons.sports_esports_rounded;
      case MissionEvent.duelWon:
        return Icons.sports_mma_rounded;
    }
  }

  Widget _missionCard(MissionProgress m, {required bool weekly}) {
    // 🆕 משימת premiumOnly נעולה כל עוד אין פרימיום פעיל - ההתקדמות
    // עדיין מוצגת (היא נצברת גם בלי פרימיום, ראו MissionsService), אבל
    // אי אפשר לתבוע אותה ואין אפשרות להחליף אותה בפרסומת.
    final bool locked = m.def.premiumOnly && !_premium;
    final canClaim = m.isComplete && !m.claimed && !locked;
    final ratio = m.def.target == 0 ? 0.0 : (m.progress / m.def.target).clamp(0.0, 1.0);
    // 🆕 משימת פרימיום (נעולה או פתוחה) מקבלת תמיד גוון זהב מיוחד -
    // כדי שתבלוט חזותית כ"בונוס בלעדי" ולא תיראה כמו משימה רגילה.
    final accent = m.def.premiumOnly ? const Color(0xFFFFD979) : (weekly ? const Color(0xFFC084FC) : const Color(0xFF34D399));
    final accentDark = m.def.premiumOnly ? const Color(0xFFE08A2C) : (weekly ? const Color(0xFF7C3AED) : const Color(0xFF16A46F));

    return Opacity(
      opacity: m.claimed ? 0.5 : (locked ? 0.75 : 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (m.claimed ? Colors.white : accent).withValues(alpha: m.claimed ? 0.1 : (m.def.premiumOnly ? 0.55 : 0.4)), width: 1.3),
          gradient: LinearGradient(
            colors: m.def.premiumOnly
                ? [const Color(0xFFFFD979).withValues(alpha: 0.1), const Color(0xFFFFD979).withValues(alpha: 0.02)]
                : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.015)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: m.claimed ? 0.15 : 0.22)),
                  alignment: Alignment.center,
                  child: m.claimed
                      ? Icon(Icons.check_rounded, color: accent, size: 20)
                      : (locked ? Icon(Icons.lock_rounded, color: accent, size: 18) : Icon(_missionIcon(m.def.event), color: accent, size: 19)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🆕 תג "⭐ פרימיום" מעל הכותרת - רק למשימות premiumOnly,
                      // כדי שיהיה ברור מיד שזו לא משימה רגילה.
                      if (m.def.premiumOnly) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFFFD979).withValues(alpha: 0.22)),
                          child: const Text('⭐ פרימיום', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFFFFD979), fontSize: 9.5, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 5),
                      ],
                      Text(m.def.title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      // 🆕 נוסף תג "+X ⭐" ליד תג המטבעות - לפי בקשה מפורשת
                      // שבמסך המשימות יהיה כתוב כמה כוכבי-באטל-פאס כל
                      // משימה נותנת (לא רק מטבעות). ב-MissionsService.claim
                      // אותו def.reward מוענק גם כמטבעות וגם כנקודות באטל
                      // פאס (BattlePassService.addPoints(def.reward)) - אז
                      // הסכום זהה בשני התגים בכוונה, לא טעות.
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFFD86B).withValues(alpha: 0.16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('+${m.def.reward}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 12, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 3),
                                const CoinIcon(size: 13),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFC084FC).withValues(alpha: 0.18)),
                            child: Text('+${m.def.reward} ⭐', style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(m.claimed ? 'נאסף' : '${m.progress}/${m.def.target}', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            if (!m.claimed) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(color: Colors.white.withValues(alpha: 0.08)),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accentDark]))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (canClaim) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF08281C),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _claim(m, weekly),
                  child: const Text('קבל פרס', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
              ),
            ] else if (locked) ...[
              // 🆕 המשימה נעולה (premiumOnly בלי פרימיום פעיל) - במקום
              // כפתור תביעה/החלפה, באנר שמסביר את זה ומקשר למסך הבאטל
              // פאס כדי לרכוש פרימיום (ההתקדמות כבר נשמרת ומחכה).
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BattlePassScreen())).then((_) => _load()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFFFD979).withValues(alpha: 0.14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.lock_rounded, color: Color(0xFFFFD979), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          m.isComplete ? 'הפרס מוכן - דורש באטל פאס פרימיום לאיסוף' : 'דורש באטל פאס פרימיום',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(color: Color(0xFFFFD979), fontSize: 11.5, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (!m.claimed && !m.def.premiumOnly) ...[
              // 🆕 המשימה עוד לא הושלמה ולא נאספה - אפשר לצפות בפרסומת
              // כדי להחליף אותה במשימה אחרת, אם היא לא מדברת אליך.
              // (משימת פרימיום קבועה לא ניתנת להחלפה כלל - היא לא חלק
              // מהמאגר האקראי, ראו ה-guard התואם ב-
              // MissionsService.rerollMission - הכפתור פשוט לא מוצג לה בכלל).
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _rerollMission(m, weekly),
                  icon: const Icon(Icons.smart_display_rounded, size: 15, color: Color(0xFFA7F3D0)),
                  label: const Text('פרסומת = החלף משימה', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlassRoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassRoundIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}