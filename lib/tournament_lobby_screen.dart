// tournament_lobby_screen.dart
//
// מסך האתגר הרב-יומי: דמי כניסה (פעם אחת לכל האירוע), פרסים (🥇🥈🥉),
// טבלת דירוג חיה *מצטברת* לאירוע הנוכחי (ראו tournament_service.dart),
// והסטטוס של השחקן (עוד לא נרשם / נרשם ועוד לא שיחק את היום הנוכחי /
// כבר שיחק את היום הנוכחי - חוזרים מחר ליום הבא / האירוע הסתיים - ראו
// _StickyCta). בפתיחת המסך גם בודקים אם מחכה פרס מאירוע קודם שהסתיים
// (TournamentService.checkAndClaimPendingPrize) ומציגים חלונית "זכית!".
//
// 🆕 עיצוב מחדש מלא (לפי מוקאפ מדויק ששלח המשתמש - "תעשה כמו זה"):
//  - באנר גיבור גדול (גרדיאנט כתום/ורוד) עם גביע צף, תג "משתתפים" חי,
//    הקופה הנוכחית בגדול, וספירה-לאחור בתצוגת שעון דיגיטלי (תיבות HH:MM:SS).
//  - שורת פרסים "פודיום" אמיתית (2-1-3) עם הסכומים המחושבים בפועל +
//    תג "+25% בחנות ל-24 שעות" על מקום 1 (ראו IapManager.activateTournamentBonus).
//  - כרטיס "איך זה עובד" - 3 שורות הסבר קצרות.
//  - תצוגה מקדימה של 3 המובילים בלבד (לא הפודיום המלא) + קישור "כל
//    הטבלה" שפותח גיליון תחתון עם הפודיום המלא + שאר הדירוג (ראו
//    _FullLeaderboardSheet - משתמש מחדש ב-_Podium/_LeaderboardRow הישנים).
//  - כפתור הפעולה (CTA) עבר להיות "דביק" בתחתית המסך (מחוץ לגלילה),
//    לא עוד כרטיס בתוך הרשימה - עם 3 מצבים (לא נרשם/נרשם/כבר שיחק היום).
// שום שינוי בלוגיקה/קריאות Firestore/TournamentService - רק שכבת התצוגה.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tournament_service.dart';
import 'tournament_play_screen.dart';
import 'tournament_result_popup.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'app_icons.dart';
import 'not_enough_coins_dialog.dart';
import 'device_id.dart';

class TournamentLobbyScreen extends StatefulWidget {
  const TournamentLobbyScreen({super.key});

  @override
  State<TournamentLobbyScreen> createState() => _TournamentLobbyScreenState();
}

