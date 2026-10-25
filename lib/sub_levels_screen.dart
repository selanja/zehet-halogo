//sub_levels_screen
// 🎨 עוצב מחדש בדיוק לפי מוקאפ "Levels_Screen.html": כרטיס התקדמות עם
// אחוזים בגרדיאנט זהב, גריד 3 עמודות מרובע (לא מלבני) עם 3 מצבי אריח
// (הושלם/פעיל/נעול) כולל תג-מספר בפינה עליונה, וסרגל "המשך לשלב X" צף
// קבוע בתחתית המסך.
// ⚠️ בלי "שלב בונוס נעול" (רמת אגדה/לוגואים נדירים) - פיצ'ר שלא קיים
// באפליקציה שלנו, הוסר במפורש לפי בקשת המשתמש (כמו ברמת אגדה בעולמות).
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logo_level_screen.dart';
import 'level_loading_screen.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'review_manager.dart';
import 'app_notification.dart';
import 'first_visit_explainer.dart'; // 🆕 הסבר חד-פעמי בכניסה הראשונה למסך
import 'l10n/app_localizations.dart';

class SubLevelsScreen extends StatefulWidget {
  final int mainLevel; // מקבל את הרמה הראשית (1, 2, 3...)

  const SubLevelsScreen({super.key, required this.mainLevel});

  @override
  State<SubLevelsScreen> createState() => _SubLevelsScreenState();
}

class _SubLevelsScreenState extends State<SubLevelsScreen> {
  int maxUnlockedLevel = 1;

