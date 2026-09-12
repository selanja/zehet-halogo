// app_bottom_nav.dart
//
// 🆕 סרגל ניווט תחתון משותף - מופיע עכשיו בכל מסכי ה"טאב" הראשיים
// (בית/חנות/מובילים/משימות/חברים), לא רק במסך הבית, לפי בקשה מפורשת:
// "אני רוצה שבכל המסכים יופיע המניו למטה כדי שבמקום ללחוץ על הסימן של
// הבית למעלה הם פשוט ילחצו למטה". הכפתור המרכזי נשאר "בית" (לא "שחק") -
// לחיצה עליו תמיד מחזירה למסך הראשי (בדיוק כמו כפתור ה-Icons.home_rounded
// שכבר היה בפינה של shop_screen.dart, רק עכשיו גם כפתור מרכזי בתחתית).
// כל טאב "מסומן" (מודגש בזהב) כשנמצאים בו כרגע - לפי הפרמטר `current`.
//
// 🆕 עדכון לפי עיצוב מחדש (Claude Design): טאב "הגדרות" הוצא מהסרגל -
// גישה להגדרות עברה לאייקון גלגל-שיניים בפינת מסך הבית (ראה
// main_menu_screen.dart) - ובמקומו נכנס טאב "חברים" חדש, שמוביל למסך
// "חברים" כללי (friends_screen.dart: הזמנה כללית למשחק + אתגר דו-קרב
// כפעולה משנית) - לא רק דו-קרב כמו קודם, לפי בקשה מפורשת.
//
// עיצוב: ניווט "חכם" - מהמסך הראשי (current == home) לוחצים על טאב אחר
// עושים Navigator.push רגיל (המסך הראשי נשאר למטה במחסנית). מתוך מסך
// טאב אחר (חנות/מובילים/משימות/חברים) עוברים לטאב אחר עם pushReplacement
// (כדי לא לערום עשרות מסכים זה על זה כשעוברים בין טאבים) - כך שהמסך
// הראשי תמיד נשאר "קרקעית" יציבה של המחסנית, וכפתור "בית" תמיד יכול
// לחזור אליו עם popUntil(isFirst).
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'missions_service.dart';
import 'friends_screen.dart'; // 🆕 טאב "חברים" בסרגל התחתון - מסך "חברים" כללי (לא רק דו-קרב)

enum AppTab { home, shop, leaderboard, missions, friends }