class _TournamentLobbyScreenState extends State<TournamentLobbyScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _joined = false;
  bool _played = false;
  int _coins = 0;
  List<TournamentEntry> _leaderboard = [];
  String? _myDeviceId;

  // 🆕 כניסה מדורגת של הבלוקים במסך (header/כרטיסים/פודיום/רשימה) - ראו
  // _FadeSlideIn למטה. מתחילה (forward) רק כש-_load מסתיים, כדי שהאנימציה
  // תוצג מול תוכן אמיתי ולא מול ספינר.
  late final AnimationController _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  // 🆕 פעימה איטית ואינסופית (glow על ה-CTA/הגביע, bob עדין על הגביע
  // בבאנר) - נפרדת מ-_entrance כדי שתמשיך לרוץ גם אחרי שהכניסה הסתיימה.
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // 🐛 תוקן: מסך הטורניר מעולם לא נספר כ"גלישה" לקראת פרסומת - כמו
    // כל מסך גלישה אחר (ראו duel_lobby_screen.dart/shop_screen.dart).
    AdsManager.recordBrowseNavigation();
    // 🆕 טיימר הספירה-לאחור להיום (ראו _timeUntilReset) - מרענן כל שנייה
    // בלבד (setState ריק, רק כדי שה-getter יחושב מחדש בבנייה הבאה).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  // 🕐 זמן שנותר עד סוף *האירוע* כולו (לא עוד חצות של הלילה - עכשיו
  // האירוע נמשך tournamentEventDays ימים, ראו TournamentService.eventEndTime).
  Duration get _timeUntilReset {
    final diff = TournamentService.eventEndTime().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // 🆕 מפורק לשלושה מחרוזות נפרדות (לא "HH:MM:SS" אחד) בשביל תצוגת
  // שעון הדיגיטלי (3 תיבות נפרדות עם ":" ביניהן) במוקאפ.
  (String, String, String) get _countdownParts {
    final d = _timeUntilReset;
    String two(int n) => n.toString().padLeft(2, '0');
    return (two(d.inHours), two(d.inMinutes % 60), two(d.inSeconds % 60));
  }

  // �2 "משתתפים" אופטימי - כולל את עצמנו מיד אחרי הרשמה, גם לפני ש-
  // submitResult כתב בפועל ל-Firestore (זה קורה רק בסוף המשחק) - בדיוק
  // אותו רעיון כמו במוקאפ (players + (joined ? 1 : 0)), כדי שהבאנר/ה-CTA
  // יתנו משוב מיידי בלי להמתין לרשת.
  int get _playersOptimistic => _leaderboard.length + (_joined ? 1 : 0);
  int get _poolOptimistic => currentPoolEstimate(_playersOptimistic);

  Future<void> _load() async {
    final prize = await TournamentService.checkAndClaimPendingPrize();
    final prefs = await SharedPreferences.getInstance();
    final joined = await TournamentService.hasJoinedEvent();
    final played = await TournamentService.hasPlayedToday();
    final board = await TournamentService.fetchLeaderboard(TournamentService.eventId());
    final deviceId = await DeviceId.get();
    if (!mounted) return;
    setState(() {
      _coins = prefs.getInt('coins') ?? 15;
      _joined = joined;
      _played = played;
      _leaderboard = board;
      _myDeviceId = deviceId;
      _loading = false;
    });
    _entrance.forward(from: 0);
    if (prize != null && mounted) {
      // 🩹 הדיאלוג הפשוט הקודם הוחלף בפופאפ המשותף (ראו
      // tournament_result_popup.dart) כדי שהעיצוב יהיה זהה בין נקודת
      // הכניסה הזו (מסך הלובי) לבין הקפצה האוטומטית בכניסה הכללית
      // לאפליקציה (main_menu_screen.dart:_maybeShowTournamentResult).
      showTournamentResultPopup(context, prize);
    }
  }

  Future<void> _onJoinTap() async {
    AudioManager.playClick();
    if (_coins < tournamentEntryFee) {
      showNotEnoughCoinsDialog(context, cost: tournamentEntryFee, coins: _coins, onReturnedFromShop: _load);
      return;
    }
    final missing = await TournamentService.join();
    if (!mounted) return;
    if (missing != null) {
      showNotEnoughCoinsDialog(context, cost: tournamentEntryFee, coins: _coins, onReturnedFromShop: _load);
      return;
    }
    setState(() {
      _joined = true;
      _coins -= tournamentEntryFee;
    });
  }

  Future<void> _onStartTap() async {
    AudioManager.playClick();
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const TournamentPlayScreen()));
    _load();
  }

  void _openFullLeaderboard() {
    AudioManager.playClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _FullLeaderboardSheet(leaderboard: _leaderboard, myDeviceId: _myDeviceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF120B2C),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.38, 0.72, 1.0],
                    colors: [Color(0xFF4A2394), Color(0xFF2E1668), Color(0xFF1B0F42), Color(0xFF120B2C)],
                  ),
                ),
              ),
            ),
            // 🆕 זוהר עדין בפינה השמאלית-עליונה, בדיוק כמו במוקאפ.
            Positioned(
              top: -100,
              left: -80,
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFFFB24D).withValues(alpha: 0.28), const Color(0xFFFFB24D).withValues(alpha: 0)]),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: const _DotGridPainter()))),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B)))
            else
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                color: Colors.white.withValues(alpha: 0.09),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('אתגר 3 הימים', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFFFD86B).withValues(alpha: 0.13),
                              border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [const CoinIcon(size: 15), const SizedBox(width: 5), Text('$_coins', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w900))],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                        children: [
                          _FadeSlideIn(
                            controller: _entrance,
                            delay: 0.0,
                            span: 0.55,
                            child: _HeroBanner(players: _playersOptimistic, pot: _poolOptimistic, countdownParts: _countdownParts, pulse: _pulse),
                          ),
                          const SizedBox(height: 18),
                          _FadeSlideIn(
                            controller: _entrance,
                            delay: 0.1,
                            span: 0.55,
                            child: _PrizesRow(pool: _poolOptimistic),
                          ),
                          const SizedBox(height: 18),
                          _FadeSlideIn(
                            controller: _entrance,
                            delay: 0.18,
                            span: 0.55,
                            child: const _HowItWorksCard(),
                          ),
                          const SizedBox(height: 22),
                          _FadeSlideIn(
                            controller: _entrance,
                            delay: 0.26,
                            span: 0.5,
                            child: _LeaderboardPreview(leaderboard: _leaderboard, myDeviceId: _myDeviceId, onOpenFull: _openFullLeaderboard),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (!_loading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyCta(
                  joined: _joined,
                  played: _played,
                  pool: _poolOptimistic,
                  onJoin: _onJoinTap,
                  onStart: _onStartTap,
                  pulse: _pulse,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 🆕 עטיפת-אנימציה כללית: fade+slide-up מדורג לפי delay (0..~0.6) יחסית
// לאורך כולל של controller (0..1) - בדיוק אותה נוסחה (clamp + easeOut)
// שכבר קיימת ב-battle_pass_reward_popup.dart/tournament_result_popup.dart,
// רק מופשטת כאן לעטיפה חזרה-לשימוש כדי לא לשכפל אותה בכל בלוק במסך הזה.
class _FadeSlideIn extends StatelessWidget {
  final Animation<double> controller;
  final double delay;
  final double span;
  final Widget child;
  const _FadeSlideIn({required this.controller, required this.child, this.delay = 0, this.span = 0.6});

  @override
  Widget build(BuildContext context) {
    const offsetY = 16.0;
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (ctx, child) {
        final local = ((controller.value - delay) / span).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(local);
        return Opacity(
          opacity: eased,
          child: Transform.translate(offset: Offset(0, (1 - eased) * offsetY), child: child),
        );
      },
    );
  }
}

// 🆕 רשת נקודות דקה ברקע כל המסך (אפקט "טקסטורה"), בדיוק כמו במוקאפ -
// מצוירת פעם אחת (shouldRepaint תמיד false, אין אנימציה שמניעה אותה),
// אז אין עלות ביצועים מתמשכת.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.055);
    const spacing = 24.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}

// 🆕 "באנר גיבור" חדש לגמרי לפי המוקאפ: גרדיאנט כתום→ורוד, גביע צף עם
// bob עדין, תג "משתתפים" חי עם נקודה פועמת, הקופה הנוכחית בגדול, וספירה-
// לאחור בתצוגת שעון דיגיטלי (3 תיבות HH/MM/SS).
class _HeroBanner extends StatelessWidget {
  final int players;
  final int pot;
  final (String, String, String) countdownParts;
  final Animation<double> pulse;
  const _HeroBanner({required this.players, required this.pot, required this.countdownParts, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final (hh, mm, ss) = countdownParts;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFFBE185D)]),
        boxShadow: [BoxShadow(color: const Color(0xFFEA580C).withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -4,
            left: -2,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (ctx, child) => Transform.translate(offset: Offset(0, -4 + 8 * pulse.value), child: child),
              child: const Text('🏆', style: TextStyle(fontSize: 56)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.25)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: pulse,
                          builder: (ctx, _) => Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6EE7B7).withValues(alpha: 0.5 + 0.5 * pulse.value)),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text('$players משתתפים', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🆕 "ככה שיהיה יותר עניין שכל יום הם יצטרכו להיכנס" -
                  // תג "יום X מתוך 3" תמיד גלוי בבאנר, כדי שהשחקן תמיד
                  // יידע איפה הוא נמצא באירוע.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.25)),
                    child: Text('יום ${TournamentService.dayInEvent()}/$tournamentEventDays', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('הקופה כרגע', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w800)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$pot',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1, shadows: [Shadow(color: Color(0x59781400), offset: Offset(0, 4))]),
                  ),
                  const SizedBox(width: 8),
                  const CoinIcon(size: 22),
                ],
              ),
              const SizedBox(height: 2),
              Text('$tournamentPotSeed בקופה מההתחלה + $players × $tournamentEntryFee שמצטרפים', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.22)),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    Expanded(child: Text('האתגר מסתיים בעוד', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _clockBox(hh),
                          _clockColon(),
                          _clockBox(mm),
                          _clockColon(),
                          _clockBox(ss),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clockBox(String v) => Container(
        constraints: const BoxConstraints(minWidth: 32),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: Colors.white.withValues(alpha: 0.92)),
        alignment: Alignment.center,
        child: Text(v, style: const TextStyle(color: Color(0xFF9A3412), fontSize: 16, fontWeight: FontWeight.w900)),
      );

  Widget _clockColon() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Text(':', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
      );
}

