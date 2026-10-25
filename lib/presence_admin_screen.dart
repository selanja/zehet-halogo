// presence_admin_screen.dart
//
// 🆕 מסך מעקב יזמי (לך בלבד - לא ל-users רגילים) - "כמה שחקנים מחוברים
// עכשיו בפועל ומה הם עושים" (איזה מוד: דו-קרב/מירוץ). נפתח דרך מסך
// הדיבאג הקיים (DebugLogScreen - כבר מוסתר מאחורי לחיצה ארוכה על מספר
// הגרסה/הגדרות, ראה main_menu_screen.dart / settings_screen.dart).
//
// ⚠️ מבוסס על אותה תשתית presence שכבר קיימת (presence_service.dart) -
// לא נוסף שום כתיבה/עלות חדשה ל-Firebase, רק שאילתת קריאה חדשה
// (listActive) שמופעלת רק כל עוד המסך הזה פתוח (כל 10 שניות), לא ברקע.
// ⚠️ אותה מגבלה ידועה כמו שאר המקומות שמשתמשים ב-presence: שחקן שכבר
// בתוך DuelRoomScreen בפועל (הקובץ המוגן) לא נספר - רק מי שבלובי/מחפש/
// בספירה לאחור. זו הערכה סבירה, לא ספירה מדויקת של כולם.
import 'dart:async';
import 'package:flutter/material.dart';
import 'presence_service.dart';
import 'l10n/app_localizations.dart';

class PresenceAdminScreen extends StatefulWidget {
  const PresenceAdminScreen({super.key});

  @override
  State<PresenceAdminScreen> createState() => _PresenceAdminScreenState();
}

class _PresenceAdminScreenState extends State<PresenceAdminScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  DateTime? _lastRefresh;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // 🆕 מתרענן אוטומטית כל 10 שניות כל עוד המסך פתוח - כדי שהמעקב
    // ירגיש "חי" בלי צורך ללחוץ רענון ידני כל הזמן.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await PresenceService.listActive();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
      _lastRefresh = DateTime.now();
    });
  }

  Map<String, int> get _countsByMode {
    final counts = <String, int>{};
    for (final e in _entries) {
      final mode = e['mode'] as String? ?? '?';
      counts[mode] = (counts[mode] ?? 0) + 1;
    }
    return counts;
  }

  String _modeLabel(String mode) {
    final loc = AppLocalizations.of(context)!;
    switch (mode) {
      case 'duel':
        return loc.presenceAdminModeDuel;
      case 'superdual':
        return loc.presenceAdminModeSuperDuel;
      case 'race':
        return loc.presenceAdminModeRace;
      default:
        return mode;
    }
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'duel':
        return const Color(0xFFF43F5E);
      case 'superdual':
        return const Color(0xFFF87171);
      case 'race':
        return const Color(0xFF38BDF8);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final counts = _countsByMode;
    // 🩹 תוקן: "בפנים רשום 3 1 1" (הסה"כ לא שווה לסכום דו-קרב+מירוץ) -
    // total היה _entries.length, שסופר *כל* מסמך נוכחות כולל מוד לא מוכר
    // (למשל משאריות ישנות/גרסת אפליקציה קודמת), בעוד שתי הכרטיסיות
    // למטה מציגות רק 'duel'/'race' במפורש - אז מסמך כזה ניפח את הסה"כ
    // בלי להופיע באף כרטיסייה. עכשיו הסה"כ מחושב מאותם שני מודים בדיוק
    // שמוצגים, כך שהוא תמיד שווה לסכומם - אין יותר מוד "רפאים" שסופר
    // בסה"כ אבל לא נראה בשום מקום.
    final total = (counts['duel'] ?? 0) + (counts['superdual'] ?? 0) + (counts['race'] ?? 0);
    return Scaffold(
      backgroundColor: const Color(0xFF12081F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12081F),
        title: Text(loc.presenceAdminTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _loading = true); _load(); }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white54))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🆕 שורת סיכום - סה"כ + פירוט לפי מוד, בדיוק המידע
                // שביקשת ("כמה שחקנים מחוברים ברגע זה, איזה מוד").
                Row(
                  children: [
                    Expanded(child: _summaryCard(loc.presenceAdminTotalLabel, '$total', Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(child: _summaryCard(loc.presenceAdminModeDuel, '${counts['duel'] ?? 0}', _modeColor('duel'))),
                    const SizedBox(width: 8),
                    Expanded(child: _summaryCard(loc.presenceAdminSeriesLabel, '${counts['superdual'] ?? 0}', _modeColor('superdual'))),
                    const SizedBox(width: 8),
                    Expanded(child: _summaryCard(loc.presenceAdminModeRace, '${counts['race'] ?? 0}', _modeColor('race'))),
                  ],
                ),
                const SizedBox(height: 6),
                if (_lastRefresh != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      loc.presenceAdminLastRefreshLabel(DateTime.now().difference(_lastRefresh!).inSeconds),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      loc.presenceAdminEmptyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                    ),
                  )
                else
                  ..._entries.map((e) => _deviceRow(e)),
              ],
            ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.05)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _deviceRow(Map<String, dynamic> e) {
    final loc = AppLocalizations.of(context)!;
    final deviceId = e['deviceId'] as String;
    final mode = e['mode'] as String? ?? '?';
    final updatedAt = e['updatedAt'] as DateTime?;
    final agoSec = updatedAt == null ? null : DateTime.now().difference(updatedAt).inSeconds;
    final shortId = deviceId.length > 10 ? '${deviceId.substring(0, 10)}…' : deviceId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.04)),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _modeColor(mode))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$shortId · ${_modeLabel(mode)}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (agoSec != null)
            Text(loc.presenceAdminSecondsAgo(agoSec), style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
        ],
      ),
    );
  }
}