  // 🆕 הסבר חד-פעמי - ראו first_visit_explainer.dart. לפי בקשה מפורשת:
  // "הסבר על הרמות ואז שילחץ על הרמה ואז הסבר על השלבים הוא לוחץ על
  // השלב ואז ממשיך להסביר בפנים" - זה שלב הביניים בין רשימת העולמות
  // (levels_screen.dart) לבין ההדרכה בתוך המשחק עצמו (logo_level_screen.dart).
  // 🩹 אותו דפוס שני-שלבים כמו ב-levels_screen.dart: שלב 0 מסביר את
  // מנגנון הנעילה עם כפתור "המשך", שלב 1 ספוטלייט על השלב הפתוח הראשון.
  bool _showExplainer = false;
  int _explainerStep = 0;
  final GlobalKey _tourFirstTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 🐛 תוקן: מסך בחירת השלב (מצב קלאסי) מעולם לא נספר כ"גלישה".
    AdsManager.recordBrowseNavigation();
    // 🩹 תוקן באג מדווח: הסיור הוצג גם למשתמש עם משתמש/התקדמות אמיתית
    // (לדוגמה אחרי שחזור ענן שמאפס את דגל "נראה כבר" המקומי בלי לאפס את
    // ההתקדמות בפועל) - "אם הוא לא ברמה 1 זה לא יעבוד לו" - עכשיו ממתינים
    // לטעינת ההתקדמות האמיתית ומציגים את הסיור רק אם המשתמש באמת בשלב 1.
    _loadProgress().then((_) async {
      final show = await FirstVisitExplainer.shouldShow('subLevels');
      if (show && maxUnlockedLevel <= 1 && mounted) {
        setState(() => _showExplainer = true);
      }
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    int globalMax = prefs.getInt('maxLevel') ?? 1;

    // אם הרמה הזו נרכשה מראש בתשלום (לפני שההתקדמות הרגילה הגיעה אליה) -
    // ההתקדמות שלה נשמרת בסמן נפרד, כדי שלא "נדרוס" רמות קודמות שעדיין
    // לא נפתרו. ⚠️ אותו מנגנון קיים ב-levels_screen.dart וב-iap_manager.dart.
    List<String> purchasedWorlds = prefs.getStringList('purchasedWorlds') ?? [];
    int effectiveMax = globalMax;
    if (purchasedWorlds.contains(widget.mainLevel.toString())) {
      int worldCursor = prefs.getInt('worldCursor_${widget.mainLevel}') ??
          getFirstPuzzleIdOfMainLevel(widget.mainLevel);
      if (worldCursor > effectiveMax) effectiveMax = worldCursor;
    }

    if (!mounted) return;
    setState(() {
      maxUnlockedLevel = effectiveMax;
    });
  }

  // 🆕 נקרא בלחיצה על כפתור "בית" - מציג פופאפ דירוג בפעם הראשונה בלבד
  // (הלוגיקה המשותפת נמצאת ב-review_manager.dart, ראו logo_level_screen.dart)
  Future<void> _onHomePressed() async {
    await ReviewManager.handleHomeButtonTap(context);
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  // העתקת מפת הכמויות הגמישה כדי להתאים למסך הראשי
  final Map<int, int> levelsCounts = {
    1: 35,
    2: 33,
    3: 23,
    4: 33,
    5: 19,
    6: 28,
    7: 31,
    8: 29,
    9: 27,
    10: 35,
    11: 27,
    12: 33,
    13: 22,
    14: 23, // NBA
    15: 37, // יחידות בצה"ל וכוחות הביטחון
    16: 23, // רכבים חלק ב
    17: 22, // אלקטרוניקה ומכשירי חשמל
    18: 18, // תקשורת וחדשות ישראליות
    19: 40, // דגלים חלק ג'
    20: 20, // אלקטרוניקה חלק ב
    21: 18, // כדורסל אירופי - יורוליג
    22: 32, // NFL - פוטבול אמריקאי
    23: 30, // קבוצות כדורגל ישראליות - ליגת העל וליגה לאומית
    24: 30, // אולפני סרטים ובידור עולמי
    25: 30, // חברות תעופה
    26: 34, // קבוצות כדורגל אירופאיות חלק ב'
  };

  // פונקציה שמחזירה את שם הקטגוריה לפי מספר הרמה
  String getWorldName(int worldNum) {
    final loc = AppLocalizations.of(context)!;
    switch (worldNum) {
      case 1:
        return loc.worldName1;
      case 2:
        return loc.worldName2;
      case 3:
        return loc.worldName3;
      case 4:
        return loc.worldName4;
      case 5:
        return loc.worldName5;
      case 6:
        return loc.worldName6;
      case 7:
        return loc.worldName7;
      case 8:
        return loc.worldName8;
      case 9:
        return loc.worldName9;
      case 10:
        return loc.worldName10;
      case 11:
        return loc.worldName11;
      case 12:
        return loc.worldName12;
      case 13:
        return loc.worldName13;
      case 14:
        return loc.worldName14;
      case 15:
        return loc.worldName15;
      case 16:
        return loc.worldName16;
      case 17:
        return loc.worldName17;
      case 18:
        return loc.worldName18;
      case 19:
        return loc.worldName19;
      case 20:
        return loc.worldName20;
      case 21:
        return loc.worldName21;
      case 22:
        return loc.worldName22;
      case 23:
        return loc.worldName23;
      case 24:
        return loc.worldName24;
      case 25:
        return loc.worldName25;
      case 26:
        return loc.worldName26;
      default:
        return loc.worldNameDefault;
    }
  }

  // פונקציה שמחשבת את ה-puzzleId הראשון של רמה מסוימת
  int getFirstPuzzleIdOfMainLevel(int mainLevel) {
    int startId = 1;
    for (int i = 1; i < mainLevel; i++) {
      startId += levelsCounts[i] ?? 23;
    }
    return startId;
  }

  // 🆕 עובר קודם דרך מסך "טעינת שלב" (LevelLoadingScreen, לפי מוקאפ
  // "מכינים את השלב...") במקום לקפוץ ישר לחידה - מציג לרגע קצר את
  // הקטגוריה/מספר השלב וטיפ אקראי, אז מחליף אוטומטית למסך המשחק עצמו.
  void _openPuzzle(int puzzleId, int displayNum) {
    AudioManager.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelLoadingScreen(
          puzzleId: puzzleId,
          categoryLabel: AppLocalizations.of(context)!.subLevelsCategoryStageLabel(getWorldName(widget.mainLevel), displayNum),
        ),
      ),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // חישוב דינמי של ה-ID הראשון ברמה הזו לפי מפת הכמויות
    int startPuzzleId = getFirstPuzzleIdOfMainLevel(widget.mainLevel);
    // שליפת כמות השלבים הייחודית לרמה הזו (ברירת מחדל 23)
    int totalSubLevels = levelsCounts[widget.mainLevel] ?? 23;
    // שליפת שם הקטגוריה
    String categoryName = getWorldName(widget.mainLevel);

    // כמה שלבים הושלמו/נותרו - לכרטיס סיכום ההתקדמות שבראש המסך, ולסרגל
    // ה"המשך" הצף בתחתית. currentDisplayNum = השלב הבא לפתרון (1-based).
    int doneCount = (maxUnlockedLevel - startPuzzleId).clamp(0, totalSubLevels);
    int leftCount = totalSubLevels - doneCount;
    double progressPct = totalSubLevels > 0 ? (doneCount / totalSubLevels).clamp(0.0, 1.0) : 0.0;
    int currentDisplayNum = (doneCount + 1).clamp(1, totalSubLevels);
    int currentPuzzleId = startPuzzleId + currentDisplayNum - 1;
    bool allDone = doneCount >= totalSubLevels;

    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: Stack(
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            child: Stack(
              children: [
                // ===== רשימה גוללת: כרטיס התקדמות + גריד השלבים =====
                Padding(
                  padding: EdgeInsets.only(top: 78, bottom: allDone ? 12 : 92),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    children: [
                      // ===== כרטיס סיכום התקדמות =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.02)]),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF9A3C)])),
                                      child: const Center(child: Text("🏆", style: TextStyle(fontSize: 18))),
                                    ),
                                    const SizedBox(width: 9),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(loc.subLevelsYourProgressTitle, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                                        Text(
                                          allDone ? loc.subLevelsAllCompletedMessage : loc.subLevelsNextStageMessage(currentDisplayNum),
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ShaderMask(
                                  shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFF3CF), Color(0xFFFFC64B)]).createShader(r),
                                  child: Text("${(progressPct * 100).round()}%", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 11),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressPct,
                                minHeight: 7,
                                backgroundColor: Colors.black.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD86B)),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Text(loc.subLevelsDoneCount(doneCount), style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                Text(loc.subLevelsRemainingCount(leftCount), style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== גריד השלבים (3 עמודות, ריבועי) =====
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1,
                        ),
                        itemCount: totalSubLevels,
                        itemBuilder: (context, index) {
                          int puzzleId = startPuzzleId + index;
                          int displayNum = index + 1;

                          bool isCompleted = puzzleId < maxUnlockedLevel;
                          bool isActive = puzzleId == maxUnlockedLevel;
                          bool isLocked = puzzleId > maxUnlockedLevel;

                          return KeyedSubtree(
                            key: isActive ? _tourFirstTileKey : null,
                            child: _LevelTile(
                            key: ValueKey(puzzleId),
                            gridIndex: index,
                            displayNum: displayNum,
                            isCompleted: isCompleted,
                            isActive: isActive,
                            isLocked: isLocked,
                            onTap: () {
                              // 🩹 הפעלה בפועל על השלב הפתוח הראשון בזמן שלב 1 של
                              // הסיור (ראו _buildSubLevelsTourSpotlight) - מסיימת
                              // את הסיור לפני שפותחים את החידה.
                              if (_showExplainer && isActive && _explainerStep == 1) {
                                FirstVisitExplainer.markSeen('subLevels');
                                setState(() => _showExplainer = false);
                              }
                              if (isLocked) {
                                AppNotification.show(context, loc.subLevelsLockedMessage, type: AppNotificationType.warning);
                              } else if (isCompleted) {
                                AppNotification.show(context, loc.subLevelsAlreadyFoundMessage);
                              } else {
                                _openPuzzle(puzzleId, displayNum);
                              }
                            },
                          ));
                        },
                      ),
                    ],
                  ),
                ),

                // ===== כותרת עליונה קבועה (glass) =====
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [const Color(0xFF120C2E).withValues(alpha: 0.95), const Color(0xFF120C2E).withValues(alpha: 0.6), const Color(0xFF120C2E).withValues(alpha: 0.0)],
                          ),
                        ),
                        child: Row(
                          children: [
                            _GlassRoundButton(icon: Icons.arrow_back_ios_new_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      loc.subLevelsCategoryWorldLabel(categoryName, widget.mainLevel),
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    loc.subLevelsDoneOfTotal(doneCount, totalSubLevels),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _GlassRoundButton(icon: Icons.home_rounded, color: const Color(0xFFFFD86B), onTap: () => _onHomePressed()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ===== סרגל "המשך לשלב X" צף וקבוע בתחתית =====
                if (!allDone)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _openPuzzle(currentPuzzleId, currentDisplayNum),
                        child: Container(
                          padding: const EdgeInsets.all(1.6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.6), const Color(0xFFFFD86B).withValues(alpha: 0.2)]),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 12)),
                              BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.26), blurRadius: 30),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(21),
                              gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            ),
                            child: Stack(
                              children: [
                                // 🆕 הוסרה שכבת "הברק" הלבנה - יצרה כתם לבן
                                // בתוך הכפתור הזהוב, לפי בקשה מפורשת.
                                Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2A1740).withValues(alpha: 0.85)),
                                      child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFFD86B), size: 18),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            loc.subLevelsContinueToStage(currentDisplayNum),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900),
                                          ),
                                          Text(
                                            loc.subLevelsCategoryWorldLabel(categoryName, widget.mainLevel),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: const Color(0xFF2A1740).withValues(alpha: 0.62), fontSize: 10.5, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 🎨 אחוזי ההתקדמות עכשיו בתוך "כדור" זכוכית קטן ונפרד -
                                    // מפריד אותם חזותית מהכותרת בבירור, כדי שלא יתקרבו אליה.
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A1740).withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Text("${(progressPct * 100).round()}%", style: TextStyle(color: const Color(0xFF2A1740).withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_showExplainer) _buildSubLevelsTourOverlay(),
        ],
      ),
    );
  }

  void _skipSubLevelsTour() {
    AudioManager.playClick();
    FirstVisitExplainer.markSeen('subLevels');
    setState(() => _showExplainer = false);
  }

  // שלב 0: כרטיסייה ממורכזת מסבירה את מנגנון הנעילה (אותו דפוס בדיוק
  // כמו ב-levels_screen.dart, ברמת השלבים הבודדים במקום העולמות).
  Widget _buildSubLevelsTourInfoCard() {
    final loc = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: () {}, child: Container(color: const Color(0xCC0C0820)))),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 18,
            child: TextButton(
              onPressed: _skipSubLevelsTour,
              child: Text(loc.mainMenuSkipButton, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
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
                    Text(loc.subLevelsTourTitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Text(loc.subLevelsTourBody, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4)),
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
                          setState(() => _explainerStep = 1);
                        },
                        child: Text(loc.levelsTourContinueButton, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
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

  // שלב 1: ספוטלייט על השלב הפתוח הראשון.
  Widget _buildSubLevelsTourSpotlight() {
    final loc = AppLocalizations.of(context)!;
    final ctx = _tourFirstTileKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }
    final screenSize = MediaQuery.of(context).size;
    final topLeft = box.localToGlobal(Offset.zero);
    final hole = (topLeft & box.size).inflate(8);
    final showCardBelow = hole.center.dy < screenSize.height * 0.6;
    const dimColor = Color(0xCC0C0820);
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, right: 0, height: hole.top.clamp(0, screenSize.height), child: GestureDetector(onTap: () {}, child: Container(color: dimColor))),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 18,
            child: TextButton(
              onPressed: _skipSubLevelsTour,
              child: Text(loc.mainMenuSkipButton, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          Positioned(left: 0, top: hole.bottom.clamp(0, screenSize.height), right: 0, bottom: 0, child: GestureDetector(onTap: () {}, child: Container(color: dimColor))),
          Positioned(left: 0, top: hole.top, width: hole.left.clamp(0, screenSize.width), height: hole.height, child: GestureDetector(onTap: () {}, child: Container(color: dimColor))),
          Positioned(left: hole.right, top: hole.top, right: 0, height: hole.height, child: GestureDetector(onTap: () {}, child: Container(color: dimColor))),
          Positioned(
            left: hole.left,
            top: hole.top,
            width: hole.width,
            height: hole.height,
            child: IgnorePointer(
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFD86B), width: 2.5))),
            ),
          ),
          Positioned(
            top: showCardBelow ? (hole.bottom + 14).clamp(0, screenSize.height - 80) : null,
            bottom: showCardBelow ? null : (screenSize.height - hole.top + 14).clamp(0, screenSize.height - 80),
            left: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👆 ', style: TextStyle(fontSize: 15)),
                  Flexible(child: Text(loc.subLevelsTourTapHighlighted, style: const TextStyle(color: Color(0xFFFF8A3C), fontSize: 13.5, fontWeight: FontWeight.w900))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubLevelsTourOverlay() {
    return _explainerStep == 0 ? _buildSubLevelsTourInfoCard() : _buildSubLevelsTourSpotlight();
  }
}

/// כפתור עגול קטן זכוכיתי לכותרת - עקבי לכפתורי הכותרת ביתר המסכים.
class _GlassRoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassRoundButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.32))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