// 🆕 שורת פרסים "פודיום" לפי המוקאפ - מקום 2 (ימין) / מקום 1 (אמצע,
// מוגבה עם תג בונוס) / מקום 3 (שמאל) - בדיוק אותו סדר-ילדים [2,1,3]
// שכבר שימש את ה-_Podium הישן, שתחת ה-RTL של האפליקציה נותן בפועל
// את הקריאה הנכונה מימין לשמאל: 2 → 1 → 3.
class _PrizesRow extends StatelessWidget {
  final int pool;
  const _PrizesRow({required this.pool});

  @override
  Widget build(BuildContext context) {
    final p1 = (pool * tournamentFirstShare).round();
    final p2 = (pool * tournamentSecondShare).round();
    final p3 = (pool * tournamentThirdShare).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('הפרסים', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            const Spacer(),
            Text('אחוז מהקופה', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 100, child: _tile(rank: 2, amount: p2, percent: 20)),
            const SizedBox(width: 8),
            Expanded(flex: 115, child: _tile(rank: 1, amount: p1, percent: 40, elevated: true)),
            const SizedBox(width: 8),
            Expanded(flex: 100, child: _tile(rank: 3, amount: p3, percent: 10)),
          ],
        ),
      ],
    );
  }

  Widget _tile({required int rank, required int amount, required int percent, bool elevated = false}) {
    final Color top = rank == 1 ? const Color(0xFFFFE9A8) : (rank == 2 ? const Color(0xFFEDEDED) : const Color(0xFFE6B37E));
    return Container(
      padding: EdgeInsets.fromLTRB(6, elevated ? 18 : 14, 6, elevated ? 14 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(elevated ? 22 : 20),
        gradient: elevated
            ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFD86B).withValues(alpha: 0.26), const Color(0xFFFF9F45).withValues(alpha: 0.10)])
            : null,
        color: elevated ? null : top.withValues(alpha: 0.12),
        border: Border.all(color: elevated ? const Color(0xFFFFD86B).withValues(alpha: 0.7) : top.withValues(alpha: 0.4), width: elevated ? 2 : 1.5),
        boxShadow: elevated ? [BoxShadow(color: const Color(0xFFFFB24D).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MedalIcon(rank: rank, size: elevated ? 30 : 24),
          const SizedBox(height: 4),
          Text('$amount', style: TextStyle(color: elevated ? const Color(0xFFFFD86B) : Colors.white, fontSize: elevated ? 24 : 18, fontWeight: FontWeight.w900)),
          Text('$percent%', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w800)),
          if (elevated) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black.withValues(alpha: 0.25)),
              child: const Text('+25% בחנות ל-24 שעות', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFE7A8), fontSize: 10, fontWeight: FontWeight.w800, height: 1.3)),
            ),
          ],
        ],
      ),
    );
  }
}

