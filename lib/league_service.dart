// league_service.dart
//
// 🆕 "ליגה שבועית" - כל שבוע כולם מתחילים מאפס, ומתחרים רק מול שחקנים באותה
// דרגה (ארד/כסף/זהב/יהלום), כך שמי שחדש לא מול מי שיש לו אלפי XP. בסוף השבוע:
// פרס מטבעות לפי מקום, ועלייה/ירידה בדרגה.
//
// הנקודות = אותו XP שמוענק ממילא על פעולות במשחק (BattlePassService.addPoints
// מעביר אליי כל תוספת) - אבל נספר רק לשבוע הנוכחי.
//
// אחסון: אותו מסמך leaderboard/{deviceId} שכבר קיים (חוקי Firestore הקיימים
// פותחים כתיבה אליו), בשלושה שדות נוספים: leagueKey ("weekId|tier"),
// leaguePoints, leagueName. שאילתה: where leagueKey == X (שוויון על שדה בודד -
// לא דורש אינדקס מורכב), ומיון בצד הלקוח.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_id.dart';

class LeagueTierInfo {
  final String name;
  final String emoji;
  final int color;
  const LeagueTierInfo(this.name, this.emoji, this.color);
}

class LeagueEntry {
  final String deviceId;
  final String name;
  final int points;
  const LeagueEntry(this.deviceId, this.name, this.points);
}

class LeagueRolloverResult {
  final int lastRank;
  final int lastPlayers;
  final int lastPoints;
  final int coins;
  final int oldTier;
  final int newTier;
  const LeagueRolloverResult({
    required this.lastRank,
    required this.lastPlayers,
    required this.lastPoints,
    required this.coins,
    required this.oldTier,
    required this.newTier,
  });
}

class LeagueService {
  LeagueService._();

  static const List<LeagueTierInfo> tiers = [
    LeagueTierInfo('ארד', '🥉', 0xFFCD7F32),
    LeagueTierInfo('כסף', '🥈', 0xFFC0C7D1),
    LeagueTierInfo('זהב', '🥇', 0xFFFFD86B),
    LeagueTierInfo('יהלום', '💎', 0xFF7DD3FC),
  ];

  static final _db = FirebaseFirestore.instance;
  static const String _keyTier = 'leagueTier';
  static const String _keyProcessedWeek = 'leagueProcessedWeek';
  static const String _keyLastPush = 'leagueLastPushMs';
  static const Duration _pushEvery = Duration(seconds: 90);

  // השבוע מתחיל ביום ראשון (שעון המכשיר). מזהה = תאריך יום ראשון בפורמט yyyy-MM-dd.
  static DateTime weekStart([DateTime? now]) {
    final n = now ?? DateTime.now();
    final d = DateTime(n.year, n.month, n.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  static String weekId([DateTime? now]) {
    final s = weekStart(now);
    return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
  }

  static DateTime weekEnd([DateTime? now]) => weekStart(now).add(const Duration(days: 7));

  static String _pointsKey(String week) => 'leaguePoints_$week';

  static Future<int> getTier() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_keyTier) ?? 0).clamp(0, tiers.length - 1);
  }

  static Future<int> myPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey(weekId())) ?? 0;
  }

  /// נקרא מ-BattlePassService.addPoints על כל תוספת XP.
  static Future<void> addPoints(int amount) async {
    if (amount <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _pointsKey(weekId());
      await prefs.setInt(key, (prefs.getInt(key) ?? 0) + amount);
      await pushScore();
    } catch (_) {}
  }

  /// שולח את הניקוד השבועי לענן. מוגבל בקצב (חיסכון בכתיבות) אלא אם force.
  static Future<void> pushScore({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs.getInt(_keyLastPush) ?? 0;
      if (!force && now - last < _pushEvery.inMilliseconds) return;
      final name = (prefs.getString('username') ?? '').trim();
      if (name.isEmpty) return; // בלי שם משתמש אין טבלה
      final points = prefs.getInt(_pointsKey(weekId())) ?? 0;
      final tier = (prefs.getInt(_keyTier) ?? 0).clamp(0, tiers.length - 1);
      final id = await DeviceId.get();
      await _db.collection('leaderboard').doc(id).set({
        'leagueKey': '${weekId()}|$tier',
        'leaguePoints': points,
        'leagueName': name,
      }, SetOptions(merge: true));
      await prefs.setInt(_keyLastPush, now);
    } catch (_) {}
  }

  static Future<List<LeagueEntry>> _standings(String week, int tier) async {
    final snap = await _db.collection('leaderboard').where('leagueKey', isEqualTo: '$week|$tier').limit(100).get();
    final list = snap.docs.map((d) {
      final data = d.data();
      final pts = data['leaguePoints'];
      return LeagueEntry(d.id, (data['leagueName'] ?? data['name'] ?? '').toString(), pts is num ? pts.toInt() : 0);
    }).toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  /// הטבלה של הדרגה שלי בשבוע הנוכחי.
  static Future<List<LeagueEntry>> currentStandings() async {
    await pushScore(force: true);
    return _standings(weekId(), await getTier());
  }

  static int coinsForRank(int rank, int points) {
    if (points <= 0) return 0;
    if (rank == 1) return 100;
    if (rank == 2) return 60;
    if (rank == 3) return 40;
    return 10;
  }

  /// בודק אם התחיל שבוע חדש מאז הפעם האחרונה - אם כן, מחשב מקום בשבוע
  /// שעבר, מזכה מטבעות, ומעדכן דרגה (עלייה/ירידה). מחזיר null אם אין מה לדווח.
  static Future<LeagueRolloverResult?> processRollover() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = weekId();
      final processed = prefs.getString(_keyProcessedWeek);
      if (processed == null) {
        await prefs.setString(_keyProcessedWeek, current); // התקנה ראשונה/פיצ'ר חדש - אין שבוע קודם
        return null;
      }
      if (processed == current) return null;
      final prev = weekId(weekStart().subtract(const Duration(days: 1)));
      final myPrevPoints = prefs.getInt(_pointsKey(prev)) ?? 0;
      final oldTier = (prefs.getInt(_keyTier) ?? 0).clamp(0, tiers.length - 1);
      LeagueRolloverResult? result;
      if (myPrevPoints > 0) {
        final standings = await _standings(prev, oldTier);
        final id = await DeviceId.get();
        final idx = standings.indexWhere((e) => e.deviceId == id);
        final rank = idx >= 0 ? idx + 1 : standings.length + 1;
        final n = standings.isEmpty ? 1 : standings.length;
        var newTier = oldTier;
        if (n >= 4 && rank <= 3 && oldTier < tiers.length - 1) newTier = oldTier + 1;
        if (n >= 8 && rank > n - 2 && oldTier > 0) newTier = oldTier - 1;
        final coins = coinsForRank(rank, myPrevPoints);
        if (coins > 0) await prefs.setInt('coins', (prefs.getInt('coins') ?? 15) + coins);
        await prefs.setInt(_keyTier, newTier);
        result = LeagueRolloverResult(lastRank: rank, lastPlayers: n, lastPoints: myPrevPoints, coins: coins, oldTier: oldTier, newTier: newTier);
      }
      await prefs.setString(_keyProcessedWeek, current);
      await pushScore(force: true); // מעדכן את המפתח לשבוע/דרגה החדשים (נקודות 0)
      return result;
    } catch (_) {
      return null;
    }
  }
}