/// ============================================================
/// אריח שלב בודד בגריד - עיצוב "פרימיום" מוקפד: כרטיסי זכוכית עם ברק
/// (glass-morphism), אנימציית כניסה מדורגת (כל אריח "קופץ" פנימה
/// בעיכוב קטן לפי מיקומו בגריד), הילה פועמת רכה לשלב הפעיל + "מטאטא
/// אור" (shimmer) אלכסוני שעובר עליו שוב ושוב, וטבעת ברק עדינה לשלב
/// שהושלם. 3 מצבים: הושלם (ירוק-אזמרגד עם ברק זכוכית + וי לבן), פעיל
/// (זהב עם shimmer + הילה פועמת + "שחק"), נעול (זכוכית כהה מינימלית).
/// ============================================================
class _LevelTile extends StatefulWidget {
  final int gridIndex;
  final int displayNum;
  final bool isCompleted;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _LevelTile({
    super.key,
    required this.gridIndex,
    required this.displayNum,
    required this.isCompleted,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile> with TickerProviderStateMixin {
  bool _entered = false;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    // ✨ כניסה מדורגת - כל אריח "קופץ" פנימה בעיכוב קטן לפי המיקום שלו
    // בגריד, כדי שהמסך כולו ירגיש חי ומטופל ולא כמו רשימה סטטית שקופצת
    // כל התאים בבת אחת.
    // 🛠️ לפי בקשה מפורשת - הוסרו לגמרי ההילה הפועמת וה"מטאטא אור"
    // (shimmer) שהיו על האריח הפעיל: הם יצרו ריבוע/אור מוזר על הכפתור.
    // עכשיו האריחים סטטיים ונקיים, בלי שום אנימציה מלבד הכניסה המדורגת.
    final delayMs = 22 * (widget.gridIndex % 18);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context)!;
    Widget tile;
    if (widget.isLocked) {
      tile = _buildLocked();
    } else if (widget.isCompleted) {
      tile = _buildCompleted();
    } else {
      tile = _buildActive();
    }

    return AnimatedScale(
      scale: _entered ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _entered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 260),
        child: tile,
      ),
    );
  }

  Widget _buildLocked() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withValues(alpha: 0.065), Colors.white.withValues(alpha: 0.015)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(bottom: -18, left: -8, child: Text("?", textDirection: TextDirection.ltr, style: TextStyle(color: Colors.white.withValues(alpha: 0.04), fontSize: 64, fontWeight: FontWeight.w900))),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.5), size: 15),
                ),
                const SizedBox(height: 6),
                Text("${widget.displayNum}", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3FD98A), Color(0xFF1C8F5C), Color(0xFF0F6B45)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFF19D480).withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ברק זכוכית עדין מלמעלה - שכבה סטטית, בלי אנימציה
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 5),
                Text("${widget.displayNum}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // אריח "פעיל" (השלב הבא לשחק) - זהב, סטטי ונקי (בלי הילה פועמת/shimmer
  // שגרמו לגליץ' ויזואלי - הוסרו לפי בקשה מפורשת).
  Widget _buildActive() {
    // 🛠️ תוקן באג חמור: ה-Container הזה הוא הווידג'ט העליון ביותר של
    // האריח הפעיל, וקיבל תמיד constraints צמודים (tight) ישירות מתא
    // הגריד - כך שהוא תמיד ממלא ריבוע מלא בדיוק כמו שאר האריחים, בלי
    // הצורך ב-Stack חיצוני שגרם בעבר להתכווצות לכדי "גלולה" צרה.
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE9A8), Color(0xFFFFB84D), Color(0xFFFF8A3C)]),
          boxShadow: [BoxShadow(color: const Color(0xFFFFC64B).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🆕 הוסרה שכבת "הברק" הלבנה שהייתה כאן - יצרה כתם לבן בתוך
            // האריח הזהוב, לפי בקשה מפורשת להסיר אותה לגמרי.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: const Color(0xFF2A1740), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFFD86B), size: 18),
                ),
                const SizedBox(height: 4),
                Text(_loc.subLevelsPlayLabel, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                Text("${widget.displayNum}", style: const TextStyle(color: Color(0xFF6B4A1C), fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// רקע "אורורה" - זהה בעיצובו לזה שנבנה כבר בשאר המסכים, משוכפל כאן
// (פרטי לקובץ) לעקביות חזותית.
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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final dx = sin(t * 2 * pi) * 24;
            final dy = cos(t * 2 * pi) * 14;
            return Stack(
              children: [
                Positioned(top: 60 + dy, right: -60 + dx, child: _blob(240, const Color(0xFFFF8E3C).withValues(alpha: 0.22))),
                Positioned(top: 260 - dy, left: -70 - dx, child: _blob(280, const Color(0xFFA855F7).withValues(alpha: 0.26))),
                Positioned(bottom: -40 + dx, right: 40 - dy, child: _blob(240, const Color(0xFF34D399).withValues(alpha: 0.16))),
              ],
            );
          },
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        Positioned.fill(child: _FloatingMarks(controller: _controller)),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
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
            Positioned(top: 120 + drift(0), right: -18, child: Text("?", style: TextStyle(fontSize: 160, color: Colors.white.withValues(alpha: 0.05), fontWeight: FontWeight.w900))),
            Positioned(top: size.height * 0.45 + drift(0.4), left: -24, child: Text("?", style: TextStyle(fontSize: 190, color: Colors.white.withValues(alpha: 0.04), fontWeight: FontWeight.w900))),
            Positioned(bottom: 40 + drift(0.7), right: 24, child: Text("?", style: TextStyle(fontSize: 110, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900))),
          ],
        );
      },
    );
  }
}