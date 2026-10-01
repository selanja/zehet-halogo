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
import 'review_manager.dart';
import 'app_notification.dart';

class SubLevelsScreen extends StatefulWidget {
  final int mainLevel; // מקבל את הרמה הראשית (1, 2, 3...)

  const SubLevelsScreen({super.key, required this.mainLevel});

  @override
  State<SubLevelsScreen> createState() => _SubLevelsScreenState();
}

class _SubLevelsScreenState extends State<SubLevelsScreen> {
  int maxUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
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
  };

  // פונקציה שמחזירה את שם הקטגוריה לפי מספר הרמה
  String getWorldName(int worldNum) {
    switch (worldNum) {
      case 1:
        return "חברות חלק א";
      case 2:
        return "דגלים חלק א";
      case 3:
        return "אפליקציות";
      case 4:
        return "רכבים";
      case 5:
        return "סופרים";
      case 6:
        return "רשתות מוכרות";
      case 7:
        return "חטיפים וממתקים";
      case 8:
        return "קבוצות כדורגל";
      case 9:
        return "ערים בישראל";
      case 10:
        return "דגלים חלק ב";
      case 11:
        return "בנקים וביטוח";
        case 12:
        return "חברות חלק ב";
        case 13:
        return "משחקים מוכרים";
      case 14:
        return "קבוצות NBA";
      case 15:
        return "יחידות בצה\"ל וכוחות הביטחון";
      case 16:
        return "רכבים חלק ב";
      case 17:
        return "אלקטרוניקה ומכשירי חשמל";
      case 18:
        return "תקשורת וחדשות ישראליות";
      case 19:
        return "דגלים חלק ג'";
      case 20:
        return "אלקטרוניקה ומכשירי חשמל חלק ב";
      default:
        return "כללי";
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
          categoryLabel: "${getWorldName(widget.mainLevel)} · שלב $displayNum",
        ),
      ),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
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
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  textDirection: TextDirection.rtl,
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
                                        const Text("ההתקדמות שלך", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                                        Text(
                                          allDone ? "כל השלבים הושלמו!" : "השלב הבא: שלב $currentDisplayNum",
                                          textDirection: TextDirection.rtl,
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
                              textDirection: TextDirection.rtl,
                              children: [
                                Text("✓ $doneCount הושלמו", style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                Text("· נותרו $leftCount שלבים", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w700)),
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

                          return _LevelTile(
                            key: ValueKey(puzzleId),
                            gridIndex: index,
                            displayNum: displayNum,
                            isCompleted: isCompleted,
                            isActive: isActive,
                            isLocked: isLocked,
                            onTap: () {
                              if (isLocked) {
                                AppNotification.show(context, "המילה נעולה! פתור את הקודמות.", type: AppNotificationType.warning);
                              } else if (isCompleted) {
                                AppNotification.show(context, "כבר מצאת את הלוגו הזה!");
                              } else {
                                _openPuzzle(puzzleId, displayNum);
                              }
                            },
                          );
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
                                      "$categoryName · רמה ${widget.mainLevel}",
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    "$doneCount מתוך $totalSubLevels שלבים הושלמו",
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
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2A1740).withValues(alpha: 0.85)),
                                      child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFFD86B), size: 18),
                                    ),
                                    const SizedBox(width: 11),
                                    // 🛠️ תוקן באג: לעמודה הזו לא היה textDirection משלה, אז
                                    // ה-CrossAxisAlignment.start התיישר לפי כיווניות ברירת
                                    // המחדל (LTR) ודחף את הטקסט העברי שמאלה - ממש לכיוון
                                    // האחוזים, מה שיצר את המראה ה"דבוק"/מוזר. עכשיו העמודה
                                    // עצמה מוגדרת RTL, כך ש-start אכן מתיישר לימין כמו שצריך.
                                    Expanded(
                                      child: Column(
                                        textDirection: TextDirection.rtl,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "המשך לשלב $currentDisplayNum",
                                            textDirection: TextDirection.rtl,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Color(0xFF2A1740), fontSize: 15.5, fontWeight: FontWeight.w900),
                                          ),
                                          Text(
                                            "$categoryName · רמה ${widget.mainLevel}",
                                            textDirection: TextDirection.rtl,
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
        ],
      ),
    );
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
                const Text("שחק", style: TextStyle(color: Color(0xFF2A1740), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
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