// 🆕 "איך זה עובד" - כרטיס הסבר סטטי קצר, בדיוק לפי המוקאפ (3 שורות).
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          _row(
            gradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
            icon: Icons.extension_rounded,
            text: '$tournamentDailyLogoCount לוגואים כל יום, למשך $tournamentEventDays ימים - אותם לוגואים לכל המשתתפים בכל יום',
          ),
          const SizedBox(height: 13),
          _row(gradient: const [Color(0xFF8EDCFF), Color(0xFF0E8FD8)], icon: Icons.bar_chart_rounded, text: 'הדירוג מצטבר על פני כל הימים לפי נכונות וזמן - ככל שפותרים מהר יותר, הניקוד גבוה יותר'),
          const SizedBox(height: 13),
          _row(gradient: const [Color(0xFF6EE7B7), Color(0xFF10B981)], icon: Icons.replay_rounded, text: 'פחות מ-$tournamentMinPlayers נרשמו? כולם מקבלים החזר מלא'),
        ],
      ),
    );
  }

  Widget _row({required List<Color> gradient, required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, fontWeight: FontWeight.w700))),
      ],
    );
  }
}

// 🆕 תצוגה מקדימה קומפקטית של 3 המובילים (לא הפודיום המלא) + קישור
// "כל הטבלה" שפותח את _FullLeaderboardSheet. מטפל גם במצב "אין עדיין
// משתתפים" (בדיוק כמו הקוד הישן).
class _LeaderboardPreview extends StatelessWidget {
  final List<TournamentEntry> leaderboard;
  final String? myDeviceId;
  final VoidCallback onOpenFull;
  const _LeaderboardPreview({required this.leaderboard, required this.myDeviceId, required this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    final top3 = leaderboard.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('המובילים עכשיו', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            const Spacer(),
            if (leaderboard.isNotEmpty)
              GestureDetector(
                onTap: onOpenFull,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('כל הטבלה', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 12.5, fontWeight: FontWeight.w800)),
                    const Icon(Icons.chevron_left_rounded, color: Color(0xFFFFD86B), size: 18),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (top3.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06)),
            alignment: Alignment.center,
            child: Text('עדיין אין משתתפים באתגר הזה - תהיו הראשונים!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          )
        else
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06)),
            child: Column(
              children: List.generate(top3.length, (i) {
                final entry = top3[i];
                final isMe = myDeviceId != null && entry.deviceId == myDeviceId;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: i < top3.length - 1 ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))) : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 26, child: Center(child: _MedalIcon(rank: i + 1, size: 18))),
                      const SizedBox(width: 12),
                      _initialCircle(rank: i + 1, name: entry.name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isMe ? FontWeight.w900 : FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.person_rounded, color: Color(0xFF34D399), size: 14)),
                      // 🆕 "גם לפי זמן, שמי שעושה בזמן הכי מהר הניקוד שלו
                      // יותר גבוה" - הניקוד המשולב (TournamentEntry.score,
                      // לפיו גם מדרגים בפועל) מוצג עכשיו ראשון ובולט, עם
                      // הנכונות/הזמן הגולמיים כפירוט קטן מתחתיו.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.score} נק׳',
                            style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${entry.correctCount}/${tournamentDailyLogoCount * tournamentEventDays} · ${(entry.totalTimeMs / 1000).toStringAsFixed(1)}s',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _initialCircle({required int rank, required String name}) {
    final gradTop = rank == 1 ? const Color(0xFFFFE9A8) : (rank == 2 ? const Color(0xFFEDEDED) : const Color(0xFFE6B37E));
    final gradBottom = rank == 1 ? const Color(0xFFFF9F45) : (rank == 2 ? const Color(0xFF9CA3AF) : const Color(0xFFCD7F32));
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [gradTop, gradBottom])),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 14, fontWeight: FontWeight.w900)),
    );
  }
}

