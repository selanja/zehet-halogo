// app_bottom_nav.dart
//
// סרגל ניווט תחתון משותף - מופיע בכל מסכי ה"טאב" הראשיים (חנות/מובילים/
// משימות/הגדרות), לא רק במסך הבית.
//
// 🆕 עודכן לפי בקשה מפורשת: "בכל המסכים תשנה את המניו למטה למניו החדש
// כי במסכים הישנים לא מופיע המניו החדש אלה הישן" - הסרגל הזה היה בעיצוב
// ישן (פס מלא עד הקצוות, כפתור מרכזי גדול עם טבעת מסתובבת+הילה, וטאב
// "חברים"). עכשיו הוא זהה בעיצובו לסרגל התחתון של מסך הבית עצמו
// (_buildHomeBottomNavV7 ב-main_menu_screen.dart): פס צמוד לקצה התחתון
// האמיתי של המסך (לא כרית צפה עם שוליים - ראו תיקון מתועד למטה), כפתור
// מרכזי סטטי (לא מסתובב), וסט הטאבים: חנות · מובילים · [בית] · משימות ·
// הגדרות. טאב "חברים" הוסר מכאן - "חברים" נגיש עכשיו מכרטיס התלתן במסך
// הבית (ראה main_menu_screen.dart), לא כטאב קבוע.
// 🩹 הכפתור המרכזי מוצג כ"🏠 בית" (לא "▶ שחק" כמו במסך הבית עצמו) - לפי
// בקשה מפורשת, כי ההתנהגות שלו כאן היא תמיד "חזרה הביתה" בלבד (ראו
// _buildHomeSlot למטה), לא פתיחת מוד כמו הכפתור האמיתי במסך הבית.
//
// עיצוב ניווט "חכם" (לא השתנה): מהמסך הראשי (current == home) לוחצים על
// טאב אחר עושים Navigator.push רגיל (המסך הראשי נשאר למטה במחסנית). מתוך
// מסך טאב אחר (חנות/מובילים/משימות/הגדרות) עוברים לטאב אחר עם
// pushReplacement (כדי לא לערום עשרות מסכים זה על זה כשעוברים בין
// טאבים) - כך שהמסך הראשי תמיד נשאר "קרקעית" יציבה של המחסנית, וכפתור
// "בית" המרכזי תמיד יכול לחזור אליו עם popUntil(isFirst).
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'missions_service.dart';
import 'settings_screen.dart';
import 'iap_manager.dart';
import 'l10n/app_localizations.dart';

// 🩹 none - לפי בקשה מפורשת ("הכפתור של הבית לא עובד"): גיליון "בחרו מוד"
// (main_menu_screen.dart, _buildModesSheetV7) מציג את הסרגל הזה עם
// current: AppTab.home כי הוא "הרחבה" של מסך הבית - אבל זה גרם לכפתור
// "בית" להיות no-op, כי _goHome בודק "אם current כבר home, אל תעשה כלום"
// (נכון למסכי הטאבים האמיתיים, אבל לא נכון כאן - הגיליון הזה נדחף
// (push) מעל מסך הבית, לא מחליף אותו, אז "חזרה הביתה" עדיין צריכה
// לסגור אותו). none מייצג מסך שהוא לא אף אחד מ-5 הטאבים עצמם (אז הכפתור
// שלו תמיד פעיל), בלי לשנות התנהגות קיימת בשום מסך טאב אמיתי.
enum AppTab { home, shop, leaderboard, missions, settings, none }

class AppBottomNav extends StatefulWidget {
  final AppTab current;
  const AppBottomNav({super.key, required this.current});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _missionsUnclaimed = 0;
  // 🆕 "שיופיע להם בצד ימין לוגו צהוב של החנות עם סימן של הנחה ככה הם
  // ידעו שעדיין יש להם את ההנחה" - אותו תג כמו בסרגל התחתון של מסך
  // הבית (_navTabV7 ב-main_menu_screen.dart), כדי שיהיה עקבי גם במסכי
  // הטאבים האחרים (חנות/מובילים/משימות/הגדרות) לא רק בבית.
  bool _shopDiscountActive = false;

  @override
  void initState() {
    super.initState();
    _loadBadge();
    _loadShopDiscountBadge();
  }

  Future<void> _loadBadge() async {
    final count = await MissionsService.unclaimedCount();
    if (mounted) setState(() => _missionsUnclaimed = count);
  }

  Future<void> _loadShopDiscountBadge() async {
    final active = await IapManager.tournamentBonusActive();
    if (mounted) setState(() => _shopDiscountActive = active);
  }

  // ניווט "חכם" בין טאבים - ראו הסבר בראש הקובץ.
  // מיקום כל טאב בסרגל, משמאל לימין (ראו הסדר ב-build למטה):
  // הגדרות, משימות, שחק, מובילים, חנות.
  static int _tabPosition(AppTab t) => switch (t) {
        AppTab.settings => 0,
        AppTab.missions => 1,
        AppTab.home => 2,
        AppTab.none => 2,
        AppTab.leaderboard => 3,
        AppTab.shop => 4,
      };

