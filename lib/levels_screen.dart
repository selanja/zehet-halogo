// levels_screen
// 🎨 עוצב מחדש לפי מוקאפ "בחר רמה" (מסך 03 ב-All_Screens.html): שורות
// לסירוגין (מדליון עגול מצד אחד, כרטיס זכוכית עם פס התקדמות מהצד השני),
// מחוברות בקו מקווקו אנכי במרכז, עם אותה שפת "אורורה" שכבר נבנתה
// ב-leaderboard_screen.dart / main_menu_screen.dart.
// ⚠️ בלי "רמת אגדה" / קטגוריית בונוס - הפיצ'ר הזה לא קיים באפליקציה שלנו,
// הוסר במפורש לפי בקשת המשתמש.
// רמה נעולה ניתנת לפתיחה בתשלום (₪2.90 לכל רמה) ישירות מהמסך הזה.
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub_levels_screen.dart';
import 'audio_manager.dart';
import 'iap_manager.dart';
import 'app_notification.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  int maxUnlockedLevel = 1;

  // עולמות שנפתחו "מוקדם" בתשלום, לפני שההתקדמות הרגילה הגיעה אליהם -
  // וה"סמן" הפנימי (worldCursor) שלהם, נפרד מההתקדמות הגלובלית כדי
  // שרכישת עולם קדימה לא תסמן עולמות קודמים שלא נפתרו כאילו נפתרו.
  // ⚠️ אותו מנגנון קיים ב-sub_levels_screen.dart וב-iap_manager.dart.
  Set<int> purchasedWorlds = {};
  Map<int, int> worldCursors = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
    // אם רכישת פתיחה אושרה בזמן שהמסך פתוח - מרעננים מיד
    IapManager.onLevelUnlocked = () {
      if (mounted) _loadProgress();
    };
  }

  @override
  void dispose() {
    IapManager.onLevelUnlocked = null;
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // רשימת העולמות שנפתחו מראש בתשלום, נטענת קודם כי גם מימוש "קרדיט"
    // ממתין (למטה) צריך לדעת לדלג עליהם וגם לא לגעת בהתקדמות הגלובלית.
    List<String> purchasedList = prefs.getStringList('purchasedWorlds') ?? [];

    // אם יש פתיחה ששולמה ולא מומשה (למשל האפליקציה נסגרה באמצע) -
    // מממשים אותה עכשיו על הרמה הנעולה הבאה, בלי לדרוס את ההתקדמות
    // הגלובלית - בדיוק כמו רכישה רגילה (ראה iap_manager.dart).
    int credits = await IapManager.unlockCredits();
    if (credits > 0) {
      int current = prefs.getInt('maxLevel') ?? 1;
      int next = _firstLockedWorldForList(current, purchasedList);
      if (next > 0 && await IapManager.consumeUnlockCredit()) {
        int firstPuzzle = getFirstPuzzleIdOfMainLevel(next);
        String key = next.toString();
        if (!purchasedList.contains(key)) {
          purchasedList.add(key);
          await prefs.setStringList('purchasedWorlds', purchasedList);
        }
        String cursorKey = 'worldCursor_$next';
        if ((prefs.getInt(cursorKey) ?? 0) < firstPuzzle) {
          await prefs.setInt(cursorKey, firstPuzzle);
        }
      }
    }

    Map<int, int> cursors = {};
    for (final key in purchasedList) {
      final w = int.tryParse(key);
      if (w == null) continue;
      cursors[w] = prefs.getInt('worldCursor_$w') ?? getFirstPuzzleIdOfMainLevel(w);
    }

    if (!mounted) return;
    setState(() {
      maxUnlockedLevel = prefs.getInt('maxLevel') ?? 1;
      purchasedWorlds = purchasedList.map((e) => int.tryParse(e) ?? -1).toSet();
      worldCursors = cursors;
    });
  }

  // כמות השלבים בכל רמה
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
  };

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
      default:
        return "כללי";
    }
  }

  /// אייקון שמייצג בפועל את התוכן של כל רמה
  IconData getWorldIcon(int worldNum) {
    switch (worldNum) {
      case 1:
        return Icons.business_center_rounded;
      case 2:
        return Icons.flag_rounded;
      case 3:
        return Icons.apps_rounded;
      case 4:
        return Icons.directions_car_filled_rounded;
      case 5:
        return Icons.shopping_cart_rounded;
      case 6:
        return Icons.restaurant_rounded;
      case 7:
        return Icons.cookie_rounded;
      case 8:
        return Icons.sports_soccer_rounded;
      case 9:
        return Icons.location_city_rounded;
      case 10:
        return Icons.outlined_flag_rounded;
      case 11:
        return Icons.account_balance_rounded;
      case 14:
        return Icons.sports_basketball_rounded;
      case 15:
        return Icons.shield_rounded;
      case 16:
        return Icons.directions_car_filled_rounded;
      case 17:
        return Icons.devices_rounded;
      case 18:
        return Icons.newspaper_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  int getFirstPuzzleIdOfMainLevel(int mainLevel) {
    int startId = 1;
    for (int i = 1; i < mainLevel; i++) {
      startId += levelsCounts[i] ?? 23;
    }
    return startId;
  }

  /// הרמה הנעולה הראשונה ביחס להתקדמות נתונה (0 אם אין), מדלגת על עולמות
  /// שכבר נרכשו מראש בנפרד (הם לא "נעולים" יותר גם אם ההתקדמות הרגילה
  /// עוד לא הגיעה אליהם)
  int _firstLockedWorldForList(int progress, List<String> purchasedList) {
    for (int w = 1; w <= levelsCounts.length; w++) {
      if (purchasedList.contains(w.toString())) continue;
      if (getFirstPuzzleIdOfMainLevel(w) > progress) return w;
    }
    return 0;
  }

  int _firstLockedWorldFor(int progress) =>
      _firstLockedWorldForList(progress, purchasedWorlds.map((e) => e.toString()).toList());

  /// הרמה הנעולה הראשונה כרגע - היא היחידה שניתן לרכוש
  int get nextLockedWorld => _firstLockedWorldFor(maxUnlockedLevel);

  /// הסמן האפקטיבי של רמה מסוימת - אם היא נרכשה מראש בתשלום משתמשים
  /// בסמן הפנימי שלה (worldCursor), אחרת בהתקדמות הגלובלית הרגילה
  int _effectiveCursorFor(int mainLevel) {
    if (purchasedWorlds.contains(mainLevel)) {
      int cursor = worldCursors[mainLevel] ?? getFirstPuzzleIdOfMainLevel(mainLevel);
      return cursor > maxUnlockedLevel ? cursor : maxUnlockedLevel;
    }
    return maxUnlockedLevel;
  }

  /// כמה שלבים נפתרו ברמה הזו
  int solvedInLevel(int mainLevel) {
    int start = getFirstPuzzleIdOfMainLevel(mainLevel);
    int total = levelsCounts[mainLevel] ?? 0;
    int done = _effectiveCursorFor(mainLevel) - start;
    if (done < 0) done = 0;
    if (done > total) done = total;
    return done;
  }

  /// כמה רמות (עולמות) כבר פתוחות כרגע - לתת-כותרת בראש המסך
  int get _unlockedWorldsCount {
    int count = 0;
    for (int w = 1; w <= levelsCounts.length; w++) {
      if (getFirstPuzzleIdOfMainLevel(w) <= _effectiveCursorFor(w)) count++;
    }
    return count;
  }

  String get _unlockPrice =>
      IapManager.product(IapManager.unlockLevelId)?.price ?? "₪2.90";

  // ============================================================
  // פתיחת רמה בתשלום
  // ============================================================

  void _showUnlockDialog(int world) {
    AudioManager.playClick();
    int next = nextLockedWorld;
    // כמה רמות צריך לפתוח כדי להגיע לרמה שנלחצה
    int needed = world - next + 1;
    bool isNext = world == next;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        contentPadding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC64B).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: Color(0xFFFFC64B), size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              "רמה $world נעולה",
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              isNext
                  ? "אפשר לפתוח אותה עכשיו תמורת $_unlockPrice,\nאו פשוט לסיים את הרמה הקודמת."
                  : "פתיחת רמה עולה $_unlockPrice.\nכדי להגיע לרמה $world צריך לפתוח $needed רמות,\nאחת אחרי השנייה - מתחילים ברמה $next.",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.6),
            ),
            const SizedBox(height: 6),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("לא עכשיו",
                        style: TextStyle(color: Colors.white54, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6C453),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _buyUnlock(next);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "פתח רמה $next  •  $_unlockPrice",
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            color: Color(0xFF3A2405),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900),
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

  Future<void> _buyUnlock(int world) async {
    if (world <= 0) return;
    // רושמים איזו רמה נפתחת - כדי שהרכישה תדע מה לפתוח כשהיא תאושר
    await IapManager.setPendingUnlock(world, getFirstPuzzleIdOfMainLevel(world));
    bool started = await IapManager.buy(IapManager.unlockLevelId);
    if (!started && mounted) {
      AppNotification.show(context, "פתיחת רמות אינה זמינה כרגע, נסה שוב מאוחר יותר", type: AppNotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: Stack(
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            child: Column(
              children: [
                // ===== כותרת =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          const Text(
                            "בחר רמה",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${levelsCounts.length} רמות · $_unlockedWorldsCount פתוחות",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _CircleIconButton(
                        icon: Icons.home_rounded,
                        color: const Color(0xFFFFD86B),
                        onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                      ),
                    ],
                  ),
                ),

                // ===== רשימת הרמות =====
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                    itemCount: levelsCounts.length,
                    itemBuilder: (context, index) {
                      int mainLevel = index + 1;
                      bool isLocked = getFirstPuzzleIdOfMainLevel(mainLevel) >
                          _effectiveCursorFor(mainLevel);
                      int total = levelsCounts[mainLevel] ?? 0;
                      int done = solvedInLevel(mainLevel);
                      bool isCompleted = !isLocked && done >= total;
                      bool isCurrent = !isLocked && !isCompleted;

                      return _FadeSlideIn(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: _LevelRow(
                            mainLevel: mainLevel,
                            icon: getWorldIcon(mainLevel),
                            categoryName: getWorldName(mainLevel),
                            solved: done,
                            total: total,
                            isLocked: isLocked,
                            isCompleted: isCompleted,
                            isCurrent: isCurrent,
                            reversed: index.isOdd,
                            onTap: () {
                              AudioManager.playClick();
                              if (isLocked) {
                                _showUnlockDialog(mainLevel);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubLevelsScreen(mainLevel: mainLevel),
                                  ),
                                ).then((_) => _loadProgress());
                              }
                            },
                          ),
                        ),
                      );
                    },
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

