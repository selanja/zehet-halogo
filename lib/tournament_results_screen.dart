// tournament_results_screen.dart
//
// מסך תוצאות אחרי סיום יום בודד בתוך האתגר הרב-יומי: כמה נכונות באותו
// יום, הזמן, המיקום הנוכחי בטבלה המצטברת (נטען פעם אחת מ-Firestore -
// ראו TournamentService.fetchLeaderboard), ופרס ההשתתפות (XP + נקודות
// לוגו פאס) שכבר ניתן אוטומטית ב-submitDayResult. פרס המיקום (אם זוכים)
// ניתן רק כשהאירוע כולו מסתיים - ראו checkAndClaimPendingPrize במסך
// הלובי, לא כאן.
import 'package:flutter/material.dart';
import 'tournament_service.dart';
import 'tournament_lobby_screen.dart';
import 'device_id.dart';

class TournamentResultsScreen extends StatefulWidget {
  final int correctCount;
  final int totalMs;
  const TournamentResultsScreen({super.key, required this.correctCount, required this.totalMs});

  @override
  State<TournamentResultsScreen> createState() => _TournamentResultsScreenState();
}

class _TournamentResultsScreenState extends State<TournamentResultsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  int? _rank;
  int _totalParticipants = 0;

  // 🆕 כניסה קלה (fade+scale עם easeOutBack) לכל התוכן - בדיוק אותה
  // נוסחה שכבר קיימת ב-tournament_result_popup.dart/battle_pass_reward_popup.dart,
  // כדי שגם מסך התוצאות ירגיש קצת יותר "אירוע" ולא רק טקסט שקופץ מיד.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final board = await TournamentService.fetchLeaderboard(TournamentService.eventId());
    final myDeviceId = await DeviceId.get();
    if (!mounted) return;
    final idx = board.indexWhere((e) => e.deviceId == myDeviceId);
    setState(() {
      _rank = idx >= 0 ? idx + 1 : null;
      _totalParticipants = board.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (widget.totalMs / 1000).toStringAsFixed(1);
    final day = TournamentService.dayInEvent();
    final isLastDay = day >= tournamentEventDays;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToLobby();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0818),
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A2394), Color(0xFF1F1150), Color(0xFF120B2C)]),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (ctx, child) {
                        final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
                        return Opacity(
                          opacity: _c.value.clamp(0.0, 1.0),
                          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
                        );
                      },
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A2170), Color(0xFF1F1150)]),
                            border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4), width: 2),
                            boxShadow: [BoxShadow(color: const Color(0xFFFFD86B).withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 2)],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD86B), size: 56),
                        ),
                        const SizedBox(height: 22),
                        Text(isLastDay ? 'סיימתם את האתגר!' : 'סיימתם את יום $day!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        // 🆕 "גם לפי זמן, שמי שעושה בזמן הכי מהר הניקוד
                        // שלו יותר גבוה" - ניקוד היום (אותה נוסחה בדיוק
                        // כמו TournamentEntry.score, רק על נתוני היום
                        // הזה בלבד) - כדי שיהיה ברור שהזמן באמת משפיע.
                        Text(
                          '+${widget.correctCount * tournamentPointsPerCorrect - (widget.totalMs ~/ 1000)} נק׳ היום',
                          style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statTile('${widget.correctCount}/$tournamentDailyLogoCount', 'נכונות'),
                            const SizedBox(width: 14),
                            _statTile('${seconds}s', 'זמן'),
                            const SizedBox(width: 14),
                            _statTile(
                              _loading ? '...' : (_rank != null ? '#$_rank' : '-'),
                              'מיקום',
                              accent: (!_loading && _rank != null && _rank! <= 3) ? const Color(0xFFFFD86B) : null,
                            ),
                          ],
                        ),
                        if (!_loading && _rank != null && _totalParticipants > 0) ...[
                          const SizedBox(height: 10),
                          Text('מתוך $_totalParticipants משתתפים באתגר', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5)),
                        ],
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFFFD86B).withValues(alpha: 0.14)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('+$tournamentXpReward XP', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 13, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              const Text('·', style: TextStyle(color: Color(0xFFFFD86B))),
                              const SizedBox(width: 8),
                              Text('+$tournamentBattlePassPoints', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 13, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 3),
                              const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFFD86B), size: 13),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLastDay
                              ? 'זה היה היום האחרון! התוצאות הסופיות והפרסים יחולקו בפעם הבאה שתפתחו את מסך הטורניר'
                              : 'יש עוד ${tournamentEventDays - day} ימים באתגר - חזרו מחר ליום הבא',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                        ),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _goToLobby,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 15),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F45)])),
                            child: const Text('לטבלת הדירוג', style: TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 accent - אם לא null (מיקום 1-3 בפועל), מדגיש את האריח בזהב כדי
  // שהתוצאה המיוחדת תורגש בלי מילים נוספות.
  Widget _statTile(String value, String label, {Color? accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent != null ? accent.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: accent != null ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent ?? Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  void _goToLobby() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TournamentLobbyScreen()));
  }
}
