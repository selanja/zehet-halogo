// scheduled_tournament_screen.dart
//
// מסך "טורניר מתוזמן" - הפורמט השני, בנוסף לטורניר היומי (ראו ההערה
// המלאה ב-scheduled_tournament_service.dart). 3 מצבים לפי
// ScheduledTournamentService.currentPhase:
//  - upcoming: עוד לא התחיל היום - ספירה-לאחור לתחילת החלון.
//  - active: בתוך החלון - אפשר להצטרף+לשחק (פעולה אחת), ספירה-לאחור
//    לסגירה, וטבלת דירוג חיה של מי שכבר שיחק.
//  - closed: החלון של היום נסגר - חוזרים מחר, ספירה-לאחור לחלון הבא.
// שפה עיצובית כחולה-סגולה (לא כתומה כמו הטורניר היומי) כדי שיהיה ברור
// מיד שזה פורמט אחר, אבל אותה "משפחה" ויזואלית (רקע/זוהר/רשת-נקודות
// זהים ל-tournament_lobby_screen.dart).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scheduled_tournament_service.dart';
import 'scheduled_tournament_play_screen.dart';
import 'tournament_result_popup.dart';
import 'audio_manager.dart';
import 'ads_manager.dart';
import 'app_icons.dart';
import 'not_enough_coins_dialog.dart';
import 'device_id.dart';
import 'notification_manager.dart'; // 🆕 "הירשמו מראש" - ראו _togglePreRegister

class ScheduledTournamentScreen extends StatefulWidget {
  const ScheduledTournamentScreen({super.key});

  @override
  State<ScheduledTournamentScreen> createState() => _ScheduledTournamentScreenState();
}

