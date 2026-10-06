import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard.dart';
import 'device_id.dart';
import 'audio_manager.dart';
import 'league_screen.dart';
import 'achievements_screen.dart';
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון משותף - גם כאן, לא רק במסך הבית
import 'first_visit_explainer.dart'; // 🆕 הסבר חד-פעמי בכניסה הראשונה למסך

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

// 🆕 שתי תצוגות לטבלה הארצית: לפי מדליות (ברירת מחדל, דירוג הוגן במקום
// XP גולמי) או לפי נקודות (XP). הבחירה נעשית דרך שני "כפתורים" בכותרת
// (ראו _buildModeSwitch).
// 🐛 תוקן: הוסרה תצוגת "רצף" השלישית - לפי בקשה מפורשת ("הטבלה עמוסה
// מדי") - הרצף עדיין מוצג כסטטיסטיקה משנית קטנה בתוך תצוגת הנקודות
// (ראו _buildMyStatsRow/_buildRow למטה), רק לא כתצוגה/מיון נפרד משלו.
enum _BoardMode { medals, points }

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // מגבילים את מספר השורות שמוצגות בטבלה - בלי זה, ככל שיותר אנשים
  // ישחקו, הרשימה תגדל ללא גבול ותעמיס על המסך.
  static const int _maxDisplayed = 50;
  // אם אני לא בין 10 הראשונים - מוצג תג צף עם המיקום האמיתי שלי
  static const int _floatingThreshold = 10;

  _BoardMode _mode = _BoardMode.medals;
  bool get _byMedals => _mode == _BoardMode.medals;

  String get _metricKey => _byMedals ? 'medals' : 'xp';

  List<Map<String, dynamic>> entries = [];
  bool isLoading = true;
  String? error;
  String myName = "";
  String myDeviceId = "";

  // 🐛 תוקן: "התוכן למעלה ולמטה מסתיר חלק מהטבלה" - הכותרת העליונה
  // (כותרת+מתג+שורת קיצורים) גדלה עם הזמן (נוספה שורת הקיצורים) אבל
  // הריפוד העליון של הרשימה נשאר מספר קבוע ("קסם") שלא עודכן יחד איתה -
  // אז החלק העליון של הרשימה נגלל מתחת לכותרת ומוסתר בפועל. במקום עוד
  // מספר קבוע ש"ישבר" שוב בפעם הבאה שהכותרת תשתנה - מודדים את הגובה
  // האמיתי שלה בפועל (ראו _headerKey/_measureHeaderHeight) ומשתמשים בו
  // כריפוד. _headerHeight מתחיל מהערכה סבירה עד המדידה הראשונה בפועל.
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 190;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _myRowKey = GlobalKey();
  bool _myRowVisible = false; // האם השורה האמיתית שלי כרגע נראית על המסך

  // 🆕 הסבר חד-פעמי - ראו first_visit_explainer.dart.
  bool _showExplainer = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_checkMyRowVisibility);
    FirstVisitExplainer.shouldShow('leaderboard').then((show) {
      if (show && mounted) setState(() => _showExplainer = true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkMyRowVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceId.get();
    final data = _byMedals ? await LeaderboardService.fetchLeaderboardByMedals() : await LeaderboardService.fetchLeaderboard();

    if (!mounted) return; // המסך נסגר בזמן שהבקשה עוד הייתה באוויר
    setState(() {
      myName = prefs.getString('username') ?? "";
      myDeviceId = deviceId;
      entries = data;
      isLoading = false;
      if (data.isEmpty) {
        // 🆕 אבחון זמני - מציג את השגיאה האמיתית מ-Firestore (אם נתפסה)
        // בסוגריים, במקום רק את ההודעה הגנרית. להסיר אחרי שהתקלה נמצאת.
        final real = LeaderboardService.lastError;
        error = real == null
            ? "לא הצלחנו לטעון את הטבלה. בדקו חיבור לאינטרנט ונסו שוב."
            : "לא הצלחנו לטעון את הטבלה.\n\nשגיאה טכנית (אבחון זמני):\n$real";
      }
    });

    // בודקים אחרי הציור הראשון האם השורה שלי כבר נראית מלכתחילה
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMyRowVisibility());
  }

  // 🆕 מעבר בין תצוגת "נקודות" לתצוגת "רצף" - טוען מחדש מ-Firestore עם
  // המיון המתאים (בקשה נפרדת, לא מיון מקומי, כדי שבאמת יוצגו 200 השיאנים
  // המובילים לפי המדד הנבחר ולא רק מי שכבר נטען).
  void _switchMode(_BoardMode mode) {
    if (mode == _mode) return;
    AudioManager.playClick();
    setState(() => _mode = mode);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _load();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    _load();
  }

  /// בודק אם השורה האמיתית שלי (המסומנת ב-_myRowKey) נמצאת כרגע בתוך
  /// אזור התצוגה. כשהיא כן - התג הצף נעלם, כי אין צורך בו יותר (כאילו
  /// "התחבר" למיקום האמיתי).
  void _checkMyRowVisibility() {
    if (!mounted) return;
    final ctx = _myRowKey.currentContext;
    bool visible = false;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final screenHeight = MediaQuery.of(context).size.height;
        final position = box.localToGlobal(Offset.zero);
        visible = position.dy < screenHeight - 30 && (position.dy + box.size.height) > 90;
      }
    }
    if (visible != _myRowVisible) {
      setState(() => _myRowVisible = visible);
    }
  }

  /// מחליק את הרשימה עד לשורה שלי (בלחיצה על התג הצף), ואז "מהבהב" אותה
  /// פעם אחת עם פעימת זוהר קלה - כדי שהעין תבין מיד איפה היא נחתה,
  /// במקום שהשורה תופיע סתם בשקט בתוך רשימה ארוכה.
  void _scrollToMyRow() {
    AudioManager.playClick();
    final ctx = _myRowKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic, alignment: 0.4)
          .then((_) {
        final state = _myRowKey.currentState;
        if (state is _PulseHighlightState) state.pulse();
      });
    } else {
      // 🛡️ רשת ביטחון: אם מסיבה כלשהי _myRowKey עדיין לא מחובר לאף widget
      // בעץ (למשל הרשימה עוד לא סיימה להיבנות) - לפחות גוללים לראש הרשימה,
      // כדי שלחיצה על "השם שלי" תמיד תעשה משהו ולא "תיתקע" בלי תגובה.
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  /// מודד את הגובה האמיתי של הכותרת הקבועה (אחרי כל build, ברגע שה-
  /// frame כבר צויר) ומעדכן את _headerHeight אם הוא השתנה - כדי שריפוד
  /// הרשימה תמיד יתאים לגובה האמיתי, גם אם הכותרת תשתנה שוב בעתיד.
  void _measureHeaderHeight() {
    final ctx = _headerKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _headerHeight).abs() > 0.5 && mounted) {
      setState(() => _headerHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeaderHeight());
    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: Stack(
        children: [
          // 🌌 רקע: גרדיאנט בסיס + "אורורה" מיטשטשת נעה + רשת נקודות + כוכבים
          // מנצנצים + סימני "?" צפים - בדיוק כמו העיצוב שקיבלתי
          const Positioned.fill(child: _AuroraBackground()),

          SafeArea(
            top: false,
            bottom: false,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC64B)))
                : error != null
                    ? _buildError()
                    : entries.isEmpty
                        ? _buildEmpty()
                        : _buildBoard(),
          ),

          // כותרת עליונה קבועה עם רקע מטושטש (glass) - בדיוק כמו במקור
          _buildHeader(),

          // 🆕 סרגל ניווט תחתון משותף
          const AppBottomNav(current: AppTab.leaderboard),
          if (_showExplainer)
            buildFirstVisitOverlay(
              title: 'הטבלה הארצית',
              points: const [
                ExplainerPoint('🏅', 'דירוג לפי מדליות', 'ברירת המחדל - דירוג הוגן לפי הישגים, לא רק כמות משחקים.'),
                ExplainerPoint('⭐', 'אפשר גם לפי נקודות', 'מתג למעלה מחליף לדירוג לפי XP שנצבר.'),
                ExplainerPoint('📍', 'המיקום שלכם תמיד גלוי', 'גם אם אתם לא בעשירייה הראשונה - תג צף מראה איפה אתם.'),
              ],
              onDismiss: () {
                FirstVisitExplainer.markSeen('leaderboard');
                setState(() => _showExplainer = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            key: _headerKey,
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF120C2E).withValues(alpha: 0.94),
                  const Color(0xFF120C2E).withValues(alpha: 0.6),
                  const Color(0xFF120C2E).withValues(alpha: 0.0),
                ],
              ),
            ),
            // 🩹 תוקן: "הורדת את כפתור החזרה/הבית, הם ירדו למטה" - עם הוספת
            // _buildShortcutsRow (ליגה/הישגים) מתחת למתג נקודות/רצף, העמודה
            // הימנית נהייתה גבוהה יותר. ה-Row החיצוני הזה לא הגדיר
            // crossAxisAlignment בכלל (ברירת מחדל: center) - כך שכפתורי
            // הבית/רענון (שלא גדלים) התמרכזו כלפי מטה יחד עם העמודה
            // הגבוהה יותר, במקום להישאר צמודים לחלק העליון. crossAxisAlignment.start
            // מצמיד את שניהם לראש הכותרת תמיד, בלי קשר לגובה הצד השני.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassIconButton(
                  icon: Icons.home_rounded,
                  color: const Color(0xFFFFD86B),
                  accent: true,
                  onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                ),
                const SizedBox(width: 8),
                _GlassIconButton(icon: Icons.refresh_rounded, color: Colors.white70, onTap: _scrollToTop),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("טבלה ארצית",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                        SizedBox(width: 8),
                        Text("🏆", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildModeSwitch(),
                    const SizedBox(height: 8),
                    _buildShortcutsRow(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 "ליגה" ו"הישגים" - שורה נפרדת מתחת למתג נקודות/רצף, כדי שלא יידחסו
  // יחד עם שני הצ'יפים הקיימים לרוחב אחד צר מדי במסכים קטנים.
  Widget _buildShortcutsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        _linkChip(label: "ליגה שבועית", emoji: "🏅", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeagueScreen()))),
        const SizedBox(width: 8),
        _linkChip(label: "הישגים", emoji: "🎖️", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()))),
      ],
    );
  }

  // 🆕 מתג "נקודות / רצף" - שתי אפשרויות שאפשר לבחור ביניהן, כדי לצפות
  // בטבלה הארצית ממוינת לפי XP או לפי שיא הרצף הגבוה ביותר אי-פעם.
  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          _modeChip(label: "מדליות", emoji: "🎖️", mode: _BoardMode.medals),
          const SizedBox(width: 4),
          _modeChip(label: "נקודות", emoji: "🏆", mode: _BoardMode.points),
        ],
      ),
    );
  }

  // 🆕 צ'יפ שמנווט למסך אחר (ליגה שבועית / הישגים) במקום לשנות את מצב הטבלה.
  Widget _linkChip({required String label, required String emoji, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        AudioManager.playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withValues(alpha: 0.08)),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12.5)),
            const SizedBox(width: 4),
            Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _modeChip({required String label, required String emoji, required _BoardMode mode}) {
    final bool selected = _mode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: selected ? const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF9A3C)]) : null,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12.5)),
            const SizedBox(width: 5),
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: selected ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 60),
            const SizedBox(height: 15),
            Text(
              error!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC64B)),
              child: const Text("נסה שוב", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        "עדיין אין ניקוד בטבלה.\nהיה הראשון לפתור לוגו!",
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  Widget _buildBoard() {
    // מוצאים את המיקום האמיתי שלי ברשימה המלאה (יכול להיות גם מעבר ל-50)
    int myIndex = -1;
    if (myDeviceId.isNotEmpty) {
      myIndex = entries.indexWhere((e) => (e["deviceId"] ?? "") == myDeviceId);
    }
    final int? myRank = myIndex >= 0 ? myIndex + 1 : null;

    // מגבילים ל-50 הראשונים בלבד (מונע רשימה שגדלה ללא גבול)
    final capped = entries.take(_maxDisplayed).toList();
    final top3 = capped.take(3).toList();
    final rest = capped.length > 3 ? capped.sublist(3) : <Map<String, dynamic>>[];
    final topXp = capped.isNotEmpty ? max(1, _asInt(capped.first[_metricKey])) : 1;

    // האם השורה שלי כבר קיימת בתוך ה-50 הראשונים (רק לא בהכרח בטופ 10)
    final bool myRowIsInCappedList = myRank != null && myRank <= _maxDisplayed;
    // מעבר ל-50 - אין לי שורה ברשימה הרגילה, מוסיפים אותה בנפרד בסוף
    final bool showMyRowAppended = myRank != null && !myRowIsInCappedList;
    // מציגים תג צף כל עוד אני לא בין 10 הראשונים
    final bool needsFloating = myRank != null && myRank > _floatingThreshold;

    return Stack(
      children: [
        RefreshIndicator(
          color: const Color(0xFFFFC64B),
          backgroundColor: const Color(0xFF2C2C3E),
          onRefresh: _load,
          // ⚠️ בכוונה SingleChildScrollView+Column ולא ListView(children: [...]):
          // גם ListView "רגיל" עם רשימת children בונה את השורות שלו בעצלנות
          // (SliverList), כך ש-_myRowKey.currentContext הוא null כל עוד השורה
          // שלי לא נכנסה בעבר לטווח שכבר נבנה - וזה בדיוק מה שגרם ל"קפיצה
          // לראש הטבלה" במקום גלילה למיקום שלי (ה"רשת ביטחון" הייתה מופעלת
          // כמעט תמיד). עם Column כל השורות (עד 50) תמיד בנויות בפועל, כך
          // ש-ensureVisible עובד נכון בכל טווח.
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            // 🆕 +108 לריפוד התחתון כדי שהתוכן יגלול מעל סרגל הניווט הקבוע החדש
            // 🐛 תוקן: הריפוד התחתון היה קבוע (108) ולא כלל את
            // MediaQuery.padding.bottom (אזור הבטוח התחתון - למשל פס
            // המחוות באנדרואיד/הבית ב-iPhone) - בדיוק כמו ש-AppBottomNav
            // עצמו מוסיף אותו לגובה שלו (ראו app_bottom_nav.dart:136).
            // במכשירים עם אזור בטוח תחתון, הסרגל היה בפועל גבוה יותר
            // מהריפוד שחישבנו לו, ומכסה את השורה האחרונה בטבלה.
            padding: EdgeInsets.fromLTRB(16, _headerHeight + 12, 16, (needsFloating ? 106 : 30) + 108 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _FadeSlideIn(index: 0, child: _buildPodium(top3)),
              if (myRank != null) ...[
                const SizedBox(height: 14),
                _FadeSlideIn(index: 1, child: _buildMyStatsRow(entries[myIndex], myRank)),
              ],
              const SizedBox(height: 20),
              _buildSectionDivider(_byMedals ? "$_maxDisplayed לפי מדליות" : "$_maxDisplayed המובילים"),
              const SizedBox(height: 12),
              for (int i = 0; i < rest.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _FadeSlideIn(
                    index: i + 2,
                    child: (myRank != null && (i + 4) == myRank)
                        // זו השורה האמיתית שלי - עוטפים ב-_PulseHighlight (עם מפתח)
                        // כדי שנוכל להפעיל עליה "הבהוב" קצר כשגוללים אליה
                        ? _PulseHighlight(key: _myRowKey, child: _buildRow(rest[i], i + 4, topXp))
                        : _buildRow(rest[i], i + 4, topXp),
                  ),
                ),

              // מעבר ל-50 הראשונים: מוסיפים קו מפריד ואת השורה שלי בסוף,
              // כדי שאפשר יהיה לגלול אליה ולראות אותה
              if (showMyRowAppended) ...[
                const SizedBox(height: 6),
                _buildSectionDivider("המקום שלך"),
                const SizedBox(height: 12),
                _PulseHighlight(key: _myRowKey, child: _buildRow(entries[myIndex], myRank, topXp)),
              ],
              ],
            ),
          ),
        ),

        // 🏷️ תג צף עם המיקום האמיתי שלי - קבוע בתחתית המסך (לא זז עם
        // הגלילה), ונמזג בעדינות (דהייה + כיווץ) ברגע שהשורה האמיתית שלי
        // נראית על המסך - במקום להיעלם בבת אחת
        if (needsFloating)
          Positioned(
            left: 14,
            right: 14,
            // 🆕 הועלה מ-18 ל-118 כדי לא להתנגש עם סרגל הניווט התחתון הקבוע החדש
            // 🩹 תוקן: היה קבוע (118) בלי MediaQuery.padding.bottom - בדיוק
            // אותה בעיה שתוקנה כבר בריפוד הגלילה (ראו ההערה למעלה ליד
            // SingleChildScrollView.padding) אבל נשכחה כאן. במכשיר עם אזור
            // בטוח תחתון גדול (iPhone עם home indicator) התג היה יושב נמוך
            // מדי וחופף לסרגל הניווט הקבוע - בדיוק מה שדווח ("חלק מהמסך
            // הזה חסום בגלל הלמטה").
            bottom: 118 + MediaQuery.of(context).padding.bottom,
            // ⚠️ בכוונה בלי IgnorePointer כאן: קודם היה חוסם לחיצות על
            // התג כשהחישוב של "השורה שלי כבר נראית" החזיר תוצאה שגויה
            // (למשל מיד עם פתיחת המסך, לפני גלילה ראשונה) - מה שגרם
            // ללחיצות על התג "לא לעשות כלום". העמעום/הכיווץ נשארים
            // ויזואליים בלבד - התג תמיד לחיץ כשהוא מוצג (needsFloating).
            child: AnimatedOpacity(
              opacity: _myRowVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut,
              child: AnimatedScale(
                scale: _myRowVisible ? 0.84 : 1.0,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOut,
                child: _buildFloatingRankBadge(entries[myIndex], myRank),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.22)]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.02)]),
            ),
          ),
        ),
      ],
    );
  }

  // שלוש כרטיסיות מיני עם הסטטיסטיקה שלי: מקום / XP / רצף
  Widget _buildMyStatsRow(Map<String, dynamic> me, int rank) {
    int streak = _asInt(me["streak"]);
    // ⚠️ שורת הסיכום הזו תמיד גלויה מתחת לפודיום (זה הדבר הכי בולט
    // שקשור אליי במסך) - לכן היא גם לחיצה ומובילה ל-_scrollToMyRow,
    // בדיוק כמו התג הצף והשורה עצמה.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _scrollToMyRow,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(child: _miniStat("#$rank", "המקום שלך", const Color(0xFFFFC64B))),
            const SizedBox(width: 8),
            if (_byMedals) ...[
              Expanded(child: _miniStat("🎖️ ${_asInt(me["medals"])}", "מדליות", const Color(0xFFFFD86B))),
              const SizedBox(width: 8),
              Expanded(child: _miniStat("${_asInt(me["xp"])}", "XP שלך", const Color(0xFF93C5FD))),
            ] else ...[
              Expanded(child: _miniStat("${_asInt(me["xp"])}", "XP שלך", const Color(0xFF93C5FD))),
              const SizedBox(width: 8),
              Expanded(child: _miniStat("🔥 $streak", "רצף", const Color(0xFFFF8A5B))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // התג הצף - מוצג במקום קבוע על המסך: מסגרת-זוהר, מילוי חם, ברק עדין
  // למעלה, ומספר/שם/XP/רצף + חץ שמנתר בעדינות כלפי מטה.
  Widget _buildFloatingRankBadge(Map<String, dynamic> entry, int rank) {
    int streak = _asInt(entry["streak"]);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _scrollToMyRow,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: 0.65), const Color(0xFFFFD86B).withValues(alpha: 0.2)],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 26, offset: const Offset(0, 10)),
              BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.28), blurRadius: 30),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)],
              ),
            ),
            child: Stack(
              children: [
                // 🆕 הוסרה שכבת "הברק" הלבנה שהייתה כאן - יצרה כתם לבן
                // בתוך הכפתור הזהוב, לפי בקשה מפורשת להסיר אותה לגמרי.
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: const Color(0xFF2A1740).withValues(alpha: 0.85),
                      ),
                      child: Center(
                        child: Text("#$rank",
                            style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 13, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${entry["name"] ?? ""}  (אתה)",
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 1),
                          Text("הקש כדי לגלול למקום שלך",
                              textDirection: TextDirection.rtl,
                              style: TextStyle(color: const Color(0xFF2A1740).withValues(alpha: 0.62), fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Column(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${_asInt(entry["xp"])} XP",
                            style: const TextStyle(color: Color(0xFF2A1740), fontSize: 13.5, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 1),
                        Text("🔥 $streak",
                            style: TextStyle(color: const Color(0xFF2A1740).withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const _BouncingChevron(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== פודיום 🥇🥈🥉 =====================
  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    Map<String, dynamic>? p1 = top3.isNotEmpty ? top3[0] : null;
    Map<String, dynamic>? p2 = top3.length > 1 ? top3[1] : null;
    Map<String, dynamic>? p3 = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.015)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // זוהר עדין מאחורי מקום ראשון
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFFFFD86B).withValues(alpha: 0.22), const Color(0xFFFFD86B).withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 100,
                child: p2 != null
                    ? _buildPodiumSpot(p2, 2, 118, const Color(0xFFC7D0DA))
                    : const SizedBox(),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 116,
                child: p1 != null ? _buildPodiumSpot(p1, 1, 152, const Color(0xFFFFD86B)) : const SizedBox(),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 100,
                child: p3 != null
                    ? _buildPodiumSpot(p3, 3, 92, const Color(0xFFD69A63))
                    : const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(Map<String, dynamic> entry, int place, double height, Color color) {
    bool isMe = (entry["deviceId"] ?? "") == myDeviceId && myDeviceId.isNotEmpty && (entry["deviceId"] ?? "").isNotEmpty;
    String name = _asString(entry["name"]);
    String initial = name.isNotEmpty ? name.characters.first : "?";
    int streak = _asInt(entry["streak"]);
    bool isFirst = place == 1;
    double avatarSize = isFirst ? 68 : 50;

    // גם בפודיום - אם זו אני, הופכים את כל הכרטיס ללחיץ ומצמידים אליו את
    // _myRowKey (בדיוק כמו שורה רגילה ברשימה) - כך ש-_scrollToMyRow תמיד
    // ימצא אותי, גם אם אני נמצא/ת בפודיום (מקום 1-3) ולא ברשימה הרגילה.
    final Widget podiumCard = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isMe ? _scrollToMyRow : null,
        borderRadius: BorderRadius.circular(18),
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst)
          const Text("👑", style: TextStyle(fontSize: 22))
        else
          Text(place == 2 ? "🥈" : "🥉", style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        SizedBox(
          width: avatarSize + 12,
          height: avatarSize + 12,
          child: isFirst ? _SpinningRingAvatar(initial: initial, size: avatarSize) : _buildPlainAvatar(initial, avatarSize, color),
        ),
        const SizedBox(height: 8),
        isMe
            ? ShaderMask(
                shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFF3CF), Color(0xFFFFC64B)]).createShader(r),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white, fontSize: isFirst ? 16 : 13.5, fontWeight: FontWeight.w900),
                ),
              )
            : Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: isFirst ? 16 : 13.5, fontWeight: FontWeight.bold),
              ),
        const SizedBox(height: 3),
        if (_byMedals)
          Text("${_asInt(entry["xp"])} XP", style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, fontWeight: FontWeight.bold))
        else if (streak > 0)
          Text("🔥 $streak", style: const TextStyle(color: Color(0xFFFF8A5B), fontSize: 11.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 9),
        // עמוד הפודיום
        Container(
          height: height,
          width: double.infinity,
          padding: EdgeInsets.only(top: isFirst ? 16 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(isFirst ? 22 : 20), bottom: const Radius.circular(6)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: isFirst ? 0.62 : 0.5)),
              left: BorderSide(color: color.withValues(alpha: isFirst ? 0.62 : 0.5)),
              right: BorderSide(color: color.withValues(alpha: isFirst ? 0.62 : 0.5)),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isFirst
                  ? [const Color(0xFFFFC95A).withValues(alpha: 0.52), const Color(0xFFFF9A3C).withValues(alpha: 0.08)]
                  : [color.withValues(alpha: 0.42), color.withValues(alpha: 0.06)],
            ),
            boxShadow: isFirst
                ? [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.28), blurRadius: 26, offset: const Offset(0, -6))]
                : null,
          ),
          child: Column(
            children: [
              Text("$place",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: isFirst ? 1 : 0.9),
                      fontSize: isFirst ? 30 : 22,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: isFirst ? 8 : 5),
              Text(_byMedals ? "${_asInt(entry["medals"])}" : "${_asInt(entry["xp"])}",
                  style: TextStyle(color: Colors.white, fontSize: isFirst ? 19 : 15, fontWeight: FontWeight.w900)),
              Text(_byMedals ? "מדליות" : "XP", style: TextStyle(color: Colors.white.withValues(alpha: isFirst ? 0.7 : 0.55), fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
        ),
      ],
        ),
      ),
    );
    return isMe ? _PulseHighlight(key: _myRowKey, child: podiumCard) : podiumCard;
  }

  // ⚠️ עטוף ב-Center: הקוראים ל-widget הזה (_buildPodiumSpot) שמים אותו
  // בתוך SizedBox עם גודל קבוע (avatarSize+12) - כלומר הוא מקבל אילוצי
  // גודל "צמודים" (tight) מהאב. בלי ה-Center הזה, ה-Container החיצוני
  // (בלי width/height עצמי) נאלץ להימתח לגודל המלא של ה-SizedBox, אבל
  // ה-Container הפנימי נשאר בגודל size המדויק שלו - וכתוצאה מכך העיגול
  // הפנימי "נדחק" לפינה במקום להיות ממורכז, בדיוק הבאג שדווח.
  Widget _buildPlainAvatar(String initial, double size, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [color, color.withValues(alpha: 0.45), color]),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14)],
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
          ),
          child: Center(
            child: Text(initial, style: const TextStyle(color: Color(0xFF231536), fontSize: 19, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  // ===================== שורות 4 ומטה =====================
  Widget _buildRow(Map<String, dynamic> entry, int place, int topXp) {
    bool isMe = (entry["deviceId"] ?? "") == myDeviceId && myDeviceId.isNotEmpty && (entry["deviceId"] ?? "").isNotEmpty;
    int streak = _asInt(entry["streak"]);
    int xp = _asInt(entry["xp"]);
    int medals = _asInt(entry["medals"]);
    double pct = ((_byMedals ? medals : xp) / topXp).clamp(0.02, 1.0);
    String name = _asString(entry["name"]);

    // ⚠️ עוטפים ב-Material+InkWell (לא רק את התג הצף!) כדי שלחיצה על
    // "השם שלי" תמיד תעשה משהו - כולל כשהשורה שלי כבר גלויה בתוך הרשימה
    // (בלי תג צף כלל, למשל אם אני בין ה-10 הראשונים). לחיצה כזו קוראת
    // ל-_scrollToMyRow שמפעילה פעימת-זוהר קצרה כאישור ויזואלי.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isMe ? _scrollToMyRow : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? const Color(0xFFFFC64B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.09),
          width: isMe ? 1.6 : 1,
        ),
        gradient: isMe
            ? const LinearGradient(colors: [Color(0x42FFC64B), Color(0x12FF9A3C)])
            : LinearGradient(colors: [Colors.white.withValues(alpha: 0.075), Colors.white.withValues(alpha: 0.02)]),
        boxShadow: isMe
            ? [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 6))]
            : null,
      ),
      child: Stack(
        children: [
          // מספר ענק שקוף ברקע - "watermark" בדיוק כמו בעיצוב
          Positioned(
            top: -14,
            left: -2,
            child: Text("$place",
                style: TextStyle(
                    color: isMe ? const Color(0xFFFFC64B).withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    height: 1)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isMe ? const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF9A3C)]) : null,
                    color: isMe ? null : Colors.white.withValues(alpha: 0.07),
                    border: isMe ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Center(
                    child: Text("$place",
                        style: TextStyle(
                            color: isMe ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.78),
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMe ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.96),
                                fontSize: isMe ? 15.5 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD86B).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("אתה",
                                  style: TextStyle(color: Color(0xFF2A1740), fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // פס התקדמות יחסי לניקוד המוביל בטבלה
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 4,
                          color: Colors.black.withValues(alpha: isMe ? 0.22 : 0.08),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerRight,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF9A3C)])
                                    : LinearGradient(colors: [
                                        const Color(0xFF93C5FD).withValues(alpha: 0.9),
                                        const Color(0xFFA855F7).withValues(alpha: 0.75),
                                      ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _byMedals
                      ? [
                          Text("🎖️ $medals",
                              style: TextStyle(
                                  color: isMe ? const Color(0xFFFFE7A8) : const Color(0xFFFFD86B),
                                  fontSize: isMe ? 14.5 : 14,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text("$xp XP", style: TextStyle(color: const Color(0xFFBFDBFE).withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.bold)),
                        ]
                      : [
                          Text("$xp",
                              style: TextStyle(
                                  color: isMe ? const Color(0xFFFFE7A8) : const Color(0xFFBFDBFE),
                                  fontSize: isMe ? 14.5 : 14,
                                  fontWeight: FontWeight.w900)),
                          if (streak > 0) ...[
                            const SizedBox(height: 2),
                            Text("🔥 $streak", style: TextStyle(color: const Color(0xFFFF8A5B).withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  // המרה בטוחה למספר (הסקריפט יכול להחזיר מחרוזת/מספר/ריק)
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // המרה בטוחה לטקסט - הגנה נוספת אם השם מגיע כמספר מהגיליון
  // (למשל אם שחקן בחר שם שהוא רק ספרות)
  String _asString(dynamic v) {
    if (v == null) return "";
    return v.toString();
  }
}

// ============================================================
// רקע "אורורה": גרדיאנט בסיס סגול-כחול כהה, שלושה כתמי צבע מיטשטשים
// שנעים לאט (מקביל ל-CSS blur + keyframe aurora), רשת נקודות דקה,
// כמה כוכבים מנצנצים, וסימני "?" ענקיים שצפים בעדינות ברקע - נושא
// המשחק (זהה את הלוגו) בא לידי ביטוי גם ברקע של הטבלה.
// ============================================================
class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // גרדיאנט בסיס
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF241154), Color(0xFF33176B), Color(0xFF1E1050), Color(0xFF120C2E)],
              stops: [0.0, 0.3, 0.62, 1.0],
            ),
          ),
        ),
        // כתמי אורורה נעים
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final dx = sin(t * 2 * pi) * 24;
            final dy = cos(t * 2 * pi) * 14;
            return Stack(
              children: [
                Positioned(
                  top: 40 + dy,
                  right: -60 + dx,
                  child: _blob(260, const Color(0xFFFF8E3C).withValues(alpha: 0.28)),
                ),
                Positioned(
                  top: 220 - dy,
                  left: -70 - dx,
                  child: _blob(300, const Color(0xFFA855F7).withValues(alpha: 0.28)),
                ),
                Positioned(
                  bottom: -40 + dx,
                  right: 40 - dy,
                  child: _blob(280, const Color(0xFF38BDF8).withValues(alpha: 0.18)),
                ),
              ],
            );
          },
        ),
        // רשת נקודות דקה
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        // סימני "?" צפים + כוכבים מנצנצים
        Positioned.fill(child: _FloatingMarks(controller: _controller)),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingMarks extends StatelessWidget {
  final AnimationController controller;
  const _FloatingMarks({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        double drift(double phase) => sin((t + phase) * 2 * pi) * 8;
        return Stack(
          children: [
            Positioned(
              top: 70 + drift(0),
              right: -10,
              child: Text("?", style: TextStyle(fontSize: 130, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900)),
            ),
            Positioned(
              top: size.height * 0.4 + drift(0.35),
              left: -18,
              child: Text("?", style: TextStyle(fontSize: 160, color: Colors.white.withValues(alpha: 0.04), fontWeight: FontWeight.w900)),
            ),
            Positioned(
              bottom: 40 + drift(0.7),
              right: 24,
              child: Text("?", style: TextStyle(fontSize: 100, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900)),
            ),
            // כוכבים מנצנצים
            Positioned(top: 130, left: 40, child: _Twinkle(controller: controller, phase: 0)),
            Positioned(top: size.height * 0.45, right: 36, child: _Twinkle(controller: controller, phase: 0.4, color: const Color(0xFFFFD86B))),
            Positioned(bottom: 160, left: 66, child: _Twinkle(controller: controller, phase: 0.75, color: const Color(0xFFA5F3FC))),
          ],
        );
      },
    );
  }
}