// 🆕 כפתור הפעולה - עכשיו "דביק" בתחתית המסך (Positioned, מחוץ לגלילה),
// עם דעיכה (gradient שקוף→רקע) מעליו בדיוק כמו במוקאפ, ו-3 מצבים.
class _StickyCta extends StatelessWidget {
  final bool joined;
  final bool played;
  final int pool;
  final VoidCallback onJoin;
  final VoidCallback onStart;
  final Animation<double> pulse;
  const _StickyCta({required this.joined, required this.played, required this.pool, required this.onJoin, required this.onStart, required this.pulse});

  @override
  Widget build(BuildContext context) {
    // 🆕 4 מצבים במקום 3 - "שיחק היום" כבר לא אומר "סיים הכול": יש עוד
    // ימים באירוע (ראו TournamentService.dayInEvent/tournamentEventDays),
    // אז מבדילים בין "חזרו מחר ליום הבא" לבין "זה היה היום האחרון".
    final day = TournamentService.dayInEvent();
    final isLastDay = day >= tournamentEventDays;
    Widget content;
    if (!joined) {
      content = _joinButton(onJoin, pulse);
    } else if (!played) {
      content = _startButton(onStart, day);
    } else if (isLastDay) {
      content = _waitingState(
        icon: Icons.flag_rounded,
        text: 'זה היה היום האחרון! התוצאות הסופיות והפרסים יחולקו בפעם הבאה שתפתחו את מסך האתגר',
      );
    } else {
      content = _waitingState(
        icon: Icons.check_circle_rounded,
        text: 'השלמתם את יום $day! חזרו מחר ליום ${day + 1} מתוך $tournamentEventDays',
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00120B2C), Color(0xFF120B2C)], stops: [0.0, 0.45]),
      ),
      child: SafeArea(top: false, child: content),
    );
  }

  Widget _waitingState({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF34D399), size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _joinButton(VoidCallback onTap, Animation<double> pulse) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (ctx, _) {
        final glow = pulse.value;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)]),
              boxShadow: [
                const BoxShadow(color: Color(0xFFB4531A), offset: Offset(0, 6)),
                BoxShadow(color: const Color(0xFFFF8A3C).withValues(alpha: 0.25 + 0.2 * glow), blurRadius: 20 + 10 * glow, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('הרשמה לטורניר', style: TextStyle(color: Color(0xFF2A1740), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFF2A1740).withValues(alpha: 0.16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [const CoinIcon(size: 14), const SizedBox(width: 4), const Text('$tournamentEntryFee', style: TextStyle(color: Color(0xFF2A1740), fontSize: 14, fontWeight: FontWeight.w900))],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _startButton(VoidCallback onTap, int day) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFA7F3D0), size: 16),
            const SizedBox(width: 6),
            Text('נרשמתם לאתגר! הקופה כרגע $pool', style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6EE7B7), Color(0xFF10B981)]),
              boxShadow: const [BoxShadow(color: Color(0xFF0A6E47), offset: Offset(0, 6))],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Color(0xFF052E1C), size: 20),
                const SizedBox(width: 6),
                Text('שחקו יום $day', style: const TextStyle(color: Color(0xFF052E1C), fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 🆕 גיליון תחתון עם הפודיום המלא (1-2-3) + שאר הדירוג - נפתח מ"כל
// הטבלה" בתצוגה המקדימה. משתמש מחדש ב-_Podium/_LeaderboardRow (היו
// בעבר חלק קבוע מהמסך הראשי - עכשיו "עברו דירה" לכאן).
class _FullLeaderboardSheet extends StatelessWidget {
  final List<TournamentEntry> leaderboard;
  final String? myDeviceId;
  const _FullLeaderboardSheet({required this.leaderboard, required this.myDeviceId});

  @override
  Widget build(BuildContext context) {
    final restCount = (leaderboard.length > 10 ? 10 : leaderboard.length) - 3;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1B0F42),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Row(
                    children: [
                      const Text('טבלת הדירוג של האתגר', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.08)),
                        child: Text('${leaderboard.length} משתתפים', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                    children: [
                      _Podium(
                        top3: List<TournamentEntry?>.generate(3, (i) => i < leaderboard.length ? leaderboard[i] : null),
                        myDeviceId: myDeviceId,
                      ),
                      if (restCount > 0) const SizedBox(height: 18),
                      ...List.generate(restCount > 0 ? restCount : 0, (i) {
                        final rank = i + 4;
                        final entry = leaderboard[i + 3];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LeaderboardRow(rank: rank, entry: entry, isMe: entry.deviceId == myDeviceId && myDeviceId != null),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 🆕 פודיום אמיתי למקומות 1-3 (עמודה 2 - עמודה 1 (הגבוהה) - עמודה 3,
// בדיוק כמו פודיום קלאסי). מטפל במפורש במקרה של 0/1/2 משתתפים (top3 יכול
// להכיל null במקום TournamentEntry - ראו _PodiumColumn.hasEntry) כדי לא
// לקרוס ולא להציג פודיום שבור.
class _Podium extends StatelessWidget {
  final List<TournamentEntry?> top3; // [מקום1, מקום2, מקום3] - כל איבר יכול להיות null.
  final String? myDeviceId;
  const _Podium({required this.top3, required this.myDeviceId});

  bool _isMe(TournamentEntry? e) => e != null && myDeviceId != null && e.deviceId == myDeviceId;

  @override
  Widget build(BuildContext context) {
    // ⚠️ בכוונה בלי SizedBox עם גובה קבוע סביב ה-Row: Row מתכווץ אוטומטית
    // לגובה העמודה הגבוהה ביותר, ו-crossAxisAlignment.end מצמיד את *תחתית*
    // כל העמודות לאותו קו בדיוק - בלי צורך לנחש/לחשב גובה כולל מראש.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumColumn(rank: 2, entry: top3[1], isMe: _isMe(top3[1]), pedestalHeight: 86)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumColumn(rank: 1, entry: top3[0], isMe: _isMe(top3[0]), pedestalHeight: 118)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumColumn(rank: 3, entry: top3[2], isMe: _isMe(top3[2]), pedestalHeight: 66)),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final TournamentEntry? entry;
  final bool isMe;
  final double pedestalHeight;
  const _PodiumColumn({required this.rank, required this.entry, required this.isMe, required this.pedestalHeight});

  bool get hasEntry => entry != null;

  Color get _gradTop {
    switch (rank) {
      case 1:
        return const Color(0xFFFFE9A8);
      case 2:
        return const Color(0xFFEDEDED);
      default:
        return const Color(0xFFE6B37E);
    }
  }

  Color get _gradBottom {
    switch (rank) {
      case 1:
        return const Color(0xFFFF9F45);
      case 2:
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = hasEntry && entry!.name.isNotEmpty ? entry!.name.substring(0, 1).toUpperCase() : '?';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF34D399).withValues(alpha: 0.18),
                border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6)),
              ),
              child: const Text('אתה', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasEntry ? LinearGradient(colors: [_gradTop, _gradBottom]) : null,
            color: hasEntry ? null : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: isMe ? const Color(0xFF34D399) : Colors.white.withValues(alpha: hasEntry ? 0.5 : 0.15),
              width: isMe ? 2.5 : 1.5,
            ),
            boxShadow: hasEntry ? [BoxShadow(color: _gradBottom.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: 1)] : null,
          ),
          alignment: Alignment.center,
          child: hasEntry
              ? Text(initial, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 19, fontWeight: FontWeight.w900))
              : Icon(Icons.person_outline_rounded, color: Colors.white.withValues(alpha: 0.25), size: 24),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            hasEntry ? entry!.name : 'מחכים...',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: hasEntry ? Colors.white : Colors.white.withValues(alpha: 0.35), fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          // 🆕 הפודיום מדורג לפי entry.score (לא רק נכונות) - מציגים
          // אותו כאן, לא את הנכונות הגולמית, כדי שהמספר שרואים יתאים
          // למה שבאמת קובע את המיקום.
          hasEntry ? '${entry!.score} נק׳' : '-',
          style: TextStyle(color: Colors.white.withValues(alpha: hasEntry ? 0.55 : 0.25), fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: pedestalHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            gradient: hasEntry
                ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_gradTop, _gradBottom])
                : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.04)]),
            boxShadow: hasEntry ? [BoxShadow(color: _gradBottom.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))] : null,
          ),
          alignment: Alignment.center,
          child: rank == 1
              ? Icon(Icons.emoji_events_rounded, color: hasEntry ? const Color(0xFF8A4B00) : Colors.white.withValues(alpha: 0.2), size: 30)
              : Text('$rank', style: TextStyle(color: hasEntry ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.25), fontSize: 24, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final TournamentEntry entry;
  final bool isMe;
  const _LeaderboardRow({required this.rank, required this.entry, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: rank <= 3 ? const Color(0xFFFFD86B).withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
        border: isMe ? Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: rank <= 3 ? _MedalIcon(rank: rank, size: 18) : Text('$rank', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: isMe ? FontWeight.w900 : FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMe) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.person_rounded, color: const Color(0xFF34D399), size: 14)),
          Text('${entry.score} נק׳', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text('${entry.correctCount}/${tournamentDailyLogoCount * tournamentEventDays}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Text('${(entry.totalTimeMs / 1000).toStringAsFixed(1)}s', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5)),
        ],
      ),
    );
  }
}

// 🩹 אייקון מדליה וקטורי (Icons.emoji_events_rounded בצבע זהב/כסף/ארד),
// לא אימוג'י (🥇🥈🥉) - אותה בעיית תאימות מתועדת ב-app_icons.dart
// (אימוג'י לא תמיד נטענים אצל המשתמש הזה במכשיר הספציפי שלו).
class _MedalIcon extends StatelessWidget {
  final int rank;
  final double size;
  const _MedalIcon({required this.rank, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    return Icon(Icons.emoji_events_rounded, color: color, size: size);
  }
}