class _ScheduledTournamentScreenState extends State<ScheduledTournamentScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _played = false;
  bool _preRegistered = false;
  bool _joinedToday = false;
  int _coins = 0;
  List<TournamentEntry> _leaderboard = [];
  String? _myDeviceId;

  late final AnimationController _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // 🐛 תוקן: אותו תיקון כמו tournament_lobby_screen.dart.
    AdsManager.recordBrowseNavigation();
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

  ScheduledTournamentPhase get _phase => ScheduledTournamentService.currentPhase;

  (String, String, String) _parts(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return (two(d.inHours), two(d.inMinutes % 60), two(d.inSeconds % 60));
  }

  Future<void> _load() async {
    final prize = await ScheduledTournamentService.checkAndClaimPendingPrize();
    final prefs = await SharedPreferences.getInstance();
    final played = await ScheduledTournamentService.hasPlayedToday();
    final joinedToday = await ScheduledTournamentService.hasJoinedToday();
    final preRegistered = await ScheduledTournamentService.hasPreRegisteredForNext();
    final board = await ScheduledTournamentService.fetchLeaderboard(ScheduledTournamentService.todayId());
    final deviceId = await DeviceId.get();
    if (!mounted) return;
    setState(() {
      _coins = prefs.getInt('coins') ?? 15;
      _played = played;
      _joinedToday = joinedToday;
      _preRegistered = preRegistered;
      _leaderboard = board;
      _myDeviceId = deviceId;
      _loading = false;
    });
    _entrance.forward(from: 0);
    if (prize != null && mounted) {
      showTournamentResultPopup(context, prize, label: 'הטורניר המתוזמן');
    }
  }

  // 🆕 "הירשמו מראש וקבלו תזכורת" - לפי בקשה מפורשת, כולל תשלום מיידי
  // של דמי הכניסה (ראו ScheduledTournamentService.preRegisterForNext) -
  // לכן מציגים אישור לפני החיוב, בדיוק כמו שמציגים לפני רכישה אמיתית
  // בחנות. ברגע שהחלון נפתח אין צורך לשלם שוב.
  Future<void> _togglePreRegister() async {
    AudioManager.playClick();
    if (_preRegistered) {
      await ScheduledTournamentService.cancelPreRegistration();
      if (!mounted) return;
      setState(() {
        _preRegistered = false;
        _joinedToday = false;
      });
      _load();
      return;
    }
    if (_coins < scheduledTournamentEntryFee) {
      showNotEnoughCoinsDialog(context, cost: scheduledTournamentEntryFee, coins: _coins, onReturnedFromShop: _load);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF241a4f),
          title: const Text('הרשמה מראש', style: TextStyle(color: Colors.white)),
          content: Text(
            '$scheduledTournamentEntryFee מטבעות ינוכו עכשיו, והמקום שלכם שמור - כשהחלון ייפתח פשוט תלחצו "שחקו" בלי לשלם שוב. אפשר לבטל ולקבל החזר כל עוד לא שיחקתם.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('אישור')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final missing = await ScheduledTournamentService.preRegisterForNext();
    if (!mounted) return;
    if (missing != null) {
      showNotEnoughCoinsDialog(context, cost: missing, coins: _coins, onReturnedFromShop: _load);
      return;
    }
    setState(() => _preRegistered = true);
    _load();
    if (!NotificationManager.notificationsEnabled) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF241a4f),
            title: const Text('נרשמתם בהצלחה', style: TextStyle(color: Colors.white)),
            content: Text(
              'שימו לב - ההתראות כבויות אצלכם בהגדרות, אז התזכורת לא תגיע בפועל (המקום שלכם כן שמור). אפשר להדליק אותן במסך ההגדרות.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('הבנתי'))],
          ),
        ),
      );
    }
  }

  // 🆕 כפתור "שחקו!" כשכבר שולם מראש (pre-registered) - join() בטוח גם
  // נגד תשלום כפול (ראו שם), אז פשוט קוראים לו תמיד לפני הניווט; במקרה
  // הזה הוא לא יגבה שוב, רק יבטל את תזכורת ה"מתחיל עכשיו" המיותרת.
  Future<void> _onPlayNow() async {
    AudioManager.playClick();
    await ScheduledTournamentService.join();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduledTournamentPlayScreen()));
    _load();
  }

  Future<void> _onJoinAndPlay() async {
    AudioManager.playClick();
    if (_phase != ScheduledTournamentPhase.active) return;
    if (_coins < scheduledTournamentEntryFee) {
      showNotEnoughCoinsDialog(context, cost: scheduledTournamentEntryFee, coins: _coins, onReturnedFromShop: _load);
      return;
    }
    final missing = await ScheduledTournamentService.join();
    if (!mounted) return;
    if (missing != null) {
      showNotEnoughCoinsDialog(context, cost: scheduledTournamentEntryFee, coins: _coins, onReturnedFromShop: _load);
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduledTournamentPlayScreen()));
    _load();
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
                    colors: [Color(0xFF28197A), Color(0xFF231468), Color(0xFF1B0F42), Color(0xFF120B2C)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF7C3AED).withValues(alpha: 0.3), const Color(0xFF7C3AED).withValues(alpha: 0)]),
                  ),
                ),
              ),
            ),
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
                          const Text('טורניר מתוזמן', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
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
                          _FadeIn(controller: _entrance, delay: 0.0, child: _buildHero()),
                          const SizedBox(height: 18),
                          _FadeIn(controller: _entrance, delay: 0.12, child: _buildPrizesRow()),
                          const SizedBox(height: 18),
                          _FadeIn(controller: _entrance, delay: 0.22, child: _buildInfoCard()),
                          const SizedBox(height: 22),
                          _FadeIn(controller: _entrance, delay: 0.3, child: _buildLeaderboard()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (!_loading)
              Positioned(left: 0, right: 0, bottom: 0, child: _buildStickyCta()),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final phase = _phase;
    final players = _leaderboard.length;
    String badge;
    String bigLabel;
    Duration countdown;
    String countdownLabel;
    switch (phase) {
      case ScheduledTournamentPhase.upcoming:
        badge = 'עוד לא התחיל';
        bigLabel = 'הטורניר הבא';
        countdown = ScheduledTournamentService.timeUntilNextStart;
        countdownLabel = 'מתחיל בעוד';
        break;
      case ScheduledTournamentPhase.active:
        badge = '$players משתתפים';
        bigLabel = 'הטורניר פעיל עכשיו!';
        countdown = ScheduledTournamentService.timeLeftInWindow;
        countdownLabel = 'נסגר בעוד';
        break;
      case ScheduledTournamentPhase.closed:
        badge = 'נסגר להיום';
        bigLabel = 'חוזר מחר';
        countdown = ScheduledTournamentService.timeUntilNextStart;
        countdownLabel = 'מתחיל בעוד';
        break;
    }
    final (hh, mm, ss) = _parts(countdown);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFBE185D)]),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (ctx, child) => Transform.translate(offset: Offset(0, -3 + 6 * _pulse.value), child: child),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFFFFD86B), size: 30),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(bigLabel, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.25)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'כל יום ב-$scheduledTournamentStartHour:00 · $scheduledTournamentLogoCount לוגואים · שעה לענות',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.22)),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(countdownLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [_clockBox(hh), _clockColon(), _clockBox(mm), _clockColon(), _clockBox(ss)]),
                ),
              ],
            ),
          ),
          if (phase != ScheduledTournamentPhase.active) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _togglePreRegister,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _preRegistered ? const Color(0xFF34D399).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.22),
                  border: _preRegistered ? Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _preRegistered ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      color: _preRegistered ? const Color(0xFFA7F3D0) : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _preRegistered ? 'נרשמתם! המקום שמור + תזכורת' : 'הירשמו מראש ($scheduledTournamentEntryFee מטבעות)',
                      style: TextStyle(color: _preRegistered ? const Color(0xFFA7F3D0) : Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _clockBox(String v) => Container(
        constraints: const BoxConstraints(minWidth: 32),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: Colors.white.withValues(alpha: 0.92)),
        alignment: Alignment.center,
        child: Text(v, style: const TextStyle(color: Color(0xFF4338CA), fontSize: 16, fontWeight: FontWeight.w900)),
      );

  Widget _clockColon() => const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Text(':', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)));

  Widget _buildPrizesRow() {
    final pool = currentScheduledPoolEstimate(_leaderboard.length);
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
            Expanded(flex: 100, child: _prizeTile(rank: 2, amount: p2, percent: 20)),
            const SizedBox(width: 8),
            Expanded(flex: 115, child: _prizeTile(rank: 1, amount: p1, percent: 40, elevated: true)),
            const SizedBox(width: 8),
            Expanded(flex: 100, child: _prizeTile(rank: 3, amount: p3, percent: 10)),
          ],
        ),
      ],
    );
  }

  Widget _prizeTile({required int rank, required int amount, required int percent, bool elevated = false}) {
    final Color top = rank == 1 ? const Color(0xFFFFE9A8) : (rank == 2 ? const Color(0xFFEDEDED) : const Color(0xFFE6B37E));
    final medalColor = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    return Container(
      padding: EdgeInsets.fromLTRB(6, elevated ? 18 : 14, 6, elevated ? 14 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(elevated ? 22 : 20),
        gradient: elevated ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFA78BFA).withValues(alpha: 0.26), const Color(0xFF7C3AED).withValues(alpha: 0.10)]) : null,
        color: elevated ? null : top.withValues(alpha: 0.12),
        border: Border.all(color: elevated ? const Color(0xFFA78BFA).withValues(alpha: 0.7) : top.withValues(alpha: 0.4), width: elevated ? 2 : 1.5),
        boxShadow: elevated ? [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: medalColor, size: elevated ? 30 : 24),
          const SizedBox(height: 4),
          Text('$amount', style: TextStyle(color: elevated ? const Color(0xFFD8B4FE) : Colors.white, fontSize: elevated ? 24 : 18, fontWeight: FontWeight.w900)),
          Text('$percent%', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.07), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
      child: Column(
        children: [
          _infoRow(gradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)], icon: Icons.schedule_rounded, text: 'כל יום ב-$scheduledTournamentStartHour:00, חלון של שעה בדיוק'),
          const SizedBox(height: 13),
          _infoRow(gradient: const [Color(0xFF8EDCFF), Color(0xFF0E8FD8)], icon: Icons.extension_rounded, text: '$scheduledTournamentLogoCount לוגואים, אותם לוגואים לכל המשתתפים'),
          const SizedBox(height: 13),
          _infoRow(gradient: const [Color(0xFF6EE7B7), Color(0xFF10B981)], icon: Icons.login_rounded, text: 'אפשר להצטרף תוך כדי, כל עוד החלון פתוח'),
        ],
      ),
    );
  }

  Widget _infoRow({required List<Color> gradient, required IconData icon, required String text}) {
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

  Widget _buildLeaderboard() {
    final top = _leaderboard.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('הדירוג של החלון הזה', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            if (_leaderboard.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.08)),
                child: Text('${_leaderboard.length} משתתפים', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (top.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06)),
            alignment: Alignment.center,
            child: Text(
              _phase == ScheduledTournamentPhase.active ? 'עדיין אין תוצאות בחלון הזה - תהיו הראשונים!' : 'הדירוג יופיע כשהחלון הבא ייפתח',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withValues(alpha: 0.06)),
            child: Column(
              children: List.generate(top.length, (i) {
                final entry = top[i];
                final isMe = _myDeviceId != null && entry.deviceId == _myDeviceId;
                final rank = i + 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(border: i < top.length - 1 ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))) : null),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Center(
                          child: rank <= 3
                              ? Icon(Icons.emoji_events_rounded, color: rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32)), size: 18)
                              : Text('$rank', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.name, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isMe ? FontWeight.w900 : FontWeight.w700), overflow: TextOverflow.ellipsis),
                      ),
                      if (isMe) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.person_rounded, color: Color(0xFF34D399), size: 14)),
                      Text('${entry.correctCount}/$scheduledTournamentLogoCount', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('${(entry.totalTimeMs / 1000).toStringAsFixed(1)}s', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5)),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildStickyCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 18),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00120B2C), Color(0xFF120B2C)], stops: [0.0, 0.45])),
      child: SafeArea(
        top: false,
        child: _buildCtaContent(),
      ),
    );
  }

  Widget _buildCtaContent() {
    if (_phase == ScheduledTournamentPhase.upcoming) {
      return _lockedMessage(icon: Icons.schedule_rounded, text: 'הטורניר עוד לא התחיל - חזרו ב-$scheduledTournamentStartHour:00');
    }
    if (_phase == ScheduledTournamentPhase.closed) {
      return _lockedMessage(icon: Icons.lock_clock_rounded, text: 'החלון של היום נסגר - חוזרים מחר ב-$scheduledTournamentStartHour:00');
    }
    if (_played) {
      return _lockedMessage(icon: Icons.check_circle_rounded, text: 'כבר השתתפתם בחלון הזה! חכו לתוצאות', iconColor: const Color(0xFF34D399));
    }
    // 🆕 כבר שולם מראש (ScheduledTournamentService.preRegisterForNext) -
    // בלי תג מחיר, בלי לגבות שוב - ראו _onPlayNow.
    if (_joinedToday) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (ctx, _) {
          final glow = _pulse.value;
          return GestureDetector(
            onTap: _onPlayNow,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6EE7B7), Color(0xFF10B981)]),
                boxShadow: [
                  const BoxShadow(color: Color(0xFF0A6E47), offset: Offset(0, 6)),
                  BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3 + 0.2 * glow), blurRadius: 20 + 10 * glow, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow_rounded, color: Color(0xFF052E1C), size: 20),
                  SizedBox(width: 6),
                  Text('שחקו! (כבר שילמתם)', style: TextStyle(color: Color(0xFF052E1C), fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        },
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, _) {
        final glow = _pulse.value;
        return GestureDetector(
          onTap: _onJoinAndPlay,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
              boxShadow: [
                const BoxShadow(color: Color(0xFF4C1D95), offset: Offset(0, 6)),
                BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3 + 0.2 * glow), blurRadius: 20 + 10 * glow, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('הצטרפו ושחקו', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.18)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [const CoinIcon(size: 14), const SizedBox(width: 4), Text('$scheduledTournamentEntryFee', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _lockedMessage({required IconData icon, required String text, Color iconColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white.withValues(alpha: 0.07), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  final Animation<double> controller;
  final double delay;
  final Widget child;
  const _FadeIn({required this.controller, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (ctx, child) {
        final local = ((controller.value - delay) / 0.55).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(local);
        return Opacity(opacity: eased, child: Transform.translate(offset: Offset(0, (1 - eased) * 16), child: child));
      },
    );
  }
}