class _Twinkle extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  final Color color;
  const _Twinkle({required this.controller, required this.phase, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = (sin((controller.value + phase) * 2 * pi) + 1) / 2; // 0..1
        return Opacity(
          opacity: 0.18 + v * 0.52,
          child: Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        );
      },
    );
  }
}

// ============================================================
// אווטאר מקום ראשון עם טבעת זוהר מסתובבת (מקביל ל-conic-gradient +
// spinRing 7s ב-CSS) - משתמש ב-SweepGradient (הגרסה הזהה ב-Flutter
// ל-conic-gradient) עם סיבוב איטי ורציף.
// ============================================================
class _SpinningRingAvatar extends StatefulWidget {
  final String initial;
  final double size;
  const _SpinningRingAvatar({required this.initial, required this.size});

  @override
  State<_SpinningRingAvatar> createState() => _SpinningRingAvatarState();
}

class _SpinningRingAvatarState extends State<_SpinningRingAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.rotate(angle: _controller.value * 2 * pi, child: child),
          child: Container(
            width: widget.size + 14,
            height: widget.size + 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0x00FFD86B),
                Color(0xFFFFD86B),
                Color(0xFFFF9A3C),
                Color(0x00FFD86B),
              ]),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFF9A3C)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFFAA3C).withValues(alpha: 0.55), blurRadius: 26)],
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFFA94D)]),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
            ),
            child: Center(
              child: Text(widget.initial, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 25, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// כפתור זכוכית קטן לכותרת (רענון / בית)
// ============================================================
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool accent;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.color, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? const Color(0xFFFFD86B).withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent ? const Color(0xFFFFD86B).withValues(alpha: 0.38) : Colors.white.withValues(alpha: 0.14)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(icon, color: color, size: 17)),
      ),
    );
  }
}