/// כפתור עגול קטן לכותרת (זכוכית, עם מסגרת בצבע נתון)
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.34))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

/// ============================================================
/// שורת רמה בודדת: מדליון עגול (עם טבעת "הילה" מסתובבת לרמה הנוכחית,
/// דומה ל-_SpinningRingAvatar שב-leaderboard_screen.dart) מצד אחד,
/// וכרטיס זכוכית עם פס התקדמות מהצד השני - לסירוגין (reversed).
/// ============================================================
class _LevelRow extends StatelessWidget {
  final int mainLevel;
  final IconData icon;
  final String categoryName;
  final int solved;
  final int total;
  final bool isLocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool reversed;
  final VoidCallback onTap;

  const _LevelRow({
    required this.mainLevel,
    required this.icon,
    required this.categoryName,
    required this.solved,
    required this.total,
    required this.isLocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.reversed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double pct = total > 0 ? (solved / total).clamp(0.0, 1.0) : 0.0;
    final Color accent = isCompleted
        ? const Color(0xFF6EE7B7)
        : isCurrent
            ? const Color(0xFFFFD86B)
            : Colors.white.withValues(alpha: 0.5);

    final medallion = SizedBox(
      width: 100,
      height: 100,
      child: isCurrent ? _SpinningHaloMedallion(icon: icon, mainLevel: mainLevel) : _PlainMedallion(icon: icon, mainLevel: mainLevel, isLocked: isLocked, isCompleted: isCompleted),
    );

    final card = Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: isLocked ? 0.14 : 0.45)),
              gradient: LinearGradient(colors: [accent.withValues(alpha: isLocked ? 0.05 : 0.18), accent.withValues(alpha: 0.03)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoryName, textDirection: TextDirection.rtl, style: TextStyle(color: isLocked ? Colors.white.withValues(alpha: 0.8) : accent, fontSize: 15.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  isLocked ? "נעול · ניתן לפתוח בתשלום" : "$solved מתוך $total שלבים",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
                if (!isLocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final rowChildren = reversed
        ? [medallion, const SizedBox(width: 14), card]
        : [card, const SizedBox(width: 14), medallion];

    return GestureDetector(
      onTap: onTap,
      child: Row(children: rowChildren),
    );
  }
}

/// מדליון "רגיל" (נעול / הושלם / עוד לא נפתח) - בלי אנימציה
class _PlainMedallion extends StatelessWidget {
  final IconData icon;
  final int mainLevel;
  final bool isLocked;
  final bool isCompleted;
  const _PlainMedallion({required this.icon, required this.mainLevel, required this.isLocked, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.02)]),
          ),
          child: Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.55), size: 24),
        ),
      );
    }
    // הושלם - עיגול ירוק עם וי
    final colors = isCompleted
        ? const [Color(0xFF86EFAC), Color(0xFF22C79A)]
        : const [Color(0xFFFFE79A), Color(0xFFFFB24D)];
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
          boxShadow: [BoxShadow(color: colors[1].withValues(alpha: 0.4), blurRadius: 18)],
        ),
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: Color(0xFF10233A), size: 32)
            : Icon(icon, color: const Color(0xFF3A2405), size: 26),
      ),
    );
  }
}