class AppBottomNav extends StatefulWidget {
  final AppTab current;
  const AppBottomNav({super.key, required this.current});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _haloController;
  int _missionsUnclaimed = 0;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _haloController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _loadBadge();
  }

  Future<void> _loadBadge() async {
    final count = await MissionsService.unclaimedCount();
    if (mounted) setState(() => _missionsUnclaimed = count);
  }

  @override
  void dispose() {
    _ringController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  // ניווט "חכם" בין טאבים - ראו הסבר בראש הקובץ.
  void _go(BuildContext context, AppTab target, WidgetBuilder builder) {
    if (target == widget.current) return;
    if (widget.current == AppTab.home) {
      Navigator.push(context, MaterialPageRoute(builder: builder));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: builder));
    }
  }

  Future<void> _goFriends(BuildContext context) async {
    if (widget.current == AppTab.friends) return;
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    if (!context.mounted) return;
    _go(context, AppTab.friends, (_) => FriendsScreen(username: username));
  }

  void _goHome(BuildContext context) {
    if (widget.current == AppTab.home) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: 108 + MediaQuery.of(context).padding.bottom,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // רקע הסרגל
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF1E1448).withValues(alpha: 0.94), const Color(0xFF120C2E).withValues(alpha: 0.98)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 14 + MediaQuery.of(context).padding.bottom,
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 🆕 סדר תואם למוקאפ (מסך 01 · בית): משמאל לימין - חברים,
                  // משימות, [שחק], מובילים, חנות. ב-Row עם textDirection.rtl
                  // ה"ילד" הראשון ברשימה מוצג הכי מימין, אז חנות מגיע ראשון.
                  Expanded(
                    child: _TabItem(
                      icon: Icons.shopping_cart_rounded,
                      color: const Color(0xFF60A5FA),
                      label: "חנות",
                      active: widget.current == AppTab.shop,
                      onTap: () => _go(context, AppTab.shop, (_) => const ShopScreen()),
                    ),
                  ),
                  Expanded(
                    child: _TabItem(
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFFFC64B),
                      label: "מובילים",
                      active: widget.current == AppTab.leaderboard,
                      onTap: () => _go(context, AppTab.leaderboard, (_) => const LeaderboardScreen()),
                    ),
                  ),
                  SizedBox(width: 92, child: _buildHomeSlot(context)),
                  Expanded(
                    child: _TabItem(
                      icon: Icons.track_changes_rounded,
                      color: const Color(0xFFFB7185),
                      label: "משימות",
                      active: widget.current == AppTab.missions,
                      onTap: () => _go(context, AppTab.missions, (_) => const MissionsScreen()),
                      badgeCount: _missionsUnclaimed > 0 ? _missionsUnclaimed : null,
                    ),
                  ),
                  Expanded(
                    child: _TabItem(
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF7DD3FC),
                      label: "חברים",
                      active: widget.current == AppTab.friends,
                      onTap: () => _goFriends(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // כפתור "בית" מרכזי, מוגבה ומוגדל - עם טבעת מסתובבת + הילה פועמת.
  // תמיד מחזיר למסך הראשי (בדיוק כמו כפתור ה-Icons.home_rounded שכבר
  // קיים בפינת חלק מהמסכים) - ולכן לא צריך "אקטיבי" מיוחד: הבית מסומן
  // ממילא כי הוא תמיד הכפתור הכי בולט בסרגל.
  Widget _buildHomeSlot(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _haloController,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_haloController.value);
                return Transform.scale(
                  scale: 1 + t * 0.12,
                  child: Opacity(
                    opacity: 0.45 + t * 0.45,
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [const Color(0xFFFFBE50).withValues(alpha: 0.30), const Color(0xFFFFBE50).withValues(alpha: 0.0)]),
                      ),
                    ),
                  ),
                );
              },
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _goHome(context),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _ringController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _ringController.value * 2 * pi,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(colors: [
                                    const Color(0x00FFD86B),
                                    const Color(0xFFFFD86B),
                                    const Color(0xFFFF8A3C),
                                    const Color(0x00FFD86B),
                                  ], stops: const [0.0, 0.34, 0.54, 0.84]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.85), const Color(0xFFFF9A3C).withValues(alpha: 0.4)]),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 28, offset: const Offset(0, 12)),
                            BoxShadow(color: const Color(0xFFFFAA3C).withValues(alpha: 0.35), blurRadius: 34),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          // 🆕 עיצוב מחדש - הכפתור נראה עכשיו בדיוק כמו במוקאפ
                          // ("▶ שחק" - לא "🏠 בית") - אבל ההתנהגות מתחתיו
                          // (popUntil(isFirst), ראה _goHome) לא השתנתה בכוונה:
                          // זה עדיין "תמיד חוזר למסך הראשי", התיקון לבאג ניווט
                          // ישן שהיה כאן נשאר בתוקף, רק התווית/אייקון הוחלפו.
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Color(0xFF2A1740), size: 26),
                              Text("שחק", style: TextStyle(color: const Color(0xFF2A1740), fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// כרטיסיית ניווט בודדת בסרגל התחתון.
// 🩹 תוקן: האייקונים היו אימוג'י (🛒🏆🎯👥) - בדיוק אותה בעיה תיעודית
// שכבר הייתה עם אימוג'י המטבע/אנרגיה (ראו app_icons.dart): אימוג'י לא
// אמין בין מכשירים, ואצלך בעבר פשוט לא הוצג בכלל. הוחלף לאייקון
// Material וקטורי עם צבע מלא קבוע משלו (לא לבן/שקוף כמו קודם) - כדי
// שהסרגל ייראה צבעוני בדיוק כמו במוקאפ, בלי תלות בפונט אימוג'י.
class _TabItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int? badgeCount;
  const _TabItem({required this.icon, required this.color, required this.label, required this.onTap, this.active = false, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final Color labelColor = active ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.65);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? color.withValues(alpha: 0.22) : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: active ? color : color.withValues(alpha: 0.75), size: 24),
                  ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF16A46F)]),
                          border: Border.all(color: const Color(0xFF1E1448), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text("$badgeCount", style: const TextStyle(color: Color(0xFF08281C), fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: active ? FontWeight.w900 : FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}