// duel_season_leaderboard_screen.dart
//
// 🆕 טבלת שיאים חודשית של דו-קרבים - מי ניצח הכי הרבה דו-קרבים החודש.
// מתאפסת אוטומטית בתחילת כל חודש קלנדרי (ראו DuelService.currentSeasonId
// ו-getSeasonLeaderboard) - לא כמו טבלת השיאים הרגילה (XP) שנשארת לתמיד.
// נכנסים אליו מכפתור "🏆 טבלת עונה" בתוך מסך בחירת ההימור של הדו-קרב.
//
// 🩹 עוצב מחדש לפי בקשה מפורשת - "תעשה כמו כל הטבלאות": בעבר זו הייתה
// רשימה פשוטה של שורות טקסט. עכשיו זה באותה שפה חזותית בדיוק כמו הטבלה
// הארצית (leaderboard_screen.dart) - פודיום 🥇🥈🥉 למקומות 1-3 עם
// אווטארים עגולים, שורות עם "watermark" מספר ענק שקוף ברקע, בר התקדמות
// יחסי, הדגשה זהובה למקום שלי, וכותרת-זכוכית (glass) קבועה למעלה. בכוונה
// *בלי* הרקע ה"אורורה" המונפש עם CustomPaint/RadialGradient שיש בטבלה
// הארצית - זה תועד כגורם קריסה על iOS (ראו ההערה ב-app_background.dart) -
// במקום זה נשאר AppBackground הבטוח שכבר משמש בכל שאר המסך.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'duel_service.dart';
import 'device_id.dart';
import 'app_background.dart';
import 'l10n/app_localizations.dart';

class DuelSeasonLeaderboardScreen extends StatefulWidget {
  const DuelSeasonLeaderboardScreen({super.key});

  @override
  State<DuelSeasonLeaderboardScreen> createState() => _DuelSeasonLeaderboardScreenState();
}

