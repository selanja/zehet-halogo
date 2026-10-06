// play_vs_person_mode_screen.dart
//
// 🆕 מסך רכזת "שחק מול אחרים" - נקודת הכניסה המאוחדת לדו-קרב ולמרוץ
// לוגואים, במקום שני כרטיסים נפרדים בתפריט הראשי. עוצב במדויק לפי
// המוקאפ שסופק (מסך "04 · בחירת מוד" ב-New_Screens.html): שני כרטיסי
// מוד גדולים בגרדיאנט (דו-קרב אדום, מרוץ כחול) עם מספר "משחקים עכשיו"
// חי לכל מוד, ושתי כפתורי קיצור בתחתית (טבלת העונה / קרא לחבר) - שהיו
// בעבר בתוך בורר ההימור של הדו-קרב עצמו ועברו לכאן כדי לשרת את שני
// המודים במקום אחד.
//
// ⚠️ בחירת ה"הימור" (כמה מטבעות) לא קורית כאן יותר - היא נשארה בתוך
// כל מסך מוד בנפרד (DuelLobbyScreen/LogoRaceScreen - ראה שם
// "_buildStakePicker", שעוצב מחדש בהתאמה לפי מסך "05 · גודל ההימור"),
// כי לכל מוד טבלת הימורים שונה משלו.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_icons.dart';
import 'audio_manager.dart';
import 'duel_lobby_screen.dart';
import 'duel_service.dart';
import 'logo_race_screen.dart';
import 'logo_race_service.dart';
import 'presence_service.dart';
import 'duel_season_leaderboard_screen.dart';
import 'friend_challenge_screen.dart';
import 'friend_service.dart'; // 🆕 רשימת חברים כאן במסך עצמו - ראו _buildFriendsSection
import 'first_visit_explainer.dart'; // 🆕 הסבר חד-פעמי, עצמאי - לא תלוי בסיור במסך הבית

class PlayVsPersonModeScreen extends StatefulWidget {
  final String username;
  const PlayVsPersonModeScreen({super.key, required this.username});

  @override
  State<PlayVsPersonModeScreen> createState() => _PlayVsPersonModeScreenState();
}

class _PlayVsPersonModeScreenState extends State<PlayVsPersonModeScreen> {
  // 🐛 תוקן: "מדגיש את שחק מול אחרים אבל ההסבר נמצא בשלבים" - קודם ההסבר
  // הזה הגיע רק דרך דגל שהועבר מ-main_menu_screen.dart (שלב 3 של הסיור),
  // ובטעות גם סימן הדרכה *אחרת* לגמרי (ראו logo_level_screen.dart) - אז
  // אם הגיעו לכאן בדרך אחרת (לא דרך הסיור), ההסבר הזה אף פעם לא הופיע,
  // וההדרכה הלא-קשורה קפצה מאוחר יותר במקום אחר. עכשיו זה בודק באופן
  // עצמאי לגמרי (כמו מסכי משימות/חברים/מובילים) - מופיע בכל דרך שמגיעים
  // לכאן בפעם הראשונה, לא משנה אם זה היה דרך הסיור או לא.
  bool _showIntro = false;
  int _coins = 0;
  int? _duelPlayersNow;
  int? _racePlayersNow;
  // 🆕 "סדרת דו-קרב" - מוד presence נפרד לגמרי מ-'duel' (ראו
  // duel_lobby_screen.dart/PresenceService.startHeartbeat) - לא אותו
  // מספר כמו דו-קרב רגיל, לא צריך "להצטרף" לשום סכום אחר.
  int? _superdualPlayersNow;

  // 🆕 "כשמישהו רוצה להזמין חבר בתוך שחק מול אחרים, שתופיע לו למטה
  // רשימת החברים שלו" - לפי בקשה מפורשת. כל חבר מחובר מקבל כאן שני
  // כפתורי הזמנה מהירים (דו-קרב/מירוץ) במקום שיצטרך לצאת למסך "חברים"
  // הנפרד ולחזור.
  List<FriendInfo> _friends = [];
  bool _loadingFriends = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadFriends();
    FirstVisitExplainer.shouldShow('playVsPerson').then((show) {
      if (show && mounted) setState(() => _showIntro = true);
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _coins = prefs.getInt('coins') ?? 15);
    final results = await Future.wait([
      PresenceService.countActive('duel'),
      PresenceService.countActive('race'),
      PresenceService.countActive('superdual'),
    ]);
    if (!mounted) return;
    setState(() {
      _duelPlayersNow = results[0];
      _racePlayersNow = results[1];
      _superdualPlayersNow = results[2];
    });
  }

