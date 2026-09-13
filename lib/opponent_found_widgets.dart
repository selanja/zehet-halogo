// opponent_found_widgets.dart
//
// 🆕 ווידג'טים משותפים למסך "נמצא יריב!" - חולצו מ-duel_lobby_screen.dart
// כדי ש-logo_race_screen.dart יוכל להשתמש באותם ווידג'טים בדיוק (לא רק
// "בהשראתם") לפי בקשה מפורשת: "אני רוצה שהמסך של נמצא יריב במירוץ יהיה
// בדיוק כמו בנמצא יריב בדו קרב". מקור האמת היחיד לעיצוב הזה מעכשיו הוא
// כאן - שינוי עתידי כאן ישפיע על שני המודים יחד.
import 'package:flutter/material.dart';

/// עיגול אווטאר עם טבעת גרדיאנט זוהרת - האות הראשונה של השם באמצע.
Widget avatarCircleWidget(
  String name, {
  double size = 54,
  bool ring = true,
  List<Color> innerColors = const [Color(0xFFFFE79A), Color(0xFFFFB24D)],
  List<Color> ringColors = const [Color(0xFFFFD86B), Color(0xFFFF9A3C)],
  Color glowColor = const Color(0xFFFFB43C),
  Color letterColor = const Color(0xFF2A1740),
  double borderAlpha = 0.75,
}) {
  final trimmed = name.trim();
  final letter = trimmed.isNotEmpty ? trimmed.substring(0, 1) : '?';
  final inner = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: innerColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      border: Border.all(color: Colors.white.withValues(alpha: borderAlpha), width: 2),
    ),
    alignment: Alignment.center,
    child: Text(letter, style: TextStyle(color: letterColor, fontSize: size * 0.38, fontWeight: FontWeight.w900)),
  );
  if (!ring) return inner;
  return Container(
    padding: const EdgeInsets.all(2.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: ringColors),
      boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.45), blurRadius: 18)],
    ),
    child: inner,
  );
}

/// באדג' ירוק "נמצא יריב!" - זהה בכל המודים.
Widget foundOpponentBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.5)),
      color: const Color(0xFF34D399).withValues(alpha: 0.16),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Icon(Icons.check_rounded, color: Color(0xFF6EE7B7), size: 14),
        SizedBox(width: 7),
        Text("נמצא יריב!", textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 12.5, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

String formatXpValue(int xp) {
  final s = xp.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

Widget _foundStatRow(String label, String value, Color valueColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: Colors.white.withValues(alpha: 0.06)),
    child: Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w700)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12.5, fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

/// כרטיס שחקן במסך "נמצא יריב!" - אווטאר + שם + תג + (אופציונלי) שורות
/// סטטיסטיקה (מקום/XP/ניצחונות). כשאין נתונים כאלה (למשל במרוץ, שאין בו
/// דירוג/היסטוריה) - להשאיר rank/xp/wins כ-null ושורות הסטטיסטיקה לא יוצגו.
Widget foundPlayerCard({
  required String name,
  required String label,
  required Color borderColor,
  required Color nameColor,
  required List<Color> innerColors,
  required List<Color> ringColors,
  required Color glowColor,
  int? rank,
  int? xp,
  int? wins,
}) {
  final showStats = rank != null || xp != null || wins != null;
  return Container(
    padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      gradient: LinearGradient(colors: [borderColor.withValues(alpha: 0.2), borderColor.withValues(alpha: 0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatarCircleWidget(name, size: 74, innerColors: innerColors, ringColors: ringColors, glowColor: glowColor),
        const SizedBox(height: 11),
        Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: nameColor, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
        if (showStats) ...[
          const SizedBox(height: 12),
          Column(
            children: [
              _foundStatRow("מקום", rank != null ? "#$rank" : "—", Colors.white),
              const SizedBox(height: 6),
              _foundStatRow("XP", xp != null ? formatXpValue(xp) : "—", const Color(0xFF93C5FD)),
              const SizedBox(height: 6),
              _foundStatRow("ניצחונות", "${wins ?? 0}", const Color(0xFFA7F3D0)),
            ],
          ),
        ],
      ],
    ),
  );
}

/// המפריד "VS" בין שני כרטיסי השחקנים - שני קווים אנכיים + עיגול "VS".
Widget foundVsDivider() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.18)),
        const SizedBox(height: 6),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.6), width: 1.5),
            color: const Color(0xFF2A1740).withValues(alpha: 0.95),
          ),
          alignment: Alignment.center,
          child: const Text("VS", style: TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 6),
        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.18)),
      ],
    ),
  );
}

Widget _termBox({required String value, required String label, required Color bg, required Color valueColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: bg.withValues(alpha: 0.14),
      border: Border.all(color: bg.withValues(alpha: 0.35)),
    ),
    child: Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

/// כרטיס "תנאי המשחק" (הימור/לוגואים/פרס) - משמש גם דו-קרב וגם מרוץ,
/// רק עם כותרת/אימוג'י/צבע מסגרת שונים לפי המוד.
Widget gameTermsCard({
  required String title,
  required String emoji,
  required Color accent,
  required int stake,
  required int logos,
  required int winnerReward,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: accent.withValues(alpha: 0.4)),
      gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _termBox(value: "$stake", label: "הימור", bg: const Color(0xFFFFD86B), valueColor: const Color(0xFFFFE7A8))),
            const SizedBox(width: 9),
            Expanded(child: _termBox(value: "$logos", label: "לוגואים", bg: const Color(0xFF60A5FA), valueColor: const Color(0xFFBFDBFE))),
            const SizedBox(width: 9),
            Expanded(child: _termBox(value: "$winnerReward", label: "למנצח", bg: const Color(0xFF34D399), valueColor: const Color(0xFFA7F3D0))),
          ],
        ),
      ],
    ),
  );
}

/// טבעת ספירה-לאחור עם המספר (או label חלופי, למשל "צאו!" בסוף הספירה
/// במרוץ) באמצע - זהה בכל המודים.
Widget readyCountdownRing({required int value, Color color = const Color(0xFFFFD86B), String? label}) {
  return SizedBox(
    width: 84,
    height: 84,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: CircularProgressIndicator(strokeWidth: 4, color: color, backgroundColor: const Color(0x22FFFFFF)),
        ),
        Text(label ?? "$value", style: TextStyle(color: color, fontSize: label != null ? 20 : 32, fontWeight: FontWeight.w900)),
      ],
    ),
  );
}