// ============================================================
// כניסה מדורגת (Fade + Slide) לכל שורה/פודיום ברשימה - נותנת תחושת
// "קסם" עדינה כשהמסך נטען, בלי לעכב את התצוגה בפועל (רק אנימציית כניסה).
// ============================================================
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  const _FadeSlideIn({required this.child, required this.index});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    // מגבילים את השהיית ה"מדרגה" ל-12 הראשונים בלבד - כדי שגלילה מהירה
    // לרשימה ארוכה לא תיתקע עם עשרות אנימציות ממתינות בתור
    final delay = Duration(milliseconds: 45 * widget.index.clamp(0, 12));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ============================================================
// עוטף את השורה האמיתית שלי ומאפשר להפעיל עליה "פעימת זוהר" קצרה
// (pulse()) בכל פעם שגוללים אליה מהתג הצף - כדי שברור מיד היכן היא נחתה.
// ============================================================
class _PulseHighlight extends StatefulWidget {
  final Widget child;
  const _PulseHighlight({super.key, required this.child});

  @override
  State<_PulseHighlight> createState() => _PulseHighlightState();
}

class _PulseHighlightState extends State<_PulseHighlight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void pulse() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _glow.value > 0
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFCD5A).withValues(alpha: 0.6 * _glow.value),
                      blurRadius: 34 * _glow.value,
                      spreadRadius: 3 * _glow.value,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================
// חץ קטן שמנתר בעדינות למטה בתוך התג הצף - רמז ויזואלי לא פולשני
// שאפשר ללחוץ כדי לגלול למיקום האמיתי.
// ============================================================
class _BouncingChevron extends StatefulWidget {
  const _BouncingChevron();

  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: 4).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2A1740), size: 20),
    );
  }
}