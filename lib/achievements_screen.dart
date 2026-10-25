// achievements_screen.dart - מסך "הישגים ומדליות"
import 'package:flutter/material.dart';
import 'achievements_service.dart';
import 'app_background.dart';
import 'app_notification.dart';
import 'audio_manager.dart';
import 'main_menu_screen.dart';
import 'l10n/app_localizations.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final Map<String, int> _progress = {};
  Set<String> _claimed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final claimed = await AchievementsService.claimed();
    final progress = <String, int>{};
    for (final a in AchievementsService.all) {
      progress[a.id] = await AchievementsService.progress(a.counter);
    }
    if (!mounted) return;
    setState(() {
      _claimed = claimed;
      _progress
        ..clear()
        ..addAll(progress);
      _loading = false;
    });
  }

  Future<void> _claim(AchievementDef a) async {
    AudioManager.playClick();
    final coins = await AchievementsService.claim(a);
    if (!mounted) return;
    if (coins != null) {
      MainMenuScreen.onReturnedHome?.call();
      AppNotification.show(context, AppLocalizations.of(context)!.achievementsClaimedMessage(coins, a.title), type: AppNotificationType.success);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final earned = AchievementsService.all.where((a) => (_progress[a.id] ?? 0) >= a.goal).length;
    final loc = AppLocalizations.of(context)!;
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
                      Text(loc.achievementsTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.22), const Color(0xFFFF9A3C).withValues(alpha: 0.08)]),
                      border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎖️', style: TextStyle(fontSize: 34)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.achievementsEarnedCount(earned, AchievementsService.all.length), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(loc.achievementsDescription, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD86B)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                          itemCount: AchievementsService.all.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _row(AchievementsService.all[i]),
                        ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _row(AchievementDef a) {
    final p = _progress[a.id] ?? 0;
    final done = p >= a.goal;
    final claimed = _claimed.contains(a.id);
    final ratio = (p / a.goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: done ? 0.09 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? const Color(0xFFFFD86B).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF59E0B)]) : null,
              color: done ? null : Colors.white.withValues(alpha: 0.08),
            ),
            child: Opacity(opacity: done ? 1 : 0.35, child: Text(a.medal, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(a.desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: done ? const Color(0xFF4ADE80) : const Color(0xFF7DD3FC),
                  ),
                ),
                const SizedBox(height: 3),
                Text('${p.clamp(0, a.goal)} / ${a.goal}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (claimed)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 28)
          else if (done)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB24D), foregroundColor: const Color(0xFF2A1740), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _claim(a),
              child: Text('+${a.rewardCoins}', style: const TextStyle(fontWeight: FontWeight.w900)),
            )
          else
            Text('+${a.rewardCoins}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