  // "כשעוברים לעמוד בצד ימין למטה הסלייד ימינה, ובצד שמאל - שמאלה":
  // המסך החדש נכנס מהצד שבו נמצא הטאב בסרגל התחתון (טאב מימין - נכנס
  // מימין, טאב משמאל - נכנס משמאל), יחסית לטאב שבו נמצאים עכשיו. חזרה
  // לבית (popUntil) מריצה את אותה אנימציה הפוך, אז זה עקבי אוטומטית.
  Route<void> _tabRoute(AppTab target, WidgetBuilder builder) {
    final fromRight = _tabPosition(target) > _tabPosition(widget.current);
    final begin = Offset(fromRight ? 1.0 : -1.0, 0);
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return SlideTransition(position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved), child: child);
      },
    );
  }

  void _go(BuildContext context, AppTab target, WidgetBuilder builder) {
    if (target == widget.current) return;
    if (widget.current == AppTab.home || widget.current == AppTab.none) {
      Navigator.push(context, _tabRoute(target, builder));
    } else {
      Navigator.pushReplacement(context, _tabRoute(target, builder));
    }
  }

  Future<void> _goSettings(BuildContext context) async {
    if (widget.current == AppTab.settings) return;
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    if (!context.mounted) return;
    _go(context, AppTab.settings, (_) => SettingsScreen(username: username));
  }

  void _goHome(BuildContext context) {
    if (widget.current == AppTab.home) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // 🩹 תוקן לפי בקשה מפורשת ("המניו למטה הוא לא הכי למטה ומופיעים מאחוריו
  // דברים") - הסרגל היה "כרית" צפה עם שוליים מכל 4 הצדדים, שמשאירה פער
  // שקוף בינה לבין קצה המסך האמיתי - בדיוק שם תוכן גלול יכול "להציץ"
  // מתחתיו. תואם עכשיו את המוקאפ המקורי (Home v10.html, "bottom tab bar")
  // ואת אותו תיקון שבוצע ב-_buildHomeBottomNavV7 (main_menu_screen.dart):
  // צמוד לקצה התחתון האמיתי (left:0/right:0/bottom:0), בלי שום פער.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.fromLTRB(8, 12, 8, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF1E1448).withValues(alpha: 0.95), const Color(0xFF120C2E).withValues(alpha: 0.99)],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 36, offset: const Offset(0, -14))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // סדר תואם למוקאפ (מסך 01 · בית): משמאל לימין - הגדרות,
                // משימות, [שחק], מובילים, חנות. ב-Row עם textDirection.rtl
                // ה"ילד" הראשון ברשימה מוצג הכי מימין, אז חנות מגיע ראשון.
                Expanded(
                  child: _TabItem(
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF6EE7B7),
                    label: loc.appBottomNavShop,
                    active: widget.current == AppTab.shop,
                    discountBadge: _shopDiscountActive,
                    onTap: () => _go(context, AppTab.shop, (_) => const ShopScreen()),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFFFDA4AF),
                    label: loc.appBottomNavLeaderboard,
                    active: widget.current == AppTab.leaderboard,
                    onTap: () => _go(context, AppTab.leaderboard, (_) => const LeaderboardScreen()),
                  ),
                ),
                SizedBox(width: 88, child: _buildHomeSlot(context)),
                Expanded(
                  child: _TabItem(
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFF34D399),
                    label: loc.appBottomNavMissions,
                    active: widget.current == AppTab.missions,
                    onTap: () => _go(context, AppTab.missions, (_) => const MissionsScreen()),
                    badgeCount: _missionsUnclaimed > 0 ? _missionsUnclaimed : null,
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.settings_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    label: loc.settingsScreenTitle,
                    active: widget.current == AppTab.settings,
                    onTap: () => _goSettings(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // כפתור מרכזי - חוזר תמיד למסך הראשי (popUntil(isFirst)). 🩹 תוקן לפי
  // בקשה מפורשת ("במקום הכפתור של השחק כפתור של בית") - בעבר הוצג כאן
  // "▶ שחק" (אותו עיצוב כמו כפתור השחק האמיתי במסך הבית, _navPlayButtonV7)
  // למרות שההתנהגות שלו תמיד הייתה "חזרה הביתה" בלבד, לא "פתיחת מוד" -
  // מטעה במסכים אחרים שבהם אין שום דבר "לשחק" בלחיצה. עכשיו האייקון/
  // התווית תואמים את ההתנהגות האמיתית (🏠 בית), בלי לשנות שום דבר
  // בניווט עצמו.
  Widget _buildHomeSlot(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _goHome(context),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: const Color(0xFFFFAA3C).withValues(alpha: 0.4), blurRadius: 26),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded, color: Color(0xFF2A1740), size: 24),
                Text(AppLocalizations.of(context)!.appBottomNavHome, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// כרטיסיית ניווט בודדת בסרגל התחתון - אייקון Material וקטורי עם צבע
// מלא קבוע משלו (תואם את _navTabV7 במסך הבית), + הדגשה בזהב כשהטאב הזה
// הוא הטאב הנוכחי.
class _TabItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int? badgeCount;
  final bool discountBadge;
  const _TabItem({required this.icon, required this.color, required this.label, required this.onTap, this.active = false, this.badgeCount, this.discountBadge = false});

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
                    child: Icon(icon, color: active ? color : color.withValues(alpha: 0.75), size: 23),
                  ),
                  if (discountBadge)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD86B)),
                        child: const Icon(Icons.percent_rounded, color: Color(0xFF2A1740), size: 10),
                      ),
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
              Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: active ? FontWeight.w900 : FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
