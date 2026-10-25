// league_screen.dart - מסך "ליגה שבועית"
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_background.dart';
import 'device_id.dart';
import 'league_service.dart';
import 'main_menu_screen.dart';
import 'l10n/app_localizations.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  bool _loading = true;
  int _tier = 0;
  int _myPoints = 0;
  String _myId = '';
  List<LeagueEntry> _entries = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final rollover = await LeagueService.processRollover();
    final tier = await LeagueService.getTier();
    final pts = await LeagueService.myPoints();
    final id = await DeviceId.get();
    final entries = await LeagueService.currentStandings();
    if (!mounted) return;
    setState(() {
      _tier = tier;
      _myPoints = pts;
      _myId = id;
      _entries = entries;
      _loading = false;
    });
    if (rollover != null) {
      MainMenuScreen.onReturnedHome?.call();
      _showRollover(rollover);
    }
    // מבטיח שהשם שלי מופיע גם אם עוד לא נשלח
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString('username') ?? '').isEmpty) return;
  }

  void _showRollover(LeagueRolloverResult r) {
    final loc = AppLocalizations.of(context)!;
    final up = r.newTier > r.oldTier;
    final down = r.newTier < r.oldTier;
    final tierName = LeagueService.tiers[r.newTier].name;
    final body = '${loc.leaguePointsLastWeek(r.lastPoints)}\n'
        '${r.coins > 0 ? '${loc.leagueCoinsReceived(r.coins)}\n' : ''}'
        '${up ? loc.leagueTierUp(tierName) : down ? loc.leagueTierDown(tierName) : loc.leagueTierSame(tierName)}';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(loc.leagueRolloverSummaryTitle(r.lastRank, r.lastPlayers), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(
          body,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.leagueGreatButton))],
      ),
    );
  }

  String _timeLeft() {
    final loc = AppLocalizations.of(context)!;
    final left = LeagueService.weekEnd().difference(DateTime.now());
    if (left.isNegative) return loc.leagueEndsNow;
    final d = left.inDays;
    final h = left.inHours % 24;
    return d > 0 ? loc.leagueEndsInDaysHours(d, h) : loc.leagueEndsInHours(left.inHours);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final info = LeagueService.tiers[_tier];
    final tierColor = Color(info.color);
    final myIdx = _entries.indexWhere((e) => e.deviceId == _myId);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 4),
                      Text(loc.leagueScreenTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [tierColor.withValues(alpha: 0.28), tierColor.withValues(alpha: 0.06)]),
                      border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Text(info.emoji, style: const TextStyle(fontSize: 46)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.leagueTierNameLabel(info.name), style: TextStyle(color: tierColor, fontSize: 20, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(_timeLeft(), style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                myIdx >= 0 ? loc.leagueMyRankPoints(myIdx + 1, _myPoints) : loc.leaguePointsOnly(_myPoints),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    loc.leagueExplanationBody,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B)))
                      : _entries.isEmpty
                          ? Center(child: Text(loc.leagueEmptyMessage, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                                itemCount: _entries.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, i) => _row(i, _entries[i]),
                              ),
                            ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _row(int i, LeagueEntry e) {
    final loc = AppLocalizations.of(context)!;
    final me = e.deviceId == _myId;
    final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: me ? const Color(0xFFFFD86B).withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: me ? const Color(0xFFFFD86B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 22))
                : Text('${i + 1}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, fontWeight: FontWeight.w900)),
          ),
          Expanded(child: Text(e.name.isEmpty ? loc.leaguePlayerFallbackName : e.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: me ? FontWeight.w900 : FontWeight.w700))),
          Text('${e.points}', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text(loc.leaguePointsAbbrev, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }
}