class _DuelSeasonLeaderboardScreenState extends State<DuelSeasonLeaderboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  int? _myRank;
  int _myWins = 0;
  String? _myDeviceId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final deviceId = await DeviceId.get();
    _myDeviceId = deviceId;
    final results = await Future.wait([
      DuelService.getSeasonLeaderboard(),
      DuelService.getMySeasonRank(deviceId),
    ]);
    if (!mounted) return;
    final rows = results[0] as List<Map<String, dynamic>>;
    final myRankData = results[1] as Map<String, dynamic>?;
    setState(() {
      _rows = rows;
      _myRank = myRankData?['rank'] as int?;
      _myWins = (myRankData?['wins'] ?? 0) as int;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: _loading
                  ? _buildLoading()
                  : _rows.isEmpty
                      ? _buildEmpty()
                      : _buildBoard(),
            ),
            _buildHeader(),
          ],
        ),
      ),
    );
  }

  // ===================== כותרת-זכוכית קבועה (בדיוק כמו leaderboard_screen) =====================
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 14),
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
            child: Row(
              children: [
                _GlassIconButton(icon: Icons.arrow_forward_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLocalizations.of(context)!.duelSeasonLbTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 6),
                          const Text("🏆", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(DuelService.seasonDisplayName(), style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _GlassIconButton(icon: Icons.refresh_rounded, color: Colors.white70, onTap: _load),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B)));
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.duelSeasonLbEmptyTitle, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.duelSeasonLbEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    final top3 = _rows.take(3).toList();
    final rest = _rows.length > 3 ? _rows.sublist(3) : <Map<String, dynamic>>[];
    final topWins = _rows.isNotEmpty ? (_rows.first['wins'] as int? ?? 1).clamp(1, 1 << 30) : 1;
    final bool myRowInList = _myRank != null && _myRank! <= _rows.length;
    final bool showMyRowFooter = _myRank != null && !myRowInList;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 84, 16, (showMyRowFooter ? 96 : 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPodium(top3),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionDivider(AppLocalizations.of(context)!.duelSeasonLbOthersSection),
            const SizedBox(height: 12),
            for (int i = 0; i < rest.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _buildRow(rest[i], i + 4, topWins),
              ),
          ],
          if (showMyRowFooter) ...[
            const SizedBox(height: 6),
            _buildSectionDivider(AppLocalizations.of(context)!.duelSeasonLbYourPlaceSection),
            const SizedBox(height: 12),
            _buildRow({'name': AppLocalizations.of(context)!.duelLobbyYouLabel, 'wins': _myWins, 'deviceId': _myDeviceId}, _myRank!, topWins),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.22)]))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        Expanded(
          child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.02)]))),
        ),
      ],
    );
  }

  // ===================== פודיום 🥇🥈🥉 =====================
  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    final p1 = top3.isNotEmpty ? top3[0] : null;
    final p2 = top3.length > 1 ? top3[1] : null;
    final p3 = top3.length > 2 ? top3[2] : null;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(flex: 100, child: p2 != null ? _podiumSpot(p2, 2, 108, const Color(0xFFC7D0DA)) : const SizedBox()),
          const SizedBox(width: 6),
          Expanded(flex: 116, child: p1 != null ? _podiumSpot(p1, 1, 140, const Color(0xFFFFD86B)) : const SizedBox()),
          const SizedBox(width: 6),
          Expanded(flex: 100, child: p3 != null ? _podiumSpot(p3, 3, 84, const Color(0xFFD69A63)) : const SizedBox()),
        ],
      ),
    );
  }

  Widget _podiumSpot(Map<String, dynamic> entry, int place, double height, Color color) {
    final loc = AppLocalizations.of(context)!;
    final bool isMe = (entry['deviceId'] ?? '') == _myDeviceId && (_myDeviceId ?? '').isNotEmpty;
    final String name = (entry['name'] ?? loc.duelSeasonLbPlayerFallbackName).toString();
    final String initial = name.isNotEmpty ? name.characters.first : '?';
    final int wins = (entry['wins'] ?? 0) as int;
    final bool isFirst = place == 1;
    final double avatarSize = isFirst ? 62 : 46;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isFirst ? "👑" : (place == 2 ? "🥈" : "🥉"), style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [color, color.withValues(alpha: 0.45), color]),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14)],
          ),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)])),
            child: Center(child: Text(initial, style: const TextStyle(color: Color(0xFF231536), fontSize: 18, fontWeight: FontWeight.w900))),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isMe ? loc.duelSeasonLbYouSuffix(name) : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isMe ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.92), fontSize: isFirst ? 15.5 : 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 9),
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
            boxShadow: isFirst ? [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.28), blurRadius: 26, offset: const Offset(0, -6))] : null,
          ),
          child: Column(
            children: [
              Text("$place", style: TextStyle(color: Colors.white.withValues(alpha: isFirst ? 1 : 0.9), fontSize: isFirst ? 26 : 20, fontWeight: FontWeight.w900)),
              SizedBox(height: isFirst ? 6 : 4),
              Text("$wins", style: TextStyle(color: Colors.white, fontSize: isFirst ? 17 : 14, fontWeight: FontWeight.w900)),
              Text(loc.duelLobbyWinsLabel, style: TextStyle(color: Colors.white.withValues(alpha: isFirst ? 0.7 : 0.55), fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== שורות 4 ומטה =====================
  Widget _buildRow(Map<String, dynamic> entry, int place, int topWins) {
    final loc = AppLocalizations.of(context)!;
    final bool isMe = (entry['deviceId'] ?? '') == _myDeviceId && (_myDeviceId ?? '').isNotEmpty;
    final String name = (entry['name'] ?? loc.duelSeasonLbPlayerFallbackName).toString();
    final int wins = (entry['wins'] ?? 0) as int;
    final double pct = (wins / topWins).clamp(0.02, 1.0);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMe ? const Color(0xFFFFC64B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.09), width: isMe ? 1.6 : 1),
        gradient: isMe
            ? const LinearGradient(colors: [Color(0x42FFC64B), Color(0x12FF9A3C)])
            : LinearGradient(colors: [Colors.white.withValues(alpha: 0.075), Colors.white.withValues(alpha: 0.02)]),
        boxShadow: isMe ? [BoxShadow(color: const Color(0xFFFF9A3C).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 6))] : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -14,
            left: -2,
            child: Text("$place", style: TextStyle(color: isMe ? const Color(0xFFFFC64B).withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05), fontSize: 56, fontWeight: FontWeight.w900, height: 1)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
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
                  child: Center(child: Text("$place", style: TextStyle(color: isMe ? const Color(0xFF2A1740) : Colors.white.withValues(alpha: 0.78), fontSize: 14, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isMe ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.96), fontSize: isMe ? 15.5 : 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFFFD86B).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
                              child: Text(loc.duelLobbyYouLabel, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
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
                                    : const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFC2163F)]),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$wins", style: TextStyle(color: isMe ? const Color(0xFFFFE7A8) : const Color(0xFFBFDBFE), fontSize: isMe ? 14.5 : 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(loc.duelLobbyWinsLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// כפתור זכוכית קטן לכותרת (רענון / חזרה) - עותק מקומי (private) של אותו
// widget שקיים ב-leaderboard_screen.dart, כי מחלקות פרטיות (_ClassName)
// לא ניתנות לשיתוף/ייבוא בין קבצים ב-Dart.
// ============================================================
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(icon, color: color, size: 17)),
      ),
    );
  }
}