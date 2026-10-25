// preview_main.dart - standalone preview harness, NOT part of the real app.
// Renders the new home-screen design with fake static data so it can be
// visually checked in a browser (flutter build web -t lib/preview_main.dart)
// without touching Firebase/real app state. Delete before shipping.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'locale_controller.dart';

void main() => runApp(const PreviewApp());

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        backgroundColor: const Color(0xFF120D2B),
        body: Center(
          child: SizedBox(
            width: 390,
            height: 880,
            child: HomePreview(),
          ),
        ),
      ),
    );
  }
}

class HomePreview extends StatelessWidget {
  const HomePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF120D2B))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 14),
                _buildStatsCapsule(context),
                const SizedBox(height: 14),
                _buildContinueCard(context),
                const SizedBox(height: 14),
                _buildDailyChallenge(context),
                const SizedBox(height: 12),
                _buildModesGrid(context),
                const SizedBox(height: 12),
                _buildBattlePass(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF2C2360),
                border: Border.all(color: const Color(0xFFFFC94D), width: 2),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _tile('ז', const Color(0xFFFF6B8B)),
                  _tile('ה', const Color(0xFF4FB8FF)),
                  _tile('ל', const Color(0xFF3DD68C)),
                  _tile('?', const Color(0xFFFFC94D)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.previewUsername, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFFF4F1FF))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Color(0xFFFFC94D), size: 14),
                    const SizedBox(width: 5),
                    Text(loc.previewMedalsCount, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _roundIconButton(Icons.card_giftcard_rounded, dot: true),
            const SizedBox(width: 10),
            _roundIconButton(Icons.settings_rounded),
          ],
        ),
      ],
    );
  }

  Widget _tile(String letter, Color color) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      alignment: Alignment.center,
      child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _roundIconButton(IconData icon, {bool dot = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2C2360)),
          child: Icon(icon, color: const Color(0xFFC9C2EC), size: 21),
        ),
        if (dot)
          Positioned(
            top: 9,
            left: 9,
            child: Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5470))),
          ),
      ],
    );
  }

  Widget _buildStatsCapsule(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFF1D1645), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(child: _statSegment(Icons.local_fire_department_rounded, const Color(0xFFFF8A3D), '1', loc.leaderboardStreakLabel)),
          Container(width: 1, height: 36, color: const Color(0xFF332A66)),
          Expanded(child: _statSegment(Icons.bolt_rounded, const Color(0xFF5CC8FF), '8/8', loc.shopEnergyLabel)),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: const Color(0xFF2C2360)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFC94D), size: 18),
                  const SizedBox(width: 6),
                  const Text('8,405', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statSegment(IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }

  Widget _buildContinueCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const percent = 58;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF6A4FE0), Color(0xFF4A3BD6)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.22)),
                      child: Text(loc.previewContinueBannerLabel, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    Text(loc.worldName5, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(loc.previewStageLabel(11), style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(value: percent / 100, strokeWidth: 8, backgroundColor: Color(0x33000000), valueColor: AlwaysStoppedAnimation(Color(0xFFFFC94D)), strokeCap: StrokeCap.round),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('$percent%', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(loc.previewCompletedLabel, style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 52,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFFFC94D)),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.previewContinuePlayingButton, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2A1B00))),
                const SizedBox(width: 8),
                const Icon(Icons.play_arrow_rounded, color: Color(0xFF2A1B00), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: const Color(0xFF1D1645)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFF173A5C)),
            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF5CC8FF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.previewDailyChallengeTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(loc.previewDailyChallengeSubtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFFB3ABDB))),
              ],
            ),
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: const Color(0xFF5CC8FF)),
            alignment: Alignment.center,
            child: Text(loc.subLevelsPlayLabel, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF08243A))),
          ),
        ],
      ),
    );
  }

  Widget _buildModesGrid(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _modeCard(loc.mainMenuPlayVsOthersTitle, loc.mainMenuDuelRaceNote, Icons.groups_rounded, const Color(0xFFC8344A), loc.previewConnectedCount)),
        const SizedBox(width: 12),
        Expanded(child: _modeCard(loc.logoLevelRandomChallengeHeader, loc.previewRandomChallengeSubtitle, Icons.apps_rounded, const Color(0xFF6A3FD3), null)),
      ],
    );
  }

  Widget _modeCard(String title, String subtitle, IconData icon, Color color, String? badge) {
    return Container(
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.18)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.3)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3DD68C))),
                      const SizedBox(width: 5),
                      Text(badge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _buildBattlePass(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: const Color(0xFF1D1645)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFFFFC94D)),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF3A2600), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.battlePassScreenTitle, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Color(0xFFFFC94D))),
                    const Text('0/0', style: TextStyle(fontSize: 13, color: Color(0xFFB3ABDB))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 8,
                    color: const Color(0xFF332A66),
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(widthFactor: 0.04, child: Container(color: const Color(0xFFFFC94D))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_left_rounded, color: Color(0xFF8E86BC)),
        ],
      ),
    );
  }
}