  Future<void> _loadFriends() async {
    final friends = await FriendService.fetchFriends();
    if (!mounted) return;
    setState(() {
      _friends = friends;
      _loadingFriends = false;
    });
  }

  Future<void> _inviteFriend(FriendInfo friend, {required bool isDuel}) async {
    AudioManager.playClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendChallengeScreen(
          username: widget.username,
          targetFriendId: friend.id,
          targetFriendName: friend.name,
          isDuel: isDuel,
        ),
      ),
    );
    if (mounted) _load();
  }

  int get _totalConnected => (_duelPlayersNow ?? 0) + (_racePlayersNow ?? 0) + (_superdualPlayersNow ?? 0);

  @override
  Widget build(BuildContext context) {
    // 🎯 טווח שאלות הדו-קרב לפי טבלת ההימורים (מחושב דינמית, לא קבוע -
    // כדי שיישאר נכון גם אם DuelService.stakeQuestionCounts ישתנה).
    final duelCounts = DuelService.stakeQuestionCounts.values.toList()..sort();
    final duelLogosLabel = duelCounts.isEmpty ? '' : (duelCounts.first == duelCounts.last ? '${duelCounts.first} לוגואים' : '${duelCounts.first}–${duelCounts.last} לוגואים');
    final raceMax = LogoRaceService.stakeQuestionCounts.values.isEmpty ? 0 : LogoRaceService.stakeQuestionCounts.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1140),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4C1D5E), Color(0xFF2A1550), Color(0xFF1A1140)],
                stops: [0.0, 0.42, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 18),
                  // 🆕 "סדרת דו-קרב (הטוב מ-3)" - הועבר להיות המוד הראשון
                  // שמוצג (לפי בקשה מפורשת) - מוד ארוך יותר: אותו יריב, עד
                  // 3 סיבובים ברצף (ממשיכים אוטומטית בין סיבוב לסיבוב), מי
                  // שמנצח 2 ראשון לוקח בונוס מטבעות על כל הסדרה.
                  _buildModeCard(
                    icon: '🏆',
                    title: "סדרת דו-קרב",
                    subtitle: "הטוב מ-3 מול אותו יריב · בונוס מטבעות על ניצחון בסדרה",
                    badge: "חדש",
                    gradient: const [Color(0xFFDC2626), Color(0xFF7C2D12)],
                    glowColor: const Color(0xFFF87171),
                    // 🆕 "סדרת דו-קרב" קיבלה מוד presence נפרד משלה
                    // ('superdual' - ראו duel_lobby_screen.dart/bot_config.dart)
                    // לפי בקשה מפורשת - זה *לא* אותו מספר כמו "דו־קרב" הרגיל
                    // למטה (ולא צריך להצטרף אליו לשום סכום), אז אין יותר
                    // בלבול מהצגת שני מספרים זהים.
                    playersNow: _superdualPlayersNow,
                    energyCost: 2,
                    infoRight: duelLogosLabel,
                    buttonTextColor: const Color(0xFFB91C1C),
                    onTap: () async {
                      AudioManager.playClick();
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => DuelLobbyScreen(username: widget.username, seriesMode: true)));
                      if (mounted) _load();
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildModeCard(
                    icon: '⚔',
                    title: "דו־קרב",
                    subtitle: "1 על 1 · מי שפותר יותר לוגואים מנצח",
                    badge: null,
                    gradient: const [Color(0xFFF43F5E), Color(0xFF7F1D3A)],
                    glowColor: const Color(0xFFF43F5E),
                    playersNow: _duelPlayersNow,
                    energyCost: 2,
                    infoRight: duelLogosLabel,
                    buttonTextColor: const Color(0xFFBE123C),
                    onTap: () => _openMode(isDuel: true),
                  ),
                  const SizedBox(height: 18),
                  _buildModeCard(
                    icon: '🏁',
                    title: "מירוץ",
                    subtitle: "1 על 1 · מי שמנחש ראשון בכל לוגו מנצח",
                    badge: "חדש",
                    gradient: const [Color(0xFF0EA5E9), Color(0xFF1E3A8A)],
                    glowColor: const Color(0xFF38BDF8),
                    playersNow: _racePlayersNow,
                    energyCost: 2,
                    infoRight: raceMax > 0 ? '$raceMax לוגואים' : '',
                    buttonTextColor: const Color(0xFF0369A1),
                    onTap: () => _openMode(isDuel: false),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _bottomButton(
                          icon: '🏆',
                          label: "טבלת העונה",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DuelSeasonLeaderboardScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bottomButton(
                          icon: '👥',
                          label: "קרא לחבר",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendChallengeScreen(username: widget.username))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildFriendsSection(),
                ],
              ),
            ),
          ),
          if (_showIntro) _buildOnboardingIntroOverlay(),
        ],
      ),
    );
  }

  // 🆕 "בפנים זה יסביר" - הסבר קצר (חד-פעמי) על שלושת המודים, מוצג רק
  // כשמגיעים לכאן מתוך שלב ה-3 של הסיור במסך הבית (ראו showOnboardingIntro).
  Widget _buildOnboardingIntroOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('3 דרכים לשחק נגד אחרים', textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    _introModeRow('🏆', 'סדרת דו-קרב', 'הטוב מ-3 מול אותו יריב - בונוס מטבעות על ניצחון בסדרה'),
                    const SizedBox(height: 12),
                    _introModeRow('⚔️', 'דו-קרב', 'עימות 1 על 1 - מי שפותר יותר לוגואים מנצח'),
                    const SizedBox(height: 12),
                    _introModeRow('🏁', 'מירוץ', 'עימות 1 על 1 - מי שמנחש ראשון בכל לוגו מנצח'),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          AudioManager.playClick();
                          FirstVisitExplainer.markSeen('playVsPerson');
                          setState(() => _showIntro = false);
                        },
                        child: const Text('הבנתי, בואו נבחר!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _introModeRow(String emoji, String title, String desc) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 14.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(desc, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // 🆕 "החברים שלי" - ישירות במסך הזה, כדי שאפשר יהיה להזמין חבר ספציפי
  // למוד ספציפי (⚔ דו-קרב / 🏁 מירוץ) בלי לצאת למסך "חברים" הנפרד.
  // רק חברים מחוברים ניתנים להזמנה, בדיוק כמו ב-friends_screen.dart.
  Widget _buildFriendsSection() {
    if (_loadingFriends) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFA7F3D0), strokeWidth: 2.4)),
      );
    }
    if (_friends.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            const Text("הזמן חבר ישירות", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Text("(${_friends.length})", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        for (final friend in _friends) ...[
          _friendInviteRow(friend),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _friendInviteRow(FriendInfo friend) {
    final letter = friend.name.trim().isNotEmpty ? friend.name.trim().substring(0, 1).toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.05)),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)])),
                alignment: Alignment.center,
                child: Text(letter, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 14, fontWeight: FontWeight.w900)),
              ),
              Positioned(
                bottom: -1,
                left: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: friend.online ? const Color(0xFF34D399) : Colors.white24,
                    border: Border.all(color: const Color(0xFF1A1140), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              friend.name,
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
          ),
          if (!friend.online)
            Text("לא מחובר", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11.5, fontWeight: FontWeight.w700))
          else ...[
            _quickInviteButton(icon: '⚔', color: const Color(0xFFF43F5E), onTap: () => _inviteFriend(friend, isDuel: true)),
            const SizedBox(width: 8),
            _quickInviteButton(icon: '🏁', color: const Color(0xFF38BDF8), onTap: () => _inviteFriend(friend, isDuel: false)),
          ],
        ],
      ),
    );
  }

  Widget _quickInviteButton({required String icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(icon, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  Future<void> _openMode({required bool isDuel}) async {
    AudioManager.playClick();
    if (isDuel) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => DuelLobbyScreen(username: widget.username)));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => LogoRaceScreen(username: widget.username)));
    }
    if (mounted) _load(); // 🆕 מרענן מטבעות + "משחקים עכשיו" עם החזרה למסך הזה
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFFFFC64B).withValues(alpha: 0.18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoinIcon(size: 15),
              const SizedBox(width: 5),
              Text('$_coins', style: const TextStyle(color: Color(0xFFFFD979), fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text("בחר מוד", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              if (_duelPlayersNow != null || _racePlayersNow != null || _superdualPlayersNow != null) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
                    const SizedBox(width: 5),
                    Text('$_totalConnected מחוברים', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String subtitle,
    required String? badge,
    required List<Color> gradient,
    required Color glowColor,
    required int? playersNow,
    required int energyCost,
    required String infoRight,
    required Color buttonTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(colors: gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
            boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.25), blurRadius: 26, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playersNow != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.28)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6EE7B7))),
                          const SizedBox(width: 5),
                          Text('$playersNow', style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 4),
                          Text('משחקים', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.22)),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 27)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFFDE68A)),
                      child: Text(badge, style: const TextStyle(color: Color(0xFF40170F), fontSize: 9.5, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 55,
                    height: 40,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white),
                    alignment: Alignment.center,
                    child: Text("בחר", style: TextStyle(color: buttonTextColor, fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  if (infoRight.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.28)),
                      child: Text(infoRight, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.28)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EnergyIcon(size: 11),
                        const SizedBox(width: 3),
                        Text('$energyCost', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton({required String icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.07)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(label, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}