/// מדליון עם טבעת הילה מסתובבת + פעימת זוהר - לרמה הנוכחית/פעילה,
/// מקביל ל-halo-ring + haloPulse במוקאפ.
class _SpinningHaloMedallion extends StatefulWidget {
  final IconData icon;
  final int mainLevel;
  const _SpinningHaloMedallion({required this.icon, required this.mainLevel});

  @override
  State<_SpinningHaloMedallion> createState() => _SpinningHaloMedallionState();
}

class _SpinningHaloMedallionState extends State<_SpinningHaloMedallion> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // פעימת זוהר
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final v = (sin(_controller.value * 2 * pi) + 1) / 2;
                return Container(
                  width: 92 + v * 10,
                  height: 92 + v * 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFFFBE50).withValues(alpha: 0.35 + v * 0.2), const Color(0xFFFFBE50).withValues(alpha: 0.0)]),
                  ),
                );
              },
            ),
            // טבעת מסתובבת
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.rotate(angle: _controller.value * 2 * pi, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF8A3C), Color(0x26FFD86B), Color(0x26FFD86B), Color(0xFFFFD86B)]),
                ),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1C1046)),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: const Color(0xFF3A2405), size: 20),
                  const SizedBox(height: 1),
                  Text("רמה ${widget.mainLevel}", style: const TextStyle(color: Color(0xFF3A2405), fontSize: 9.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// רקע "אורורה" - זהה בעיצובו לזה שנבנה כבר ב-leaderboard_screen.dart /
// main_menu_screen.dart, משוכפל כאן (פרטי לקובץ) לעקביות חזותית.
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
              colors: [Color(0xFF2A1360), Color(0xFF3A1B78), Color(0xFF211055), Color(0xFF120C2E)],
              stops: [0.0, 0.3, 0.64, 1.0],
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
            Positioned(top: 140 + drift(0), right: -18, child: Text("?", style: TextStyle(fontSize: 150, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900))),
            Positioned(bottom: 120 + drift(0.4), left: -16, child: Text("?", style: TextStyle(fontSize: 150, color: Colors.white.withValues(alpha: 0.045), fontWeight: FontWeight.w900))),
          ],
        );
      },
    );
  }
}

// ============================================================
// כניסה מדורגת (Fade + Slide) לכל שורת רמה - זהה לזו שכבר קיימת
// ב-leaderboard_screen.dart / main_menu_screen.dart.
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
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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